import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
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
  static const String _appBaseUrl = 'https://optiyou.fit';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final SupabasePatientRepository _patientRepository =
      SupabasePatientRepository();

  SupabaseClient get _client => Supabase.instance.client;

  DateTime? _birthDate;
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

  String _generateConsentToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final encoded = base64UrlEncode(bytes).replaceAll('=', '');
    return 'consent_$encoded';
  }

  String _buildConsentLink(String token) {
    return '$_appBaseUrl/#/legal-consent?token=$token';
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

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
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
        final request = await _createConsentRequest(
          patientId: savedPatient.patientId!,
          email: email,
        );

        consentLink = request.link;

        mailSent = await _sendConsentEmailIfAvailable(
          email: email,
          patientName:
              '${savedPatient.firstName} ${savedPatient.lastName}'.trim(),
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

  Future<_ConsentRequestResult> _createConsentRequest({
    required int patientId,
    required String email,
  }) async {
    final expertUserId = widget.currentUser.userId;

    if (expertUserId == null) {
      throw Exception('Uzman kullanıcı ID bulunamadı.');
    }

    final token = _generateConsentToken();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 14));
    final link = _buildConsentLink(token);

    final response = await _client
        .from('patient_consent_requests')
        .insert({
          'patient_id': patientId,
          'expert_user_id': expertUserId,
          'email': email,
          'token': token,
          'status': 'pending',
          'expires_at': expiresAt.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .select('id, token')
        .maybeSingle();

    if (response == null) {
      throw Exception('KVKK/onam isteği oluşturulamadı.');
    }

    final map = Map<String, dynamic>.from(response as Map);

    return _ConsentRequestResult(
      requestId: int.tryParse(map['id'].toString()),
      token: map['token']?.toString() ?? token,
      link: link,
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
                        InkWell(
                          onTap: _pickBirthDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Doğum Tarihi',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(_formatDate(_birthDate)),
                          ),
                        ),
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

class _ConsentRequestResult {
  final int? requestId;
  final String token;
  final String link;

  const _ConsentRequestResult({
    required this.requestId,
    required this.token,
    required this.link,
  });
}