import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/core/supabase_config.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/payment_result_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'site/site_routes.dart';
import 'screens/auth/legal_consent_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/public/welcome_qr_screen.dart';

class AppConfig {
  static bool useMock = true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Site tipografisi assets/fonts/ altında paketlenmiştir; çalışma anında
  // Google'dan font indirilmez (yükleme gecikmesi ve dış bağımlılık olmasın).
  GoogleFonts.config.allowRuntimeFetching = false;

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final pressureRepository =
      AppConfig.useMock ? 'MOCK_REPOSITORY' : 'SUPABASE_REPOSITORY';

  runApp(
    OYDashboardApp(
      pressureRepository: pressureRepository,
    ),
  );
}

class OYDashboardApp extends StatefulWidget {
  final dynamic pressureRepository;

  const OYDashboardApp({
    super.key,
    required this.pressureRepository,
  });

  @override
  State<OYDashboardApp> createState() => _OYDashboardAppState();
}

class _OYDashboardAppState extends State<OYDashboardApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  StreamSubscription<AuthState>? _authSubscription;
  bool _isResetPasswordScreenOpen = false;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _openResetPasswordScreen();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _openResetPasswordScreen() {
    if (_isResetPasswordScreenOpen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;
      if (_isResetPasswordScreenOpen) return;

      _isResetPasswordScreenOpen = true;

      navigator
          .push(
        MaterialPageRoute(
          builder: (_) => const ResetPasswordScreen(),
          settings: const RouteSettings(name: '/reset-password'),
        ),
      )
          .whenComplete(() {
        _isResetPasswordScreenOpen = false;
      });
    });
  }

  void _openDashboardFromWelcome(AppUser user) {
    _navigatorKey.currentState?.pushReplacementNamed(
      '/dashboard',
      arguments: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentResult = _extractPaymentResultFromUrl();
    final inviteToken = _extractInviteTokenFromUrl();
    final legalConsentToken = _extractLegalConsentTokenFromUrl();
    final isResetPasswordRoute = _isResetPasswordRouteFromUrl();
    final isWelcomeRoute = _isWelcomeRouteFromUrl();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'OY Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: paymentResult != null
          ? PaymentResultScreen(
              success: paymentResult.success,
              token: paymentResult.token,
              pressureRepository: widget.pressureRepository,
            )
          : isResetPasswordRoute
              ? const ResetPasswordScreen()
              : isWelcomeRoute
                  ? WelcomeQrScreen(
                      pressureRepository: widget.pressureRepository,
                      onOpenApp: _openDashboardFromWelcome,
                    )
                  : inviteToken != null
                      ? RegisterScreen(
                          inviteToken: inviteToken,
                          pressureRepository: widget.pressureRepository,
                        )
                      : legalConsentToken != null
                          ? LegalConsentScreen(token: legalConsentToken)
                          : HomeScreen(
                              pressureRepository: widget.pressureRepository,
                            ),
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '';

        if (routeName.startsWith('/welcome')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => WelcomeQrScreen(
              pressureRepository: widget.pressureRepository,
              onOpenApp: _openDashboardFromWelcome,
            ),
          );
        }

        if (routeName.startsWith('/payment-result')) {
          final uri = Uri.parse(routeName);
          final status = (uri.queryParameters['status'] ?? '').toLowerCase();
          final token = uri.queryParameters['token'];

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => PaymentResultScreen(
              success: status == 'success',
              token: token,
              pressureRepository: widget.pressureRepository,
            ),
          );
        }

        if (routeName.startsWith('/register')) {
          final uri = Uri.parse(routeName);
          final inviteToken = uri.queryParameters['invite'];

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => RegisterScreen(
              inviteToken: inviteToken,
              pressureRepository: widget.pressureRepository,
            ),
          );
        }

        if (routeName.startsWith('/legal-consent')) {
          final uri = Uri.parse(routeName);
          final token = uri.queryParameters['token'] ?? '';

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => LegalConsentScreen(token: token),
          );
        }

        if (routeName.startsWith('/reset-password')) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/reset-password'),
            builder: (_) => const ResetPasswordScreen(),
          );
        }

        // '/giris' public sitedeki giriş bağlantısı, '/login' mevcut adres.
        if (routeName.startsWith('/login') || routeName.startsWith('/giris')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => LoginScreen(
              pressureRepository: widget.pressureRepository,
            ),
          );
        }

        if (routeName == '/dashboard' || routeName.startsWith('/dashboard')) {
          final currentUser = _currentUserFromRouteArguments(
            settings.arguments,
          );

          return MaterialPageRoute(
            settings: settings,
            builder: (_) => DashboardScreen(
              currentUser: currentUser,
              pressureRepository: widget.pressureRepository,
            ),
          );
        }

        // Public site route'ları (ana sayfa ve menü sayfaları).
        final siteRoute = generateSiteRoute(settings);
        if (siteRoute != null) return siteRoute;

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeScreen(
            pressureRepository: widget.pressureRepository,
          ),
        );
      },
    );
  }

  AppUser _currentUserFromRouteArguments(Object? arguments) {
    if (arguments is AppUser) {
      return arguments;
    }

    if (arguments is Map<String, dynamic>) {
      final directCurrentUser = arguments['currentUser'];

      if (directCurrentUser is AppUser) {
        return directCurrentUser;
      }

      if (directCurrentUser is Map<String, dynamic>) {
        return AppUser.fromMap(directCurrentUser);
      }

      if (arguments.containsKey('email') || arguments.containsKey('role_code')) {
        return AppUser.fromMap(arguments);
      }
    }

    return const AppUser(
      firstName: 'Bilinmeyen',
      lastName: 'Kullanıcı',
      email: 'unknown@example.com',
      roleCode: RoleCodes.customer,
      roleName: 'Müşteri',
    );
  }

  bool _isWelcomeRouteFromUrl() {
    final directUri = Uri.base;

    if (directUri.path == '/welcome') {
      return true;
    }

    final fragmentUri = _fragmentUriFromBase();
    if (fragmentUri == null) return false;

    return fragmentUri.path == '/welcome';
  }

  bool _isResetPasswordRouteFromUrl() {
    final directUri = Uri.base;

    if (directUri.path == '/reset-password') {
      return true;
    }

    final fragmentUri = _fragmentUriFromBase();
    if (fragmentUri == null) return false;

    return fragmentUri.path == '/reset-password';
  }

  String? _extractInviteTokenFromUrl() {
    final directUri = Uri.base;

    if (directUri.path == '/register') {
      final token = directUri.queryParameters['invite'];
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
    }

    final fragmentUri = _fragmentUriFromBase();

    if (fragmentUri == null || fragmentUri.path != '/register') {
      return null;
    }

    final token = fragmentUri.queryParameters['invite'];
    if (token == null || token.trim().isEmpty) return null;

    return token.trim();
  }

  String? _extractLegalConsentTokenFromUrl() {
    final directUri = Uri.base;

    if (directUri.path == '/legal-consent') {
      final token = directUri.queryParameters['token'];
      if (token != null && token.trim().isNotEmpty) {
        return token.trim();
      }
    }

    final fragmentUri = _fragmentUriFromBase();

    if (fragmentUri == null || fragmentUri.path != '/legal-consent') {
      return null;
    }

    final token = fragmentUri.queryParameters['token'];
    if (token == null || token.trim().isEmpty) return null;

    return token.trim();
  }

  _PaymentResultRouteData? _extractPaymentResultFromUrl() {
    final directUri = Uri.base;

    if (directUri.path == '/payment-result') {
      final status = directUri.queryParameters['status']?.toLowerCase();
      final success = status == 'success';
      final token = directUri.queryParameters['token'];

      return _PaymentResultRouteData(
        success: success,
        token: token,
      );
    }

    final fragmentUri = _fragmentUriFromBase();

    if (fragmentUri == null || fragmentUri.path != '/payment-result') {
      return null;
    }

    final status = fragmentUri.queryParameters['status']?.toLowerCase();
    final success = status == 'success';
    final token = fragmentUri.queryParameters['token'];

    return _PaymentResultRouteData(
      success: success,
      token: token,
    );
  }

  Uri? _fragmentUriFromBase() {
    final fragment = Uri.base.fragment;

    if (fragment.isEmpty) return null;

    final normalized = fragment.startsWith('/') ? fragment : '/$fragment';

    return Uri.tryParse(normalized);
  }
}

class _PaymentResultRouteData {
  final bool success;
  final String? token;

  const _PaymentResultRouteData({
    required this.success,
    required this.token,
  });
}