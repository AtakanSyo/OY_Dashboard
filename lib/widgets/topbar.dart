import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/auth/login_screen.dart';
import 'package:oy_site/screens/dashboard/profiles/profile_screen.dart';
import 'package:oy_site/services/auth_service.dart';

class Topbar extends StatelessWidget {
  final AppUser currentUser;

  const Topbar({
    super.key,
    required this.currentUser,
  });

  String _getSubtitle() {
    final roleName = currentUser.roleName.trim();
    final clinicName = (currentUser.clinicName ?? '').trim();

    if (clinicName.isNotEmpty) {
      return '$roleName • $clinicName';
    }

    return roleName;
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _getSubtitle();

    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currentUser.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currentUser.email,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              PopupMenuButton<_TopbarMenuAction>(
                tooltip: 'Profil menüsü',
                onSelected: (action) async {
                  switch (action) {
                    case _TopbarMenuAction.viewProfile:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            currentUser: currentUser,
                          ),
                        ),
                      );
                      break;

                    case _TopbarMenuAction.editProfile:
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Bilgileri düzenleme ekranını sonra bağlayacağız.',
                          ),
                        ),
                      );
                      break;

                    case _TopbarMenuAction.logout:
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
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _TopbarMenuAction.viewProfile,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_outline),
                      title: Text('Profili Görüntüle'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _TopbarMenuAction.editProfile,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Bilgileri Düzenle'),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _TopbarMenuAction.logout,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('Çıkış Yap'),
                    ),
                  ),
                ],
                child: const CircleAvatar(
                  radius: 20,
                  child: Icon(Icons.person),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TopbarMenuAction {
  viewProfile,
  editProfile,
  logout,
}
