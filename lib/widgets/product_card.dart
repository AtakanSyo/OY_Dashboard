import 'package:flutter/material.dart';

class ProductCard extends StatefulWidget {
  final String name;
  final double price;
  final String image;
  final String category;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.onAddToCart,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.015 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: _isHovered ? 18 : 8,
              spreadRadius: _isHovered ? 3 : 1,
            ),
          ],
        ),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),

        // 🔥 overflow çözümü
        child: Column(
          mainAxisSize: MainAxisSize.min,   // ✔ içerik kadar yer
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ÜRÜN RESMİ
            SizedBox(
              height: 130,                   // ✔ sabit yükseklik overflow'u kesiyor
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  widget.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.category.toUpperCase(),
                style: const TextStyle(fontSize: 12, color: Colors.teal),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "₺${widget.price.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text("Sepete Ekle"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
