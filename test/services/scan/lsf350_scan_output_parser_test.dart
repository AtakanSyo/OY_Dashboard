import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/services/scan/lsf350_scan_output_parser.dart';

void main() {
  test(
    'classifies LSF350 output files by report, preview, stl and archives',
    () {
      final tempDir = Directory.systemTemp.createTempSync(
        'lsf350_parser_test_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));

      File('${tempDir.path}/analysis_report.pdf').writeAsStringSync('pdf');
      File('${tempDir.path}/raw_export.doc').writeAsStringSync('doc');
      File('${tempDir.path}/foot_left.bmp').writeAsStringSync('left image');
      File('${tempDir.path}/foot_right.bmp').writeAsStringSync('right image');
      File('${tempDir.path}/scan_l.stl').writeAsStringSync('left stl');
      File('${tempDir.path}/scan_r.stl').writeAsStringSync('right stl');
      File('${tempDir.path}/models.zip').writeAsStringSync('zip');

      final result = const Lsf350ScanOutputParser().parseFolder(tempDir.path);

      expect(result.folderExists, isTrue);
      expect(result.detectedFileCount, 7);
      expect(result.reportPdfPath, endsWith('analysis_report.pdf'));
      expect(result.reportDocumentPath, endsWith('raw_export.doc'));
      expect(result.leftPreviewImagePath, endsWith('foot_left.bmp'));
      expect(result.rightPreviewImagePath, endsWith('foot_right.bmp'));
      expect(result.leftStlPath, endsWith('scan_l.stl'));
      expect(result.rightStlPath, endsWith('scan_r.stl'));
      expect(result.stlArchivePaths.single, endsWith('models.zip'));
      expect(result.hasAnyOutput, isTrue);
      expect(result.toSessionScanAssets().stlLeftPath, result.leftStlPath);
    },
  );

  test('assigns two unlabelled stl files as left and right fallback', () {
    final tempDir = Directory.systemTemp.createTempSync('lsf350_parser_pair_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    File('${tempDir.path}/001.stl').writeAsStringSync('first');
    File('${tempDir.path}/002.stl').writeAsStringSync('second');

    final result = const Lsf350ScanOutputParser().parseFolder(tempDir.path);

    expect(result.leftStlPath, endsWith('001.stl'));
    expect(result.rightStlPath, endsWith('002.stl'));
  });

  test('returns an empty result for missing folders', () {
    final result = const Lsf350ScanOutputParser().parseFolder(
      '${Directory.systemTemp.path}/missing_lsf350_folder_for_test',
    );

    expect(result.folderExists, isFalse);
    expect(result.hasAnyOutput, isFalse);
    expect(result.detectedFileCount, 0);
  });
}
