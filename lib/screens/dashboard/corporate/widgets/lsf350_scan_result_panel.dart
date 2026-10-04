import 'dart:io';

import 'package:flutter/material.dart';
import 'package:oy_site/models/lsf350_scan_result.dart';

class Lsf350ScanResultPanel extends StatelessWidget {
  final Lsf350ScanResult result;
  final ValueChanged<String> onOpenPath;

  const Lsf350ScanResultPanel({
    super.key,
    required this.result,
    required this.onOpenPath,
  });

  @override
  Widget build(BuildContext context) {
    if (!result.folderExists) {
      return _EmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Klasör bulunamadı',
        message: result.folderPath,
      );
    }

    if (!result.hasAnyOutput) {
      return _EmptyState(
        icon: Icons.insert_drive_file_outlined,
        title: 'Tarama çıktısı bulunamadı',
        message: result.folderPath,
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _ResultSummary(result: result),
        const SizedBox(height: 12),
        _PreviewRow(result: result),
        const SizedBox(height: 12),
        _GeneratedFilesList(result: result, onOpenPath: onOpenPath),
      ],
    );
  }
}

class _ResultSummary extends StatelessWidget {
  final Lsf350ScanResult result;

  const _ResultSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Metric(
        icon: Icons.picture_as_pdf_outlined,
        label: 'Rapor',
        value: result.hasReport ? 'Hazır' : 'Yok',
        active: result.hasReport,
      ),
      _Metric(
        icon: Icons.image_outlined,
        label: 'Görsel',
        value: result.previewImagePaths.length.toString(),
        active: result.hasPreviewImages,
      ),
      _Metric(
        icon: Icons.view_in_ar_outlined,
        label: '3D Model',
        value: result.stlFilePaths.length.toString(),
        active: result.hasStlModels,
      ),
      _Metric(
        icon: Icons.folder_zip_outlined,
        label: 'Arşiv',
        value: result.stlArchivePaths.length.toString(),
        active: result.hasModelArchives,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tarama çıktısı',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '${result.detectedFileCount} dosya',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.folderPath,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map(_MetricTile.new).toList(),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final Lsf350ScanResult result;

  const _PreviewRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final previews = <({String label, String? path})>[
      (label: 'Sol ayak', path: result.leftPreviewImagePath),
      (label: 'Sağ ayak', path: result.rightPreviewImagePath),
    ].where((item) => item.path != null).toList();

    if (previews.isEmpty) return const SizedBox.shrink();

    return Row(
      children: previews.map((preview) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: preview == previews.last ? 0 : 12),
            child: _LocalImagePreview(
              label: preview.label,
              path: preview.path!,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LocalImagePreview extends StatelessWidget {
  final String label;
  final String path;

  const _LocalImagePreview({required this.label, required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Center(
              child: Text(
                'Önizleme açılamadı',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeneratedFilesList extends StatelessWidget {
  final Lsf350ScanResult result;
  final ValueChanged<String> onOpenPath;

  const _GeneratedFilesList({required this.result, required this.onOpenPath});

  @override
  Widget build(BuildContext context) {
    final paths = result.allFilePaths;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 130, maxHeight: 280),
      decoration: _panelDecoration(),
      child: paths.isEmpty
          ? Center(
              child: Text(
                'Dosya bulunamadı.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: paths.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final path = paths[index];
                final extension = _extensionOf(path);
                return ListTile(
                  dense: true,
                  leading: Icon(_iconFor(extension)),
                  title: Text(_fileName(path), overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${_formatSize(path)} • $path',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => onOpenPath(path),
                );
              },
            ),
    );
  }
}

class _Metric {
  final IconData icon;
  final String label;
  final String value;
  final bool active;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
  });
}

class _MetricTile extends StatelessWidget {
  final _Metric metric;

  const _MetricTile(this.metric);

  @override
  Widget build(BuildContext context) {
    final color = metric.active ? const Color(0xFF087F73) : Colors.grey[600]!;
    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: metric.active ? const Color(0xFFE7F7F4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: metric.active
              ? const Color(0xFFB7E6DE)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                Text(
                  metric.value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.grey[500]),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFFF9FAFB),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE5E7EB)),
  );
}

IconData _iconFor(String extension) {
  switch (extension.toLowerCase()) {
    case '.pdf':
      return Icons.picture_as_pdf_outlined;
    case '.bmp':
    case '.png':
    case '.jpg':
    case '.jpeg':
      return Icons.image_outlined;
    case '.zip':
      return Icons.folder_zip_outlined;
    case '.stl':
      return Icons.view_in_ar_outlined;
    case '.doc':
    case '.docx':
      return Icons.description_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

String _fileName(String path) {
  try {
    return File(path).uri.pathSegments.last;
  } catch (_) {
    final normalized = path.replaceAll('\\', '/');
    final index = normalized.lastIndexOf('/');
    return index < 0 ? normalized : normalized.substring(index + 1);
  }
}

String _extensionOf(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf('.');
  if (dot < 0) return '';
  return name.substring(dot).toLowerCase();
}

String _formatSize(String path) {
  try {
    final bytes = File(path).statSync().size;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  } catch (_) {
    return 'Boyut okunamadı';
  }
}
