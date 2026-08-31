import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/report/analysis_pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'builds a Turkish assessment PDF matching the analysis screen',
    () async {
      final bytes = await _buildSampleReport(languageCode: 'tr');

      expect(bytes.length, greaterThan(100000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');

      const qaOutput = String.fromEnvironment('ANALYSIS_PDF_QA_OUTPUT');
      if (qaOutput.isNotEmpty) {
        final file = File(qaOutput);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      }
    },
  );

  test('builds the same assessment PDF in English', () async {
    final bytes = await _buildSampleReport(languageCode: 'en');

    expect(bytes.length, greaterThan(100000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

Future<List<int>> _buildSampleReport({required String languageCode}) async {
  final service = AnalysisPdfReportService();
  return service.buildReport(
    result: _sampleResult(),
    pageTitle: languageCode == 'en'
        ? 'Assessment Results'
        : 'Değerlendirme Sonuçları',
    languageCode: languageCode,
    imageUrls: const {},
    imageBytes: {
      'arch_left_image': await File(
        'assets/mock_data/mock_3d_data/arch_L.bmp',
      ).readAsBytes(),
      'arch_right_image': await File(
        'assets/mock_data/mock_3d_data/arch_R.bmp',
      ).readAsBytes(),
      'arch_section_left': await File(
        'assets/mock_data/mock_3d_data/archSectV_L.bmp',
      ).readAsBytes(),
      'arch_section_right': await File(
        'assets/mock_data/mock_3d_data/archSectV_R.bmp',
      ).readAsBytes(),
      'foot_2d_left': await File(
        'assets/mock_data/mock_3d_data/foot3d_L.bmp',
      ).readAsBytes(),
      'foot_2d_right': await File(
        'assets/mock_data/mock_3d_data/foot3d_R.bmp',
      ).readAsBytes(),
      'pronator_left': await File(
        'assets/mock_data/mock_3d_data/pronatorL.bmp',
      ).readAsBytes(),
      'pronator_right': await File(
        'assets/mock_data/mock_3d_data/pronatorR.bmp',
      ).readAsBytes(),
    },
    pressureSnapshot: AnalysisPdfPressureSnapshot(
      matrix: _samplePressureMatrix(),
      maxVisualValue: 900,
      threshold: 16,
      weightKg: 72.5,
      cellAreaCm2: (452 / 64) * (344 / 32) / 100,
    ),
  );
}

CustomerAnalysisResult _sampleResult() {
  return CustomerAnalysisResult(
    sessionId: 42,
    sessionCode: 'QA-2026-001',
    locationLabel: 'İstanbul Ölçüm Merkezi',
    analysisDate: DateTime(2026, 8, 10, 14, 30),
    overallSummary:
        'Sol ve sağ ayak birlikte değerlendirilmiş, karşılaştırmalı sonuçlar raporlanmıştır.',
    generalRiskNote:
        'Bu rapor klinik muayenenin yerine geçmez; uzman değerlendirmesi ile birlikte ele alınmalıdır.',
    leftFoot: const CustomerFootSummary(
      side: 'left',
      footType: 'Düşük ark',
      pressureSummary: 'Ön ayak yükü artmış.',
      balanceSummary: 'Hafif içe basma eğilimi görülüyor.',
      archSupportNeed: 'Medial ark desteği önerilir.',
      mainFinding: 'Sol ayakta hafif pronasyon gözlendi.',
      pressureScore: 68,
      stabilityScore: 74,
      archScore: 62,
    ),
    rightFoot: const CustomerFootSummary(
      side: 'right',
      footType: 'Normal ark',
      pressureSummary: 'Yük dağılımı dengeli.',
      balanceSummary: 'Nötr hizalanma görülüyor.',
      archSupportNeed: 'Standart destek yeterli.',
      mainFinding: 'Sağ ayakta belirgin risk görülmedi.',
      pressureScore: 82,
      stabilityScore: 86,
      archScore: 80,
    ),
    metrics: const [],
    recommendations: const [],
    visuals: const CustomerAnalysisVisualSet(sessionCode: 'QA-2026-001'),
    parsedReport: const ParsedScanReport(
      customerName: 'Çağla Öztürk',
      leftFootLength: 252.4,
      rightFootLength: 254.1,
      leftSoleLength: 238.2,
      rightSoleLength: 240.0,
      leftFootWidth: 98.7,
      rightFootWidth: 97.9,
      leftToeWidth: 91.5,
      rightToeWidth: 90.8,
      leftArchLength: 168.2,
      rightArchLength: 170.1,
      leftArchHeight: 21.4,
      rightArchHeight: 25.9,
      leftArchOutsideWidth: 55.2,
      rightArchOutsideWidth: 54.8,
      leftTotalHeelWidth: 64.1,
      rightTotalHeelWidth: 63.7,
      leftFirstMetaLength: 71.3,
      rightFirstMetaLength: 72.0,
      leftFifthMetaLength: 64.6,
      rightFifthMetaLength: 65.1,
      leftFirstMetaJointHeight: 34.2,
      rightFirstMetaJointHeight: 35.0,
      leftShoeSize: '40',
      rightShoeSize: '40',
      leftArchType: 'Düşük ark',
      rightArchType: 'Normal ark',
      leftArchIndex: 0.318,
      rightArchIndex: 0.247,
      leftArchWidthIndex: 0.421,
      rightArchWidthIndex: 0.366,
      leftHalluxAngle: 11.8,
      rightHalluxAngle: 7.2,
      leftHalluxType: 'Hafif valgus',
      rightHalluxType: 'Normal',
      leftPronatorAngle: 8.4,
      rightPronatorAngle: 3.1,
      leftHeelType: 'Hafif valgus',
      rightHeelType: 'Nötr',
      leftKneeAngle: 4.3,
      rightKneeAngle: 2.2,
      leftKneeType: 'Hafif iç rotasyon',
      rightKneeType: 'Nötr',
    ),
  );
}

List<List<double>> _samplePressureMatrix() {
  return List.generate(32, (row) {
    return List.generate(64, (column) {
      final leftHeel = _gaussian(column, row, 18, 7, 4.2, 4.6, 680);
      final leftForefoot = _gaussian(column, row, 17, 23, 5.5, 5.0, 820);
      final leftToe = _gaussian(column, row, 20, 29, 2.8, 2.4, 540);
      final rightHeel = _gaussian(column, row, 45, 7, 4.3, 4.7, 610);
      final rightForefoot = _gaussian(column, row, 46, 23, 5.7, 5.1, 760);
      final rightToe = _gaussian(column, row, 43, 29, 2.8, 2.4, 500);
      return leftHeel +
          leftForefoot +
          leftToe +
          rightHeel +
          rightForefoot +
          rightToe;
    });
  });
}

double _gaussian(
  int x,
  int y,
  double centerX,
  double centerY,
  double sigmaX,
  double sigmaY,
  double amplitude,
) {
  final dx = (x - centerX) / sigmaX;
  final dy = (y - centerY) / sigmaY;
  return amplitude * math.exp(-0.5 * (dx * dx + dy * dy));
}
