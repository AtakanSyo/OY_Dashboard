import 'dart:async';
import 'package:oy_site/models/customer_home_model.dart';

class MockCustomerHomeRepository {
  Future<CustomerHomeData> getHomeData() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return CustomerHomeData(
      patientName: 'Ahmet Yılmaz',
      lastAnalysisDate: DateTime(2026, 4, 5),
      summary:
          'Ayak analizinizde kemer desteği ihtiyacı ve topuk bölgesinde yük artışı gözlemlendi.',
      recommendationNote:
          'Uzun süre ayakta kaldığınız günlerde destekli iç taban kullanmanız önerilir.',
      orderNo: 'ORD-2026-041',
      orderStatus: 'Üretimde',
      productName: 'Kişiye Özel Tabanlık',
      estimatedDelivery: DateTime(2026, 4, 12),
      suggestedProductName: 'Spor Tabanlık',
      suggestedProductDescription:
          'Günlük kullanım dışında spor aktivitelerinde destek sağlar.',
      suggestedProductPrice: 3200,
    );
  }
}