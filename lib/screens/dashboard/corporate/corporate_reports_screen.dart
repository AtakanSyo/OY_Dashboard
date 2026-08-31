import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_corporate_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';

class CorporateReportsScreen extends StatefulWidget {
  final AppUser currentUser;

  const CorporateReportsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CorporateReportsScreen> createState() => _CorporateReportsScreenState();
}

class _CorporateReportsScreenState extends State<CorporateReportsScreen> {
  final MockCorporateRepository _repository = MockCorporateRepository();

  bool _isLoading = true;
  List<CorporateReportItem> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reports = await _repository.getReports();
    if (!mounted) return;

    setState(() {
      _reports = reports;
      _isLoading = false;
    });
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
          children: _reports.map((report) {
            final isReady = report.status == 'Hazır';

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
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
                  const Icon(Icons.description_outlined, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report.description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(report.date),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isReady
                          ? Colors.green.withOpacity(0.08)
                          : Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      report.status,
                      style: TextStyle(
                        color: isReady ? Colors.green : Colors.orange,
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