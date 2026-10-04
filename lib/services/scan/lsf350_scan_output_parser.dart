import 'dart:io';

import 'package:oy_site/models/lsf350_scan_result.dart';

class Lsf350ScanOutputParser {
  const Lsf350ScanOutputParser();

  Lsf350ScanResult parseFolder(String folderPath, {bool recursive = true}) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      return Lsf350ScanResult(
        folderPath: folderPath,
        folderExists: false,
        allFilePaths: const [],
        previewImagePaths: const [],
        stlFilePaths: const [],
        stlArchivePaths: const [],
      );
    }

    final files = _listFiles(dir, recursive: recursive);
    final sortedFiles = [...files]
      ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

    final imagePaths = <String>[];
    final stlPaths = <String>[];
    final archivePaths = <String>[];
    final pdfPaths = <String>[];
    final documentPaths = <String>[];

    for (final file in sortedFiles) {
      final extension = _extensionOf(file.path);
      switch (extension) {
        case '.bmp':
        case '.png':
        case '.jpg':
        case '.jpeg':
        case '.webp':
          imagePaths.add(file.path);
        case '.stl':
          stlPaths.add(file.path);
        case '.zip':
          archivePaths.add(file.path);
        case '.pdf':
          pdfPaths.add(file.path);
        case '.doc':
        case '.docx':
        case '.rtf':
          documentPaths.add(file.path);
      }
    }

    final stlBySide = _pickSideFiles(stlPaths);
    final imageBySide = _pickSideFiles(imagePaths);

    return Lsf350ScanResult(
      folderPath: folderPath,
      folderExists: true,
      allFilePaths: sortedFiles.map((file) => file.path).toList(),
      reportPdfPath: _preferReportFile(pdfPaths),
      reportDocumentPath: _preferReportFile(documentPaths),
      previewImagePaths: imagePaths,
      leftPreviewImagePath: imageBySide.left,
      rightPreviewImagePath: imageBySide.right,
      stlFilePaths: stlPaths,
      leftStlPath: stlBySide.left,
      rightStlPath: stlBySide.right,
      stlArchivePaths: archivePaths,
    );
  }

  List<File> _listFiles(Directory dir, {required bool recursive}) {
    return dir
        .listSync(recursive: recursive, followLinks: false)
        .whereType<File>()
        .toList();
  }

  String? _preferReportFile(List<String> paths) {
    if (paths.isEmpty) return null;
    final preferred = paths.where((path) {
      final name = _fileName(path).toLowerCase();
      return name.contains('report') ||
          name.contains('rapor') ||
          name.contains('analysis') ||
          name.contains('analiz') ||
          name.contains('result') ||
          name.contains('sonuc') ||
          name.contains('sonuç');
    }).toList();
    return (preferred.isEmpty ? paths : preferred).first;
  }

  _SideFiles _pickSideFiles(List<String> paths) {
    if (paths.isEmpty) return const _SideFiles();

    String? left;
    String? right;

    for (final path in paths) {
      final name = _fileNameWithoutExtension(path).toLowerCase();
      if (left == null && _looksLeft(name)) {
        left = path;
        continue;
      }
      if (right == null && _looksRight(name)) {
        right = path;
      }
    }

    if ((left == null || right == null) && paths.length == 2) {
      left ??= paths.first;
      right ??= paths.last;
    }

    return _SideFiles(left: left, right: right);
  }

  bool _looksLeft(String name) {
    return name.contains('left') ||
        name.contains('sol') ||
        RegExp(r'(^|[_\-\s\(])l($|[_\-\s\)])').hasMatch(name) ||
        name.endsWith('_l') ||
        name.endsWith('-l');
  }

  bool _looksRight(String name) {
    return name.contains('right') ||
        name.contains('sag') ||
        name.contains('sağ') ||
        RegExp(r'(^|[_\-\s\(])r($|[_\-\s\)])').hasMatch(name) ||
        name.endsWith('_r') ||
        name.endsWith('-r');
  }

  String _extensionOf(String path) {
    final name = _fileName(path);
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '';
    return name.substring(dot).toLowerCase();
  }

  String _fileNameWithoutExtension(String path) {
    final name = _fileName(path);
    final dot = name.lastIndexOf('.');
    if (dot < 0) return name;
    return name.substring(0, dot);
  }

  String _fileName(String path) {
    return File(path).uri.pathSegments.last;
  }
}

class _SideFiles {
  final String? left;
  final String? right;

  const _SideFiles({this.left, this.right});
}
