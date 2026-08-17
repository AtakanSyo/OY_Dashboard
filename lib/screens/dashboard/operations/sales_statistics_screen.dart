import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_sales_stats_repository.dart';
import 'package:oy_site/models/sales_stats_models.dart';

class SalesStatisticsScreen extends StatefulWidget {
  const SalesStatisticsScreen({super.key});

  @override
  State<SalesStatisticsScreen> createState() =>
      _SalesStatisticsScreenState();
}

class _SalesStatisticsScreenState
    extends State<SalesStatisticsScreen> {
  final SupabaseSalesStatsRepository _repository =
      SupabaseSalesStatsRepository();

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
      final range = _resolveDateRange(_selectedRange);

      final data = await _repository.getSalesStats(
        startDate: range.startDate,
        endDate: range.endDate,
        groupByDay: range.groupByDay,
        currencyCode: 'TRY',
      );

      if (!mounted) return;

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Satış istatistikleri yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  _SalesDateRange _resolveDateRange(String range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (range) {
      case 'Son 30 Gün':
        return _SalesDateRange(
          startDate: today.subtract(
            const Duration(days: 29),
          ),
          endDate: today,
          groupByDay: true,
        );

      case 'Son 3 Ay':
        return _SalesDateRange(
          startDate: DateTime(
            today.year,
            today.month - 2,
            1,
          ),
          endDate: today,
          groupByDay: false,
        );

      case 'Son 6 Ay':
        return _SalesDateRange(
          startDate: DateTime(
            today.year,
            today.month - 5,
            1,
          ),
          endDate: today,
          groupByDay: false,
        );

      case 'Bu Yıl':
        return _SalesDateRange(
          startDate: DateTime(today.year, 1, 1),
          endDate: today,
          groupByDay: false,
        );

      default:
        return _SalesDateRange(
          startDate: DateTime(
            today.year,
            today.month - 5,
            1,
          ),
          endDate: today,
          groupByDay: false,
        );
    }
  }

  String _formatMoney(double value) {
    final formatted = value.toStringAsFixed(2);
    return '$formatted TL';
  }

  String _productShortLabel(String productType) {
    switch (productType) {
      case 'Tabanlık':
        return 'Tabanlık';
      case 'Spor Tabanlık':
        return 'Spor';
      case 'Sandalet':
        return 'Sandalet';
      case 'Ayakkabı':
        return 'Ayakkabı';
      case 'Terlik':
        return 'Terlik';
      default:
        return productType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Satış İstatistikleri'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
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
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSummarySection(data),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Zamana Göre Satış',
            subtitle:
                'İptal edilen siparişler hariç net sipariş tutarları',
            child: SizedBox(
              height: 320,
              child: _buildSalesLineChart(
                data.salesOverTime,
              ),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 920;

              final productSection = _buildSectionCard(
                title: 'Ürün Tipine Göre Dağılım',
                subtitle:
                    'Ürün gruplarının toplam net satış tutarı',
                child: SizedBox(
                  height: 340,
                  child: _buildProductBarChart(
                    data.productDistribution,
                  ),
                ),
              );

              final expertSection = _buildSectionCard(
                title: 'En Çok Satış Yapan Uzmanlar',
                subtitle:
                    'Net satış tutarına göre ilk 10 uzman',
                child: _buildTopExpertsList(
                  data.topExperts,
                ),
              );

              if (!isWide) {
                return Column(
                  children: [
                    productSection,
                    const SizedBox(height: 24),
                    expertSection,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: productSection),
                  const SizedBox(width: 24),
                  Expanded(child: expertSection),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Satış performansı ve sipariş eğilimleri',
              style:
                  Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
            ),
            const SizedBox(height: 6),
            Text(
              'İptal edilen siparişler hariç, oluşturulmuş tüm TRY siparişleri',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        );

        final filter = SizedBox(
          width: 190,
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
            onChanged: _isLoading
                ? null
                : (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedRange = value;
                    });

                    _loadData();
                  },
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 16),
              filter,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            filter,
          ],
        );
      },
    );
  }

  Widget _buildSummarySection(SalesStatsData data) {
    final cards = [
      _SummaryCardData(
        title: 'Toplam Satış',
        value: _formatMoney(data.summary.totalSales),
        icon: Icons.payments_outlined,
      ),
      _SummaryCardData(
        title: 'Toplam Sipariş',
        value: data.summary.totalOrders.toString(),
        icon: Icons.shopping_bag_outlined,
      ),
      _SummaryCardData(
        title: 'Ortalama Sipariş',
        value: _formatMoney(
          data.summary.averageOrderValue,
        ),
        icon: Icons.bar_chart_outlined,
      ),
      _SummaryCardData(
        title: 'Bekleyen Sipariş Değeri',
        value: _formatMoney(
          data.summary.pendingOrdersValue,
        ),
        icon: Icons.timelapse_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;

        if (constraints.maxWidth >= 1000) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 620) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 110,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];

            return _buildSummaryCard(
              title: card.title,
              value: card.value,
              icon: card.icon,
            );
          },
        );
      },
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
        border: Border.all(
          color: Colors.grey.shade200,
        ),
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
            radius: 23,
            backgroundColor:
                Colors.teal.withOpacity(0.12),
            child: Icon(
              icon,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
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
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildSalesLineChart(
    List<SalesTimePoint> points,
  ) {
    if (points.isEmpty ||
        points.every((point) => point.value == 0)) {
      return _buildEmptyChartState(
        'Seçilen dönemde satış verisi bulunmuyor.',
      );
    }

    final rawMax = points
        .map((point) => point.value)
        .fold<double>(
          0,
          (current, value) =>
              value > current ? value : current,
        );

    final maxY = rawMax <= 0 ? 1.0 : rawMax * 1.20;
    final interval = maxY / 5;

    final bottomInterval =
        points.length > 15 ? 5.0 : 1.0;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles:
                SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles:
                SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 62,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactMoneyAxis(value),
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: bottomInterval,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final index = value.round();

                if (index < 0 ||
                    index >= points.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding:
                      const EdgeInsets.only(top: 8),
                  child: Text(
                    points[index].label,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData:
              LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.round();

                if (index < 0 ||
                    index >= points.length) {
                  return null;
                }

                return LineTooltipItem(
                  '${points[index].label}\n'
                  '${_formatMoney(points[index].value)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            color: Colors.teal,
            dotData: const FlDotData(
              show: true,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withOpacity(0.10),
            ),
            spots: List.generate(
              points.length,
              (index) => FlSpot(
                index.toDouble(),
                points[index].value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBarChart(
    List<ProductSalesDistributionItem> items,
  ) {
    if (items.isEmpty ||
        items.every((item) => item.amount == 0)) {
      return _buildEmptyChartState(
        'Seçilen dönemde ürün satış verisi bulunmuyor.',
      );
    }

    final rawMax = items
        .map((item) => item.amount)
        .fold<double>(
          0,
          (current, value) =>
              value > current ? value : current,
        );

    final maxY = rawMax <= 0 ? 1.0 : rawMax * 1.20;
    final interval = maxY / 5;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles:
                SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles:
                SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactMoneyAxis(value),
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final index = value.round();

                if (index < 0 ||
                    index >= items.length) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding:
                      const EdgeInsets.only(top: 8),
                  child: Text(
                    _productShortLabel(
                      items[index].productType,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData:
              BarTouchTooltipData(
            getTooltipItem: (
              group,
              groupIndex,
              rod,
              rodIndex,
            ) {
              if (groupIndex < 0 ||
                  groupIndex >= items.length) {
                return null;
              }

              final item = items[groupIndex];

              return BarTooltipItem(
                '${item.productType}\n'
                '${_formatMoney(item.amount)}\n'
                '${item.orderCount} sipariş',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(
          items.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: items[index].amount,
                width: 26,
                color: Colors.teal,
                borderRadius:
                    BorderRadius.circular(6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopExpertsList(
    List<ExpertSalesPerformanceItem> items,
  ) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: const Text(
          'Seçilen dönemde uzman satış verisi bulunmuyor.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: List.generate(
        items.length,
        (index) {
          final item = items[index];

          return Container(
            margin:
                const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Colors.teal.withOpacity(0.12),
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
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatMoney(
                        item.totalSales,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.orderCount} sipariş',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyChartState(
    String message,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.query_stats_outlined,
            size: 54,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  String _compactMoneyAxis(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }

    return value.toStringAsFixed(0);
  }
}

class _SalesDateRange {
  final DateTime startDate;
  final DateTime endDate;
  final bool groupByDay;

  const _SalesDateRange({
    required this.startDate,
    required this.endDate,
    required this.groupByDay,
  });
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}