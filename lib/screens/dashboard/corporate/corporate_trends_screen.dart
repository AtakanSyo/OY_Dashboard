import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_corporate_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';

class CorporateTrendsScreen extends StatefulWidget {
  final AppUser currentUser;

  const CorporateTrendsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CorporateTrendsScreen> createState() => _CorporateTrendsScreenState();
}

class _CorporateTrendsScreenState extends State<CorporateTrendsScreen> {
  final MockCorporateRepository _repository = MockCorporateRepository();

  bool _isLoading = true;
  Map<String, List<CorporateTrendPoint>> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repository.getTrendData();
    if (!mounted) return;

    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _TrendCard(
              title: 'Ortalama Risk Skoru',
              points: _data['risk'] ?? const [],
            ),
            _TrendCard(
              title: 'Pronasyon Eğilimi',
              points: _data['pronation'] ?? const [],
            ),
            _TrendCard(
              title: 'Basınç Yüklenme Endeksi',
              points: _data['pressure'] ?? const [],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String title;
  final List<CorporateTrendPoint> points;

  const _TrendCard({
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final spots = points.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Container(
      width: 380,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
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
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[index].label,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    barWidth: 3,
                    spots: spots,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}