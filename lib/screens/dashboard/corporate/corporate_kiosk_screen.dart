import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_corporate_scan_session_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/lsf350_scan_result.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/services/scan/lsf350_scan_output_parser.dart';
import 'package:oy_site/services/scanner/oy_scanner_automation_service.dart';
import 'package:oy_site/services/window/kiosk_window_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _KioskStep { select, ready, scanning, completed }

class CorporateKioskScreen extends StatefulWidget {
  final AppUser currentUser;
  final VoidCallback? onExit;
  final OYScannerAutomationService? automationService;
  final SupabaseCorporateScanSessionRepository? scanSessionRepository;

  const CorporateKioskScreen({
    super.key,
    required this.currentUser,
    this.onExit,
    this.automationService,
    this.scanSessionRepository,
  });

  @override
  State<CorporateKioskScreen> createState() => _CorporateKioskScreenState();
}

class _CorporateKioskScreenState extends State<CorporateKioskScreen> {
  static const Duration _progressDuration = Duration(seconds: 40);

  late final OYScannerAutomationService _automationService;
  late final SupabaseCorporateScanSessionRepository _scanSessionRepository;
  late final KioskWindowController _kioskWindowController;
  final Lsf350ScanOutputParser _scanOutputParser =
      const Lsf350ScanOutputParser();
  final TextEditingController _searchController = TextEditingController();

  Timer? _progressTimer;
  bool _isLoading = true;
  bool _isRunning = false;
  double _progressValue = 0;
  String? _errorMessage;
  String _statusText = 'Hazır';
  _KioskStep _step = _KioskStep.select;
  List<Patient> _patients = [];
  Set<String> _completedCodes = {};
  Patient? _selectedPatient;
  Patient? _lastCompletedPatient;
  Lsf350ScanResult? _lastScanResult;
  List<OYScannerGeneratedFile> _lastGeneratedFiles = const [];

  @override
  void initState() {
    super.initState();
    _automationService =
        widget.automationService ?? createOYScannerAutomationService();
    _scanSessionRepository =
        widget.scanSessionRepository ??
        const SupabaseCorporateScanSessionRepository();
    _kioskWindowController = createKioskWindowController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_enterKioskWindowMode());
    });
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _enterKioskWindowMode() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await _kioskWindowController.enterFullscreen();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    unawaited(_kioskWindowController.exitFullscreen());
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.currentUser.userId;
      final patients = userId == null
          ? <Patient>[]
          : await const SupabasePatientRepository().getPatientsByExpert(
              expertUserId: userId,
            );
      await _cachePatients(patients);
      final completed = await _loadCompletedCodes();
      await _mergeRemoteCompletedCodes(patients, completed);
      await _syncLocalCompletedCodesToRemote(patients, completed);
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _completedCodes = completed;
        _isLoading = false;
      });
    } catch (error) {
      final cachedPatients = await _loadCachedPatients();
      final completed = await _loadCompletedCodes();
      if (!mounted) return;
      setState(() {
        _patients = cachedPatients;
        _completedCodes = completed;
        _errorMessage = cachedPatients.isEmpty
            ? 'Çalışan listesi yüklenemedi. İnternet bağlantısını kontrol edin.'
            : 'Çalışan listesi güncellenemedi. Son kaydedilen liste gösteriliyor.';
        _isLoading = false;
      });
    }
  }

  Future<void> _mergeRemoteCompletedCodes(
    List<Patient> patients,
    Set<String> completed,
  ) async {
    final userId = widget.currentUser.userId;
    if (userId == null) return;

    try {
      final completedIds = await _scanSessionRepository.getCompletedPatientIds(
        corporateUserId: userId,
      );
      for (final patient in patients) {
        final patientId = patient.patientId;
        if (patientId != null && completedIds.contains(patientId)) {
          completed.add(patient.patientCode);
        }
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(
        _completedKey,
        completed.toList()..sort(),
      );
    } catch (_) {
      // Migration henüz uygulanmadıysa kiosk lokal tamamlanma kaydıyla çalışmaya devam eder.
    }
  }

  Future<void> _syncLocalCompletedCodesToRemote(
    List<Patient> patients,
    Set<String> completed,
  ) async {
    for (final patient in patients) {
      if (!completed.contains(patient.patientCode)) continue;
      await _upsertRemoteStatus(
        patient,
        status: 'completed',
        completedAt: DateTime.now(),
      );
    }
  }

  List<Patient> get _filteredPatients {
    final query = _searchController.text.trim().toLowerCase();
    final waitingPatients = _patients
        .where((patient) => !_completedCodes.contains(patient.patientCode))
        .toList();
    if (query.isEmpty) return waitingPatients.take(12).toList();
    return waitingPatients.where((patient) {
      return patient.fullName.toLowerCase().contains(query) ||
          patient.patientCode.toLowerCase().contains(query) ||
          (patient.phone ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void _selectPatient(Patient patient) {
    setState(() => _selectedPatient = patient);
  }

  void _goToReadyStep() {
    if (_selectedPatient == null) return;
    setState(() => _step = _KioskStep.ready);
  }

  void _goBackToSelect() {
    if (_isRunning) return;
    setState(() => _step = _KioskStep.select);
  }

  void _resetForNextEmployee() {
    setState(() {
      _step = _KioskStep.select;
      _selectedPatient = null;
      _lastCompletedPatient = null;
      _lastScanResult = null;
      _lastGeneratedFiles = const [];
      _progressValue = 0;
      _statusText = 'Hazır';
      _searchController.clear();
    });
  }

  Future<void> _startSelectedScan() async {
    final patient = _selectedPatient;
    if (patient == null || _isRunning) return;

    final startedAt = DateTime.now().subtract(const Duration(seconds: 2));
    final scanStartedAt = DateTime.now();
    setState(() {
      _step = _KioskStep.scanning;
      _isRunning = true;
      _progressValue = 0;
      _statusText = 'Tarama başlatılıyor';
    });
    _startProgressAnimation();
    await _upsertRemoteStatus(
      patient,
      status: 'scanning',
      startedAt: scanStartedAt,
    );

    try {
      await _runCommand('Ekranı hazırla', const ['--silent', '--wake']);
      await Future<void>.delayed(const Duration(seconds: 1));
      await _runCommand('Taramayı başlat', [
        '--silent',
        '--start-scan',
        '--gender',
        _genderFor(patient),
      ]);
      await _wait('Tarama alınıyor', const Duration(seconds: 30));
      final exportResult = await _completeFormAndExportUntilDone(
        patient,
        startedAt,
      );
      await _returnEFootHome();
      await _markCompleted(patient);
      await _upsertRemoteStatus(
        patient,
        status: 'completed',
        startedAt: scanStartedAt,
        completedAt: DateTime.now(),
        localOutputPath: exportResult.scanResult?.folderPath,
      );

      if (!mounted) return;
      _progressTimer?.cancel();
      setState(() {
        _progressValue = 1;
        _statusText = 'Tarama tamamlandı';
        _isRunning = false;
        _lastCompletedPatient = patient;
        _lastScanResult = exportResult.scanResult;
        _lastGeneratedFiles = exportResult.files;
        _step = _KioskStep.completed;
      });
    } catch (error) {
      await _upsertRemoteStatus(
        patient,
        status: 'failed',
        startedAt: scanStartedAt,
        errorMessage: error.toString(),
      );
      if (!mounted) return;
      _progressTimer?.cancel();
      setState(() {
        _statusText = 'Tarama tamamlanamadı';
        _isRunning = false;
        _step = _KioskStep.ready;
      });
      _showMessage('Tarama tamamlanamadı: $error');
    }
  }

  void _startProgressAnimation() {
    _progressTimer?.cancel();
    final startedAt = DateTime.now();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(startedAt);
      final value = elapsed.inMilliseconds / _progressDuration.inMilliseconds;
      setState(() => _progressValue = value.clamp(0, 0.98).toDouble());
    });
  }

  Future<void> _runCommand(String label, List<String> arguments) async {
    final result = await _automationService.runCommand(label, arguments);
    if (!result.success) {
      throw result.errorMessage ?? result.summary;
    }
  }

  Future<void> _wait(String label, Duration duration) async {
    for (var remaining = duration.inSeconds; remaining > 0; remaining--) {
      if (!mounted) return;
      setState(() => _statusText = '$label: ${remaining}s');
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Future<_KioskExportResult> _completeFormAndExportUntilDone(
    Patient patient,
    DateTime startedAt,
  ) async {
    for (var attempt = 1; attempt <= 3; attempt++) {
      if (mounted) {
        setState(() => _statusText = 'Form hazırlanıyor ($attempt/3)');
      }

      await _runCommand('Formu doldur', [
        '--silent',
        '--fill-form',
        '--name',
        patient.fullName,
        '--tel',
        _safeText(patient.phone, fallback: '5550000000'),
        '--age',
        _ageFor(patient).toString(),
        '--height',
        '175',
        '--weight',
        '70',
        '--shoe-size',
        _shoeSizeFor(patient).toString(),
        '--next',
      ]);

      await _wait('Rapor hazırlanıyor', const Duration(seconds: 18));
      final exportResult = await _exportUntilDone(startedAt, attempts: 5);
      if (exportResult.files.isNotEmpty) return exportResult;

      if (attempt < 3) {
        await _wait(
          'Rapor bulunamadı, form adımı tekrar deneniyor',
          const Duration(seconds: 8),
        );
      }
    }

    throw Exception(
      'Rapor dosyaları üretilemedi. eFoot form ekranı hazır olmadan işlem yapılmış olabilir.',
    );
  }

  Future<void> _returnEFootHome() async {
    if (mounted) setState(() => _statusText = 'Başlangıç ekranı hazırlanıyor');
    await _runCommand('Başlangıca dön', const ['--silent', '--home']);
    await Future<void>.delayed(const Duration(milliseconds: 900));
  }

  Future<_KioskExportResult> _exportUntilDone(
    DateTime startedAt, {
    int attempts = 12,
  }) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (mounted) setState(() => _statusText = 'Dosyalar kaydediliyor');
      await _runCommand('Export', const ['--silent', '--export']);
      await Future<void>.delayed(const Duration(seconds: 4));
      final files = await _automationService.listGeneratedFiles(
        since: startedAt,
      );
      if (files.isNotEmpty) return _buildExportResult(files);
    }

    final files = await _automationService.listGeneratedFiles(since: startedAt);
    return _buildExportResult(files);
  }

  _KioskExportResult _buildExportResult(List<OYScannerGeneratedFile> files) {
    if (files.isEmpty) {
      return const _KioskExportResult(files: []);
    }

    final folderPath = File(files.first.path).parent.path;
    final scanResult = _scanOutputParser.parseFolder(folderPath);
    return _KioskExportResult(files: files, scanResult: scanResult);
  }

  Future<void> _markCompleted(Patient patient) async {
    final codes = await _loadCompletedCodes();
    codes.add(patient.patientCode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_completedKey, codes.toList()..sort());
    if (!mounted) return;
    setState(() => _completedCodes = codes);
  }

  Future<void> _upsertRemoteStatus(
    Patient patient, {
    required String status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? localOutputPath,
  }) async {
    final corporateUserId = widget.currentUser.userId;
    final patientId = patient.patientId;
    if (corporateUserId == null || patientId == null) return;

    try {
      await _scanSessionRepository.upsertSession(
        corporateUserId: corporateUserId,
        patientId: patientId,
        patientCode: patient.patientCode,
        status: status,
        startedAt: startedAt,
        completedAt: completedAt,
        errorMessage: errorMessage,
        localOutputPath: localOutputPath,
      );
    } catch (_) {
      // Çevrimdışı kullanımda veya migration henüz yokken kullanıcı akışı durmasın.
    }
  }

  Future<Set<String>> _loadCompletedCodes() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_completedKey) ?? const <String>[])
        .toSet();
  }

  Future<void> _cachePatients(List<Patient> patients) async {
    final preferences = await SharedPreferences.getInstance();
    final rows = patients.map((patient) => patient.toMap()).toList();
    await preferences.setString(_patientCacheKey, jsonEncode(rows));
  }

  Future<List<Patient>> _loadCachedPatients() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_patientCacheKey);
    if (rawValue == null || rawValue.trim().isEmpty) return const [];
    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => Patient.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  String get _patientCacheKey =>
      'corporate_kiosk_patients_v1_user_${widget.currentUser.userId ?? 'guest'}';

  String get _completedKey =>
      'corporate_kiosk_completed_v1_user_${widget.currentUser.userId ?? 'guest'}';

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static String _genderFor(Patient patient) {
    return (patient.gender ?? '').toLowerCase() == 'female' ? 'female' : 'male';
  }

  static int _ageFor(Patient patient) {
    final birthDate = patient.birthDate;
    if (birthDate == null) return 30;
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    if (age < 1 || age > 120) return 30;
    return age;
  }

  static int _shoeSizeFor(Patient patient) {
    final notes = patient.notes ?? '';
    for (final line in notes.split('\n')) {
      final separator = line.indexOf(':');
      if (separator < 0) continue;
      final key = line.substring(0, separator).trim().toLowerCase();
      if (key != 'ayakkabı numarası' && key != 'shoe size') continue;
      final value = int.tryParse(line.substring(separator + 1).trim());
      if (value != null && value >= 20 && value <= 55) return value;
    }
    return 42;
  }

  static String _safeText(String? value, {required String fallback}) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPatients = _filteredPatients;
    final completedCount = _completedCodes.length;
    final totalCount = _patients.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KioskHeader(
                statusText: _statusText,
                completedCount: completedCount,
                totalCount: totalCount,
                isRunning: _isRunning,
                onRefresh: _isRunning ? null : _load,
                onExit: _isRunning ? null : widget.onExit,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                _Notice(message: _errorMessage!),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 360),
                        transitionBuilder: (child, animation) {
                          final offset =
                              Tween<Offset>(
                                begin: const Offset(0.08, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offset,
                              child: child,
                            ),
                          );
                        },
                        child: _buildStep(
                          filteredPatients: filteredPatients,
                          completedCount: completedCount,
                          totalCount: totalCount,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required List<Patient> filteredPatients,
    required int completedCount,
    required int totalCount,
  }) {
    switch (_step) {
      case _KioskStep.select:
        return _SelectStep(
          key: const ValueKey('select'),
          searchController: _searchController,
          patients: filteredPatients,
          selectedPatient: _selectedPatient,
          onSelected: _selectPatient,
          onContinue: _selectedPatient == null ? null : _goToReadyStep,
        );
      case _KioskStep.ready:
        return _ReadyStep(
          key: const ValueKey('ready'),
          patient: _selectedPatient,
          onBack: _goBackToSelect,
          onStart: _selectedPatient == null || _isRunning
              ? null
              : _startSelectedScan,
        );
      case _KioskStep.scanning:
        return _ScanningStep(
          key: const ValueKey('scanning'),
          patient: _selectedPatient,
          progressValue: _progressValue,
          statusText: _statusText,
        );
      case _KioskStep.completed:
        return _CompletedStep(
          key: const ValueKey('completed'),
          patient: _lastCompletedPatient,
          completedCount: completedCount,
          totalCount: totalCount,
          scanResult: _lastScanResult,
          files: _lastGeneratedFiles,
          onNext: _resetForNextEmployee,
        );
    }
  }
}

class _KioskExportResult {
  final List<OYScannerGeneratedFile> files;
  final Lsf350ScanResult? scanResult;

  const _KioskExportResult({required this.files, this.scanResult});
}

class _KioskHeader extends StatelessWidget {
  final String statusText;
  final int completedCount;
  final int totalCount;
  final bool isRunning;
  final VoidCallback? onRefresh;
  final VoidCallback? onExit;

  const _KioskHeader({
    required this.statusText,
    required this.completedCount,
    required this.totalCount,
    required this.isRunning,
    required this.onRefresh,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: Color(0xFF087F73),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OY Kurumsal Tarama Kiosku',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount/$totalCount tamamlandı • $statusText',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Listeyi yenile',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Kiosktan çık',
            onPressed: onExit,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _SelectStep extends StatelessWidget {
  final TextEditingController searchController;
  final List<Patient> patients;
  final Patient? selectedPatient;
  final ValueChanged<Patient> onSelected;
  final VoidCallback? onContinue;

  const _SelectStep({
    super.key,
    required this.searchController,
    required this.patients,
    required this.selectedPatient,
    required this.onSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '1. Kendinizi seçin',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adınızı veya çalışan kodunuzu yazarak listeden kendinizi bulun.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 22),
                  decoration: InputDecoration(
                    hintText: 'Adınızı veya çalışan kodunuzu yazın',
                    prefixIcon: const Icon(Icons.search, size: 30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: patients.isEmpty
                      ? Center(
                          child: Text(
                            'Bekleyen çalışan bulunamadı.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        )
                      : ListView.separated(
                          itemCount: patients.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final patient = patients[index];
                            final selected =
                                patient.patientCode ==
                                selectedPatient?.patientCode;
                            return _PatientChoiceTile(
                              patient: patient,
                              selected: selected,
                              onTap: () => onSelected(patient),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: _Surface(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  selectedPatient == null
                      ? Icons.person_search_outlined
                      : Icons.check_circle_outline,
                  size: 62,
                  color: const Color(0xFF087F73),
                ),
                const SizedBox(height: 18),
                Text(
                  selectedPatient == null
                      ? 'Listeden kendinizi seçin.'
                      : selectedPatient!.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedPatient == null
                      ? 'Sonraki adımda bilgilerinizi onaylayıp taramayı başlatacaksınız.'
                      : 'Çalışan kodu: ${selectedPatient!.patientCode}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Devam Et', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadyStep extends StatelessWidget {
  final Patient? patient;
  final VoidCallback onBack;
  final VoidCallback? onStart;

  const _ReadyStep({
    super.key,
    required this.patient,
    required this.onBack,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 74,
            color: Color(0xFF087F73),
          ),
          const SizedBox(height: 22),
          const Text(
            '2. Taramaya hazırlanın',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            patient == null
                ? ''
                : '${patient!.fullName} • ${patient!.patientCode}',
            style: TextStyle(color: Colors.grey[700], fontSize: 18),
          ),
          const SizedBox(height: 22),
          const Text(
            'Tarayıcının üzerinde sabit durun. Hazır olduğunuzda taramayı başlatın. İşlem boyunca ekrandaki ilerlemeyi takip edebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Geri'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text(
                    'Taramayı Başlat',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanningStep extends StatelessWidget {
  final Patient? patient;
  final double progressValue;
  final String statusText;

  const _ScanningStep({
    super.key,
    required this.patient,
    required this.progressValue,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progressValue * 100).round().clamp(0, 100);

    return _Surface(
      key: key,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.document_scanner_outlined,
            size: 74,
            color: Color(0xFF087F73),
          ),
          const SizedBox(height: 22),
          const Text(
            '3. Tarama devam ediyor',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            patient == null ? '' : patient!.fullName,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 18),
          ),
          const SizedBox(height: 30),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 18,
              color: const Color(0xFF087F73),
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '%$percent • $statusText',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Text(
            'Lütfen tarama tamamlanana kadar cihaz üzerinde sabit durun.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _CompletedStep extends StatelessWidget {
  final Patient? patient;
  final int completedCount;
  final int totalCount;
  final Lsf350ScanResult? scanResult;
  final List<OYScannerGeneratedFile> files;
  final VoidCallback onNext;

  const _CompletedStep({
    super.key,
    required this.patient,
    required this.completedCount,
    required this.totalCount,
    required this.scanResult,
    required this.files,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      key: key,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 58,
                color: Color(0xFF087F73),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '4. Tarama tamamlandı',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      patient == null
                          ? 'İşlem tamamlandı.'
                          : '${patient!.fullName}, inebilirsiniz.',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onNext,
                icon: const Icon(Icons.person_search_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  child: Text(
                    'Sıradaki Çalışan',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$completedCount/$totalCount çalışan tamamlandı.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 22),
          _ScanResultSummary(scanResult: scanResult, files: files),
          const SizedBox(height: 14),
          _StlModelPreviewPanel(scanResult: scanResult),
        ],
      ),
    );
  }
}

class _ScanResultSummary extends StatelessWidget {
  final Lsf350ScanResult? scanResult;
  final List<OYScannerGeneratedFile> files;

  const _ScanResultSummary({required this.scanResult, required this.files});

  @override
  Widget build(BuildContext context) {
    final result = scanResult;
    final items = <_ResultMetric>[
      _ResultMetric(
        icon: Icons.picture_as_pdf_outlined,
        label: 'Rapor',
        value: result?.hasReport == true ? 'Hazır' : 'Bekleniyor',
        active: result?.hasReport == true,
      ),
      _ResultMetric(
        icon: Icons.image_outlined,
        label: 'Görsel',
        value: '${result?.previewImagePaths.length ?? 0}',
        active: result?.hasPreviewImages == true,
      ),
      _ResultMetric(
        icon: Icons.view_in_ar_outlined,
        label: '3D Model',
        value: '${result?.stlFilePaths.length ?? 0}',
        active: result?.hasStlModels == true,
      ),
      _ResultMetric(
        icon: Icons.folder_zip_outlined,
        label: 'Arşiv',
        value: '${result?.stlArchivePaths.length ?? 0}',
        active: result?.hasModelArchives == true,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tarama çıktısı',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                files.isEmpty ? 'Dosya bulunamadı' : '${files.length} dosya',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          if (result?.folderPath != null) ...[
            const SizedBox(height: 4),
            Text(
              result!.folderPath,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) => _ResultMetricTile(item)).toList(),
          ),
        ],
      ),
    );
  }
}

class _StlModelPreviewPanel extends StatelessWidget {
  final Lsf350ScanResult? scanResult;

  const _StlModelPreviewPanel({required this.scanResult});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_StlPreviewMesh>>(
      future: _loadStlPreviewMeshes(scanResult),
      builder: (context, snapshot) {
        final meshes = snapshot.data ?? const <_StlPreviewMesh>[];
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '3D ayak modeli',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (meshes.isEmpty)
                SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'STL modeli bulunamadı.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                Row(
                  children: meshes.take(2).map((mesh) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: mesh == meshes.take(2).last ? 0 : 12,
                        ),
                        child: _InteractiveStlPreview(mesh: mesh),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InteractiveStlPreview extends StatefulWidget {
  final _StlPreviewMesh mesh;

  const _InteractiveStlPreview({required this.mesh});

  @override
  State<_InteractiveStlPreview> createState() => _InteractiveStlPreviewState();
}

class _InteractiveStlPreviewState extends State<_InteractiveStlPreview> {
  double _yaw = -0.35;
  double _pitch = -0.7;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _yaw += details.delta.dx * 0.012;
          _pitch = (_pitch + details.delta.dy * 0.012).clamp(-1.35, 1.15);
        });
      },
      onDoubleTap: () {
        setState(() {
          _yaw = -0.35;
          _pitch = -0.7;
        });
      },
      child: Container(
        height: 520,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _StlMeshPainter(
                  mesh: widget.mesh,
                  yaw: _yaw,
                  pitch: _pitch,
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  child: Text(
                    widget.mesh.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  child: Text(
                    'Sürükleyerek döndür',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StlMeshPainter extends CustomPainter {
  final _StlPreviewMesh mesh;
  final double yaw;
  final double pitch;

  const _StlMeshPainter({
    required this.mesh,
    required this.yaw,
    required this.pitch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (mesh.triangles.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.82;
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosX = math.cos(pitch);
    final sinX = math.sin(pitch);

    _Point3 rotate(_Point3 p) {
      var x = p.x - mesh.center.x;
      var y = p.y - mesh.center.y;
      var z = p.z - mesh.center.z;

      final rx = x * cosY + z * sinY;
      final rz = -x * sinY + z * cosY;
      final ry = y * cosX - rz * sinX;
      final depth = y * sinX + rz * cosX;
      return _Point3(rx, ry, depth);
    }

    Offset project(_Point3 p) {
      final rotated = rotate(p);
      final perspective = 1.15 / (1.15 + rotated.z * 0.55);

      return Offset(
        center.dx + rotated.x * scale * perspective,
        center.dy - rotated.y * scale * perspective,
      );
    }

    final projected = <_ProjectedTriangle>[];
    for (final triangle in mesh.triangles) {
      final ra = rotate(triangle.a);
      final rb = rotate(triangle.b);
      final rc = rotate(triangle.c);
      final a = project(triangle.a);
      final b = project(triangle.b);
      final c = project(triangle.c);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();

      final normal = _normalOf(ra, rb, rc);
      final light = (normal.x * -0.25 + normal.y * -0.45 + normal.z * 0.85)
          .clamp(-1.0, 1.0);
      final shade = (0.42 + light.abs() * 0.44).clamp(0.0, 1.0);
      projected.add(
        _ProjectedTriangle(
          path: path,
          depth: (ra.z + rb.z + rc.z) / 3,
          shade: shade,
        ),
      );
    }

    projected.sort((a, b) => b.depth.compareTo(a.depth));

    final strokePaint = Paint()
      ..color = const Color(0x66065F57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35;

    for (final triangle in projected) {
      final fillColor = Color.lerp(
        const Color(0xFFE7F7F4),
        const Color(0xFF087F73),
        triangle.shade,
      )!;
      final fillPaint = Paint()
        ..color = fillColor.withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;
      canvas.drawPath(triangle.path, fillPaint);
      canvas.drawPath(triangle.path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StlMeshPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.mesh != mesh;
  }
}

_Point3 _normalOf(_Point3 a, _Point3 b, _Point3 c) {
  final ux = b.x - a.x;
  final uy = b.y - a.y;
  final uz = b.z - a.z;
  final vx = c.x - a.x;
  final vy = c.y - a.y;
  final vz = c.z - a.z;

  final nx = uy * vz - uz * vy;
  final ny = uz * vx - ux * vz;
  final nz = ux * vy - uy * vx;
  final length = math.sqrt(nx * nx + ny * ny + nz * nz);
  if (length == 0) return const _Point3(0, 0, 1);
  return _Point3(nx / length, ny / length, nz / length);
}

class _ProjectedTriangle {
  final Path path;
  final double depth;
  final double shade;

  const _ProjectedTriangle({
    required this.path,
    required this.depth,
    required this.shade,
  });
}

Future<List<_StlPreviewMesh>> _loadStlPreviewMeshes(
  Lsf350ScanResult? result,
) async {
  if (result == null) return const [];

  final meshes = <_StlPreviewMesh>[];

  for (final path in result.stlFilePaths) {
    final mesh = await _readStlMesh(path, label: _labelForStl(path));
    if (mesh != null) meshes.add(mesh);
  }

  for (final archivePath in result.stlArchivePaths) {
    final archiveFile = File(archivePath);
    if (!archiveFile.existsSync()) continue;
    try {
      final archive = ZipDecoder().decodeBytes(await archiveFile.readAsBytes());
      for (final file in archive.files) {
        if (!file.isFile || !file.name.toLowerCase().endsWith('.stl')) {
          continue;
        }
        final content = file.content;
        final mesh = _parseStlBytes(
          Uint8List.fromList(content),
          label: _labelForStl(file.name),
        );
        if (mesh != null) meshes.add(mesh);
      }
    } catch (_) {
      continue;
    }
  }

  final unique = <String, _StlPreviewMesh>{};
  for (final mesh in meshes) {
    unique.putIfAbsent(mesh.label, () => mesh);
  }
  return unique.values.toList();
}

Future<_StlPreviewMesh?> _readStlMesh(
  String path, {
  required String label,
}) async {
  final file = File(path);
  if (!file.existsSync()) return null;
  try {
    return _parseStlBytes(await file.readAsBytes(), label: label);
  } catch (_) {
    return null;
  }
}

_StlPreviewMesh? _parseStlBytes(Uint8List bytes, {required String label}) {
  if (bytes.length < 84) return _parseAsciiStl(bytes, label: label);

  final data = ByteData.sublistView(bytes);
  final triangleCount = data.getUint32(80, Endian.little);
  final expectedLength = 84 + triangleCount * 50;
  if (triangleCount > 0 && expectedLength <= bytes.length) {
    final triangles = <_Triangle3>[];
    final step = math.max(1, (triangleCount / 4200).ceil());
    for (var i = 0; i < triangleCount; i += step) {
      final offset = 84 + i * 50 + 12;
      if (offset + 36 > bytes.length) break;
      triangles.add(
        _Triangle3(
          _pointFromStl(data, offset),
          _pointFromStl(data, offset + 12),
          _pointFromStl(data, offset + 24),
        ),
      );
    }
    return _StlPreviewMesh.normalized(label: label, triangles: triangles);
  }

  return _parseAsciiStl(bytes, label: label);
}

_StlPreviewMesh? _parseAsciiStl(Uint8List bytes, {required String label}) {
  final text = utf8.decode(bytes, allowMalformed: true);
  final matches = RegExp(
    r'vertex\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)\s+([-+0-9.eE]+)',
  ).allMatches(text).toList();
  if (matches.length < 3) return null;

  final triangles = <_Triangle3>[];
  final vertexStep = math.max(3, ((matches.length / 3) / 4200).ceil() * 3);
  for (var i = 0; i + 2 < matches.length; i += vertexStep) {
    triangles.add(
      _Triangle3(
        _pointFromMatch(matches[i]),
        _pointFromMatch(matches[i + 1]),
        _pointFromMatch(matches[i + 2]),
      ),
    );
  }
  return _StlPreviewMesh.normalized(label: label, triangles: triangles);
}

_Point3 _pointFromStl(ByteData data, int offset) {
  return _Point3(
    data.getFloat32(offset, Endian.little),
    data.getFloat32(offset + 4, Endian.little),
    data.getFloat32(offset + 8, Endian.little),
  );
}

_Point3 _pointFromMatch(RegExpMatch match) {
  return _Point3(
    double.tryParse(match.group(1) ?? '') ?? 0,
    double.tryParse(match.group(2) ?? '') ?? 0,
    double.tryParse(match.group(3) ?? '') ?? 0,
  );
}

String _labelForStl(String path) {
  final lower = path.toLowerCase();
  if (lower.contains('left') || lower.contains('sol')) return 'Sol ayak';
  if (lower.contains('right') ||
      lower.contains('sag') ||
      lower.contains('sağ')) {
    return 'Sağ ayak';
  }
  return path.split(RegExp(r'[\\/]')).last;
}

class _StlPreviewMesh {
  final String label;
  final List<_Triangle3> triangles;
  final _Point3 center;

  const _StlPreviewMesh({
    required this.label,
    required this.triangles,
    required this.center,
  });

  factory _StlPreviewMesh.normalized({
    required String label,
    required List<_Triangle3> triangles,
  }) {
    if (triangles.isEmpty) {
      return _StlPreviewMesh(
        label: label,
        triangles: const [],
        center: const _Point3(0, 0, 0),
      );
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var minZ = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    var maxZ = -double.infinity;

    for (final triangle in triangles) {
      for (final point in [triangle.a, triangle.b, triangle.c]) {
        minX = math.min(minX, point.x);
        minY = math.min(minY, point.y);
        minZ = math.min(minZ, point.z);
        maxX = math.max(maxX, point.x);
        maxY = math.max(maxY, point.y);
        maxZ = math.max(maxZ, point.z);
      }
    }

    final center = _Point3(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
      (minZ + maxZ) / 2,
    );
    final maxDimension = [
      maxX - minX,
      maxY - minY,
      maxZ - minZ,
    ].reduce(math.max);
    final scale = maxDimension <= 0 ? 1.0 : 1 / maxDimension;

    return _StlPreviewMesh(
      label: label,
      center: const _Point3(0, 0, 0),
      triangles: triangles.map((triangle) {
        _Point3 normalize(_Point3 point) {
          return _Point3(
            (point.x - center.x) * scale,
            (point.y - center.y) * scale,
            (point.z - center.z) * scale,
          );
        }

        return _Triangle3(
          normalize(triangle.a),
          normalize(triangle.b),
          normalize(triangle.c),
        );
      }).toList(),
    );
  }
}

class _Triangle3 {
  final _Point3 a;
  final _Point3 b;
  final _Point3 c;

  const _Triangle3(this.a, this.b, this.c);
}

class _Point3 {
  final double x;
  final double y;
  final double z;

  const _Point3(this.x, this.y, this.z);
}

class _ResultMetric {
  final IconData icon;
  final String label;
  final String value;
  final bool active;

  const _ResultMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
  });
}

class _ResultMetricTile extends StatelessWidget {
  final _ResultMetric item;

  const _ResultMetricTile(this.item);

  @override
  Widget build(BuildContext context) {
    final color = item.active ? const Color(0xFF087F73) : Colors.grey[600]!;
    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.active ? const Color(0xFFE7F7F4) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.active
              ? const Color(0xFFB7E6DE)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                Text(
                  item.value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientChoiceTile extends StatelessWidget {
  final Patient patient;
  final bool selected;
  final VoidCallback? onTap;

  const _PatientChoiceTile({
    required this.patient,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE7F7F4) : const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.person_outline,
                color: const Color(0xFF087F73),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(patient.patientCode),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final String message;

  const _Notice({required this.message});

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Text(message, style: const TextStyle(color: Color(0xFFB3261E))),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}
