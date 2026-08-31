import 'package:flutter/material.dart';
import '../../../models/foot_profile.dart';
import 'measurement_detail_dialog.dart';

class MeasurementCard extends StatefulWidget {
  final FootProfile profile;
  final Map<String, Map<String, dynamic>> products;

  const MeasurementCard({
    super.key,
    required this.profile,
    required this.products,
  });

  @override
  State<MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<MeasurementCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    /// Sol + Sağ değerleri tek satır halinde birleştirme yardımcıları
    String mergeStr(String left, String right) {
      if (left == right) return left;
      return "L: $left / R: $right";
    }

    String mergeNum(double left, double right) {
      if (left == right) {
        return "${left.toStringAsFixed(1)} mm";
      }
      return "L: ${left.toStringAsFixed(1)} / R: ${right.toStringAsFixed(1)} mm";
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => MeasurementDetailDialog(
              profile: p,
              products: widget
                  .products, // Yeni değerlendirme ekranına ürünleri geçir.
            ),
          ),
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(16),
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
                /// TARİH
                Text(
                  p.dateString,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 12),

                /// === 5 ANA BULGU ===
                _buildRow("Foot Length", mergeNum(p.leftLength, p.rightLength)),

                _buildRow(
                  "Arch Type",
                  mergeStr(p.leftArchType, p.rightArchType),
                ),

                _buildRow(
                  "Pronation",
                  mergeStr(p.leftPronType, p.rightPronType),
                ),

                _buildRow("Toe Type", mergeStr(p.leftToeType, p.rightToeType)),

                _buildRow(
                  "Hallux Type",
                  mergeStr(p.leftHalluxType, p.rightHalluxType),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// --- UI HELPER ---
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
