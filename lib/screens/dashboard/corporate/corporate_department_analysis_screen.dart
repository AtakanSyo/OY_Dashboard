import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';
import 'package:oy_site/services/corporate/corporate_employee_source_service.dart';

class CorporateDepartmentAnalysisScreen extends StatefulWidget {
  final AppUser currentUser;

  const CorporateDepartmentAnalysisScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CorporateDepartmentAnalysisScreen> createState() =>
      _CorporateDepartmentAnalysisScreenState();
}

class _CorporateDepartmentAnalysisScreenState
    extends State<CorporateDepartmentAnalysisScreen> {
  final CorporateEmployeeSourceService _employeeSource =
      const CorporateEmployeeSourceService();

  bool _isLoading = true;
  List<CorporateDepartmentItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final employees = await _employeeSource.getEmployees(
      currentUser: widget.currentUser,
    );
    final items = _buildDepartmentItems(employees);
    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  List<CorporateDepartmentItem> _buildDepartmentItems(
    List<CorporateEmployeeItem> employees,
  ) {
    final counts = <String, int>{};
    for (final employee in employees) {
      final department = employee.departmentName.trim().isEmpty
          ? 'Departman belirtilmemiş'
          : employee.departmentName.trim();
      counts[department] = (counts[department] ?? 0) + 1;
    }

    final items = counts.entries.map((entry) {
      return CorporateDepartmentItem(
        departmentName: entry.key,
        employeeCount: entry.value,
        avgRiskScore: 0,
        topIssue: 'Analiz bekleniyor',
        trendLabel: 'Yeni dönem',
      );
    }).toList()..sort((a, b) => a.departmentName.compareTo(b.departmentName));

    return items;
  }

  Color _riskColor(double score) {
    if (score >= 70) return Colors.red;
    if (score >= 50) return Colors.orange;
    return Colors.green;
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
        child: _items.isEmpty
            ? const _EmptyCorporateState(
                icon: Icons.account_tree_outlined,
                title: 'Departman verisi yok',
                message:
                    'CSV içe aktarıldığında çalışanlar departmanlarına göre burada listelenecek.',
              )
            : Column(
                children: _items.map((item) {
                  final color = _riskColor(item.avgRiskScore);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
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
                          flex: 2,
                          child: Text(
                            item.departmentName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(child: Text('Çalışan: ${item.employeeCount}')),
                        Expanded(child: Text('Ana bulgu: ${item.topIssue}')),
                        Expanded(child: Text('Trend: ${item.trendLabel}')),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: item.avgRiskScore / 100,
                                  minHeight: 8,
                                  color: color,
                                  backgroundColor: Colors.grey.shade300,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.avgRiskScore.toStringAsFixed(0),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
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

class _EmptyCorporateState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyCorporateState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
