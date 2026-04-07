import 'dart:async';

import 'package:oy_site/models/optiyou_operation_column.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:oy_site/models/order_model.dart';

class MockOptiYouOrderOperationsRepository {
  Future<List<OptiYouOrderOperationItem>> getOrderOperations() async {
    await Future.delayed(const Duration(milliseconds: 350));

    return [
      OptiYouOrderOperationItem(
        order: OrderModel(
          orderId: 1,
          sessionId: 1,
          patientId: 1,
          clinicId: 101,
          expertUserId: 11,
          assignedOptityouUserId: 21,
          orderNo: 'ORD-2026-001',
          productType: 'insole',
          orderStatus: OrderStatuses.pending,
          currencyCode: 'TRY',
          grossAmount: 3200,
          discountAmount: 200,
          netAmount: 3000,
          orderedAt: DateTime(2026, 4, 2, 10, 30),
        ),
        expertName: 'Dr. Ayşe Demir',
        clinicName: 'İzmir Ortopedi Kliniği',
        hasMissingData: true,
        missingDataSummary: '3D scan eksik',
        priorityLabel: 'Yüksek',
        currentColumnCode: OptiYouOperationColumnCodes.technicalReview,
      ),
      OptiYouOrderOperationItem(
        order: OrderModel(
          orderId: 2,
          sessionId: 2,
          patientId: 2,
          clinicId: 102,
          expertUserId: 12,
          assignedOptityouUserId: 21,
          orderNo: 'ORD-2026-002',
          productType: 'sports_insole',
          orderStatus: OrderStatuses.production,
          currencyCode: 'TRY',
          grossAmount: 4100,
          discountAmount: 100,
          netAmount: 4000,
          orderedAt: DateTime(2026, 4, 1, 14, 10),
        ),
        expertName: 'Uzm. Dr. Mehmet Kaya',
        clinicName: 'Ankara Ayak Sağlığı Merkezi',
        hasMissingData: false,
        missingDataSummary: '',
        priorityLabel: 'Orta',
        currentColumnCode: OptiYouOperationColumnCodes.productionStarted,
      ),
      OptiYouOrderOperationItem(
        order: OrderModel(
          orderId: 3,
          sessionId: 3,
          patientId: 3,
          clinicId: 103,
          expertUserId: 13,
          assignedOptityouUserId: 22,
          orderNo: 'ORD-2026-003',
          productType: 'sandal',
          orderStatus: OrderStatuses.shipped,
          currencyCode: 'TRY',
          grossAmount: 5200,
          discountAmount: 500,
          netAmount: 4700,
          orderedAt: DateTime(2026, 3, 28, 9, 20),
          shippedAt: DateTime(2026, 4, 4, 16, 40),
        ),
        expertName: 'Dr. Elif Yıldız',
        clinicName: 'İstanbul Postür Merkezi',
        hasMissingData: false,
        missingDataSummary: '',
        priorityLabel: 'Düşük',
        currentColumnCode: OptiYouOperationColumnCodes.postInfoMailSent,
      ),
      OptiYouOrderOperationItem(
        order: OrderModel(
          orderId: 4,
          sessionId: 4,
          patientId: 4,
          clinicId: 101,
          expertUserId: 14,
          assignedOptityouUserId: null,
          orderNo: 'ORD-2026-004',
          productType: 'insole',
          orderStatus: OrderStatuses.delivered,
          currencyCode: 'TRY',
          grossAmount: 2900,
          discountAmount: 0,
          netAmount: 2900,
          orderedAt: DateTime(2026, 3, 20, 11, 45),
          shippedAt: DateTime(2026, 3, 24, 10, 15),
          deliveredAt: DateTime(2026, 3, 26, 13, 30),
        ),
        expertName: 'Uzm. Dr. Burak Aydın',
        clinicName: 'Bursa Ortez Merkezi',
        hasMissingData: false,
        missingDataSummary: '',
        priorityLabel: 'Orta',
        currentColumnCode: OptiYouOperationColumnCodes.closed,
      ),
    ];
  }
}