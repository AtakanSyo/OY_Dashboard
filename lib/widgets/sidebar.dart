import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final AppUser currentUser;

  const Sidebar({
    super.key,
    required this.onItemSelected,
    required this.selectedIndex,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItemsByRole();

    return Container(
      width: 220,
      color: Colors.grey[200],
      child: Column(
        children: [
          const SizedBox(height: 32),

          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "OY Dashboard",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Expanded(
            child: Column(
              children: [
                ...menuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return _buildMenuItem(
                    item.icon,
                    item.title,
                    index,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_SidebarMenuItem> _getMenuItemsByRole() {
    switch (currentUser.roleCode) {
      case RoleCodes.expert:
        return const [
          _SidebarMenuItem(Icons.groups, "Hastalar"),
          _SidebarMenuItem(Icons.fact_check, "Ölçüm Oturumları"),
          _SidebarMenuItem(Icons.analytics, "Ayak Analizi"),
          _SidebarMenuItem(Icons.shopping_bag, "Siparişler"),
          _SidebarMenuItem(Icons.help_outline, "Destek"),
          _SidebarMenuItem(Icons.speed, "Basınç Ölçüm"),
          _SidebarMenuItem(Icons.person, "Profil"),
        ];

      case RoleCodes.customer:
        return const [
          _SidebarMenuItem(Icons.home, "Ana Sayfa"),
          _SidebarMenuItem(Icons.insights_outlined, "Analiz Sonuçlarım"),
          _SidebarMenuItem(Icons.shopping_bag, "Siparişler"),
          _SidebarMenuItem(Icons.storefront, "Mağaza"),
          _SidebarMenuItem(Icons.help_outline, "Destek"),
          _SidebarMenuItem(Icons.person, "Profil"),
        ];

      case RoleCodes.optiYouTeam:
        return const [
          _SidebarMenuItem(Icons.show_chart, "Satış İstatistikleri"),
          _SidebarMenuItem(Icons.inventory_2_outlined, "Sipariş Operasyonlar"),
          _SidebarMenuItem(Icons.shopping_bag, "Siparişler"),
          _SidebarMenuItem(Icons.help_outline, "Destek"),
          _SidebarMenuItem(Icons.person, "Profil"),
        ];

      default:
        return const [
          _SidebarMenuItem(Icons.help_outline, "Destek"),
          _SidebarMenuItem(Icons.person, "Profil"),
        ];
    }
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final bool isActive = selectedIndex == index;

    return Container(
      color: isActive ? Colors.teal.withOpacity(0.15) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.teal : Colors.black,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.teal : Colors.black,
          ),
        ),
        onTap: () => onItemSelected(index),
      ),
    );
  }
}

class _SidebarMenuItem {
  final IconData icon;
  final String title;

  const _SidebarMenuItem(this.icon, this.title);
}