import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oy_site/data/repositories/supabase_measurement_session_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_invite_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/patient_invite_model.dart';
import 'package:oy_site/screens/dashboard/anthropometric_clinical_info_screen.dart';
import 'package:oy_site/screens/dashboard/expert_profile_screen.dart';
import 'package:oy_site/screens/dashboard/insole_photo_upload_dialog.dart';
import 'package:oy_site/screens/dashboard/orthotic_design_form_screen.dart';
import 'package:oy_site/screens/dashboard/pressure_measurement_dialog.dart';
import 'package:oy_site/screens/dashboard/scan_folder_upload_dialog.dart';
import 'package:oy_site/screens/dashboard/session_analysis_results_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final MeasurementSession session;
  final dynamic pressureRepository;

  const SessionDetailScreen({
    super.key,
    required this.currentUser,
    required this.session,
    required this.pressureRepository,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late MeasurementSession _currentSession;

  final SupabaseMeasurementSessionRepository _sessionRepository =
      SupabaseMeasurementSessionRepository();

  final SupabasePatientInviteRepository _inviteRepository =
      SupabasePatientInviteRepository();

  final SupabasePatientRepository _patientRepository =
      SupabasePatientRepository();

  SupabaseClient get _client => Supabase.instance.client;

  PatientInviteModel? _latestInvite;
  bool _isCreatingInvite = false;
  bool _isLoadingDisplayInfo = true;

  String? _patientDisplayName;
  String? _patientCode;
  String? _clinicDisplayName;
  String? _clinicCode;
  String? _expertDisplayName;
  String? _assignedOptiyouDisplayName;

  String? _scanFolderPath;
  List<String> _scanFolderFiles = [];

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _loadDisplayInfo();
    _loadLatestInvite();
  }

  bool get _hasUploadedScanFolder =>
      _currentSession.has3dScan || _scanFolderPath != null;

  bool get _canOpenAnalysisResults =>
      _currentSession.clinicalInfoCompleted &&
      _hasUploadedScanFolder &&
      _currentSession.hasPlantarCsv;

  Future<void> _loadDisplayInfo() async {
    setState(() {
      _isLoadingDisplayInfo = true;
    });

    await Future.wait([
      _loadPatientDisplayInfo(),
      _loadClinicDisplayInfo(),
      _loadExpertDisplayInfo(),
      _loadAssignedOptiyouDisplayInfo(),
    ]);

    if (!mounted) return;

    setState(() {
      _isLoadingDisplayInfo = false;
    });
  }

  Future<void> _loadLatestInvite() async {
    final sessionId = _currentSession.sessionId;

    if (sessionId == null) return;

    try {
      final invite = await _inviteRepository.getLatestInviteForSession(
        sessionId: sessionId,
      );

      if (!mounted) return;

      setState(() {
        _latestInvite = invite;
      });
    } catch (_) {
      // Davet yüklenemese bile oturum ekranı çalışmaya devam eder.
    }
  }

  Future<void> _loadPatientDisplayInfo() async {
    try {
      final response = await _client
          .from('patients')
          .select('id, first_name, last_name, patient_code')
          .eq('id', _currentSession.patientId)
          .maybeSingle();

      if (response == null) return;

      final row = Map<String, dynamic>.from(response as Map);
      final firstName = (row['first_name'] ?? '').toString().trim();
      final lastName = (row['last_name'] ?? '').toString().trim();
      final patientCode = (row['patient_code'] ?? '').toString().trim();
      final fullName = '$firstName $lastName'.trim();

      if (!mounted) return;

      setState(() {
        _patientDisplayName = fullName.isNotEmpty
            ? fullName
            : 'Hasta #${_currentSession.patientId}';
        _patientCode = patientCode.isEmpty ? null : patientCode;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _patientDisplayName = 'Hasta #${_currentSession.patientId}';
      });
    }
  }

  Future<void> _loadClinicDisplayInfo() async {
    try {
      final clinicId = _currentSession.clinicId;

      if (clinicId <= 0) {
        if (!mounted) return;

        setState(() {
          _clinicDisplayName = 'Klinik bilgisi eksik';
        });
        return;
      }

      final response = await _client
          .from('clinics')
          .select('id, clinic_name, clinic_code, clinic_type')
          .eq('id', clinicId)
          .maybeSingle();

      if (response == null) {
        if (!mounted) return;

        setState(() {
          _clinicDisplayName = 'Klinik #$clinicId';
        });
        return;
      }

      final row = Map<String, dynamic>.from(response as Map);
      final clinicName = (row['clinic_name'] ?? '').toString().trim();
      final clinicCode = (row['clinic_code'] ?? '').toString().trim();

      if (!mounted) return;

      setState(() {
        _clinicDisplayName =
            clinicName.isNotEmpty ? clinicName : 'Klinik #$clinicId';
        _clinicCode = clinicCode.isEmpty ? null : clinicCode;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _clinicDisplayName = 'Klinik #${_currentSession.clinicId}';
      });
    }
  }

  Future<void> _loadExpertDisplayInfo() async {
    try {
      final response = await _client
          .from('user_profiles_full')
          .select('user_id, first_name, last_name, username, email, title')
          .eq('user_id', _currentSession.expertUserId)
          .maybeSingle();

      if (response == null) {
        if (!mounted) return;

        setState(() {
          _expertDisplayName =
              _currentSession.expertUserId == widget.currentUser.userId
                  ? widget.currentUser.displayName
                  : 'Uzman #${_currentSession.expertUserId}';
        });
        return;
      }

      final row = Map<String, dynamic>.from(response as Map);
      final firstName = (row['first_name'] ?? '').toString().trim();
      final lastName = (row['last_name'] ?? '').toString().trim();
      final username = (row['username'] ?? '').toString().trim();
      final email = (row['email'] ?? '').toString().trim();
      final title = (row['title'] ?? '').toString().trim();

      final fullName = '$firstName $lastName'.trim();
      final displayName = fullName.isNotEmpty
          ? title.isNotEmpty
              ? '$title $fullName'
              : fullName
          : username.isNotEmpty
              ? username
              : email.isNotEmpty
                  ? email
                  : 'Uzman #${_currentSession.expertUserId}';

      if (!mounted) return;

      setState(() {
        _expertDisplayName = displayName;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _expertDisplayName =
            _currentSession.expertUserId == widget.currentUser.userId
                ? widget.currentUser.displayName
                : 'Uzman #${_currentSession.expertUserId}';
      });
    }
  }

  Future<void> _loadAssignedOptiyouDisplayInfo() async {
    final assignedId = _currentSession.assignedOptityouUserId;

    if (assignedId == null || assignedId <= 0) {
      if (!mounted) return;

      setState(() {
        _assignedOptiyouDisplayName = 'Atama yok';
      });
      return;
    }

    try {
      final response = await _client
          .from('user_profiles_full')
          .select('user_id, first_name, last_name, username, email, title')
          .eq('user_id', assignedId)
          .maybeSingle();

      if (response == null) {
        if (!mounted) return;

        setState(() {
          _assignedOptiyouDisplayName = 'OptiYou #$assignedId';
        });
        return;
      }

      final row = Map<String, dynamic>.from(response as Map);
      final firstName = (row['first_name'] ?? '').toString().trim();
      final lastName = (row['last_name'] ?? '').toString().trim();
      final username = (row['username'] ?? '').toString().trim();
      final email = (row['email'] ?? '').toString().trim();
      final title = (row['title'] ?? '').toString().trim();

      final fullName = '$firstName $lastName'.trim();
      final displayName = fullName.isNotEmpty
          ? title.isNotEmpty
              ? '$title $fullName'
              : fullName
          : username.isNotEmpty
              ? username
              : email.isNotEmpty
                  ? email
                  : 'OptiYou #$assignedId';

      if (!mounted) return;

      setState(() {
        _assignedOptiyouDisplayName = displayName;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _assignedOptiyouDisplayName = 'OptiYou #$assignedId';
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case SessionStatuses.completed:
        return Colors.green;
      case SessionStatuses.inProgress:
        return Colors.orange;
      case SessionStatuses.draft:
        return Colors.blueGrey;
      case SessionStatuses.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case SessionStatuses.completed:
        return 'Tamamlandı';
      case SessionStatuses.inProgress:
        return 'Devam Ediyor';
      case SessionStatuses.draft:
        return 'Taslak';
      case SessionStatuses.cancelled:
        return 'İptal';
      default:
        return status;
    }
  }

  String _safeValue(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? '—' : text;
  }

  String _publicAppOrigin() {
    final uri = Uri.base;

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.trim().isNotEmpty) {
      return uri.origin;
    }

    return 'https://www.optiyou.fit';
  }

  String _buildWelcomeQrUrl(PatientInviteModel invite) {
    final token = invite.token.trim();
    final encodedToken = Uri.encodeComponent(token);

    return '${_publicAppOrigin()}/#/welcome?invite=$encodedToken&source=session';
  }

  void _openExpertProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpertProfileScreen(
          currentUser: widget.currentUser,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadDisplayInfo();
      }
    });
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

  Widget _buildKeyValueRow(
    String label,
    String value, {
    Widget? trailing,
  }) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicProfileButton() {
    return Tooltip(
      message: 'Uzman profilindeki klinik bilgisini görüntüle / düzenle',
      child: InkWell(
        onTap: _openExpertProfile,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_circle_outlined,
            size: 18,
            color: Colors.teal,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    final patientText = _patientCode == null
        ? _safeValue(_patientDisplayName)
        : '${_safeValue(_patientDisplayName)} ($_patientCode)';

    final clinicText = _clinicCode == null
        ? _safeValue(_clinicDisplayName)
        : '${_safeValue(_clinicDisplayName)} ($_clinicCode)';

    return _buildSectionCard(
      title: 'Temel Bilgiler',
      child: Column(
        children: [
          if (_isLoadingDisplayInfo)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Hasta, klinik ve uzman bilgileri yükleniyor...',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          _buildKeyValueRow(
            'Hasta',
            patientText,
          ),
          _buildKeyValueRow(
            'Klinik',
            clinicText,
            trailing: _buildClinicProfileButton(),
          ),
          _buildKeyValueRow(
            'Uzman',
            _safeValue(_expertDisplayName),
          ),
          const Divider(height: 22),
          _buildKeyValueRow(
            'Oturum Kodu',
            _currentSession.sessionCode,
          ),
          _buildKeyValueRow(
            'Oluşturulma',
            _formatDate(_currentSession.createdAt),
          ),
          _buildKeyValueRow(
            'Güncellenme',
            _formatDate(_currentSession.updatedAt),
          ),
          _buildKeyValueRow(
            'Tamamlanma',
            _formatDate(_currentSession.completedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResultsCard() {
    final isEnabled = _canOpenAnalysisResults;

    return Opacity(
      opacity: isEnabled ? 1 : 0.62,
      child: InkWell(
        onTap: isEnabled ? _openAnalysisResults : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEnabled
                  ? Colors.teal.withOpacity(0.20)
                  : Colors.grey.shade300,
            ),
            boxShadow: isEnabled
                ? const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? Colors.teal.withOpacity(0.12)
                      : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: isEnabled ? Colors.teal : Colors.grey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ayak Sağlığı Analiz Sonuçları',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? const Color(0xFF1A2340)
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEnabled
                          ? 'Ölçüm sonuçlarını görüntülemek için tıklayın'
                          : 'Bu alanın aktif olması için ilk 3 ölçüm adımı tamamlanmalıdır',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? Colors.green.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isEnabled ? 'Aktif' : 'Kilidi Açılmadı',
                        style: TextStyle(
                          color: isEnabled
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                isEnabled ? Icons.arrow_forward_ios : Icons.lock_outline,
                size: 16,
                color: isEnabled ? Colors.black38 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteQrCard() {
    return _buildSectionCard(
      title: 'Sonuç Erişim QR',
      child: Row(
        children: [
          Expanded(
            child: Text(
              _latestInvite == null
                  ? 'Ölçüm onaylandıktan sonra kullanıcıyı Optiyou karşılama sayfasına yönlendiren QR bağlantısı oluşturulur.'
                  : 'Sonuç erişim bağlantısı oluşturuldu. QR kodu tekrar görüntüleyebilir veya linki kopyalayabilirsiniz.',
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _latestInvite == null ? null : _showLatestInviteQr,
            icon: const Icon(Icons.qr_code),
            label: const Text('QR Görüntüle'),
          ),
        ],
      ),
    );
  }

  List<_SessionStepItem> _buildSessionSteps() {
    final hasUploadedScanFolder = _hasUploadedScanFolder;

    return [
      _SessionStepItem(
        icon: Icons.monitor_weight,
        title: 'Klinik / Antropometrik Bilgiler',
        subtitle: 'Boy, kilo, BMI, şikayet, tanı ve patoloji bilgileri',
        isCompleted: _currentSession.clinicalInfoCompleted,
        onTap: _openClinicalInfoScreen,
      ),
      _SessionStepItem(
        icon: Icons.view_in_ar,
        title: '3D Scan',
        subtitle: _scanFolderPath == null
            ? '3D tarama klasörünü yükle'
            : 'Klasör yüklendi • ${_scanFolderFiles.length} dosya',
        isCompleted: hasUploadedScanFolder,
        onTap: _openScanFolderUploadDialog,
      ),
      _SessionStepItem(
        icon: Icons.speed,
        title: 'Plantar Pressure',
        subtitle: 'Basınç verisi ve özet sonuçları',
        isCompleted: _currentSession.hasPlantarCsv,
        onTap: _openPressureMeasurementDialog,
      ),
      _SessionStepItem(
        icon: Icons.photo_camera_back,
        title: 'Referans İç Tabanlık',
        subtitle: 'İç tabanlık / ayak referans görselleri',
        isCompleted: _currentSession.hasInsolePhoto,
        onTap: _openInsolePhotoUploadDialog,
      ),
      _SessionStepItem(
        icon: Icons.design_services,
        title: 'Tasarım Formu',
        subtitle: 'Ortez tasarım kararları ve uzman notları',
        isCompleted: _currentSession.designFormCompleted,
        onTap: _openDesignFormScreen,
      ),
      _SessionStepItem(
        icon: Icons.verified_user_outlined,
        title: 'Ölçümü Onayla',
        subtitle: _currentSession.orderCreated
            ? 'Ölçüm onaylandı ve sonuç erişim QR bağlantısı oluşturuldu'
            : 'Ölçümü tamamla, kullanıcıyı karşılama sayfasına yönlendiren QR oluştur',
        isCompleted: _currentSession.orderCreated,
        onTap: _currentSession.orderCreated && _latestInvite != null
            ? _showLatestInviteQr
            : _confirmMeasurementAndCreateInvite,
      ),
    ];
  }

  double _completionRatio() {
    final items = _buildSessionSteps();
    final completedCount = items.where((e) => e.isCompleted).length;
    return items.isEmpty ? 0 : completedCount / items.length;
  }

  Future<void> _persistSessionUpdate(MeasurementSession updatedSession) async {
    setState(() {
      _currentSession = updatedSession;
    });

    try {
      await _sessionRepository.updateSession(session: updatedSession);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oturum güncellenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openClinicalInfoScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnthropometricClinicalInfoScreen(
          currentUser: widget.currentUser,
          session: _currentSession,
        ),
      ),
    );

    if (result == true && mounted) {
      final updated = _currentSession.copyWith(
        clinicalInfoCompleted: true,
        updatedAt: DateTime.now(),
      );

      await _persistSessionUpdate(
        updated.copyWith(
          completedAt:
              updated.allStepsCompleted ? DateTime.now() : updated.completedAt,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Klinik / antropometrik bilgiler tamamlandı.'),
        ),
      );
    }
  }

  Future<void> _openScanFolderUploadDialog() async {
    final result = await showDialog<ScanFolderUploadResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ScanFolderUploadDialog(
        sessionId: _currentSession.sessionId,
        patientId: _currentSession.patientId,
        expertUserId: widget.currentUser.userId,
        targetUserId: null,
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _scanFolderPath = result.folderPath;
      _scanFolderFiles = result.fileNames;
    });

    final updated = _currentSession.copyWith(
      has3dScan: true,
      updatedAt: DateTime.now(),
    );

    await _persistSessionUpdate(
      updated.copyWith(
        completedAt:
            updated.allStepsCompleted ? DateTime.now() : updated.completedAt,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '3D tarama klasörü yüklendi (${result.fileNames.length} dosya).',
        ),
      ),
    );
  }

  Future<void> _openDesignFormScreen() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrthoticDesignFormScreen(
          currentUser: widget.currentUser,
          session: _currentSession,
        ),
      ),
    );

    if (result == true && mounted) {
      final updated = _currentSession.copyWith(
        designFormCompleted: true,
        updatedAt: DateTime.now(),
      );

      await _persistSessionUpdate(
        updated.copyWith(
          completedAt:
              updated.allStepsCompleted ? DateTime.now() : updated.completedAt,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tasarım formu tamamlandı.'),
        ),
      );
    }
  }

  Future<void> _openPressureMeasurementDialog() async {
    if (!_currentSession.clinicalInfoCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Basınç ölçümünden önce klinik / antropometrik bilgiler tamamlanmalıdır.',
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PressureMeasurementDialog(
        pressureRepository: widget.pressureRepository,
        sessionCode: _currentSession.sessionCode,
        sessionId: _currentSession.sessionId,
        patientId: _currentSession.patientId,
        expertUserId: widget.currentUser.userId,
      ),
    );

    if (!mounted) return;

    final updated = _currentSession.copyWith(
      hasPlantarCsv: true,
      updatedAt: DateTime.now(),
    );

    await _persistSessionUpdate(
      updated.copyWith(
        completedAt:
            updated.allStepsCompleted ? DateTime.now() : updated.completedAt,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plantar basınç ölçümü tamamlandı.'),
      ),
    );
  }

  Future<void> _openInsolePhotoUploadDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InsolePhotoUploadDialog(
        sessionId: _currentSession.sessionId,
        patientId: _currentSession.patientId,
        expertUserId: widget.currentUser.userId,
      ),
    );

    if (result == true && mounted) {
      final updated = _currentSession.copyWith(
        hasInsolePhoto: true,
        updatedAt: DateTime.now(),
      );

      await _persistSessionUpdate(
        updated.copyWith(
          completedAt:
              updated.allStepsCompleted ? DateTime.now() : updated.completedAt,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İç taban fotoğrafı yüklendi.'),
        ),
      );
    }
  }

  Future<void> _confirmMeasurementAndCreateInvite() async {
    if (!_currentSession.canCreateOrder) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ölçümü onaylamadan önce önceki tüm adımlar tamamlanmalıdır.',
          ),
        ),
      );
      return;
    }

    final patientId = _currentSession.patientId;
    final sessionId = _currentSession.sessionId;
    final expertUserId = widget.currentUser.userId;

    if (sessionId == null || expertUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oturum veya uzman kullanıcı ID bulunamadı.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingInvite = true;
    });

    try {
      final patient = await _patientRepository.getPatientById(
        patientId: patientId,
      );

      final invite = await _inviteRepository.createInvite(
        patientId: patientId,
        sessionId: sessionId,
        expertUserId: expertUserId,
        email: patient?.email,
        validDays: 365,
      );

      if (!mounted) return;

      final updated = _currentSession.copyWith(
        orderCreated: true,
        updatedAt: DateTime.now(),
      );

      await _persistSessionUpdate(
        updated.copyWith(
          completedAt:
              updated.allStepsCompleted ? DateTime.now() : updated.completedAt,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latestInvite = invite;
        _isCreatingInvite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (patient?.email ?? '').trim().isEmpty
                ? 'Ölçüm onaylandı ve sonuç erişim QR bağlantısı oluşturuldu. E-posta bulunamadı.'
                : 'Ölçüm onaylandı ve sonuç erişim QR bağlantısı oluşturuldu. E-posta davete eklendi.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _showInviteDialog(invite);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreatingInvite = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sonuç erişim QR bağlantısı oluşturulamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInviteDialog(PatientInviteModel invite) {
    final welcomeUrl = _buildWelcomeQrUrl(invite);

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sonuç Erişim QR'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Taraması yapılan kişi bu QR kodu okutarak Optiyou karşılama sayfasına gider. Kayıt veya giriş işlemini aynı sayfadan tamamlayıp ölçüm sonuçlarına erişebilir.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.teal.withOpacity(0.20)),
                ),
                child: QrImageView(
                  data: welcomeUrl,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              SelectableText(
                welcomeUrl,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: welcomeUrl),
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Welcome QR bağlantısı kopyalandı.'),
                ),
              );
            },
            child: const Text('Linki Kopyala'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showLatestInviteQr() {
    final invite = _latestInvite;

    if (invite == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce ölçüm onaylanmalı ve davet oluşturulmalıdır.'),
        ),
      );
      return;
    }

    _showInviteDialog(invite);
  }

  void _openAnalysisResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionAnalysisResultsScreen(
          currentUser: widget.currentUser,
          session: _currentSession,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_currentSession.effectiveStatus);
    final sessionSteps = _buildSessionSteps();
    final progress = _completionRatio();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oturum Detayı'),
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
                          Icons.fact_check,
                          size: 36,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentSession.sessionCode,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Oturum Tarihi: ${_formatDate(_currentSession.sessionDate)}'
                              '${_currentSession.sessionTime != null ? ' • Saat: ${_currentSession.sessionTime}' : ''}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'İşlem yapan kullanıcı: ${widget.currentUser.displayName}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_isCreatingInvite)
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
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
                            _statusLabel(_currentSession.effectiveStatus),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
                          _buildSessionInfoCard(),
                          const SizedBox(height: 16),
                          _buildAnalysisResultsCard(),
                          const SizedBox(height: 16),
                          _buildInviteQrCard(),
                          if (_scanFolderPath != null) ...[
                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Yüklenen 3D Tarama Klasörü',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _scanFolderPath!,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Dosya sayısı: ${_scanFolderFiles.length}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_scanFolderFiles.isNotEmpty)
                                    ..._scanFolderFiles.take(6).map(
                                          (fileName) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .insert_drive_file_outlined,
                                                  size: 18,
                                                  color: Colors.teal,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    fileName,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  if (_scanFolderFiles.length > 6)
                                    Text(
                                      '+ ${_scanFolderFiles.length - 6} dosya daha',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: _buildSectionCard(
                        title: 'Oturum Akışı',
                        child: Column(
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
                            ...List.generate(sessionSteps.length, (index) {
                              final step = sessionSteps[index];
                              final isLast = index == sessionSteps.length - 1;
                              return _buildFlowStep(
                                step: step,
                                isLast: isLast,
                              );
                            }),
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
    );
  }

  Widget _buildFlowStep({
    required _SessionStepItem step,
    required bool isLast,
  }) {
    final Color activeColor = step.isCompleted ? Colors.green : Colors.orange;

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
                  color: activeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeColor.withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  step.isCompleted ? Icons.check : step.icon,
                  color: activeColor,
                  size: 20,
                ),
              ),
              if (!isLast)
                Container(
                  width: 3,
                  height: 110,
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
            child: InkWell(
              onTap: _isCreatingInvite ? null : step.onTap,
              borderRadius: BorderRadius.circular(14),
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
                child: Row(
                  children: [
                    Expanded(
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
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _isCreatingInvite
                          ? Icons.hourglass_top_outlined
                          : Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionStepItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _SessionStepItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.onTap,
  });
}