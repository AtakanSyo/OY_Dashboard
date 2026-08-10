import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_order_operation_repository.dart';
import 'package:oy_site/data/repositories/supabase_order_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/optiyou_operation_column.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/screens/dashboard/operations/optiyou_order_detail_screen.dart';
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
  List<OptiYouOrderOperationItem> _archivedItems = [];

  bool _isLoading = true;
  bool _isArchiving = false;
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final orders = await _orderRepository.getAllOrders();

      final results = await Future.wait<dynamic>([
        _loadRelatedLabels(orders),
        _operationRepository.getArchivedOrderIds(),
      ]);

      final relatedLabels = results[0] as _OrderRelatedLabels;
      final archivedOrderIds = results[1] as Set<int>;

      final activeItems = <OptiYouOrderOperationItem>[];
      final archivedItems = <OptiYouOrderOperationItem>[];

      for (final order in orders) {
        final orderId = order.orderId;

        if (orderId == null) {
          continue;
        }

        final state = await _operationRepository.getStateByOrderId(
          orderId: orderId,
        );

        final patientName = relatedLabels.patientNames[order.patientId] ??
            'Kullanıcı #${order.patientId}';

        final expertName = relatedLabels.expertNames[order.expertUserId] ??
            'Uzman #${order.expertUserId}';

        final clinicName = order.clinicId > 0
            ? relatedLabels.clinicNames[order.clinicId] ?? '-'
            : '-';

        final item = OptiYouOrderOperationItem(
          order: order,
          patientName: patientName,
          expertName: expertName,
          clinicName: clinicName,
          priorityLabel: 'Orta',
          currentColumnCode: state?.boardColumnCode ??
              OptiYouOperationColumnCodes.designWaiting,
          hasMissingData: false,
          missingDataSummary: '',
        );

        if (archivedOrderIds.contains(orderId)) {
          archivedItems.add(item);
        } else {
          activeItems.add(item);
        }
      }

      archivedItems.sort((a, b) {
        final aDate =
            a.order.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final bDate =
            b.order.orderedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        _allItems = activeItems;
        _archivedItems = archivedItems;
        _filteredItems = _filterActiveItems(
          activeItems,
          _searchController.text,
        );
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
    final patientIds = orders
        .map((order) => order.patientId)
        .where((id) => id > 0)
        .toSet()
        .toList();

    final clinicIds = orders
        .map((order) => order.clinicId)
        .where((id) => id > 0)
        .toSet()
        .toList();

    final expertUserIds = orders
        .map((order) => order.expertUserId)
        .where((id) => id > 0)
        .toSet()
        .toList();

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
            .map(
              (item) => Map<String, dynamic>.from(item as Map),
            )
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
                  : 'Kullanıcı #$id';
        }
      } catch (e) {
        debugPrint('Kullanıcı bilgileri okunamadı: $e');
      }
    }

    if (clinicIds.isNotEmpty) {
      try {
        final response = await _client
            .from('clinics')
            .select('id, clinic_name, clinic_code')
            .inFilter('id', clinicIds);

        final rows = (response as List<dynamic>)
            .map(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();

        for (final row in rows) {
          final id = _asInt(row['id']);
          if (id == null) continue;

          final clinicName =
              (row['clinic_name'] ?? '').toString().trim();

          final clinicCode =
              (row['clinic_code'] ?? '').toString().trim();

          if (clinicName.isNotEmpty && clinicCode.isNotEmpty) {
            clinicNames[id] = '$clinicName ($clinicCode)';
          } else if (clinicName.isNotEmpty) {
            clinicNames[id] = clinicName;
          } else if (clinicCode.isNotEmpty) {
            clinicNames[id] = clinicCode;
          } else {
            clinicNames[id] = '-';
          }
        }
      } catch (e) {
        debugPrint('Klinik bilgileri okunamadı: $e');
      }
    }

    if (expertUserIds.isNotEmpty) {
      try {
        final response = await _client
            .from('user_profiles_full')
            .select(
              'user_id, first_name, last_name, username, email, '
              'role_code, role_name',
            )
            .inFilter('user_id', expertUserIds);

        final rows = (response as List<dynamic>)
            .map(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();

        for (final row in rows) {
          final id = _asInt(row['user_id']);
          if (id == null) continue;

          final firstName = (row['first_name'] ?? '').toString().trim();
          final lastName = (row['last_name'] ?? '').toString().trim();
          final username = (row['username'] ?? '').toString().trim();
          final email = (row['email'] ?? '').toString().trim();

          final fullName = '$firstName $lastName'.trim();

          expertNames[id] = fullName.isNotEmpty
              ? fullName
              : username.isNotEmpty && !username.contains('@')
                  ? username
                  : email.isNotEmpty
                      ? email
                      : 'Uzman #$id';
        }
      } catch (e) {
        debugPrint('Uzman bilgileri okunamadı: $e');
      }
    }

    return _OrderRelatedLabels(
      patientNames: patientNames,
      clinicNames: clinicNames,
      expertNames: expertNames,
    );
  }

  List<OptiYouOrderOperationItem> _filterActiveItems(
    List<OptiYouOrderOperationItem> source,
    String query,
  ) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return List<OptiYouOrderOperationItem>.from(source);
    }

    return source.where((item) {
      return _matchesQuery(item, q);
    }).toList();
  }

  List<OptiYouOrderOperationItem> _filterArchivedItems(
    String query,
  ) {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      return List<OptiYouOrderOperationItem>.from(_archivedItems);
    }

    return _archivedItems.where((item) {
      return _matchesQuery(item, q);
    }).toList();
  }

  bool _matchesQuery(
    OptiYouOrderOperationItem item,
    String normalizedQuery,
  ) {
    return item.order.orderNo.toLowerCase().contains(normalizedQuery) ||
        item.patientName.toLowerCase().contains(normalizedQuery) ||
        item.expertName.toLowerCase().contains(normalizedQuery) ||
        item.clinicName.toLowerCase().contains(normalizedQuery) ||
        item.priorityLabel.toLowerCase().contains(normalizedQuery) ||
        item.order.productType.toLowerCase().contains(normalizedQuery) ||
        item.order.orderStatus.toLowerCase().contains(normalizedQuery);
  }

  void _applySearch(String query) {
    setState(() {
      _filteredItems = _filterActiveItems(_allItems, query);
    });
  }

  List<OptiYouOrderOperationItem> _itemsForColumn(
    String columnCode,
  ) {
    return _filteredItems
        .where(
          (item) => item.currentColumnCode == columnCode,
        )
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

      final index = _allItems.indexWhere(
        (element) => element.order.orderId == orderId,
      );

      if (index == -1) return;

      final updatedItem = _allItems[index].copyWith(
        currentColumnCode: newColumnCode,
      );

      setState(() {
        _allItems[index] = updatedItem;
        _filteredItems = _filterActiveItems(
          _allItems,
          _searchController.text,
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kolon güncellenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _columnIndexOfItem(
    OptiYouOrderOperationItem item,
  ) {
    return OptiYouOperationColumnCodes.all.indexWhere(
      (column) => column.code == item.currentColumnCode,
    );
  }

  bool _canMoveLeft(
    OptiYouOrderOperationItem item,
  ) {
    return _columnIndexOfItem(item) > 0;
  }

  bool _canMoveRight(
    OptiYouOrderOperationItem item,
  ) {
    final index = _columnIndexOfItem(item);

    return index >= 0 &&
        index < OptiYouOperationColumnCodes.all.length - 1;
  }

  bool _isCompletedItem(
    OptiYouOrderOperationItem item,
  ) {
    return item.currentColumnCode ==
        OptiYouOperationColumnCodes.completed;
  }

  void _moveLeft(
    OptiYouOrderOperationItem item,
  ) {
    final currentIndex = _columnIndexOfItem(item);

    if (currentIndex <= 0) return;

    final previousColumn =
        OptiYouOperationColumnCodes.all[currentIndex - 1];

    _moveItemToColumn(
      item,
      previousColumn.code,
    );
  }

  void _moveRight(
    OptiYouOrderOperationItem item,
  ) {
    final currentIndex = _columnIndexOfItem(item);

    if (currentIndex < 0 ||
        currentIndex >=
            OptiYouOperationColumnCodes.all.length - 1) {
      return;
    }

    final nextColumn =
        OptiYouOperationColumnCodes.all[currentIndex + 1];

    _moveItemToColumn(
      item,
      nextColumn.code,
    );
  }

  Future<void> _confirmArchiveItem(
    OptiYouOrderOperationItem item,
  ) async {
    if (_isArchiving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Siparişi Arşivle'),
          content: Text(
            '${item.order.orderNo} numaralı sipariş arşive taşınacak.\n\n'
            'Sipariş operasyon boardundan kaldırılacak ancak arşiv '
            'içerisinde saklanmaya devam edecektir.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Arşivle'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _archiveItem(item);
  }

  Future<void> _archiveItem(
    OptiYouOrderOperationItem item,
  ) async {
    final orderId = item.order.orderId;

    if (orderId == null) {
      _showMessage(
        'Sipariş ID bulunamadı.',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isArchiving = true;
    });

    try {
      await _operationRepository.archiveOrder(
        orderId: orderId,
        sessionId: item.order.sessionId,
        patientId: item.order.patientId,
        archivedByUserId: widget.currentUser.userId,
      );

      if (!mounted) return;

      setState(() {
        _allItems.removeWhere(
          (element) => element.order.orderId == orderId,
        );

        _filteredItems = _filterActiveItems(
          _allItems,
          _searchController.text,
        );

        _archivedItems = [
          item.copyWith(
            currentColumnCode: OptiYouOperationColumnCodes.completed,
          ),
          ..._archivedItems.where(
            (element) => element.order.orderId != orderId,
          ),
        ];

        _isArchiving = false;
      });

      _showMessage(
        '${item.order.orderNo} arşive taşındı.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isArchiving = false;
      });

      _showMessage(
        'Sipariş arşivlenemedi: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _restoreArchivedItem(
    OptiYouOrderOperationItem item,
  ) async {
    final orderId = item.order.orderId;

    if (orderId == null) {
      _showMessage(
        'Sipariş ID bulunamadı.',
        backgroundColor: Colors.red,
      );
      return;
    }

    try {
      await _operationRepository.restoreArchivedOrder(
        orderId: orderId,
      );

      if (!mounted) return;

      final restoredItem = item.copyWith(
        currentColumnCode: OptiYouOperationColumnCodes.completed,
      );

      setState(() {
        _archivedItems.removeWhere(
          (element) => element.order.orderId == orderId,
        );

        _allItems = [
          ..._allItems.where(
            (element) => element.order.orderId != orderId,
          ),
          restoredItem,
        ];

        _filteredItems = _filterActiveItems(
          _allItems,
          _searchController.text,
        );
      });

      _showMessage(
        '${item.order.orderNo} Tamamlandı kolonuna geri taşındı.',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Sipariş arşivden çıkarılamadı: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _openArchiveDialog() async {
    final archiveSearchController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            final visibleArchivedItems = _filterArchivedItems(
              archiveSearchController.text,
            );

            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 980,
                  maxHeight: 760,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sipariş Arşivi',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tamamlanan ve aktif operasyon akışından '
                                  'kaldırılan siparişler',
                                  style: TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Kapat',
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: archiveSearchController,
                        onChanged: (_) {
                          dialogSetState(() {});
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Sipariş no, kullanıcı, klinik, uzman veya ürün ara',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              archiveSearchController.text.trim().isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Aramayı temizle',
                                      onPressed: () {
                                        archiveSearchController.clear();
                                        dialogSetState(() {});
                                      },
                                      icon: const Icon(Icons.clear),
                                    ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            '${visibleArchivedItems.length} arşivlenmiş sipariş',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              await _loadItems();

                              if (!dialogContext.mounted) return;

                              dialogSetState(() {});
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Yenile'),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Expanded(
                        child: visibleArchivedItems.isEmpty
                            ? _buildArchiveEmptyState(
                                archiveSearchController.text.trim().isEmpty
                                    ? 'Arşivlenmiş sipariş bulunmuyor.'
                                    : 'Arama kriterine uygun arşivlenmiş '
                                        'sipariş bulunamadı.',
                              )
                            : ListView.separated(
                                itemCount: visibleArchivedItems.length,
                                separatorBuilder: (_, __) {
                                  return const SizedBox(height: 10);
                                },
                                itemBuilder: (context, index) {
                                  final item =
                                      visibleArchivedItems[index];

                                  return _buildArchivedOrderRow(
                                    item: item,
                                    onOpen: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              OptiYouOrderDetailScreen(
                                            currentUser:
                                                widget.currentUser,
                                            operationItem: item,
                                          ),
                                        ),
                                      );

                                      if (!mounted) return;

                                      await _loadItems();

                                      if (!dialogContext.mounted) return;

                                      dialogSetState(() {});
                                    },
                                    onRestore: () async {
                                      final shouldRestore =
                                          await _confirmRestoreArchivedItem(
                                        item,
                                      );

                                      if (!shouldRestore) return;

                                      await _restoreArchivedItem(item);

                                      if (!dialogContext.mounted) return;

                                      dialogSetState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    archiveSearchController.dispose();
  }

  Future<bool> _confirmRestoreArchivedItem(
    OptiYouOrderOperationItem item,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Arşivden Çıkar'),
          content: Text(
            '${item.order.orderNo} numaralı sipariş Tamamlandı '
            'kolonuna geri taşınacak.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.unarchive_outlined),
              label: const Text('Geri Al'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Widget _buildArchivedOrderRow({
    required OptiYouOrderOperationItem item,
    required VoidCallback onOpen,
    required VoidCallback onRestore,
  }) {
    final order = item.order;
    final statusColor = _statusColor(order.orderStatus);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.archive_outlined,
              color: Colors.blueGrey.shade700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNo,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.patientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.clinicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _productLabel(order.productType),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Uzman: ${item.expertName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tarih: ${_formatDate(order.orderedAt)}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildTinyChip(
            _statusLabel(order.orderStatus),
            statusColor,
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Sipariş detayını aç',
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new),
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: onRestore,
            icon: const Icon(
              Icons.unarchive_outlined,
              size: 18,
            ),
            label: const Text('Geri Al'),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveEmptyState(
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 68,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) return '—';

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _productLabel(
    String productType,
  ) {
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

  String _statusLabel(
    String status,
  ) {
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

  Color _statusColor(
    String status,
  ) {
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

  Color _priorityColor(
    String priority,
  ) {
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

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  static int? _asInt(
    dynamic value,
  ) {
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
                          'Sipariş no, kullanıcı, uzman, klinik veya ürün ile ara',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchController.text.trim().isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Aramayı temizle',
                                  onPressed: () {
                                    _searchController.clear();
                                    _applySearch('');
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loadItems,
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

  Widget _buildBoard(
    List<OptiYouOperationColumn> columns,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _loadItems,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
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
            children: [
              ...columns.map((column) {
                final items = _itemsForColumn(column.code);

                return Container(
                  width: 320,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildColumn(
                    column,
                    items,
                  ),
                );
              }),
              _buildArchivePanel(),
            ],
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
        border: Border.all(
          color: Colors.grey.shade300,
        ),
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
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                ),
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
                    color: Colors.grey.shade700,
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
                      'Sipariş yok',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(
                        items[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivePanel() {
    final count = _archivedItems.length;

    return Container(
      width: 220,
      height: 714,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blueGrey.withOpacity(0.28),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openArchiveDialog,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    count.toString(),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 82,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Arşiv',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '$count sipariş',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tamamlanan siparişleri arşivde görüntülemek için tıklayın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _openArchiveDialog,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: const Text('Arşivi Gör'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(
    OptiYouOrderOperationItem item,
  ) {
    final order = item.order;
    final statusColor = _statusColor(order.orderStatus);
    final priorityColor = _priorityColor(item.priorityLabel);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OptiYouOrderDetailScreen(
              currentUser: widget.currentUser,
              operationItem: item,
            ),
          ),
        );

        if (mounted) {
          await _loadItems();
        }
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
    final isCompleted = _isCompletedItem(item);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.25)
              : Colors.grey.shade200,
        ),
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
            label: 'Kullanıcı',
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
              color: Colors.grey.shade600,
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
                  enabled: canMoveLeft && !_isArchiving,
                  onTap: canMoveLeft
                      ? () {
                          _moveLeft(item);
                        }
                      : null,
                ),
                const SizedBox(width: 2),
                _buildStepArrowButton(
                  icon: isCompleted
                      ? Icons.archive_outlined
                      : Icons.chevron_right,
                  enabled:
                      (isCompleted || canMoveRight) && !_isArchiving,
                  tooltip: isCompleted
                      ? 'Siparişi arşivle'
                      : 'Sonraki adıma taşı',
                  onTap: isCompleted
                      ? () {
                          _confirmArchiveItem(item);
                        }
                      : canMoveRight
                          ? () {
                              _moveRight(item);
                            }
                          : null,
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
        color: Colors.grey.shade800,
        fontSize: 11,
        fontWeight: fontWeight,
      ),
    );
  }

  Widget _buildTinyChip(
    String label,
    Color color,
  ) {
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
    String? tooltip,
  }) {
    final button = Material(
      color: enabled
          ? Colors.grey.shade100
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 24,
          height: 24,
          child: Icon(
            icon,
            size: 15,
            color: enabled
                ? Colors.grey.shade800
                : Colors.grey.shade400,
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip.trim().isEmpty) {
      return button;
    }

    return Tooltip(
      message: tooltip,
      child: button,
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