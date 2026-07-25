import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/optiyou_operation_column.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/screens/dashboard/optiyou_order_detail_screen.dart';
import 'package:oy_site/data/repositories/supabase_order_operation_repository.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OptiYouOperationsBoardScreen extends StatefulWidget {
  final AppUser currentUser;

  const OptiYouOperationsBoardScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<OptiYouOperationsBoardScreen> createState() =>
      _OptiYouOperationsBoardScreenState();
}

class _OptiYouOperationsBoardScreenState
    extends State<OptiYouOperationsBoardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  final SupabaseOrderRepository _orderRepository = SupabaseOrderRepository();

  final SupabaseOrderOperationRepository _operationRepository =
      SupabaseOrderOperationRepository();

  SupabaseClient get _client => Supabase.instance.client;

  List<OptiYouOrderOperationItem> _allItems = [];
  List<OptiYouOrderOperationItem> _filteredItems = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderRepository.getAllOrders();
      final relatedLabels = await _loadRelatedLabels(orders);

      final List<OptiYouOrderOperationItem> items = [];

      for (final order in orders) {
        final state = await _operationRepository.getStateByOrderId(
          orderId: order.orderId ?? 0,
        );

        final item = OptiYouOrderOperationItem(
          order: order,
          patientName: relatedLabels.patientNames[order.patientId] ??
              'Hasta #${order.patientId}',
          expertName: relatedLabels.expertNames[order.expertUserId] ??
              'Uzman #${order.expertUserId}',
          clinicName: relatedLabels.clinicNames[order.clinicId] ??
              'Klinik #${order.clinicId}',
          priorityLabel: 'Orta',
          currentColumnCode:
              state?.boardColumnCode ??
              OptiYouOperationColumnCodes.designWaiting,
          hasMissingData: false,
          missingDataSummary: '',
        );

        items.add(item);
      }

      if (!mounted) return;

      setState(() {
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Operasyon board verileri yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<_OrderRelatedLabels> _loadRelatedLabels(
    List<OrderModel> orders,
  ) async {
    final patientIds = orders.map((order) => order.patientId).toSet().toList();

    final clinicIds = orders.map((order) => order.clinicId).toSet().toList();

    final expertUserIds =
        orders.map((order) => order.expertUserId).toSet().toList();

    final patientNames = <int, String>{};
    final clinicNames = <int, String>{};
    final expertNames = <int, String>{};

    if (patientIds.isNotEmpty) {
      try {
        final response = await _client
            .from('patients')
            .select('id, first_name, last_name, patient_code')
            .inFilter('id', patientIds);

        final rows = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        for (final row in rows) {
          final id = _asInt(row['id']);
          if (id == null) continue;

          final firstName = (row['first_name'] ?? '').toString().trim();
          final lastName = (row['last_name'] ?? '').toString().trim();
          final patientCode = (row['patient_code'] ?? '').toString().trim();

          final fullName = '$firstName $lastName'.trim();

          patientNames[id] = fullName.isNotEmpty
              ? fullName
              : patientCode.isNotEmpty
                  ? patientCode
                  : 'Hasta #$id';
        }
      } catch (_) {
        // Hasta bilgisi okunamazsa fallback kullanılacak.
      }
    }

    if (clinicIds.isNotEmpty) {
      try {
        final response = await _client
            .from('clinics')
            .select('clinic_id, clinic_name, clinic_code')
            .inFilter('clinic_id', clinicIds);

        final rows = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        for (final row in rows) {
          final id = _asInt(row['clinic_id']);
          if (id == null) continue;

          final clinicName = (row['clinic_name'] ?? '').toString().trim();
          final clinicCode = (row['clinic_code'] ?? '').toString().trim();

          clinicNames[id] = clinicName.isNotEmpty
              ? clinicName
              : clinicCode.isNotEmpty
                  ? clinicCode
                  : 'Klinik #$id';
        }
      } catch (_) {
        // Klinik bilgisi okunamazsa fallback kullanılacak.
      }
    }

    if (expertUserIds.isNotEmpty) {
      try {
        final response = await _client
            .from('user_profiles_full')
            .select(
              'user_id, first_name, last_name, username, email, role_code, role_name',
            )
            .inFilter('user_id', expertUserIds);

        final rows = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        for (final row in rows) {
          final id = _asInt(row['user_id']);
          if (id == null) continue;

          final firstName = (row['first_name'] ?? '').toString().trim();
          final lastName = (row['last_name'] ?? '').toString().trim();
          final username = (row['username'] ?? '').toString().trim();

          final fullName = '$firstName $lastName'.trim();

          expertNames[id] = fullName.isNotEmpty
              ? fullName
              : username.isNotEmpty && !username.contains('@')
                  ? username
                  : 'Uzman #$id';
        }
      } catch (_) {
        // Uzman bilgisi okunamazsa fallback kullanılacak.
      }
    }

    return _OrderRelatedLabels(
      patientNames: patientNames,
      clinicNames: clinicNames,
      expertNames: expertNames,
    );
  }

  void _applySearch(String query) {
    final q = query.trim().toLowerCase();

    setState(() {
      if (q.isEmpty) {
        _filteredItems = _allItems;
        return;
      }

      _filteredItems = _allItems.where((item) {
        return item.order.orderNo.toLowerCase().contains(q) ||
            item.patientName.toLowerCase().contains(q) ||
            item.expertName.toLowerCase().contains(q) ||
            item.clinicName.toLowerCase().contains(q) ||
            item.priorityLabel.toLowerCase().contains(q) ||
            item.order.productType.toLowerCase().contains(q) ||
            item.order.orderStatus.toLowerCase().contains(q);
      }).toList();
    });
  }

  List<OptiYouOrderOperationItem> _itemsForColumn(String columnCode) {
    return _filteredItems
        .where((item) => item.currentColumnCode == columnCode)
        .toList();
  }

  Future<void> _moveItemToColumn(
    OptiYouOrderOperationItem item,
    String newColumnCode,
  ) async {
    final orderId = item.order.orderId;

    if (orderId == null) return;

    try {
      await _operationRepository.updateBoardColumn(
        orderId: orderId,
        boardColumnCode: newColumnCode,
        sessionId: item.order.sessionId,
        patientId: item.order.patientId,
        assignedUserId: widget.currentUser.userId,
      );

      if (!mounted) return;

      setState(() {
        final index = _allItems.indexWhere(
          (e) => e.order.orderId == item.order.orderId,
        );

        if (index == -1) return;

        _allItems[index] = _allItems[index].copyWith(
          currentColumnCode: newColumnCode,
        );

        final query = _searchController.text.trim();
        _applySearch(query);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kolon güncellenemedi: $e'),
        ),
      );
    }
  }

  int _columnIndexOfItem(OptiYouOrderOperationItem item) {
    return OptiYouOperationColumnCodes.all.indexWhere(
      (column) => column.code == item.currentColumnCode,
    );
  }

  bool _canMoveLeft(OptiYouOrderOperationItem item) {
    return _columnIndexOfItem(item) > 0;
  }

  bool _canMoveRight(OptiYouOrderOperationItem item) {
    final index = _columnIndexOfItem(item);
    return index >= 0 && index < OptiYouOperationColumnCodes.all.length - 1;
  }

  void _moveLeft(OptiYouOrderOperationItem item) {
    final currentIndex = _columnIndexOfItem(item);
    if (currentIndex <= 0) return;

    final previousColumn = OptiYouOperationColumnCodes.all[currentIndex - 1];
    _moveItemToColumn(item, previousColumn.code);
  }

  void _moveRight(OptiYouOrderOperationItem item) {
    final currentIndex = _columnIndexOfItem(item);
    if (currentIndex < 0 ||
        currentIndex >= OptiYouOperationColumnCodes.all.length - 1) {
      return;
    }

    final nextColumn = OptiYouOperationColumnCodes.all[currentIndex + 1];
    _moveItemToColumn(item, nextColumn.code);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
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

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final columns = OptiYouOperationColumnCodes.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operasyon Board'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _applySearch,
                    decoration: InputDecoration(
                      hintText:
                          'Sipariş no, hasta, uzman, klinik veya ürün ile ara',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _loadItems,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildBoard(columns),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard(List<OptiYouOperationColumn> columns) {
    if (_isLoading) {
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

    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((column) {
              final items = _itemsForColumn(column.code);

              return Container(
                width: 320,
                margin: const EdgeInsets.only(right: 16),
                child: _buildColumn(column, items),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildColumn(
    OptiYouOperationColumn column,
    List<OptiYouOrderOperationItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  column.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} sipariş',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 650,
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Kart yok',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OptiYouOrderOperationItem item) {
    final order = item.order;
    final statusColor = _statusColor(order.orderStatus);
    final priorityColor = _priorityColor(item.priorityLabel);

    return InkWell(
      onTap: () {
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
      borderRadius: BorderRadius.circular(14),
      child: _buildOrderCardContent(
        item: item,
        statusColor: statusColor,
        priorityColor: priorityColor,
      ),
    );
  }

  Widget _buildOrderCardContent({
    required OptiYouOrderOperationItem item,
    required Color statusColor,
    required Color priorityColor,
  }) {
    final order = item.order;
    final canMoveLeft = _canMoveLeft(item);
    final canMoveRight = _canMoveRight(item);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: item.hasMissingData
            ? Border.all(color: Colors.red.withOpacity(0.35))
            : null,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.orderNo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _buildTinyChip(
                _productLabel(order.productType),
                Colors.teal,
              ),
              _buildTinyChip(
                _statusLabel(order.orderStatus),
                statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoText(
            label: 'Hasta',
            value: item.patientName,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 4),
          _buildInfoText(
            label: 'Uzman',
            value: item.expertName,
          ),
          const SizedBox(height: 4),
          _buildInfoText(
            label: 'Klinik',
            value: item.clinicName,
          ),
          const SizedBox(height: 4),
          Text(
            'Tarih: ${_formatDate(order.orderedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10.5,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStepArrowButton(
                  icon: Icons.chevron_left,
                  enabled: canMoveLeft,
                  onTap: canMoveLeft ? () => _moveLeft(item) : null,
                ),
                const SizedBox(width: 4),
                _buildStepArrowButton(
                  icon: Icons.chevron_right,
                  enabled: canMoveRight,
                  onTap: canMoveRight ? () => _moveRight(item) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoText({
    required String label,
    required String value,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Text(
      '$label: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.grey[800],
        fontSize: 11,
        fontWeight: fontWeight,
      ),
    );
  }

  Widget _buildTinyChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStepArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: enabled ? Colors.grey.shade200 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.black87 : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

class _OrderRelatedLabels {
  final Map<int, String> patientNames;
  final Map<int, String> clinicNames;
  final Map<int, String> expertNames;

  const _OrderRelatedLabels({
    required this.patientNames,
    required this.clinicNames,
    required this.expertNames,
  });
}