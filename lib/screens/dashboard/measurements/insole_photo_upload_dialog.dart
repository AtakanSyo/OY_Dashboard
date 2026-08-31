import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_session_reference_photo_repository.dart';
import 'package:oy_site/models/session_reference_photo_model.dart';
import 'package:oy_site/services/file_bytes_helper.dart';
import 'package:oy_site/services/storage/supabase_storage_service.dart';

class InsolePhotoUploadDialog extends StatefulWidget {
  final int? sessionId;
  final int? patientId;
  final int? expertUserId;

  const InsolePhotoUploadDialog({
    super.key,
    this.sessionId,
    this.patientId,
    this.expertUserId,
  });

  @override
  State<InsolePhotoUploadDialog> createState() =>
      _InsolePhotoUploadDialogState();
}

class _InsolePhotoUploadDialogState extends State<InsolePhotoUploadDialog> {
  final SupabaseSessionReferencePhotoRepository _repository =
      SupabaseSessionReferencePhotoRepository();

  final SupabaseStorageService _storageService = SupabaseStorageService();

  final TextEditingController _shoeBrandController = TextEditingController();
  final TextEditingController _shoeModelController = TextEditingController();
  final TextEditingController _shoeSizeController = TextEditingController();

  Uint8List? _fileBytes;
  String? _fileName;
  String? _localFilePath;
  int? _sizeBytes;

  bool _isDragging = false;
  bool _isUploading = false;
  String? _statusMessage;

  bool get _hasFile => _fileBytes != null;

  bool get _hasShoeInfo =>
      _shoeBrandController.text.trim().isNotEmpty &&
      _shoeModelController.text.trim().isNotEmpty &&
      _shoeSizeController.text.trim().isNotEmpty;

  bool get _canUpload => _hasFile && _hasShoeInfo && !_isUploading;

  @override
  void dispose() {
    _shoeBrandController.dispose();
    _shoeModelController.dispose();
    _shoeSizeController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    Uint8List? bytes = file.bytes;

    if (bytes == null && file.path != null) {
      bytes = await readBytesFromPath(file.path!);
    }

    if (bytes == null) return;

    setState(() {
      _fileBytes = bytes;
      _fileName = file.name;
      _localFilePath = file.path;
      _sizeBytes = file.size;
      _statusMessage = null;
    });
  }

  Future<void> _upload() async {
    if (_fileBytes == null) return;

    if (!_hasShoeInfo) {
      setState(() {
        _statusMessage =
            'Lütfen ayakkabı markası, modeli ve ayakkabı numarasını girin.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _statusMessage = null;
    });

    try {
      await _saveMetadataToSupabase();

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _statusMessage = 'Fotoğraf bilgisi kaydedilemedi: $e';
      });
    }
  }

  Future<void> _saveMetadataToSupabase() async {
    final sessionId = widget.sessionId;
    final patientId = widget.patientId;
    final expertUserId = widget.expertUserId;

    if (sessionId == null || patientId == null || expertUserId == null) {
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    final fileName =
        _fileName ?? 'insole_photo_${DateTime.now().millisecondsSinceEpoch}.png';

    StorageUploadResult? uploadResult;

    if (_localFilePath != null && _localFilePath!.trim().isNotEmpty) {
      final storagePath = _storageService.buildReferencePhotoPath(
        sessionId: sessionId,
        photoType: SessionReferencePhotoTypes.insolePhoto,
        fileName: fileName,
      );

      uploadResult = await _storageService.uploadLocalFile(
        localFilePath: _localFilePath!,
        storagePath: storagePath,
      );
    } else if (_fileBytes != null) {
      final storagePath = _storageService.buildReferencePhotoPath(
        sessionId: sessionId,
        photoType: SessionReferencePhotoTypes.insolePhoto,
        fileName: fileName,
      );

      uploadResult = await _storageService.uploadBytes(
        bytes: _fileBytes!,
        storagePath: storagePath,
      );
    }

    final shoeBrand = _shoeBrandController.text.trim();
    final shoeModel = _shoeModelController.text.trim();
    final shoeSize = _shoeSizeController.text.trim();

    final note = [
      'Referans iç taban fotoğrafı',
      'Ayakkabı markası: $shoeBrand',
      'Ayakkabı modeli: $shoeModel',
      'Ayakkabı numarası: $shoeSize',
    ].join('\n');

    final photo = SessionReferencePhotoModel(
      sessionId: sessionId,
      patientId: patientId,
      expertUserId: expertUserId,
      photoType: SessionReferencePhotoTypes.insolePhoto,
      fileName: fileName,
      mimeType: _guessMimeType(fileName),
      sizeBytes: uploadResult?.sizeBytes ?? _sizeBytes ?? _fileBytes?.length,
      localFilePath: _localFilePath,
      storageBucket: uploadResult?.bucket,
      storagePath: uploadResult?.storagePath,
      publicUrl: null,
      uploadStatus: uploadResult == null
          ? ReferencePhotoUploadStatuses.local
          : ReferencePhotoUploadStatuses.uploaded,
      note: note,
    );

    await _repository.createPhoto(photo: photo);
  }

  String? _guessMimeType(String? fileName) {
    final lower = (fileName ?? '').toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (lower.endsWith('.png')) {
      return 'image/png';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    return null;
  }

  Future<void> _handleDroppedFile(dynamic file) async {
    final path = file.path as String?;
    if (path == null || path.trim().isEmpty) return;

    final bytes = await readBytesFromPath(path);
    if (bytes == null || !mounted) return;

    int? size;
    try {
      final localFile = File(path);
      if (localFile.existsSync()) {
        size = localFile.lengthSync();
      }
    } catch (_) {}

    setState(() {
      _fileBytes = bytes;
      _fileName = file.name as String?;
      _localFilePath = path;
      _sizeBytes = size ?? bytes.length;
      _isDragging = false;
      _statusMessage = null;
    });
  }

  void _clearFile() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
      _localFilePath = null;
      _sizeBytes = null;
      _statusMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 760,
          maxHeight: 820,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'İç Taban Fotoğrafı Yükle',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Lütfen iç tabanı aşağıdaki yöntemlerden biriyle fotoğraflayın:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• İç tabanı ölçekli / antetli A4 kağıt üzerine yerleştirin.',
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Alternatif olarak A4 üzerine ortalayın, üst köşeye yakın ve alt köşeye yakın 1 TL ile fotoğraflayın.',
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Fotoğraf net, üstten çekilmiş ve kenarlar görünür olmalı.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildShoeInfoFields(),
              const SizedBox(height: 18),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildTemplatePreview(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: kIsWeb
                          ? _buildDropArea()
                          : DropTarget(
                              onDragDone: (detail) async {
                                if (detail.files.isNotEmpty) {
                                  await _handleDroppedFile(detail.files.first);
                                }
                              },
                              onDragEntered: (_) {
                                setState(() => _isDragging = true);
                              },
                              onDragExited: (_) {
                                setState(() => _isDragging = false);
                              },
                              child: _buildDropArea(),
                            ),
                    ),
                  ],
                ),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isUploading
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _canUpload ? _upload : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Yükle',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShoeInfoFields() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final brandField = TextField(
            controller: _shoeBrandController,
            enabled: !_isUploading,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (mounted) setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Ayakkabı Markası',
              hintText: 'Örn. Nike',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          );

          final modelField = TextField(
            controller: _shoeModelController,
            enabled: !_isUploading,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (mounted) setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Ayakkabı Modeli',
              hintText: 'Örn. Air Zoom Pegasus',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          );

          final sizeField = TextField(
            controller: _shoeSizeController,
            enabled: !_isUploading,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text,
            onChanged: (_) {
              if (mounted) setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Ayakkabı Numarası',
              hintText: 'Örn. 42 / 42.5',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.directions_run_outlined,
                    color: Colors.teal,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Ayakkabı Bilgisi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isNarrow)
                Column(
                  children: [
                    brandField,
                    const SizedBox(height: 10),
                    modelField,
                    const SizedBox(height: 10),
                    sizeField,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: brandField),
                    const SizedBox(width: 10),
                    Expanded(child: modelField),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: sizeField,
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Text(
                'Bu bilgi referans iç taban fotoğrafıyla birlikte kaydedilir.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplatePreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Örnek Fotoğraf',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İç tabanı aşağıdaki örneğe benzer şekilde fotoğraflayın.',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/analysis/insole_photo_template.png',
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isDragging
            ? Colors.teal.withOpacity(0.10)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDragging ? Colors.teal : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: !_hasFile
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 56,
                      color: Colors.teal.shade600,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dosyayı buraya sürükleyip bırakın',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'veya aşağıdaki butonla seçin',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      icon: const Icon(
                        Icons.folder_open,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Dosya Seç',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _isUploading ? null : _clearFile,
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                  if (_localFilePath != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _localFilePath!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _fileBytes!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}