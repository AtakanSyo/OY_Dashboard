import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_customer_home_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_home_model.dart';

class CustomerHomeScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerHomeScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _repo = MockCustomerHomeRepository();

  bool _isLoading = true;
  CustomerHomeData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.getHomeData();

    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}.${date.month}.${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Üretimde':
        return Colors.orange;
      case 'Kargoda':
        return Colors.blue;
      case 'Teslim Edildi':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildWelcomeCard(d),
          const SizedBox(height: 20),
          _buildOrderCard(d),
          const SizedBox(height: 20),
          _buildRecommendationCard(d),
          const SizedBox(height: 20),
          _buildProductSuggestionCard(d),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _buildWelcomeCard(CustomerHomeData d) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoş geldiniz, ${d.patientName}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text('Son analiz: ${_formatDate(d.lastAnalysisDate)}'),
          const SizedBox(height: 10),
          Text(d.summary),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CustomerHomeData d) {
    final color = _statusColor(d.orderStatus);

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktif Sipariş',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(d.orderNo),
          const SizedBox(height: 4),
          Text(d.productName),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                d.orderStatus,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('Tahmini: ${_formatDate(d.estimatedDelivery)}'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(CustomerHomeData d) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Size Özel Öneri',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(d.recommendationNote),
        ],
      ),
    );
  }

  Widget _buildProductSuggestionCard(CustomerHomeData d) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Önerilen Ürün',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            d.suggestedProductName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(d.suggestedProductDescription),
          const SizedBox(height: 10),
          Text('${d.suggestedProductPrice} TL'),
        ],
      ),
    );
  }
}