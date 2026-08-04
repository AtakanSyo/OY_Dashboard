import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/models/sales_stats_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSalesStatsRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<SalesStatsData> getSalesStats({
    required DateTime startDate,
    required DateTime endDate,
    required bool groupByDay,
    String currencyCode = 'TRY',
  }) async {
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndExclusive = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));

    final response = await _client
        .from('orders')
        .select(
          'id, '
          'session_id, '
          'patient_id, '
          'clinic_id, '
          'expert_user_id, '
          'assigned_optityou_user_id, '
          'order_no, '
          'product_type, '
          'order_status, '
          'currency_code, '
          'gross_amount, '
          'discount_amount, '
          'net_amount, '
          'ordered_at, '
          'shipped_at, '
          'delivered_at',
        )
        .gte('ordered_at', normalizedStart.toIso8601String())
        .lt('ordered_at', normalizedEndExclusive.toIso8601String())
        .eq('currency_code', currencyCode)
        .neq('order_status', OrderStatuses.cancelled)
        .order('ordered_at', ascending: true);

    final orders = (response as List<dynamic>)
        .map(
          (item) => OrderModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final expertNames = await _loadExpertNames(orders);

    return SalesStatsData(
      summary: _buildSummary(orders),
      salesOverTime: groupByDay
          ? _buildDailySales(
              orders: orders,
              startDate: normalizedStart,
              endDate: endDate,
            )
          : _buildMonthlySales(
              orders: orders,
              startDate: normalizedStart,
              endDate: endDate,
            ),
      productDistribution: _buildProductDistribution(orders),
      topExperts: _buildTopExperts(
        orders: orders,
        expertNames: expertNames,
      ),
    );
  }

  SalesSummary _buildSummary(List<OrderModel> orders) {
    final double totalSales = orders.fold<double>(
      0.0,
      (sum, order) => sum + order.netAmount,
    );

    final int totalOrders = orders.length;

    final double averageOrderValue =
        totalOrders == 0 ? 0.0 : totalSales / totalOrders;

    final double pendingOrdersValue = orders
        .where(
          (order) =>
              order.orderStatus == OrderStatuses.pending ||
              order.orderStatus == OrderStatuses.designing ||
              order.orderStatus == OrderStatuses.production ||
              order.orderStatus == OrderStatuses.shipped,
        )
        .fold<double>(
          0.0,
          (sum, order) => sum + order.netAmount,
        );

    return SalesSummary(
      totalSales: totalSales,
      totalOrders: totalOrders,
      averageOrderValue: averageOrderValue,
      pendingOrdersValue: pendingOrdersValue,
    );
  }

  List<SalesTimePoint> _buildDailySales({
    required List<OrderModel> orders,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totals = <DateTime, double>{};

    for (final order in orders) {
      final key = DateTime(
        order.orderedAt.year,
        order.orderedAt.month,
        order.orderedAt.day,
      );

      totals[key] = (totals[key] ?? 0) + order.netAmount;
    }

    final points = <SalesTimePoint>[];

    DateTime cursor = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final lastDay = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    while (!cursor.isAfter(lastDay)) {
      points.add(
        SalesTimePoint(
          label:
              '${cursor.day.toString().padLeft(2, '0')}.${cursor.month.toString().padLeft(2, '0')}',
          value: totals[cursor] ?? 0,
        ),
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    return points;
  }

  List<SalesTimePoint> _buildMonthlySales({
    required List<OrderModel> orders,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totals = <String, double>{};

    for (final order in orders) {
      final key = _monthKey(
        order.orderedAt.year,
        order.orderedAt.month,
      );

      totals[key] = (totals[key] ?? 0) + order.netAmount;
    }

    final points = <SalesTimePoint>[];

    DateTime cursor = DateTime(
      startDate.year,
      startDate.month,
      1,
    );

    final lastMonth = DateTime(
      endDate.year,
      endDate.month,
      1,
    );

    while (!cursor.isAfter(lastMonth)) {
      final key = _monthKey(cursor.year, cursor.month);

      points.add(
        SalesTimePoint(
          label: _monthShortLabel(cursor.month),
          value: totals[key] ?? 0,
        ),
      );

      cursor = DateTime(
        cursor.year,
        cursor.month + 1,
        1,
      );
    }

    return points;
  }

  List<ProductSalesDistributionItem> _buildProductDistribution(
    List<OrderModel> orders,
  ) {
    final amounts = <String, double>{};
    final counts = <String, int>{};

    for (final order in orders) {
      final productType = order.productType.trim().isEmpty
          ? 'unknown'
          : order.productType.trim();

      amounts[productType] =
          (amounts[productType] ?? 0) + order.netAmount;

      counts[productType] = (counts[productType] ?? 0) + 1;
    }

    final items = amounts.entries.map((entry) {
      return ProductSalesDistributionItem(
        productType: _productLabel(entry.key),
        amount: entry.value,
        orderCount: counts[entry.key] ?? 0,
      );
    }).toList();

    items.sort(
      (a, b) => b.amount.compareTo(a.amount),
    );

    return items;
  }

  List<ExpertSalesPerformanceItem> _buildTopExperts({
    required List<OrderModel> orders,
    required Map<int, String> expertNames,
  }) {
    final salesByExpert = <int, double>{};
    final countsByExpert = <int, int>{};

    for (final order in orders) {
      final expertId = order.expertUserId;

      salesByExpert[expertId] =
          (salesByExpert[expertId] ?? 0) + order.netAmount;

      countsByExpert[expertId] =
          (countsByExpert[expertId] ?? 0) + 1;
    }

    final items = salesByExpert.entries.map((entry) {
      return ExpertSalesPerformanceItem(
        expertName:
            expertNames[entry.key] ?? 'Uzman #${entry.key}',
        orderCount: countsByExpert[entry.key] ?? 0,
        totalSales: entry.value,
      );
    }).toList();

    items.sort(
      (a, b) => b.totalSales.compareTo(a.totalSales),
    );

    return items.take(10).toList();
  }

  Future<Map<int, String>> _loadExpertNames(
    List<OrderModel> orders,
  ) async {
    final expertIds = orders
        .map((order) => order.expertUserId)
        .where((id) => id > 0)
        .toSet()
        .toList();

    if (expertIds.isEmpty) {
      return <int, String>{};
    }

    try {
      final response = await _client
          .from('user_profiles_full')
          .select(
            'user_id, first_name, last_name, username, email, title',
          )
          .inFilter('user_id', expertIds);

      final result = <int, String>{};

      for (final item in response as List<dynamic>) {
        final row = Map<String, dynamic>.from(item as Map);

        final userId = _asInt(row['user_id']);
        if (userId == null) continue;

        final firstName =
            (row['first_name'] ?? '').toString().trim();

        final lastName =
            (row['last_name'] ?? '').toString().trim();

        final title =
            (row['title'] ?? '').toString().trim();

        final username =
            (row['username'] ?? '').toString().trim();

        final email =
            (row['email'] ?? '').toString().trim();

        final fullName = '$firstName $lastName'.trim();

        if (fullName.isNotEmpty) {
          result[userId] = title.isNotEmpty
              ? '$title $fullName'
              : fullName;
        } else if (username.isNotEmpty &&
            !username.contains('@')) {
          result[userId] = username;
        } else if (email.isNotEmpty) {
          result[userId] = email;
        } else {
          result[userId] = 'Uzman #$userId';
        }
      }

      return result;
    } catch (_) {
      return <int, String>{};
    }
  }

  String _productLabel(String value) {
    switch (value.toLowerCase()) {
      case 'insole':
        return 'Tabanlık';
      case 'sports_insole':
        return 'Spor Tabanlık';
      case 'sandal':
        return 'Sandalet';
      case 'shoe':
        return 'Ayakkabı';
      case 'slipper':
        return 'Terlik';
      case 'unknown':
        return 'Belirtilmemiş';
      default:
        return value;
    }
  }

  String _monthKey(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  String _monthShortLabel(int month) {
    const months = [
      '',
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];

    if (month < 1 || month > 12) return '';

    return months[month];
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}