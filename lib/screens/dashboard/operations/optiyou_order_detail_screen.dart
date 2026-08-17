import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:oy_site/data/repositories/supabase_anthropometric_clinical_info_repository.dart';
import 'package:oy_site/data/repositories/supabase_order_operation_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_invite_repository.dart';
import 'package:oy_site/models/anthropometric_clinical_info_model.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/models/order_operation_file_model.dart';
import 'package:oy_site/models/order_operation_state_model.dart';
import 'package:oy_site/models/patient_invite_model.dart';
import 'package:oy_site/screens/dashboard/operations/optiyou_measurement_review_screen.dart';
import 'package:oy_site/screens/dashboard/orthotics/orthotic_design_form_screen.dart';
import 'package:oy_site/screens/dashboard/analysis/session_analysis_results_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oy_site/screens/dashboard/analysis/reference_insole_analysis_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OptiYouOrderDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final OptiYouOrderOperationItem operationItem;
  final dynamic pressureRepository;

  const OptiYouOrderDetailScreen({
    super.key,
    required this.currentUser,
    required this.operationItem,
    this.pressureRepository,
  });

  @override
  State<OptiYouOrderDetailScreen> createState() =>
      _OptiYouOrderDetailScreenState();
}

class _OptiYouOrderDetailScreenState extends State<OptiYouOrderDetailScreen> {
  static const String _camFileType = 'cam_file';
  static const String _gcodeFileType = 'gcode_file';

  final SupabaseOrderOperationRepository _operationRepository =
      SupabaseOrderOperationRepository();

  final SupabasePatientInviteRepository _inviteRepository =
      SupabasePatientInviteRepository();

  final SupabaseAnthropometricClinicalInfoRepository _clinicalInfoRepository =
      SupabaseAnthropometricClinicalInfoRepository();

  final GlobalKey _packagingQrCardKey = GlobalKey();

  SupabaseClient get _client => Supabase.instance.client;

  OrderModel get order => widget.operationItem.order;

  OrderOperationStateModel? _operationState;
  MeasurementSession? _session;
  late String _currentOrderStatus;
  DateTime? _currentShippedAt;
  DateTime? _currentDeliveredAt;

  final Map<String, OrderOperationFileModel> _operationFiles = {};

  bool _isLoadingOperation = true;
  bool _isSavingOperation = false;
  bool _isPreparingPackagingQr = false;

  PatientInviteModel? _packagingInvite;

  bool _designCompleted = false;
  bool _productionStarted = false;
  bool _productionCompleted = false;

  bool _qcDesignMatch = false;
  bool _qcMeasurementDone = false;
  bool _qcSurfaceChecked = false;
  bool _qcReadyForDelivery = false;

  bool _packagingCompleted = false;
  bool _orderClosed = false;

  String? _leftDesignStlName;
  String? _rightDesignStlName;
  String? _camFileName;
  String? _gcodeFileName;

  final TextEditingController _qualityNoteController = TextEditingController();
  final TextEditingController _shippingTrackingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    _currentOrderStatus = order.orderStatus;
    _currentShippedAt = order.shippedAt;
    _currentDeliveredAt = order.deliveredAt;

    _loadOperationData();
  }

  @override
  void dispose() {
    _qualityNoteController.dispose();
    _shippingTrackingController.dispose();
    super.dispose();
  }

  Future<void> _loadOperationData() async {
    final orderId = order.orderId;

    if (orderId == null) {
      setState(() => _isLoadingOperation = false);
      return;
    }

    setState(() => _isLoadingOperation = true);

    try {
      final state = await _operationRepository.getStateByOrderId(
        orderId: orderId,
      );

      final files = await _operationRepository.getFilesByOrderId(
        orderId: orderId,
      );

      final session = await _loadSessionForOrder();

      final effectiveState = state ??
          OrderOperationStateModel.empty(
            orderId: orderId,
            sessionId: order.sessionId,
            patientId: order.patientId,
            assignedUserId: widget.currentUser.userId,
          );

      if (!mounted) return;

      setState(() {
        _session = session;
        _operationState = effectiveState;

        _designCompleted = effectiveState.designCompleted;
        _productionStarted = effectiveState.productionStarted;
        _productionCompleted = effectiveState.productionCompleted;

        _qcDesignMatch = effectiveState.qcDesignMatch;
        _qcMeasurementDone = effectiveState.qcMeasurementDone;
        _qcSurfaceChecked = effectiveState.qcSurfaceChecked;
        _qcReadyForDelivery = effectiveState.qcReadyForDelivery;

        _qualityNoteController.text = effectiveState.qcNote ?? '';

        _packagingCompleted = effectiveState.packagingCompleted;
        _shippingTrackingController.text =
            effectiveState.shippingTrackingNo ?? '';

        _orderClosed = effectiveState.orderClosed;

        _operationFiles.clear();
        for (final file in files) {
          _operationFiles[file.fileType] = file;
        }

        _leftDesignStlName =
            _operationFiles[OrderOperationFileTypes.leftDesignStl]?.fileName;
        _rightDesignStlName =
            _operationFiles[OrderOperationFileTypes.rightDesignStl]?.fileName;

        _camFileName = _operationFiles[_camFileType]?.fileName;
        _gcodeFileName = _operationFiles[_gcodeFileType]?.fileName;

        _isLoadingOperation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingOperation = false);
      _showMessage('Operasyon verileri yüklenemedi: $e');
    }
  }

  Future<MeasurementSession?> _loadSessionForOrder() async {
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
          .eq('id', order.sessionId)
          .maybeSingle();

      if (response == null) return null;

      return _measurementSessionFromMap(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (_) {
      return null;
    }
  }

  MeasurementSession _measurementSessionFromMap(Map<String, dynamic> map) {
    return MeasurementSession(
      sessionId: _asInt(map['id'] ?? map['session_id']),
      clinicId: _asInt(map['clinic_id']) ?? order.clinicId,
      patientId: _asInt(map['patient_id']) ?? order.patientId,
      expertUserId: _asInt(map['expert_user_id']) ?? order.expertUserId,
      assignedOptityouUserId: _asInt(map['assigned_optityou_user_id']),
      sessionCode: (map['session_code'] ?? '').toString(),
      sessionDate: _asDateTime(map['session_date']) ??
          _asDateTime(map['created_at']) ??
          DateTime.now(),
      sessionTime: map['session_time']?.toString(),
      status: (map['status'] ?? SessionStatuses.draft).toString(),
      has3dScan: _asBool(map['has_3d_scan']),
      hasPlantarCsv: _asBool(map['has_plantar_csv']),
      hasInsolePhoto: _asBool(map['has_insole_photo']),
      orderCreated: _asBool(map['order_created']),
      clinicalInfoCompleted: _asBool(map['clinical_info_completed']),
      designFormCompleted: _asBool(map['design_form_completed']),
      completedAt: _asDateTime(map['completed_at']),
      createdAt: _asDateTime(map['created_at']),
      updatedAt: _asDateTime(map['updated_at']),
    );
  }

  Future<MeasurementSession?> _ensureSessionLoaded() async {
    if (_session != null) return _session;

    final loaded = await _loadSessionForOrder();

    if (!mounted) return loaded;

    setState(() {
      _session = loaded;
    });

    return loaded;
  }

  String _deriveOrderStatusFromOperation() {
    if (_currentOrderStatus == OrderStatuses.cancelled) {
      return OrderStatuses.cancelled;
    }

    if (_orderClosed) {
      return OrderStatuses.delivered;
    }

    final hasTrackingNo = _shippingTrackingController.text.trim().isNotEmpty;

    if (_packagingCompleted && hasTrackingNo) {
      return OrderStatuses.shipped;
    }

    if (_productionStarted || _productionCompleted) {
      return OrderStatuses.production;
    }

    if (_designCompleted) {
      return OrderStatuses.designing;
    }

    return OrderStatuses.pending;
  }

  Future<void> _syncOrderStatusIfNeeded({
    required int orderId,
  }) async {
    final nextStatus = _deriveOrderStatusFromOperation();

    final updateMap = <String, dynamic>{};

    if (nextStatus != _currentOrderStatus) {
      updateMap['order_status'] = nextStatus;
    }

    DateTime? nextShippedAt = _currentShippedAt;
    DateTime? nextDeliveredAt = _currentDeliveredAt;

    if (nextStatus == OrderStatuses.shipped && nextShippedAt == null) {
      nextShippedAt = DateTime.now();
      updateMap['shipped_at'] = nextShippedAt.toIso8601String();
    }

    if (nextStatus == OrderStatuses.delivered && nextDeliveredAt == null) {
      nextDeliveredAt = DateTime.now();
      updateMap['delivered_at'] = nextDeliveredAt.toIso8601String();
    }

    if (updateMap.isEmpty) return;

    await _client.from('orders').update(updateMap).eq('id', orderId);

    if (!mounted) return;

    setState(() {
      _currentOrderStatus = nextStatus;
      _currentShippedAt = nextShippedAt;
      _currentDeliveredAt = nextDeliveredAt;
    });
  }

  Future<void> _persistOperationState() async {
    final orderId = order.orderId;
    final userId = widget.currentUser.userId;

    if (orderId == null) return;

    setState(() => _isSavingOperation = true);

    try {
      final state = OrderOperationStateModel(
        id: _operationState?.id,
        orderId: orderId,
        sessionId: order.sessionId,
        patientId: order.patientId,
        assignedUserId: userId,
        boardColumnCode: _operationState?.boardColumnCode ??
            widget.operationItem.currentColumnCode,
        designCompleted: _designCompleted,
        productionStarted: _productionStarted,
        productionCompleted: _productionCompleted,
        qcDesignMatch: _qcDesignMatch,
        qcMeasurementDone: _qcMeasurementDone,
        qcSurfaceChecked: _qcSurfaceChecked,
        qcReadyForDelivery: _qcReadyForDelivery,
        qcNote: _qualityNoteController.text.trim(),
        packagingCompleted: _packagingCompleted,
        shippingTrackingNo: _shippingTrackingController.text.trim(),
        orderClosed: _orderClosed,
      );
      final saved = await _operationRepository.upsertState(state: state);

      await _syncOrderStatusIfNeeded(orderId: orderId);

      if (!mounted) return;

      setState(() {
        _operationState = saved;
        _isSavingOperation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSavingOperation = false);
      _showMessage('Operasyon durumu kaydedilemedi: $e');
    }
  }

  Future<void> _pickAndUploadOperationFile({
    required String title,
    required String fileType,
    required void Function(String fileName) onSelected,
  }) async {
    final orderId = order.orderId;
    final userId = widget.currentUser.userId;

    if (orderId == null || userId == null) {
      _showMessage('Order ID veya kullanıcı ID bulunamadı.');
      return;
    }

    final result = await FilePicker.pickFiles(
      dialogTitle: title,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    if (file.path == null) {
      _showMessage('Dosya yolu alınamadı.');
      return;
    }

    try {
      setState(() => _isSavingOperation = true);

      final uploaded = await _operationRepository.uploadOperationFile(
        orderId: orderId,
        sessionId: order.sessionId,
        patientId: order.patientId,
        uploadedByUserId: userId,
        fileType: fileType,
        localFilePath: file.path!,
        fileName: file.name,
      );

      if (!mounted) return;

      setState(() {
        _operationFiles[fileType] = uploaded;
        onSelected(uploaded.fileName ?? file.name);
        _isSavingOperation = false;
      });

      _showMessage('${uploaded.fileName ?? file.name} Storage’a yüklendi.');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSavingOperation = false);
      _showMessage('Dosya yüklenemedi: $e');
    }
  }

  Future<void> _downloadOperationFile(String fileType, String label) async {
    final file = _operationFiles[fileType];

    if (file == null) {
      _showMessage('$label için yüklü dosya bulunamadı.');
      return;
    }

    try {
      final url = await _operationRepository.createSignedUrl(file: file);
      await _openUrl(url);
    } catch (e) {
      _showMessage('Dosya indirilemedi: $e');
    }
  }

  Future<void> _openDesignForm() async {
    final session = await _ensureSessionLoaded();

    if (session == null) {
      _showMessage('Bu siparişe bağlı ölçüm oturumu okunamadı.');
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrthoticDesignFormScreen(
          currentUser: widget.currentUser,
          session: session,
        ),
      ),
    );
  }

  Future<void> _openAnalysisResults() async {
    final session = await _ensureSessionLoaded();

    if (session == null) {
      _showMessage('Bu siparişe bağlı ölçüm oturumu okunamadı.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionAnalysisResultsScreen(
          currentUser: widget.currentUser,
          session: session,
        ),
      ),
    );
  }

  Future<void> _openSessionInputs() async {
    final session = await _ensureSessionLoaded();

    if (session?.sessionId == null || session!.expertUserId <= 0) {
      _showMessage('Bu siparişe bağlı ölçüm oturumu okunamadı.');
      return;
    }
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OptiYouMeasurementReviewScreen(
          currentUser: widget.currentUser,
          session: session,
          pressureRepository: widget.pressureRepository,
        ),
      ),
    );

    if (mounted) await _loadOperationData();
  }

  Future<void> _openClinicalInfo() async {
    final session = await _ensureSessionLoaded();

    if (session?.sessionId == null) {
      _showMessage('Bu siparişe bağlı ölçüm oturumu okunamadı.');
      return;
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.medical_information_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('Klinik / Antropometrik Bilgiler')),
          ],
        ),
        content: SizedBox(
          width: 680,
          child: FutureBuilder<AnthropometricClinicalInfoModel?>(
            future: _clinicalInfoRepository.getBySessionId(session!.sessionId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const Text(
                  'Klinik / antropometrik bilgiler yüklenemedi.',
                );
              }
              final info = snapshot.data;
              if (info == null) {
                return const Text(
                  'Bu ölçüm oturumu için klinik / antropometrik bilgi bulunamadı.',
                );
              }
              return _buildClinicalInfoContent(info);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalInfoContent(AnthropometricClinicalInfoModel info) {
    String number(double? value, {String suffix = ''}) => value == null
        ? 'Belirtilmedi'
        : '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}$suffix';
    String text(String? value) => value == null || value.trim().isEmpty
        ? 'Belirtilmedi'
        : value.trim();

    final pathologies = <String>[
      if (info.halluxValgus) 'Halluks valgus',
      if (info.heelSpur) 'Topuk dikeni',
      if (info.flatFoot) 'Düz tabanlık',
      if (info.pesCavus) 'Yüksek kavisli ayak',
      if (info.mortonNeuroma) 'Morton nöroması',
      if (info.achillesProblem) 'Aşil problemi',
      if (info.metatarsalPain) 'Metatarsal ağrı',
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 620),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClinicalSection('Antropometrik Bilgiler', [
              ('Boy', number(info.heightCm, suffix: ' cm')),
              ('Kilo', number(info.weightKg, suffix: ' kg')),
              ('Vücut kitle indeksi', number(info.bmi)),
              ('Ayakkabı numarası', number(info.shoeSizeEu)),
            ]),
            _buildClinicalSection('Meslek ve Günlük Yaşam', [
              ('Meslek', text(info.profession)),
              ('Günlük ayakta kalma', number(info.dailyStandingHours, suffix: ' saat')),
              ('İş tanımı', text(info.jobDescription)),
              ('Spor yapıyor', info.doesSport ? 'Evet' : 'Hayır'),
              if (info.doesSport) ('Spor bilgisi', text(info.sportDescription)),
            ]),
            _buildClinicalSection('Klinik Bilgiler', [
              ('Mevcut şikâyet', text(info.currentComplaint)),
              ('Tanı / ön tanı', text(info.diagnosisPreDiagnosis)),
              ('Diyabet', info.hasDiabetes ? 'Var' : 'Yok'),
              if (info.hasDiabetes) ('Diyabet notu', text(info.diabetesNote)),
              ('Patolojiler', pathologies.isEmpty ? 'Belirtilmedi' : pathologies.join(', ')),
              ('Diğer patolojiler', text(info.otherPathologies)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalSection(
    String title,
    List<(String, String)> values,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 8),
          ...values.map((value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(value.$1, style: TextStyle(color: Colors.grey.shade700)),
                ),
                Expanded(child: Text(value.$2, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _openReferenceInsoleAnalysis() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReferenceInsoleAnalysisScreen(
          currentUser: widget.currentUser,
          operationItem: widget.operationItem,
        ),
      ),
    );
  }

  Future<void> _downloadLeftScanFile() async {
    await _downloadScanFile(
      label: 'Sol ayak 3D scan STL',
      preferredSideKeywords: const ['left', 'sol'],
    );
  }

  Future<void> _downloadRightScanFile() async {
    await _downloadScanFile(
      label: 'Sağ ayak 3D scan STL',
      preferredSideKeywords: const ['right', 'sag', 'sağ'],
    );
  }

  Future<void> _downloadScanFile({
    required String label,
    required List<String> preferredSideKeywords,
  }) async {
    try {
      final rows = await _fetchSessionScanFiles();

      if (rows.isEmpty) {
        _showMessage('Bu oturum için 3D scan dosyası bulunamadı.');
        return;
      }

      final preferredSideNormalized =
          preferredSideKeywords.map(_normalizeSearchText).toList();

      final stlRows = rows.where(_looksLikeStlScanRecord).toList();

      if (stlRows.isEmpty) {
        _showMessage('Bu oturum için STL formatında 3D scan dosyası bulunamadı.');
        return;
      }

      final exactSideMatches = stlRows.where((row) {
        final text = _storageRecordSearchText(row);

        return preferredSideNormalized.any((keyword) {
          return text.contains(keyword);
        });
      }).toList();

      if (exactSideMatches.length == 1) {
        await _openStorageRecord(
          exactSideMatches.first,
          emptyMessage: '$label için storage bilgisi bulunamadı.',
        );
        return;
      }

      if (exactSideMatches.length > 1) {
        final selected = await _showStorageRecordPicker(
          title: '$label seç',
          records: exactSideMatches,
        );

        if (selected == null) return;

        await _openStorageRecord(
          selected,
          emptyMessage: '$label için storage bilgisi bulunamadı.',
        );
        return;
      }

      final selected = await _showStorageRecordPicker(
        title: '$label bulunamadı, STL dosyası seç',
        records: stlRows,
        helperText:
            'Bu oturumda $label olarak net eşleşen dosya bulunamadı. Yanlış dosya açmamak için lütfen doğru STL dosyasını seç.',
      );

      if (selected == null) return;

      await _openStorageRecord(
        selected,
        emptyMessage: '$label için storage bilgisi bulunamadı.',
      );
    } catch (e) {
      _showMessage('$label indirilemedi: $e');
    }
  }

  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  String _storageRecordSearchText(_StorageRecord record) {
    return _normalizeSearchText(
      [
        record.fileType,
        record.fileName,
        record.storagePath ?? '',
        record.storageBucket ?? '',
      ].join(' '),
    );
  }

  bool _looksLikeStlScanRecord(_StorageRecord record) {
    final text = _storageRecordSearchText(record);

    final hasStlExtension = text.contains('.stl');
    final hasStlType = text.contains('stl');
    final hasScanHint =
        text.contains('scan') ||
        text.contains('3d') ||
        text.contains('foot') ||
        text.contains('ayak');

    final looksLikeReferencePhoto =
        text.contains('photo') ||
        text.contains('foto') ||
        text.contains('image') ||
        text.contains('jpg') ||
        text.contains('jpeg') ||
        text.contains('png');

    if (looksLikeReferencePhoto) return false;

    return hasStlExtension || (hasStlType && hasScanHint);
  }

  Future<_StorageRecord?> _showStorageRecordPicker({
    required String title,
    required List<_StorageRecord> records,
    String? helperText,
  }) async {
    if (!mounted) return null;

    return showDialog<_StorageRecord>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (helperText != null && helperText.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    helperText,
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final row = records[index];

                    return ListTile(
                      leading: const Icon(
                        Icons.view_in_ar_outlined,
                        color: Colors.teal,
                      ),
                      title: Text(
                        row.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(row.subtitle),
                      onTap: () => Navigator.pop(context, row),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPressureRecordings() async {
    try {
      final rows = await _fetchPressureRecordings();

      if (rows.isEmpty) {
        _showMessage('Bu oturum için basınç kaydı bulunamadı.');
        return;
      }

      if (rows.length == 1) {
        await _openStorageRecord(
          rows.first,
          emptyMessage: 'Basınç kaydı için storage bilgisi bulunamadı.',
        );
        return;
      }

      if (!mounted) return;

      final selected = await showDialog<_StorageRecord>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Basınç Kaydı Seç'),
          content: SizedBox(
            width: 520,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: rows.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final row = rows[index];

                return ListTile(
                  leading: const Icon(Icons.speed, color: Colors.teal),
                  title: Text(row.displayName),
                  subtitle: Text(row.subtitle),
                  onTap: () => Navigator.pop(context, row),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );

      if (selected == null) return;

      await _openStorageRecord(
        selected,
        emptyMessage: 'Basınç kaydı için storage bilgisi bulunamadı.',
      );
    } catch (e) {
      _showMessage('Basınç kayıtları indirilemedi: $e');
    }
  }

  Future<void> _downloadReferenceInsolePhoto() async {
    try {
      final rows = await _fetchReferencePhotos();

      if (rows.isEmpty) {
        _showMessage('Bu oturum için referans iç taban fotoğrafı bulunamadı.');
        return;
      }

      final preferred = rows.where((row) {
        final text = [
          row.fileType,
          row.fileName,
          row.storagePath,
        ].join(' ').toLowerCase();

        return text.contains('insole') ||
            text.contains('ic_taban') ||
            text.contains('iç_taban') ||
            text.contains('iç taban') ||
            text.contains('taban') ||
            text.contains('reference') ||
            text.contains('referans');
      }).toList();

      final selected = preferred.isNotEmpty ? preferred.first : rows.first;

      await _openStorageRecord(
        selected,
        emptyMessage:
            'Referans iç taban fotoğrafı için storage bilgisi bulunamadı.',
      );
    } catch (e) {
      _showMessage('Referans iç taban fotoğrafı indirilemedi: $e');
    }
  }

  Future<List<_StorageRecord>> _fetchSessionScanFiles() async {
    final response = await _client
        .from('session_scan_files')
        .select('''
          id,
          file_type,
          file_name,
          mime_type,
          size_bytes,
          storage_bucket,
          storage_path,
          public_url,
          upload_status,
          created_at
        ''')
        .eq('session_id', order.sessionId)
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return rows.map((row) {
      final id = _asInt(row['id']);
      final fileType = (row['file_type'] ?? '').toString();
      final fileName = (row['file_name'] ?? '').toString();
      final bucket = (row['storage_bucket'] ?? '').toString();
      final path = (row['storage_path'] ?? '').toString();
      final publicUrl = (row['public_url'] ?? '').toString();
      final createdAt = _asDateTime(row['created_at']);

      return _StorageRecord(
        id: id,
        fileType: fileType,
        fileName: fileName,
        storageBucket: bucket.isEmpty ? null : bucket,
        storagePath: path.isEmpty ? null : path,
        publicUrl: publicUrl.isEmpty ? null : publicUrl,
        createdAt: createdAt,
      );
    }).toList();
  }

  Future<List<_StorageRecord>> _fetchPressureRecordings() async {
    final response = await _client
        .from('session_pressure_recordings')
        .select('''
          id,
          title,
          frame_count,
          duration_ms,
          max_pressure,
          avg_pressure,
          storage_bucket,
          storage_path,
          upload_status,
          recorded_at,
          created_at
        ''')
        .eq('session_id', order.sessionId)
        .order('recorded_at', ascending: false);

    final rows = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return rows.map((row) {
      final id = _asInt(row['id']);
      final title = (row['title'] ?? '').toString();
      final bucket = (row['storage_bucket'] ?? '').toString();
      final path = (row['storage_path'] ?? '').toString();
      final recordedAt = _asDateTime(row['recorded_at']);
      final createdAt = _asDateTime(row['created_at']);

      final frameCount = _asInt(row['frame_count']);
      final durationMs = _asInt(row['duration_ms']);

      final details = <String>[
        if (frameCount != null) '$frameCount frame',
        if (durationMs != null) '${(durationMs / 1000).toStringAsFixed(1)} sn',
      ].join(' • ');

      return _StorageRecord(
        id: id,
        fileType: 'pressure_recording',
        fileName: title.isNotEmpty ? title : 'Basınç kaydı #${id ?? '—'}',
        storageBucket: bucket.isEmpty ? null : bucket,
        storagePath: path.isEmpty ? null : path,
        publicUrl: null,
        createdAt: recordedAt ?? createdAt,
        subtitleExtra: details,
      );
    }).toList();
  }

  Future<List<_StorageRecord>> _fetchReferencePhotos() async {
    final response = await _client
        .from('session_reference_photos')
        .select()
        .eq('session_id', order.sessionId)
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return rows.map((row) {
      final id = _asInt(row['id']);

      final fileType = (row['file_type'] ??
              row['photo_type'] ??
              row['reference_type'] ??
              'reference_photo')
          .toString();

      final fileName = (row['file_name'] ??
              row['title'] ??
              row['photo_title'] ??
              'Referans iç taban fotoğrafı #${id ?? '—'}')
          .toString();

      final bucket = (row['storage_bucket'] ?? '').toString();
      final path = (row['storage_path'] ?? '').toString();
      final publicUrl = (row['public_url'] ?? '').toString();
      final createdAt = _asDateTime(row['created_at']);

      return _StorageRecord(
        id: id,
        fileType: fileType,
        fileName: fileName,
        storageBucket: bucket.isEmpty ? null : bucket,
        storagePath: path.isEmpty ? null : path,
        publicUrl: publicUrl.isEmpty ? null : publicUrl,
        createdAt: createdAt,
      );
    }).toList();
  }

  Future<void> _openStorageRecord(
    _StorageRecord record, {
    required String emptyMessage,
  }) async {
    if (record.publicUrl != null && record.publicUrl!.trim().isNotEmpty) {
      await _openUrl(record.publicUrl!);
      return;
    }

    final bucket = record.storageBucket;
    final path = record.storagePath;

    if (bucket == null ||
        bucket.trim().isEmpty ||
        path == null ||
        path.trim().isEmpty) {
      _showMessage(emptyMessage);
      return;
    }

    final signedUrl = await _client.storage.from(bucket).createSignedUrl(
          path,
          3600,
        );

    await _openUrl(signedUrl);
  }

  Future<void> _showPackagingQrDialog() async {
    try {
      setState(() => _isPreparingPackagingQr = true);

      final invite = await _getOrCreatePackagingInvite();

      if (!mounted) return;

      setState(() {
        _packagingInvite = invite;
        _isPreparingPackagingQr = false;
      });

      final welcomeUrl = _buildWelcomeQrUrl(invite.token);

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Kutu Broşürü QR Kodu'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _packagingQrCardKey,
                    child: _buildPackagingQrExportCard(
                      invite: invite,
                      welcomeUrl: welcomeUrl,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    welcomeUrl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.withOpacity(0.18)),
                    ),
                    child: Text(
                      'Bu QR kod kullanıcıyı hoş geldin sayfasına götürür. Kullanıcı aynı sayfada hesap oluşturup sonuçlarına güvenli şekilde erişebilir.',
                      style: TextStyle(
                        color: Colors.teal.shade900,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: welcomeUrl));

                if (!mounted) return;

                _showMessage('QR linki kopyalandı.');
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Linki Kopyala'),
            ),
            OutlinedButton.icon(
              onPressed: () => _savePackagingQrPng(invite: invite),
              icon: const Icon(Icons.download_outlined),
              label: const Text('PNG Kaydet'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kapat'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isPreparingPackagingQr = false);
      _showMessage('QR hazırlanamadı: $e');
    }
  }

  Future<PatientInviteModel> _getOrCreatePackagingInvite() async {
    final cached = _packagingInvite;
    if (cached != null && cached.isStillValid) return cached;

    final latest = await _inviteRepository.getLatestInviteForSession(
      sessionId: order.sessionId,
    );

    if (latest != null && latest.isStillValid) {
      return latest;
    }

    final patientEmail = await _loadPatientEmailForInvite();

    return _inviteRepository.createInvite(
      patientId: order.patientId,
      sessionId: order.sessionId,
      expertUserId: order.expertUserId,
      email: patientEmail,
      validDays: 365,
    );
  }

  Future<String?> _loadPatientEmailForInvite() async {
    try {
      final response = await _client
          .from('patients')
          .select('email')
          .eq('id', order.patientId)
          .maybeSingle();

      if (response == null) return null;

      final map = Map<String, dynamic>.from(response as Map);
      final email = map['email']?.toString().trim();

      return email == null || email.isEmpty ? null : email;
    } catch (_) {
      return null;
    }
  }

  String _buildWelcomeQrUrl(String inviteToken) {
    final encodedToken = Uri.encodeQueryComponent(inviteToken);
    return 'https://www.optiyou.fit/#/welcome?invite=$encodedToken&source=package';
  }

  Future<void> _savePackagingQrPng({
    required PatientInviteModel invite,
  }) async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));

      final boundaryContext = _packagingQrCardKey.currentContext;
      if (boundaryContext == null) {
        _showMessage('QR görseli henüz hazır değil. Tekrar deneyin.');
        return;
      }

      final boundary = boundaryContext.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        _showMessage('QR görseli okunamadı.');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showMessage('PNG verisi oluşturulamadı.');
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final fileName =
          '${_safeFileName(order.orderNo)}_welcome_qr_${invite.inviteId ?? DateTime.now().millisecondsSinceEpoch}.png';

      await _saveBytesToComputer(
        fileName: fileName,
        bytes: bytes,
        extensions: const ['png'],
      );

      _showMessage('QR PNG olarak kaydedildi.');
    } catch (e) {
      _showMessage('QR PNG kaydedilemedi: $e');
    }
  }

  Future<void> _saveBytesToComputer({
    required String fileName,
    required Uint8List bytes,
    required List<String> extensions,
  }) async {
    await FilePicker.saveFile(
      dialogTitle: 'Dosyayı kaydet',
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: extensions,
    );
  }

  Widget _buildPackagingQrExportCard({
    required PatientInviteModel invite,
    required String welcomeUrl,
  }) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2_outlined,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Optiyou',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF07343A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Kişisel iç taban deneyiminiz başladı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: welcomeUrl,
              version: QrVersions.auto,
              size: 230,
              gapless: true,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sonuçlarınıza güvenli erişim için okutun',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.teal.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sipariş: ${order.orderNo}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          Text(
            'Davet: ${invite.token.length > 14 ? '${invite.token.substring(0, 14)}...' : invite.token}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingQrPanel() {
    final invite = _packagingInvite;
    final url = invite == null ? null : _buildWelcomeQrUrl(invite.token);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.withOpacity(0.12),
                child: const Icon(
                  Icons.qr_code_2_outlined,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kutu Broşürü QR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kutunun içine eklenecek broşür için hoş geldin sayfası QR kodunu oluştur ve PNG olarak kaydet.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    if (url != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        url,
                        style: TextStyle(
                          color: Colors.teal.shade900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed:
                  _isPreparingPackagingQr ? null : _showPackagingQrDialog,
              icon: _isPreparingPackagingQr
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_2_outlined),
              label: Text(
                _isPreparingPackagingQr
                    ? 'QR hazırlanıyor...'
                    : invite == null
                        ? 'QR Oluştur / PNG Kaydet'
                        : 'QR Görüntüle / PNG Kaydet',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _safeFileName(String value) {
    final normalized = value.trim().isEmpty ? 'order' : value.trim();

    return normalized
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      _showMessage('Dosya bağlantısı açılamadı.');
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryInfoCard() {
    return _buildSectionCard(
      title: 'Sipariş ve Kullanıcı Bilgileri',
      child: Column(
        children: [
          _buildHighlightInfoRow(
            icon: Icons.account_circle_outlined,
            label: 'Kullanıcı',
            value: widget.operationItem.patientName,
            color: Colors.teal,
          ),
          const SizedBox(height: 10),
          _buildHighlightInfoRow(
            icon: Icons.local_hospital_outlined,
            label: 'Klinik',
            value: widget.operationItem.clinicName,
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildHighlightInfoRow(
            icon: Icons.person_outline,
            label: 'Uzman',
            value: widget.operationItem.expertName,
            color: Colors.deepPurple,
          ),
          const Divider(height: 26),
          _buildKeyValueRow('Sipariş No', order.orderNo),
          _buildKeyValueRow(
            'Oturum',
            _session?.sessionCode.trim().isNotEmpty == true
                ? _session!.sessionCode
                : 'Oturum bilgisi okunamadı',
          ),
          _buildKeyValueRow('Ürün', _productLabel(order.productType)),
          _buildKeyValueRow('Durum', _statusLabel(_currentOrderStatus)),
        ],
      ),
    );
  }

  Widget _buildHighlightInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? '—' : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard({
    required int index,
    required String title,
    required String description,
    required IconData icon,
    required bool completed,
    required Widget child,
  }) {
    final color = completed ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              completed ? Colors.green.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$index. $title',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  completed ? 'Tamamlandı' : 'Bekliyor',
                  style: TextStyle(
                    color: completed
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildExpandableFileSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
    bool initiallyExpanded = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Icon(
            icon,
            color: Colors.teal,
            size: 20,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedFileRow({
    required String label,
    required String? fileName,
    required VoidCallback onUpload,
    required VoidCallback onDownload,
  }) {
    final hasFile = fileName != null && fileName.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            color: hasFile ? Colors.teal : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasFile ? '$label: $fileName' : '$label: Dosya yok',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasFile ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
          IconButton(
            tooltip: 'İndir',
            onPressed: hasFile ? onDownload : null,
            icon: const Icon(Icons.download_outlined),
          ),
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file),
            label: const Text('Yükle'),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingFileDownloadRow({
    required String label,
    required String? fileName,
    required VoidCallback onDownload,
  }) {
    final hasFile = fileName != null && fileName.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            color: hasFile ? Colors.teal : Colors.grey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasFile ? '$label: $fileName' : '$label: Dosya yok',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasFile ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
          IconButton(
            tooltip: 'İndir / Aç',
            onPressed: hasFile ? onDownload : null,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildInputDownloadRow({
    required String label,
    required VoidCallback onDownload,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_open_outlined, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            tooltip: 'İndir / Aç',
            onPressed: onDownload,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationActionsCard() {
    return _buildSectionCard(
      title: 'İletişim Aksiyonları',
      child: Column(
        children: [
          _buildFullWidthButton(
            icon: Icons.mail_outline,
            label: 'Bilgi Maili Gönder',
            onPressed: () =>
                _showMessage('Bilgi maili gönderme akışı sonra bağlanacak.'),
          ),
          const SizedBox(height: 10),
          _buildFullWidthButton(
            icon: Icons.mark_email_read_outlined,
            label: 'Sipariş Teslim Maili Gönder',
            onPressed: () =>
                _showMessage('Teslim maili gönderme akışı sonra bağlanacak.'),
          ),
          const SizedBox(height: 10),
          _buildFullWidthButton(
            icon: Icons.rate_review_outlined,
            label: 'Memnuniyet Anketi Gönder',
            onPressed: () =>
                _showMessage('Memnuniyet anketi akışı sonra bağlanacak.'),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildDesignStepCard() {
    return _buildOperationCard(
      index: 1,
      title: 'Tasarım Hazırlığı',
      description:
          'Ölçüm verileri incelenir, gerekli girdi dosyaları indirilir ve ürün tasarım dosyaları yüklenir.',
      icon: Icons.design_services_outlined,
      completed: _designCompleted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionButton(
                icon: Icons.assignment_outlined,
                label: 'Tasarım Formunu Görüntüle',
                onPressed: _openDesignForm,
              ),
              _buildActionButton(
                icon: Icons.fact_check_outlined,
                label: 'Oturum Girdilerini İncele',
                onPressed: _openSessionInputs,
              ),
              _buildActionButton(
                icon: Icons.analytics_outlined,
                label: 'Analiz Raporunu Görüntüle',
                onPressed: _openAnalysisResults,
              ),
              _buildActionButton(
                icon: Icons.medical_information_outlined,
                label: 'Antropometrik Bilgileri Görüntüle',
                onPressed: _openClinicalInfo,
              ),
              _buildActionButton(
                icon: Icons.straighten_outlined,
                label: 'Referans İç Taban Analizi',
                onPressed: _openReferenceInsoleAnalysis,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildExpandableFileSection(
            title: 'Kullanılacak Ölçüm Dosyaları',
            subtitle:
                'Tasarım için gerekli 3D scan, plantar basınç ve referans iç taban fotoğrafı.',
            icon: Icons.folder_open_outlined,
            initiallyExpanded: false,
            child: Column(
              children: [
                _buildInputDownloadRow(
                  label: 'Sol ayak 3D scan STL',
                  onDownload: _downloadLeftScanFile,
                ),
                _buildInputDownloadRow(
                  label: 'Sağ ayak 3D scan STL',
                  onDownload: _downloadRightScanFile,
                ),
                _buildInputDownloadRow(
                  label: 'Basınç kayıtları',
                  onDownload: _downloadPressureRecordings,
                ),
                _buildInputDownloadRow(
                  label: 'Referans iç taban fotoğrafı',
                  onDownload: _downloadReferenceInsolePhoto,
                ),
              ],
            ),
          ),
          _buildExpandableFileSection(
            title: 'Yüklenecek Tasarım Çıktıları',
            subtitle:
                'Tasarım tamamlandıktan sonra sol ve sağ ürün STL dosyalarını buraya yükle.',
            icon: Icons.upload_file_outlined,
            initiallyExpanded: false,
            child: Column(
              children: [
                _buildUploadedFileRow(
                  label: 'Sol ürün tasarım STL',
                  fileName: _leftDesignStlName,
                  onUpload: () => _pickAndUploadOperationFile(
                    title: 'Sol ürün tasarım STL seç',
                    fileType: OrderOperationFileTypes.leftDesignStl,
                    onSelected: (name) => _leftDesignStlName = name,
                  ),
                  onDownload: () => _downloadOperationFile(
                    OrderOperationFileTypes.leftDesignStl,
                    'Sol ürün tasarım STL',
                  ),
                ),
                _buildUploadedFileRow(
                  label: 'Sağ ürün tasarım STL',
                  fileName: _rightDesignStlName,
                  onUpload: () => _pickAndUploadOperationFile(
                    title: 'Sağ ürün tasarım STL seç',
                    fileType: OrderOperationFileTypes.rightDesignStl,
                    onSelected: (name) => _rightDesignStlName = name,
                  ),
                  onDownload: () => _downloadOperationFile(
                    OrderOperationFileTypes.rightDesignStl,
                    'Sağ ürün tasarım STL',
                  ),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _designCompleted,
            onChanged: (v) async {
              setState(() => _designCompleted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Tasarım tamamlandı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildProductionStepCard() {
    return _buildOperationCard(
      index: 2,
      title: 'Üretim Hazırlığı ve Üretim',
      description:
          'Üretim için tasarım STL dosyaları referans alınır. CAM dosyası ve G-code dosyası tekil olarak yüklenir.',
      icon: Icons.precision_manufacturing_outlined,
      completed: _productionCompleted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpandableFileSection(
            title: 'Üretimde Kullanılacak Tasarım Dosyaları',
            subtitle:
                'Üretim dosyası hazırlanırken tasarım adımında yüklenen sol ve sağ STL dosyaları kullanılır.',
            icon: Icons.download_outlined,
            initiallyExpanded: false,
            child: Column(
              children: [
                _buildExistingFileDownloadRow(
                  label: 'Sol ürün tasarım STL',
                  fileName: _leftDesignStlName,
                  onDownload: () => _downloadOperationFile(
                    OrderOperationFileTypes.leftDesignStl,
                    'Sol ürün tasarım STL',
                  ),
                ),
                _buildExistingFileDownloadRow(
                  label: 'Sağ ürün tasarım STL',
                  fileName: _rightDesignStlName,
                  onDownload: () => _downloadOperationFile(
                    OrderOperationFileTypes.rightDesignStl,
                    'Sağ ürün tasarım STL',
                  ),
                ),
              ],
            ),
          ),
          _buildExpandableFileSection(
            title: 'Yüklenecek Üretim Dosyaları',
            subtitle:
                'CAM hazırlığı ve makineye gönderilecek G-code dosyası burada tutulur. Bu dosyalar sağ/sol ayrılmaz.',
            icon: Icons.upload_file_outlined,
            initiallyExpanded: false,
            child: Column(
              children: [
                _buildUploadedFileRow(
                  label: 'CAM dosyası',
                  fileName: _camFileName,
                  onUpload: () => _pickAndUploadOperationFile(
                    title: 'CAM dosyası seç',
                    fileType: _camFileType,
                    onSelected: (name) => _camFileName = name,
                  ),
                  onDownload: () => _downloadOperationFile(
                    _camFileType,
                    'CAM dosyası',
                  ),
                ),
                _buildUploadedFileRow(
                  label: 'G-code dosyası',
                  fileName: _gcodeFileName,
                  onUpload: () => _pickAndUploadOperationFile(
                    title: 'G-code dosyası seç',
                    fileType: _gcodeFileType,
                    onSelected: (name) => _gcodeFileName = name,
                  ),
                  onDownload: () => _downloadOperationFile(
                    _gcodeFileType,
                    'G-code dosyası',
                  ),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _productionStarted,
            onChanged: (v) async {
              setState(() => _productionStarted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Üretim başladı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _productionCompleted,
            onChanged: (v) async {
              setState(() => _productionCompleted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Üretim tamamlandı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityControlCard() {
    final completed = _qcDesignMatch &&
        _qcMeasurementDone &&
        _qcSurfaceChecked &&
        _qcReadyForDelivery;

    return _buildOperationCard(
      index: 3,
      title: 'Kalite Kontrol',
      description:
          'Ürünün tasarım, ölçü, yüzey ve teslimata uygunluk kontrolleri yapılır.',
      icon: Icons.fact_check_outlined,
      completed: completed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpandableFileSection(
            title: 'Kontrol Referansları',
            subtitle:
                'Kalite kontrol sırasında tasarım formu, analiz raporu, tasarım STL, CAM ve G-code dosyaları referans alınır.',
            icon: Icons.rule_folder_outlined,
            initiallyExpanded: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildActionButton(
                      icon: Icons.assignment_outlined,
                      label: 'Tasarım Formunu Görüntüle',
                      onPressed: _openDesignForm,
                    ),
                    _buildActionButton(
                      icon: Icons.analytics_outlined,
                      label: 'Analiz Raporunu Görüntüle',
                      onPressed: _openAnalysisResults,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildExistingFileDownloadRow(
                  label: 'Sol ürün tasarım STL',
                  fileName: _leftDesignStlName,
                  onDownload: () => _downloadOperationFile(
                    OrderOperationFileTypes.leftDesignStl,
                    'Sol ürün tasarım STL',
                  ),
                ),
                _buildExistingFileDownloadRow(
                  label: 'Sağ ürün tasarım STL',
                  fileName: _rightDesignStlName,
                  onDownload: () => _downloadOperationFile(
                    OrderOperationFileTypes.rightDesignStl,
                    'Sağ ürün tasarım STL',
                  ),
                ),
                _buildExistingFileDownloadRow(
                  label: 'CAM dosyası',
                  fileName: _camFileName,
                  onDownload: () => _downloadOperationFile(
                    _camFileType,
                    'CAM dosyası',
                  ),
                ),
                _buildExistingFileDownloadRow(
                  label: 'G-code dosyası',
                  fileName: _gcodeFileName,
                  onDownload: () => _downloadOperationFile(
                    _gcodeFileType,
                    'G-code dosyası',
                  ),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcDesignMatch,
            onChanged: (v) async {
              setState(() => _qcDesignMatch = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Ürün dosya/tasarım ile uyumlu'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcMeasurementDone,
            onChanged: (v) async {
              setState(() => _qcMeasurementDone = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Ölçü ve form kontrolü yapıldı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcSurfaceChecked,
            onChanged: (v) async {
              setState(() => _qcSurfaceChecked = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Yüzey / kenar kontrolü yapıldı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _qcReadyForDelivery,
            onChanged: (v) async {
              setState(() => _qcReadyForDelivery = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Ürün teslimata uygun'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _qualityNoteController,
            maxLines: 3,
            onEditingComplete: _persistOperationState,
            decoration: const InputDecoration(
              labelText: 'Kalite kontrol notu',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagingShippingCard() {
    final completed =
        _packagingCompleted && _shippingTrackingController.text.trim().isNotEmpty;

    return _buildOperationCard(
      index: 4,
      title: 'Paketleme ve Kargo',
      description:
          'Paketleme tamamlanır ve kargo takip bilgisi siparişe eklenir.',
      icon: Icons.local_shipping_outlined,
      completed: completed,
      child: Column(
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _packagingCompleted,
            onChanged: (v) async {
              setState(() => _packagingCompleted = v ?? false);
              await _persistOperationState();
            },
            title: const Text('Paketleme tamamlandı'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _shippingTrackingController,
            onChanged: (_) => setState(() {}),
            onEditingComplete: _persistOperationState,
            decoration: const InputDecoration(
              labelText: 'Kargo takip numarası',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildPackagingQrPanel(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: completed ? _persistOperationState : null,
              icon: const Icon(Icons.local_shipping),
              label: const Text('Kargoya Verildi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseOperationCard() {
    return _buildOperationCard(
      index: 5,
      title: 'Operasyonu Kapat',
      description:
          'Sipariş teslim ve operasyon kapanış kontrolleri tamamlandıktan sonra süreç kapatılır.',
      icon: Icons.check_circle_outline,
      completed: _orderClosed,
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _orderClosed,
        onChanged: (v) async {
          setState(() => _orderClosed = v ?? false);
          await _persistOperationState();
        },
        title: const Text('Operasyon kapatıldı'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOperation) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final statusColor = _statusColor(_currentOrderStatus);
    final priorityColor = _priorityColor(widget.operationItem.priorityLabel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operasyon Sipariş Detayı'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          if (_isSavingOperation) const LinearProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
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
                            BoxShadow(color: Colors.black12, blurRadius: 8),
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
                                    '${_productLabel(order.productType)} • ${widget.operationItem.patientName}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${widget.operationItem.clinicName} • ${widget.operationItem.expertName}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
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
                                    _statusLabel(_currentOrderStatus),
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
                                _buildPrimaryInfoCard(),
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
                                        _formatDate(_currentShippedAt),
                                      ),
                                      _buildKeyValueRow(
                                        'Teslim Tarihi',
                                        _formatDate(_currentDeliveredAt),
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
                                const SizedBox(height: 16),
                                _buildCommunicationActionsCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _buildSectionCard(
                              title: 'Üretim Operasyon Akışı',
                              child: Column(
                                children: [
                                  _buildDesignStepCard(),
                                  _buildProductionStepCard(),
                                  _buildQualityControlCard(),
                                  _buildPackagingShippingCard(),
                                  _buildCloseOperationCard(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

class _StorageRecord {
  final int? id;
  final String fileType;
  final String fileName;
  final String? storageBucket;
  final String? storagePath;
  final String? publicUrl;
  final DateTime? createdAt;
  final String? subtitleExtra;

  const _StorageRecord({
    required this.id,
    required this.fileType,
    required this.fileName,
    required this.storageBucket,
    required this.storagePath,
    required this.publicUrl,
    required this.createdAt,
    this.subtitleExtra,
  });

  String get displayName {
    if (fileName.trim().isNotEmpty) return fileName;
    if (fileType.trim().isNotEmpty) return fileType;
    return 'Dosya #${id ?? '—'}';
  }

  String get subtitle {
    final parts = <String>[
      if (fileType.trim().isNotEmpty) fileType,
      if (createdAt != null)
        '${createdAt!.day.toString().padLeft(2, '0')}.'
            '${createdAt!.month.toString().padLeft(2, '0')}.'
            '${createdAt!.year}',
      if (subtitleExtra != null && subtitleExtra!.trim().isNotEmpty)
        subtitleExtra!,
    ];

    return parts.isEmpty ? 'Storage dosyası' : parts.join(' • ');
  }
}
