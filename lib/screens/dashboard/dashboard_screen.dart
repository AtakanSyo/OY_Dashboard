import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/customer_analysis_results_screen.dart';
import 'package:oy_site/screens/dashboard/patient_list_screen.dart';
import 'package:oy_site/screens/dashboard/session_list_screen.dart';
import 'package:oy_site/screens/dashboard/optiyou_operations_board_screen.dart';
import 'package:oy_site/screens/dashboard/sales_statistics_screen.dart';
import 'package:oy_site/screens/dashboard/customer_home_screen.dart';
import 'package:oy_site/screens/dashboard/corporate_dashboard_screen.dart';
import 'package:oy_site/screens/dashboard/corporate_department_analysis_screen.dart';
import 'package:oy_site/screens/dashboard/corporate_trends_screen.dart';
import 'package:oy_site/screens/dashboard/corporate_employees_screen.dart';
import 'package:oy_site/screens/dashboard/corporate_reports_screen.dart';
import 'package:oy_site/screens/dashboard/expert_control_panel_screen.dart';
import '/widgets/sidebar.dart';
import '/widgets/topbar.dart';
import 'profile_screen.dart';
import 'customer_profile_screen.dart';
import 'expert_profile_screen.dart';
import 'corporate_profile_screen.dart';
import 'orders_screen.dart';
import 'store_screen.dart';
import 'support_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser currentUser;
  final dynamic pressureRepository;
  final int initialIndex;

  const DashboardScreen({
    super.key,
    required this.currentUser,
    required this.pressureRepository,
    this.initialIndex = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  List<Widget> get _pages {
    switch (widget.currentUser.roleCode) {
      case RoleCodes.expert:
        return [
          ExpertControlPanelScreen(
            currentUser: widget.currentUser,
            onNewMeasurementTap: () => _onItemSelected(1),
            onMeasurementHistoryTap: () => _onItemSelected(2),
          ),
          PatientListScreen(
            currentUser: widget.currentUser,
            pressureRepository: widget.pressureRepository,
          ),
          SessionListScreen(
            currentUser: widget.currentUser,
            pressureRepository: widget.pressureRepository,
          ),
          OrdersScreen(currentUser: widget.currentUser),
          SupportScreen(currentUser: widget.currentUser),
          ExpertProfileScreen(currentUser: widget.currentUser),
        ];

      case RoleCodes.customer:
        return [
          CustomerHomeScreen(currentUser: widget.currentUser),
          CustomerAnalysisResultsScreen(currentUser: widget.currentUser),
          OrdersScreen(currentUser: widget.currentUser),
          StoreScreen(currentUserEmail: widget.currentUser.email),
          SupportScreen(currentUser: widget.currentUser),
          CustomerProfileScreen(currentUser: widget.currentUser),
        ];

      case RoleCodes.corporate:
        return [
          CorporateDashboardScreen(currentUser: widget.currentUser),
          CorporateDepartmentAnalysisScreen(currentUser: widget.currentUser),
          CorporateTrendsScreen(currentUser: widget.currentUser),
          CorporateEmployeesScreen(currentUser: widget.currentUser),
          CorporateReportsScreen(currentUser: widget.currentUser),
          CorporateProfileScreen(currentUser: widget.currentUser),
        ];

      case RoleCodes.optiYouTeam:
        return [
          const SalesStatisticsScreen(),
          OptiYouOperationsBoardScreen(currentUser: widget.currentUser),
          OrdersScreen(currentUser: widget.currentUser),
          SupportScreen(currentUser: widget.currentUser),
          ProfileScreen(currentUser: widget.currentUser),
        ];

      default:
        return [
          SupportScreen(currentUser: widget.currentUser),
          ProfileScreen(currentUser: widget.currentUser),
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