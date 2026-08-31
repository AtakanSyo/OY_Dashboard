import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_corporate_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';

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
  final MockCorporateRepository _repository = MockCorporateRepository();

  bool _isLoading = true;
  List<CorporateDepartmentItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repository.getDepartmentItems();
    if (!mounted) return;

    setState(() {
      _items = items;
      _isLoading = false;
    });
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
        child: Column(
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
                  Expanded(
                    child: Text('Çalışan: ${item.employeeCount}'),
                  ),
                  Expanded(
                    child: Text('Ana bulgu: ${item.topIssue}'),
                  ),
                  Expanded(
                    child: Text('Trend: ${item.trendLabel}'),
                  ),
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