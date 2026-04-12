import 'dart:async';

import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/session_scan_assets.dart';
import 'package:oy_site/services/scan/session_scan_assets_parser.dart';

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
    );
  }
}