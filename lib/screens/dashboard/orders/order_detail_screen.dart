import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/order_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final OrderModel order;

  const OrderDetailScreen({
    super.key,
    required this.currentUser,
    required this.order,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final SupabaseOrderRepository _orderRepository = SupabaseOrderRepository();

  late OrderModel _order;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);

    try {
      final now = DateTime.now();

      final updatedOrder = _order.copyWith(
        orderStatus: newStatus,
        shippedAt: newStatus == OrderStatuses.shipped && _order.shippedAt == null
            ? now
            : _order.shippedAt,
        deliveredAt:
            newStatus == OrderStatuses.delivered && _order.deliveredAt == null
                ? now
                : _order.deliveredAt,
      );

      await _orderRepository.updateOrder(updatedOrder);

      if (!mounted) return;

      setState(() {
        _order = updatedOrder;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş durumu güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isUpdating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş güncellenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatMoney(double amount, String currencyCode) {
    return '${amount.toStringAsFixed(2)} $currencyCode';
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

  String _statusLabel(String status) {
    switch (status) {
      case OrderStatuses.pending:
        return 'Beklemede';
      case OrderStatuses.designing:
        return 'Tasarımda';
      case OrderStatuses.production:
        return 'Üretimde';
      case OrderStatuses.shipped:
        return 'Kargoda';
      case OrderStatuses.delivered:
        return 'Teslim Edildi';
      case OrderStatuses.cancelled:
        return 'İptal';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case OrderStatuses.pending:
        return Colors.orange;
      case OrderStatuses.designing:
        return Colors.deepPurple;
      case OrderStatuses.production:
        return Colors.blue;
      case OrderStatuses.shipped:
        return Colors.teal;
      case OrderStatuses.delivered:
        return Colors.green;
      case OrderStatuses.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _currentStepIndex() {
    switch (_order.orderStatus) {
      case OrderStatuses.pending:
        return 0;
      case OrderStatuses.designing:
        return 1;
      case OrderStatuses.production:
        return 2;
      case OrderStatuses.shipped:
        return 3;
      case OrderStatuses.delivered:
        return 4;
      case OrderStatuses.cancelled:
        return 0;
      default:
        return 0;
    }
  }

  List<_OrderFlowStep> _buildOrderSteps() {
    final currentStep = _currentStepIndex();

    return [
      _OrderFlowStep(
        icon: Icons.receipt_long,
        title: 'Sipariş Alındı',
        subtitle: 'Sipariş sisteme kaydedildi ve işleme alındı.',
        isCompleted: currentStep >= 0,
      ),
      _OrderFlowStep(
        icon: Icons.design_services,
        title: 'Tasarım Hazırlığı',
        subtitle: 'Teknik tasarım ve üretim hazırlıkları yapılıyor.',
        isCompleted: currentStep >= 1,
      ),
      _OrderFlowStep(
        icon: Icons.precision_manufacturing,
        title: 'Üretim',
        subtitle: 'Ürün üretim sürecinde.',
        isCompleted: currentStep >= 2,
      ),
      _OrderFlowStep(
        icon: Icons.local_shipping,
        title: 'Kargoya Verildi',
        subtitle: 'Sipariş sevkiyata hazırlandı ve gönderildi.',
        isCompleted: currentStep >= 3,
      ),
      _OrderFlowStep(
        icon: Icons.home_filled,
        title: 'Teslim Edildi',
        subtitle: 'Sipariş alıcıya ulaştı.',
        isCompleted: currentStep >= 4,
      ),
    ];
  }

  bool get _canUpdateOrder =>
      !widget.currentUser.isCustomer && _order.orderId != null;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_order.orderStatus);
    final steps = _buildOrderSteps();
    final completedCount = steps.where((e) => e.isCompleted).length;
    final progress = steps.isEmpty ? 0.0 : completedCount / steps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Detayı'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(statusColor),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildOrderInfoCard(),
                          const SizedBox(height: 16),
                          _buildDeliveryAddressCard(),
                          if (_canUpdateOrder) ...[
                            const SizedBox(height: 16),
                            _buildStatusUpdateCard(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildFlowCard(progress, steps),
                          const SizedBox(height: 16),
                          _buildPriceCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: statusColor.withOpacity(0.12),
            child: Icon(
              Icons.shopping_bag,
              size: 34,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order.orderNo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ürün: ${_productLabel(_order.productType)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 6),
                Text(
                  'İşlem yapan kullanıcı: ${widget.currentUser.displayName}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel(_order.orderStatus),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return _buildSectionCard(
      title: 'Sipariş Bilgileri',
      child: Column(
        children: [
          _buildKeyValueRow('Order ID', _order.orderId?.toString() ?? '—'),
          _buildKeyValueRow('Session ID', _order.sessionId.toString()),
          _buildKeyValueRow('Patient ID', _order.patientId.toString()),
          _buildKeyValueRow('Clinic ID', _order.clinicId.toString()),
          _buildKeyValueRow('Expert User ID', _order.expertUserId.toString()),
          _buildKeyValueRow(
            'Assigned OptiYou User ID',
            _order.assignedOptityouUserId?.toString() ?? '—',
          ),
          _buildKeyValueRow('Sipariş Tarihi', _formatDate(_order.orderedAt)),
          _buildKeyValueRow('Kargo Tarihi', _formatDate(_order.shippedAt)),
          _buildKeyValueRow('Teslim Tarihi', _formatDate(_order.deliveredAt)),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard() {
    final snapshot = _order.deliveryAddressSnapshot;

    if (snapshot == null || snapshot.isEmpty) {
      return _buildSectionCard(
        title: 'Teslimat Adresi',
        child: Text(
          'Teslimat adresi bulunamadı.',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    final title = snapshot['title']?.toString() ?? 'Teslimat Adresi';
    final fullName = snapshot['full_name']?.toString() ?? '—';
    final phone = snapshot['phone']?.toString() ?? '—';
    final city = snapshot['city']?.toString() ?? '—';
    final district = snapshot['district']?.toString() ?? '—';
    final addressLine = snapshot['address_line']?.toString() ?? '—';

    return _buildSectionCard(
      title: 'Teslimat Adresi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$fullName • $phone'),
          const SizedBox(height: 6),
          Text('$addressLine, $district/$city'),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateCard() {
    return _buildSectionCard(
      title: 'Durum Güncelle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _order.orderStatus,
            decoration: const InputDecoration(
              labelText: 'Sipariş Durumu',
              border: OutlineInputBorder(),
            ),
            items: OrderStatuses.values.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(_statusLabel(status)),
              );
            }).toList(),
            onChanged: _isUpdating
                ? null
                : (value) {
                    if (value == null || value == _order.orderStatus) return;
                    _updateStatus(value);
                  },
          ),
          if (_isUpdating) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildFlowCard(double progress, List<_OrderFlowStep> steps) {
    return _buildSectionCard(
      title: 'Üretim / Sipariş Akışı',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tamamlanma Oranı: ${(progress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 22),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            return _buildFlowStep(step: step, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildPriceCard() {
    return _buildSectionCard(
      title: 'Fiyat Bilgileri',
      child: Column(
        children: [
          _buildKeyValueRow(
            'Brüt Tutar',
            _formatMoney(_order.grossAmount, _order.currencyCode),
          ),
          _buildKeyValueRow(
            'İndirim',
            _formatMoney(_order.discountAmount, _order.currencyCode),
          ),
          _buildKeyValueRow(
            'Net Tutar',
            _formatMoney(_order.netAmount, _order.currencyCode),
          ),
          _buildKeyValueRow('Para Birimi', _order.currencyCode),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
        ),
      ],
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep({
    required _OrderFlowStep step,
    required bool isLast,
  }) {
    final color = step.isCompleted ? Colors.green : Colors.orange;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Icon(
                  step.isCompleted ? Icons.check : step.icon,
                  color: color,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 110,
                  margin: const EdgeInsets.only(top: 2, bottom: 2),
                  decoration: BoxDecoration(
                    color: step.isCompleted
                        ? Colors.green.withOpacity(0.45)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: step.isCompleted
                      ? Colors.green.withOpacity(0.35)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: step.isCompleted
                                ? Colors.green.withOpacity(0.12)
                                : Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            step.isCompleted ? 'Tamamlandı' : 'Bekliyor',
                            style: TextStyle(
                              color: step.isCompleted
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.black38,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderFlowStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;

  const _OrderFlowStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
  });
}