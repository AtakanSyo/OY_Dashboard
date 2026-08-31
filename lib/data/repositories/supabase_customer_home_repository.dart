import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/customer_home_model.dart';
import 'package:oy_site/models/order_model.dart';

abstract class CustomerHomeRepository {
  Future<CustomerHomeData> getHomeData({required String patientName});
}

class SupabaseCustomerHomeRepository implements CustomerHomeRepository {
  final SupabaseAnalysisRepository _analysisRepository;
  final SupabaseOrderRepository _orderRepository;

  SupabaseCustomerHomeRepository({
    SupabaseAnalysisRepository? analysisRepository,
    SupabaseOrderRepository? orderRepository,
  }) : _analysisRepository = analysisRepository ?? SupabaseAnalysisRepository(),
       _orderRepository = orderRepository ?? SupabaseOrderRepository();

  @override
  Future<CustomerHomeData> getHomeData({required String patientName}) async {
    final results = await Future.wait<Object>([
      _loadLatestAssessment(),
      _loadOrders(),
    ]);
    final assessmentResult = results[0] as _LoadResult<CustomerAnalysisResult?>;
    final ordersResult = results[1] as _LoadResult<List<OrderModel>>;

    return CustomerHomeData(
      patientName: patientName.trim(),
      latestAssessment: _mapAssessment(assessmentResult.value),
      activeOrder: _mapActiveOrder(ordersResult.value),
      // Product selection does not yet have a structured backend field.
      suggestedProduct: null,
      analysisLoadFailed: assessmentResult.failed,
      ordersLoadFailed: ordersResult.failed,
    );
  }

  Future<_LoadResult<CustomerAnalysisResult?>> _loadLatestAssessment() async {
    try {
      return _LoadResult.success(
        await _analysisRepository.getLatestAnalysisForCurrentCustomer(),
      );
    } catch (_) {
      return const _LoadResult.failure();
    }
  }

  Future<_LoadResult<List<OrderModel>>> _loadOrders() async {
    try {
      return _LoadResult.success(
        await _orderRepository.getOrdersForCurrentCustomer(),
      );
    } catch (_) {
      return const _LoadResult.failure();
    }
  }

  CustomerHomeAssessmentData? _mapAssessment(
    CustomerAnalysisResult? assessment,
  ) {
    if (assessment == null) return null;

    final highlights = <String>[];
    void addHighlight(String? value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty || highlights.contains(text)) return;
      highlights.add(text);
    }

    addHighlight(assessment.leftFoot.mainFinding);
    addHighlight(assessment.rightFoot.mainFinding);
    for (final recommendation in assessment.recommendations) {
      addHighlight(recommendation.title);
      if (highlights.length >= 3) break;
    }

    final firstRecommendation = assessment.recommendations.isEmpty
        ? null
        : assessment.recommendations.first;
    return CustomerHomeAssessmentData(
      sessionCode: assessment.sessionCode,
      analysisDate: assessment.analysisDate,
      summary: assessment.overallSummary.trim(),
      highlights: highlights.take(3).toList(growable: false),
      recommendationTitle: firstRecommendation?.title.trim(),
      recommendationNote: firstRecommendation?.description.trim(),
    );
  }

  CustomerHomeOrderData? _mapActiveOrder(List<OrderModel>? orders) {
    if (orders == null) return null;

    OrderModel? activeOrder;
    for (final order in orders) {
      if (!order.isDelivered && !order.isCancelled) {
        activeOrder = order;
        break;
      }
    }
    if (activeOrder == null) return null;

    return CustomerHomeOrderData(
      orderNo: activeOrder.orderNo,
      orderStatus: activeOrder.orderStatus,
      productType: activeOrder.productType,
      orderedAt: activeOrder.orderedAt,
      progressStep: _progressStep(activeOrder.orderStatus),
    );
  }

  int _progressStep(String status) {
    switch (status) {
      case OrderStatuses.designing:
        return 1;
      case OrderStatuses.production:
        return 2;
      case OrderStatuses.shipped:
        return 3;
      case OrderStatuses.delivered:
        return 4;
      default:
        return 0;
    }
  }
}

class _LoadResult<T> {
  final T? value;
  final bool failed;

  const _LoadResult.success(T this.value) : failed = false;

  const _LoadResult.failure() : value = null, failed = true;
}
