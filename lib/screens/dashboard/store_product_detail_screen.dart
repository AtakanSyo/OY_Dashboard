import 'package:flutter/material.dart';
import 'package:oy_site/screens/dashboard/store_screen.dart';
import 'package:oy_site/services/payment/iyzico_checkout_service.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreProductDetailScreen extends StatefulWidget {
  final StoreProduct product;
  final StoreMeasurementSummary measurement;

  const StoreProductDetailScreen({
    super.key,
    required this.product,
    required this.measurement,
  });

  @override
  State<StoreProductDetailScreen> createState() =>
      _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends State<StoreProductDetailScreen> {
  final IyzicoCheckoutService _checkoutService = IyzicoCheckoutService();
  bool _isStartingPayment = false;

  Future<void> _startPayment() async {
    if (_isStartingPayment) return;

    setState(() => _isStartingPayment = true);
    try {
      final checkout = await _checkoutService.initializeCheckout(
        productId: widget.product.id,
      );
      final url = checkout.paymentPageUrl!;
      final uri = Uri.tryParse(url);
      if (uri == null) {
        throw Exception('Geçersiz ödeme URL\'i alındı.');
      }

      final opened = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!opened) {
        throw Exception('Ödeme sayfası açılamadı.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme başlatılamadı: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildMeasurementCard(
                  measurement: widget.measurement,
                  compact: false,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey.shade100,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    widget.product.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    widget.product.icon,
                                    size: 18,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.product.shortDescription,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    height: 1.4,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  widget.product.priceLabel,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(
                        title: 'Ürün Hakkında',
                        content: widget.product.fullDescription,
                      ),
                      const SizedBox(height: 18),
                      _buildInfoSection(
                        title: widget.product.usageTitle,
                        content: widget.product.usageDescription,
                      ),
                      const SizedBox(height: 18),
                      _buildInfoSection(
                        title: 'Neden Bu Ürün Öneriliyor?',
                        content: widget.product.whyRecommended,
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: _isStartingPayment ? null : _startPayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isStartingPayment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Satın Al',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[800],
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
