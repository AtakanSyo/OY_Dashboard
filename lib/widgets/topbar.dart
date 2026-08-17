import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/auth/login_screen.dart';
import 'package:oy_site/services/auth_service.dart';
import 'package:oy_site/widgets/language_selector.dart';

class Topbar extends StatelessWidget {
  final AppUser currentUser;
  final VoidCallback onProfileTap;

  const Topbar({
    super.key,
    required this.currentUser,
    required this.onProfileTap,
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
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const LanguageSelector(),
          const SizedBox(width: 12),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    currentUser.email,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              PopupMenuButton<_TopbarMenuAction>(
                tooltip: l10n.profileMenuTooltip,
                onSelected: (action) async {
                  switch (action) {
                    case _TopbarMenuAction.viewProfile:
                      onProfileTap();
                      break;

                    case _TopbarMenuAction.editProfile:
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.editInformationComingSoon)),
                      );
                      break;

                    case _TopbarMenuAction.logout:
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const LoginScreen(pressureRepository: null),
                          ),
                          (route) => false,
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _TopbarMenuAction.viewProfile,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_outline),
                      title: Text(l10n.viewProfile),
                    ),
                  ),
                  PopupMenuItem(
                    value: _TopbarMenuAction.editProfile,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_outlined),
                      title: Text(l10n.editInformation),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: _TopbarMenuAction.logout,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text(l10n.logout),
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

enum _TopbarMenuAction { viewProfile, editProfile, logout }
