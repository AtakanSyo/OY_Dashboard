import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/patient_list_screen.dart';
import 'package:oy_site/screens/dashboard/session_list_screen.dart';
import '/widgets/sidebar.dart';
import '/widgets/topbar.dart';

import 'profile_screen.dart';
import 'analysis_screen.dart';
import 'orders_screen.dart';
import 'store_screen.dart';
import 'pressure_screen.dart';
import 'support_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  final dynamic pressureRepository;

  const DashboardScreen({
    super.key,
    required this.currentUser,
    required this.pressureRepository,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  List<Widget> get _pages {
    switch (widget.currentUser.roleCode) {
      case RoleCodes.expert:
        return [
          ProfileScreen(currentUser: widget.currentUser),
          PatientListScreen(currentUser: widget.currentUser),
          SessionListScreen(currentUser: widget.currentUser),
          AnalysisScreen(currentUser: widget.currentUser),
          OrdersScreen(currentUser: widget.currentUser),
          SupportScreen(currentUser: widget.currentUser),
          PressureScreen(
            pressureRepository: widget.pressureRepository,
          ),
        ];

      case RoleCodes.customer:
        return [
          ProfileScreen(currentUser: widget.currentUser),
          OrdersScreen(currentUser: widget.currentUser),
          StoreScreen(currentUserEmail: widget.currentUser.email),
          SupportScreen(currentUser: widget.currentUser),
        ];

      case RoleCodes.optiYouTeam:
        return [
          ProfileScreen(currentUser: widget.currentUser),
          PatientListScreen(currentUser: widget.currentUser),
          SessionListScreen(currentUser: widget.currentUser),
          AnalysisScreen(currentUser: widget.currentUser),
          OrdersScreen(currentUser: widget.currentUser),
          StoreScreen(currentUserEmail: widget.currentUser.email),
          SupportScreen(currentUser: widget.currentUser),
          PressureScreen(
            pressureRepository: widget.pressureRepository,
          ),
        ];

      default:
        return [
          ProfileScreen(currentUser: widget.currentUser),
          SupportScreen(currentUser: widget.currentUser),
        ];
    }
  }

  void _onItemSelected(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            onItemSelected: _onItemSelected,
            selectedIndex: _selectedIndex,
            currentUser: widget.currentUser,
          ),
          Expanded(
            child: Column(
              children: [
                Topbar(
                  currentUser: widget.currentUser,
                ),
                Expanded(
                  child: pages[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}