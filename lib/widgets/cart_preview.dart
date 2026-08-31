import 'package:flutter/material.dart';

class CartPreview extends StatelessWidget {
  const CartPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart, size: 40, color: Colors.teal),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Sepetiniz", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("2 ürün - ₺548.00", style: TextStyle(fontSize: 14)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text("Sepeti Gör"),
          ),
        ],
      ),
    );
  }
}
