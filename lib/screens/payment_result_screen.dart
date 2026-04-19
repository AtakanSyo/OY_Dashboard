import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/dashboard_screen.dart';
import 'package:oy_site/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String? token;
  final dynamic pressureRepository;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.token,
    required this.pressureRepository,
  });

  Future<void> _goToProfile(BuildContext context) async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;

    if (authUser == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            pressureRepository: pressureRepository,
          ),
        ),
        (_) => false,
      );
      return;
    }

    final profileData = await client
        .from('user_profiles_full')
        .select()
        .eq('auth_id', authUser.id)
        .single();

    final currentUser = AppUser.fromMap(profileData);
    final profileTabIndex = _profileIndexForRole(currentUser.roleCode);

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          currentUser: currentUser,
          pressureRepository: pressureRepository,
          initialIndex: profileTabIndex,
        ),
      ),
      (_) => false,
    );
  }

  int _profileIndexForRole(String roleCode) {
    switch (roleCode) {
      case RoleCodes.expert:
        return 6;
      case RoleCodes.customer:
        return 5;
      case RoleCodes.corporate:
        return 5;
      case RoleCodes.optiYouTeam:
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = success ? 'Odeme Basarili' : 'Odeme Tamamlanamadi';
    final subtitle = success
        ? 'Odemeniz alindi. Siparisiniz isleme alinacak.'
        : 'Odeme islemi basarisiz veya iptal edildi.';
    final icon = success ? Icons.check_circle : Icons.cancel;
    final color = success ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odeme Sonucu'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 72, color: color),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _goToProfile(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Profil sayfasina gidilemedi: $e'),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Profilime Don'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
