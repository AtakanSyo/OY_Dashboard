import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_patient_invite_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/legal/legal_document_registry.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient_invite_model.dart';
import 'package:oy_site/screens/auth/login_screen.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  final String? inviteToken;
  final dynamic pressureRepository;

  const RegisterScreen({
    super.key,
    this.inviteToken,
    this.pressureRepository,
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

  String? _activeInviteToken;
  PatientInviteModel? _invite;

  String? _errorMessage;
  String? _inviteError;

  bool _isLoading = false;
  bool _isLoadingInvite = false;
  bool _inviteInvalid = false;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _success = false;

  bool _acceptedMembershipAgreement = false;
  bool _acceptedPrivacyPolicy = false;
  bool _acceptedTermsOfUse = false;
  bool _acceptedCommercialMessages = false;

  String? _selectedRoleCode;

  bool get _hasInvite =>
      _activeInviteToken != null && _activeInviteToken!.trim().isNotEmpty;

  static const List<Map<String, String>> _roles = [
    {'code': RoleCodes.expert, 'label': 'Uzman'},
    {'code': RoleCodes.customer, 'label': 'Müşteri'},
    {'code': RoleCodes.corporate, 'label': 'Kurumsal'},
    {'code': RoleCodes.optiYouTeam, 'label': 'OptiYou Ekibi'},
  ];

  @override
  void initState() {
    super.initState();

    _activeInviteToken = widget.inviteToken?.trim();

    if (_hasInvite) {
      _selectedRoleCode = RoleCodes.customer;
      _loadInvite();
    }
  }

  Future<void> _loadInvite() async {
    final token = _activeInviteToken?.trim();

    if (token == null || token.isEmpty) return;

    setState(() {
      _isLoadingInvite = true;
      _inviteInvalid = false;
      _inviteError = null;
      _errorMessage = null;
      _invite = null;
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

        final inviteEmail = (invite.email ?? '').trim();
        if (inviteEmail.isNotEmpty) {
          _emailController.text = inviteEmail;
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

    if (!_acceptedMembershipAgreement) {
      setState(() {
        _errorMessage =
            'Devam etmek için Üyelik Sözleşmesi kabul edilmelidir.';
      });
      return;
    }

    if (!_acceptedPrivacyPolicy) {
      setState(() {
        _errorMessage = 'Devam etmek için Aydınlatma Metni okunmalıdır.';
      });
      return;
    }

    if (!_acceptedTermsOfUse) {
      setState(() {
        _errorMessage =
            'Devam etmek için Kullanım Koşulları kabul edilmelidir.';
      });
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
        lower.contains('already been registered') ||
        lower.contains('user already registered')) {
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

  String? _extractInviteTokenFromText(String value) {
    final text = value.trim();

    if (text.isEmpty) return null;

    if (text.startsWith('inv_')) {
      return text;
    }

    final uri = Uri.tryParse(text);
    if (uri == null) return null;

    final directToken = uri.queryParameters['invite'];
    if (directToken != null && directToken.trim().isNotEmpty) {
      return directToken.trim();
    }

    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
      final fragmentUri = Uri.tryParse(normalized);
      final fragmentToken = fragmentUri?.queryParameters['invite'];

      if (fragmentToken != null && fragmentToken.trim().isNotEmpty) {
        return fragmentToken.trim();
      }
    }

    return null;
  }

  Future<void> _showInviteLinkDialog() async {
    final controller = TextEditingController();

    final token = await showDialog<String>(
      context: context,
      builder: (_) {
        String? localError;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Davet Bağlantısı ile Kaydol'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Size verilen davet bağlantısını veya inv_ ile başlayan tokenı buraya yapıştırın.',
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Davet bağlantısı',
                        hintText:
                            'https://optiyou.fit/#/register?invite=inv_...',
                        border: const OutlineInputBorder(),
                        errorText: localError,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final parsedToken =
                        _extractInviteTokenFromText(controller.text);

                    if (parsedToken == null) {
                      setLocalState(() {
                        localError = 'Geçerli bir davet tokenı bulunamadı.';
                      });
                      return;
                    }

                    Navigator.pop(context, parsedToken);
                  },
                  child: const Text('Devam Et'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (token == null || token.trim().isEmpty) return;

    if (!mounted) return;

    setState(() {
      _activeInviteToken = token.trim();
      _selectedRoleCode = RoleCodes.customer;
      _invite = null;
      _inviteInvalid = false;
      _inviteError = null;
      _errorMessage = null;
    });

    await _loadInvite();
  }

  void _goToLogin() {
    if (widget.pressureRepository != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            pressureRepository: widget.pressureRepository,
          ),
        ),
      );
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  void _showLegalDocument(String code) {
    final document = LegalDocumentRegistry.findByCode(code);

    if (document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belge bulunamadı.'),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(document.title),
        content: SizedBox(
          width: 700,
          height: 500,
          child: SingleChildScrollView(
            child: SelectableText(
              document.content,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalCheckboxes() {
    return Column(
      children: [
        _buildLegalCheckbox(
          value: _acceptedMembershipAgreement,
          onChanged: (value) {
            setState(() {
              _acceptedMembershipAgreement = value ?? false;
              _errorMessage = null;
            });
          },
          documentCode: LegalDocumentCodes.uyelikSozlesmesi,
          documentTitle: 'Üyelik Sözleşmesi',
          trailingText: '’ni kabul ediyorum.',
        ),
        _buildLegalCheckbox(
          value: _acceptedPrivacyPolicy,
          onChanged: (value) {
            setState(() {
              _acceptedPrivacyPolicy = value ?? false;
              _errorMessage = null;
            });
          },
          documentCode: LegalDocumentCodes.aydinlatmaMetni,
          documentTitle: 'Aydınlatma Metni',
          trailingText: '’ni okudum.',
        ),
        _buildLegalCheckbox(
          value: _acceptedTermsOfUse,
          onChanged: (value) {
            setState(() {
              _acceptedTermsOfUse = value ?? false;
              _errorMessage = null;
            });
          },
          documentCode: LegalDocumentCodes.kullanimKosullari,
          documentTitle: 'Kullanım Koşulları',
          trailingText: '’nı kabul ediyorum.',
        ),
        _buildLegalCheckbox(
          value: _acceptedCommercialMessages,
          onChanged: (value) {
            setState(() {
              _acceptedCommercialMessages = value ?? false;
              _errorMessage = null;
            });
          },
          documentCode: LegalDocumentCodes.ticariElektronikIleti,
          documentTitle: 'Ticari Elektronik İleti',
          trailingText: ' onayını veriyorum. (Opsiyonel)',
        ),
      ],
    );
  }

  Widget _buildLegalCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String documentCode,
    required String documentTitle,
    required String trailingText,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: _isLoading ? null : onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Wrap(
        children: [
          InkWell(
            onTap: () => _showLegalDocument(documentCode),
            child: Text(
              documentTitle,
              style: const TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Text(trailingText),
        ],
      ),
    );
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
            width: 460,
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
                    onPressed: _goToLogin,
                    child: const Text('Giriş Ekranına Dön'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _inviteInvalid = false;
                      _inviteError = null;
                      _activeInviteToken = null;
                    });
                  },
                  child: const Text('Farklı Davet Bağlantısı Gir'),
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
            width: 420,
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
            onPressed: _goToLogin,
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

    final inviteEmail = (_invite?.email ?? '').trim();

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
              inviteEmail.isEmpty
                  ? 'Davet bağlantısı doğrulandı. Bu kayıt müşteri hesabı olarak oluşturulacak ve ölçüm kaydı hesabınıza bağlanacak.'
                  : 'Davet bağlantısı doğrulandı. E-posta otomatik dolduruldu: $inviteEmail',
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
    final inviteEmailLocked =
        _hasInvite && (_invite?.email ?? '').trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Kayıt Ol',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        if (!_hasInvite) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _showInviteLinkDialog,
              icon: const Icon(Icons.link),
              label: const Text('Davet Bağlantısı ile Kaydol'),
            ),
          ),
          const SizedBox(height: 16),
        ],
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
          enabled: !_isLoading && !inviteEmailLocked,
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
        const SizedBox(height: 16),
        _buildLegalCheckboxes(),
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
          onPressed: _isLoading ? null : _goToLogin,
          child: const Text('Zaten hesabın var mı? Giriş Yap'),
        ),
      ],
    );
  }
}