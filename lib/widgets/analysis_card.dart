import 'package:flutter/material.dart';

class AnalysisCard extends StatelessWidget {
  final String title;               // Örn: "Arch Analysis"
  final String leftImage;           // L görseli
  final String rightImage;          // R görseli
  final List<Map<String, String>> metrics; // ölçüm listesi
  final String conclusion;          // Değerlendirme metni

  const AnalysisCard({
    super.key,
    required this.title,
    required this.leftImage,
    required this.rightImage,
    required this.metrics,
    required this.conclusion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Başlık
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          /// Sağ & Sol görseller
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildImageBox("Left", leftImage),
              _buildImageBox("Right", rightImage),
            ],
          ),

          const SizedBox(height: 20),

          /// Ölçüm değerleri listesi
          ...metrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m["label"]!, style: const TextStyle(color: Colors.black54)),
                    Text(
                      m["value"]!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 16),

          /// Sonuç / değerlendirme
          Text(
            conclusion,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBox(String label, String url) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
            image: DecorationImage(
              image: AssetImage(url), // veya NetworkImage(url)
              fit: BoxFit.cover,
            ),
          ),
        )
      ],
    );
  }
}
