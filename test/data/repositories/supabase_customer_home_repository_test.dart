import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/data/repositories/supabase_customer_home_repository.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/order_model.dart';

void main() {
  test('maps the latest assessment and first active order', () async {
    final repository = SupabaseCustomerHomeRepository(
      analysisRepository: _FakeAnalysisRepository(result: _assessment()),
      orderRepository: _FakeOrderRepository(
        orders: [
          _order(status: OrderStatuses.delivered, orderNo: 'OY-DONE'),
          _order(status: OrderStatuses.production, orderNo: 'OY-ACTIVE'),
        ],
      ),
    );

    final data = await repository.getHomeData(patientName: 'Ada Test');

    expect(data.patientName, 'Ada Test');
    expect(data.analysisLoadFailed, isFalse);
    expect(data.ordersLoadFailed, isFalse);
    expect(data.latestAssessment?.sessionCode, 'SESSION-1');
    expect(data.latestAssessment?.highlights, [
      'Left finding',
      'Right finding',
      'Recommendation',
    ]);
    expect(data.activeOrder?.orderNo, 'OY-ACTIVE');
    expect(data.activeOrder?.progressStep, 2);
    expect(data.suggestedProduct, isNull);
  });

  test('keeps order data when the assessment request fails', () async {
    final repository = SupabaseCustomerHomeRepository(
      analysisRepository: _FakeAnalysisRepository(shouldThrow: true),
      orderRepository: _FakeOrderRepository(
        orders: [
          _order(status: OrderStatuses.designing, orderNo: 'OY-PARTIAL'),
        ],
      ),
    );

    final data = await repository.getHomeData(patientName: 'Ada Test');

    expect(data.analysisLoadFailed, isTrue);
    expect(data.latestAssessment, isNull);
    expect(data.ordersLoadFailed, isFalse);
    expect(data.activeOrder?.orderNo, 'OY-PARTIAL');
    expect(data.activeOrder?.progressStep, 1);
  });

  test('keeps assessment data when the order request fails', () async {
    final repository = SupabaseCustomerHomeRepository(
      analysisRepository: _FakeAnalysisRepository(result: _assessment()),
      orderRepository: _FakeOrderRepository(shouldThrow: true),
    );

    final data = await repository.getHomeData(patientName: 'Ada Test');

    expect(data.analysisLoadFailed, isFalse);
    expect(data.latestAssessment?.sessionCode, 'SESSION-1');
    expect(data.ordersLoadFailed, isTrue);
    expect(data.activeOrder, isNull);
  });
}

CustomerAnalysisResult _assessment() {
  return CustomerAnalysisResult(
    sessionCode: 'SESSION-1',
    locationLabel: 'Test Center',
    analysisDate: DateTime(2026, 8, 10),
    overallSummary: 'Assessment summary',
    generalRiskNote: '',
    leftFoot: _foot(side: 'left', finding: 'Left finding'),
    rightFoot: _foot(side: 'right', finding: 'Right finding'),
    metrics: const [],
    recommendations: const [
      CustomerRecommendationItem(
        title: 'Recommendation',
        description: 'Recommendation note',
      ),
    ],
    visuals: const CustomerAnalysisVisualSet(sessionCode: 'SESSION-1'),
  );
}

CustomerFootSummary _foot({required String side, required String finding}) {
  return CustomerFootSummary(
    side: side,
    footType: '',
    pressureSummary: '',
    balanceSummary: '',
    archSupportNeed: '',
    mainFinding: finding,
    pressureScore: 0,
    stabilityScore: 0,
    archScore: 0,
  );
}

OrderModel _order({required String status, required String orderNo}) {
  return OrderModel(
    orderId: 1,
    sessionId: 1,
    patientId: 1,
    clinicId: 1,
    expertUserId: 1,
    orderNo: orderNo,
    productType: 'insole',
    orderStatus: status,
    orderedAt: DateTime(2026, 8, 10),
  );
}

class _FakeAnalysisRepository extends SupabaseAnalysisRepository {
  final CustomerAnalysisResult? result;
  final bool shouldThrow;

  _FakeAnalysisRepository({this.result, this.shouldThrow = false});

  @override
  Future<CustomerAnalysisResult?> getLatestAnalysisForCurrentCustomer() async {
    if (shouldThrow) throw Exception('analysis failed');
    return result;
  }
}

class _FakeOrderRepository extends SupabaseOrderRepository {
  final List<OrderModel> orders;
  final bool shouldThrow;

  _FakeOrderRepository({this.orders = const [], this.shouldThrow = false});

  @override
  Future<List<OrderModel>> getOrdersForCurrentCustomer() async {
    if (shouldThrow) throw Exception('orders failed');
    return orders;
  }
}
