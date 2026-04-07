import 'package:flutter/material.dart';
import 'package:oy_site/data/mock/mock_customer_analysis_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';

class CustomerAnalysisResultsScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerAnalysisResultsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CustomerAnalysisResultsScreen> createState() =>
      _CustomerAnalysisResultsScreenState();
}

class _CustomerAnalysisResultsScreenState
    extends State<CustomerAnalysisResultsScreen> {
  final MockCustomerAnalysisRepository _repository =
      MockCustomerAnalysisRepository();

  bool _isLoading = true;
  String? _errorMessage;
  CustomerAnalysisResult? _result;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.getLatestAnalysis(
        userId: widget.currentUser.userId!,
      );

      if (!mounted) return;

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Analiz sonuçları yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  Color _scoreColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Sonuçlarım'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_result == null) {
      return const Center(
        child: Text('Analiz sonucu bulunamadı.'),
      );
    }

    final result = _result!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(result),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildFootCard(
                  title: 'Sol Ayak',
                  foot: result.leftFoot,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildFootCard(
                  title: 'Sağ Ayak',
                  foot: result.rightFoot,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Önemli Bulgular',
            child: Column(
              children: result.metrics
                  .map(
                    (metric) => _buildMetricRow(metric),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionCard(
            title: 'Öneriler',
            child: Column(
              children: result.recommendations
                  .map(
                    (item) => _buildRecommendationItem(item),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(CustomerAnalysisResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal.withOpacity(0.12),
            child: const Icon(
              Icons.insights_outlined,
              color: Colors.teal,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Son Analiz Özeti',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Analiz Tarihi: ${_formatDate(result.analysisDate)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Text(
                  result.overallSummary,
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.generalRiskNote,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFootCard({
    required String title,
    required CustomerFootSummary foot,
  }) {
    return _buildSectionCard(
      title: title,
      child: Column(
        children: [
          _buildKeyValueRow('Ayak Tipi', foot.footType),
          _buildKeyValueRow('Basınç Özeti', foot.pressureSummary),
          _buildKeyValueRow('Denge Özeti', foot.balanceSummary),
          _buildKeyValueRow('Kemer Desteği', foot.archSupportNeed),
          _buildKeyValueRow('Ana Bulgular', foot.mainFinding),
          const SizedBox(height: 16),
          _buildScoreBar(
            label: 'Basınç Konfor Skoru',
            score: foot.pressureScore,
          ),
          const SizedBox(height: 12),
          _buildScoreBar(
            label: 'Stabilite Skoru',
            score: foot.stabilityScore,
          ),
          const SizedBox(height: 12),
          _buildScoreBar(
            label: 'Ark Desteği Skoru',
            score: foot.archScore,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar({
    required String label,
    required double score,
  }) {
    final color = _scoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
            Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(CustomerAnalysisMetric metric) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.teal.withOpacity(0.12),
            child: const Icon(
              Icons.analytics_outlined,
              size: 18,
              color: Colors.teal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metric.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            metric.value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(CustomerRecommendationItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.teal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}