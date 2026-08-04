import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/screens/dashboard/session_analysis_results_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class OptiYouMeasurementReviewScreen extends StatefulWidget {
  final AppUser currentUser;
  final MeasurementSession session;

  const OptiYouMeasurementReviewScreen({
    super.key,
    required this.currentUser,
    required this.session,
  });

  @override
  State<OptiYouMeasurementReviewScreen> createState() =>
      _OptiYouMeasurementReviewScreenState();
}

class _OptiYouMeasurementReviewScreenState
    extends State<OptiYouMeasurementReviewScreen> {
  SupabaseClient get _client => Supabase.instance.client;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _patient;
  Map<String, dynamic>? _clinic;
  Map<String, dynamic>? _expert;
  Map<String, dynamic>? _clinicalInfo;
  Map<String, dynamic>? _designForm;

  List<Map<String, dynamic>> _scanFiles = [];
  List<Map<String, dynamic>> _pressureRecordings = [];
  List<Map<String, dynamic>> _referencePhotos = [];

  late int _currentClinicId;

  MeasurementSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    _currentClinicId = widget.session.clinicId;
    _loadReviewData();
  }

  Future<void> _loadReviewData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sessionId = session.sessionId;

      if (sessionId == null) {
        throw Exception('Oturum ID bulunamadı.');
      }

      final freshSessionResponse = await _client
          .from('measurement_sessions')
          .select('id, clinic_id')
          .eq('id', sessionId)
          .maybeSingle();

      final freshSessionRow = freshSessionResponse == null
          ? null
          : Map<String, dynamic>.from(freshSessionResponse as Map);

      final freshClinicId =
          _asInt(freshSessionRow?['clinic_id']) ?? _currentClinicId;

      _currentClinicId = freshClinicId;

      final results = await Future.wait<dynamic>([
        _fetchSingleById(
          table: 'patients',
          idColumn: 'id',
          id: session.patientId,
        ),
        _fetchSingleById(
          table: 'clinics',
          idColumn: 'id',
          id: _currentClinicId,
        ),
        _fetchSingleById(
          table: 'user_profiles_full',
          idColumn: 'user_id',
          id: session.expertUserId,
        ),
        _fetchLatestBySession(
          table: 'anthropometric_clinical_infos',
          sessionId: sessionId,
          orderBy: 'created_at',
        ),
        _fetchLatestBySession(
          table: 'orthotic_design_forms',
          sessionId: sessionId,
          orderBy: 'created_at',
        ),
        _fetchRowsBySession(
          table: 'session_scan_files',
          sessionId: sessionId,
          orderBy: 'created_at',
        ),
        _fetchRowsBySession(
          table: 'session_pressure_recordings',
          sessionId: sessionId,
          orderBy: 'recorded_at',
        ),
        _fetchRowsBySession(
          table: 'session_reference_photos',
          sessionId: sessionId,
          orderBy: 'created_at',
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _patient = results[0] as Map<String, dynamic>?;
        _clinic = results[1] as Map<String, dynamic>?;
        _expert = results[2] as Map<String, dynamic>?;
        _clinicalInfo = results[3] as Map<String, dynamic>?;
        _designForm = results[4] as Map<String, dynamic>?;
        _scanFiles = results[5] as List<Map<String, dynamic>>;
        _pressureRecordings = results[6] as List<Map<String, dynamic>>;
        _referencePhotos = results[7] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Ölçüm inceleme verileri yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchSingleById({
    required String table,
    required String idColumn,
    required int id,
  }) async {
    if (id <= 0) return null;

    try {
      final response = await _client
          .from(table)
          .select()
          .eq(idColumn, id)
          .maybeSingle();

      if (response == null) return null;

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      debugPrint('Review fetchSingle error [$table]: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchLatestBySession({
    required String table,
    required int sessionId,
    required String orderBy,
  }) async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('session_id', sessionId)
          .order(orderBy, ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      debugPrint('Review fetchLatest error [$table]: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRowsBySession({
    required String table,
    required int sessionId,
    required String orderBy,
  }) async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('session_id', sessionId)
          .order(orderBy, ascending: false);

      return (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      debugPrint('Review fetchRows error [$table]: $e');
      return <Map<String, dynamic>>[];
    }
  }

  void _openAnalysisResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionAnalysisResultsScreen(
          currentUser: widget.currentUser,
          session: session,
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchClinics() async {
    try {
      final response = await _client
          .from('clinics')
          .select('id, clinic_code, clinic_name, clinic_type')
          .order('clinic_name', ascending: true);

      return (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (e) {
      debugPrint('Clinic list fetch error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  String _generateClinicCode(String clinicName) {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString();

    final cleaned = clinicName
        .trim()
        .toUpperCase()
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ş', 'S')
        .replaceAll('İ', 'I')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    if (cleaned.isEmpty) {
      return 'CLN-$suffix';
    }

    final prefix = cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned;
    return '$prefix-$suffix';
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  String _clinicRowLabel(Map<String, dynamic> clinic) {
    final name = (clinic['clinic_name'] ?? '').toString().trim();
    final code = (clinic['clinic_code'] ?? '').toString().trim();

    if (name.isNotEmpty && code.isNotEmpty) return '$name ($code)';
    if (name.isNotEmpty) return name;
    if (code.isNotEmpty) return code;

    return 'Klinik #${clinic['id']}';
  }

  Future<Map<String, dynamic>> _createClinic({
    required String clinicName,
    required String clinicCode,
    required String clinicType,
  }) async {
    final normalizedName = clinicName.trim();
    final normalizedType = clinicType.trim();
    final normalizedCode = clinicCode.trim().isEmpty
        ? _generateClinicCode(normalizedName)
        : clinicCode.trim();

    if (normalizedName.isEmpty) {
      throw Exception('Klinik adı boş olamaz.');
    }

    if (normalizedType.isEmpty) {
      throw Exception('Klinik tipi seçilmelidir.');
    }

    final response = await _client
        .from('clinics')
        .insert({
          'clinic_code': normalizedCode,
          'clinic_name': normalizedName,
          'clinic_type': normalizedType,
        })
        .select('id, clinic_code, clinic_name, clinic_type')
        .single();

    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> _updateSessionClinic({
    required int clinicId,
    required Map<String, dynamic> clinicRow,
  }) async {
    final sessionId = session.sessionId;

    if (sessionId == null) {
      _showMessage('Oturum ID bulunamadı.');
      return;
    }

    await _client
        .from('measurement_sessions')
        .update({
          'clinic_id': clinicId,
        })
        .eq('id', sessionId);

    Map<String, dynamic>? freshSessionRow;

    try {
      final freshSessionResponse = await _client
          .from('measurement_sessions')
          .select('id, clinic_id')
          .eq('id', sessionId)
          .limit(1);

      final rows = freshSessionResponse as List<dynamic>;

      if (rows.isNotEmpty) {
        freshSessionRow = Map<String, dynamic>.from(rows.first as Map);
      }
    } catch (e) {
      debugPrint('Session clinic verify skipped: $e');
    }

    if (freshSessionRow == null) {
      throw Exception(
        'Klinik güncellemesi doğrulanamadı. measurement_sessions için SELECT/UPDATE RLS policy kontrol edilmeli.',
      );
    }

    final updatedClinicId = _asInt(freshSessionRow['clinic_id']);

    if (updatedClinicId != clinicId) {
      throw Exception(
        'Klinik güncellenmedi. Beklenen clinic_id: $clinicId, mevcut clinic_id: $updatedClinicId. RLS UPDATE policy kontrol edilmeli.',
      );
    }

    try {
      await _client
          .from('orders')
          .update({
            'clinic_id': clinicId,
          })
          .eq('session_id', sessionId);
    } catch (e) {
      debugPrint('Related order clinic update skipped: $e');
    }

    if (!mounted) return;

    setState(() {
      _currentClinicId = clinicId;
      _clinic = clinicRow;
    });

    _showMessage('Klinik bilgisi güncellendi.');
  }

  Future<void> _openClinicEditDialog() async {
    bool isLoadingClinics = true;
    bool isSaving = false;
    bool createNewClinic = false;
    bool didStartLoading = false;

    List<Map<String, dynamic>> clinics = [];
    int? selectedClinicId = _currentClinicId > 0 ? _currentClinicId : null;

    final clinicNameController = TextEditingController();
    final clinicCodeController = TextEditingController();

    final allowedTypes = _ClinicTypeOption.values.map((e) => e.value).toSet();
    String selectedClinicType = allowedTypes.contains(
      (_clinic?['clinic_type'] ?? '').toString().trim(),
    )
        ? (_clinic?['clinic_type'] ?? '').toString().trim()
        : 'clinic';

    Future<void> loadClinics(StateSetter dialogSetState) async {
      final rows = await _fetchClinics();

      if (!mounted) return;

      dialogSetState(() {
        clinics = rows;
        isLoadingClinics = false;

        final hasCurrentClinic = clinics.any((clinic) {
          return _asInt(clinic['id']) == selectedClinicId;
        });

        if (!hasCurrentClinic && clinics.isNotEmpty) {
          selectedClinicId = _asInt(clinics.first['id']);
        }
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            if (!didStartLoading) {
              didStartLoading = true;
              Future.microtask(() => loadClinics(dialogSetState));
            }

            return AlertDialog(
              title: const Text('Klinik Bilgisini Düzenle'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          'Mevcut klinik: ${_clinicDisplayName()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            icon: Icon(Icons.local_hospital_outlined),
                            label: Text('Mevcut Klinik'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            icon: Icon(Icons.add_business_outlined),
                            label: Text('Yeni Klinik'),
                          ),
                        ],
                        selected: {createNewClinic},
                        onSelectionChanged: isSaving
                            ? null
                            : (value) {
                                dialogSetState(() {
                                  createNewClinic = value.first;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      if (!createNewClinic)
                        isLoadingClinics
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              )
                            : clinics.isEmpty
                                ? _buildEmptyState(
                                    'Kayıtlı klinik bulunamadı. Yeni klinik oluşturabilirsiniz.',
                                  )
                                : DropdownButtonFormField<int>(
                                    initialValue: selectedClinicId,
                                    decoration: const InputDecoration(
                                      labelText: 'Klinik Seç',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: clinics.map((clinic) {
                                      final id = _asInt(clinic['id']) ?? 0;

                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(_clinicRowLabel(clinic)),
                                      );
                                    }).toList(),
                                    onChanged: isSaving
                                        ? null
                                        : (value) {
                                            dialogSetState(() {
                                              selectedClinicId = value;
                                            });
                                          },
                                  )
                      else ...[
                        TextField(
                          controller: clinicNameController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Klinik adı',
                            hintText: 'Örn. Galen Hastanesi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: selectedClinicType,
                          decoration: const InputDecoration(
                            labelText: 'Klinik tipi',
                            border: OutlineInputBorder(),
                          ),
                          items: _ClinicTypeOption.values.map((option) {
                            return DropdownMenuItem<String>(
                              value: option.value,
                              child: Text(option.label),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;

                                  dialogSetState(() {
                                    selectedClinicType = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: clinicCodeController,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Klinik kodu',
                            hintText: 'Boş bırakılırsa otomatik oluşturulur',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Kaydedildiğinde bu ölçüm oturumunun clinic_id değeri güncellenir. Aynı oturuma bağlı sipariş kaydı varsa order.clinic_id de eşitlenmeye çalışılır.',
                        style: TextStyle(
                          color: Colors.grey[700],
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          dialogSetState(() {
                            isSaving = true;
                          });

                          try {
                            Map<String, dynamic> selectedClinicRow;

                            if (createNewClinic) {
                              selectedClinicRow = await _createClinic(
                                clinicName: clinicNameController.text,
                                clinicCode: clinicCodeController.text,
                                clinicType: selectedClinicType,
                              );
                            } else {
                              final id = selectedClinicId;

                              if (id == null || id <= 0) {
                                throw Exception('Lütfen bir klinik seçin.');
                              }

                              selectedClinicRow = clinics.firstWhere(
                                (clinic) => _asInt(clinic['id']) == id,
                                orElse: () => <String, dynamic>{},
                              );

                              if (selectedClinicRow.isEmpty) {
                                throw Exception('Seçilen klinik bulunamadı.');
                              }
                            }

                            final clinicId = _asInt(selectedClinicRow['id']);

                            if (clinicId == null || clinicId <= 0) {
                              throw Exception('Klinik ID alınamadı.');
                            }

                            await _updateSessionClinic(
                              clinicId: clinicId,
                              clinicRow: selectedClinicRow,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                          } catch (e) {
                            if (!mounted) return;

                            _showMessage('Klinik güncellenemedi: $e');

                            if (!dialogContext.mounted) return;

                            dialogSetState(() {
                              isSaving = false;
                            });
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving ? 'Kaydediliyor' : 'Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    clinicNameController.dispose();
    clinicCodeController.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '—';

    final date = value is DateTime ? value : DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
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

  String _patientDisplayName() {
    final firstName = (_patient?['first_name'] ?? '').toString().trim();
    final lastName = (_patient?['last_name'] ?? '').toString().trim();
    final code = (_patient?['patient_code'] ?? '').toString().trim();

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty && code.isNotEmpty) return '$fullName ($code)';
    if (fullName.isNotEmpty) return fullName;
    if (code.isNotEmpty) return code;

    return 'Hasta #${session.patientId}';
  }

  String _clinicDisplayName() {
    final name = (_clinic?['clinic_name'] ?? '').toString().trim();
    final code = (_clinic?['clinic_code'] ?? '').toString().trim();

    if (name.isNotEmpty && code.isNotEmpty) return '$name ($code)';
    if (name.isNotEmpty) return name;
    if (code.isNotEmpty) return code;

    return _currentClinicId > 0
        ? 'Klinik #$_currentClinicId'
        : 'Klinik bilgisi yok';
  }

  String _expertDisplayName() {
    final firstName = (_expert?['first_name'] ?? '').toString().trim();
    final lastName = (_expert?['last_name'] ?? '').toString().trim();
    final title = (_expert?['title'] ?? '').toString().trim();
    final email = (_expert?['email'] ?? '').toString().trim();

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty && title.isNotEmpty) return '$title $fullName';
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'Uzman #${session.expertUserId}';
  }

  String _compactValue(dynamic value) {
    if (value == null) return '—';

    if (value is bool) return value ? 'Evet' : 'Hayır';

    if (value is DateTime) return _formatDateTime(value);

    if (value is List) {
      if (value.isEmpty) return '—';
      return value.map(_compactValue).join(', ');
    }

    if (value is Map) {
      if (value.isEmpty) return '—';

      return value.entries
          .where((entry) => _compactValue(entry.value) != '—')
          .map(
            (entry) =>
                '${_labelForKey(entry.key.toString())}: ${_compactValue(entry.value)}',
          )
          .join('\n');
    }

    final text = value.toString().trim();

    if (text.isEmpty) return '—';

    final parsedDate = DateTime.tryParse(text);
    if (parsedDate != null && text.contains('-')) {
      return _formatDateTime(parsedDate);
    }

    return text;
  }

  String _labelForKey(String key) {
    const labels = {
      'first_name': 'Ad',
      'last_name': 'Soyad',
      'patient_code': 'Hasta Kodu',
      'email': 'E-posta',
      'phone': 'Telefon',
      'clinic_name': 'Klinik Adı',
      'clinic_code': 'Klinik Kodu',
      'clinic_type': 'Klinik Tipi',
      'session_code': 'Oturum Kodu',
      'session_date': 'Oturum Tarihi',
      'session_time': 'Oturum Saati',
      'status': 'Durum',
      'height_cm': 'Boy',
      'weight_kg': 'Kilo',
      'bmi': 'BMI',
      'shoe_size_eu': 'Ayakkabı Numarası',
      'foot_size': 'Ayak Numarası',
      'chief_complaint': 'Ana Şikayet',
      'complaint': 'Şikayet',
      'diagnosis': 'Tanı',
      'clinical_evaluation': 'Klinik Değerlendirme',
      'clinical_notes': 'Klinik Not',
      'expert_notes': 'Uzman Notu',
      'notes': 'Not',
      'dominant_foot': 'Baskın Ayak',
      'activity_level': 'Aktivite Seviyesi',
      'occupation': 'Meslek',
      'pain_level': 'Ağrı Seviyesi',
      'pain_location': 'Ağrı Bölgesi',
      'approved_for_order': 'Siparişe Onaylı',
      'overall_summary': 'Genel Özet',
      'general_risk_note': 'Genel Risk Notu',
      'location_label': 'Lokasyon',
      'file_type': 'Dosya Tipi',
      'file_name': 'Dosya Adı',
      'mime_type': 'Dosya Formatı',
      'size_bytes': 'Boyut',
      'upload_status': 'Yükleme Durumu',
      'title': 'Başlık',
      'frame_count': 'Frame Sayısı',
      'duration_ms': 'Süre',
      'max_pressure': 'Maksimum Basınç',
      'avg_pressure': 'Ortalama Basınç',
      'recorded_at': 'Kayıt Tarihi',
      'created_at': 'Oluşturulma',
      'updated_at': 'Güncellenme',
    };

    if (labels.containsKey(key)) return labels[key]!;

    return key
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  bool _shouldHideTechnicalKey(String key) {
    const hidden = {
      'id',
      'session_id',
      'patient_id',
      'expert_user_id',
      'user_id',
      'auth_id',
      'role_id',
      'clinic_id',
      'assigned_optityou_user_id',
      'storage_bucket',
      'storage_path',
      'public_url',
      'signed_url_expires_at',
      'raw_text',
      'raw_frames_json',
      'ai_recommendation_json',
      'design_parameters_json',
    };

    return hidden.contains(key);
  }

  bool _isClinicalPathologyKey(String key) {
    final normalized = key.toLowerCase();

    const patterns = [
      'pathology',
      'patoloji',
      'pes_planus',
      'flat_foot',
      'düz_taban',
      'duz_taban',
      'pes_cavus',
      'high_arch',
      'hallux_valgus',
      'halluks_valgus',
      'bunion',
      'plantar_fasciitis',
      'plantar_fasiit',
      'heel_spur',
      'calcaneal_spur',
      'topuk_dikeni',
      'metatarsalgia',
      'morton',
      'neuroma',
      'neuropathy',
      'neuropati',
      'diabetic',
      'diyabet',
      'pronation',
      'pronasyon',
      'supination',
      'supinasyon',
      'valgus',
      'varus',
      'hammertoe',
      'hammer_toe',
      'çekiç',
      'cekic',
      'achilles',
      'aşil',
      'asil',
      'knee_pain',
      'diz',
      'hip_pain',
      'kalça',
      'kalca',
      'low_back',
      'bel',
      'leg_length',
      'bacak_boyu',
    ];

    return patterns.any(normalized.contains);
  }

  List<String> _clinicalPathologyChips() {
    final data = _clinicalInfo;
    if (data == null) return [];

    final chips = <String>[];

    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;

      if (_shouldHideTechnicalKey(key)) continue;

      if (value is bool && value == true && _isClinicalPathologyKey(key)) {
        chips.add(_labelForKey(key));
      }

      if (_isClinicalPathologyKey(key) && value is List && value.isNotEmpty) {
        chips.addAll(
          value
              .map((item) => _compactValue(item))
              .where((item) => item.trim().isNotEmpty && item != '—'),
        );
      }

      if (_isClinicalPathologyKey(key) &&
          value is String &&
          value.trim().isNotEmpty &&
          value.trim() != 'false' &&
          value.trim() != '0') {
        chips.add(value.trim());
      }
    }

    return chips.toSet().toList();
  }

  List<MapEntry<String, dynamic>> _visibleClinicalEntries() {
    final data = _clinicalInfo;
    if (data == null) return [];

    return data.entries.where((entry) {
      final key = entry.key;
      final value = entry.value;

      if (_shouldHideTechnicalKey(key)) return false;
      if (_isClinicalPathologyKey(key)) return false;

      if (value is bool) {
        return value == true;
      }

      return _compactValue(value) != '—';
    }).toList();
  }

  Future<void> _openStorageFile(Map<String, dynamic> row) async {
    try {
      final publicUrl = (row['public_url'] ?? '').toString().trim();

      if (publicUrl.isNotEmpty) {
        await _openUrl(publicUrl);
        return;
      }

      final bucket = (row['storage_bucket'] ?? '').toString().trim();
      final path = (row['storage_path'] ?? '').toString().trim();

      if (bucket.isEmpty || path.isEmpty) {
        _showMessage('Bu kayıt için storage bilgisi bulunamadı.');
        return;
      }

      final signedUrl = await _client.storage.from(bucket).createSignedUrl(
            path,
            3600,
          );

      await _openUrl(signedUrl);
    } catch (e) {
      _showMessage('Dosya açılamadı: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      _showMessage('Bağlantı açılamadı.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Map<String, dynamic> _mapFromJson(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _designParameters() {
    final raw = _designForm?['design_parameters_json'] ??
        _designForm?['ai_recommendation_json'];

    if (raw == null) return <String, dynamic>{};

    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      final root = _mapFromJson(decoded);

      if (root.isEmpty) return <String, dynamic>{};

      if (root['design_parameters'] != null) {
        return _mapFromJson(root['design_parameters']);
      }

      return root;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  num? _asNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;

    return num.tryParse(value.toString().replaceAll(',', '.'));
  }

  bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;

    final text = value.toString().toLowerCase().trim();

    return text == 'true' || text == '1' || text == 'yes' || text == 'evet';
  }

  bool _hasNonZero(dynamic value) {
    final number = _asNum(value);
    if (number == null) return false;

    return number != 0;
  }

  String _formatNumber(dynamic value) {
    final number = _asNum(value);

    if (number == null) return '—';

    if (number % 1 == 0) return number.toInt().toString();

    return number.toString();
  }

  String _formatMm(dynamic value) {
    final number = _asNum(value);

    if (number == null) return '—';

    final text = number % 1 == 0 ? number.toInt().toString() : number.toString();

    if (number > 0) return '+$text mm';
    return '$text mm';
  }

  String _formatDegree(dynamic value) {
    final number = _asNum(value);

    if (number == null) return '—';

    final text = number % 1 == 0 ? number.toInt().toString() : number.toString();

    return '$text°';
  }

  Widget _buildHeaderCard() {
    final statusColor = _statusColor(session.effectiveStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: statusColor.withOpacity(0.12),
            child: Icon(
              Icons.fact_check_outlined,
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
                  session.sessionCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_patientDisplayName()} • ${_clinicDisplayName()}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 6),
                Text(
                  'Uzman: ${_expertDisplayName()}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
                  _statusLabel(session.effectiveStatus),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _openAnalysisResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('Analiz Sonuçlarını Aç'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _buildSectionCard(
      title: 'Ölçüm Özeti',
      icon: Icons.summarize_outlined,
      child: Column(
        children: [
          _buildInfoRow('Hasta', _patientDisplayName()),
          _buildInfoRow('Klinik', _clinicDisplayName()),
          _buildInfoRow('Uzman', _expertDisplayName()),
          const Divider(height: 22),
          _buildInfoRow('Oturum Kodu', session.sessionCode),
          _buildInfoRow(
            'Oturum Tarihi',
            '${_formatDate(session.sessionDate)}'
            '${session.sessionTime != null ? ' • ${session.sessionTime}' : ''}',
          ),
          _buildInfoRow('Durum', _statusLabel(session.effectiveStatus)),
          _buildInfoRow('Tamamlanma', _formatDate(session.completedAt)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openAnalysisResults,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Analiz Sonuçlarını Görüntüle'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openClinicEditDialog,
              icon: const Icon(Icons.local_hospital_outlined),
              label: const Text('Klinik Bilgisini Düzenle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepStatusCard() {
    final steps = [
      _StepStatusRow(
        'Klinik / Antropometrik Bilgiler',
        session.clinicalInfoCompleted,
      ),
      _StepStatusRow('3D Scan', session.has3dScan),
      _StepStatusRow('Plantar Basınç', session.hasPlantarCsv),
      _StepStatusRow('Referans Fotoğraf', session.hasInsolePhoto),
      _StepStatusRow('Tasarım Formu', session.designFormCompleted),
      _StepStatusRow('Ölçüm Onayı', session.orderCreated),
    ];

    return _buildSectionCard(
      title: 'Adım Durumları',
      icon: Icons.checklist_outlined,
      child: Column(
        children: steps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    step.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: step.done
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    step.done ? 'Tamamlandı' : 'Eksik',
                    style: TextStyle(
                      color: step.done
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClinicalInfoCard() {
    final pathologyChips = _clinicalPathologyChips();
    final entries = _visibleClinicalEntries();

    return _buildSectionCard(
      title: 'Klinik / Antropometrik Bilgiler',
      icon: Icons.monitor_weight_outlined,
      child: _clinicalInfo == null
          ? _buildEmptyState(
              'Bu oturum için klinik / antropometrik bilgi kaydı bulunamadı.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entries.isEmpty && pathologyChips.isEmpty)
                  _buildEmptyState('Gösterilecek klinik bilgi bulunamadı.'),
                if (entries.isNotEmpty)
                  ...entries.map((entry) {
                    return _buildInfoRow(
                      _labelForKey(entry.key),
                      _compactValue(entry.value),
                    );
                  }),
                if (pathologyChips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'İşaretli Patolojiler',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pathologyChips.map((label) {
                      return Chip(
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 17,
                          color: Colors.teal,
                        ),
                        label: Text(label),
                        backgroundColor: Colors.teal.withOpacity(0.08),
                        side: BorderSide(
                          color: Colors.teal.withOpacity(0.18),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildDesignFormCard() {
    if (_designForm == null) {
      return _buildSectionCard(
        title: 'Ortez Tasarım Formu',
        icon: Icons.design_services_outlined,
        child: _buildEmptyState('Bu oturum için ortez tasarım formu bulunamadı.'),
      );
    }

    final params = _designParameters();
    final cards = _buildDesignFeatureCards(params);
    final expertNotes = (_designForm?['expert_notes'] ?? '').toString().trim();
    final approvedForOrder = _asBool(_designForm?['approved_for_order']);

    return _buildSectionCard(
      title: 'Ortez Tasarım Formu',
      icon: Icons.design_services_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (approvedForOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                avatar: const Icon(
                  Icons.verified_outlined,
                  size: 17,
                  color: Colors.green,
                ),
                label: const Text('Siparişe onaylı'),
                backgroundColor: Colors.green.withOpacity(0.10),
                side: BorderSide(
                  color: Colors.green.withOpacity(0.20),
                ),
              ),
            ),
          if (cards.isEmpty)
            _buildEmptyState(
              'Tasarım parametresi bulunamadı. Form kaydı var ancak üretim parametreleri boş görünüyor.',
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards,
            ),
          if (expertNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.blueGrey.withOpacity(0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uzman Notu',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    expertNotes,
                    style: const TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDesignFeatureCards(Map<String, dynamic> params) {
    final cards = <Widget>[];

    final medialArch = _mapFromJson(params['medial_arch']);
    final lateralArch = _mapFromJson(params['lateral_arch']);
    final heelCup = _mapFromJson(params['heel_cup']);
    final gait = _mapFromJson(params['gait']);
    final flanges = _mapFromJson(params['flanges']);
    final pads = _mapFromJson(params['pads']);

    final medialLeft = medialArch['left_mm'];
    final medialRight = medialArch['right_mm'];

    if (_hasNonZero(medialLeft) || _hasNonZero(medialRight)) {
      cards.add(
        _buildDesignFeatureCard(
          icon: Icons.architecture_outlined,
          title: 'Medial Ark',
          values: [
            _SideValue('Sol', _formatMm(medialLeft)),
            _SideValue('Sağ', _formatMm(medialRight)),
          ],
        ),
      );
    }

    final lateralLeft = lateralArch['left_mm'];
    final lateralRight = lateralArch['right_mm'];

    if (_hasNonZero(lateralLeft) || _hasNonZero(lateralRight)) {
      cards.add(
        _buildDesignFeatureCard(
          icon: Icons.swap_horiz_outlined,
          title: 'Lateral Ark',
          values: [
            _SideValue('Sol', _formatMm(lateralLeft)),
            _SideValue('Sağ', _formatMm(lateralRight)),
          ],
        ),
      );
    }

    final heelCupHeight =
        heelCup['height_mm'] ?? _designForm?['deep_heel_cup_mm'];

    if (heelCupHeight != null) {
      cards.add(
        _buildDesignFeatureCard(
          icon: Icons.height_outlined,
          title: 'Topuk Yüksekliği',
          values: [
            _SideValue(
              'Heel Cup',
              '${_formatNumber(heelCupHeight)} mm',
            ),
          ],
        ),
      );
    }

    final noValgusVarus = _asBool(gait['no_valgus_varus']);

    final pronationLeft = gait['pronation_left_degree'];
    final pronationRight = gait['pronation_right_degree'];
    final supinationLeft = gait['supination_left_degree'];
    final supinationRight = gait['supination_right_degree'];

    if (!noValgusVarus &&
        (_hasNonZero(pronationLeft) ||
            _hasNonZero(pronationRight) ||
            _hasNonZero(supinationLeft) ||
            _hasNonZero(supinationRight))) {
      cards.add(
        _buildDesignFeatureCard(
          icon: Icons.directions_walk_outlined,
          title: 'Basış Düzeltmesi',
          values: [
            if (_hasNonZero(pronationLeft))
              _SideValue('Sol Pronasyon', _formatDegree(pronationLeft)),
            if (_hasNonZero(pronationRight))
              _SideValue('Sağ Pronasyon', _formatDegree(pronationRight)),
            if (_hasNonZero(supinationLeft))
              _SideValue('Sol Supinasyon', _formatDegree(supinationLeft)),
            if (_hasNonZero(supinationRight))
              _SideValue('Sağ Supinasyon', _formatDegree(supinationRight)),
          ],
        ),
      );
    }

    final flangeNotRequired = _asBool(flanges['not_required']);

    final medialFlangeLeft = flanges['medial_left_mm'];
    final medialFlangeRight = flanges['medial_right_mm'];
    final lateralFlangeLeft = flanges['lateral_left_mm'];
    final lateralFlangeRight = flanges['lateral_right_mm'];

    if (!flangeNotRequired &&
        (_hasNonZero(medialFlangeLeft) ||
            _hasNonZero(medialFlangeRight) ||
            _hasNonZero(lateralFlangeLeft) ||
            _hasNonZero(lateralFlangeRight))) {
      cards.add(
        _buildDesignFeatureCard(
          icon: Icons.border_outer_outlined,
          title: 'Duvar / Flange',
          values: [
            if (_hasNonZero(medialFlangeLeft))
              _SideValue('Sol İç Duvar', _formatMm(medialFlangeLeft)),
            if (_hasNonZero(medialFlangeRight))
              _SideValue('Sağ İç Duvar', _formatMm(medialFlangeRight)),
            if (_hasNonZero(lateralFlangeLeft))
              _SideValue('Sol Dış Duvar', _formatMm(lateralFlangeLeft)),
            if (_hasNonZero(lateralFlangeRight))
              _SideValue('Sağ Dış Duvar', _formatMm(lateralFlangeRight)),
          ],
        ),
      );
    }

    final metatarsalLeft = pads['metatarsal_left_mm'];
    final metatarsalRight = pads['metatarsal_right_mm'];

    if (_hasNonZero(metatarsalLeft) || _hasNonZero(metatarsalRight)) {
      cards.add(
        _buildDesignFeatureCard(
          icon: Icons.grid_view_outlined,
          title: 'Metatarsal Ped',
          values: [
            _SideValue('Sol', _formatMm(metatarsalLeft)),
            _SideValue('Sağ', _formatMm(metatarsalRight)),
          ],
        ),
      );
    }

    final heelPadLeft = pads['heel_left_mm'];
    final heelPadRight = pads['heel_right_mm'];

    if (_hasNonZero(heelPadLeft) || _hasNonZero(heelPadRight)) {
      cards.add(
        _buildDesignFeatureCard(
          icon: Icons.motion_photos_on_outlined,
          title: 'Topuk Pedi',
          values: [
            _SideValue('Sol', _formatMm(heelPadLeft)),
            _SideValue('Sağ', _formatMm(heelPadRight)),
          ],
        ),
      );
    }

    final legacyHeelPad = _asBool(_designForm?['heel_pad']);
    final legacyMetatarsalPad = _asBool(_designForm?['metatarsal_pad']);
    final legacyMedialArch = _asBool(_designForm?['medial_arch_support']);
    final legacyTransverseArch =
        _asBool(_designForm?['transverse_arch_support']);

    if (cards.isEmpty) {
      if (legacyHeelPad) {
        cards.add(
          _buildDesignFeatureCard(
            icon: Icons.motion_photos_on_outlined,
            title: 'Topuk Pedi',
            values: const [_SideValue('Durum', 'İsteniyor')],
          ),
        );
      }

      if (legacyMetatarsalPad) {
        cards.add(
          _buildDesignFeatureCard(
            icon: Icons.grid_view_outlined,
            title: 'Metatarsal Ped',
            values: const [_SideValue('Durum', 'İsteniyor')],
          ),
        );
      }

      if (legacyMedialArch) {
        cards.add(
          _buildDesignFeatureCard(
            icon: Icons.architecture_outlined,
            title: 'Medial Ark',
            values: const [_SideValue('Durum', 'Destek isteniyor')],
          ),
        );
      }

      if (legacyTransverseArch) {
        cards.add(
          _buildDesignFeatureCard(
            icon: Icons.swap_horiz_outlined,
            title: 'Transvers / Lateral Ark',
            values: const [_SideValue('Durum', 'Destek isteniyor')],
          ),
        );
      }
    }

    return cards;
  }

  Widget _buildDesignFeatureCard({
    required IconData icon,
    required String title,
    required List<_SideValue> values,
  }) {
    final visibleValues = values.where((item) {
      final value = item.value.trim();
      return value.isNotEmpty && value != '—' && value != '0 mm';
    }).toList();

    if (visibleValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...visibleValues.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilesCard() {
    return _buildSectionCard(
      title: '3D Scan Dosyaları',
      icon: Icons.view_in_ar_outlined,
      child: _scanFiles.isEmpty
          ? _buildEmptyState('Bu oturum için 3D scan dosyası bulunamadı.')
          : Column(
              children: _scanFiles.map((file) {
                final fileName = (file['file_name'] ?? 'Dosya').toString();
                final fileType = (file['file_type'] ?? '').toString();
                final status = (file['upload_status'] ?? '').toString();

                return _buildFileListTile(
                  title: fileName,
                  subtitle: [
                    if (fileType.trim().isNotEmpty) fileType,
                    if (status.trim().isNotEmpty) status,
                    if (file['created_at'] != null)
                      _formatDateTime(file['created_at']),
                  ].join(' • '),
                  onOpen: () => _openStorageFile(file),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPressureCard() {
    return _buildSectionCard(
      title: 'Plantar Basınç Kayıtları',
      icon: Icons.speed_outlined,
      child: _pressureRecordings.isEmpty
          ? _buildEmptyState('Bu oturum için plantar basınç kaydı bulunamadı.')
          : Column(
              children: _pressureRecordings.map((record) {
                final title = (record['title'] ?? 'Basınç kaydı').toString();

                final details = <String>[
                  if (record['frame_count'] != null)
                    '${record['frame_count']} frame',
                  if (record['duration_ms'] != null)
                    '${((_asNum(record['duration_ms']) ?? 0) / 1000).toStringAsFixed(1)} sn',
                  if (record['max_pressure'] != null)
                    'Maks: ${record['max_pressure']}',
                  if (record['avg_pressure'] != null)
                    'Ort: ${record['avg_pressure']}',
                  if (record['recorded_at'] != null)
                    _formatDateTime(record['recorded_at']),
                ];

                return _buildFileListTile(
                  title: title,
                  subtitle: details.join(' • '),
                  onOpen: () => _openStorageFile(record),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildReferencePhotosCard() {
    return _buildSectionCard(
      title: 'Referans Fotoğraflar',
      icon: Icons.photo_camera_back_outlined,
      child: _referencePhotos.isEmpty
          ? _buildEmptyState('Bu oturum için referans fotoğraf bulunamadı.')
          : Column(
              children: _referencePhotos.map((photo) {
                final title = (photo['file_name'] ??
                        photo['title'] ??
                        photo['photo_type'] ??
                        'Referans fotoğraf')
                    .toString();

                final subtitle = <String>[
                  if (photo['photo_type'] != null)
                    photo['photo_type'].toString(),
                  if (photo['created_at'] != null)
                    _formatDateTime(photo['created_at']),
                ].join(' • ');

                return _buildFileListTile(
                  title: title,
                  subtitle: subtitle,
                  onOpen: () => _openStorageFile(photo),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildFileListTile({
    required String title,
    required String subtitle,
    required VoidCallback onOpen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty ? 'Dosya' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Aç / İndir',
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 7),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ölçüm İnceleme'),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  onPressed: _loadReviewData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Ölçüm İnceleme'),
        backgroundColor: Colors.teal,
        actions: [
          TextButton.icon(
            onPressed: _openAnalysisResults,
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            label: const Text(
              'Analiz',
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loadReviewData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 920;

                    final leftColumn = Column(
                      children: [
                        _buildSummaryCard(),
                        _buildStepStatusCard(),
                        _buildFilesCard(),
                        _buildPressureCard(),
                        _buildReferencePhotosCard(),
                      ],
                    );

                    final rightColumn = Column(
                      children: [
                        _buildClinicalInfoCard(),
                        _buildDesignFormCard(),
                      ],
                    );

                    if (!isWide) {
                      return Column(
                        children: [
                          leftColumn,
                          rightColumn,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: leftColumn,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 6,
                          child: rightColumn,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepStatusRow {
  final String title;
  final bool done;

  const _StepStatusRow(this.title, this.done);
}

class _SideValue {
  final String label;
  final String value;

  const _SideValue(this.label, this.value);
}

class _ClinicTypeOption {
  final String value;
  final String label;

  const _ClinicTypeOption({
    required this.value,
    required this.label,
  });

  static const List<_ClinicTypeOption> values = [
    _ClinicTypeOption(value: 'clinic', label: 'Klinik'),
    _ClinicTypeOption(value: 'hospital', label: 'Hastane'),
    _ClinicTypeOption(
      value: 'orthotics_center',
      label: 'Ortez / Protez Merkezi',
    ),
    _ClinicTypeOption(value: 'store', label: 'Mağaza'),
    _ClinicTypeOption(value: 'corporate', label: 'Kurumsal Lokasyon'),
    _ClinicTypeOption(value: 'other', label: 'Diğer'),
  ];
}