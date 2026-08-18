import 'package:flutter/material.dart';
import '../../../models/foot_profile.dart';
import 'analysis_card_template.dart';

class ArchAnalysisCard extends StatelessWidget {
  final FootProfile profile;

  const ArchAnalysisCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AnalysisCardTemplate(
      title: "Kavis Değerlendirmesi",

      leftContent: _buildSide(
        title: "Left Foot",
        heatmapAsset: "assets/heatmaps/left_arch.png",
        archHeight: profile.leftArchHeight,
        archType: profile.leftArchType,
        index: _archIndex(profile.leftWidth, profile.leftLength),
      ),

      rightContent: _buildSide(
        title: "Right Foot",
        heatmapAsset: "assets/heatmaps/right_arch.png",
        archHeight: profile.rightArchHeight,
        archType: profile.rightArchType,
        index: _archIndex(profile.rightWidth, profile.rightLength),
      ),

      bottomNote: _buildConclusion(profile),
    );
  }

  /// SOL & SAĞ BÖLÜM TEMASI
  Widget _buildSide({
    required String title,
    required String heatmapAsset,
    required double archHeight,
    required String archType,
    required double index,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        const SizedBox(height: 12),

        /// Isı haritası
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(heatmapAsset, fit: BoxFit.cover),
          ),
        ),

        const SizedBox(height: 12),

        Text("Arch Index: ${index.toStringAsFixed(2)}"),
        Text("Arch Height: ${archHeight.toStringAsFixed(1)} mm"),
        Text("Arch Type: $archType"),
      ],
    );
  }

  /// Arch Index hesaplama
  double _archIndex(double width, double length) {
    if (length == 0) return 0;
    return width / length;
  }

  /// Değerlendirme metni
  String _buildConclusion(FootProfile p) {
    if (p.hasFlatFoot) {
      return "Sol veya sağ ayakta düşük kavis tespit edildi. Bu durum pronasyon ve yorgunluk riskini artırabilir.";
    }

    if (p.hasHighArch) {
      return "Kavis yüksekliği fazla. Basınç dağılımı ön ve arka bölgeye kaymış olabilir.";
    }

    return "Kavis yüksekliği normal aralıktadır.";
  }
}
