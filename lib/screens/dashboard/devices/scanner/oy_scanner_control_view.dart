import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/services/scanner/oy_scanner_automation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef OYScannerPatientLoader = Future<List<Patient>> Function();

class OYScannerControlView extends StatefulWidget {
  final AppUser? currentUser;
  final OYScannerAutomationService? automationService;
  final OYScannerPatientLoader? patientLoader;

  const OYScannerControlView({
    super.key,
    this.currentUser,
    this.automationService,
    this.patientLoader,
  });

  @override
  State<OYScannerControlView> createState() => _OYScannerControlViewState();
}

class _OYScannerControlViewState extends State<OYScannerControlView> {
  late final OYScannerAutomationService _automationService;
  final _searchController = TextEditingController();

  bool _silentMode = true;
  bool _isSupported = false;
  bool _isLoadingPatients = true;
  bool _isWorkflowRunning = false;
  String? _patientError;
  String _workflowStatus = 'Hazır';
  List<Patient> _patients = [];
  List<Patient> _filteredPatients = [];
  Patient? _selectedPatient;
  List<String> _messages = [];
  List<OYScannerGeneratedFile> _generatedFiles = [];

  @override
  void initState() {
    super.initState();
    _automationService =
        widget.automationService ?? createOYScannerAutomationService();
    _searchController.addListener(_filterPatients);
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final supported = await _automationService.isSupported();
    if (!mounted) return;
    setState(() => _isSupported = supported);
    await _loadPatients();
    await _refreshGeneratedFiles();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoadingPatients = true;
      _patientError = null;
    });

    try {
      final loader = widget.patientLoader;
      final patients = loader != null
          ? await loader()
          : await _loadPatientsFromRepositoryAndCache();
      if (!mounted) return;
      setState(() {
        _setPatients(patients);
        _isLoadingPatients = false;
      });
    } catch (error) {
      final cachedPatients = await _loadCachedPatients();
      if (!mounted) return;
      setState(() {
        if (cachedPatients.isEmpty) {
          _patientError = _patientLoadErrorMessage(error);
        } else {
          _setPatients(cachedPatients);
          _patientError =
              'Hasta listesi güncellenemedi. Son kaydedilen liste gösteriliyor.';
        }
        _isLoadingPatients = false;
      });
    }
  }

  Future<List<Patient>> _loadPatientsFromRepositoryAndCache() async {
    final userId = widget.currentUser?.userId;
    if (userId == null) return const [];
    final patients = await SupabasePatientRepository().getPatientsByExpert(
      expertUserId: userId,
    );
    await _cachePatients(patients);
    return patients;
  }

  void _setPatients(List<Patient> patients) {
    _patients = patients;
    _filteredPatients = _filteredPatientsForCurrentQuery(patients);
    if (patients.isEmpty) {
      _selectedPatient = null;
      return;
    }

    final selectedId = _selectedPatient?.patientId;
    final selectedStillExists =
        selectedId != null &&
        patients.any((patient) => patient.patientId == selectedId);
    if (!selectedStillExists) {
      _selectedPatient = patients.first;
    }
  }

  List<Patient> _filteredPatientsForCurrentQuery(List<Patient> patients) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return patients;
    return patients.where((patient) {
      return patient.fullName.toLowerCase().contains(query) ||
          patient.patientCode.toLowerCase().contains(query) ||
          (patient.phone ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _cachePatients(List<Patient> patients) async {
    final key = _patientCacheKey;
    if (key == null) return;
    final preferences = await SharedPreferences.getInstance();
    final rows = patients.map((patient) => patient.toMap()).toList();
    await preferences.setString(key, jsonEncode(rows));
  }

  Future<List<Patient>> _loadCachedPatients() async {
    final key = _patientCacheKey;
    if (key == null) return const [];
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(key);
    if (rawValue == null || rawValue.trim().isEmpty) return const [];

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map>()
        .map((item) => Patient.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  String? get _patientCacheKey {
    final userId = widget.currentUser?.userId;
    if (userId == null) return null;
    return 'oy_scanner_cached_patients_v1_user_$userId';
  }

  static String _patientLoadErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    final looksLikeConnectionProblem =
        message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network') ||
        message.contains('connection');

    if (looksLikeConnectionProblem) {
      return 'Hasta listesi yüklenemedi. Bu bilgisayar Supabase bağlantısına erişemiyor; internet veya DNS bağlantısını kontrol edin.';
    }

    return 'Hasta listesi yüklenemedi. Bağlantıyı kontrol edip tekrar deneyin.';
  }

  void _filterPatients() {
    setState(() {
      _filteredPatients = _filteredPatientsForCurrentQuery(_patients);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderCard(
                  isSupported: _isSupported,
                  isRunning: _isWorkflowRunning,
                  status: _workflowStatus,
                  silentMode: _silentMode,
                  onSilentModeChanged: _isWorkflowRunning
                      ? null
                      : (value) => setState(() => _silentMode = value),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 980;
                    final workflow = _WorkflowPanel(
                      patient: _selectedPatient,
                      isRunning: _isWorkflowRunning,
                      messages: _messages,
                      onStart: _selectedPatient == null || _isWorkflowRunning
                          ? null
                          : _runAutomaticWorkflow,
                      onStatus: _isWorkflowRunning
                          ? null
                          : () => _runSingleCommand('Durum kontrolü', const [
                              '--status',
                            ]),
                    );
                    final patients = _PatientPickerPanel(
                      patients: _filteredPatients,
                      selectedPatient: _selectedPatient,
                      isLoading: _isLoadingPatients,
                      errorMessage: _patientError,
                      searchController: _searchController,
                      onRefresh: _loadPatients,
                      onSelected: (patient) {
                        setState(() => _selectedPatient = patient);
                      },
                    );

                    if (!isWide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          workflow,
                          const SizedBox(height: 14),
                          patients,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: workflow),
                        const SizedBox(width: 14),
                        Expanded(flex: 4, child: patients),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _GeneratedFilesPanel(
                  files: _generatedFiles,
                  onRefresh: () => _refreshGeneratedFiles(),
                  onOpen: (file) =>
                      _automationService.openGeneratedFile(file.path),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _runAutomaticWorkflow() async {
    final patient = _selectedPatient;
    if (patient == null || _isWorkflowRunning) return;

    final startedAt = DateTime.now().subtract(const Duration(seconds: 2));
    setState(() {
      _isWorkflowRunning = true;
      _workflowStatus = 'Tarama başlatılıyor';
      _messages = [];
      _generatedFiles = [];
    });

    try {
      _addMessage('${patient.fullName} için otomatik akış başladı.');
      await _runSingleCommand('Ekranı hazırla', const ['--wake']);
      await Future<void>.delayed(const Duration(seconds: 1));

      await _runSingleCommand('Taramayı başlat', [
        '--start-scan',
        '--gender',
        _genderFor(patient),
      ]);

      await _waitWithStatus('Tarama tamamlanıyor', const Duration(seconds: 25));

      await _runSingleCommand('Formu doldur ve ilerle', [
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
        '42',
        '--next',
      ]);

      await _waitWithStatus(
        'Rapor dosyaları hazırlanıyor',
        const Duration(seconds: 18),
      );

      final files = await _exportUntilFilesAppear(startedAt);
      if (!mounted) return;
      setState(() {
        _generatedFiles = files;
        _workflowStatus = files.isEmpty
            ? 'Export kontrol bekliyor'
            : 'Tarama tamamlandı';
      });
      _addMessage(
        files.isEmpty
            ? 'Export sonrası dosya bulunamadı. Birkaç saniye sonra yenileyin.'
            : '${files.length} dosya bulundu.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _workflowStatus = 'Akış tamamlanamadı');
      _addMessage('Hata: $error');
    } finally {
      if (mounted) setState(() => _isWorkflowRunning = false);
    }
  }

  Future<List<OYScannerGeneratedFile>> _exportUntilFilesAppear(
    DateTime startedAt,
  ) async {
    for (var attempt = 0; attempt < 12; attempt++) {
      setState(() => _workflowStatus = 'Export deneniyor ${attempt + 1}/12');
      await _runSingleCommand('Export', const ['--export']);
      await Future<void>.delayed(const Duration(seconds: 4));
      final files = await _automationService.listGeneratedFiles(
        since: startedAt,
      );
      if (files.isNotEmpty) return files;
    }
    return _automationService.listGeneratedFiles(since: startedAt);
  }

  Future<void> _waitWithStatus(String label, Duration duration) async {
    final seconds = duration.inSeconds;
    for (var remaining = seconds; remaining > 0; remaining--) {
      if (!mounted) return;
      setState(() => _workflowStatus = '$label: ${remaining}s');
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }

  Future<void> _runSingleCommand(String label, List<String> arguments) async {
    final commandArguments = [if (_silentMode) '--silent', ...arguments];
    final result = await _automationService.runCommand(label, commandArguments);
    _addMessage(result.summary);
    final output = result.stdoutText.trim();
    if (output.isNotEmpty) {
      _addMessage(output.split('\n').last.trim());
    }
    if (!result.success) {
      throw result.errorMessage ?? result.summary;
    }
  }

  Future<void> _refreshGeneratedFiles({DateTime? since}) async {
    final files = await _automationService.listGeneratedFiles(since: since);
    if (!mounted) return;
    setState(() => _generatedFiles = files);
  }

  void _addMessage(String message) {
    if (!mounted || message.trim().isEmpty) return;
    setState(() {
      _messages = [
        '${TimeOfDay.now().format(context)}  $message',
        ..._messages,
      ].take(10).toList();
    });
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

  static String _safeText(String? value, {required String fallback}) {
    final trimmed = (value ?? '').trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isSupported;
  final bool isRunning;
  final String status;
  final bool silentMode;
  final ValueChanged<bool>? onSilentModeChanged;

  const _HeaderCard({
    required this.isSupported,
    required this.isRunning,
    required this.status,
    required this.silentMode,
    required this.onSilentModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSupported
        ? const Color(0xFF087F73)
        : const Color(0xFFB3261E);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F7F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  color: Color(0xFF087F73),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OY Scanner',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hasta seçin ve tüm tarama akışını tek butonla başlatın.',
                      style: TextStyle(color: Colors.grey[700], height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(
                color: color,
                label: isRunning
                    ? status
                    : isSupported
                    ? 'Hazır'
                    : 'Windows destekli değil',
                isRunning: isRunning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: silentMode,
              onChanged: isRunning ? null : onSilentModeChanged,
              title: const Text(
                'Gizli mod',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'eFoot ekranı kullanıcıya gösterilmeden Dashboard üstte tutulur.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowPanel extends StatelessWidget {
  final Patient? patient;
  final bool isRunning;
  final List<String> messages;
  final VoidCallback? onStart;
  final VoidCallback? onStatus;

  const _WorkflowPanel({
    required this.patient,
    required this.isRunning,
    required this.messages,
    required this.onStart,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Otomatik tarama',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            patient == null
                ? 'Başlamak için sağdan bir hasta seçin.'
                : 'Seçili hasta: ${patient!.fullName}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onStart,
                icon: isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isRunning ? 'Akış sürüyor' : 'Taramayı Başlat'),
              ),
              OutlinedButton.icon(
                onPressed: onStatus,
                icon: const Icon(Icons.radar_outlined),
                label: const Text('Durum'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Akış günlüğü',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (messages.isEmpty)
            Text('Henüz işlem yok.', style: TextStyle(color: Colors.grey[600]))
          else
            ...messages.map(
              (message) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(message, style: const TextStyle(fontSize: 12.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PatientPickerPanel extends StatelessWidget {
  final List<Patient> patients;
  final Patient? selectedPatient;
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final ValueChanged<Patient> onSelected;

  const _PatientPickerPanel({
    required this.patients,
    required this.selectedPatient,
    required this.isLoading,
    required this.errorMessage,
    required this.searchController,
    required this.onRefresh,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hastalar',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Hasta ara',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            if (errorMessage != null) ...[
              Text(
                errorMessage!,
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
              const SizedBox(height: 10),
            ],
            if (patients.isEmpty)
              Text(
                'Kayıtlı hasta bulunamadı.',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: patients.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final patient = patients[index];
                    final selected =
                        patient.patientId == selectedPatient?.patientId;
                    return _PatientTile(
                      patient: patient,
                      selected: selected,
                      onTap: () => onSelected(patient),
                    );
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final Patient patient;
  final bool selected;
  final VoidCallback onTap;

  const _PatientTile({
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
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.person_outline,
                color: const Color(0xFF087F73),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${patient.patientCode} • ${patient.displayPhone}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
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

class _GeneratedFilesPanel extends StatelessWidget {
  final List<OYScannerGeneratedFile> files;
  final Future<void> Function() onRefresh;
  final ValueChanged<OYScannerGeneratedFile> onOpen;

  const _GeneratedFilesPanel({
    required this.files,
    required this.onRefresh,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Üretilen dosyalar',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 96, maxHeight: 240),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: files.isEmpty
                ? Center(
                    child: Text(
                      'Export sonrası dosyalar burada görünecek.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: files.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(_iconFor(file.extension)),
                        title: Text(file.name, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${_formatSize(file.sizeBytes)} • ${file.path}',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onOpen(file),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return Icons.picture_as_pdf_outlined;
      case '.bmp':
        return Icons.image_outlined;
      case '.zip':
      case '.stl':
        return Icons.view_in_ar_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;
  final bool isRunning;

  const _StatusPill({
    required this.color,
    required this.label,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRunning)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
