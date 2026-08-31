import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrendChart extends StatelessWidget {
  final String title;
  final List<double> pointsLeft;
  final List<double> pointsRight;

  const TrendChart({
    super.key,
    required this.title,
    required this.pointsLeft,
    required this.pointsRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: _toSpots(pointsLeft),
                    color: Colors.teal,
                    isCurved: true,
                    barWidth: 3,
                  ),
                  LineChartBarData(
                    spots: _toSpots(pointsRight),
                    color: Colors.orange,
                    isCurved: true,
                    barWidth: 3,
                  ),
                ],
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _toSpots(List<double> values) {
    return [
      for (int i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), values[i]),
    ];
  }
}
