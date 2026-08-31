import 'package:flutter/material.dart';
import 'product_card.dart';

class SuggestedProductsCarousel extends StatelessWidget {
  const SuggestedProductsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    // Şimdilik statik örnek veriler
    final suggestions = [
      {
        'name': 'Ortopedik Tabanlık 1',
        'price': 349.00,
        'image': 'assets/images/tb1.png',
        'category': 'tabanlik'
      },
      {
        'name': 'Hallux Gece Ateli',
        'price': 199.00,
        'image': 'assets/images/hallux1.png',
        'category': 'hallux'
      },
    ];

    return SizedBox(
      height: 350,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, i) {
          final p = suggestions[i];

          return SizedBox(
            width: 260,
            child: ProductCard(
              name: p['name'].toString(),
              price: double.tryParse(p['price'].toString()) ?? 0.0,
              category: p['category'].toString(),
              image: p['image'].toString(),
              onAddToCart: () {
                print("${p['name']} sepete eklendi!");
              },
            ),
          );
        },
      ),
    );
  }
}
