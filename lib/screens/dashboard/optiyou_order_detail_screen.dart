import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_order_production_steps_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/models/order_production_step.dart';

class OptiYouOrderDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final OptiYouOrderOperationItem operationItem;

  const OptiYouOrderDetailScreen({
    super.key,
    required this.currentUser,
    required this.operationItem,
  });

  @override
  State<OptiYouOrderDetailScreen> createState() =>
      _OptiYouOrderDetailScreenState();
}

class _OptiYouOrderDetailScreenState extends State<OptiYouOrderDetailScreen> {
  final MockOrderProductionStepsRepository _stepsRepository =
      MockOrderProductionStepsRepository();

  List<OrderProductionStep> _steps = [];
  bool _isLoadingSteps = true;
  String? _errorMessage;

  OrderModel get order => widget.operationItem.order;

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    setState(() {
      _isLoadingSteps = true;
      _errorMessage = null;
    });

    try {
      final steps = await _stepsRepository.getStepsByOrderId(order.orderId ?? 0);

      if (!mounted) return;

      setState(() {
        _steps = steps..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _isLoadingSteps = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Üretim adımları yüklenirken hata oluştu: $e';
        _isLoadingSteps = false;
      });
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

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'yüksek':
        return Colors.red;
      case 'orta':
        return Colors.orange;
      case 'düşük':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep({
    required OrderProductionStep step,
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
                  border: Border.all(
                    color: color.withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  step.isCompleted ? Icons.check : Icons.pending_actions,
                  color: color,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 120,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.stepName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
                  const SizedBox(height: 6),
                  Text(
                    step.stepDescription,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  _buildKeyValueRow(
                    'Tamamlanma Tarihi',
                    _formatDate(step.completedAt),
                  ),
                  _buildKeyValueRow(
                    'Tamamlayan',
                    step.completedByUserName ?? '—',
                  ),
                  if ((step.note ?? '').trim().isNotEmpty)
                    _buildKeyValueRow(
                      'Not',
                      step.note!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowContent() {
    if (_isLoadingSteps) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_steps.isEmpty) {
      return const Center(
        child: Text('Bu sipariş için üretim adımı bulunamadı.'),
      );
    }

    final completedCount = _steps.where((e) => e.isCompleted).length;
    final progress = _steps.isEmpty ? 0.0 : completedCount / _steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tamamlanma Oranı: ${(progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
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
        ...List.generate(_steps.length, (index) {
          final step = _steps[index];
          final isLast = index == _steps.length - 1;
          return _buildFlowStep(
            step: step,
            isLast: isLast,
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.orderStatus);
    final priorityColor = _priorityColor(widget.operationItem.priorityLabel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operasyon Sipariş Detayı'),
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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: statusColor.withOpacity(0.12),
                        child: Icon(
                          Icons.inventory_2_outlined,
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
                              order.orderNo,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_productLabel(order.productType)} • ${widget.operationItem.expertName}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Operasyon kullanıcısı: ${widget.currentUser.displayName}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusLabel(order.orderStatus),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Öncelik: ${widget.operationItem.priorityLabel}',
                              style: TextStyle(
                                color: priorityColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildSectionCard(
                            title: 'Sipariş Referans Bilgileri',
                            child: Column(
                              children: [
                                _buildKeyValueRow(
                                  'Order ID',
                                  order.orderId?.toString() ?? '—',
                                ),
                                _buildKeyValueRow(
                                  'Session ID',
                                  order.sessionId.toString(),
                                ),
                                _buildKeyValueRow(
                                  'Patient ID',
                                  order.patientId.toString(),
                                ),
                                _buildKeyValueRow(
                                  'Clinic',
                                  widget.operationItem.clinicName,
                                ),
                                _buildKeyValueRow(
                                  'Expert',
                                  widget.operationItem.expertName,
                                ),
                                _buildKeyValueRow(
                                  'Assigned OptiYou User ID',
                                  order.assignedOptityouUserId?.toString() ?? '—',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            title: 'Tarih ve Fiyat Bilgileri',
                            child: Column(
                              children: [
                                _buildKeyValueRow(
                                  'Sipariş Tarihi',
                                  _formatDate(order.orderedAt),
                                ),
                                _buildKeyValueRow(
                                  'Kargo Tarihi',
                                  _formatDate(order.shippedAt),
                                ),
                                _buildKeyValueRow(
                                  'Teslim Tarihi',
                                  _formatDate(order.deliveredAt),
                                ),
                                const SizedBox(height: 8),
                                _buildKeyValueRow(
                                  'Brüt Tutar',
                                  _formatMoney(order.grossAmount, order.currencyCode),
                                ),
                                _buildKeyValueRow(
                                  'İndirim',
                                  _formatMoney(order.discountAmount, order.currencyCode),
                                ),
                                _buildKeyValueRow(
                                  'Net Tutar',
                                  _formatMoney(order.netAmount, order.currencyCode),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildSectionCard(
                            title: 'Üretim / Operasyon Akışı',
                            child: _buildFlowContent(),
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            title: 'Operasyon Notları / ERP Özeti',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.operationItem.hasMissingData)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Eksik veri uyarısı: ${widget.operationItem.missingDataSummary}',
                                            style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.25),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Temel üretim verileri eksiksiz görünüyor.',
                                            style: TextStyle(
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bu alan ileride iç ekip notları, hedef teslim tarihi, kalite kontrol bilgileri '
                                  've operasyonel ERP verileri için genişletilecek.',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}