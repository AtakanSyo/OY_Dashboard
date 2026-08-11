import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/scan/legacy_doc_text_extractor.dart';
import 'package:oy_site/services/scan/scan_report_word_parser_service.dart';

void main() {
  const fixturePath = 'assets/mock_data/mock_3d_data/qq_121_232605.doc';

  test(
    'extracts mixed UTF-16 and ANSI text from a legacy DOC report',
    () async {
      final text = await const LegacyDocTextExtractor().extractText(
        fixturePath,
      );

      expect(text, contains('No.\n20251104001'));
      expect(text, contains('Foot length\n250.8\n248.8'));
      expect(text, contains('Sole length\n242.0\n239.9'));
      expect(text, contains('Arch height\n13.5\n12.4'));
    },
  );

  test('parses the legacy DOC report into structured scan values', () async {
    final report = await const ScanReportWordParserService().parseWordFile(
      fixturePath,
    );

    expect(report.reportNo, '20251104001');
    expect(report.reportDate, '2025-11-04');
    expect(report.reportTime, '23:26:05');
    expect(report.customerName, 'qq');
    expect(report.leftFootLength, 250.8);
    expect(report.rightFootLength, 248.8);
    expect(report.leftSoleLength, 242.0);
    expect(report.rightSoleLength, 239.9);
    expect(report.leftFootWidth, 102.4);
    expect(report.rightFootWidth, 101.8);
    expect(report.leftArchHeight, 13.5);
    expect(report.rightArchHeight, 12.4);
    expect(report.leftHalluxAngle, -2.4);
    expect(report.rightHalluxAngle, 1.1);
    expect(report.leftPronatorAngle, 2.2);
    expect(report.rightPronatorAngle, -0.6);
    expect(report.leftKneeAngle, 0.6);
    expect(report.rightKneeAngle, -2.3);
    expect(report.leftArchType, 'Severe Flat');
    expect(report.rightArchType, 'Severe Flat');
    expect(report.leftArchIndex, 0.326);
    expect(report.rightArchIndex, 0.306);
    expect(report.leftArchWidthIndex, 0.462);
    expect(report.rightArchWidthIndex, 0.341);
    expect(report.leftHalluxType, startsWith('Normal'));
    expect(report.rightHalluxType, startsWith('Normal'));
    expect(report.leftHeelType, startsWith('Normal'));
    expect(report.rightHeelType, startsWith('Normal'));
    expect(report.leftKneeType, startsWith('Normal'));
    expect(report.rightKneeType, startsWith('Normal'));
    expect(report.leftToeWidth, 100.4);
    expect(report.rightToeWidth, 99.0);
    expect(report.leftArchLength, 102.8);
    expect(report.rightArchLength, 102.1);
  });

  test('merges stored session fields without losing analysis measurements', () {
    final stored = ParsedScanReport.fromMap({
      'left_pronator_angle': 2.2,
      'right_knee_angle': -2.3,
    });
    const analysis = ParsedScanReport(
      leftFootLength: 250.8,
      rightFootLength: 248.8,
      leftSoleLength: 242.0,
    );

    final merged = ParsedScanReport.merge(
      preferred: stored,
      fallback: analysis,
    );

    expect(merged.leftFootLength, 250.8);
    expect(merged.rightFootLength, 248.8);
    expect(merged.leftSoleLength, 242.0);
    expect(merged.leftPronatorAngle, 2.2);
    expect(merged.rightKneeAngle, -2.3);
  });
}
