import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/models/patient.dart';

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

  Future<void> _createSession() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir hasta seçin.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    final session = MeasurementSession(
      sessionId: DateTime.now().millisecondsSinceEpoch,
      clinicId: widget.currentUser.clinicId ?? 0,
      patientId: _selectedPatient!.patientId ?? 0,
      expertUserId: widget.currentUser.userId ?? 0,
      assignedOptityouUserId: null,
      sessionCode: _generateSessionCode(),
      sessionDate: _selectedDate,
      sessionTime: _formatTimeOfDay(_selectedTime),
      status: SessionStatuses.draft,
      has3dScan: false,
      hasPlantarCsv: false,
      hasInsolePhoto: false,
      orderCreated: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    Navigator.pop(context, session);
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
                  'Yeni oturum bilgileri',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hasta, tarih ve saat bilgilerini girerek yeni bir ölçüm oturumu oluşturabilirsiniz.',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<Patient>(
                  initialValue: _selectedPatient,
                  decoration: const InputDecoration(
                    labelText: 'Hasta',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.patients.map((patient) {
                    return DropdownMenuItem<Patient>(
                      value: patient,
                      child: Text('${patient.fullName} (${patient.patientCode})'),
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

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Klinik ID: ${widget.currentUser.clinicId ?? '-'}\n'
                    'Uzman: ${widget.currentUser.displayName}\n'
                    'Yeni oturum başlangıç durumu: draft',
                    style: const TextStyle(height: 1.5),
                  ),
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
}