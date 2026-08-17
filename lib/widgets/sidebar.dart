import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_localizations.dart';
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
    final menuItems = _getMenuItemsByRole(AppLocalizations.of(context));

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
                  'assets/images/branding/logo.png',
                  height: 40,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'OY Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

                  return _buildMenuItem(item.icon, item.title, index);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_SidebarMenuItem> _getMenuItemsByRole(AppLocalizations l10n) {
    switch (currentUser.roleCode) {
      case RoleCodes.expert:
        return [
          _SidebarMenuItem(Icons.dashboard_outlined, l10n.dashboard),
          _SidebarMenuItem(Icons.groups, l10n.customers),
          _SidebarMenuItem(Icons.fact_check, l10n.measurementHistory),
          _SidebarMenuItem(Icons.shopping_bag, l10n.orders),
          _SidebarMenuItem(Icons.help_outline, l10n.support),
          _SidebarMenuItem(Icons.person, l10n.profile),
        ];

      case RoleCodes.customer:
        return [
          _SidebarMenuItem(Icons.home, l10n.home),
          _SidebarMenuItem(Icons.insights_outlined, l10n.myAnalysisResults),
          _SidebarMenuItem(Icons.shopping_bag, l10n.orders),
          _SidebarMenuItem(Icons.storefront, l10n.store),
          _SidebarMenuItem(Icons.help_outline, l10n.support),
          _SidebarMenuItem(Icons.person, l10n.profile),
        ];

      case RoleCodes.corporate:
        return [
          _SidebarMenuItem(Icons.dashboard_outlined, l10n.dashboard),
          _SidebarMenuItem(Icons.apartment_outlined, l10n.departmentAnalysis),
          _SidebarMenuItem(Icons.show_chart, l10n.trends),
          _SidebarMenuItem(Icons.groups_outlined, l10n.employees),
          _SidebarMenuItem(Icons.description_outlined, l10n.reports),
          _SidebarMenuItem(Icons.person, l10n.profile),
        ];

      case RoleCodes.optiYouTeam:
        return [
          _SidebarMenuItem(Icons.show_chart, l10n.salesStatistics),
          _SidebarMenuItem(Icons.hub_outlined, l10n.measurementPool),
          _SidebarMenuItem(Icons.inventory_2_outlined, l10n.operations),
          _SidebarMenuItem(Icons.shopping_bag, l10n.orders),
          _SidebarMenuItem(Icons.help_outline, l10n.support),
          _SidebarMenuItem(Icons.person, l10n.profile),
        ];

      default:
        return [
          _SidebarMenuItem(Icons.help_outline, l10n.support),
          _SidebarMenuItem(Icons.person, l10n.profile),
        ];
    }
  }

  Widget _buildMenuItem(IconData icon, String title, int index) {
    final bool isActive = selectedIndex == index;

    return Container(
      color: isActive
          ? Colors.teal.withValues(alpha: 0.15)
          : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.teal : Colors.black),
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
