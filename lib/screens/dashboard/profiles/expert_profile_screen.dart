import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpertProfileScreen extends StatefulWidget {
  final AppUser currentUser;

  const ExpertProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ExpertProfileScreen> createState() => _ExpertProfileScreenState();
}

class _ExpertProfileScreenState extends State<ExpertProfileScreen> {
  static const String _profilePhotoBucket = 'profile-photos';

  SupabaseClient get _client => Supabase.instance.client;

  late int? _clinicId;
  late String? _clinicCode;
  late String? _clinicName;
  late String? _clinicType;

  late String _firstName;
  late String _lastName;
  late String _email;
  String? _phone;
  String? _title;
  String? _profilePhotoUrl;

  bool _isLoadingClinic = false;
  bool _isLoadingProfile = false;
  bool _isSavingProfile = false;
  bool _isUploadingPhoto = false;

  bool _isLoadingStats = false;
  int _totalPatients = 0;
  int _thisMonthSessions = 0;
  int _pendingDesigns = 0;

  @override
  void initState() {
    super.initState();

    _clinicId = widget.currentUser.clinicId;
    _clinicCode = widget.currentUser.clinicCode;
    _clinicName = widget.currentUser.clinicName;
    _clinicType = widget.currentUser.clinicType;

    final nameParts = _splitDisplayName(widget.currentUser.displayName);
    _firstName = nameParts.$1;
    _lastName = nameParts.$2;
    _email = widget.currentUser.email;
    _phone = widget.currentUser.phone;
    _title = widget.currentUser.title;

    _loadClinicDetailsIfNeeded();
    _loadProfileDetails();
    _loadDashboardStats();
  }

  String get _displayName {
    final fullName = '$_firstName $_lastName'.trim();
    return fullName.isEmpty ? widget.currentUser.displayName : fullName;
  }

  bool get _hasClinic {
    return _clinicId != null &&
        _clinicId! > 0 &&
        (_clinicName ?? '').trim().isNotEmpty;
  }

  (String, String) _splitDisplayName(String displayName) {
    final cleaned = displayName.trim();

    if (cleaned.isEmpty) {
      return ('', '');
    }

    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return (parts.first, '');
    }

    return (parts.first, parts.skip(1).join(' '));
  }

  Future<void> _loadClinicDetailsIfNeeded() async {
    final clinicId = _clinicId;
    final hasClinicName = (_clinicName ?? '').trim().isNotEmpty;

    if (clinicId == null || clinicId <= 0 || hasClinicName) return;

    setState(() {
      _isLoadingClinic = true;
    });

    try {
      final response = await _client
          .from('clinics')
          .select('id, clinic_code, clinic_name, clinic_type')
          .eq('id', clinicId)
          .maybeSingle();

      if (response == null || !mounted) {
        setState(() {
          _isLoadingClinic = false;
        });
        return;
      }

      final row = Map<String, dynamic>.from(response as Map);

      setState(() {
        _clinicId = _asInt(row['id']) ?? clinicId;
        _clinicCode = row['clinic_code']?.toString();
        _clinicName = row['clinic_name']?.toString();
        _clinicType = row['clinic_type']?.toString();
        _isLoadingClinic = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingClinic = false;
      });
    }
  }

  Future<void> _loadProfileDetails() async {
    final userId = widget.currentUser.userId;

    if (userId == null) return;

    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final response = await _client
          .from('user_profiles')
          .select(
            'id, first_name, last_name, email, phone, title, profile_photo_url',
          )
          .eq('id', userId)
          .maybeSingle();

      if (response == null || !mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }

      final row = Map<String, dynamic>.from(response as Map);
      final firstName = (row['first_name'] ?? '').toString().trim();
      final lastName = (row['last_name'] ?? '').toString().trim();
      final email = (row['email'] ?? '').toString().trim();
      final phone = (row['phone'] ?? '').toString().trim();
      final title = (row['title'] ?? '').toString().trim();
      final profilePhotoUrl =
          (row['profile_photo_url'] ?? '').toString().trim();

      setState(() {
        if (firstName.isNotEmpty) _firstName = firstName;
        if (lastName.isNotEmpty) _lastName = lastName;
        if (email.isNotEmpty) _email = email;

        _phone = phone.isEmpty ? null : phone;
        _title = title.isEmpty ? null : title;
        _profilePhotoUrl = profilePhotoUrl.isEmpty ? null : profilePhotoUrl;
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingProfile = false;
      });

      _showMessage(
        'Profil bilgileri yüklenemedi. profile_photo_url kolonu ekli değilse SQL migration çalıştırılmalı.',
      );
    }
  }

  Future<void> _loadDashboardStats() async {
    final userId = widget.currentUser.userId;

    if (userId == null) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final patientsResponse = await _client
          .from('patients')
          .select('id')
          .eq('created_by_user_id', userId);

      final sessionsResponse = await _client
          .from('measurement_sessions')
          .select('id, created_at, design_form_completed, status')
          .eq('expert_user_id', userId);

      final patientRows =
          patientsResponse is List ? patientsResponse : const [];

      final sessionRows =
          sessionsResponse is List ? sessionsResponse : const [];

      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);

      int thisMonthSessions = 0;
      int pendingDesigns = 0;

      for (final item in sessionRows) {
        if (item is! Map) continue;

        final row = Map<String, dynamic>.from(item);
        final createdAtText = row['created_at']?.toString();
        final createdAt = createdAtText == null
            ? null
            : DateTime.tryParse(createdAtText)?.toLocal();

        if (createdAt != null &&
            createdAt.isAfter(firstDayOfMonth.subtract(
              const Duration(seconds: 1),
            ))) {
          thisMonthSessions++;
        }

        final status = (row['status'] ?? '').toString();
        final isCancelled = status == 'cancelled';
        final designCompleted = row['design_form_completed'] == true;

        if (!isCancelled && !designCompleted) {
          pendingDesigns++;
        }
      }

      if (!mounted) return;

      setState(() {
        _totalPatients = patientRows.length;
        _thisMonthSessions = thisMonthSessions;
        _pendingDesigns = pendingDesigns;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingStats = false;
      });

      _showMessage('Dashboard özeti yüklenemedi: $e');
    }
  }

  String _buildClinicText() {
    final clinicName = (_clinicName ?? '').trim();
    final clinicType = (_clinicType ?? '').trim();

    if (_isLoadingClinic) {
      return 'Klinik bilgisi yükleniyor...';
    }

    if (clinicName.isEmpty && clinicType.isEmpty) {
      return 'Bağlı klinik bilgisi yok';
    }

    final typeLabel = _clinicTypeLabel(clinicType);

    if (clinicName.isNotEmpty && typeLabel.isNotEmpty) {
      return '$clinicName ($typeLabel)';
    }

    return clinicName.isNotEmpty ? clinicName : typeLabel;
  }

  String _buildClinicCodeText() {
    final code = (_clinicCode ?? '').trim();

    if (code.isEmpty) {
      return 'Klinik kodu yok';
    }

    return code;
  }

  String _clinicTypeLabel(String value) {
    switch (value) {
      case 'clinic':
        return 'Klinik';
      case 'hospital':
        return 'Hastane';
      case 'orthotics_center':
        return 'Ortez / Protez Merkezi';
      case 'store':
        return 'Mağaza';
      case 'corporate':
        return 'Kurumsal Lokasyon';
      case 'other':
        return 'Diğer';
      default:
        return value;
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

  Future<bool> _saveClinicInfo({
    required String clinicCode,
    required String clinicName,
    required String clinicType,
  }) async {
    final userId = widget.currentUser.userId;

    if (userId == null) {
      _showMessage('Kullanıcı ID bulunamadı.');
      return false;
    }

    final normalizedClinicName = clinicName.trim();
    final normalizedClinicType = clinicType.trim();
    final normalizedClinicCode = clinicCode.trim();

    if (normalizedClinicName.isEmpty) {
      _showMessage('Klinik adı boş olamaz.');
      return false;
    }

    if (normalizedClinicType.isEmpty) {
      _showMessage('Klinik tipi seçilmelidir.');
      return false;
    }

    try {
      int savedClinicId;
      String savedClinicCode;

      if (_clinicId != null && _clinicId! > 0) {
        final updateMap = <String, dynamic>{
          'clinic_name': normalizedClinicName,
          'clinic_type': normalizedClinicType,
        };

        if (normalizedClinicCode.isNotEmpty) {
          updateMap['clinic_code'] = normalizedClinicCode;
        }

        final response = await _client
            .from('clinics')
            .update(updateMap)
            .eq('id', _clinicId!)
            .select('id, clinic_code, clinic_name, clinic_type')
            .single();

        final row = Map<String, dynamic>.from(response as Map);

        savedClinicId = _asInt(row['id']) ?? _clinicId!;
        savedClinicCode = row['clinic_code']?.toString() ?? '';
      } else {
        savedClinicCode = normalizedClinicCode.isNotEmpty
            ? normalizedClinicCode
            : _generateClinicCode(normalizedClinicName);

        final response = await _client
            .from('clinics')
            .insert({
              'clinic_code': savedClinicCode,
              'clinic_name': normalizedClinicName,
              'clinic_type': normalizedClinicType,
            })
            .select('id, clinic_code, clinic_name, clinic_type')
            .single();

        final row = Map<String, dynamic>.from(response as Map);

        savedClinicId = _asInt(row['id']) ?? 0;
        savedClinicCode = row['clinic_code']?.toString() ?? savedClinicCode;

        if (savedClinicId <= 0) {
          throw Exception('Klinik ID alınamadı.');
        }
      }

      await _client
          .from('user_profiles')
          .update({
            'clinic_id': savedClinicId,
          })
          .eq('id', userId);

      if (!mounted) return false;

      setState(() {
        _clinicId = savedClinicId;
        _clinicCode = savedClinicCode;
        _clinicName = normalizedClinicName;
        _clinicType = normalizedClinicType;
      });

      _showMessage('Klinik bilgisi kaydedildi.');
      return true;
    } catch (e) {
      _showMessage('Klinik bilgisi kaydedilemedi: $e');
      return false;
    }
  }

  Future<bool> _saveProfileInfo({
    required String firstName,
    required String lastName,
    required String phone,
    required String title,
  }) async {
    final userId = widget.currentUser.userId;

    if (userId == null) {
      _showMessage('Kullanıcı ID bulunamadı.');
      return false;
    }

    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();
    final normalizedPhone = phone.trim();
    final normalizedTitle = title.trim();

    if (normalizedFirstName.isEmpty) {
      _showMessage('Ad boş olamaz.');
      return false;
    }

    if (normalizedLastName.isEmpty) {
      _showMessage('Soyad boş olamaz.');
      return false;
    }

    try {
      final response = await _client
          .from('user_profiles')
          .update({
            'first_name': normalizedFirstName,
            'last_name': normalizedLastName,
            'phone': normalizedPhone.isEmpty ? null : normalizedPhone,
            'title': normalizedTitle.isEmpty ? null : normalizedTitle,
          })
          .eq('id', userId)
          .select('first_name, last_name, phone, title, profile_photo_url')
          .maybeSingle();

      if (!mounted) return false;

      if (response != null) {
        final row = Map<String, dynamic>.from(response as Map);
        final profilePhotoUrl =
            (row['profile_photo_url'] ?? '').toString().trim();

        setState(() {
          _firstName =
              (row['first_name'] ?? normalizedFirstName).toString().trim();
          _lastName =
              (row['last_name'] ?? normalizedLastName).toString().trim();
          _phone = (row['phone'] ?? '').toString().trim().isEmpty
              ? null
              : row['phone'].toString();
          _title = (row['title'] ?? '').toString().trim().isEmpty
              ? null
              : row['title'].toString();
          _profilePhotoUrl = profilePhotoUrl.isEmpty ? null : profilePhotoUrl;
        });
      } else {
        setState(() {
          _firstName = normalizedFirstName;
          _lastName = normalizedLastName;
          _phone = normalizedPhone.isEmpty ? null : normalizedPhone;
          _title = normalizedTitle.isEmpty ? null : normalizedTitle;
        });
      }

      _showMessage('Profil bilgileri kaydedildi.');
      return true;
    } catch (e) {
      _showMessage('Profil bilgileri kaydedilemedi: $e');
      return false;
    }
  }

  Future<void> _openClinicEditDialog() async {
    final clinicNameController = TextEditingController(
      text: (_clinicName ?? '').trim(),
    );

    final clinicCodeController = TextEditingController(
      text: (_clinicCode ?? '').trim(),
    );

    final allowedTypes = _ClinicTypeOption.values.map((e) => e.value).toSet();

    String selectedClinicType = allowedTypes.contains((_clinicType ?? '').trim())
        ? (_clinicType ?? '').trim()
        : 'clinic';

    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(
                _hasClinic
                    ? 'Klinik Bilgisini Düzenle'
                    : 'Klinik Bilgisi Ekle',
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        hintText: 'Örn. GALEN-IZMIR',
                        helperText:
                            'Boş bırakılırsa otomatik klinik kodu oluşturulur.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                      child: const Text(
                        'Bu bilgi yeni oluşturulacak ölçüm oturumlarına otomatik bağlanır. '
                        'Böylece session.clinic_id ve order.clinic_id doğru oluşur.',
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                  ],
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

                          final ok = await _saveClinicInfo(
                            clinicCode: clinicCodeController.text,
                            clinicName: clinicNameController.text,
                            clinicType: selectedClinicType,
                          );

                          if (!dialogContext.mounted) return;

                          if (ok) {
                            Navigator.pop(dialogContext);
                            return;
                          }

                          dialogSetState(() {
                            isSaving = false;
                          });
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

  Future<void> _openProfileEditDialog() async {
    final firstNameController = TextEditingController(text: _firstName);
    final lastNameController = TextEditingController(text: _lastName);
    final phoneController = TextEditingController(text: _phone ?? '');
    final titleController = TextEditingController(text: _title ?? '');

    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving && !_isUploadingPhoto,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Profil Bilgilerini Düzenle'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildProfilePhotoEditor(
                        onUploadPressed: () async {
                          dialogSetState(() {
                            _isUploadingPhoto = true;
                          });

                          await _pickAndUploadProfilePhoto();

                          if (!dialogContext.mounted) return;

                          dialogSetState(() {
                            _isUploadingPhoto = false;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              enabled: !isSaving && !_isUploadingPhoto,
                              textInputAction: TextInputAction.next,
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
                              enabled: !isSaving && !_isUploadingPhoto,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Soyad',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        enabled: false,
                        controller: TextEditingController(text: _email),
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          helperText:
                              'E-posta adresi bu ekrandan değiştirilemez.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: phoneController,
                        enabled: !isSaving && !_isUploadingPhoto,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          hintText: 'Örn. +90 5XX XXX XX XX',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        enabled: !isSaving && !_isUploadingPhoto,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Unvan',
                          hintText: 'Örn. Ortez Protez Uzmanı',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving || _isUploadingPhoto
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving || _isUploadingPhoto
                      ? null
                      : () async {
                          dialogSetState(() {
                            isSaving = true;
                          });

                          setState(() {
                            _isSavingProfile = true;
                          });

                          final ok = await _saveProfileInfo(
                            firstName: firstNameController.text,
                            lastName: lastNameController.text,
                            phone: phoneController.text,
                            title: titleController.text,
                          );

                          if (!mounted) return;

                          setState(() {
                            _isSavingProfile = false;
                          });

                          if (!dialogContext.mounted) return;

                          if (ok) {
                            Navigator.pop(dialogContext);
                            return;
                          }

                          dialogSetState(() {
                            isSaving = false;
                          });
                        },
                  icon: isSaving || _isSavingProfile
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

    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    titleController.dispose();
  }

  Widget _buildProfilePhotoEditor({
    required VoidCallback onUploadPressed,
  }) {
    final hasPhoto = (_profilePhotoUrl ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.teal.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            backgroundImage: hasPhoto ? NetworkImage(_profilePhotoUrl!) : null,
            child: hasPhoto
                ? null
                : const Icon(
                    Icons.person_outline,
                    color: Colors.teal,
                    size: 34,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Fotoğrafı',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhoto
                      ? 'Profil fotoğrafı yüklendi. Yeni bir görsel seçerek değiştirebilirsiniz.'
                      : 'Profil fotoğrafı ekleyebilirsiniz.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _isUploadingPhoto ? null : onUploadPressed,
            icon: _isUploadingPhoto
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: Text(_isUploadingPhoto ? 'Yükleniyor' : 'Fotoğraf Seç'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final userId = widget.currentUser.userId;

    if (userId == null) {
      _showMessage('Kullanıcı ID bulunamadı.');
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        _showMessage('Fotoğraf okunamadı.');
        return;
      }

      final extension = _fileExtension(file.name);
      final mimeType = _guessImageMimeType(file.name);
      final storagePath =
          'experts/$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from(_profilePhotoBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final publicUrl = _client.storage
          .from(_profilePhotoBucket)
          .getPublicUrl(storagePath);

      await _client
          .from('user_profiles')
          .update({
            'profile_photo_url': publicUrl,
          })
          .eq('id', userId);

      if (!mounted) return;

      setState(() {
        _profilePhotoUrl = publicUrl;
      });

      _showMessage('Profil fotoğrafı güncellendi.');
    } catch (e) {
      _showMessage('Profil fotoğrafı yüklenemedi: $e');
    }
  }

  String _fileExtension(String fileName) {
    final clean = fileName.trim().toLowerCase();
    final dotIndex = clean.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == clean.length - 1) {
      return 'png';
    }

    final extension = clean.substring(dotIndex + 1);

    if (extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp') {
      return extension;
    }

    return 'png';
  }

  String _guessImageMimeType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }

    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }

    return 'image/png';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _safeText(String? value, {String fallback = '—'}) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final roleName = widget.currentUser.roleName.trim().isEmpty
        ? 'Uzman'
        : widget.currentUser.roleName;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Uzman Profili'),
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
                _ProfileHeaderCard(
                  title: _displayName,
                  subtitle: _safeText(_title, fallback: 'Uzman Kullanıcı'),
                  email: _email,
                  profilePhotoUrl: _profilePhotoUrl,
                  hasClinic: _hasClinic,
                  clinicName: _buildClinicText(),
                  isLoadingProfile: _isLoadingProfile,
                  onEditClinic: _openClinicEditDialog,
                  onEditProfile: _openProfileEditDialog,
                ),
                if (!_hasClinic) ...[
                  const SizedBox(height: 18),
                  _MissingClinicWarningCard(
                    onPressed: _openClinicEditDialog,
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _SectionCard(
                            title: 'Uzman Bilgileri',
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: 'Ad Soyad',
                                  value: _displayName,
                                ),
                                _InfoRow(
                                  label: 'E-posta',
                                  value: _email,
                                ),
                                _InfoRow(
                                  label: 'Telefon',
                                  value: _safeText(_phone),
                                ),
                                _InfoRow(
                                  label: 'Unvan',
                                  value: _safeText(_title),
                                ),
                                _InfoRow(
                                  label: 'Rol',
                                  value: roleName,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: 'Klinik Bilgileri',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoRow(
                                  label: 'Klinik',
                                  value: _buildClinicText(),
                                ),
                                _InfoRow(
                                  label: 'Klinik Kodu',
                                  value: _buildClinicCodeText(),
                                ),
                                _InfoRow(
                                  label: 'Klinik Tipi',
                                  value: _clinicTypeLabel(
                                    (_clinicType ?? '').trim(),
                                  ).isEmpty
                                      ? '—'
                                      : _clinicTypeLabel(
                                          (_clinicType ?? '').trim(),
                                        ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _openClinicEditDialog,
                                    icon: Icon(
                                      _hasClinic
                                          ? Icons.edit_outlined
                                          : Icons.add_business_outlined,
                                    ),
                                    label: Text(
                                      _hasClinic
                                          ? 'Klinik Bilgisini Düzenle'
                                          : 'Klinik Bilgisi Ekle',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _openProfileEditDialog,
                                    icon: const Icon(Icons.person_outline),
                                    label: const Text(
                                      'Profil Bilgilerini Düzenle',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _SectionCard(
                            title: 'Uzman Dashboard Özeti',
                            child: _isLoadingStats
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(18),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _MiniStatTile(
                                          title: 'Toplam Kullanıcı',
                                          value: _totalPatients.toString(),
                                          icon: Icons.people_alt_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _MiniStatTile(
                                          title: 'Bu Ay Oturum',
                                          value:
                                              _thisMonthSessions.toString(),
                                          icon: Icons.event_note_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _MiniStatTile(
                                          title: 'Bekleyen Tasarım',
                                          value: _pendingDesigns.toString(),
                                          icon: Icons.design_services_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
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

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String email;
  final String? profilePhotoUrl;
  final bool hasClinic;
  final String clinicName;
  final bool isLoadingProfile;
  final VoidCallback onEditClinic;
  final VoidCallback onEditProfile;

  const _ProfileHeaderCard({
    required this.title,
    required this.subtitle,
    required this.email,
    required this.profilePhotoUrl,
    required this.hasClinic,
    required this.clinicName,
    required this.isLoadingProfile,
    required this.onEditClinic,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final MaterialColor clinicColor = hasClinic ? Colors.green : Colors.orange;
    final hasPhoto = (profilePhotoUrl ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;

          final avatar = CircleAvatar(
            radius: 38,
            backgroundColor: Colors.teal.withOpacity(0.12),
            backgroundImage: hasPhoto ? NetworkImage(profilePhotoUrl!) : null,
            child: hasPhoto
                ? null
                : const Icon(
                    Icons.medical_services_outlined,
                    size: 36,
                    color: Colors.teal,
                  ),
          );

          final info = Column(
            crossAxisAlignment:
                isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment:
                    isNarrow ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isLoadingProfile) ...[
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: isNarrow ? TextAlign.center : TextAlign.left,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: isNarrow ? Alignment.center : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: clinicColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasClinic
                            ? Icons.local_hospital_outlined
                            : Icons.warning_amber_outlined,
                        size: 16,
                        color: clinicColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          hasClinic ? clinicName : 'Klinik bilgisi eksik',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: clinicColor.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: onEditClinic,
                icon: Icon(
                  hasClinic ? Icons.edit_outlined : Icons.add_business_outlined,
                ),
                label: Text(hasClinic ? 'Klinik Düzenle' : 'Klinik Ekle'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.person_outline),
                label: const Text('Profil Bilgilerini Düzenle'),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(height: 14),
                info,
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: actions,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(child: info),
              const SizedBox(width: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 230,
                  maxWidth: 280,
                ),
                child: actions,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MissingClinicWarningCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _MissingClinicWarningCard({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Yeni ölçüm oturumu oluşturabilmek için önce uzman hesabına bağlı klinik bilgisini tanımlamalısınız.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Klinik Ekle'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.trim().isEmpty ? '—' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
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
              safeValue,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
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