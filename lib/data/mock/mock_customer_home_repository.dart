import 'dart:async';

import 'package:oy_site/models/customer_home_model.dart';

class MockCustomerHomeRepository {
  Future<CustomerHomeData> getHomeData({String? patientName}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return CustomerHomeData(
      patientName: patientName?.trim().isNotEmpty == true
          ? patientName!.trim()
          : 'Ahmet Yılmaz',
      lastAnalysisDate: DateTime(2026, 8, 4),
      analysisStatus: 'Değerlendirme hazır',
      summary:
          'Ayak değerlendirmenizde kemer desteği ihtiyacı ve topuk bölgesinde yük artışı gözlemlendi.',
      analysisHighlights: const [
        'Kemer desteği ihtiyacı',
        'Topuk yükünde artış',
        'Kişiye özel destek önerisi',
      ],
      recommendationNote:
          'Uzun süre ayakta kaldığınız günlerde destekli iç taban kullanmanız ve ürününüzü düzenli aralıklarla kontrol ettirmeniz önerilir.',
      recommendationUpdatedAt: DateTime(2026, 8, 5),
      orderNo: 'OY-2026-0041',
      orderStatus: 'Üretimde',
      orderProgressStep: 2,
      productName: 'Kişiye Özel Ortopedik İç Taban',
      estimatedDelivery: DateTime(2026, 8, 16),
      suggestedProductName: 'Kişiye Özel İç Taban',
      suggestedProductDescription:
          'Günlük kullanımda basınç dağılımını dengelemeye ve ayağınıza uygun desteği sağlamaya yardımcı olur.',
      suggestedProductReason:
          'Son değerlendirmenizde görülen kemer desteği ihtiyacına göre önerildi.',
      suggestedProductPrice: 3200,
      suggestedProductImagePath:
          'assets/images/products/personal_insole.png',
    );
  }
}
