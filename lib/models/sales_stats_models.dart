class SalesSummary {
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final double pendingOrdersValue;

  const SalesSummary({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.pendingOrdersValue,
  });
}

class SalesTimePoint {
  final String label;
  final double value;

  const SalesTimePoint({
    required this.label,
    required this.value,
  });
}

class ProductSalesDistributionItem {
  final String productType;
  final double amount;
  final int orderCount;

  const ProductSalesDistributionItem({
    required this.productType,
    required this.amount,
    required this.orderCount,
  });
}

class ExpertSalesPerformanceItem {
  final String expertName;
  final int orderCount;
  final double totalSales;

  const ExpertSalesPerformanceItem({
    required this.expertName,
    required this.orderCount,
    required this.totalSales,
  });
}

class SalesStatsData {
  final SalesSummary summary;
  final List<SalesTimePoint> salesOverTime;
  final List<ProductSalesDistributionItem> productDistribution;
  final List<ExpertSalesPerformanceItem> topExperts;

  const SalesStatsData({
    required this.summary,
    required this.salesOverTime,
    required this.productDistribution,
    required this.topExperts,
  });
}