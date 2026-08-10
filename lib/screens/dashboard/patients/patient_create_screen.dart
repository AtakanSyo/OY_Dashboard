import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/models/patient_consent_request_model.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_consent_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientCreateScreen extends StatefulWidget {
  final AppUser currentUser;

  const PatientCreateScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<PatientCreateScreen> createState() => _PatientCreateScreenState();
}

class _PatientCreateScreenState extends State<PatientCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final SupabasePatientRepository _patientRepository =
      SupabasePatientRepository();
  final SupabasePatientConsentRepository _consentRepository =
      SupabasePatientConsentRepository();

  SupabaseClient get _client => Supabase.instance.client;

  DateTime? _birthDate;
  int? _selectedBirthDay;
  int? _selectedBirthMonth;
  int? _selectedBirthYear;

  String? _selectedGender;
  bool _isSaving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _generatePatientCode() {
    final now = DateTime.now();
    final short = now.millisecondsSinceEpoch.toString().substring(7);
    return 'PT-$short';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Doğum tarihi seçilmedi';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return true;

    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  List<int> _birthYearOptions() {
    final currentYear = DateTime.now().year;

    return List<int>.generate(
      currentYear - 1930 + 1,
      (index) => currentYear - index,
    );
  }

  List<int> _birthMonthOptions() {
    return List<int>.generate(12, (index) => index + 1);
  }

  List<int> _birthDayOptions() {
    final year = _selectedBirthYear ?? 2000;
    final month = _selectedBirthMonth ?? 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return List<int>.generate(daysInMonth, (index) => index + 1);
  }

  String _monthLabel(int month) {
    switch (month) {
      case 1:
        return 'Ocak';
      case 2:
        return 'Şubat';
      case 3:
        return 'Mart';
      case 4:
        return 'Nisan';
      case 5:
        return 'Mayıs';
      case 6:
        return 'Haziran';
      case 7:
        return 'Temmuz';
      case 8:
        return 'Ağustos';
      case 9:
        return 'Eylül';
      case 10:
        return 'Ekim';
      case 11:
        return 'Kasım';
      case 12:
        return 'Aralık';
      default:
        return month.toString();
    }
  }

  void _updateBirthDateFromParts() {
    final day = _selectedBirthDay;
    final month = _selectedBirthMonth;
    final year = _selectedBirthYear;

    if (day == null || month == null || year == null) {
      setState(() {
        _birthDate = null;
      });
      return;
    }

    final now = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final safeDay = day > daysInMonth ? daysInMonth : day;
    final selectedDate = DateTime(year, month, safeDay);

    if (selectedDate.isAfter(now)) {
      setState(() {
        _selectedBirthDay = now.day;
        _selectedBirthMonth = now.month;
        _selectedBirthYear = now.year;
        _birthDate = DateTime(now.year, now.month, now.day);
      });
      return;
    }

    setState(() {
      _selectedBirthDay = safeDay;
      _birthDate = selectedDate;
    });
  }

  void _clearBirthDate() {
    setState(() {
      _birthDate = null;
      _selectedBirthDay = null;
      _selectedBirthMonth = null;
      _selectedBirthYear = null;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1930),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Doğum tarihi seçin',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _selectedBirthDay = picked.day;
        _selectedBirthMonth = picked.month;
        _selectedBirthYear = picked.year;
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final email = _emailController.text.trim();

      final patient = Patient(
        patientId: null,
        clinicId: widget.currentUser.clinicId,
        createdByUserId: widget.currentUser.userId,
        patientCode: _generatePatientCode(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: email.isEmpty ? null : email,
        birthDate: _birthDate,
        gender: _selectedGender,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final savedPatient = await _patientRepository.createPatient(patient);

      String? consentLink;
      String? consentMessage;
      bool mailSent = false;

      if (email.isNotEmpty && savedPatient.patientId != null) {
        final patientName =
            '${savedPatient.firstName} ${savedPatient.lastName}'.trim();

        final request = await _createConsentRequest(
          patientId: savedPatient.patientId!,
          email: email,
          patientName: patientName,
        );

        consentLink = request.consentUrl;

        mailSent = await _sendConsentEmailIfAvailable(
          email: email,
          patientName: patientName,
          consentLink: consentLink,
          token: request.token,
          requestId: request.requestId,
        );

        consentMessage = mailSent
            ? 'KVKK ve sözleşme onay bağlantısı $email adresine iletildi.'
            : 'KVKK ve sözleşme onay bağlantısı oluşturuldu fakat e-posta gönderimi tamamlanamadı. Linki manuel olarak paylaşabilirsiniz.';
      } else if (email.isEmpty) {
        consentMessage =
            'Kullanıcı kaydı oluşturuldu. E-posta girilmediği için KVKK/onam bağlantısı oluşturulmadı.';
      } else {
        consentMessage =
            'Kullanıcı kaydı oluşturuldu fakat hasta ID bulunamadığı için KVKK/onam bağlantısı oluşturulamadı.';
      }

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      await _showSuccessDialog(
        patient: savedPatient,
        consentMessage: consentMessage,
        consentLink: consentLink,
        mailSent: mailSent,
      );

      if (!mounted) return;

      Navigator.pop(context, savedPatient);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı kaydı oluşturulamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<PatientConsentRequestModel> _createConsentRequest({
    required int patientId,
    required String email,
    required String patientName,
  }) async {
    final expertUserId = widget.currentUser.userId;

    if (expertUserId == null) {
      throw Exception('Uzman kullanıcı ID bulunamadı.');
    }

    return _consentRepository.createConsentRequest(
      patientId: patientId,
      expertUserId: expertUserId,
      email: email,
      patientName: patientName,
    );
  }

  Future<bool> _sendConsentEmailIfAvailable({
    required String email,
    required String patientName,
    required String consentLink,
    required String token,
    required int? requestId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-patient-consent-email',
        body: {
          'email': email,
          'patient_name': patientName,
          'consent_link': consentLink,
          'token': token,
          'request_id': requestId,
        },
      );

      final data = response.data;

      if (data is Map) {
        final ok = data['success'] == true || data['ok'] == true;
        return ok;
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showSuccessDialog({
    required Patient patient,
    required String? consentMessage,
    required String? consentLink,
    required bool mailSent,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Kullanıcı Kaydı Oluşturuldu'),
        content: SizedBox(
          width: 540,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    mailSent ? Icons.mark_email_read_outlined : Icons.info,
                    color: mailSent ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      consentMessage ?? 'Kullanıcı kaydı başarıyla oluşturuldu.',
                      style: const TextStyle(height: 1.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Kullanıcı: ${patient.firstName} ${patient.lastName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text('Kullanıcı Kodu: ${patient.patientCode}'),
              if (consentLink != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Onay Bağlantısı',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    consentLink,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text(
              'Tamam',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _emailController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Kullanıcı Kaydı'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kullanıcı Bilgileri',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yeni kullanıcı kaydı oluşturmak için aşağıdaki bilgileri doldurun.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Temel Bilgiler',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Ad',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ad zorunludur';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Soyad',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Soyad zorunludur';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Cinsiyet',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('Kadın'),
                            ),
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Erkek'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Diğer'),
                            ),
                            DropdownMenuItem(
                              value: 'unspecified',
                              child: Text('Belirtmek istemiyorum'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildBirthDateSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'İletişim Bilgileri',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                            helperText:
                                'KVKK ve sözleşme onayı bu adrese gönderilir.',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (text.isNotEmpty && !_isValidEmail(text)) {
                              return 'Geçerli bir e-posta adresi girin';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: email.isEmpty
                                ? Colors.orange.withOpacity(0.08)
                                : Colors.teal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: email.isEmpty
                                  ? Colors.orange.withOpacity(0.18)
                                  : Colors.teal.withOpacity(0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                email.isEmpty
                                    ? Icons.warning_amber_outlined
                                    : Icons.mark_email_read_outlined,
                                color: email.isEmpty
                                    ? Colors.orange.shade800
                                    : Colors.teal,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  email.isEmpty
                                      ? 'E-posta girilmezse KVKK ve sözleşme onay bağlantısı oluşturulmaz.'
                                      : 'Kayıt sonrası KVKK ve sözleşme onay bağlantısı $email adresine gönderilmeye çalışılır.',
                                  style: TextStyle(
                                    color: email.isEmpty
                                        ? Colors.orange.shade900
                                        : Colors.teal.shade900,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefon',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Notlar',
                    child: TextFormField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı notu',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: 'Kayıt Özeti',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Klinik ID: ${widget.currentUser.clinicId ?? '-'}'),
                        const SizedBox(height: 6),
                        Text(
                          'Kaydı oluşturan kullanıcı: ${widget.currentUser.displayName}',
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kullanıcı kodu kayıt sırasında otomatik üretilecektir.',
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'E-posta varsa KVKK/onam bağlantısı kayıt sonrası oluşturulacaktır.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePatient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kullanıcı Kaydını Oluştur',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthDateSelector() {
    final days = _birthDayOptions();
    final months = _birthMonthOptions();
    final years = _birthYearOptions();

    final dayValue = _selectedBirthDay != null && days.contains(_selectedBirthDay)
        ? _selectedBirthDay
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 560;

        final dayField = DropdownButtonFormField<int>(
          initialValue: dayValue,
          decoration: const InputDecoration(
            labelText: 'Gün',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: days
              .map(
                (day) => DropdownMenuItem<int>(
                  value: day,
                  child: Text(day.toString().padLeft(2, '0')),
                ),
              )
              .toList(),
          onChanged: (value) {
            _selectedBirthDay = value;
            _updateBirthDateFromParts();
          },
        );

        final monthField = DropdownButtonFormField<int>(
          initialValue: _selectedBirthMonth,
          decoration: const InputDecoration(
            labelText: 'Ay',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: months
              .map(
                (month) => DropdownMenuItem<int>(
                  value: month,
                  child: Text(_monthLabel(month)),
                ),
              )
              .toList(),
          onChanged: (value) {
            _selectedBirthMonth = value;
            _updateBirthDateFromParts();
          },
        );

        final yearField = DropdownButtonFormField<int>(
          initialValue: _selectedBirthYear,
          decoration: const InputDecoration(
            labelText: 'Yıl',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: years
              .map(
                (year) => DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                ),
              )
              .toList(),
          onChanged: (value) {
            _selectedBirthYear = value;
            _updateBirthDateFromParts();
          },
        );

        final calendarButton = OutlinedButton.icon(
          onPressed: _pickBirthDate,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Takvim'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
          ),
        );

        final clearButton = IconButton(
          tooltip: 'Doğum tarihini temizle',
          onPressed: _birthDate == null ? null : _clearBirthDate,
          icon: const Icon(Icons.close),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doğum Tarihi',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (isNarrow)
              Column(
                children: [
                  dayField,
                  const SizedBox(height: 10),
                  monthField,
                  const SizedBox(height: 10),
                  yearField,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: calendarButton),
                      const SizedBox(width: 8),
                      clearButton,
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: dayField),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: monthField),
                  const SizedBox(width: 10),
                  Expanded(child: yearField),
                  const SizedBox(width: 10),
                  calendarButton,
                  const SizedBox(width: 4),
                  clearButton,
                ],
              ),
            const SizedBox(height: 8),
            Text(
              _birthDate == null
                  ? 'Doğum tarihi isteğe bağlıdır.'
                  : 'Seçilen tarih: ${_formatDate(_birthDate)}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
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
}