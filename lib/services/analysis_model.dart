import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Ayak Değerlendirmesi"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve tarih
            const Text(
              "John S - Değerlendirme Tarihi: 21.09.2025",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1️⃣ Kavis Yüksekliği
            _buildCard(
              "Kavis Yüksekliği (mm)",
              BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: true),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: 11.5, color: Colors.blueAccent),
                      ],
                      showingTooltipIndicators: [0],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: 12.7, color: Colors.orangeAccent),
                      ],
                      showingTooltipIndicators: [0],
                    ),
                  ],
                ),
              ),
              const ["Sol", "Sağ"],
            ),

            const SizedBox(height: 24),

            // 2️⃣ Açı Değerlendirmesi
            _buildCard(
              "Duruş Açıları (°)",
              LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [FlSpot(0, 7.1), FlSpot(1, 6.8), FlSpot(2, -7.1)],
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
              const ["Hallux", "Topuk", "Pronasyon"],
            ),

            const SizedBox(height: 24),

            // 3️⃣ Uzunluk ve Genişlik
            _buildCard(
              "Ayak Uzunluk / Genişlik (mm)",
              BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(show: true),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: 262.5, color: Colors.blueAccent),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: 260.4, color: Colors.orangeAccent),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(toY: 107.6, color: Colors.blueAccent),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(toY: 106.7, color: Colors.orangeAccent),
                      ],
                    ),
                  ],
                ),
              ),
              const ["Sol Uz", "Sağ Uz", "Sol Geniş", "Sağ Geniş"],
            ),

            const SizedBox(height: 24),

            // 📝 Not kutusu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                "Uzman Notu: Kullanıcının her iki ayağında da orta düzeyde kavis düşüklüğü mevcut. "
                "Orta sertlikte tabanlık önerilir. Sağ ayakta pronasyon eğilimi gözlemlenmiştir.",
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, Widget chart, List<String> labels) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 200, child: chart),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: labels
                .map((e) => Text(e, style: const TextStyle(fontSize: 12)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
