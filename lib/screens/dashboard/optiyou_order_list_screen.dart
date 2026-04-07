import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_optiyou_order_operations_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/screens/dashboard/optiyou_order_detail_screen.dart';

class OptiYouOrderListScreen extends StatefulWidget {
  final AppUser currentUser;

  const OptiYouOrderListScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<OptiYouOrderListScreen> createState() => _OptiYouOrderListScreenState();
}

class _OptiYouOrderListScreenState extends State<OptiYouOrderListScreen> {
  final MockOptiYouOrderOperationsRepository _repository =
      MockOptiYouOrderOperationsRepository();
  final TextEditingController _searchController = TextEditingController();

  List<OptiYouOrderOperationItem> _allItems = [];
  List<OptiYouOrderOperationItem> _filteredItems = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _selectedStatus = 'Tümü';
  String _selectedProductType = 'Tümü';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _repository.getOrderOperations();

      if (!mounted) return;

      setState(() {
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Operasyon siparişleri yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredItems = _allItems.where((item) {
        final matchesQuery =
            item.order.orderNo.toLowerCase().contains(query) ||
                item.expertName.toLowerCase().contains(query) ||
                item.clinicName.toLowerCase().contains(query) ||
                item.priorityLabel.toLowerCase().contains(query);

        final matchesStatus = _selectedStatus == 'Tümü' ||
            item.order.orderStatus == _selectedStatus;

        final matchesProductType = _selectedProductType == 'Tümü' ||
            item.order.productType == _selectedProductType;

        return matchesQuery && matchesStatus && matchesProductType;
      }).toList();
    });
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

  int _countByStatus(String status) {
    return _allItems.where((e) => e.order.orderStatus == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Operasyonları'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OptiYou operasyon paneli',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uzmanlardan gelen siparişleri takip edin, eksik verileri görün ve operasyon akışını yönetin.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Bekleyen',
                    value: _countByStatus(OrderStatuses.pending).toString(),
                    icon: Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Üretimde',
                    value: _countByStatus(OrderStatuses.production).toString(),
                    icon: Icons.precision_manufacturing,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Kargoda',
                    value: _countByStatus(OrderStatuses.shipped).toString(),
                    icon: Icons.local_shipping,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Teslim Edildi',
                    value: _countByStatus(OrderStatuses.delivered).toString(),
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Sipariş no, uzman, klinik veya öncelik ile ara',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                      DropdownMenuItem(
                        value: OrderStatuses.pending,
                        child: Text('Beklemede'),
                      ),
                      DropdownMenuItem(
                        value: OrderStatuses.production,
                        child: Text('Üretimde'),
                      ),
                      DropdownMenuItem(
                        value: OrderStatuses.shipped,
                        child: Text('Kargoda'),
                      ),
                      DropdownMenuItem(
                        value: OrderStatuses.delivered,
                        child: Text('Teslim Edildi'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value ?? 'Tümü';
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedProductType,
                    decoration: InputDecoration(
                      labelText: 'Ürün Tipi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Tümü', child: Text('Tümü')),
                      DropdownMenuItem(value: 'insole', child: Text('Tabanlık')),
                      DropdownMenuItem(
                        value: 'sports_insole',
                        child: Text('Spor Tabanlık'),
                      ),
                      DropdownMenuItem(value: 'sandal', child: Text('Sandalet')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProductType = value ?? 'Tümü';
                      });
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
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

    if (_filteredItems.isEmpty) {
      return const Center(
        child: Text('Operasyon listesinde gösterilecek sipariş bulunamadı.'),
      );
    }

    return ListView.separated(
      itemCount: _filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final order = item.order;
        final statusColor = _statusColor(order.orderStatus);
        final priorityColor = _priorityColor(item.priorityLabel);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          order.orderNo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(order.orderStatus),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Öncelik: ${item.priorityLabel}',
                            style: TextStyle(
                              color: priorityColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Text(
                      '${item.expertName} • ${item.clinicName}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Ürün: ${_productLabel(order.productType)} • '
                      'Sipariş: ${_formatDate(order.orderedAt)} • '
                      'Net Tutar: ${_formatMoney(order.netAmount, order.currencyCode)}',
                      style: TextStyle(color: Colors.grey[800]),
                    ),

                    const SizedBox(height: 10),

                    if (item.hasMissingData)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Eksik veri: ${item.missingDataSummary}',
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
                        padding: const EdgeInsets.all(12),
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
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Operasyon için gerekli temel veriler hazır.',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OptiYouOrderDetailScreen(
                        currentUser: widget.currentUser,
                        operationItem: item,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_ios),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            backgroundColor: Colors.teal.withOpacity(0.12),
            child: Icon(icon, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}