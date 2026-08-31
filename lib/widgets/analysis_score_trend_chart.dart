import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';

class AnalysisScoreTrendChart extends StatelessWidget {
  final String title;
  final List<CustomerAnalysisResult> results;
  final double Function(CustomerAnalysisResult result) leftScoreSelector;
  final double Function(CustomerAnalysisResult result) rightScoreSelector;

  const AnalysisScoreTrendChart({
    super.key,
    required this.title,
    required this.results,
    required this.leftScoreSelector,
    required this.rightScoreSelector,
  });

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}';
  }

  List<double> _collectValidValues(List<CustomerAnalysisResult> sortedResults) {
    return [
      ...sortedResults.map(leftScoreSelector),
      ...sortedResults.map(rightScoreSelector),
    ].where((value) => value > 0).toList();
  }

  double _minValue(List<double> values) {
    return values.reduce((a, b) => a < b ? a : b);
  }

  double _maxValue(List<double> values) {
    return values.reduce((a, b) => a > b ? a : b);
  }

  double _calculateMinY(List<double> values) {
    if (values.isEmpty) return 0;

    final minValue = _minValue(values);
    final maxValue = _maxValue(values);
    final range = maxValue - minValue;

    if (range == 0) {
      return (minValue - _singleValuePadding(minValue))
          .clamp(0, double.infinity)
          .toDouble();
    }

    final padding = range * 0.25;
    return (minValue - padding).clamp(0, double.infinity).toDouble();
  }

  double _calculateMaxY(List<double> values) {
    if (values.isEmpty) return 100;

    final minValue = _minValue(values);
    final maxValue = _maxValue(values);
    final range = maxValue - minValue;

    if (range == 0) {
      return maxValue + _singleValuePadding(maxValue);
    }

    final padding = range * 0.25;
    return maxValue + padding;
  }

  double _singleValuePadding(double value) {
    if (value <= 10) return 2;
    if (value <= 30) return 5;
    if (value <= 100) return 10;
    return value * 0.1;
  }

  double _calculateInterval(double minY, double maxY) {
    final range = maxY - minY;

    if (range <= 5) return 1;
    if (range <= 10) return 2;
    if (range <= 25) return 5;
    if (range <= 50) return 10;
    if (range <= 100) return 20;

    return (range / 5).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    final sortedResults = [...results]
      ..sort((a, b) => a.analysisDate.compareTo(b.analysisDate));

    final leftSpots = <FlSpot>[];
    final rightSpots = <FlSpot>[];

    for (int i = 0; i < sortedResults.length; i++) {
      leftSpots.add(
        FlSpot(i.toDouble(), leftScoreSelector(sortedResults[i])),
      );
      rightSpots.add(
        FlSpot(i.toDouble(), rightScoreSelector(sortedResults[i])),
      );
    }

    final validValues = _collectValidValues(sortedResults);
    final minY = _calculateMinY(validValues);
    final maxY = _calculateMaxY(validValues);
    final interval = _calculateInterval(minY, maxY);

    return Container(
      width: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildLegendDot('Sol Ayak', Colors.teal),
              const SizedBox(width: 12),
              _buildLegendDot('Sağ Ayak', Colors.orange),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatAxisValue(value),
                          style: const TextStyle(fontSize: 11),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (value % 1 != 0 ||
                            index < 0 ||
                            index >= sortedResults.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _formatShortDate(sortedResults[index].analysisDate),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: leftSpots,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.teal,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: rightSpots,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.orange,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value.abs() >= 100) return value.toStringAsFixed(0);
    if (value.abs() >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(1);
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}