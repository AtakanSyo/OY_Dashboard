import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ScanFolderUploadResult {
  final String folderPath;
  final List<String> fileNames;

  const ScanFolderUploadResult({
    required this.folderPath,
    required this.fileNames,
  });
}

class ScanFolderUploadDialog extends StatefulWidget {
  const ScanFolderUploadDialog({super.key});

  @override
  State<ScanFolderUploadDialog> createState() => _ScanFolderUploadDialogState();
}

class _ScanFolderUploadDialogState extends State<ScanFolderUploadDialog> {
  String? _selectedFolderPath;
  List<String> _fileNames = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickFolder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final folderPath = await FilePicker.getDirectoryPath(
        dialogTitle: '3D tarama klasörünü seç',
      );

      if (folderPath == null || folderPath.trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dir = Directory(folderPath);

      if (!dir.existsSync()) {
        setState(() {
          _errorMessage = 'Seçilen klasör bulunamadı.';
          _isLoading = false;
        });
        return;
      }

      final entries = dir.listSync();
      final fileNames = entries
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toList()
        ..sort();

      setState(() {
        _selectedFolderPath = folderPath;
        _fileNames = fileNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Klasör seçilirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedFolderPath == null) return;

    Navigator.pop(
      context,
      ScanFolderUploadResult(
        folderPath: _selectedFolderPath!,
        fileNames: _fileNames,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 760,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '3D Tarama Klasörü Yükle',
                      style: TextStyle(
                        fontSize: 22,
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
              const SizedBox(height: 8),
              Text(
                '3D tarama yazılımından aldığın klasör çıktısını seçebilirsin. Şimdilik klasör yolu ve içerdiği dosyalar önizlenecek.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Klasör Seç'),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedFolderPath != null)
                    Expanded(
                      child: Text(
                        _selectedFolderPath!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _fileNames.isEmpty
                        ? Center(
                            child: Text(
                              'Henüz klasör seçilmedi.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bulunan dosyalar (${_fileNames.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _fileNames.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final fileName = _fileNames[index];

                                    return Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.insert_drive_file_outlined,
                                            color: Colors.teal,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              fileName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedFolderPath == null
                        ? null
                        : _confirmSelection,
                    child: const Text('Yüklemeyi Onayla'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}