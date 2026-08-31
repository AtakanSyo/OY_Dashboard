import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

import 'product_card.dart';

class ProductGrid extends StatefulWidget {
  const ProductGrid({super.key});

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final rawData = await rootBundle.loadString('assets/products.csv');
    final csvTable = const CsvToListConverter().convert(rawData);

    final headers = csvTable.first.cast<String>();
    final list = csvTable.skip(1).map((row) {
      return Map<String, dynamic>.fromIterables(headers, row);
    }).toList();

    setState(() => _products = list);
  }

  @override
  Widget build(BuildContext context) {
    if (_products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.68,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (context, i) {
        final p = _products[i];
        return ProductCard(
          name: p['name'],
          price: double.parse(p['price'].toString()),
          category: p['category'],
          image: p['image'],
          onAddToCart: () {
            print("Sepete eklendi: ${p['name']}");
          },
        );
      },
    );
  }
}
