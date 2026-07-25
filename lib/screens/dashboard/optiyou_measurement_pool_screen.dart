import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/screens/dashboard/optiyou_measurement_review_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OptiyouMeasurementPoolScreen extends StatefulWidget {
  final AppUser currentUser;
  final dynamic pressureRepository;

  const OptiyouMeasurementPoolScreen({
    super.key,
    required this.currentUser,
    required this.pressureRepository,
  });

  @override
  State<OptiyouMeasurementPoolScreen> createState() =>
      _OptiyouMeasurementPoolScreenState();
}

class _OptiyouMeasurementPoolScreenState
    extends State<OptiyouMeasurementPoolScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _grossAmountController =
      TextEditingController(text: '0');
  final TextEditingController _discountAmountController =
      TextEditingController(text: '0');

  bool _isLoading = true;
  bool _isCreatingOrder = false;

  String _searchText = '';
  String _statusFilter = 'all';
  String _clinicFilter = 'all';
  String _selectionFilter = 'all';

  String _selectedProductType = 'insole';
  String _selectedCurrencyCode = 'TRY';

  List<_MeasurementPoolSession> _sessions = [];
  final Set<int> _selectedSessionIds = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  String _generateOrderNo({
    required int sessionId,
    required int index,
  }) {
    final now = DateTime.now();

    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return 'ORD-${now.year}$month$day-$hour$minute$second-$sessionId-${index + 1}';
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _client
          .from('measurement_sessions')
          .select('''
            id,
            clinic_id,
            patient_id,
            expert_user_id,
            assigned_optityou_user_id,
            session_code,
            session_date,
            session_time,
            status,
            has_3d_scan,
            has_plantar_csv,
            has_insole_photo,
            order_created,
            clinical_info_completed,
            design_form_completed,
            completed_at,
            created_at,
            updated_at
          ''')
          .eq('order_created', true)
          .order('completed_at', ascending: false);

      final rows = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final sessions = rows.map(_MeasurementPoolSession.fromMap).toList();

      final existingOrderSessionIds = await _fetchExistingOrderSessionIds(
        sessions.map((session) => session.id).whereType<int>().toList(),
      );

      final visibleSessions = sessions
          .where(
            (session) =>
                session.id == null ||
                !existingOrderSessionIds.contains(session.id),
          )
          .toList();

      final enrichedSessions =
          await _enrichSessionsWithRelatedInfo(visibleSessions);

      if (!mounted) return;

      setState(() {
        _sessions = enrichedSessions;
        _selectedSessionIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ölçüm havuzu yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Set<int>> _fetchExistingOrderSessionIds(List<int> sessionIds) async {
    if (sessionIds.isEmpty) return <int>{};

    try {
      final response = await _client
          .from('orders')
          .select('session_id')
          .inFilter('session_id', sessionIds);

      final rows = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      return rows
          .map((row) => _asInt(row['session_id']))
          .whereType<int>()
          .toSet();
    } catch (_) {
      return <int>{};
    }
  }

  Future<List<_MeasurementPoolSession>> _enrichSessionsWithRelatedInfo(
    List<_MeasurementPoolSession> sessions,
  ) async {
    final patientIds = sessions
        .map((session) => session.patientId)
        .whereType<int>()
        .toSet()
        .toList();

    final expertUserIds = sessions
        .map((session) => session.expertUserId)
        .whereType<int>()
        .toSet()
        .toList();

    final clinicIds = sessions
        .map((session) => session.clinicId)
        .whereType<int>()
        .where((id) => id > 0)
        .toSet()
        .toList();

    final patientNameById = <int, String>{};
    final expertNameById = <int, String>{};
    final clinicNameById = <int, String>{};
    final clinicCodeById = <int, String>{};

    if (patientIds.isNotEmpty) {
      try {
        final response = await _client
            .from('patients')
            .select('id, first_name, last_name, patient_code')
            .inFilter('id', patientIds);

        final patientRows = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        for (final row in patientRows) {
          final id = _asInt(row['id']);
          if (id == null) continue;

          final firstName = (row['first_name'] ?? '').toString().trim();
          final lastName = (row['last_name'] ?? '').toString().trim();
          final patientCode = (row['patient_code'] ?? '').toString().trim();

          final fullName = '$firstName $lastName'.trim();

          patientNameById[id] = fullName.isNotEmpty
              ? fullName
              : patientCode.isNotEmpty
                  ? patientCode
                  : 'Kullanıcı #$id';
        }
      } catch (_) {}
    }

    if (expertUserIds.isNotEmpty) {
      try {
        final response = await _client
            .from('user_profiles_full')
            .select(
              'user_id, first_name, last_name, username, email, role_code, role_name',
            )
            .inFilter('user_id', expertUserIds);

        final expertRows = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        for (final row in expertRows) {
          final id = _asInt(row['user_id']);
          if (id == null) continue;

          final firstName = (row['first_name'] ?? '').toString().trim();
          final lastName = (row['last_name'] ?? '').toString().trim();
          final username = (row['username'] ?? '').toString().trim();

          final fullName = '$firstName $lastName'.trim();

          expertNameById[id] = fullName.isNotEmpty
              ? fullName
              : username.isNotEmpty && !username.contains('@')
                  ? username
                  : 'Uzman #$id';
        }
      } catch (_) {}
    }

    if (clinicIds.isNotEmpty) {
      try {
        final response = await _client
            .from('clinics')
            .select('id, clinic_name, clinic_code')
            .inFilter('id', clinicIds);

        final clinicRows = (response as List<dynamic>)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        for (final row in clinicRows) {
          final id = _asInt(row['id']);
          if (id == null) continue;

          final clinicName = (row['clinic_name'] ?? '').toString().trim();
          final clinicCode = (row['clinic_code'] ?? '').toString().trim();

          clinicNameById[id] = clinicName.isNotEmpty
              ? clinicName
              : clinicCode.isNotEmpty
                  ? clinicCode
                  : 'Klinik #$id';

          if (clinicCode.isNotEmpty) {
            clinicCodeById[id] = clinicCode;
          }
        }
      } catch (_) {}
    }

    return sessions.map((session) {
      final patientId = session.patientId;
      final expertUserId = session.expertUserId;
      final clinicId = session.clinicId;

      return session.copyWith(
        patientName: patientId == null ? null : patientNameById[patientId],
        expertName: expertUserId == null ? null : expertNameById[expertUserId],
        clinicName: clinicId == null ? null : clinicNameById[clinicId],
        clinicCode: clinicId == null ? null : clinicCodeById[clinicId],
      );
    }).toList();
  }

  List<_MeasurementPoolSession> get _filteredSessions {
    final query = _searchText.trim().toLowerCase();

    return _sessions.where((session) {
      final matchesStatus = _statusFilter == 'all' ||
          session.effectiveStatus.toLowerCase() == _statusFilter.toLowerCase();

      if (!matchesStatus) return false;

      final matchesClinic = _clinicFilter == 'all' ||
          (_clinicFilter == 'unknown'
              ? session.clinicId == null || session.clinicId! <= 0
              : session.clinicId?.toString() == _clinicFilter);

      if (!matchesClinic) return false;

      final isSelected =
          session.id != null && _selectedSessionIds.contains(session.id);

      final matchesSelection = _selectionFilter == 'all' ||
          (_selectionFilter == 'selected' && isSelected) ||
          (_selectionFilter == 'unselected' && !isSelected);

      if (!matchesSelection) return false;

      if (query.isEmpty) return true;

      final searchable = [
        session.id?.toString() ?? '',
        session.sessionCode,
        session.patientId?.toString() ?? '',
        session.patientName ?? '',
        session.patientLabel,
        session.expertUserId?.toString() ?? '',
        session.expertLabel,
        session.clinicLabel,
        session.status,
        session.effectiveStatus,
        session.formattedDate,
        session.formattedCompletedDate,
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  void _toggleSessionSelection(int? sessionId) {
    if (sessionId == null) return;

    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
      } else {
        _selectedSessionIds.add(sessionId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSessionIds.clear();
    });
  }

  Future<void> _openSessionDetail(_MeasurementPoolSession session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OptiYouMeasurementReviewScreen(
          currentUser: widget.currentUser,
          session: session.toMeasurementSession(),
        ),
      ),
    );

    if (mounted) {
      await _loadSessions();
    }
  }

  Future<void> _createOrderFromSelectedSessions() async {
    if (_selectedSessionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş oluşturmak için en az bir ölçüm seçmelisin.'),
        ),
      );
      return;
    }

    final selectedSessions = _sessions
        .where(
          (session) =>
              session.id != null && _selectedSessionIds.contains(session.id),
        )
        .toList();

    if (selectedSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seçili ölçüm bulunamadı.'),
        ),
      );
      return;
    }

    await _showBulkOrderCreateDialog(selectedSessions);
  }

  Future<void> _showBulkOrderCreateDialog(
    List<_MeasurementPoolSession> selectedSessions,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !_isCreatingOrder,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sipariş Oluştur'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedSessions.length} ölçüm için sipariş oluşturulacak.',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
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
                        onChanged: _isCreatingOrder
                            ? null
                            : (value) {
                                if (value == null) return;

                                setDialogState(() {
                                  _selectedProductType = value;
                                });
                              },
                      ),
                      const SizedBox(height: 14),
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
                        onChanged: _isCreatingOrder
                            ? null
                            : (value) {
                                if (value == null) return;

                                setDialogState(() {
                                  _selectedCurrencyCode = value;
                                });
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _grossAmountController,
                        enabled: !_isCreatingOrder,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Brüt Tutar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _discountAmountController,
                        enabled: !_isCreatingOrder,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'İndirim Tutarı',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildOrderSummaryRow(
                              'Ürün',
                              _productLabel(_selectedProductType),
                            ),
                            _buildOrderSummaryRow(
                              'Brüt Tutar',
                              '${_grossAmount.toStringAsFixed(2)} $_selectedCurrencyCode',
                            ),
                            _buildOrderSummaryRow(
                              'İndirim',
                              '${_discountAmount.toStringAsFixed(2)} $_selectedCurrencyCode',
                            ),
                            const Divider(),
                            _buildOrderSummaryRow(
                              'Net Tutar',
                              '${_netAmount.toStringAsFixed(2)} $_selectedCurrencyCode',
                              isBold: true,
                            ),
                            _buildOrderSummaryRow(
                              'Başlangıç Durumu',
                              'Beklemede',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 180),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: selectedSessions.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 14),
                          itemBuilder: (context, index) {
                            final session = selectedSessions[index];

                            return Row(
                              children: [
                                const Icon(
                                  Icons.analytics_outlined,
                                  size: 18,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${session.sessionCode} • Kullanıcı: ${session.patientLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isCreatingOrder
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton.icon(
                  onPressed: _isCreatingOrder
                      ? null
                      : () async {
                          setState(() {
                            _isCreatingOrder = true;
                          });

                          setDialogState(() {});

                          final result = await _persistOrdersForSessions(
                            selectedSessions: selectedSessions,
                          );

                          if (!mounted) return;

                          setState(() {
                            _isCreatingOrder = false;
                          });

                          setDialogState(() {});

                          if (result == null) return;

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!mounted) return;

                          final message = result.skippedCount > 0
                              ? '${result.createdCount} sipariş oluşturuldu. ${result.skippedCount} ölçüm için daha önce sipariş oluşturulmuş.'
                              : '${result.createdCount} sipariş oluşturuldu.';

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                              backgroundColor: result.createdCount > 0
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          );
                        },
                  icon: _isCreatingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text(
                    _isCreatingOrder ? 'Oluşturuluyor...' : 'Sipariş Oluştur',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_BulkOrderCreateResult?> _persistOrdersForSessions({
    required List<_MeasurementPoolSession> selectedSessions,
  }) async {
    if (_grossAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen geçerli bir brüt tutar girin.'),
        ),
      );
      return null;
    }

    final validSessions = selectedSessions
        .where(
          (session) =>
              session.id != null &&
              session.patientId != null &&
              session.clinicId != null &&
              session.expertUserId != null &&
              session.clinicId! > 0,
        )
        .toList();

    if (validSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş oluşturulabilecek geçerli session bulunamadı.'),
        ),
      );
      return null;
    }

    try {
      final existingOrderSessionIds = await _fetchExistingOrderSessionIds(
        validSessions.map((session) => session.id!).toList(),
      );

      final sessionsToCreate = validSessions
          .where((session) => !existingOrderSessionIds.contains(session.id))
          .toList();

      final skippedCount = validSessions.length - sessionsToCreate.length;

      if (sessionsToCreate.isEmpty) {
        await _loadSessions();

        return _BulkOrderCreateResult(
          createdCount: 0,
          skippedCount: skippedCount,
        );
      }

      final now = DateTime.now();

      final orderMaps = sessionsToCreate.asMap().entries.map((entry) {
        final index = entry.key;
        final session = entry.value;

        final order = OrderModel(
          sessionId: session.id!,
          patientId: session.patientId!,
          clinicId: session.clinicId!,
          expertUserId: session.expertUserId!,
          assignedOptityouUserId:
              widget.currentUser.userId ?? session.assignedOptityouUserId,
          orderNo: _generateOrderNo(
            sessionId: session.id!,
            index: index,
          ),
          productType: _selectedProductType,
          orderStatus: OrderStatuses.pending,
          currencyCode: _selectedCurrencyCode,
          grossAmount: _grossAmount,
          discountAmount: _discountAmount,
          netAmount: _netAmount,
          orderedAt: now,
        );

        return order.toInsertMap();
      }).toList();

      await _client.from('orders').insert(orderMaps);

      if (!mounted) return null;

      setState(() {
        _selectedSessionIds.clear();
      });

      await _loadSessions();

      return _BulkOrderCreateResult(
        createdCount: sessionsToCreate.length,
        skippedCount: skippedCount,
      );
    } catch (e) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş oluşturulamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );

      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSessions = _filteredSessions;

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 14),
          _buildToolbar(),
          const SizedBox(height: 14),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSessions.isEmpty
                    ? _buildEmptyState()
                    : _buildGroupedSessionList(filteredSessions),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ölçüm Havuzu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Uzmanlar tarafından onaylanan ölçümleri klinik bazında görüntüleyebilir ve seçili ölçümlerden sipariş oluşturabilirsin.',
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.35,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _selectedSessionIds.isEmpty || _isCreatingOrder
              ? null
              : _createOrderFromSelectedSessions,
          icon: _isCreatingOrder
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.shopping_bag_outlined, size: 18),
          label: Text(
            _selectedSessionIds.isEmpty
                ? 'Sipariş Oluştur'
                : 'Sipariş Oluştur (${_selectedSessionIds.length})',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    final statuses = _availableStatuses;
    final clinicFilters = _availableClinicFilters;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1050;

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isWide ? 360 : constraints.maxWidth,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Session kodu, kullanıcı, uzman, klinik veya tarih ile ara',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 165,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Durum',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Tümü'),
                    ),
                    ...statuses.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 230,
                child: DropdownButtonFormField<String>(
                  initialValue: _clinicFilter,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Klinik',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('Tüm klinikler'),
                    ),
                    ...clinicFilters.map(
                      (clinic) => DropdownMenuItem(
                        value: clinic.value,
                        child: Text(
                          clinic.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _clinicFilter = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectionFilter,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Seçim',
                    labelStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('Tümü'),
                    ),
                    DropdownMenuItem(
                      value: 'selected',
                      child: Text('Seçili'),
                    ),
                    DropdownMenuItem(
                      value: 'unselected',
                      child: Text('Seçilmemiş'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectionFilter = value;
                    });
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadSessions,
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Yenile'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              if (_selectedSessionIds.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.clear, size: 17),
                  label: const Text('Seçimi Temizle'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupedSessionList(List<_MeasurementPoolSession> sessions) {
    final groups = _groupSessionsByClinic(sessions);

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return _buildClinicGroupCard(groups[index]);
        },
      ),
    );
  }

  List<_ClinicSessionGroup> _groupSessionsByClinic(
    List<_MeasurementPoolSession> sessions,
  ) {
    final grouped = <String, List<_MeasurementPoolSession>>{};
    final labelByKey = <String, String>{};

    for (final session in sessions) {
      final key = session.clinicId == null || session.clinicId! <= 0
          ? 'clinic_unknown'
          : 'clinic_${session.clinicId}';

      grouped.putIfAbsent(key, () => <_MeasurementPoolSession>[]).add(session);
      labelByKey[key] = session.clinicLabel;
    }

    final groups = grouped.entries.map((entry) {
      final groupSessions = entry.value.toList()
        ..sort((a, b) {
          final aDate = a.completedAt ?? a.updatedAt ?? a.createdAt;
          final bDate = b.completedAt ?? b.updatedAt ?? b.createdAt;

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return bDate.compareTo(aDate);
        });

      return _ClinicSessionGroup(
        clinicLabel: labelByKey[entry.key] ?? 'Klinik bilgisi yok',
        sessions: groupSessions,
        isUnknownClinic: entry.key == 'clinic_unknown',
      );
    }).toList();

    groups.sort((a, b) {
      if (a.isUnknownClinic && !b.isUnknownClinic) return 1;
      if (!a.isUnknownClinic && b.isUnknownClinic) return -1;

      return a.clinicLabel.compareTo(b.clinicLabel);
    });

    return groups;
  }

  Widget _buildClinicGroupCard(_ClinicSessionGroup group) {
    final selectedCount = group.sessions
        .where(
          (session) =>
              session.id != null && _selectedSessionIds.contains(session.id),
        )
        .length;

    final groupColor = group.isUnknownClinic ? Colors.orange : Colors.teal;
    final groupIcon = group.isUnknownClinic
        ? Icons.warning_amber_outlined
        : Icons.local_hospital_outlined;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: group.isUnknownClinic
              ? Colors.orange.withOpacity(0.25)
              : Colors.grey.shade200,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: groupColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  groupIcon,
                  color: groupColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  group.clinicLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSmallCountChip(
                label: '${group.sessions.length} ölçüm',
                color: Colors.blueGrey,
              ),
              if (selectedCount > 0) ...[
                const SizedBox(width: 8),
                _buildSmallCountChip(
                  label: '$selectedCount seçili',
                  color: Colors.teal,
                ),
              ],
            ],
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;

              final cardWidth = maxWidth >= 1120
                  ? (maxWidth - 36) / 4
                  : maxWidth >= 820
                      ? (maxWidth - 24) / 3
                      : maxWidth >= 540
                          ? (maxWidth - 12) / 2
                          : maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: group.sessions.map((session) {
                  final selected = session.id != null &&
                      _selectedSessionIds.contains(session.id);

                  return SizedBox(
                    width: cardWidth,
                    child: _buildSessionCard(
                      session: session,
                      selected: selected,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCountChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700Safe,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSessionCard({
    required _MeasurementPoolSession session,
    required bool selected,
  }) {
    final accentColor = selected ? Colors.teal : Colors.blueGrey;

    return InkWell(
      onTap: () => _toggleSessionSelection(session.id),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected ? Colors.teal.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.teal : Colors.grey.shade300,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.analytics_outlined,
                    color: selected ? Colors.teal : Colors.blueGrey.shade700,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.sessionCode.isEmpty
                        ? 'Session #${session.id ?? '—'}'
                        : session.sessionCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                _buildStatusChip(session.effectiveStatus),
              ],
            ),
            const SizedBox(height: 10),
            _buildCardInfoRow(
              icon: Icons.account_circle_outlined,
              label: 'Kullanıcı',
              value: session.patientLabel,
            ),
            const SizedBox(height: 5),
            _buildCardInfoRow(
              icon: Icons.person_outline,
              label: 'Uzman',
              value: session.expertLabel,
            ),
            const SizedBox(height: 5),
            _buildCardInfoRow(
              icon: Icons.verified_outlined,
              label: 'Onay',
              value: session.formattedCompletedDate,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openSessionDetail(session),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Detay'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.teal.withOpacity(0.10)
                        : Colors.grey.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    selected ? 'Seçildi' : 'Seç',
                    style: TextStyle(
                      color: selected ? Colors.teal : Colors.grey[700],
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey[700]),
        const SizedBox(width: 5),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10.5,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final normalized = status.toLowerCase().trim();

    Color color;
    String label;

    switch (normalized) {
      case _SessionStatusCodes.completed:
      case 'tamamlandı':
      case 'tamamlandi':
        color = Colors.green;
        label = 'Tamamlandı';
        break;
      case _SessionStatusCodes.inProgress:
      case 'devam ediyor':
      case 'devam_ediyor':
        color = Colors.orange;
        label = 'Devam Ediyor';
        break;
      case _SessionStatusCodes.draft:
      case 'taslak':
        color = Colors.blueGrey;
        label = 'Taslak';
        break;
      case _SessionStatusCodes.cancelled:
      case 'iptal':
        color = Colors.red;
        label = 'İptal';
        break;
      default:
        color = Colors.grey;
        label = status.trim().isEmpty ? 'Durum Yok' : status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700Safe,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderSummaryRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
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

  String _statusLabel(String status) {
    final normalized = status.toLowerCase().trim();

    switch (normalized) {
      case _SessionStatusCodes.completed:
      case 'tamamlandı':
      case 'tamamlandi':
        return 'Tamamlandı';

      case _SessionStatusCodes.inProgress:
      case 'devam ediyor':
      case 'devam_ediyor':
        return 'Devam Ediyor';

      case _SessionStatusCodes.draft:
      case 'taslak':
        return 'Taslak';

      case _SessionStatusCodes.cancelled:
      case 'iptal':
        return 'İptal';

      default:
        return status.trim().isEmpty ? 'Durum Yok' : status;
    }
  }

  List<String> get _availableStatuses {
    final statuses = _sessions
        .map((session) => session.effectiveStatus.trim())
        .where((status) => status.isNotEmpty)
        .toSet()
        .toList();

    statuses.sort();
    return statuses;
  }

  List<_ClinicFilterItem> get _availableClinicFilters {
    final clinicMap = <String, String>{};

    for (final session in _sessions) {
      final key = session.clinicId == null || session.clinicId! <= 0
          ? 'unknown'
          : session.clinicId.toString();

      clinicMap[key] = session.clinicLabel;
    }

    final items = clinicMap.entries.map((entry) {
      return _ClinicFilterItem(
        value: entry.key,
        label: entry.value,
      );
    }).toList();

    items.sort((a, b) {
      if (a.value == 'unknown' && b.value != 'unknown') return 1;
      if (a.value != 'unknown' && b.value == 'unknown') return -1;

      return a.label.compareTo(b.label);
    });

    return items;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(28),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 52,
              color: Colors.teal.shade600,
            ),
            const SizedBox(height: 14),
            const Text(
              'Ölçüm havuzunda kayıt bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ekranda yalnızca uzman tarafından onaylanmış ve henüz siparişe dönüştürülmemiş ölçümler listelenir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class _MeasurementPoolSession {
  final int? id;
  final int? clinicId;
  final int? patientId;
  final int? expertUserId;
  final int? assignedOptityouUserId;

  final String sessionCode;
  final DateTime? sessionDate;
  final String? sessionTime;
  final String status;

  final bool has3dScan;
  final bool hasPlantarCsv;
  final bool hasInsolePhoto;
  final bool orderCreated;
  final bool clinicalInfoCompleted;
  final bool designFormCompleted;

  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? patientName;
  final String? expertName;
  final String? clinicName;
  final String? clinicCode;

  const _MeasurementPoolSession({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.expertUserId,
    required this.assignedOptityouUserId,
    required this.sessionCode,
    required this.sessionDate,
    required this.sessionTime,
    required this.status,
    required this.has3dScan,
    required this.hasPlantarCsv,
    required this.hasInsolePhoto,
    required this.orderCreated,
    required this.clinicalInfoCompleted,
    required this.designFormCompleted,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.patientName,
    required this.expertName,
    required this.clinicName,
    required this.clinicCode,
  });

  factory _MeasurementPoolSession.fromMap(Map<String, dynamic> map) {
    return _MeasurementPoolSession(
      id: _asInt(map['id'] ?? map['session_id']),
      clinicId: _asInt(map['clinic_id']),
      patientId: _asInt(map['patient_id']),
      expertUserId: _asInt(map['expert_user_id']),
      assignedOptityouUserId: _asInt(map['assigned_optityou_user_id']),
      sessionCode: (map['session_code'] ?? '').toString(),
      sessionDate: _asDateTime(map['session_date']),
      sessionTime: map['session_time']?.toString(),
      status: (map['status'] ?? _SessionStatusCodes.draft).toString(),
      has3dScan: _asBool(map['has_3d_scan']),
      hasPlantarCsv: _asBool(map['has_plantar_csv']),
      hasInsolePhoto: _asBool(map['has_insole_photo']),
      orderCreated: _asBool(map['order_created']),
      clinicalInfoCompleted: _asBool(map['clinical_info_completed']),
      designFormCompleted: _asBool(map['design_form_completed']),
      completedAt: _asDateTime(map['completed_at']),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
      patientName: null,
      expertName: null,
      clinicName: null,
      clinicCode: null,
    );
  }

  _MeasurementPoolSession copyWith({
    String? patientName,
    String? expertName,
    String? clinicName,
    String? clinicCode,
  }) {
    return _MeasurementPoolSession(
      id: id,
      clinicId: clinicId,
      patientId: patientId,
      expertUserId: expertUserId,
      assignedOptityouUserId: assignedOptityouUserId,
      sessionCode: sessionCode,
      sessionDate: sessionDate,
      sessionTime: sessionTime,
      status: status,
      has3dScan: has3dScan,
      hasPlantarCsv: hasPlantarCsv,
      hasInsolePhoto: hasInsolePhoto,
      orderCreated: orderCreated,
      clinicalInfoCompleted: clinicalInfoCompleted,
      designFormCompleted: designFormCompleted,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      patientName: patientName ?? this.patientName,
      expertName: expertName ?? this.expertName,
      clinicName: clinicName ?? this.clinicName,
      clinicCode: clinicCode ?? this.clinicCode,
    );
  }

  MeasurementSession toMeasurementSession() {
    return MeasurementSession(
      sessionId: id,
      clinicId: clinicId ?? 0,
      patientId: patientId ?? 0,
      expertUserId: expertUserId ?? 0,
      assignedOptityouUserId: assignedOptityouUserId,
      sessionCode: sessionCode,
      sessionDate: sessionDate ?? createdAt ?? DateTime.now(),
      sessionTime: sessionTime,
      status: status,
      has3dScan: has3dScan,
      hasPlantarCsv: hasPlantarCsv,
      hasInsolePhoto: hasInsolePhoto,
      orderCreated: orderCreated,
      clinicalInfoCompleted: clinicalInfoCompleted,
      designFormCompleted: designFormCompleted,
      completedAt: completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get hasAnyStepCompleted {
    return clinicalInfoCompleted ||
        has3dScan ||
        hasPlantarCsv ||
        hasInsolePhoto ||
        designFormCompleted ||
        orderCreated;
  }

  bool get allStepsCompleted {
    return clinicalInfoCompleted &&
        has3dScan &&
        hasPlantarCsv &&
        hasInsolePhoto &&
        designFormCompleted &&
        orderCreated;
  }

  String get effectiveStatus {
    if (status == _SessionStatusCodes.cancelled) {
      return _SessionStatusCodes.cancelled;
    }

    if (!hasAnyStepCompleted) {
      return _SessionStatusCodes.draft;
    }

    if (allStepsCompleted) {
      return _SessionStatusCodes.completed;
    }

    return _SessionStatusCodes.inProgress;
  }

  String get expertLabel {
    final name = expertName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (expertUserId == null) return '—';

    return 'Uzman #$expertUserId';
  }

  String get patientLabel {
    final name = patientName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (patientId == null) return '—';

    return 'Kullanıcı #$patientId';
  }

  String get clinicLabel {
    final name = clinicName?.trim();
    final code = clinicCode?.trim();

    if (name != null && name.isNotEmpty && code != null && code.isNotEmpty) {
      return '$name ($code)';
    }

    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (code != null && code.isNotEmpty) {
      return code;
    }

    if (clinicId == null || clinicId! <= 0) {
      return 'Klinik bilgisi yok';
    }

    return 'Klinik #$clinicId';
  }

  String get formattedDate {
    final value = sessionDate ?? createdAt;
    if (value == null) return '—';

    return _formatDate(value);
  }

  String get formattedDateWithTime {
    final date = formattedDate;

    if (sessionTime == null || sessionTime!.trim().isEmpty) {
      return date;
    }

    return '$date • ${sessionTime!.trim()}';
  }

  String get formattedCompletedDate {
    final value = completedAt ?? updatedAt ?? createdAt;

    if (value == null) return '—';

    return _formatDate(value);
  }

  static String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year}';
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == '1' || text == 'yes';
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }
}

class _ClinicSessionGroup {
  final String clinicLabel;
  final List<_MeasurementPoolSession> sessions;
  final bool isUnknownClinic;

  const _ClinicSessionGroup({
    required this.clinicLabel,
    required this.sessions,
    required this.isUnknownClinic,
  });
}

class _ClinicFilterItem {
  final String value;
  final String label;

  const _ClinicFilterItem({
    required this.value,
    required this.label,
  });
}

class _BulkOrderCreateResult {
  final int createdCount;
  final int skippedCount;

  const _BulkOrderCreateResult({
    required this.createdCount,
    required this.skippedCount,
  });
}

class _SessionStatusCodes {
  static const String draft = 'draft';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

extension _MaterialColorShadeSafe on Color {
  Color get shade700Safe {
    final color = this;

    if (color is MaterialColor) {
      return color.shade700;
    }

    return color;
  }
}