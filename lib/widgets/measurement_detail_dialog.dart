import 'package:flutter/material.dart';
import '../../../models/foot_profile.dart';
import '../../widgets/analysis/arch_analysis_card.dart';
import '../../services/recommendation_engine.dart';

class MeasurementDetailDialog extends StatelessWidget {
  final FootProfile profile;
  final Map<String, Map<String, dynamic>> products;

  const MeasurementDetailDialog({
    super.key,
    required this.profile,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        height: 650,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// -------------------------------------------------------
            /// TITLE BAR
            /// -------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ölçüm Detayı – ${profile.dateString}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// -------------------------------------------------------
            /// BODY (scrollable)
            /// -------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// 🔥 1) ARCH ANALYSIS CARD
                    ArchAnalysisCard(profile: profile),

                    /// 🔥 2) DİĞER ANALİZLER (buraya ekleyeceğiz)
                    // PronationAnalysisCard(profile: profile),
                    // HalluxAnalysisCard(profile: profile),

                    const SizedBox(height: 24),
                    const Divider(height: 40),

                    /// 🔥 3) ÜRÜN ÖNERİLERİ
                    _buildRecommendations(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // 🔥 TEK ÖLÇÜME ÖZEL ÜRÜN ÖNERİLERİ
  // =====================================================================
  Widget _buildRecommendations() {
    final package = RecommendationEngine.generate(profile);

    final mainProduct = products[package.mainProductId];
    final addons = package.addonProductIds
        .map((id) => products[id])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Bu Ölçüme Göre Önerilen Ürünler",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (mainProduct == null)
          const Text("⚠ Ürün önerisi bulunamadı."),

        if (mainProduct != null) ...[
          Text(
            "Ana Ürün: ${mainProduct['name']}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            package.reason,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 12),
        ],

        if (addons.isNotEmpty)
          const Text("Ek Öneriler:",
              style: TextStyle(fontWeight: FontWeight.bold)),

        ...addons.map((p) => Text("- ${p['name']}")),
      ],
    );
  }
}
