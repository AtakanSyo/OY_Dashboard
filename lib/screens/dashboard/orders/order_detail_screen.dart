import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
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
        shippedAt:
            newStatus == OrderStatuses.shipped && _order.shippedAt == null
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
        SnackBar(
          content: Text(AppLocalizations.of(context).orderStatusUpdated),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).orderStatusUpdateError(error.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date.toLocal());
  }

  String _formatMoney(
    BuildContext context,
    double amount,
    String currencyCode,
  ) {
    final value = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '',
      decimalDigits: 2,
    ).format(amount).trim();
    return '$value $currencyCode';
  }

  String _productLabel(String productType, AppLocalizations l10n) {
    switch (productType) {
      case 'insole':
        return l10n.insoleProduct;
      case 'sports_insole':
        return l10n.sportsInsoleProduct;
      case 'sandal':
        return l10n.sandalProduct;
      case 'heel_pad':
        return l10n.heelPadTitle;
      case 'met_pad':
        return l10n.metPadTitle;
      case 'cleaning_spray':
        return l10n.cleaningSprayTitle;
      case 'carry_case':
        return l10n.carryCaseTitle;
      default:
        return productType;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case OrderStatuses.pending:
        return l10n.pendingStatus;
      case OrderStatuses.designing:
        return l10n.designingStatus;
      case OrderStatuses.production:
        return l10n.productionStatus;
      case OrderStatuses.shipped:
        return l10n.shippedStatus;
      case OrderStatuses.delivered:
        return l10n.deliveredStatus;
      case OrderStatuses.cancelled:
        return l10n.cancelledStatus;
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
      default:
        return -1;
    }
  }

  List<_OrderFlowStep> _buildOrderSteps(AppLocalizations l10n) {
    final currentStep = _currentStepIndex();
    return [
      _OrderFlowStep(
        icon: Icons.receipt_long_outlined,
        title: l10n.orderReceived,
        subtitle: l10n.orderReceivedDescription,
        isCompleted: currentStep >= 0,
      ),
      _OrderFlowStep(
        icon: Icons.design_services_outlined,
        title: l10n.designPreparation,
        subtitle: l10n.designPreparationDescription,
        isCompleted: currentStep >= 1,
      ),
      _OrderFlowStep(
        icon: Icons.precision_manufacturing_outlined,
        title: l10n.production,
        subtitle: l10n.productionDescription,
        isCompleted: currentStep >= 2,
      ),
      _OrderFlowStep(
        icon: Icons.local_shipping_outlined,
        title: l10n.handedToCarrier,
        subtitle: l10n.shippedDescription,
        isCompleted: currentStep >= 3,
      ),
      _OrderFlowStep(
        icon: Icons.home_outlined,
        title: l10n.deliveredStatus,
        subtitle: l10n.deliveredDescription,
        isCompleted: currentStep >= 4,
      ),
    ];
  }

  bool get _canUpdateOrder =>
      !widget.currentUser.isCustomer && _order.orderId != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(_order.orderStatus);
    final steps = _buildOrderSteps(l10n);
    final completedCount = steps.where((step) => step.isCompleted).length;
    final progress = _order.isCancelled ? 0.0 : completedCount / steps.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.orderDetailTitle),
        backgroundColor: Colors.teal,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          final pagePadding = constraints.maxWidth < 650 ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(statusColor, l10n),
                    const SizedBox(height: 20),
                    if (isCompact) ...[
                      _buildPrimaryColumn(l10n),
                      const SizedBox(height: 16),
                      _buildSecondaryColumn(progress, steps, l10n),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildPrimaryColumn(l10n)),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _buildSecondaryColumn(progress, steps, l10n),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrimaryColumn(AppLocalizations l10n) {
    return Column(
      children: [
        _buildOrderInfoCard(l10n),
        const SizedBox(height: 16),
        _buildDeliveryAddressCard(l10n),
        if (_canUpdateOrder) ...[
          const SizedBox(height: 16),
          _buildStatusUpdateCard(l10n),
        ],
      ],
    );
  }

  Widget _buildSecondaryColumn(
    double progress,
    List<_OrderFlowStep> steps,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        _buildFlowCard(progress, steps, l10n),
        const SizedBox(height: 16),
        _buildPriceCard(l10n),
      ],
    );
  }

  Widget _buildHeader(Color statusColor, AppLocalizations l10n) {
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _order.orderNo,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${l10n.productLabel}: ${_productLabel(_order.productType, l10n)}',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        if (!widget.currentUser.isCustomer) ...[
          const SizedBox(height: 6),
          Text(
            '${l10n.actingUser}: ${widget.currentUser.displayName}',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chip = _buildStatusChip(
            _statusLabel(_order.orderStatus, l10n),
            statusColor,
          );
          final identity = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 30,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: summary),
            ],
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 16), chip],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 16),
              chip,
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildOrderInfoCard(AppLocalizations l10n) {
    return _buildSectionCard(
      title: l10n.orderInformation,
      child: Column(
        children: [
          _buildKeyValueRow(l10n.orderNumberLabel, _order.orderNo),
          if (!widget.currentUser.isCustomer) ...[
            _buildKeyValueRow(
              l10n.internalOrderId,
              _order.orderId?.toString() ?? '—',
            ),
            _buildKeyValueRow(
              l10n.internalSessionId,
              _order.sessionId.toString(),
            ),
            _buildKeyValueRow(
              l10n.internalPatientId,
              _order.patientId.toString(),
            ),
            _buildKeyValueRow(
              l10n.internalClinicId,
              _order.clinicId.toString(),
            ),
            _buildKeyValueRow(
              l10n.internalExpertId,
              _order.expertUserId.toString(),
            ),
            _buildKeyValueRow(
              l10n.internalAssignedUserId,
              _order.assignedOptityouUserId?.toString() ?? '—',
            ),
          ],
          _buildKeyValueRow(
            l10n.orderDateLabel,
            _formatDate(context, _order.orderedAt),
          ),
          _buildKeyValueRow(
            l10n.shipmentDateLabel,
            _formatDate(context, _order.shippedAt),
          ),
          _buildKeyValueRow(
            l10n.deliveryDateLabel,
            _formatDate(context, _order.deliveredAt),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressCard(AppLocalizations l10n) {
    final snapshot = _order.deliveryAddressSnapshot;
    if (snapshot == null || snapshot.isEmpty) {
      return _buildSectionCard(
        title: l10n.deliveryAddressTitle,
        child: Text(
          l10n.deliveryAddressMissing,
          style: TextStyle(color: Colors.grey.shade700),
        ),
      );
    }

    final title = snapshot['title']?.toString() ?? l10n.deliveryAddressTitle;
    final fullName = snapshot['full_name']?.toString() ?? '—';
    final phone = snapshot['phone']?.toString() ?? '—';
    final city = snapshot['city']?.toString() ?? '—';
    final district = snapshot['district']?.toString() ?? '—';
    final addressLine = snapshot['address_line']?.toString() ?? '—';

    return _buildSectionCard(
      title: l10n.deliveryAddressTitle,
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

  Widget _buildStatusUpdateCard(AppLocalizations l10n) {
    return _buildSectionCard(
      title: l10n.updateOrderStatus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _order.orderStatus,
            decoration: InputDecoration(
              labelText: l10n.orderStatusLabel,
              border: const OutlineInputBorder(),
            ),
            items: OrderStatuses.values.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(_statusLabel(status, l10n)),
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

  Widget _buildFlowCard(
    double progress,
    List<_OrderFlowStep> steps,
    AppLocalizations l10n,
  ) {
    return _buildSectionCard(
      title: l10n.orderFlowTitle,
      child: _order.isCancelled
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.orderCancelledDescription)),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.completionRate((progress * 100).round()),
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
                  return _buildFlowStep(
                    step: steps[index],
                    isLast: index == steps.length - 1,
                    l10n: l10n,
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildPriceCard(AppLocalizations l10n) {
    return _buildSectionCard(
      title: l10n.priceInformation,
      child: Column(
        children: [
          _buildKeyValueRow(
            l10n.grossAmount,
            _formatMoney(context, _order.grossAmount, _order.currencyCode),
          ),
          _buildKeyValueRow(
            l10n.discountAmount,
            _formatMoney(context, _order.discountAmount, _order.currencyCode),
          ),
          _buildKeyValueRow(
            l10n.netAmountLabel,
            _formatMoney(context, _order.netAmount, _order.currencyCode),
          ),
          _buildKeyValueRow(l10n.currency, _order.currencyCode),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
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
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
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
    required AppLocalizations l10n,
  }) {
    final color = step.isCompleted ? Colors.green : Colors.orange;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 46,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.4)),
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
                  height: 104,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: step.isCompleted
                        ? Colors.green.withValues(alpha: 0.45)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
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
                      ? Colors.green.withValues(alpha: 0.35)
                      : Colors.grey.shade300,
                ),
              ),
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
                  _buildStatusChip(
                    step.isCompleted ? l10n.stepCompleted : l10n.stepWaiting,
                    color,
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
