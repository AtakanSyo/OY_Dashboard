import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/scan/legacy_doc_text_extractor.dart';
import 'package:oy_site/services/scan/scan_report_text_parser.dart';
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
    expect(report.leftHeelCenterLength, 39.0);
    expect(report.rightHeelCenterLength, 39.0);
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

  test('parses comma decimals, degree signs, and Hallux label variants', () {
    const rawText = '''
      Foot width 100,0 100,0
      Arch outside width 46,2 34,1
      46,2% Arch width ratio 34,1%
      Normal Hallux valgus Type Mild
      −2,4° Hallux valgus angle(°) 11,1°
    ''';

    final report = const ScanReportTextParser().parse(rawText);

    expect(report.leftArchWidthIndex, closeTo(0.462, 0.0001));
    expect(report.rightArchWidthIndex, closeTo(0.341, 0.0001));
    expect(report.leftHalluxAngle, -2.4);
    expect(report.rightHalluxAngle, 11.1);
    expect(report.leftHalluxType, 'Normal');
    expect(report.rightHalluxType, 'Mild');
  });

  test('calculates arch width index when the report omits its index row', () {
    const rawText = '''
      Foot width 100,0 100,0
      Arch outside width 46,2 34,1
    ''';

    final report = const ScanReportTextParser().parse(rawText);

    expect(report.leftArchWidthIndex, closeTo(0.462, 0.0001));
    expect(report.rightArchWidthIndex, closeTo(0.341, 0.0001));
  });

  test('parses Hallux angles separated from their label by side captions', () {
    const labelFirstText = '''
      Hallux valgus angle(°)
      Left foot −2,4°
      Right foot 11,1°
      Evaluation criteria Normal: 0-10 Mild: 10-20
    ''';
    const labelBetweenText = '''
      Left foot −3,2° Hallux deviation angle(°) Right foot 12,4°
      Evaluation criteria Normal: 0-10 Mild: 10-20
    ''';

    final labelFirst = const ScanReportTextParser().parse(labelFirstText);
    final labelBetween = const ScanReportTextParser().parse(labelBetweenText);

    expect(labelFirst.leftHalluxAngle, -2.4);
    expect(labelFirst.rightHalluxAngle, 11.1);
    expect(labelBetween.leftHalluxAngle, -3.2);
    expect(labelBetween.rightHalluxAngle, 12.4);
  });

  test('recovers identical Hallux angles collapsed in previously stored text', () {
    const rawText = '''
      Hallux angle 7,5
      Pronator angle 2,0 3,0
      Knee angle 1,0 1,5
    ''';

    final report = const ScanReportTextParser().parse(rawText);

    expect(report.leftHalluxAngle, 7.5);
    expect(report.rightHalluxAngle, 7.5);
  });

  test('parses alternate Thumb angle and Arch width factor labels', () {
    const rawText = '''
      Thumb angle -4,2 13,6
      Arch width factor 3,2 0,372
    ''';

    final report = const ScanReportTextParser().parse(rawText);

    expect(report.leftHalluxAngle, -4.2);
    expect(report.rightHalluxAngle, 13.6);
    expect(report.leftArchWidthIndex, closeTo(3.2, 0.0001));
    expect(report.rightArchWidthIndex, closeTo(0.372, 0.0001));
  });
}
