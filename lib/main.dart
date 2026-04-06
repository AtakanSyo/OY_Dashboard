import 'package:flutter/material.dart';
import 'package:oy_site/core/supabase_config.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

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
    return MaterialApp(
      title: 'OY Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: LoginScreen(
        pressureRepository: pressureRepository,
      ),
      onGenerateRoute: (settings) {
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
}