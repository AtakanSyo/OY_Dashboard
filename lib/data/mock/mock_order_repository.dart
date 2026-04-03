import 'dart:async';

import 'package:oy_site/models/order_model.dart';

class MockOrderRepository {
  Future<List<OrderModel>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return [
      OrderModel(
        orderId: 1,
        sessionId: 1,
        patientId: 1,
        clinicId: 101,
        expertUserId: 1,
        assignedOptityouUserId: 2,
        orderNo: 'ORD-2026-001',
        productType: 'insole',
        orderStatus: OrderStatuses.production,
        grossAmount: 3200,
        discountAmount: 200,
        netAmount: 3000,
        currencyCode: 'TRY',
        orderedAt: DateTime(2026, 3, 21, 12, 30),
      ),
      OrderModel(
        orderId: 2,
        sessionId: 2,
        patientId: 2,
        clinicId: 101,
        expertUserId: 1,
        assignedOptityouUserId: 2,
        orderNo: 'ORD-2026-002',
        productType: 'sports_insole',
        orderStatus: OrderStatuses.shipped,
        grossAmount: 4100,
        discountAmount: 100,
        netAmount: 4000,
        currencyCode: 'TRY',
        orderedAt: DateTime(2026, 3, 28, 16, 10),
        shippedAt: DateTime(2026, 3, 31, 10, 45),
      ),
      OrderModel(
        orderId: 3,
        sessionId: 3,
        patientId: 3,
        clinicId: 101,
        expertUserId: 1,
        orderNo: 'ORD-2026-003',
        productType: 'sandal',
        orderStatus: OrderStatuses.delivered,
        grossAmount: 5200,
        discountAmount: 500,
        netAmount: 4700,
        currencyCode: 'TRY',
        orderedAt: DateTime(2026, 2, 18, 14, 20),
        shippedAt: DateTime(2026, 2, 21, 9, 0),
        deliveredAt: DateTime(2026, 2, 24, 15, 30),
      ),
      OrderModel(
        orderId: 4,
        sessionId: 4,
        patientId: 1,
        clinicId: 101,
        expertUserId: 1,
        orderNo: 'ORD-2026-004',
        productType: 'insole',
        orderStatus: OrderStatuses.pending,
        grossAmount: 2900,
        discountAmount: 0,
        netAmount: 2900,
        currencyCode: 'TRY',
        orderedAt: DateTime(2026, 4, 2, 11, 10),
      ),
    ];
  }
}