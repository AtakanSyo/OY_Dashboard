import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_sales_stats_repository.dart';
import 'package:oy_site/models/sales_stats_models.dart';

class SalesStatisticsScreen extends StatefulWidget {
  const SalesStatisticsScreen({super.key});

  @override
  State<SalesStatisticsScreen> createState() => _SalesStatisticsScreenState();
}

class _SalesStatisticsScreenState extends State<SalesStatisticsScreen> {
  final MockSalesStatsRepository _repository = MockSalesStatsRepository();

  bool _isLoading = true;
  String? _errorMessage;
  SalesStatsData? _data;

  String _selectedRange = 'Son 6 Ay';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getSalesStats();

      if (!mounted) return;

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Satış istatistikleri yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  String _formatMoney(double value) {
    return '${value.toStringAsFixed(2)} TL';
  }

  String _productShortLabel(String productType) {
    switch (productType) {
      case 'Tabanlık':
        return 'Tabanlık';
      case 'Spor Tabanlık':
        return 'Spor';
      case 'Sandalet':
        return 'Sandalet';
      default:
        return productType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış İstatistikleri'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_data == null) {
      return const Center(
        child: Text('Veri bulunamadı.'),
      );
    }

    final data = _data!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Satış performansı ve sipariş eğilimleri',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRange,
                  decoration: InputDecoration(
                    labelText: 'Dönem',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Son 30 Gün',
                      child: Text('Son 30 Gün'),
                    ),
                    DropdownMenuItem(
                      value: 'Son 3 Ay',
                      child: Text('Son 3 Ay'),
                    ),
                    DropdownMenuItem(
                      value: 'Son 6 Ay',
                      child: Text('Son 6 Ay'),
                    ),
                    DropdownMenuItem(
                      value: 'Bu Yıl',
                      child: Text('Bu Yıl'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRange = value ?? 'Son 6 Ay';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Satış',
                  value: _formatMoney(data.summary.totalSales),
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Toplam Sipariş',
                  value: data.summary.totalOrders.toString(),
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Ortalama Sipariş',
                  value: _formatMoney(data.summary.averageOrderValue),
                  icon: Icons.bar_chart_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Bekleyen Sipariş Değeri',
                  value: _formatMoney(data.summary.pendingOrdersValue),
                  icon: Icons.timelapse_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildSectionCard(
            title: 'Zamana Göre Satış',
            child: SizedBox(
              height: 300,
              child: _buildSalesLineChart(data.salesOverTime),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionCard(
                  title: 'Ürün Tipine Göre Dağılım',
                  child: SizedBox(
                    height: 320,
                    child: _buildProductBarChart(data.productDistribution),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSectionCard(
                  title: 'En Çok Satış Yapan Uzmanlar',
                  child: _buildTopExpertsList(data.topExperts),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.teal.withOpacity(0.12),
            child: Icon(icon, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSalesLineChart(List<SalesTimePoint> points) {
    final maxY = points
            .map((e) => e.value)
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    points[index].label,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true),
            spots: List.generate(
              points.length,
              (index) => FlSpot(index.toDouble(), points[index].value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBarChart(List<ProductSalesDistributionItem> items) {
    final maxY = items
            .map((e) => e.amount)
            .reduce((a, b) => a > b ? a : b) *
        1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: maxY / 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}K',
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= items.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _productShortLabel(items[index].productType),
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(
          items.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: items[index].amount,
                width: 24,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopExpertsList(List<ExpertSalesPerformanceItem> items) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.withOpacity(0.12),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.expertName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMoney(item.totalSales),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.orderCount} sipariş',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}