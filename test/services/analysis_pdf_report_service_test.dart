import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/report/analysis_pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a Turkish comparison PDF report', () async {
    final service = AnalysisPdfReportService();
    final result = CustomerAnalysisResult(
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
        leftInsoleRecommendation: 'Medial ark destekli kişisel tabanlık.',
        rightInsoleRecommendation: 'Dengeli günlük kullanım tabanlığı.',
      ),
    );

    final bytes = await service.buildReport(
      result: result,
      pageTitle: 'Ayak Sağlığı Değerlendirmesi',
      imageUrls: const {},
      imageBytes: {
        'arch_left_image': await File(
          'assets/mock_data/mock_3d_data/arch_L.bmp',
        ).readAsBytes(),
        'arch_right_image': await File(
          'assets/mock_data/mock_3d_data/arch_R.bmp',
        ).readAsBytes(),
        'pronator_left': await File(
          'assets/mock_data/mock_3d_data/pronatorL.bmp',
        ).readAsBytes(),
        'pronator_right': await File(
          'assets/mock_data/mock_3d_data/pronatorR.bmp',
        ).readAsBytes(),
      },
    );

    expect(bytes.length, greaterThan(10000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    const qaOutput = String.fromEnvironment('ANALYSIS_PDF_QA_OUTPUT');
    if (qaOutput.isNotEmpty) {
      final file = File(qaOutput);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  });
}
