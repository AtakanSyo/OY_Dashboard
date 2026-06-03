import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_measurement_session_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/screens/dashboard/create_session_screen.dart';
import 'package:oy_site/screens/dashboard/session_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final SupabaseMeasurementSessionRepository _sessionRepository =
      SupabaseMeasurementSessionRepository();

  SupabaseClient get _client => Supabase.instance.client;

  bool _isLoadingSessions = true;
  bool _isUpdatingPatient = false;

  String? _errorMessage;
  List<MeasurementSession> _sessions = [];

  late String _firstName;
  late String _lastName;
  String? _email;
  String? _phone;
  String? _gender;
  DateTime? _birthDate;
  String? _notes;

  @override
  void initState() {
    super.initState();

    _firstName = widget.patient.firstName;
    _lastName = widget.patient.lastName;
    _email = widget.patient.email;
    _phone = widget.patient.phone;
    _gender = widget.patient.gender;
    _birthDate = widget.patient.birthDate;
    _notes = widget.patient.notes;

    _loadSessions();
  }

  String get _fullName {
    final name = '$_firstName $_lastName'.trim();
    return name.isEmpty ? 'İsimsiz Kullanıcı' : name;
  }

  String get _displayGender {
    switch ((_gender ?? '').toUpperCase()) {
      case 'MALE':
      case 'M':
      case 'ERKEK':
        return 'Erkek';
      case 'FEMALE':
      case 'F':
      case 'KADIN':
        return 'Kadın';
      case 'OTHER':
      case 'DİĞER':
      case 'DIGER':
        return 'Diğer';
      default:
        return 'Belirtilmedi';
    }
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
    });

    try {
      final patientId = widget.patient.patientId;

      if (patientId == null) {
        throw Exception('Kullanıcı ID bulunamadı.');
      }

      final sessions = await _sessionRepository.getSessionsByPatient(
        patientId: patientId,
      );

      if (!mounted) return;

      setState(() {
        _sessions = sessions;
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

  String _formatDateForInput(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateInput(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      throw Exception('Doğum tarihi YYYY-MM-DD formatında olmalıdır.');
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _buildPhoneText() {
    final phone = (_phone ?? '').trim();
    return phone.isEmpty ? 'Telefon bilgisi yok' : phone;
  }

  String _buildEmailText() {
    final email = (_email ?? '').trim();
    return email.isEmpty ? 'E-posta bilgisi yok' : email;
  }

  String _buildNotesText() {
    final notes = (_notes ?? '').trim();
    return notes.isEmpty ? 'Kullanıcı notu bulunmuyor' : notes;
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

    if (newSession == null || !mounted) return;

    await _loadSessions();

    if (!mounted) return;

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

    if (mounted) {
      await _loadSessions();
    }
  }

  void _openSessionDetail(MeasurementSession session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionDetailScreen(
          currentUser: widget.currentUser,
          session: session,
          pressureRepository: widget.pressureRepository,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadSessions();
      }
    });
  }

  Future<void> _openEditPatientDialog() async {
    final firstNameController = TextEditingController(text: _firstName);
    final lastNameController = TextEditingController(text: _lastName);
    final emailController = TextEditingController(text: _email ?? '');
    final phoneController = TextEditingController(text: _phone ?? '');
    final birthDateController = TextEditingController(
      text: _formatDateForInput(_birthDate),
    );
    final notesController = TextEditingController(text: _notes ?? '');

    String selectedGender = (_gender ?? '').trim();

    final result = await showDialog<_PatientEditResult>(
      context: context,
      builder: (_) {
        String? localError;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Kullanıcı Bilgilerini Düzenle'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (localError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.20),
                            ),
                          ),
                          child: Text(
                            localError!,
                            style: const TextStyle(
                              color: Colors.red,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Ad',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Soyad',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedGender.isEmpty ? null : selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Cinsiyet',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'MALE',
                            child: Text('Erkek'),
                          ),
                          DropdownMenuItem(
                            value: 'FEMALE',
                            child: Text('Kadın'),
                          ),
                          DropdownMenuItem(
                            value: 'OTHER',
                            child: Text('Diğer'),
                          ),
                        ],
                        onChanged: (value) {
                          selectedGender = value ?? '';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: birthDateController,
                        decoration: InputDecoration(
                          labelText: 'Doğum Tarihi',
                          hintText: 'YYYY-MM-DD',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today_outlined),
                            onPressed: () async {
                              final initialDate = _birthDate ?? DateTime(1990);
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: initialDate,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );

                              if (picked == null) return;

                              birthDateController.text =
                                  _formatDateForInput(picked);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Notlar',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isUpdatingPatient
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton.icon(
                  onPressed: _isUpdatingPatient
                      ? null
                      : () {
                          try {
                            final firstName =
                                firstNameController.text.trim();
                            final lastName = lastNameController.text.trim();

                            if (firstName.isEmpty || lastName.isEmpty) {
                              setLocalState(() {
                                localError = 'Ad ve soyad zorunludur.';
                              });
                              return;
                            }

                            final parsedBirthDate = _parseDateInput(
                              birthDateController.text,
                            );

                            Navigator.pop(
                              context,
                              _PatientEditResult(
                                firstName: firstName,
                                lastName: lastName,
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                gender: selectedGender.trim(),
                                birthDate: parsedBirthDate,
                                notes: notesController.text.trim(),
                              ),
                            );
                          } catch (e) {
                            setLocalState(() {
                              localError = e.toString();
                            });
                          }
                        },
                  icon: const Icon(Icons.save),
                  label: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthDateController.dispose();
    notesController.dispose();

    if (result == null) return;

    await _updatePatient(result);
  }

  Future<void> _updatePatient(_PatientEditResult result) async {
    final patientId = widget.patient.patientId;

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı ID bulunamadı.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingPatient = true;
    });

    try {
      final response = await _client
          .from('patients')
          .update({
            'first_name': result.firstName,
            'last_name': result.lastName,
            'email': result.email.isEmpty ? null : result.email,
            'phone': result.phone.isEmpty ? null : result.phone,
            'gender': result.gender.isEmpty ? null : result.gender,
            'birth_date':
                result.birthDate == null ? null : result.birthDate!.toIso8601String(),
            'notes': result.notes.isEmpty ? null : result.notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', patientId)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Kullanıcı güncellenemedi. Kayıt bulunamadı.');
      }

      if (!mounted) return;

      setState(() {
        _firstName = result.firstName;
        _lastName = result.lastName;
        _email = result.email.isEmpty ? null : result.email;
        _phone = result.phone.isEmpty ? null : result.phone;
        _gender = result.gender.isEmpty ? null : result.gender;
        _birthDate = result.birthDate;
        _notes = result.notes.isEmpty ? null : result.notes;
        _isUpdatingPatient = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgileri güncellendi.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUpdatingPatient = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı güncellenemedi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Detayı'),
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
                  _fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kullanıcı Kodu: ${patient.patientCode}',
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
                  'Yeni Ölçüm',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isUpdatingPatient ? null : _openEditPatientDialog,
                icon: const Icon(Icons.edit),
                label: Text(
                  _isUpdatingPatient ? 'Kaydediliyor...' : 'Düzenle',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(Patient patient) {
    return _buildSectionCard(
      title: 'Kullanıcı Bilgileri',
      child: Column(
        children: [
          _buildKeyValueRow('Ad Soyad', _fullName),
          _buildKeyValueRow('Kullanıcı Kodu', patient.patientCode),
          _buildKeyValueRow('E-posta', _buildEmailText()),
          _buildKeyValueRow('Telefon', _buildPhoneText()),
          _buildKeyValueRow('Cinsiyet', _displayGender),
          _buildKeyValueRow('Doğum Tarihi', _formatDate(_birthDate)),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Text('Bu Kullanıcıya ait ölçüm oturumu bulunamadı.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.separated(
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final statusColor = _statusColor(session.effectiveStatus);

          return InkWell(
            onTap: () => _openSessionDetail(session),
            borderRadius: BorderRadius.circular(14),
            child: Container(
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
                                _statusLabel(session.effectiveStatus),
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
                              session.clinicalInfoCompleted
                                  ? 'Klinik Bilgi Var'
                                  : 'Klinik Bilgi Yok',
                              session.clinicalInfoCompleted,
                            ),
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
                              session.designFormCompleted
                                  ? 'Tasarım Formu Var'
                                  : 'Tasarım Formu Yok',
                              session.designFormCompleted,
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
                    onPressed: () => _openSessionDetail(session),
                    child: const Text('Detay'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

class _PatientEditResult {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String gender;
  final DateTime? birthDate;
  final String notes;

  const _PatientEditResult({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.gender,
    required this.birthDate,
    required this.notes,
  });
}