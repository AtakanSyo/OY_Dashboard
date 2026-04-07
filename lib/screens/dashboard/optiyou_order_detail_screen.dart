import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_order_production_steps_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/optiyou_operation_column.dart';
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

  final Map<String, TextEditingController> _noteControllers = {};

  OrderModel get order => widget.operationItem.order;

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  @override
  void dispose() {
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSteps() async {
    setState(() {
      _isLoadingSteps = true;
      _errorMessage = null;
    });

    try {
      final steps = await _stepsRepository.getStepsByOrderId(order.orderId ?? 0);

      if (!mounted) return;

      steps.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      for (final step in steps) {
        _noteControllers[step.stepCode] =
            TextEditingController(text: step.note ?? '');
      }

      setState(() {
        _steps = steps;
        _isLoadingSteps = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Sipariş adımları yüklenirken hata oluştu: $e';
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

  IconData _iconForStep(String stepCode) {
    switch (stepCode) {
      case OptiYouOperationColumnCodes.infoMailSent:
      case OptiYouOperationColumnCodes.postInfoMailSent:
      case OptiYouOperationColumnCodes.satisfactionSurveySent:
        return Icons.mail_outline;
      case OptiYouOperationColumnCodes.kvkkShared:
        return Icons.verified_user_outlined;
      case OptiYouOperationColumnCodes.stlUploaded:
        return Icons.upload_file;
      case OptiYouOperationColumnCodes.technicalReview:
        return Icons.rule_folder_outlined;
      case OptiYouOperationColumnCodes.qualityControl:
        return Icons.fact_check_outlined;
      case OptiYouOperationColumnCodes.packaging:
        return Icons.inventory_2_outlined;
      case OptiYouOperationColumnCodes.shipped:
        return Icons.local_shipping_outlined;
      case OptiYouOperationColumnCodes.designCompleted:
      case OptiYouOperationColumnCodes.designWaiting:
        return Icons.design_services_outlined;
      case OptiYouOperationColumnCodes.productionStarted:
      case OptiYouOperationColumnCodes.productionCompleted:
        return Icons.precision_manufacturing_outlined;
      case OptiYouOperationColumnCodes.closed:
        return Icons.check_circle_outline;
      default:
        return Icons.radio_button_checked;
    }
  }

  bool _isMailStep(String stepCode) {
    return stepCode == OptiYouOperationColumnCodes.infoMailSent ||
        stepCode == OptiYouOperationColumnCodes.postInfoMailSent ||
        stepCode == OptiYouOperationColumnCodes.satisfactionSurveySent;
  }

  bool _isFileStep(String stepCode) {
    return stepCode == OptiYouOperationColumnCodes.stlUploaded;
  }

  bool _needsCheckbox(String stepCode) {
    return !_isMailStep(stepCode) && !_isFileStep(stepCode);
  }

  bool _needsNoteField(String stepCode) {
    return stepCode == OptiYouOperationColumnCodes.kvkkShared ||
        stepCode == OptiYouOperationColumnCodes.technicalReview ||
        stepCode == OptiYouOperationColumnCodes.qualityControl ||
        stepCode == OptiYouOperationColumnCodes.packaging ||
        stepCode == OptiYouOperationColumnCodes.shipped;
  }

  String _stepDisplayName(String stepCode, String fallbackName) {
    switch (stepCode) {
      case OptiYouOperationColumnCodes.orderReceived:
        return 'Sipariş Alındı';
      case OptiYouOperationColumnCodes.infoMailSent:
        return 'Bilgi Maili Atıldı';
      case OptiYouOperationColumnCodes.kvkkShared:
        return 'KVKK Paylaşıldı';
      case OptiYouOperationColumnCodes.technicalReview:
        return 'Teknik Kontrol';
      case OptiYouOperationColumnCodes.designWaiting:
        return 'Tasarım Bekleniyor';
      case OptiYouOperationColumnCodes.designCompleted:
        return 'Tasarım Tamamlandı';
      case OptiYouOperationColumnCodes.stlUploaded:
        return 'STL Yüklendi';
      case OptiYouOperationColumnCodes.productionStarted:
        return 'Üretimde';
      case OptiYouOperationColumnCodes.productionCompleted:
        return 'Üretim Tamamlandı';
      case OptiYouOperationColumnCodes.qualityControl:
        return 'Kalite Kontrol';
      case OptiYouOperationColumnCodes.packaging:
        return 'Paketleme';
      case OptiYouOperationColumnCodes.shipped:
        return 'Kargoya Verildi';
      case OptiYouOperationColumnCodes.postInfoMailSent:
        return 'Sipariş Sonrası Mail';
      case OptiYouOperationColumnCodes.satisfactionSurveySent:
        return 'Memnuniyet Anketi';
      case OptiYouOperationColumnCodes.closed:
        return 'Kapandı';
      default:
        return fallbackName;
    }
  }

  void _toggleStepCompleted(OrderProductionStep step, bool? value) {
    final updatedValue = value ?? false;

    setState(() {
      final index = _steps.indexWhere((e) => e.stepId == step.stepId);
      if (index == -1) return;

      _steps[index] = _steps[index].copyWith(
        isCompleted: updatedValue,
        completedAt: updatedValue ? DateTime.now() : null,
        completedByUserName:
            updatedValue ? widget.currentUser.displayName : null,
      );
    });
  }

  void _showSimpleActionMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildStepActionArea(OrderProductionStep step) {
    final noteController = _noteControllers[step.stepCode];

    if (_isMailStep(step.stepCode)) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              _showSimpleActionMessage(
                '${_stepDisplayName(step.stepCode, step.stepName)} için trigger mail akışı daha sonra bağlanacak.',
              );
            },
            icon: const Icon(Icons.send_outlined),
            label: const Text('Trigger Mail'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              _showSimpleActionMessage(
                '${_stepDisplayName(step.stepCode, step.stepName)} için mail taslağı editörü daha sonra bağlanacak.',
              );
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Mail Taslağını Düzenle'),
          ),
        ],
      );
    }

    if (_isFileStep(step.stepCode)) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              _showSimpleActionMessage(
                'STL dosya yükleme akışı daha sonra bağlanacak.',
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Dosya Yükle'),
          ),
          if ((step.note ?? '').trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                step.note!,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_needsCheckbox(step.stepCode))
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: step.isCompleted,
            onChanged: (value) => _toggleStepCompleted(step, value),
            title: const Text('Tamamlandı olarak işaretle'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        if (_needsNoteField(step.stepCode) && noteController != null) ...[
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Not',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepRow(OrderProductionStep step) {
    final isCompleted = step.isCompleted;
    final stepTitle = _stepDisplayName(step.stepCode, step.stepName);
    final color = isCompleted ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.25)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(
                  _iconForStep(step.stepCode),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  stepTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.12)
                      : Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCompleted ? 'Tamamlandı' : 'Bekliyor',
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepActionArea(step),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Zaman: ${_formatDate(step.completedAt)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'İşleyen: ${step.completedByUserName ?? '—'}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepsContent() {
    if (_isLoadingSteps) {
      return const Center(child: CircularProgressIndicator());
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
        child: Text('Bu sipariş için adım bulunamadı.'),
      );
    }

    return Column(
      children: _steps.map(_buildStepRow).toList(),
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
            constraints: const BoxConstraints(maxWidth: 1150),
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
                                  _formatMoney(
                                    order.grossAmount,
                                    order.currencyCode,
                                  ),
                                ),
                                _buildKeyValueRow(
                                  'İndirim',
                                  _formatMoney(
                                    order.discountAmount,
                                    order.currencyCode,
                                  ),
                                ),
                                _buildKeyValueRow(
                                  'Net Tutar',
                                  _formatMoney(
                                    order.netAmount,
                                    order.currencyCode,
                                  ),
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
                      child: _buildSectionCard(
                        title: 'Operasyon Adımları',
                        child: _buildStepsContent(),
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