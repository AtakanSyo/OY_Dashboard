import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_corporate_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/corporate_dashboard_model.dart';

class CorporateDashboardScreen extends StatefulWidget {
  final AppUser currentUser;

  const CorporateDashboardScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CorporateDashboardScreen> createState() =>
      _CorporateDashboardScreenState();
}

class _CorporateDashboardScreenState extends State<CorporateDashboardScreen> {
  final MockCorporateRepository _repository = MockCorporateRepository();

  bool _isLoading = true;
  String? _errorMessage;
  CorporateDashboardModel? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getDashboardData();

      if (!mounted) return;

      setState(() {
        _dashboard = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Kurumsal dashboard yüklenemedi: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final dashboard = _dashboard;
    if (dashboard == null) {
      return const Center(
        child: Text('Gösterilecek veri bulunamadı.'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildKpiGrid(dashboard),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSectionCard(
                    title: 'Risk Dağılımı',
                    child: _buildRiskChart(dashboard),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSectionCard(
                    title: 'En Yaygın Problemler',
                    child: _buildTopIssues(dashboard),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Kritik Uyarılar',
              child: _buildAlerts(dashboard),
            ),
            const SizedBox(height: 18),
            _buildSectionCard(
              title: 'Departman İçgörüleri',
              child: _buildDepartmentInsights(dashboard),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00695C),
            Color(0xFF00897B),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kurumsal Ayak Sağlığı Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Çalışan gruplarının ayak sağlığı eğilimlerini, risk dağılımlarını ve operasyonel içgörüleri tek ekranda takip edin.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(CorporateDashboardModel dashboard) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: dashboard.kpis.map((item) {
        return Container(
          width: 240,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiskChart(CorporateDashboardModel dashboard) {
    final total = dashboard.riskDistribution.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: [
                PieChartSectionData(
                  value: dashboard.riskDistribution[0].count.toDouble(),
                  title: '%${((dashboard.riskDistribution[0].count / total) * 100).round()}',
                  radius: 52,
                ),
                PieChartSectionData(
                  value: dashboard.riskDistribution[1].count.toDouble(),
                  title: '%${((dashboard.riskDistribution[1].count / total) * 100).round()}',
                  radius: 52,
                ),
                PieChartSectionData(
                  value: dashboard.riskDistribution[2].count.toDouble(),
                  title: '%${((dashboard.riskDistribution[2].count / total) * 100).round()}',
                  radius: 52,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...dashboard.riskDistribution.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 12),
                const SizedBox(width: 8),
                Expanded(child: Text(item.label)),
                Text(
                  item.count.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopIssues(CorporateDashboardModel dashboard) {
    return Column(
      children: dashboard.topIssues.map((issue) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                issue.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                issue.percentage,
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                issue.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlerts(CorporateDashboardModel dashboard) {
    return Column(
      children: dashboard.alerts.map((alert) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.description,
                      style: TextStyle(
                        color: Colors.grey[800],
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDepartmentInsights(CorporateDashboardModel dashboard) {
    return Column(
      children: dashboard.departmentInsights.map((item) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.departmentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.keyFinding,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.riskLevel == 'Yüksek'
                      ? Colors.red.withOpacity(0.08)
                      : item.riskLevel == 'Orta'
                          ? Colors.orange.withOpacity(0.08)
                          : Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.riskLevel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}