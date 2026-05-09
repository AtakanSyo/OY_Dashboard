import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_patient_invite_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient_invite_model.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  final String? inviteToken;

  const RegisterScreen({
    super.key,
    this.inviteToken,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  final AuthService _authService = AuthService();

  final SupabasePatientInviteRepository _inviteRepository =
      SupabasePatientInviteRepository();

  final SupabasePatientRepository _patientRepository =
      SupabasePatientRepository();

  String? _errorMessage;
  bool _isLoading = false;
  bool _isLoadingInvite = false;
  bool _inviteInvalid = false;
  String? _inviteError;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _success = false;
  String? _selectedRoleCode;

  PatientInviteModel? _invite;

  bool get _hasInvite => widget.inviteToken != null &&
      widget.inviteToken!.trim().isNotEmpty;

  static const List<Map<String, String>> _roles = [
    {'code': RoleCodes.expert, 'label': 'Uzman'},
    {'code': RoleCodes.customer, 'label': 'Müşteri'},
    {'code': RoleCodes.corporate, 'label': 'Kurumsal'},
    {'code': RoleCodes.optiYouTeam, 'label': 'OptiYou Ekibi'},
  ];

  @override
  void initState() {
    super.initState();

    if (_hasInvite) {
      _selectedRoleCode = RoleCodes.customer;
      _loadInvite();
    }
  }

  Future<void> _loadInvite() async {
    final token = widget.inviteToken?.trim();

    if (token == null || token.isEmpty) return;

    setState(() {
      _isLoadingInvite = true;
      _inviteInvalid = false;
      _inviteError = null;
    });

    try {
      final invite = await _inviteRepository.getInviteByToken(token: token);

      if (!mounted) return;

      if (invite == null) {
        setState(() {
          _inviteInvalid = true;
          _inviteError = 'Davet bağlantısı bulunamadı.';
          _isLoadingInvite = false;
        });
        return;
      }

      if (invite.isUsed) {
        setState(() {
          _inviteInvalid = true;
          _inviteError = 'Bu davet bağlantısı daha önce kullanılmış.';
          _isLoadingInvite = false;
        });
        return;
      }

      if (invite.isCancelled) {
        setState(() {
          _inviteInvalid = true;
          _inviteError = 'Bu davet bağlantısı iptal edilmiş.';
          _isLoadingInvite = false;
        });
        return;
      }

      if (!invite.isStillValid) {
        setState(() {
          _inviteInvalid = true;
          _inviteError = 'Bu davet bağlantısının süresi dolmuş.';
          _isLoadingInvite = false;
        });
        return;
      }

      setState(() {
        _invite = invite;
        _selectedRoleCode = RoleCodes.customer;

        if ((invite.email ?? '').trim().isNotEmpty) {
          _emailController.text = invite.email!.trim();
        }

        _isLoadingInvite = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _inviteInvalid = true;
        _inviteError = 'Davet kontrol edilirken hata oluştu: $e';
        _isLoadingInvite = false;
      });
    }
  }

  Future<void> _register() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    if (_hasInvite && (_invite == null || _inviteInvalid)) {
      setState(() {
        _errorMessage = 'Geçerli bir davet bağlantısı bulunamadı.';
      });
      return;
    }

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorMessage = 'Lütfen adınızı ve soyadınızı girin.');
      return;
    }

    if (_selectedRoleCode == null) {
      setState(() => _errorMessage = 'Lütfen kullanıcı tipini seçin.');
      return;
    }

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Lütfen e-posta girin.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authUserId = await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        roleCode: _selectedRoleCode!,
      );

      final invite = _invite;

      if (invite != null) {
        await _patientRepository.linkAuthUserToPatient(
          patientId: invite.patientId,
          authUserId: authUserId,
        );

        final inviteId = invite.inviteId;
        if (inviteId != null) {
          await _inviteRepository.markInviteAsUsed(inviteId: inviteId);
        }
      }

      if (!mounted) return;

      setState(() => _success = true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _localizeAuthError(e.message));
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _localizeAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('already registered') ||
        lower.contains('already been registered')) {
      return 'Bu e-posta adresi zaten kayıtlı.';
    }

    if (lower.contains('invalid email')) {
      return 'Geçersiz e-posta adresi.';
    }

    if (lower.contains('password should be')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }

    return message;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInvite) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_inviteInvalid) {
      return Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Davet Bağlantısı Geçersiz',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _inviteError ?? 'Bu davet bağlantısı kullanılamıyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Giriş Ekranına Dön'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 380,
            child: _success ? _buildSuccessView() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: Colors.teal,
        ),
        const SizedBox(height: 16),
        const Text(
          'Kayıt Tamamlandı!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          _hasInvite
              ? 'Hesabınız oluşturuldu ve ölçüm kaydınız hesabınızla ilişkilendirildi. Giriş yaptıktan sonra ölçüm sonuçlarınızı görüntüleyebilirsiniz.'
              : 'Hesabınızı etkinleştirmek için ${_emailController.text.trim()} adresine gönderilen onay e-postasındaki bağlantıya tıklayın.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Giriş Ekranına Dön'),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteInfoBox() {
    if (!_hasInvite || _invite == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.teal.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Davet bağlantısı doğrulandı. Bu kayıt müşteri hesabı olarak oluşturulacak ve ölçüm kaydı hesabınıza bağlanacak.',
              style: TextStyle(
                color: Colors.teal[900],
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Kayıt Ol',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        _buildInviteInfoBox(),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _selectedRoleCode,
          decoration: InputDecoration(
            labelText: 'Kullanıcı Tipi',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _roles.map((role) {
            return DropdownMenuItem<String>(
              value: role['code'],
              child: Text(role['label']!),
            );
          }).toList(),
          onChanged: _isLoading || _hasInvite
              ? null
              : (value) {
                  setState(() {
                    _selectedRoleCode = value;
                    _errorMessage = null;
                  });
                },
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'E-posta',
            hintText: 'ornek@eposta.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Şifre',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _passwordConfirmController,
          enabled: !_isLoading,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Şifre Tekrar',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            errorText: _errorMessage,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          onChanged: (_) {
            if (_errorMessage != null) {
              setState(() => _errorMessage = null);
            }
          },
          onSubmitted: (_) => _isLoading ? null : _register(),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kayıt Ol',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Zaten hesabın var mı? Giriş Yap'),
        ),
      ],
    );
  }
}