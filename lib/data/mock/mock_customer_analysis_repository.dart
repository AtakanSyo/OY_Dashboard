import 'dart:async';

import 'package:oy_site/models/customer_analysis_result_model.dart';

class MockCustomerAnalysisRepository {
  Future<CustomerAnalysisResult> getLatestAnalysis({
    required int userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    return CustomerAnalysisResult(
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
      visuals: const CustomerAnalysisVisualSet(
        sessionCode: 'SESSION-001',
        archLeftImage: 'assets/mock_data/SESSION-001/arch_L.bmp',
        archRightImage: 'assets/mock_data/SESSION-001/arch_R.bmp',
        archSectionLeftImage: 'assets/mock_data/SESSION-001/archSectV_L.bmp',
        archSectionRightImage: 'assets/mock_data/SESSION-001/archSectV_R.bmp',
        foot2dLeftImage: 'assets/mock_data/SESSION-001/foot3d_L.bmp',
        foot2dRightImage: 'assets/mock_data/SESSION-001/foot3d_R.bmp',
        pronatorLeftImage: 'assets/mock_data/SESSION-001/pronatorL-line.bmp',
        pronatorRightImage: 'assets/mock_data/SESSION-001/pronatorR-line.bmp',
        leftStlFile: 'assets/mock_data/SESSION-001/name-surname_L.stl',
        rightStlFile: 'assets/mock_data/SESSION-001/name-surname_R.stl',
      ),
    );
  }
}