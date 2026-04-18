import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_corporate_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';

class CorporateEmployeesScreen extends StatefulWidget {
  final AppUser currentUser;

  const CorporateEmployeesScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CorporateEmployeesScreen> createState() =>
      _CorporateEmployeesScreenState();
}

class _CorporateEmployeesScreenState extends State<CorporateEmployeesScreen> {
  final MockCorporateRepository _repository = MockCorporateRepository();

  bool _isLoading = true;
  List<CorporateEmployeeItem> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repository.getEmployees();
    if (!mounted) return;

    setState(() {
      _employees = items;
      _isLoading = false;
    });
  }

  Color _riskChipColor(String risk) {
    switch (risk) {
      case 'Yüksek':
        return Colors.red;
      case 'Orta':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: _employees.map((employee) {
            final chipColor = _riskChipColor(employee.riskLevel);

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      employee.employeeCode,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(employee.fullName),
                  ),
                  Expanded(
                    child: Text(employee.departmentName),
                  ),
                  Expanded(
                    child: Text(employee.taskGroup),
                  ),
                  Expanded(
                    child: Text(employee.lastAnalysisDate),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      employee.riskLevel,
                      style: TextStyle(
                        color: chipColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}