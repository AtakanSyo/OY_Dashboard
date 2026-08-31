import 'package:flutter/material.dart';

class OrderCard extends StatefulWidget {
  final String orderId;
  final String date;
  final String productName;
  final double price;
  final String status;
  final String trackingCode;
  final String userEmail;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.date,
    required this.productName,
    required this.price,
    required this.status,
    required this.trackingCode,
    required this.userEmail,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isHovered = false;

  /// Sipariş adımları
  final List<String> _steps = const [
    "Hazırlanıyor",
    "Kargoya Verildi",
    "Yolda",
    "Teslim Edildi",
  ];

  /// CSV'den gelen status → timeline index eşlemesi
  int get _currentStepIndex {
    switch (widget.status.toLowerCase()) {
      case "processing":
        return 0;
      case "shipped":
        return 1;
      case "in_transit":
        return 2;
      case "delivered":
        return 3;
      default:
        return 0;
    }
  }

  void _setHover(bool value) {
    setState(() {
      _isHovered = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isHovered ? 1.03 : 1.0;

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: GestureDetector(
        onTap: () => _setHover(!_isHovered), // mobilde dokunarak aç/kapat
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: _isHovered ? 18 : 8,
                  spreadRadius: _isHovered ? 4 : 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Üst Bilgiler (ID + Tarih)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "#${widget.orderId}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.date,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Ürün adı
                Text(
                  widget.productName,
                  style: const TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 6),

                // Fiyat
                Text(
                  "₺${widget.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 16),

                // Hover'da açılan kısım
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState: _isHovered
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildExpandedArea(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hover sırasında görünen detay alanı (timeline + tracking + status)
  Widget _buildExpandedArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol dikey çizgi + noktalar
            Column(
              children: List.generate(_steps.length, (i) {
                Color color;
                if (i < _currentStepIndex) {
                  color = Colors.green; // önceki adımlar
                } else if (i == _currentStepIndex) {
                  color = Colors.orange; // şu anki adım
                } else {
                  color = Colors.grey; // gelecek adımlar
                }

                return Column(
                  children: [
                    Icon(Icons.circle, size: 14, color: color),
                    if (i != _steps.length - 1)
                      Container(
                        width: 2,
                        height: 30,
                        color: color.withOpacity(0.6),
                      ),
                  ],
                );
              }),
            ),

            const SizedBox(width: 12),

            // Sağ tarafta adım isimleri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_steps.length, (i) {
                  Color color;
                  FontWeight weight = FontWeight.normal;

                  if (i < _currentStepIndex) {
                    color = Colors.green;
                  } else if (i == _currentStepIndex) {
                    color = Colors.orange;
                    weight = FontWeight.bold;
                  } else {
                    color = Colors.grey;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Text(
                      _steps[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: weight,
                        color: color,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Tracking kodu
        Row(
          children: [
            const Icon(Icons.qr_code, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              widget.trackingCode.isEmpty
                  ? "Takip Kodu: —"
                  : "Takip Kodu: ${widget.trackingCode}",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Durum
        Row(
          children: [
            const Icon(Icons.info, size: 18, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              "Durum: ${widget.status}",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
