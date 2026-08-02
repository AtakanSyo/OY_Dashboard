
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_patient_invite_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/legal/legal_document_registry.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient_invite_model.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeQrScreen extends StatefulWidget {
  final dynamic pressureRepository;
  final void Function(AppUser user)? onOpenApp;

  const WelcomeQrScreen({
    super.key,
    this.pressureRepository,
    this.onOpenApp,
  });

  @override
  State<WelcomeQrScreen> createState() => _WelcomeQrScreenState();
}

class _WelcomeQrScreenState extends State<WelcomeQrScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _accessPanelKey = GlobalKey();
  final SupabasePatientInviteRepository _inviteRepository =
      SupabasePatientInviteRepository();

  String? _source;
  String? _inviteToken;
  PatientInviteModel? _invite;
  String? _inviteError;

  bool _isLoadingInvite = false;
  bool _accessPanelOpen = false;
  AppUser? _readyUser;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    final data = _parseRoute();
    _source = data.source;
    _inviteToken = data.inviteToken;

    _scrollController.addListener(() {
      if (!mounted) return;
      setState(() => _scrollOffset = _scrollController.offset);
    });

    if ((_inviteToken ?? '').trim().isNotEmpty) {
      _loadInvite(_inviteToken!.trim());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  _WelcomeRouteData _parseRoute() {
    final uri = Uri.base;

    String? read(String key) {
      final direct = uri.queryParameters[key];
      if ((direct ?? '').trim().isNotEmpty) return direct!.trim();

      final fragment = uri.fragment.trim();
      if (fragment.isEmpty) return null;

      final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
      final fragmentUri = Uri.tryParse(normalized);
      final fromFragment = fragmentUri?.queryParameters[key];

      if ((fromFragment ?? '').trim().isNotEmpty) {
        return fromFragment!.trim();
      }

      return null;
    }

    return _WelcomeRouteData(
      source: read('source') ?? 'qr',
      inviteToken: read('invite') ?? read('t') ?? read('token') ?? read('result'),
    );
  }

  Future<void> _loadInvite(String token) async {
    setState(() {
      _isLoadingInvite = true;
      _invite = null;
      _inviteError = null;
    });

    try {
      final invite = await _inviteRepository.getInviteByToken(token: token);

      if (!mounted) return;

      if (invite == null) {
        setState(() {
          _inviteError =
              'Bu QR kod ile ilişkili ölçüm daveti bulunamadı. Kodu manuel girebilirsiniz.';
          _isLoadingInvite = false;
        });
        return;
      }

      final validation = _validateInvite(invite);

      setState(() {
        _invite = validation == null ? invite : null;
        _inviteError = validation;
        _isLoadingInvite = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inviteError = 'QR daveti kontrol edilirken hata oluştu: $e';
        _isLoadingInvite = false;
      });
    }
  }

  String? _validateInvite(PatientInviteModel invite) {
    if (invite.isUsed) return 'Bu QR/davet bağlantısı daha önce kullanılmış.';
    if (invite.isCancelled) return 'Bu QR/davet bağlantısı iptal edilmiş.';
    if (!invite.isStillValid) return 'Bu QR/davet bağlantısının süresi dolmuş.';
    return null;
  }

  void _openAccessPanel() {
    setState(() => _accessPanelOpen = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _accessPanelKey.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _openUsageGuide() {
    final target = math.min(
      _scrollController.position.maxScrollExtent,
      1850.0,
    );

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleInviteLoaded({
    required String token,
    required PatientInviteModel invite,
  }) {
    setState(() {
      _inviteToken = token;
      _invite = invite;
      _inviteError = null;
    });
  }

  void _handleAuthenticated(AppUser user) {
    setState(() {
      _readyUser = user;
      _accessPanelOpen = true;
    });
  }

  void _openApp(AppUser user) {
    if (widget.onOpenApp != null) {
      widget.onOpenApp!(user);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/dashboard',
      arguments: user,
    );
  }

  double _focusForStep(int index) {
    final start = 420.0 + index * 330.0;
    final distance = (_scrollOffset - start).abs();
    return (1 - distance / 420).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final readyUser = _readyUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WelcomeBackgroundPainter(progress: _scrollOffset),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _HeroWelcomeSection(
                  hasToken: (_inviteToken ?? '').trim().isNotEmpty,
                  source: _source ?? 'qr',
                  isLoadingInvite: _isLoadingInvite,
                  inviteError: _inviteError,
                  onOpenResults: _openAccessPanel,
                  onOpenGuide: _openUsageGuide,
                ),
              ),
              SliverToBoxAdapter(
                child: _TechnologyStorySection(
                  focusForStep: _focusForStep,
                ),
              ),
              SliverToBoxAdapter(
                child: _PressurePreviewSection(
                  progress: (_scrollOffset / 1600).clamp(0.0, 1.0).toDouble(),
                ),
              ),
              SliverToBoxAdapter(
                key: _accessPanelKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 42, 18, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: InlineCustomerAccessPanel(
                        isOpen: _accessPanelOpen,
                        initialInviteToken: _inviteToken,
                        initialInvite: _invite,
                        initialInviteError: _inviteError,
                        onOpenRequested: _openAccessPanel,
                        onInviteLoaded: _handleInviteLoaded,
                        onAuthenticated: _handleAuthenticated,
                        onOpenApp: _openApp,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _UsageGuideSection(onOpenResults: _openAccessPanel),
              ),
              SliverToBoxAdapter(
                child: _SupportSection(onOpenResults: _openAccessPanel),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: _StickyActionBar(
                isReady: readyUser != null,
                onOpenResults: readyUser == null
                    ? _openAccessPanel
                    : () => _openApp(readyUser),
                onOpenGuide: _openUsageGuide,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InlineCustomerAccessPanel extends StatefulWidget {
  final bool isOpen;
  final String? initialInviteToken;
  final PatientInviteModel? initialInvite;
  final String? initialInviteError;
  final VoidCallback onOpenRequested;
  final void Function({
    required String token,
    required PatientInviteModel invite,
  }) onInviteLoaded;
  final ValueChanged<AppUser> onAuthenticated;
  final ValueChanged<AppUser> onOpenApp;

  const InlineCustomerAccessPanel({
    super.key,
    required this.isOpen,
    required this.initialInviteToken,
    required this.initialInvite,
    required this.initialInviteError,
    required this.onOpenRequested,
    required this.onInviteLoaded,
    required this.onAuthenticated,
    required this.onOpenApp,
  });

  @override
  State<InlineCustomerAccessPanel> createState() =>
      _InlineCustomerAccessPanelState();
}

class _InlineCustomerAccessPanelState extends State<InlineCustomerAccessPanel> {
  final AuthService _authService = AuthService();
  final SupabasePatientInviteRepository _inviteRepository =
      SupabasePatientInviteRepository();
  final SupabasePatientRepository _patientRepository =
      SupabasePatientRepository();

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerPasswordConfirmController =
      TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  PatientInviteModel? _invite;
  String? _inviteToken;
  String? _errorMessage;
  String? _successMessage;

  _AccessMode _mode = _AccessMode.register;

  bool _isLoading = false;
  bool _isLoadingCode = false;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirm = true;
  bool _obscureLoginPassword = true;
  bool _acceptedMembershipAgreement = false;
  bool _acceptedPrivacyPolicy = false;
  bool _acceptedTermsOfUse = false;
  bool _acceptedCommercialMessages = false;
  bool _emailConfirmationRequired = false;

  AppUser? _readyUser;

  @override
  void initState() {
    super.initState();
    _syncInitialInvite();
  }

  @override
  void didUpdateWidget(covariant InlineCustomerAccessPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialInviteToken != widget.initialInviteToken ||
        oldWidget.initialInvite != widget.initialInvite ||
        oldWidget.initialInviteError != widget.initialInviteError) {
      _syncInitialInvite();
    }
  }

  void _syncInitialInvite() {
    _inviteToken = widget.initialInviteToken?.trim();
    _invite = widget.initialInvite;

    if ((_inviteToken ?? '').trim().isNotEmpty) {
      _codeController.text = _inviteToken!;
    }

    final email = (_invite?.email ?? '').trim();
    if (email.isNotEmpty) {
      _registerEmailController.text = email;
      _loginEmailController.text = email;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerPasswordConfirmController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  bool get _hasInvite => _invite != null && (_inviteToken ?? '').isNotEmpty;

  String? _validateInvite(PatientInviteModel invite) {
    if (invite.isUsed) return 'Bu QR/davet bağlantısı daha önce kullanılmış.';
    if (invite.isCancelled) return 'Bu QR/davet bağlantısı iptal edilmiş.';
    if (!invite.isStillValid) return 'Bu QR/davet bağlantısının süresi dolmuş.';
    return null;
  }

  String? _extractInviteTokenFromText(String value) {
    final text = value.trim();

    if (text.isEmpty) return null;
    if (text.startsWith('inv_')) return text;

    final uri = Uri.tryParse(text);
    if (uri == null) return null;

    for (final key in ['invite', 't', 'token', 'result']) {
      final direct = uri.queryParameters[key];
      if ((direct ?? '').trim().isNotEmpty) return direct!.trim();
    }

    final fragment = uri.fragment.trim();
    if (fragment.isEmpty) return null;

    final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
    final fragmentUri = Uri.tryParse(normalized);

    for (final key in ['invite', 't', 'token', 'result']) {
      final fromFragment = fragmentUri?.queryParameters[key];
      if ((fromFragment ?? '').trim().isNotEmpty) return fromFragment!.trim();
    }

    return null;
  }

  Future<void> _loadInviteFromCode() async {
    final token = _extractInviteTokenFromText(_codeController.text);

    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage =
            'Geçerli bir QR bağlantısı veya inv_ ile başlayan davet kodu girin.';
      });
      return;
    }

    setState(() {
      _isLoadingCode = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final invite = await _inviteRepository.getInviteByToken(token: token);

      if (!mounted) return;

      if (invite == null) {
        setState(() {
          _isLoadingCode = false;
          _errorMessage = 'Bu davet kodu bulunamadı.';
        });
        return;
      }

      final validationError = _validateInvite(invite);

      if (validationError != null) {
        setState(() {
          _isLoadingCode = false;
          _errorMessage = validationError;
        });
        return;
      }

      final email = (invite.email ?? '').trim();

      setState(() {
        _inviteToken = token;
        _invite = invite;
        _isLoadingCode = false;
        _successMessage =
            'Davet doğrulandı. Şimdi hesap oluşturabilir veya giriş yapabilirsiniz.';
      });

      if (email.isNotEmpty) {
        _registerEmailController.text = email;
        _loginEmailController.text = email;
      }

      widget.onInviteLoaded(token: token, invite: invite);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCode = false;
        _errorMessage = 'Davet kontrol edilirken hata oluştu: $e';
      });
    }
  }

  Future<void> _registerAndClaim() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirm = _registerPasswordConfirmController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      setState(() => _errorMessage = 'Lütfen adınızı ve soyadınızı girin.');
      return;
    }

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Lütfen e-posta adresinizi girin.');
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
      _successMessage = null;
      _emailConfirmationRequired = false;
    });

    try {
      final authUserId = await _authService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        roleCode: RoleCodes.customer,
      );

      await _claimInviteIfAvailable(authUserId: authUserId);

      AppUser? user;

      try {
        user = await _authService.signIn(email: email, password: password);
      } catch (_) {
        user = await _tryReadCurrentProfile();
      }

      if (!mounted) return;

      if (user == null) {
        setState(() {
          _isLoading = false;
          _emailConfirmationRequired = true;
          _successMessage =
              'Kayıt oluşturuldu. E-posta onayı aktifse, gönderilen onay bağlantısından sonra bu sayfadan giriş yapabilirsiniz.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _readyUser = user;
        _successMessage = _hasInvite
            ? 'Hesabınız oluşturuldu ve sonuçlarınız hesabınıza bağlandı.'
            : 'Hesabınız oluşturuldu. Uygulamaya geçebilirsiniz.';
      });

      widget.onAuthenticated(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _localizeAuthError(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kayıt tamamlanamadı: $e';
      });
    }
  }

  Future<void> _loginAndClaim() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'E-posta ve şifre girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = await _authService.signIn(email: email, password: password);
      final authId = Supabase.instance.client.auth.currentUser?.id;

      if (authId != null) {
        await _claimInviteIfAvailable(authUserId: authId);
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _readyUser = user;
        _successMessage = _hasInvite
            ? 'Giriş yapıldı ve sonuçlarınız hesabınıza bağlandı.'
            : 'Giriş yapıldı. Uygulamaya geçebilirsiniz.';
      });

      widget.onAuthenticated(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _localizeAuthError(e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Giriş tamamlanamadı: $e';
      });
    }
  }

  Future<AppUser?> _tryReadCurrentProfile() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return null;

    try {
      final profile = await Supabase.instance.client
          .from('user_profiles_full')
          .select()
          .eq('auth_id', authUser.id)
          .single();

      return AppUser.fromMap(Map<String, dynamic>.from(profile as Map));
    } catch (_) {
      return null;
    }
  }

  Future<void> _claimInviteIfAvailable({
    required String authUserId,
  }) async {
    final invite = _invite;
    if (invite == null) return;

    await _patientRepository.linkAuthUserToPatient(
      patientId: invite.patientId,
      authUserId: authUserId,
    );

    final inviteId = invite.inviteId;
    if (inviteId != null) {
      await _inviteRepository.markInviteAsUsed(inviteId: inviteId);
    }
  }

  String _localizeAuthError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('already registered') ||
        lower.contains('already been registered') ||
        lower.contains('user already registered')) {
      return 'Bu e-posta adresi zaten kayıtlı. Giriş sekmesini kullanabilirsiniz.';
    }

    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'E-posta veya şifre hatalı.';
    }

    if (lower.contains('email not confirmed')) {
      return 'E-posta adresinizi onayladıktan sonra giriş yapabilirsiniz.';
    }

    if (lower.contains('invalid email')) return 'Geçersiz e-posta adresi.';

    if (lower.contains('password should be')) {
      return 'Şifre en az 6 karakter olmalıdır.';
    }

    return message;
  }

  void _showLegalDocument(String code) {
    final document = LegalDocumentRegistry.findByCode(code);

    if (document == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belge bulunamadı.')),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(document.title),
        content: SizedBox(
          width: 720,
          height: 520,
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) {
      return _ClosedAccessCard(
        hasInvite: widget.initialInvite != null,
        inviteError: widget.initialInviteError,
        onOpen: widget.onOpenRequested,
      );
    }

    final readyUser = _readyUser;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.teal.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          final intro = _AccessIntro(
            hasInvite: _hasInvite,
            email: _invite?.email,
            emailConfirmationRequired: _emailConfirmationRequired,
          );

          final auth = readyUser == null
              ? _buildAuthContent()
              : _buildSuccessView(readyUser);

          if (narrow) {
            return Column(
              children: [
                intro,
                const SizedBox(height: 20),
                auth,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: intro),
              const SizedBox(width: 26),
              Expanded(child: auth),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAuthContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCodeBox(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  text: 'Hesap Oluştur',
                  selected: _mode == _AccessMode.register,
                  onTap: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _mode = _AccessMode.register;
                            _errorMessage = null;
                          });
                        },
                ),
              ),
              Expanded(
                child: _SegmentButton(
                  text: 'Giriş Yap',
                  selected: _mode == _AccessMode.login,
                  onTap: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _mode = _AccessMode.login;
                            _errorMessage = null;
                          });
                        },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: _mode == _AccessMode.register
              ? _buildRegisterForm()
              : _buildLoginForm(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _PanelMessage(
            icon: Icons.error_outline,
            text: _errorMessage!,
            color: Colors.red,
          ),
        ],
        if (_successMessage != null) ...[
          const SizedBox(height: 12),
          _PanelMessage(
            icon: Icons.check_circle_outline,
            text: _successMessage!,
            color: Colors.teal,
          ),
        ],
      ],
    );
  }

  Widget _buildCodeBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _hasInvite
            ? Colors.teal.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _hasInvite
              ? Colors.teal.withOpacity(0.22)
              : Colors.orange.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasInvite
                    ? Icons.verified_user_outlined
                    : Icons.qr_code_scanner_outlined,
                color:
                    _hasInvite ? Colors.teal.shade700 : Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _hasInvite
                      ? 'Sonuç erişim kodu doğrulandı'
                      : 'Sonuçlar için davet kodu',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _hasInvite
                ? 'Bu kayıt müşteri hesabına bağlanacak.'
                : 'Broşürde veya QR bağlantısında verilen inv_ kodunu girerek sonuçlarınızı hesaba bağlayabilirsiniz.',
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              height: 1.35,
            ),
          ),
          if (!_hasInvite) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    enabled: !_isLoadingCode && !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Davet kodu veya QR bağlantısı',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _isLoadingCode || _isLoading ? null : _loadInviteFromCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoadingCode
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Doğrula'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    final inviteEmailLocked =
        _hasInvite && (_invite?.email ?? '').trim().isNotEmpty;

    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _firstNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Ad'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _lastNameController,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Soyad'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerEmailController,
          enabled: !_isLoading && !inviteEmailLocked,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('E-posta'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPasswordController,
          enabled: !_isLoading,
          obscureText: _obscureRegisterPassword,
          decoration: _inputDecoration('Şifre').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegisterPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureRegisterPassword = !_obscureRegisterPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _registerPasswordConfirmController,
          enabled: !_isLoading,
          obscureText: _obscureRegisterConfirm,
          decoration: _inputDecoration('Şifre Tekrar').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegisterConfirm
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureRegisterConfirm = !_obscureRegisterConfirm;
                });
              },
            ),
          ),
          onSubmitted: (_) => _isLoading ? null : _registerAndClaim(),
        ),
        const SizedBox(height: 12),
        _buildLegalCheckboxes(),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _registerAndClaim,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.lock_open_outlined),
          label: Text(
            _hasInvite
                ? 'Hesap Oluştur ve Sonuçlarıma Bağla'
                : 'Hesap Oluştur ve Devam Et',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _loginEmailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('E-posta'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _loginPasswordController,
          enabled: !_isLoading,
          obscureText: _obscureLoginPassword,
          decoration: _inputDecoration('Şifre').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscureLoginPassword = !_obscureLoginPassword);
              },
            ),
          ),
          onSubmitted: (_) => _isLoading ? null : _loginAndClaim(),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _loginAndClaim,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.login_outlined),
          label: Text(
            _hasInvite
                ? 'Giriş Yap ve Sonuçlarıma Bağla'
                : 'Giriş Yap ve Uygulamaya Geç',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.teal.shade700,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Hazırsınız.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF10323B),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasInvite
                ? 'Sonuçlarınız hesabınıza bağlandı. Analiz raporunuzu, kullanım önerilerinizi ve destek seçeneklerinizi uygulama içinde görüntüleyebilirsiniz.'
                : 'Hesabınız hazır. Optiyou uygulamasına geçebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => widget.onOpenApp(user),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Uygulamaya Geç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          Text(trailingText),
        ],
      ),
    );
  }
}

class _HeroWelcomeSection extends StatelessWidget {
  final bool hasToken;
  final String source;
  final bool isLoadingInvite;
  final String? inviteError;
  final VoidCallback onOpenResults;
  final VoidCallback onOpenGuide;

  const _HeroWelcomeSection({
    required this.hasToken,
    required this.source,
    required this.isLoadingInvite,
    required this.inviteError,
    required this.onOpenResults,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 760),
      padding: const EdgeInsets.fromLTRB(18, 44, 18, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 820;
              final visual = const _HeroVisual();

              final text = Column(
                crossAxisAlignment:
                    narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment:
                        narrow ? WrapAlignment.center : WrapAlignment.start,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        icon: Icons.qr_code_2_outlined,
                        text: 'QR deneyimi',
                      ),
                      _Pill(
                        icon: Icons.verified_user_outlined,
                        text: hasToken
                            ? 'Güvenli erişim algılandı'
                            : 'Genel bilgilendirme',
                      ),
                      _Pill(
                        icon: Icons.analytics_outlined,
                        text: 'Kaynak: $source',
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Kişiselleştirilmiş iç taban deneyiminiz başladı.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: Color(0xFF072B36),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Optiyou iç tabanınız; dijital ölçüm, basınç analizi ve uzman değerlendirmesiyle size özel bir destek çözümüne dönüştürülür.',
                    textAlign: narrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      height: 1.55,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (isLoadingInvite)
                    const _InfoBanner(
                      icon: Icons.hourglass_top_outlined,
                      text: 'QR bağlantısı kontrol ediliyor...',
                      color: Colors.teal,
                    )
                  else if (inviteError != null)
                    _InfoBanner(
                      icon: Icons.info_outline,
                      text: inviteError!,
                      color: Colors.orange,
                    )
                  else if (hasToken)
                    const _InfoBanner(
                      icon: Icons.lock_open_outlined,
                      text:
                          'Sonuçlarınıza güvenli erişim için aynı sayfada hesap oluşturabilir veya giriş yapabilirsiniz.',
                      color: Colors.teal,
                    ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment:
                        narrow ? WrapAlignment.center : WrapAlignment.start,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onOpenResults,
                        icon: const Icon(Icons.insights_outlined),
                        label: const Text('Sonuçlarımı Güvenli Şekilde Gör'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: onOpenGuide,
                        icon: const Icon(Icons.menu_book_outlined),
                        label: const Text('Kullanım Rehberi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade800,
                          side: BorderSide(color: Colors.teal.shade200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              if (narrow) {
                return Column(
                  children: [
                    visual,
                    const SizedBox(height: 24),
                    text,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 11, child: text),
                  const SizedBox(width: 34),
                  Expanded(flex: 9, child: visual),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HeroVisual extends StatefulWidget {
  const _HeroVisual();

  @override
  State<_HeroVisual> createState() => _HeroVisualState();
}

class _HeroVisualState extends State<_HeroVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: .95,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.teal.shade900,
                  const Color(0xFF072B36),
                  Colors.blueGrey.shade900,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(.22),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DataFootPainter(progress: _controller.value),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(.16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_graph_outlined,
                              color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '3D ölçümden kişisel desteğe uzanan dijital üretim akışı',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.92),
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TechnologyStorySection extends StatelessWidget {
  final double Function(int index) focusForStep;

  const _TechnologyStorySection({
    required this.focusForStep,
  });

  static const _steps = [
    _TechStep(
      icon: Icons.view_in_ar_outlined,
      badge: '01',
      title: 'Dijital Ölçüm',
      subtitle:
          '3D tarama, referans görseller ve ölçüm kayıtları aynı kullanıcı yolculuğunda birleşir.',
    ),
    _TechStep(
      icon: Icons.blur_on_outlined,
      badge: '02',
      title: 'Basınç Haritası',
      subtitle:
          'Yük dağılımı, temas alanı ve denge bilgisi görsel olarak anlamlandırılır.',
    ),
    _TechStep(
      icon: Icons.psychology_alt_outlined,
      badge: '03',
      title: 'Uzman Değerlendirmesi',
      subtitle:
          'Uzman; ölçüm verisini, klinik bilgiyi ve kullanım ihtiyacını birlikte yorumlar.',
    ),
    _TechStep(
      icon: Icons.precision_manufacturing_outlined,
      badge: '04',
      title: 'Kişisel Üretim',
      subtitle:
          'Tasarım veriye dayalı hazırlanır ve ürün kullanım amacına göre kişiselleştirilir.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 44, 18, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                eyebrow: 'Teknoloji akışı',
                title: 'Veri, uzmanlık ve üretim tek bir çizgide birleşir.',
                subtitle:
                    'Aşağı indikçe aktif adım öne çıkar; tamamlanan adımlar arka plana çekilir.',
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 760;

                  if (narrow) {
                    return Column(
                      children: List.generate(_steps.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _TechStepCard(
                            step: _steps[index],
                            focus: math.max(.64, focusForStep(index)),
                          ),
                        );
                      }),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: _PipelinePainter(
                            progress: (focusForStep(1) +
                                    focusForStep(2) * .4 +
                                    focusForStep(3) * .4)
                                .clamp(0.0, 1.0)
                                .toDouble(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: List.generate(_steps.length, (index) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index == _steps.length - 1 ? 0 : 18,
                                  ),
                                  child: _TechStepCard(
                                    step: _steps[index],
                                    focus:
                                        math.max(.28, focusForStep(index)),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 28),
                      const Expanded(child: _TechnologyOutcomeCard()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechStepCard extends StatelessWidget {
  final _TechStep step;
  final double focus;

  const _TechStepCard({
    required this.step,
    required this.focus,
  });

  @override
  Widget build(BuildContext context) {
    final scale = .94 + focus * .06;
    final opacity = .55 + focus * .45;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 260),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Color.lerp(
                Colors.blueGrey.shade100,
                Colors.teal.shade300,
                focus,
              )!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(.05 + focus * .12),
                blurRadius: 8 + focus * 18,
                offset: Offset(0, 5 + focus * 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.teal.withOpacity(.10 + focus * .06),
                ),
                child: Icon(step.icon, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${step.badge}  ${step.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10323B),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      step.subtitle,
                      style: TextStyle(
                        color: Colors.blueGrey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechnologyOutcomeCard extends StatelessWidget {
  const _TechnologyOutcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 392),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFF072B36),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(.22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MiniGridPainter())),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hub_outlined,
                  color: Colors.tealAccent.shade100, size: 34),
              const SizedBox(height: 16),
              const Text(
                'Dijital ayak sağlığı kaydı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kullanıcı; analiz, ürün, kullanım önerisi ve destek geçmişine tek hesaptan ulaşır.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.78),
                  height: 1.45,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _DarkMetric(label: 'Ölçüm', value: '3D + Basınç'),
                  _DarkMetric(label: 'Değerlendirme', value: 'Uzman'),
                  _DarkMetric(label: 'Çıktı', value: 'Kişisel Ürün'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PressurePreviewSection extends StatelessWidget {
  final double progress;

  const _PressurePreviewSection({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 42, 18, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 820;
              final visual = AspectRatio(
                aspectRatio: 1.15,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.84),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.teal.withOpacity(.12)),
                  ),
                  child: CustomPaint(
                    painter: _PressureMapPreviewPainter(progress: progress),
                  ),
                ),
              );

              final text = Column(
                crossAxisAlignment:
                    narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    eyebrow: 'Raporu anlamak kolay',
                    title: 'Basınç haritası sade kartlara dönüşür.',
                    subtitle:
                        'Kullanıcı gerçek raporuna geçtiğinde neye bakacağını önceden öğrenir.',
                  ),
                  const SizedBox(height: 18),
                  const _ReportPreviewTile(
                    icon: Icons.thermostat_auto_outlined,
                    title: 'Yük dağılımı',
                    text:
                        'Ayağın hangi bölgelerine daha fazla yük bindiğini gösterir.',
                  ),
                  const _ReportPreviewTile(
                    icon: Icons.balance_outlined,
                    title: 'Denge ve stabilite',
                    text:
                        'Yük merkezinizin ayak üzerinde nasıl dağıldığını açıklar.',
                  ),
                  const _ReportPreviewTile(
                    icon: Icons.architecture_outlined,
                    title: 'Ark desteği',
                    text:
                        'Ayak kavisi ve destek ihtiyacını anlaşılır hale getirir.',
                  ),
                ],
              );

              if (narrow) {
                return Column(
                  children: [
                    visual,
                    const SizedBox(height: 22),
                    text,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: visual),
                  const SizedBox(width: 36),
                  Expanded(child: text),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UsageGuideSection extends StatelessWidget {
  final VoidCallback onOpenResults;

  const _UsageGuideSection({
    required this.onOpenResults,
  });

  static const items = [
    _GuideItem(
      icon: Icons.timer_outlined,
      title: 'İlk gün kısa süreli kullanın',
      text:
          'İlk gün 1–2 saat ile başlayıp alışma süresine göre kullanımı artırın.',
    ),
    _GuideItem(
      icon: Icons.checkroom_outlined,
      title: 'Ayakkabı içinde doğru konumlandırın',
      text:
          'İç tabanın topuk kısmının ayakkabı içinde tam oturduğundan emin olun.',
    ),
    _GuideItem(
      icon: Icons.sync_alt_outlined,
      title: 'Alışma süresi normaldir',
      text:
          'Yeni destek yapısı vücudunuz tarafından birkaç gün içinde daha doğal algılanır.',
    ),
    _GuideItem(
      icon: Icons.report_gmailerrorred_outlined,
      title: 'Baskı veya sürtünme olursa bildirin',
      text:
          'Rahatsızlık, sürtünme veya yoğun baskı hissederseniz uzmanınıza ulaşın.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 760;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 46, 18, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                eyebrow: 'Kullanım rehberi',
                title: 'Üründen maksimum fayda almak için sade adımlar.',
                subtitle:
                    'Bu rehber herkes tarafından görülebilir; kişisel rapor için güvenli hesap gerekir.',
              ),
              const SizedBox(height: 22),
              GridView.builder(
                itemCount: items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isNarrow ? 1 : 2,
                  mainAxisExtent: 156,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) => _GuideCard(item: items[index]),
              ),
              const SizedBox(height: 22),
              Center(
                child: OutlinedButton.icon(
                  onPressed: onOpenResults,
                  icon: const Icon(Icons.insights_outlined),
                  label: const Text('Kişisel Sonuçlarıma Geç'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.teal.shade800,
                    side: BorderSide(color: Colors.teal.shade200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  final VoidCallback onOpenResults;

  const _SupportSection({
    required this.onOpenResults,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 32, 18, 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF072B36),
              borderRadius: BorderRadius.circular(30),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 700;
                final content = Column(
                  crossAxisAlignment:
                      narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Desteğe ihtiyacınız olursa buradayız.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hesabınızı oluşturduktan sonra destek taleplerini, kullanım notlarını ve takip ölçümlerini uygulama içinden yönetebilirsiniz.',
                      textAlign: narrow ? TextAlign.center : TextAlign.left,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.72),
                        height: 1.45,
                      ),
                    ),
                  ],
                );

                final action = ElevatedButton.icon(
                  onPressed: onOpenResults,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Ekosisteme Katıl'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade900,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );

                if (narrow) {
                  return Column(
                    children: [
                      content,
                      const SizedBox(height: 18),
                      action,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 24),
                    action,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ClosedAccessCard extends StatelessWidget {
  final bool hasInvite;
  final String? inviteError;
  final VoidCallback onOpen;

  const _ClosedAccessCard({
    required this.hasInvite,
    required this.inviteError,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.94),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.teal.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 720;
          final text = Column(
            crossAxisAlignment:
                narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Text(
                hasInvite ? 'Sonuçlarınıza erişim hazır.' : 'Sonuçlarınıza erişin.',
                textAlign: narrow ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                  color: Color(0xFF10323B),
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                inviteError ??
                    'Kayıt veya giriş işlemini bu sayfadan tamamlayıp uygulamaya geçebilirsiniz.',
                textAlign: narrow ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  height: 1.45,
                ),
              ),
            ],
          );

          final button = ElevatedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Güvenli Erişimi Başlat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );

          if (narrow) {
            return Column(
              children: [
                text,
                const SizedBox(height: 16),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 24),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _AccessIntro extends StatelessWidget {
  final bool hasInvite;
  final String? email;
  final bool emailConfirmationRequired;

  const _AccessIntro({
    required this.hasInvite,
    required this.email,
    required this.emailConfirmationRequired,
  });

  @override
  Widget build(BuildContext context) {
    final emailText = (email ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Güvenli erişim',
          title: 'Tüm işlemi bu sayfada tamamlayın.',
          subtitle:
              'Sonuçlar kişisel veri içerebilir. Bu yüzden raporlarınızı size ait güvenli bir hesapla ilişkilendiriyoruz.',
        ),
        const SizedBox(height: 18),
        const _AccessBenefit(
          icon: Icons.analytics_outlined,
          title: 'Analiz raporunuz',
          text: 'Basınç, denge ve destek bilgilerini uygulamada görüntüleyin.',
        ),
        const _AccessBenefit(
          icon: Icons.menu_book_outlined,
          title: 'Kullanım önerileri',
          text: 'İlk kullanım, alışma süreci ve bakım adımlarına ulaşın.',
        ),
        const _AccessBenefit(
          icon: Icons.support_agent_outlined,
          title: 'Destek ve takip',
          text: 'Ürünle ilgili destek ve sonraki ölçümler için hesabınızı kullanın.',
        ),
        const SizedBox(height: 12),
        if (hasInvite)
          _InfoBanner(
            icon: Icons.verified_outlined,
            text: emailText.isEmpty
                ? 'Davet doğrulandı. Hesap oluşturunca sonuçlarınız bu hesaba bağlanacak.'
                : 'Davet doğrulandı. E-posta: $emailText',
            color: Colors.teal,
          )
        else
          const _InfoBanner(
            icon: Icons.info_outline,
            text:
                'Kişisel sonuçlar için broşürdeki QR bağlantısı veya davet kodu gerekir. Kod yoksa yine hesap oluşturup uygulamaya geçebilirsiniz.',
            color: Colors.orange,
          ),
        if (emailConfirmationRequired) ...[
          const SizedBox(height: 10),
          const _InfoBanner(
            icon: Icons.mark_email_read_outlined,
            text:
                'E-posta onayı aktif görünüyor. Onaydan sonra aynı sayfadan giriş yapabilirsiniz.',
            color: Colors.blue,
          ),
        ],
      ],
    );
  }
}

class _StickyActionBar extends StatelessWidget {
  final bool isReady;
  final VoidCallback onOpenResults;
  final VoidCallback onOpenGuide;

  const _StickyActionBar({
    required this.isReady,
    required this.onOpenResults,
    required this.onOpenGuide,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.teal.withOpacity(.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(.16),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenResults,
                  icon: Icon(
                    isReady
                        ? Icons.dashboard_customize_outlined
                        : Icons.lock_open_outlined,
                  ),
                  label: Text(isReady ? 'Uygulamaya Geç' : 'Sonuçlarımı Gör'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Kullanım rehberi',
                onPressed: onOpenGuide,
                icon: Icon(
                  Icons.menu_book_outlined,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            color: Colors.teal.shade700,
            fontWeight: FontWeight.w800,
            letterSpacing: .9,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF10323B),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.blueGrey.shade700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.76),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.teal.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.teal.shade700),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;

  const _InfoBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.20)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;

  const _PanelMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _InfoBanner(icon: icon, text: text, color: color);
  }
}

class _SegmentButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const _SegmentButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: selected ? Colors.white : Colors.transparent,
        foregroundColor:
            selected ? Colors.teal.shade800 : Colors.blueGrey.shade600,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AccessBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _AccessBenefit({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPreviewTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ReportPreviewTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.blueGrey.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10323B),
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final _GuideItem item;

  const _GuideCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.90),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.teal.withOpacity(.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: Colors.teal.shade700, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.title}\n',
                    style: const TextStyle(
                      color: Color(0xFF10323B),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: item.text,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DarkMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(.55))),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackgroundPainter extends CustomPainter {
  final double progress;

  const _WelcomeBackgroundPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final t = (progress / 1200).clamp(0.0, 1.0);

    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFE6F7F5),
        const Color(0xFFF7FBFC),
        Color.lerp(const Color(0xFFF7FBFC), const Color(0xFFEAF4FF), t)!,
      ],
    ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    final circlePaint = Paint()
      ..color = Colors.teal.withOpacity(.045)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * .16, 180 + math.sin(t * math.pi) * 40),
      170,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * .88, 560 + math.cos(t * math.pi) * 50),
      230,
      circlePaint,
    );

    final gridPaint = Paint()
      ..color = Colors.teal.withOpacity(.035)
      ..strokeWidth = 1;

    const gap = 46.0;
    final offset = (progress * .05) % gap;

    for (double x = -gap + offset; x < size.width + gap; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = -gap + offset; y < size.height + gap; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomeBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DataFootPainter extends CustomPainter {
  final double progress;

  const _DataFootPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .52, size.height * .45);
    final footPaint = Paint()
      ..color = Colors.white.withOpacity(.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(center.dx - size.width * .12, center.dy + size.height * .34)
      ..cubicTo(
        center.dx - size.width * .22,
        center.dy + size.height * .12,
        center.dx - size.width * .16,
        center.dy - size.height * .18,
        center.dx - size.width * .05,
        center.dy - size.height * .34,
      )
      ..cubicTo(
        center.dx + size.width * .05,
        center.dy - size.height * .45,
        center.dx + size.width * .26,
        center.dy - size.height * .28,
        center.dx + size.width * .22,
        center.dy - size.height * .03,
      )
      ..cubicTo(
        center.dx + size.width * .18,
        center.dy + size.height * .22,
        center.dx + size.width * .05,
        center.dy + size.height * .40,
        center.dx - size.width * .12,
        center.dy + size.height * .34,
      );

    canvas.drawPath(path, footPaint);

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 22; i++) {
      final angle = i * .82 + progress * 1.8;
      final radius = size.shortestSide * (.12 + (i % 5) * .028);
      final x = center.dx + math.cos(angle) * radius * .8;
      final y = center.dy + math.sin(angle * 1.25) * radius * 1.25;
      final alpha =
          .25 + .45 * ((math.sin(progress * math.pi * 2 + i) + 1) / 2);

      dotPaint.color = Colors.tealAccent.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), 3.5 + (i % 4), dotPaint);
    }

    final linePaint = Paint()
      ..color = Colors.tealAccent.withOpacity(.18)
      ..strokeWidth = 1.2;

    for (int i = 0; i < 9; i++) {
      final y = size.height * (.18 + i * .075);
      canvas.drawLine(
        Offset(size.width * .08, y),
        Offset(size.width * (.52 + .16 * math.sin(progress * math.pi + i)), y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DataFootPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PipelinePainter extends CustomPainter {
  final double progress;

  const _PipelinePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x = 27.0;
    final top = 38.0;
    final bottom = size.height - 38.0;

    final basePaint = Paint()
      ..color = Colors.blueGrey.withOpacity(.10)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = Colors.teal.withOpacity(.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x, top), Offset(x, bottom), basePaint);
    final activeBottom = top + (bottom - top) * progress.clamp(0.0, 1.0);
    canvas.drawLine(Offset(x, top), Offset(x, activeBottom), activePaint);
  }

  @override
  bool shouldRepaint(covariant _PipelinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _MiniGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(.05)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniGridPainter oldDelegate) => false;
}

class _PressureMapPreviewPainter extends CustomPainter {
  final double progress;

  const _PressureMapPreviewPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final footPaint = Paint()
      ..color = Colors.blueGrey.withOpacity(.08)
      ..style = PaintingStyle.fill;

    final leftFoot = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .18,
        size.height * .14,
        size.width * .23,
        size.height * .68,
      ),
      Radius.circular(size.width * .14),
    );

    final rightFoot = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .56,
        size.height * .14,
        size.width * .23,
        size.height * .68,
      ),
      Radius.circular(size.width * .14),
    );

    canvas.drawRRect(leftFoot, footPaint);
    canvas.drawRRect(rightFoot, footPaint);

    final spots = [
      Offset(size.width * .28, size.height * .28),
      Offset(size.width * .31, size.height * .55),
      Offset(size.width * .66, size.height * .34),
      Offset(size.width * .69, size.height * .60),
      Offset(size.width * .23, size.height * .70),
      Offset(size.width * .74, size.height * .72),
    ];

    for (int i = 0; i < spots.length; i++) {
      final p = spots[i];
      final pulse = (math.sin(progress * math.pi * 2 + i) + 1) / 2;
      final radius = size.shortestSide * (.055 + pulse * .035);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.teal.withOpacity(.48),
            Colors.teal.withOpacity(.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: p, radius: radius));

      canvas.drawCircle(p, radius, paint);
    }

    final cardPaint = Paint()
      ..color = Colors.white.withOpacity(.88)
      ..style = PaintingStyle.fill;

    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .15,
        size.height * .78,
        size.width * .70,
        size.height * .14,
      ),
      const Radius.circular(18),
    );

    canvas.drawRRect(card, cardPaint);

    final barPaint = Paint()
      ..color = Colors.teal.withOpacity(.70)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawLine(
      Offset(size.width * .23, size.height * .84),
      Offset(size.width * (.23 + .46 * progress), size.height * .84),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PressureMapPreviewPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _WelcomeRouteData {
  final String? source;
  final String? inviteToken;

  const _WelcomeRouteData({
    required this.source,
    required this.inviteToken,
  });
}

class _TechStep {
  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;

  const _TechStep({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
  });
}

class _GuideItem {
  final IconData icon;
  final String title;
  final String text;

  const _GuideItem({
    required this.icon,
    required this.title,
    required this.text,
  });
}

enum _AccessMode {
  register,
  login,
}
