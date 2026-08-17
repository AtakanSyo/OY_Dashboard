import 'dart:async';

import 'package:oy_site/models/customer_home_model.dart';
import 'package:oy_site/models/order_model.dart';

/// Optional demo source retained for local UI demonstrations.
///
/// The production customer dashboard uses SupabaseCustomerHomeRepository.
class MockCustomerHomeRepository {
  Future<CustomerHomeData> getHomeData({String? patientName}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return CustomerHomeData(
      patientName: patientName?.trim().isNotEmpty == true
          ? patientName!.trim()
          : 'Demo User',
      latestAssessment: CustomerHomeAssessmentData(
        sessionCode: 'DEMO-001',
        analysisDate: DateTime(2026, 8, 4),
        summary: 'Demo assessment summary',
        highlights: const ['Demo finding'],
        recommendationTitle: 'Demo recommendation',
        recommendationNote: 'Demo recommendation note',
      ),
      activeOrder: CustomerHomeOrderData(
        orderNo: 'DEMO-ORDER-001',
        orderStatus: OrderStatuses.production,
        productType: 'insole',
        orderedAt: DateTime(2026, 8, 5),
        progressStep: 2,
      ),
    );
  }
}
