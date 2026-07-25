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
  SupabaseClient get _client => Supabase.instance.client;

  late int? _clinicId;
  late String? _clinicCode;
  late String? _clinicName;
  late String? _clinicType;

  bool _isLoadingClinic = false;

  @override
  void initState() {
    super.initState();

    _clinicId = widget.currentUser.clinicId;
    _clinicCode = widget.currentUser.clinicCode;
    _clinicName = widget.currentUser.clinicName;
    _clinicType = widget.currentUser.clinicType;

    _loadClinicDetailsIfNeeded();
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

  bool get _hasClinic {
    return _clinicId != null &&
        _clinicId! > 0 &&
        (_clinicName ?? '').trim().isNotEmpty;
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

  void _showMessage(String message) {
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
    final user = widget.currentUser;

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
                  title: user.displayName,
                  subtitle: _safeText(user.title, fallback: 'Uzman Kullanıcı'),
                  email: user.email,
                  hasClinic: _hasClinic,
                  clinicName: _buildClinicText(),
                  onEditClinic: _openClinicEditDialog,
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
                                  value: user.displayName,
                                ),
                                _InfoRow(
                                  label: 'E-posta',
                                  value: user.email,
                                ),
                                _InfoRow(
                                  label: 'Telefon',
                                  value: _safeText(user.phone),
                                ),
                                _InfoRow(
                                  label: 'Unvan',
                                  value: _safeText(user.title),
                                ),
                                _InfoRow(
                                  label: 'Rol',
                                  value: user.roleName.trim().isEmpty
                                      ? 'Uzman'
                                      : user.roleName,
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
                        children: const [
                          _SectionCard(
                            title: 'Uzman Dashboard Özeti',
                            child: Row(
                              children: [
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Toplam Kullanıcı',
                                    value: '128',
                                    icon: Icons.people_alt_outlined,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Bu Ay Oturum',
                                    value: '34',
                                    icon: Icons.event_note_outlined,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStatTile(
                                    title: 'Bekleyen Tasarım',
                                    value: '7',
                                    icon: Icons.design_services_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          _SectionCard(
                            title: 'Kısa Notlar',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• En çok düz taban eğilimli vaka görülüyor.'),
                                SizedBox(height: 8),
                                Text('• Basınç ölçümü tamamlanan oturumlarda öneri kalitesi artıyor.'),
                                SizedBox(height: 8),
                                Text('• Siparişe dönüşen oturum oranı takip edilebilir.'),
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
  final bool hasClinic;
  final String clinicName;
  final VoidCallback onEditClinic;

  const _ProfileHeaderCard({
    required this.title,
    required this.subtitle,
    required this.email,
    required this.hasClinic,
    required this.clinicName,
    required this.onEditClinic,
  });

  @override
  Widget build(BuildContext context) {
    final clinicColor = hasClinic ? Colors.green : Colors.orange;

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.teal.withOpacity(0.12),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 34,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Container(
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
                      Text(
                        hasClinic ? clinicName : 'Klinik bilgisi eksik',
                        style: TextStyle(
                          color: clinicColor.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: onEditClinic,
            icon: Icon(
              hasClinic ? Icons.edit_outlined : Icons.add_business_outlined,
            ),
            label: Text(hasClinic ? 'Klinik Düzenle' : 'Klinik Ekle'),
          ),
        ],
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