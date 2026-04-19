import 'package:flutter/material.dart';
import 'package:oy_site/core/supabase_config.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/payment_result_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/home_screen.dart';

// App config
class AppConfig {
  static bool useMock = true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final pressureRepository = AppConfig.useMock
      ? "MOCK_REPOSITORY"
      : "SUPABASE_REPOSITORY";

  runApp(
    OYDashboardApp(
      pressureRepository: pressureRepository,
    ),
  );
}

class OYDashboardApp extends StatelessWidget {
  final dynamic pressureRepository;

  const OYDashboardApp({
    super.key,
    required this.pressureRepository,
  });

  @override
  Widget build(BuildContext context) {
    final paymentResult = _extractPaymentResultFromUrl();

    return MaterialApp(
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
              pressureRepository: pressureRepository,
            )
          : HomeScreen(
              pressureRepository: pressureRepository,
            ),
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '';

        if (routeName.startsWith('/payment-result')) {
          final uri = Uri.parse(routeName);
          final status = (uri.queryParameters['status'] ?? '').toLowerCase();
          final token = uri.queryParameters['token'];

          return MaterialPageRoute(
            builder: (_) => PaymentResultScreen(
              success: status == 'success',
              token: token,
              pressureRepository: pressureRepository,
            ),
          );
        }

        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map<String, dynamic>?;
          final currentUserMap = args?['currentUser'] as Map<String, dynamic>?;

          final currentUser = currentUserMap != null
              ? AppUser.fromMap(currentUserMap)
              : const AppUser(
                  firstName: 'Bilinmeyen',
                  lastName: 'Kullanıcı',
                  email: 'unknown@example.com',
                  roleCode: RoleCodes.customer,
                  roleName: 'Müşteri',
                );

          return MaterialPageRoute(
            builder: (_) => DashboardScreen(
              currentUser: currentUser,
              pressureRepository: pressureRepository,
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => LoginScreen(
            pressureRepository: pressureRepository,
          ),
        );
      },
    );
  }

  _PaymentResultRouteData? _extractPaymentResultFromUrl() {
    final fragment = Uri.base.fragment;
    if (fragment.isEmpty) return null;

    final normalized = fragment.startsWith('/') ? fragment : '/$fragment';
    final fragmentUri = Uri.tryParse(normalized);
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
}

class _PaymentResultRouteData {
  final bool success;
  final String? token;

  const _PaymentResultRouteData({
    required this.success,
    required this.token,
  });
}
