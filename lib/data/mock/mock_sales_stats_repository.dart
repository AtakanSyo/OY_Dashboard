import 'dart:async';

import 'package:oy_site/models/sales_stats_models.dart';

class MockSalesStatsRepository {
  Future<SalesStatsData> getSalesStats() async {
    await Future.delayed(const Duration(milliseconds: 350));

    const salesOverTime = [
      SalesTimePoint(label: 'Oca', value: 18500),
      SalesTimePoint(label: 'Şub', value: 22400),
      SalesTimePoint(label: 'Mar', value: 19800),
      SalesTimePoint(label: 'Nis', value: 26750),
      SalesTimePoint(label: 'May', value: 31200),
      SalesTimePoint(label: 'Haz', value: 28600),
    ];

    const productDistribution = [
      ProductSalesDistributionItem(
        productType: 'Tabanlık',
        amount: 74200,
        orderCount: 23,
      ),
      ProductSalesDistributionItem(
        productType: 'Spor Tabanlık',
        amount: 38500,
        orderCount: 11,
      ),
      ProductSalesDistributionItem(
        productType: 'Sandalet',
        amount: 28550,
        orderCount: 7,
      ),
    ];

    const topExperts = [
      ExpertSalesPerformanceItem(
        expertName: 'Dr. Ayşe Demir',
        orderCount: 12,
        totalSales: 42800,
      ),
      ExpertSalesPerformanceItem(
        expertName: 'Uzm. Dr. Mehmet Kaya',
        orderCount: 10,
        totalSales: 36600,
      ),
      ExpertSalesPerformanceItem(
        expertName: 'Dr. Elif Yıldız',
        orderCount: 8,
        totalSales: 29850,
      ),
      ExpertSalesPerformanceItem(
        expertName: 'Uzm. Dr. Burak Aydın',
        orderCount: 6,
        totalSales: 22000,
      ),
    ];

    const summary = SalesSummary(
      totalSales: 141250,
      totalOrders: 41,
      averageOrderValue: 3445.12,
      pendingOrdersValue: 18750,
    );

    return const SalesStatsData(
      summary: summary,
      salesOverTime: salesOverTime,
      productDistribution: productDistribution,
      topExperts: topExperts,
    );
  }
}