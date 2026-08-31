import 'package:flutter/material.dart';

class RecommendationSideCard extends StatefulWidget {
  final Map<String, dynamic>? mainProduct;
  final List<Map<String, dynamic>> addons;
  final String reason;

  const RecommendationSideCard({
    super.key,
    required this.mainProduct,
    required this.addons,
    required this.reason,
  });

  @override
  State<RecommendationSideCard> createState() => _RecommendationSideCardState();
}

class _RecommendationSideCardState extends State<RecommendationSideCard> {
  final Map<int, bool> _addonSelected = {};

  @override
  Widget build(BuildContext context) {
    if (widget.mainProduct == null) {
      return const SizedBox.shrink();
    }

    double mainPrice =
        double.tryParse(widget.mainProduct!["price"]?.toString() ?? "0") ?? 0;

    double total = mainPrice;

    for (int i = 0; i < widget.addons.length; i++) {
      if (_addonSelected[i] == true) {
        total += double.tryParse(
                widget.addons[i]["price"]?.toString() ?? "0") ??
            0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Öneri başlığı
          const Text(
            "Sizin İçin Önerimiz",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Text(
            widget.reason,
            style: const TextStyle(color: Colors.black87),
          ),

          const SizedBox(height: 20),

          /// Ana ürün
          if (widget.mainProduct!["image"] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.mainProduct!["image"],
                height: 140,
                fit: BoxFit.contain,
              ),
            ),

          const SizedBox(height: 12),

          Text(
            widget.mainProduct!["name"] ?? "",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          Text(
            "${mainPrice.toStringAsFixed(2)} TL",
            style: const TextStyle(fontSize: 16, color: Colors.teal),
          ),

          const SizedBox(height: 20),

          /// Addon list
          ...List.generate(widget.addons.length, (i) {
            final addon = widget.addons[i];
            return CheckboxListTile(
              value: _addonSelected[i] ?? false,
              onChanged: (v) => setState(() => _addonSelected[i] = v ?? false),
              title: Text(addon["name"] ?? ""),
              secondary: Text(
                "+${addon["price"]}₺",
                style: const TextStyle(color: Colors.black54),
              ),
            );
          }),

          const SizedBox(height: 20),

          /// Toplam fiyat
          Text(
            "Toplam: ${total.toStringAsFixed(2)} TL",
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal),
          ),

          const SizedBox(height: 20),

          /// Sepete ekle butonu
          ElevatedButton(
            onPressed: () {
              debugPrint("SEPETE EKLENDİ: $total TL");
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: Colors.teal,
            ),
            child: const Text("Paketi Sepete Ekle"),
          )
        ],
      ),
    );
  }
}
