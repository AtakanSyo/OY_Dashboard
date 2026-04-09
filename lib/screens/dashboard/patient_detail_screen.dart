import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_measurement_session_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/screens/dashboard/create_session_screen.dart';
import 'package:oy_site/screens/dashboard/session_detail_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final AppUser currentUser;
  final Patient patient;
  final dynamic pressureRepository;

  const PatientDetailScreen({
    super.key,
    required this.currentUser,
    required this.patient,
    required this.pressureRepository,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final MockMeasurementSessionRepository _sessionRepository =
      MockMeasurementSessionRepository();

  bool _isLoadingSessions = true;
  String? _errorMessage;
  List<MeasurementSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
    });

    try {
      final allSessions = await _sessionRepository.getSessions();

      final patientSessions = allSessions
          .where((session) => session.patientId == widget.patient.patientId)
          .toList()
        ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

      if (!mounted) return;

      setState(() {
        _sessions = patientSessions;
        _isLoadingSessions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Oturumlar yüklenirken hata oluştu: $e';
        _isLoadingSessions = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _buildPhoneText() {
    final phone = (widget.patient.phone ?? '').trim();
    return phone.isEmpty ? 'Telefon bilgisi yok' : phone;
  }

  String _buildEmailText() {
    final email = (widget.patient.email ?? '').trim();
    return email.isEmpty ? 'E-posta bilgisi yok' : email;
  }

  String _buildNotesText() {
    final notes = (widget.patient.notes ?? '').trim();
    return notes.isEmpty ? 'Hasta notu bulunmuyor' : notes;
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

Future<void> _openCreateSessionScreen() async {
  final newSession = await Navigator.push<MeasurementSession>(
    context,
    MaterialPageRoute(
      builder: (_) => CreateSessionScreen(
        currentUser: widget.currentUser,
        patients: [widget.patient],
        initialPatient: widget.patient,
      ),
    ),
  );

  if (newSession != null && mounted) {
    setState(() {
      _sessions = [newSession, ..._sessions];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newSession.sessionCode} oluşturuldu.'),
      ),
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          currentUser: widget.currentUser,
          session: newSession,
          pressureRepository: widget.pressureRepository,
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasta Detayı'),
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
                _buildHeader(patient),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildPatientInfoCard(patient),
                          const SizedBox(height: 16),
                          _buildNotesCard(),
                          const SizedBox(height: 16),
                          _buildKvkkCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: _buildSessionSection(),
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

  Widget _buildHeader(Patient patient) {
    return Container(
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
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.teal,
            child: Icon(
              Icons.person,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hasta Kodu: ${patient.patientCode}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Oluşturan kullanıcı: ${widget.currentUser.displayName}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _openCreateSessionScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Yeni Oturum',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hasta düzenleme ekranını sonra bağlayacağız.'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Düzenle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(Patient patient) {
    return _buildSectionCard(
      title: 'Hasta Bilgileri',
      child: Column(
        children: [
          _buildKeyValueRow('Ad Soyad', patient.fullName),
          _buildKeyValueRow('Hasta Kodu', patient.patientCode),
          _buildKeyValueRow('E-posta', _buildEmailText()),
          _buildKeyValueRow('Telefon', _buildPhoneText()),
          _buildKeyValueRow('Cinsiyet', patient.displayGender),
          _buildKeyValueRow('Doğum Tarihi', _formatDate(patient.birthDate)),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return _buildSectionCard(
      title: 'Notlar',
      child: Text(
        _buildNotesText(),
        style: const TextStyle(height: 1.5),
      ),
    );
  }

  Widget _buildKvkkCard() {
    return _buildSectionCard(
      title: 'KVKK / Onam Durumu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKeyValueRow('Onam Durumu', 'Henüz bağlanmadı'),
          _buildKeyValueRow('Bilgilendirme', 'Mock veri aşamasında'),
          _buildKeyValueRow('E-posta Gönderimi', 'Henüz tanımlanmadı'),
          const SizedBox(height: 8),
          Text(
            'Bu alan daha sonra patient_kvkk_consents tablosuna bağlanacak.',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionSection() {
    return _buildSectionCard(
      title: 'Ölçüm Oturumları',
      child: SizedBox(
        height: 520,
        child: _buildSessionContent(),
      ),
    );
  }

  Widget _buildSessionContent() {
    if (_isLoadingSessions) {
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

    if (_sessions.isEmpty) {
      return const Center(
        child: Text('Bu hastaya ait ölçüm oturumu bulunamadı.'),
      );
    }

    return ListView.separated(
      itemCount: _sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final statusColor = _statusColor(session.status);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.12),
                child: Icon(
                  Icons.fact_check,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 14),
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
                          session.sessionCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            _statusLabel(session.status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tarih: ${_formatDate(session.sessionDate)}'
                      '${session.sessionTime != null ? ' • Saat: ${session.sessionTime}' : ''}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag(
                          session.has3dScan ? '3D Scan Var' : '3D Scan Yok',
                          session.has3dScan,
                        ),
                        _buildTag(
                          session.hasPlantarCsv
                              ? 'Plantar Veri Var'
                              : 'Plantar Veri Yok',
                          session.hasPlantarCsv,
                        ),
                        _buildTag(
                          session.hasInsolePhoto
                              ? 'Fotoğraf Var'
                              : 'Fotoğraf Yok',
                          session.hasInsolePhoto,
                        ),
                        _buildTag(
                          session.orderCreated
                              ? 'Sipariş Oluşturuldu'
                              : 'Sipariş Yok',
                          session.orderCreated,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionDetailScreen(
                        currentUser: widget.currentUser,
                        session: session,
                        pressureRepository: widget.pressureRepository,
                      ),
                    ),
                  );
                },
                child: const Text('Detay'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.12) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
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
}