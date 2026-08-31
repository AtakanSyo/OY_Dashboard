import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/auth/login_screen.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser currentUser;

  const ProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  SupabaseClient get _client => Supabase.instance.client;

  late int? _clinicId;
  late String? _clinicCode;
  late String? _clinicName;
  late String? _clinicType;

  @override
  void initState() {
    super.initState();

    _clinicId = widget.currentUser.clinicId;
    _clinicCode = widget.currentUser.clinicCode;
    _clinicName = widget.currentUser.clinicName;
    _clinicType = widget.currentUser.clinicType;
  }

  bool get _canEditClinic => widget.currentUser.isExpert;

  String _buildClinicText() {
    final clinicName = (_clinicName ?? '').trim();
    final clinicType = (_clinicType ?? '').trim();

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
    return code.isEmpty ? 'Klinik kodu yok' : code;
  }

  String _buildPhoneText() {
    final phone = (widget.currentUser.phone ?? '').trim();
    return phone.isEmpty ? 'Telefon bilgisi yok' : phone;
  }

  String _buildTitleText() {
    final title = (widget.currentUser.title ?? '').trim();
    return title.isEmpty ? 'Unvan bilgisi yok' : title;
  }

  String _buildCommissionProfileText() {
    final value = (widget.currentUser.commissionProfileName ?? '').trim();
    return value.isEmpty ? 'Komisyon profili tanımlı değil' : value;
  }

  String _buildStatusText() {
    return widget.currentUser.isActive ? 'Aktif kullanıcı' : 'Pasif kullanıcı';
  }

  Color _buildStatusColor() {
    return widget.currentUser.isActive ? Colors.green : Colors.redAccent;
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
    final cleaned = clinicName
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();

    if (cleaned.isEmpty) {
      return 'CLN-$suffix';
    }

    return '${cleaned.length > 24 ? cleaned.substring(0, 24) : cleaned}-$suffix';
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

    if (normalizedClinicName.isEmpty) {
      _showMessage('Klinik adı boş olamaz.');
      return false;
    }

    try {
      final now = DateTime.now().toIso8601String();

      int savedClinicId;
      String savedClinicCode;

      if (_clinicId != null && _clinicId! > 0) {
        final updateMap = <String, dynamic>{
          'clinic_name': normalizedClinicName,
          'clinic_type': normalizedClinicType,
          'updated_at': now,
        };

        if (clinicCode.trim().isNotEmpty) {
          updateMap['clinic_code'] = clinicCode.trim();
        }

        await _client
            .from('clinics')
            .update(updateMap)
            .eq('id', _clinicId!);

        savedClinicId = _clinicId!;
        savedClinicCode = clinicCode.trim().isNotEmpty
            ? clinicCode.trim()
            : (_clinicCode ?? '');
      } else {
        savedClinicCode = clinicCode.trim().isNotEmpty
            ? clinicCode.trim()
            : _generateClinicCode(normalizedClinicName);

        final response = await _client
            .from('clinics')
            .insert({
              'clinic_code': savedClinicCode,
              'clinic_name': normalizedClinicName,
              'clinic_type': normalizedClinicType,
              'created_at': now,
              'updated_at': now,
            })
            .select('id, clinic_code, clinic_name, clinic_type')
            .single();

        final row = Map<String, dynamic>.from(response as Map);
        savedClinicId = _asInt(row['id']) ?? 0;

        if (savedClinicId <= 0) {
          throw Exception('Klinik ID alınamadı.');
        }
      }

      await _client
          .from('user_profiles')
          .update({
            'clinic_id': savedClinicId,
            'updated_at': now,
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
    final clinicCodeController = TextEditingController(
      text: (_clinicCode ?? '').trim(),
    );

    final clinicNameController = TextEditingController(
      text: (_clinicName ?? '').trim(),
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
                _clinicId == null || _clinicId == 0
                    ? 'Klinik Bilgisi Ekle'
                    : 'Klinik Bilgisini Düzenle',
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: clinicNameController,
                      decoration: const InputDecoration(
                        labelText: 'Klinik adı',
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
                      decoration: const InputDecoration(
                        labelText: 'Klinik kodu',
                        helperText:
                            'Boş bırakılırsa otomatik oluşturulur. Örnek: GALEN-IZMIR',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Bu klinik bilgisi, yeni oluşturulacak ölçüm oturumlarına otomatik bağlanacak.',
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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

    clinicCodeController.dispose();
    clinicNameController.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicInfoMissing = (_clinicName ?? '').trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, size: 70, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              widget.currentUser.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.currentUser.email,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.currentUser.roleName,
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_canEditClinic && clinicInfoMissing) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.orange.withOpacity(0.25)),
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
                        'Ölçüm oturumu oluşturabilmek için önce klinik bilginizi tanımlayın.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _openClinicEditDialog,
                      icon: const Icon(Icons.add_business_outlined),
                      label: const Text('Klinik Ekle'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
            _buildInfoCard(
              icon: Icons.badge,
              title: 'Ad Soyad',
              value: widget.currentUser.fullName,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.workspace_premium,
              title: 'Unvan',
              value: _buildTitleText(),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.email,
              title: 'E-posta',
              value: widget.currentUser.email,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.phone,
              title: 'Telefon',
              value: _buildPhoneText(),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.admin_panel_settings,
              title: 'Rol',
              value:
                  '${widget.currentUser.roleName} (${widget.currentUser.roleCode})',
            ),
            const SizedBox(height: 16),
            _buildClinicInfoCard(),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.payments_outlined,
              title: 'Komisyon Profili',
              value: _buildCommissionProfileText(),
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.verified_user,
              title: 'Hesap Durumu',
              value: _buildStatusText(),
              valueColor: _buildStatusColor(),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            _buildSettingsButton(
              icon: Icons.lock,
              text: 'Şifre Değiştir',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSettingsButton(
              icon: Icons.logout,
              text: 'Çıkış yap',
              onTap: () async {
                await AuthService().signOut();

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(
                        pressureRepository: null,
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.local_hospital, size: 35, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Klinik',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildClinicText(),
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildClinicCodeText(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_canEditClinic) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _openClinicEditDialog,
              icon: Icon(
                _clinicId == null || _clinicId == 0
                    ? Icons.add_business_outlined
                    : Icons.edit_outlined,
              ),
              label: Text(
                _clinicId == null || _clinicId == 0 ? 'Ekle' : 'Düzenle',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 35, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black45,
            ),
          ],
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
    _ClinicTypeOption(value: 'orthotics_center', label: 'Ortez / Protez Merkezi'),
    _ClinicTypeOption(value: 'store', label: 'Mağaza'),
    _ClinicTypeOption(value: 'corporate', label: 'Kurumsal Lokasyon'),
    _ClinicTypeOption(value: 'other', label: 'Diğer'),
  ];
}