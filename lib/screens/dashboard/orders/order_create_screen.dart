import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/order_model.dart';

class OrderCreateScreen extends StatefulWidget {
  final AppUser currentUser;
  final MeasurementSession session;

  const OrderCreateScreen({
    super.key,
    required this.currentUser,
    required this.session,
  });

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final TextEditingController _grossAmountController = TextEditingController();
  final TextEditingController _discountAmountController =
      TextEditingController();

  String _selectedProductType = 'insole';
  String _selectedCurrencyCode = 'TRY';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _grossAmountController.text = '0';
    _discountAmountController.text = '0';
  }

  @override
  void dispose() {
    _grossAmountController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }

  double _parseDouble(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  double get _grossAmount => _parseDouble(_grossAmountController.text);
  double get _discountAmount => _parseDouble(_discountAmountController.text);
  double get _netAmount {
    final value = _grossAmount - _discountAmount;
    return value < 0 ? 0 : value;
  }

  String _generateOrderNo() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return 'ORD-${now.year}$month$day-$hour$minute';
  }

  String _productLabel(String productType) {
    switch (productType) {
      case 'insole':
        return 'Tabanlık';
      case 'sports_insole':
        return 'Spor Tabanlık';
      case 'sandal':
        return 'Sandalet';
      default:
        return productType;
    }
  }

  Future<void> _createOrder() async {
    if (_grossAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir brüt tutar girin.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    final order = OrderModel(
      orderId: DateTime.now().millisecondsSinceEpoch,
      sessionId: widget.session.sessionId ?? 0,
      patientId: widget.session.patientId,
      clinicId: widget.session.clinicId,
      expertUserId: widget.session.expertUserId,
      assignedOptityouUserId: widget.session.assignedOptityouUserId,
      orderNo: _generateOrderNo(),
      productType: _selectedProductType,
      orderStatus: OrderStatuses.pending,
      currencyCode: _selectedCurrencyCode,
      grossAmount: _grossAmount,
      discountAmount: _discountAmount,
      netAmount: _netAmount,
      orderedAt: DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    Navigator.pop(context, order);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Oluştur'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _createOrder,
        backgroundColor: Colors.teal,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.shopping_bag, color: Colors.white),
        label: const Text(
          'Siparişi Oluştur',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
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
          const Text(
            'Oturumdan Siparişe Geçiş',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Session: ${widget.session.sessionCode}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            'Patient ID: ${widget.session.patientId} • Clinic ID: ${widget.session.clinicId}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          Text(
            'Uzman: ${widget.currentUser.displayName}',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
          const Text(
            'Sipariş Bilgileri',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: _selectedProductType,
            decoration: const InputDecoration(
              labelText: 'Ürün Tipi',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'insole',
                child: Text('Tabanlık'),
              ),
              DropdownMenuItem(
                value: 'sports_insole',
                child: Text('Spor Tabanlık'),
              ),
              DropdownMenuItem(
                value: 'sandal',
                child: Text('Sandalet'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedProductType = value;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedCurrencyCode,
            decoration: const InputDecoration(
              labelText: 'Para Birimi',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'TRY',
                child: Text('TRY'),
              ),
              DropdownMenuItem(
                value: 'USD',
                child: Text('USD'),
              ),
              DropdownMenuItem(
                value: 'EUR',
                child: Text('EUR'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCurrencyCode = value;
                });
              }
            },
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _grossAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Brüt Tutar',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _discountAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'İndirim Tutarı',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Ürün', _productLabel(_selectedProductType)),
                _buildSummaryRow('Brüt Tutar',
                    '${_grossAmount.toStringAsFixed(2)} $_selectedCurrencyCode'),
                _buildSummaryRow('İndirim',
                    '${_discountAmount.toStringAsFixed(2)} $_selectedCurrencyCode'),
                const Divider(),
                _buildSummaryRow(
                  'Net Tutar',
                  '${_netAmount.toStringAsFixed(2)} $_selectedCurrencyCode',
                  isBold: true,
                ),
                _buildSummaryRow(
                  'Başlangıç Durumu',
                  'Beklemede',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}