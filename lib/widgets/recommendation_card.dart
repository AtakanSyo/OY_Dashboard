import 'package:flutter/material.dart';
import '../services/recommendation_engine.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendedPackage package;
  final Map<String, dynamic> products;

  const RecommendationCard({
    super.key,
    required this.package,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final mainProduct = products[package.mainProductId];
    final addons = package.addonProductIds.map((id) => products[id]).toList();

    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            "Size Özel Öneri",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(package.reason),
          const SizedBox(height: 20),

          Text("Ana Ürün", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _buildProductTile(mainProduct),

          const SizedBox(height: 16),
          Text("Ek Olarak Önerilenler:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          ...addons.map((a) => _buildProductTile(a)),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              print("Paket sepete eklendi!");
            },
            child: Text("Paketi Sepete Ekle"),
          )
        ],
      ),
    );
  }

  Widget _buildProductTile(Map<String, dynamic>? product) {
    if (product == null) return const SizedBox();

    return ListTile(
      leading: Image.asset(product["image"], height: 50),
      title: Text(product["name"]),
      subtitle: Text("${product["price"]}₺"),
    );
  }
}
