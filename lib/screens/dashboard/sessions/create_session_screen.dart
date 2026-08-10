import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_measurement_session_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateSessionScreen extends StatefulWidget {
  final AppUser currentUser;
  final List<Patient> patients;
  final Patient? initialPatient;

  const CreateSessionScreen({
    super.key,
    required this.currentUser,
    required this.patients,
    this.initialPatient,
  });

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  final SupabaseMeasurementSessionRepository _sessionRepository =
      SupabaseMeasurementSessionRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Patient? _selectedPatient;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPatient = widget.initialPatient;
  }

  String _generateSessionCode() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    return 'MS-${now.year}$month$day-$hour$minute';
  }

  String? _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return null;

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<int?> _resolveCurrentExpertClinicId() async {
    final localClinicId = widget.currentUser.clinicId;

    if (localClinicId != null && localClinicId > 0) {
      return localClinicId;
    }

    final userId = widget.currentUser.userId;

    if (userId == null) return null;

    try {
      final response = await _client
          .from('user_profiles')
          .select('clinic_id')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      final row = Map<String, dynamic>.from(response as Map);
      return _asInt(row['clinic_id']);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveCurrentExpertClinicName({
    required int clinicId,
  }) async {
    final localClinicName = (widget.currentUser.clinicName ?? '').trim();

    if (localClinicName.isNotEmpty) {
      return localClinicName;
    }

    try {
      final response = await _client
          .from('clinics')
          .select('clinic_name')
          .eq('id', clinicId)
          .maybeSingle();

      if (response == null) return null;

      final row = Map<String, dynamic>.from(response as Map);
      final clinicName = (row['clinic_name'] ?? '').toString().trim();

      return clinicName.isEmpty ? null : clinicName;
    } catch (_) {
      return null;
    }
  }

  Future<void> _createSession() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir kullanıcı seçin.'),
        ),
      );
      return;
    }

    final patientId = _selectedPatient!.patientId;
    final expertUserId = widget.currentUser.userId;

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı ID bulunamadı. Lütfen kullanıcıyı tekrar seçin.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (expertUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uzman kullanıcı ID bulunamadı.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final clinicId = await _resolveCurrentExpertClinicId();

      if (clinicId == null || clinicId <= 0) {
        throw Exception(
          'Klinik bilgisi bulunamadı. Lütfen Profil ekranından klinik bilginizi tamamlayın.',
        );
      }

      final session = MeasurementSession(
        sessionId: null,
        clinicId: clinicId,
        patientId: patientId,
        expertUserId: expertUserId,
        assignedOptityouUserId: null,
        sessionCode: _generateSessionCode(),
        sessionDate: _selectedDate,
        sessionTime: _formatTimeOfDay(_selectedTime),
        status: SessionStatuses.draft,
        has3dScan: false,
        hasPlantarCsv: false,
        hasInsolePhoto: false,
        orderCreated: false,
        clinicalInfoCompleted: false,
        designFormCompleted: false,
        completedAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedSession = await _sessionRepository.createSession(
        session: session,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${savedSession.sessionCode} oluşturuldu.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, savedSession);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oturum oluşturulamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    final bool patientLocked = widget.initialPatient != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Ölçüm Oturumu'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni ölçüm oturumu bilgileri',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kullanıcı, tarih ve saat bilgilerini girerek yeni bir ölçüm oturumu oluşturabilirsiniz.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<Patient>(
                  initialValue: _selectedPatient,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.patients.map((patient) {
                    return DropdownMenuItem<Patient>(
                      value: patient,
                      child: Text(
                        '${patient.fullName} (${patient.patientCode})',
                      ),
                    );
                  }).toList(),
                  onChanged: patientLocked
                      ? null
                      : (value) {
                          setState(() {
                            _selectedPatient = value;
                          });
                        },
                ),

                const SizedBox(height: 20),

                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2035),
                    );

                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Oturum Tarihi',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}.'
                      '${_selectedDate.month.toString().padLeft(2, '0')}.'
                      '${_selectedDate.year}',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );

                    if (picked != null) {
                      setState(() {
                        _selectedTime = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Oturum Saati',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedTime == null
                          ? 'Saat seçilmedi'
                          : _selectedTime!.format(context),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                FutureBuilder<int?>(
                  future: _resolveCurrentExpertClinicId(),
                  builder: (context, snapshot) {
                    final clinicId = snapshot.data;
                    final hasClinic = clinicId != null && clinicId > 0;

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildInfoBox(
                        color: Colors.blueGrey,
                        icon: Icons.hourglass_empty,
                        title: 'Klinik bilgisi kontrol ediliyor',
                        body:
                            'Yeni ölçüm oturumunun bağlanacağı klinik bilgisi okunuyor.',
                      );
                    }

                    if (!hasClinic) {
                      return _buildInfoBox(
                        color: Colors.orange,
                        icon: Icons.warning_amber_outlined,
                        title: 'Klinik bilgisi eksik',
                        body:
                            'Yeni ölçüm oturumu oluşturabilmek için önce Profil ekranından klinik bilginizi tamamlayın.',
                      );
                    }

                    return FutureBuilder<String?>(
                      future: _resolveCurrentExpertClinicName(
                        clinicId: clinicId,
                      ),
                      builder: (context, clinicNameSnapshot) {
                        final clinicName =
                            (clinicNameSnapshot.data ?? '').trim();

                        return _buildInfoBox(
                          color: Colors.teal,
                          icon: Icons.local_hospital_outlined,
                          title: 'Oturum bu klinikte oluşturulacak',
                          body: clinicName.isEmpty
                              ? 'Klinik ID: $clinicId\n'
                                  'Uzman: ${widget.currentUser.displayName}\n'
                                  'Yeni ölçüm oturumu başlangıç durumu: draft'
                              : 'Klinik: $clinicName\n'
                                  'Uzman: ${widget.currentUser.displayName}\n'
                                  'Yeni ölçüm oturumu başlangıç durumu: draft',
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _createSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Oturum Oluştur',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required Color color,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}