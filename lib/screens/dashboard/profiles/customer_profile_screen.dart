import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:oy_site/data/repositories/supabase_session_reference_photo_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/models/session_reference_photo_model.dart';
import 'package:oy_site/services/storage/supabase_storage_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerProfileScreen({super.key, required this.currentUser});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final SupabaseAnalysisRepository _analysisRepository =
      SupabaseAnalysisRepository();
  final SupabaseOrderRepository _orderRepository = SupabaseOrderRepository();
  final SupabaseSessionReferencePhotoRepository _photoRepository =
      SupabaseSessionReferencePhotoRepository();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final List<_UploadedInsoleItem> _uploadedInsoles = [];

  int? _analysisCount;
  int? _activeOrderCount;
  bool _isSummaryLoading = true;
  bool _isInsolesLoading = true;
  bool _isUploadingInsoles = false;
  String? _insoleError;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadInsoleImages();
  }

  Future<void> _loadInsoleImages() async {
    try {
      final photos = await _photoRepository.getInsolePhotosForCurrentCustomer();
      final items = await Future.wait(
        photos.map((photo) async {
          String? imageUrl = photo.publicUrl;
          if ((imageUrl == null || imageUrl.isEmpty) &&
              photo.storagePath != null &&
              photo.storagePath!.isNotEmpty) {
            imageUrl = await _storageService.createSignedUrl(
              storagePath: photo.storagePath!,
              bucket:
                  photo.storageBucket ?? SupabaseStorageService.defaultBucket,
            );
          }
          return _UploadedInsoleItem(
            fileName: photo.fileName ?? 'İç taban fotoğrafı',
            uploadedAt: photo.createdAt ?? DateTime.now(),
            imageUrl: imageUrl,
          );
        }),
      );
      if (!mounted) return;
      setState(() {
        _uploadedInsoles
          ..clear()
          ..addAll(items);
        _isInsolesLoading = false;
        _insoleError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInsolesLoading = false;
        _insoleError = 'İç taban fotoğrafları yüklenemedi.';
      });
    }
  }

  Future<void> _loadSummary() async {
    try {
      final values = await Future.wait<Object>([
        _analysisRepository.getAnalysisHistoryForCurrentCustomer(),
        _orderRepository.getOrdersForCurrentCustomer(),
      ]);
      if (!mounted) return;

      final analyses = values[0] as List;
      final orders = values[1] as List<OrderModel>;
      setState(() {
        _analysisCount = analyses.length;
        _activeOrderCount = orders
            .where((order) => !order.isDelivered && !order.isCancelled)
            .length;
        _isSummaryLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _analysisCount = null;
        _activeOrderCount = null;
        _isSummaryLoading = false;
      });
    }
  }

  Future<void> _pickInsoleImage() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    setState(() => _isUploadingInsoles = true);
    try {
      final session = await _photoRepository
          .getLatestSessionForCurrentCustomer();
      if (session == null) {
        throw Exception(
          'Fotoğraf eklemek için önce bir ölçüm session’ı olmalı.',
        );
      }

      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        final uniqueName =
            '${DateTime.now().microsecondsSinceEpoch}_${file.name}';
        final storagePath = _storageService.buildReferencePhotoPath(
          sessionId: session.sessionId,
          photoType: SessionReferencePhotoTypes.insolePhoto,
          fileName: uniqueName,
        );
        final upload = await _storageService.uploadBytes(
          bytes: bytes,
          storagePath: storagePath,
        );
        try {
          await _photoRepository.createPhoto(
            photo: SessionReferencePhotoModel(
              sessionId: session.sessionId,
              patientId: session.patientId,
              expertUserId: session.expertUserId,
              photoType: SessionReferencePhotoTypes.insolePhoto,
              fileName: file.name,
              mimeType: _mimeTypeFor(file.name),
              sizeBytes: upload.sizeBytes,
              storageBucket: upload.bucket,
              storagePath: upload.storagePath,
              uploadStatus: ReferencePhotoUploadStatuses.uploaded,
              note: 'Müşteri profilinden yüklendi',
            ),
          );
        } catch (_) {
          await _storageService.removeFile(
            storagePath: upload.storagePath,
            bucket: upload.bucket,
          );
          rethrow;
        }
      }
      await _loadInsoleImages();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _insoleError = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isUploadingInsoles = false);
    }
  }

  String? _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  void _openImagePreview(_UploadedInsoleItem item) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.fileName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(
                      item.imageUrl ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          Center(child: Text(l10n.imageUnavailable)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 860;
          final pagePadding = constraints.maxWidth < 650 ? 16.0 : 24.0;
          final information = _buildInformationColumn(user, l10n);
          final images = _buildImagesCard(l10n);

          return SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myProfile,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    _ProfileHeaderCard(
                      title: user.displayName,
                      subtitle: l10n.customerProfile,
                      email: user.email,
                    ),
                    const SizedBox(height: 18),
                    if (isCompact) ...[
                      information,
                      const SizedBox(height: 18),
                      images,
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: information),
                          const SizedBox(width: 18),
                          Expanded(flex: 3, child: images),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInformationColumn(AppUser user, AppLocalizations l10n) {
    return Column(
      children: [
        _SectionCard(
          title: l10n.personalInformation,
          child: Column(
            children: [
              _InfoRow(label: l10n.fullName, value: user.displayName),
              _InfoRow(label: l10n.email, value: user.email),
              _InfoRow(label: l10n.phone, value: user.phone ?? '—'),
              _InfoRow(label: l10n.role, value: l10n.customerRole),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: l10n.shortSummary,
          child: Row(
            children: [
              Expanded(
                child: _MiniStatTile(
                  title: l10n.totalAnalyses,
                  value: _summaryValue(_analysisCount),
                  icon: Icons.analytics_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatTile(
                  title: l10n.activeOrder,
                  value: _summaryValue(_activeOrderCount),
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _summaryValue(int? value) {
    if (_isSummaryLoading) return '…';
    return value?.toString() ?? '—';
  }

  Widget _buildImagesCard(AppLocalizations l10n) {
    return _SectionCard(
      title: l10n.myInsoleImages,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geçmiş ölçümlerinizdeki iç taban fotoğraflarını görebilir ve yenilerini ekleyebilirsiniz.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _isUploadingInsoles ? null : _pickInsoleImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            icon: _isUploadingInsoles
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_outlined),
            label: Text(
              _isUploadingInsoles ? 'Yükleniyor…' : l10n.uploadInsoleImage,
            ),
          ),
          const SizedBox(height: 16),
          if (_insoleError != null) ...[
            Text(_insoleError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          if (_isInsolesLoading)
            const Center(child: CircularProgressIndicator())
          else if (_uploadedInsoles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(l10n.noInsoleImages),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _uploadedInsoles.map((item) {
                return InkWell(
                  onTap: () => _openImagePreview(item),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 130,
                            child: Image.network(
                              item.imageUrl ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) =>
                                  Center(child: Text(l10n.imageUnavailable)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item.uploadedAt),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _UploadedInsoleItem {
  final String? imageUrl;
  final String fileName;
  final DateTime uploadedAt;

  const _UploadedInsoleItem({
    this.imageUrl,
    required this.fileName,
    required this.uploadedAt,
  });
}

class _ProfileHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String email;

  const _ProfileHeaderCard({
    required this.title,
    required this.subtitle,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.teal.withValues(alpha: 0.12),
            child: const Icon(Icons.person, size: 34, color: Colors.teal),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(email, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
  );
}
