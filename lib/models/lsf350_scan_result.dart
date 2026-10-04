import 'package:oy_site/models/session_scan_assets.dart';

class Lsf350ScanResult {
  final String folderPath;
  final bool folderExists;
  final List<String> allFilePaths;
  final String? reportPdfPath;
  final String? reportDocumentPath;
  final List<String> previewImagePaths;
  final String? leftPreviewImagePath;
  final String? rightPreviewImagePath;
  final List<String> stlFilePaths;
  final String? leftStlPath;
  final String? rightStlPath;
  final List<String> stlArchivePaths;

  const Lsf350ScanResult({
    required this.folderPath,
    required this.folderExists,
    required this.allFilePaths,
    this.reportPdfPath,
    this.reportDocumentPath,
    required this.previewImagePaths,
    this.leftPreviewImagePath,
    this.rightPreviewImagePath,
    required this.stlFilePaths,
    this.leftStlPath,
    this.rightStlPath,
    required this.stlArchivePaths,
  });

  bool get hasReport => reportPdfPath != null || reportDocumentPath != null;

  bool get hasPreviewImages => previewImagePaths.isNotEmpty;

  bool get hasStlModels =>
      stlFilePaths.isNotEmpty || leftStlPath != null || rightStlPath != null;

  bool get hasModelArchives => stlArchivePaths.isNotEmpty;

  bool get hasAnyOutput =>
      hasReport || hasPreviewImages || hasStlModels || hasModelArchives;

  int get detectedFileCount => allFilePaths.length;

  SessionScanAssets toSessionScanAssets() {
    return SessionScanAssets(
      folderPath: folderPath,
      foot2dLeftPath: leftPreviewImagePath,
      foot2dRightPath: rightPreviewImagePath,
      stlLeftPath: leftStlPath,
      stlRightPath: rightStlPath,
    );
  }
}
