import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:oy_site/models/app_user.dart';

class CustomerProfileScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final List<_UploadedInsoleItem> _uploadedInsoles = [];

  Future<void> _pickInsoleImage() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) return;

    final now = DateTime.now();

    setState(() {
      for (final file in result.files) {
        if (file.path == null) continue;

        _uploadedInsoles.add(
          _UploadedInsoleItem(
            filePath: file.path!,
            fileName: file.name,
            uploadedAt: now,
          ),
        );
      }
    });
  }

  void _openImagePreview(_UploadedInsoleItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 900,
          height: 700,
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: InteractiveViewer(
                    child: Container(
                      width: double.infinity,
                      height: 130,
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: Image.file(
                        File(item.filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Text('Görsel yok'),
                      ),
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
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeaderCard(
                  title: user.displayName,
                  subtitle: 'Müşteri Profili',
                  email: user.email,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _SectionCard(
                            title: 'Kişisel Bilgiler',
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: 'Ad Soyad',
                                  value: user.displayName,
                                ),
                                _InfoRow(
                                  label: 'E-posta',
                                  value: user.email,
                                ),
                                _InfoRow(
                                  label: 'Telefon',
                                  value: user.phone ?? '—',
                                ),
                                _InfoRow(
                                  label: 'Rol',
                                  value: user.roleName ?? 'Müşteri',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: 'Kısa Özet',
                            child: Row(
                              children: const [
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Toplam Analiz',
                                    value: '4',
                                    icon: Icons.analytics_outlined,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Aktif Sipariş',
                                    value: '1',
                                    icon: Icons.shopping_bag_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: _SectionCard(
                        title: 'İç Taban Görsellerim',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton.icon(
                                onPressed: _pickInsoleImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.upload_outlined),
                                label: const Text('İç Taban Görseli Yükle'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_uploadedInsoles.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Text(
                                  'Henüz yüklenmiş iç taban görseli bulunmuyor.',
                                ),
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
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              width: double.infinity,
                                              height: 130,
                                              color: Colors.grey.shade100,
                                              alignment: Alignment.center,
                                              child: Image.file(
                                                File(item.filePath),
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => Container(
                                                  alignment: Alignment.center,
                                                  color: Colors.grey.shade200,
                                                  child: const Text('Görsel yok'),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            item.fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDate(item.uploadedAt),
                                            style: TextStyle(
                                              color: Colors.grey[700],
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadedInsoleItem {
  final String filePath;
  final String fileName;
  final DateTime uploadedAt;

  _UploadedInsoleItem({
    required this.filePath,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.teal.withOpacity(0.12),
            child: const Icon(
              Icons.person,
              size: 34,
              color: Colors.teal,
            ),
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
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
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

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
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
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}