import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/analysis/customer_analysis_results_screen.dart';
import 'package:oy_site/screens/dashboard/patients/patient_list_screen.dart';
import 'package:oy_site/screens/dashboard/sessions/session_list_screen.dart';
import 'package:oy_site/screens/dashboard/operations/optiyou_operations_board_screen.dart';
import 'package:oy_site/screens/dashboard/operations/sales_statistics_screen.dart';
import 'package:oy_site/screens/dashboard/customer/customer_home_screen.dart';
import 'package:oy_site/screens/dashboard/corporate/corporate_dashboard_screen.dart';
import 'package:oy_site/screens/dashboard/corporate/corporate_department_analysis_screen.dart';
import 'package:oy_site/screens/dashboard/corporate/corporate_trends_screen.dart';
import 'package:oy_site/screens/dashboard/corporate/corporate_employees_screen.dart';
import 'package:oy_site/screens/dashboard/corporate/corporate_reports_screen.dart';
import 'package:oy_site/screens/dashboard/expert/expert_control_panel_screen.dart';
import 'package:oy_site/screens/dashboard/operations/optiyou_measurement_pool_screen.dart';
import 'package:oy_site/screens/dashboard/orders/orders_screen.dart';
import 'package:oy_site/screens/dashboard/profiles/corporate_profile_screen.dart';
import 'package:oy_site/screens/dashboard/profiles/customer_profile_screen.dart';
import 'package:oy_site/screens/dashboard/profiles/expert_profile_screen.dart';
import 'package:oy_site/screens/dashboard/profiles/profile_screen.dart';
import 'package:oy_site/screens/dashboard/store/store_screen.dart';
import 'package:oy_site/screens/dashboard/store/store_management_screen.dart';
import 'package:oy_site/screens/dashboard/support/support_screen.dart';

import '/widgets/sidebar.dart';
import '/widgets/topbar.dart';

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
  final List<int> _navigationHistory = [];

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
          CustomerHomeScreen(
            currentUser: widget.currentUser,
            onNavigate: _onItemSelected,
          ),
          CustomerAnalysisResultsScreen(currentUser: widget.currentUser),
          OrdersScreen(currentUser: widget.currentUser),
          StoreScreen(currentUser: widget.currentUser),
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
          OptiyouMeasurementPoolScreen(
            currentUser: widget.currentUser,
            pressureRepository: widget.pressureRepository,
          ),
          OptiYouOperationsBoardScreen(
            currentUser: widget.currentUser,
            pressureRepository: widget.pressureRepository,
          ),
          OrdersScreen(currentUser: widget.currentUser),
          const StoreManagementScreen(),
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
    if (index == _selectedIndex) return;

    setState(() {
      _navigationHistory.add(_selectedIndex);
      _selectedIndex = index;
    });
  }

  void _goBack() {
    if (_navigationHistory.isEmpty) return;

    setState(() {
      _selectedIndex = _navigationHistory.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
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
                    onProfileTap: () => _onItemSelected(pages.length - 1),
                  ),
                  Expanded(child: pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
