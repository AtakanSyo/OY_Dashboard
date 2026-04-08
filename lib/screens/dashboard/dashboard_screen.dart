import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/customer_analysis_results_screen.dart';
import 'package:oy_site/screens/dashboard/patient_list_screen.dart';
import 'package:oy_site/screens/dashboard/session_list_screen.dart';
import 'package:oy_site/screens/dashboard/optiyou_operations_board_screen.dart';
import 'package:oy_site/screens/dashboard/sales_statistics_screen.dart';
import 'package:oy_site/screens/dashboard/customer_home_screen.dart';
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

      // 👨‍⚕️ EXPERT
      case RoleCodes.expert:
        return [
          PatientListScreen(currentUser: widget.currentUser),        // 0
          SessionListScreen(currentUser: widget.currentUser),        // 1
          AnalysisScreen(currentUser: widget.currentUser),           // 2
          OrdersScreen(currentUser: widget.currentUser),             // 3
          SupportScreen(currentUser: widget.currentUser),            // 4
          PressureScreen(                                            // 5
            pressureRepository: widget.pressureRepository,
          ),
          ProfileScreen(currentUser: widget.currentUser),            // 6
        ];

      // 👤 CUSTOMER
      case RoleCodes.customer:
        return [
          CustomerHomeScreen(currentUser: widget.currentUser),       // 0
          CustomerAnalysisResultsScreen(currentUser: widget.currentUser), // 1
          OrdersScreen(currentUser: widget.currentUser),             // 2
          StoreScreen(currentUserEmail: widget.currentUser.email),   // 3
          SupportScreen(currentUser: widget.currentUser),            // 4
          ProfileScreen(currentUser: widget.currentUser),            // 5
        ];

      // 🏭 OPTIYOU TEAM
      case RoleCodes.optiYouTeam:
        return [
          const SalesStatisticsScreen(),                             // 0
          OptiYouOperationsBoardScreen(currentUser: widget.currentUser), // 1
          OrdersScreen(currentUser: widget.currentUser),             // 2
          SupportScreen(currentUser: widget.currentUser),            // 3
          ProfileScreen(currentUser: widget.currentUser),            // 4
        ];

      // 🔹 DEFAULT
      default:
        return [
          SupportScreen(currentUser: widget.currentUser),            // 0
          ProfileScreen(currentUser: widget.currentUser),            // 1
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