import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { line, bar }

class AnalysisChart extends StatelessWidget {
  final String title;
  final List<double> leftValues;
  final List<double> rightValues;
  final List<String> labels;
  final ChartType chartType;
  final Color leftColor;
  final Color rightColor;

  const AnalysisChart({
    super.key,
    required this.title,
    required this.leftValues,
    required this.rightValues,
    required this.labels,
    this.chartType = ChartType.line,
    this.leftColor = Colors.teal,
    this.rightColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: chartType == ChartType.line
                  ? _buildLineChart()
                  : _buildBarChart(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(leftColor, "Sol Ayak"),
                const SizedBox(width: 12),
                _buildLegend(rightColor, "Sağ Ayak"),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 📈 Çizgi grafiği
  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Text(labels[index], style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: leftColor,
            spots: [
              for (int i = 0; i < leftValues.length; i++)
                FlSpot(i.toDouble(), leftValues[i])
            ],
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            isCurved: true,
            color: rightColor,
            spots: [
              for (int i = 0; i < rightValues.length; i++)
                FlSpot(i.toDouble(), rightValues[i])
            ],
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // 📊 Bar grafiği
  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (int i = 0; i < labels.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(toY: leftValues[i], color: leftColor, width: 8),
                BarChartRodData(toY: rightValues[i], color: rightColor, width: 8),
              ],
            ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Text(labels[index], style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
