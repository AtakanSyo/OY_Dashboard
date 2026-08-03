
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:oy_site/data/repositories/supabase_patient_invite_repository.dart';
import 'package:oy_site/data/repositories/supabase_patient_repository.dart';
import 'package:oy_site/legal/legal_document_registry.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/patient_invite_model.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _logoAssetPath = 'assets/images/branding/logo.png';
const String _heroVideoAssetPath = 'assets/images/branding/welcome_flow.mp4';

EdgeInsets _sectionPadding(
  BuildContext context, {
  required double top,
  required double bottom,
}) {
  final isNarrow = MediaQuery.of(context).size.width < 720;

  return EdgeInsets.fromLTRB(isNarrow ? 18 : 72, top, 18, bottom);
}


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
  bool _accessPanelOpen = true;
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
              'Bu QR kod ile ilişkili ölçüm daveti bulunamadı. Yine de hesap oluşturup uygulamaya geçebilirsiniz.';
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
    final maxExtent = _maxScrollExtent;
    final target = maxExtent <= 0 ? 0.0 : maxExtent * .34;

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

  double get _maxScrollExtent {
    if (!_scrollController.hasClients) return 0;
    return _scrollController.position.maxScrollExtent;
  }

  double get _scrollProgress {
    final maxExtent = _maxScrollExtent;
    if (maxExtent <= 0) return 0;
    return (_scrollOffset / maxExtent).clamp(0.0, 1.0).toDouble();
  }

  double _focusFromProgress({
    required int index,
    required List<double> anchors,
    required double width,
    double minimum = .08,
  }) {
    final safeIndex = index.clamp(0, anchors.length - 1).toInt();
    final distance = (_scrollProgress - anchors[safeIndex]).abs();
    final focus = 1 - distance / width;
    return math.max(minimum, focus.clamp(0.0, 1.0).toDouble());
  }

  double _focusForStep(int index) {
    return _focusFromProgress(
      index: index,
      anchors: const [.28, .40, .52, .64],
      width: .16,
      minimum: .20,
    );
  }

  double _mainSectionFocus(BuildContext context, int index) {
    return _focusFromProgress(
      index: index,
      anchors: const [0, .50, 1],
      width: .34,
      minimum: .04,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _WelcomeBackgroundPainter(progress: _scrollOffset),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: _MeasurementFlowRail(progress: _scrollProgress),
              ),
            ),
            Positioned.fill(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _FocusStage(
                      focus: _mainSectionFocus(context, 0),
                      child: _HeroWelcomeSection(
                        hasToken: (_inviteToken ?? '').trim().isNotEmpty,
                        source: _source ?? 'qr',
                        isLoadingInvite: _isLoadingInvite,
                        inviteError: _inviteError,
                        onOpenResults: _openAccessPanel,
                        onOpenGuide: _openAccessPanel,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    key: _accessPanelKey,
                    child: _FocusStage(
                      focus: _mainSectionFocus(context, 1),
                      child: _RegistrationSection(
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
                  SliverToBoxAdapter(
                    child: _FocusStage(
                      focus: _mainSectionFocus(context, 2),
                      child: _ResultsSection(
                        isReady: _readyUser != null,
                        onOpenResults: _readyUser == null
                            ? _openAccessPanel
                            : () => _openApp(_readyUser!),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width < 720 ? 18 : 24,
              top: 18,
              child: const IgnorePointer(child: _FloatingLogo()),
            ),
          ],
        ),
      ),
    );
  }
}




class _FloatingLogo extends StatelessWidget {
  const _FloatingLogo();

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 720;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 10 : 14,
        vertical: isNarrow ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        _logoAssetPath,
        height: isNarrow ? 28 : 34,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Text(
          'Optiyou',
          style: TextStyle(
            color: Color(0xFF072B36),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _RegistrationSection extends StatelessWidget {
  final Widget child;

  const _RegistrationSection({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 720),
      padding: _sectionPadding(context, top: 48, bottom: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                eyebrow: 'Kullanıcı kaydı',
                title: 'Sonuçlarınızı size ait güvenli hesaba bağlayın.',
                subtitle:
                    'QR bağlantısı ölçüm kaydınızı tanır. Hesap oluşturduğunuzda veya giriş yaptığınızda analiz raporu ve ürün önerisi uygulama hesabınızla ilişkilendirilir.',
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final bool isReady;
  final VoidCallback onOpenResults;

  const _ResultsSection({
    required this.isReady,
    required this.onOpenResults,
  });

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 820;

    final content = Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Sonuçlar'.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(.76),
            fontWeight: FontWeight.w800,
            letterSpacing: .9,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Analiz raporu, ürün önerisi ve takip bilgileri tek yerde.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Kayıt tamamlandığında ölçüm geçmişinizi, uzman değerlendirmesini ve size önerilen ürünü Optiyou hesabınızdan görüntüleyebilirsiniz.',
          textAlign: narrow ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: Colors.white.withOpacity(.80),
            height: 1.5,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 22),
        const _ResultBenefit(
          icon: Icons.analytics_outlined,
          title: 'Analiz özeti',
          text: 'Basınç, denge ve destek ihtiyacı sade başlıklarla sunulur.',
        ),
        const _ResultBenefit(
          icon: Icons.recommend_outlined,
          title: 'Size uygun ürün önerisi',
          text: 'Değerlendirme sonucuna göre ürün listemizden uygun çözüm seçilir.',
        ),
        const _ResultBenefit(
          icon: Icons.timeline_outlined,
          title: 'Takip geçmişi',
          text: 'Sonraki ölçümlerde değişim ve kullanım notları karşılaştırılabilir.',
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onOpenResults,
          icon: Icon(isReady ? Icons.dashboard_customize_outlined : Icons.person_add_alt_1_outlined),
          label: Text(isReady ? 'Sonuçları Aç' : 'Kullanıcı Kaydına Geç'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.teal.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );

    final preview = const _ResultsPreviewPanel();

    return Container(
      constraints: const BoxConstraints(minHeight: 700),
      padding: _sectionPadding(context, top: 52, bottom: 72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Container(
            padding: EdgeInsets.all(narrow ? 22 : 30),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(.22),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: narrow
                ? Column(
                    children: [
                      preview,
                      const SizedBox(height: 24),
                      content,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 32),
                      Expanded(child: preview),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ResultBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ResultBenefit({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(.14)),
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.74),
                      height: 1.34,
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

class _ResultsPreviewPanel extends StatelessWidget {
  const _ResultsPreviewPanel();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.04,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(.40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.insights_outlined, color: Colors.teal.shade700),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Kişisel sonuç görünümü',
                    style: TextStyle(
                      color: Color(0xFF10323B),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _ResultPreviewRow(label: 'Analiz skoru', value: '82 / 100'),
            const _ResultPreviewRow(label: 'Destek ihtiyacı', value: 'Orta'),
            const _ResultPreviewRow(label: 'Önerilen ürün', value: 'Kişisel iç taban'),
            const SizedBox(height: 18),
            Expanded(
              child: CustomPaint(
                painter: _ResultsPreviewPainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultPreviewRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF10323B),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsPreviewPainter extends CustomPainter {
  const _ResultsPreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.teal.withOpacity(.08)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.teal.withOpacity(.20)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final points = <Offset>[
      Offset(size.width * .08, size.height * .72),
      Offset(size.width * .24, size.height * .54),
      Offset(size.width * .40, size.height * .60),
      Offset(size.width * .58, size.height * .36),
      Offset(size.width * .78, size.height * .42),
      Offset(size.width * .92, size.height * .24),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.teal.shade700
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final p in points) {
      canvas.drawCircle(p, 8, basePaint);
      canvas.drawCircle(p, 4.5, Paint()..color = Colors.teal.shade700);
    }
  }

  @override
  bool shouldRepaint(covariant _ResultsPreviewPainter oldDelegate) => false;
}

class _FocusStage extends StatelessWidget {
  final double focus;
  final Widget child;

  const _FocusStage({
    required this.focus,
    required this.child,
  });

  List<double> _saturationMatrix(double saturation) {
    final s = saturation.clamp(0.0, 1.0);
    final inv = 1 - s;
    const r = .2126;
    const g = .7152;
    const b = .0722;

    return <double>[
      r * inv + s,
      g * inv,
      b * inv,
      0,
      0,
      r * inv,
      g * inv + s,
      b * inv,
      0,
      0,
      r * inv,
      g * inv,
      b * inv + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final normalized = focus.clamp(0.0, 1.0).toDouble();
    final inactive = 1 - normalized;
    final scale = .84 + normalized * .16;
    final opacity = .30 + normalized * .70;
    final saturation = .03 + normalized * .97;
    final yOffset = inactive * 22;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        child: AnimatedSlide(
          offset: Offset(0, yOffset / 100),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(_saturationMatrix(saturation)),
            child: child,
          ),
        ),
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

    final email = (_invite?.email ?? '').trim();
    if (email.isNotEmpty) {
      _registerEmailController.text = email;
      _loginEmailController.text = email;
    }
  }

  @override
  void dispose() {
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

    if (!(_acceptedMembershipAgreement &&
        _acceptedPrivacyPolicy &&
        _acceptedTermsOfUse)) {
      setState(() {
        _errorMessage =
            'Devam etmek için sözleşme ve bilgilendirme metinlerini kabul etmelisiniz.';
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
        color: Colors.teal.shade700,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.teal.shade600),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.18),
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
            onGreenBackground: true,
          );

          final authContent = readyUser == null
              ? _buildAuthContent()
              : _buildSuccessView(readyUser);

          final auth = Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: authContent,
          );

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
    final acceptedRequiredDocuments = _acceptedMembershipAgreement &&
        _acceptedPrivacyPolicy &&
        _acceptedTermsOfUse;

    return CheckboxListTile(
      value: acceptedRequiredDocuments,
      onChanged: _isLoading
          ? null
          : (value) {
              final checked = value ?? false;
              setState(() {
                _acceptedMembershipAgreement = checked;
                _acceptedPrivacyPolicy = checked;
                _acceptedTermsOfUse = checked;
                _errorMessage = null;
              });
            },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Devam ederek '),
          InkWell(
            onTap: () => _showLegalDocument(
              LegalDocumentCodes.uyelikSozlesmesi,
            ),
            child: const Text(
              'Üyelik Sözleşmesi',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text(', '),
          InkWell(
            onTap: () => _showLegalDocument(
              LegalDocumentCodes.aydinlatmaMetni,
            ),
            child: const Text(
              'Aydınlatma Metni',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text(' ve '),
          InkWell(
            onTap: () => _showLegalDocument(
              LegalDocumentCodes.kullanimKosullari,
            ),
            child: const Text(
              'Kullanım Koşulları',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Text('’nı okuduğumu ve kabul ettiğimi onaylıyorum.'),
        ],
      ),
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
      padding: _sectionPadding(context, top: 86, bottom: 42),
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
                    children: const [
                      _Pill(
                        icon: Icons.health_and_safety_outlined,
                        text: 'Ayak Sağlığı Ekosistemi',
                      ),
                      _Pill(
                        icon: Icons.precision_manufacturing_outlined,
                        text: 'Dijital Üretim',
                      ),
                      _Pill(
                        icon: Icons.speed_outlined,
                        text: 'Performans Desteği',
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Optiyou ekosistemine hoş geldiniz.',
                    textAlign: narrow ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      fontSize: narrow ? 34 : 42,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: const Color(0xFF072B36),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ölçüm, uzman değerlendirmesi ve sonuç erişimini tek bir kullanıcı yolculuğunda birleştiriyoruz. QR bağlantısı üzerinden hesabınızı oluşturup kişisel sonuçlarınıza güvenli şekilde ulaşabilirsiniz.',
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
                      text: 'Sonuç erişim bağlantısı kontrol ediliyor...',
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
                          'Bu bağlantı kişisel sonuç erişimi için hazır. Hesap oluşturma veya giriş işlemini aynı sayfa içinde tamamlayabilirsiniz.',
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
                        label: const Text('Kullanıcı Kaydına Geç'),
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

class _HeroVisualState extends State<_HeroVisual> {
  late final VideoPlayerController _controller;
  bool _isVideoReady = false;
  bool _hasVideoError = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(_heroVideoAssetPath)
      ..setLooping(true)
      ..setVolume(0);

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isVideoReady = true);
      _controller.play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _hasVideoError = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          color: const Color(0xFF072B36),
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
                child: _isVideoReady && !_hasVideoError
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const _HeroVideoFallback(),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(.06),
                        Colors.black.withOpacity(.32),
                      ],
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

class _HeroVideoFallback extends StatefulWidget {
  const _HeroVideoFallback();

  @override
  State<_HeroVideoFallback> createState() => _HeroVideoFallbackState();
}

class _HeroVideoFallbackState extends State<_HeroVideoFallback>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal.shade900,
                const Color(0xFF072B36),
                Colors.blueGrey.shade900,
              ],
            ),
          ),
          child: CustomPaint(
            painter: _DataFootPainter(progress: _controller.value),
          ),
        );
      },
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
      title: 'Dijital Tarama',
      subtitle:
          'Ayak yapısı, referans görseller ve ölçüm kayıtları dijital bir kullanıcı profili altında toplanır.',
    ),
    _TechStep(
      icon: Icons.manage_search_outlined,
      badge: '02',
      title: 'Uzman Değerlendirmesi',
      subtitle:
          'Uzman; ölçüm verisini, kullanım ihtiyacını ve klinik notları birlikte değerlendirir.',
    ),
    _TechStep(
      icon: Icons.recommend_outlined,
      badge: '03',
      title: 'Size Uygun Ürün Önerisi',
      subtitle:
          'Değerlendirme sonuçlarına göre ürün listemiz içinden kullanıcının ihtiyacına en uygun çözüm önerilir.',
    ),
    _TechStep(
      icon: Icons.precision_manufacturing_outlined,
      badge: '04',
      title: 'Dijital Üretim',
      subtitle:
          'Onaylanan ürün seçimi ve tasarım girdileri dijital üretim sürecine aktarılır.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _sectionPadding(context, top: 44, bottom: 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(
                eyebrow: 'Teknoloji akışı',
                title: 'Ölçümden ürüne uzanan akış tek ekranda anlaşılır.',
                subtitle:
                    'Dijital tarama, uzman yorumu, ürün önerisi ve üretim adımları sade bir yolculuk olarak sunulur.',
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
              Icon(
                Icons.hub_outlined,
                color: Colors.tealAccent.shade100,
                size: 34,
              ),
              const SizedBox(height: 16),
              const Text(
                'Optiyou ekosisteminin kullanıcıya katkısı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tek bir ölçüm deneyimi, takip edilebilir sonuçlara ve farklı ürün seçeneklerine bağlanır.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.78),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              const _OutcomeBenefit(
                icon: Icons.timeline_outlined,
                title: 'Periyodik takip',
                text:
                    'Ölçüm ve ürün geçmişi zaman içinde karşılaştırılabilir hale gelir.',
              ),
              const _OutcomeBenefit(
                icon: Icons.category_outlined,
                title: 'Tek tarama ile çoklu ürün erişimi',
                text:
                    'Aynı dijital kayıt, iç taban ve farklı ürün aileleri için temel veri sağlar.',
              ),
              const _OutcomeBenefit(
                icon: Icons.psychology_alt_outlined,
                title: 'Yapay zeka destekli değerlendirme',
                text:
                    'Ölçüm çıktıları daha hızlı yorumlanır ve uzman karar süreci desteklenir.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutcomeBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _OutcomeBenefit({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withOpacity(.12)),
            ),
            child: Icon(icon, color: Colors.tealAccent.shade100, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.72),
                    height: 1.32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiEvaluationSection extends StatelessWidget {
  final double progress;

  const _AiEvaluationSection({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _sectionPadding(context, top: 42, bottom: 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 820;
              final visual = AspectRatio(
                aspectRatio: narrow ? 1.10 : 1.18,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.88),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.teal.withOpacity(.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(.09),
                        blurRadius: 22,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _AiEvaluationPreviewPainter(progress: progress),
                  ),
                ),
              );

              final text = Column(
                crossAxisAlignment:
                    narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: const [
                  _SectionHeader(
                    eyebrow: 'Yapay zeka destekli değerlendirme',
                    title: 'Ölçüm verisi uzman kararını destekleyen içgörüye dönüşür.',
                    subtitle:
                        'Dijital tarama, basınç verisi ve kullanım ihtiyacı birlikte yorumlanır. Yapay zeka destekli analiz; risk sinyallerini, destek ihtiyacını ve ürün uyumunu uzman değerlendirmesine hazır hale getirir.',
                  ),
                  SizedBox(height: 18),
                  _ReportPreviewTile(
                    icon: Icons.hub_outlined,
                    title: 'Veri bütünleştirme',
                    text:
                        'Tarama, basınç dağılımı, uzman notu ve ürün tercihleri aynı değerlendirme akışında bir araya gelir.',
                  ),
                  _ReportPreviewTile(
                    icon: Icons.psychology_alt_outlined,
                    title: 'Destek ihtiyacı sinyalleri',
                    text:
                        'Sistem; yüklenme bölgeleri, denge ve kullanım senaryosuna göre dikkat edilmesi gereken noktaları öne çıkarır.',
                  ),
                  _ReportPreviewTile(
                    icon: Icons.recommend_outlined,
                    title: 'Ürün önerisine hazırlık',
                    text:
                        'Değerlendirme sonuçları, ürün listemiz içinden kişiye uygun çözümün seçilmesini kolaylaştırır.',
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
        color: Colors.teal.shade700,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.teal.shade600),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(.20),
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
                  color: Colors.white,
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
                  color: Colors.white.withOpacity(.82),
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
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal.shade800,
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
  final bool onGreenBackground;

  const _AccessIntro({
    required this.hasInvite,
    required this.email,
    required this.emailConfirmationRequired,
    this.onGreenBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final emailText = (email ?? '').trim();

    final titleColor = onGreenBackground ? Colors.white : const Color(0xFF10323B);
    final mutedColor = onGreenBackground
        ? Colors.white.withOpacity(.80)
        : Colors.blueGrey.shade700;
    final eyebrowColor = onGreenBackground
        ? Colors.white.withOpacity(.76)
        : Colors.teal.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kullanıcı kaydı'.toUpperCase(),
          style: TextStyle(
            color: eyebrowColor,
            fontWeight: FontWeight.w800,
            letterSpacing: .9,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hesabınızı oluşturun ve sonuçlarınıza bağlanın.',
          style: TextStyle(
            color: titleColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Kişisel sonuçlarınızı güvenli şekilde görüntüleyebilmeniz için ölçüm kaydınızı size ait kullanıcı hesabıyla ilişkilendiriyoruz.',
          style: TextStyle(
            color: mutedColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        _AccessBenefit(
          icon: Icons.analytics_outlined,
          title: 'Analiz raporunuz',
          text: 'Basınç, denge ve destek bilgilerini uygulamada görüntüleyin.',
          onGreenBackground: onGreenBackground,
        ),
        _AccessBenefit(
          icon: Icons.recommend_outlined,
          title: 'Ürün öneriniz',
          text: 'Değerlendirme sonucuna göre size uygun ürün seçimine ulaşın.',
          onGreenBackground: onGreenBackground,
        ),
        _AccessBenefit(
          icon: Icons.timeline_outlined,
          title: 'Takip geçmişiniz',
          text: 'Sonraki ölçümlerde gelişimi ve kullanım notlarını takip edin.',
          onGreenBackground: onGreenBackground,
        ),
        const SizedBox(height: 12),
        if (hasInvite)
          _InfoBanner(
            icon: Icons.verified_outlined,
            text: emailText.isEmpty
                ? 'Davet doğrulandı. Hesap oluşturunca sonuçlarınız bu hesaba bağlanacak.'
                : 'Davet doğrulandı. E-posta: $emailText',
            color: Colors.teal,
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
  final bool onGreenBackground;

  const _AccessBenefit({
    required this.icon,
    required this.title,
    required this.text,
    this.onGreenBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = onGreenBackground ? Colors.white : Colors.teal.shade700;
    final titleColor = onGreenBackground ? Colors.white : Colors.black87;
    final textColor = onGreenBackground
        ? Colors.white.withOpacity(.78)
        : Colors.blueGrey.shade700;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      color: textColor,
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

class _MeasurementFlowRail extends StatelessWidget {
  final double progress;

  const _MeasurementFlowRail({
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showLabels = screenWidth >= 980;
    final railWidth = showLabels ? 230.0 : 46.0;
    final left = screenWidth < 720 ? 8.0 : 18.0;
    final top = screenWidth < 720 ? 92.0 : 112.0;
    final bottom = screenWidth < 720 ? 104.0 : 112.0;
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          bottom: bottom,
          child: SizedBox(
            width: railWidth,
            child: CustomPaint(
              painter: _MeasurementFlowRailPainter(
                progress: safeProgress,
                showLabels: showLabels,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MeasurementFlowRailPainter extends CustomPainter {
  final double progress;
  final bool showLabels;

  const _MeasurementFlowRailPainter({
    required this.progress,
    required this.showLabels,
  });

  static const _labels = [
    'Optiyou ekosistemi',
    'Kullanıcı kaydı',
    'Sonuçlar',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final lineX = 21.0;
    final top = 18.0;
    final bottom = size.height - 18.0;
    final lineHeight = bottom - top;
    final activeEnd = top + lineHeight * progress;

    final basePaint = Paint()
      ..color = Colors.teal.withOpacity(.13)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F766E), Color(0xFF7DD3FC)],
      ).createShader(Rect.fromLTWH(0, top, 1, lineHeight))
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(lineX, top), Offset(lineX, bottom), basePaint);
    canvas.drawLine(Offset(lineX, top), Offset(lineX, activeEnd), activePaint);

    for (var i = 0; i < _labels.length; i++) {
      final itemAnchor = i / (_labels.length - 1);
      final y = top + lineHeight * itemAnchor;
      final distance = (progress - itemAnchor).abs();
      final pulse = (1 - distance * (_labels.length - 1)).clamp(0.0, 1.0);
      final isCompleted = progress + .012 >= itemAnchor;
      final isCurrent = distance <= .17;

      final outerPaint = Paint()
        ..color = isCompleted
            ? Colors.teal.withOpacity(.18 + pulse * .18)
            : Colors.white.withOpacity(.72)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = isCompleted
            ? Colors.teal.withOpacity(.72)
            : Colors.blueGrey.withOpacity(.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 2.8 : 2;

      canvas.drawCircle(Offset(lineX, y), 9.5 + pulse * 3.5, outerPaint);
      canvas.drawCircle(Offset(lineX, y), 9.5, borderPaint);

      if (isCompleted) {
        canvas.drawCircle(
          Offset(lineX, y),
          4.2,
          Paint()..color = Colors.teal.shade700,
        );
      }

      if (showLabels) {
        final tp = TextPainter(
          text: TextSpan(
            text: _labels[i],
            style: TextStyle(
              color: isCurrent || isCompleted
                  ? const Color(0xFF0F3A42)
                  : Colors.blueGrey.shade400,
              fontSize: isCurrent ? 12.2 : 11.5,
              fontWeight: isCurrent || isCompleted
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: size.width - 42);

        tp.paint(canvas, Offset(38, y - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MeasurementFlowRailPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.showLabels != showLabels;
  }
}


class _AiEvaluationPreviewPainter extends CustomPainter {
  final double progress;

  const _AiEvaluationPreviewPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .43, size.height * .48);
    final cardPaint = Paint()..color = Colors.teal.withOpacity(.055);
    final strokePaint = Paint()
      ..color = Colors.teal.withOpacity(.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final profile = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: size.width * .36,
        height: size.height * .66,
      ),
      Radius.circular(size.width * .18),
    );

    canvas.drawRRect(profile, cardPaint);
    canvas.drawRRect(profile, strokePaint);

    final nodes = <Offset>[
      Offset(size.width * .26, size.height * .28),
      Offset(size.width * .40, size.height * .22),
      Offset(size.width * .55, size.height * .34),
      Offset(size.width * .32, size.height * .54),
      Offset(size.width * .51, size.height * .64),
      Offset(size.width * .42, size.height * .78),
    ];

    final linePaint = Paint()
      ..color = Colors.teal.withOpacity(.22)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], linePaint);
    }

    for (var i = 0; i < nodes.length; i++) {
      final pulse = (math.sin(progress * math.pi * 2 + i * .8) + 1) / 2;
      final radius = 7.0 + pulse * 3;
      canvas.drawCircle(
        nodes[i],
        radius,
        Paint()..color = Colors.teal.withOpacity(.24 + pulse * .25),
      );
      canvas.drawCircle(
        nodes[i],
        3.6,
        Paint()..color = Colors.teal.shade700,
      );
    }

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .60,
        size.height * .20,
        size.width * .30,
        size.height * .58,
      ),
      const Radius.circular(22),
    );

    canvas.drawRRect(
      panelRect,
      Paint()..color = const Color(0xFF072B36).withOpacity(.92),
    );

    final accentPaint = Paint()
      ..color = Colors.tealAccent.withOpacity(.72)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final mutedPaint = Paint()
      ..color = Colors.white.withOpacity(.20)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final bars = <double>[.78, .58, .70, .46];
    for (var i = 0; i < bars.length; i++) {
      final y = size.height * (.32 + i * .10);
      final x1 = size.width * .66;
      final x2 = size.width * .84;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), mutedPaint);
      canvas.drawLine(
        Offset(x1, y),
        Offset(x1 + (x2 - x1) * bars[i] * (.55 + progress * .45), y),
        accentPaint,
      );
    }

    final titlePainter = TextPainter(
      text: TextSpan(
        text: 'AI\nEvaluation',
        style: TextStyle(
          color: Colors.white.withOpacity(.88),
          fontSize: size.width < 520 ? 15 : 18,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: size.width * .22);

    titlePainter.paint(
      canvas,
      Offset(size.width * .66, size.height * .22),
    );
  }

  @override
  bool shouldRepaint(covariant _AiEvaluationPreviewPainter oldDelegate) {
    return oldDelegate.progress != progress;
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



enum _AccessMode {
  register,
  login,
}
