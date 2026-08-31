import 'package:flutter/material.dart';

class SuggestedRecommendationCard extends StatefulWidget {
  final String mainImage;
  final String mainName;
  final double mainPrice;

  final List<Map<String, dynamic>> addons;

  final Function(List<Map<String, dynamic>>) onAddToCart;

  const SuggestedRecommendationCard({
    super.key,
    required this.mainImage,
    required this.mainName,
    required this.mainPrice,
    required this.addons,
    required this.onAddToCart,
  });

  @override
  State<SuggestedRecommendationCard> createState() =>
      _SuggestedRecommendationCardState();
}

class _SuggestedRecommendationCardState extends State<SuggestedRecommendationCard> {
  late List<bool> selectedAddons;

  @override
  void initState() {
    super.initState();
    selectedAddons = List.filled(widget.addons.length, false);
  }

  double get totalPrice {
    double sum = widget.mainPrice;
    for (int i = 0; i < widget.addons.length; i++) {
      if (selectedAddons[i]) {
        sum += widget.addons[i]['price'];
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// --- Başlık ---
          const Text(
            "Size Özel Öneri",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          /// --- Ana Ürün ---
          Row(
            children: [
              Image.asset(
                widget.mainImage,
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.mainName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                "${widget.mainPrice.toStringAsFixed(2)} ₺",
                style: const TextStyle(fontSize: 18, color: Colors.teal),
              )
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          /// --- Yan Ürünler ---
          const Text(
            "Eklenebilir Ürünler",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Column(
            children: List.generate(widget.addons.length, (index) {
              final addon = widget.addons[index];

              final bool isSelected = selectedAddons[index];

              return GestureDetector(
                onTap: () {
                  setState(() => selectedAddons[index] = !isSelected);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? Colors.green[50] : Colors.grey[100],
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          addon['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.green[900] : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        "+${addon['price']} ₺",
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? Colors.green : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),
          const Divider(),

          /// --- Toplam + Sepete Ekle ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Toplam: ${totalPrice.toStringAsFixed(2)} ₺",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final selectedItems = <Map<String, dynamic>>[];

                  selectedItems.add({
                    "name": widget.mainName,
                    "price": widget.mainPrice,
                    "type": "main"
                  });

                  for (int i = 0; i < widget.addons.length; i++) {
                    if (selectedAddons[i]) {
                      selectedItems.add(widget.addons[i]);
                    }
                  }

                  widget.onAddToCart(selectedItems);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Sepete Ekle"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
