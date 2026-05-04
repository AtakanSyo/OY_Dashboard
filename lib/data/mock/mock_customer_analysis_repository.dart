import 'dart:async';

import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/session_scan_assets.dart';
import 'package:oy_site/services/scan/session_scan_assets_parser.dart';
import 'package:oy_site/models/parsed_scan_report.dart';

class MockCustomerAnalysisRepository {
  final SessionScanAssetsParser _parser = const SessionScanAssetsParser();

  Future<CustomerAnalysisResult> getLatestAnalysis({
    required int userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    // Geçici local test klasörü:
    const localScanFolderPath =
        r'C:\dev_projects\oy_dashboard_dev_project\OY_Dashboard\assets\mock_data\mock_3d_data';

    final SessionScanAssets assets =
        _parser.parseFolder(localScanFolderPath);

    return CustomerAnalysisResult(
      sessionCode: 'SES-2026-0408',
      locationLabel: 'OptiYou İzmir',
      analysisDate: DateTime(2026, 4, 8),
      overallSummary:
          'Ayak analizinizde her iki ayakta da ark desteği ihtiyacı ve uzun süreli yüklenmede yorgunluk artışı görülmektedir. Sol ayakta basınç yoğunluğu sağ ayağa göre biraz daha fazladır.',
      generalRiskNote:
          'Uzun süre ayakta kalma ve sert zemin kullanımı gün sonunda konfor kaybını artırabilir.',
      leftFoot: const CustomerFootSummary(
        side: 'left',
        footType: 'Düz taban eğilimi',
        pressureSummary: 'Topuk ve ön ayakta yük artışı',
        balanceSummary: 'Sol ayakta yük biraz daha fazla',
        archSupportNeed: 'Orta-Yüksek',
        mainFinding: 'Kemer desteği ihtiyacı belirgin',
        pressureScore: 78,
        stabilityScore: 64,
        archScore: 42,
      ),
      rightFoot: const CustomerFootSummary(
        side: 'right',
        footType: 'Nötr - hafif destek ihtiyacı',
        pressureSummary: 'Ön ayakta orta düzey yüklenme',
        balanceSummary: 'Sağ ayakta denge daha iyi',
        archSupportNeed: 'Orta',
        mainFinding: 'Uzun süreli kullanımlarda destek önerilir',
        pressureScore: 69,
        stabilityScore: 72,
        archScore: 56,
      ),
      metrics: const [
        CustomerAnalysisMetric(
          label: 'Sol / Sağ Denge',
          value: '%54 / %46',
          description: 'Yük dağılımı sol ayağa biraz daha fazladır.',
        ),
        CustomerAnalysisMetric(
          label: 'Maksimum Basınç Bölgesi',
          value: 'Topuk',
          description: 'En yüksek yük topuk bölgesinde görülmektedir.',
        ),
        CustomerAnalysisMetric(
          label: 'Ark Desteği İhtiyacı',
          value: 'Belirgin',
          description: 'Kemer desteği konforu artırabilir.',
        ),
        CustomerAnalysisMetric(
          label: 'Gün Sonu Yorgunluk Riski',
          value: 'Orta',
          description: 'Uzun süre ayakta kalmada rahatsızlık artabilir.',
        ),
      ],
      recommendations: const [
        CustomerRecommendationItem(
          title: 'Kemer destekli iç taban önerilir',
          description:
              'Özellikle uzun süre ayakta kaldığınız günlerde konforu artırabilir.',
        ),
        CustomerRecommendationItem(
          title: 'Topuk yükünü dağıtan yapı tercih edilmeli',
          description:
              'Topuk bölgesindeki yoğun basıncı azaltmaya yardımcı olabilir.',
        ),
        CustomerRecommendationItem(
          title: 'Günlük ve iş kullanımına uygun destek seçimi',
          description:
              'Sert zemin kullanımı için destekleyici ürünler daha uygun olabilir.',
        ),
      ],
      visuals: CustomerAnalysisVisualSet(
        sessionCode: 'SES-2026-0408',
        archLeftImagePath: assets.archLeftPath,
        archRightImagePath: assets.archRightPath,
        archSectionLeftImagePath: assets.archSectionLeftPath,
        archSectionRightImagePath: assets.archSectionRightPath,
        foot2dLeftImagePath: assets.foot2dLeftPath,
        foot2dRightImagePath: assets.foot2dRightPath,
        pronatorLeftImagePath: assets.pronatorLeftPath,
        pronatorRightImagePath: assets.pronatorRightPath,
        leftStlPath: assets.stlLeftPath,
        rightStlPath: assets.stlRightPath,
      ),

      parsedReport: _buildMockParsedReport(
        reportNo: '20251104001',
        reportDate: '2025-11-04',
        reportTime: '23:26:05',
        leftFootLength: 250.8,
        rightFootLength: 248.8,
        leftFootWidth: 102.4,
        rightFootWidth: 101.8,
        leftArchHeight: 13.5,
        rightArchHeight: 12.4,
        leftHalluxAngle: 2.4,
        rightHalluxAngle: 1.5,
        leftPronatorAngle: 2.2,
        rightPronatorAngle: 0.6,
        leftArchWidthIndex: 0.448,
        rightArchWidthIndex: 0.360,
        leftKneeAngle: 1.4,
        rightKneeAngle: 3.1,
        leftHalluxType: 'Normal Hallgux',
        rightHalluxType: 'Normal Hallgux',
        leftHeelType: 'Normal Heel',
        rightHeelType: 'Normal Heel',
        leftKneeType: 'Normal Heel',
        rightKneeType: 'Normal Heel',
      ),
    );
  }

  ParsedScanReport _buildMockParsedReport({
    required String reportNo,
    required String reportDate,
    required String reportTime,
    required double leftFootLength,
    required double rightFootLength,
    required double leftFootWidth,
    required double rightFootWidth,
    required double leftArchHeight,
    required double rightArchHeight,
    required double leftHalluxAngle,
    required double rightHalluxAngle,
    required double leftPronatorAngle,
    required double rightPronatorAngle,
    required double leftArchWidthIndex,
    required double rightArchWidthIndex,
    required double leftKneeAngle,
    required double rightKneeAngle,
    required String leftHalluxType,
    required String rightHalluxType,
    required String leftHeelType,
    required String rightHeelType,
    required String leftKneeType,
    required String rightKneeType,
  }) {
    return ParsedScanReport(
      reportNo: reportNo,
      reportDate: reportDate,
      reportTime: reportTime,
      storeCode: 'tuerqi020001',
      address: '',
      customerName: 'qq',
      gender: 'Male',
      age: '42',
      phone: '121',
      leftFootLength: leftFootLength,
      rightFootLength: rightFootLength,
      leftFootWidth: leftFootWidth,
      rightFootWidth: rightFootWidth,
      leftArchHeight: leftArchHeight,
      rightArchHeight: rightArchHeight,
      leftHalluxAngle: leftHalluxAngle,
      rightHalluxAngle: rightHalluxAngle,
      leftPronatorAngle: leftPronatorAngle,
      rightPronatorAngle: rightPronatorAngle,
      leftArchWidthIndex: leftArchWidthIndex,
      rightArchWidthIndex: rightArchWidthIndex,
      leftKneeAngle: leftKneeAngle,
      rightKneeAngle: rightKneeAngle,
      leftHalluxType: leftHalluxType,
      rightHalluxType: rightHalluxType,
      leftHeelType: leftHeelType,
      rightHeelType: rightHeelType,
      leftKneeType: leftKneeType,
      rightKneeType: rightKneeType,
      leftShoeSize: '40(WE)',
      rightShoeSize: '40(WE)',
      leftArchType: 'Severe Flat',
      rightArchType: 'Severe Flat',
      leftArchIndex: 0.326,
      rightArchIndex: 0.306,
      recommendationText:
          'Uzun süre ayakta kalma ve uygun destek kullanımı önerilir.',
    );
  }

  Future<List<CustomerAnalysisResult>> getAnalysisHistory({
  required int userId,
}) async {
  final latest = await getLatestAnalysis(userId: userId);

  final older1 = CustomerAnalysisResult(
    sessionCode: 'SES-2026-0318',
    locationLabel: 'OptiYou İzmir',
    analysisDate: DateTime(2026, 3, 18),
    overallSummary:
        'Önceki ölçümde sol ayakta yük dağılımı daha dengesiz görünmektedir.',
    generalRiskNote:
        'Destekli kullanım sürdürülmelidir.',
    leftFoot: const CustomerFootSummary(
      side: 'left',
      footType: 'Düz taban eğilimi',
      pressureSummary: 'Topuk ve ön ayakta yük artışı',
      balanceSummary: 'Sol ayakta yük daha belirgin',
      archSupportNeed: 'Yüksek',
      mainFinding: 'Kemer desteği ihtiyacı daha belirgin',
      pressureScore: 65,
      stabilityScore: 58,
      archScore: 35,
    ),
    rightFoot: const CustomerFootSummary(
      side: 'right',
      footType: 'Nötr - hafif destek ihtiyacı',
      pressureSummary: 'Ön ayakta yüklenme',
      balanceSummary: 'Sağ ayakta denge daha iyi',
      archSupportNeed: 'Orta',
      mainFinding: 'Destek ihtiyacı mevcut',
      pressureScore: 61,
      stabilityScore: 66,
      archScore: 48,
    ),
    metrics: latest.metrics,
    recommendations: latest.recommendations,
    visuals: latest.visuals,
    parsedReport: _buildMockParsedReport(
      reportNo: '20251018001',
      reportDate: '2025-10-18',
      reportTime: '15:10:12',
      leftFootLength: 251.2,
      rightFootLength: 249.1,
      leftFootWidth: 103.1,
      rightFootWidth: 102.3,
      leftArchHeight: 12.8,
      rightArchHeight: 11.9,
      leftHalluxAngle: 3.1,
      rightHalluxAngle: 1.5,
      leftPronatorAngle: 3.0,
      rightPronatorAngle: 1.2,
      leftArchWidthIndex: 0.462,
      rightArchWidthIndex: 0.341,
      leftKneeAngle: 0.6,
      rightKneeAngle: 2.3,
      leftHalluxType: 'Normal Hallgux',
      rightHalluxType: 'Normal Hallgux',
      leftHeelType: 'Normal Heel',
      rightHeelType: 'Normal Heel',
      leftKneeType: 'Normal Heel',
      rightKneeType: 'Normal Heel',
    ),
  );

  final older2 = CustomerAnalysisResult(
    sessionCode: 'SES-2026-0210',
    locationLabel: 'OptiYou İzmir',
    analysisDate: DateTime(2026, 2, 10),
    overallSummary:
        'İlk ölçümlerde kemer desteği ihtiyacı daha belirgindir.',
    generalRiskNote:
        'Destekleyici iç taban kullanımı önerilmektedir.',
    leftFoot: const CustomerFootSummary(
      side: 'left',
      footType: 'Düz taban eğilimi',
      pressureSummary: 'Topuk bölgesinde belirgin yük',
      balanceSummary: 'Sol ayakta yük daha fazla',
      archSupportNeed: 'Yüksek',
      mainFinding: 'Kemer desteği ihtiyacı belirgin',
      pressureScore: 58,
      stabilityScore: 52,
      archScore: 30,
    ),
    rightFoot: const CustomerFootSummary(
      side: 'right',
      footType: 'Nötr - hafif destek ihtiyacı',
      pressureSummary: 'Ön ayakta orta yük',
      balanceSummary: 'Sağ ayakta denge daha iyi',
      archSupportNeed: 'Orta',
      mainFinding: 'Uzun süreli kullanımda destek önerilir',
      pressureScore: 55,
      stabilityScore: 60,
      archScore: 44,
    ),
    metrics: latest.metrics,
    recommendations: latest.recommendations,
    visuals: latest.visuals,
    parsedReport: _buildMockParsedReport(
      reportNo: '20250902001',
      reportDate: '2025-09-02',
      reportTime: '11:42:22',
      leftFootLength: 251.6,
      rightFootLength: 249.4,
      leftFootWidth: 103.8,
      rightFootWidth: 102.9,
      leftArchHeight: 12.1,
      rightArchHeight: 11.2,
      leftHalluxAngle: 4.0,
      rightHalluxAngle: 1.9,
      leftPronatorAngle: 3.8,
      rightPronatorAngle: 1.8,
      leftArchWidthIndex: 0.455,
      rightArchWidthIndex: 0.352,
      leftKneeAngle: 1.0,
      rightKneeAngle: 2.6,
      leftHalluxType: 'Normal Hallgux',
      rightHalluxType: 'Normal Hallgux',
      leftHeelType: 'Normal Heel',
      rightHeelType: 'Normal Heel',
      leftKneeType: 'Normal Heel',
      rightKneeType: 'Normal Heel',
    ),
  );

  return [latest, older1, older2];
}
}