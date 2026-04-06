import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/services/file_bytes_helper.dart';

class InsolePhotoUploadDialog extends StatefulWidget {
  const InsolePhotoUploadDialog({super.key});

  @override
  State<InsolePhotoUploadDialog> createState() =>
      _InsolePhotoUploadDialogState();
}

class _InsolePhotoUploadDialogState extends State<InsolePhotoUploadDialog> {
  Uint8List? _fileBytes;
  String? _fileName;
  bool _isDragging = false;
  bool _isUploading = false;

  bool get _hasFile => _fileBytes != null;

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

    // On desktop, bytes may be null — read from path.
    if (bytes == null && file.path != null) {
      bytes = await readBytesFromPath(file.path!);
    }

    if (bytes == null) return;

    setState(() {
      _fileBytes = bytes;
      _fileName = file.name;
    });
  }

  Future<void> _upload() async {
    if (_fileBytes == null) return;

    setState(() => _isUploading = true);

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() => _isUploading = false);

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 700,
          maxHeight: 720,
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
                    Text('• İç tabanı ölçekli / antetli A4 kağıt üzerine yerleştirin.'),
                    SizedBox(height: 4),
                    Text('• Alternatif olarak A4 üzerine ortalayın, üst köşeye yakın ve alt köşeye yakın 1 TL ile fotoğraflayın.'),
                    SizedBox(height: 4),
                    Text('• Fotoğraf net, üstten çekilmiş ve kenarlar görünür olmalı.'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: kIsWeb
                    ? _buildDropArea()
                    : DropTarget(
                        onDragDone: (detail) async {
                          if (detail.files.isNotEmpty) {
                            final f = detail.files.first;
                            final bytes = await readBytesFromPath(f.path);
                            if (bytes != null && mounted) {
                              setState(() {
                                _fileBytes = bytes;
                                _fileName = f.name;
                              });
                            }
                          }
                        },
                        onDragEntered: (_) =>
                            setState(() => _isDragging = true),
                        onDragExited: (_) =>
                            setState(() => _isDragging = false),
                        child: _buildDropArea(),
                      ),
              ),

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
                    onPressed: (!_hasFile || _isUploading) ? null : _upload,
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
                    Icon(Icons.cloud_upload,
                        size: 56, color: Colors.teal.shade600),
                    const SizedBox(height: 12),
                    const Text(
                      'Dosyayı buraya sürükleyip bırakın',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text('veya aşağıdaki butonla seçin',
                        style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal),
                      icon: const Icon(Icons.folder_open,
                          color: Colors.white),
                      label: const Text('Dosya Seç',
                          style: TextStyle(color: Colors.white)),
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
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _fileBytes = null;
                          _fileName = null;
                        }),
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
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
