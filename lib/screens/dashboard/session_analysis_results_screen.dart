import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/measurement_session.dart';
import 'package:oy_site/screens/dashboard/analysis_results_view.dart';

class SessionAnalysisResultsScreen extends StatefulWidget {
  final AppUser currentUser;
  final MeasurementSession session;

  const SessionAnalysisResultsScreen({
    super.key,
    required this.currentUser,
    required this.session,
  });

  @override
  State<SessionAnalysisResultsScreen> createState() =>
      _SessionAnalysisResultsScreenState();
}

class _SessionAnalysisResultsScreenState
    extends State<SessionAnalysisResultsScreen> {
  final SupabaseAnalysisRepository _repository =
      SupabaseAnalysisRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<CustomerAnalysisResult> _results = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final sessionId = widget.session.sessionId;
      final patientId = widget.session.patientId;
      final sessionCode = widget.session.sessionCode;

      final results = await _repository.getAnalysisHistoryBySession(
        sessionId: sessionId,
        patientId: patientId,
        sessionCode: sessionCode,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu oturum için analiz sonucu bulunamadı.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '3D scan klasörü yüklendikten ve analiz sonucu kaydedildikten sonra burada görünecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadAnalyses,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Kontrol Et'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Analiz Sonuçları - ${widget.session.sessionCode}',
          ),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ayak Sağlığı Analiz Sonuçları'),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analiz Sonuçları - ${widget.session.sessionCode}',
        ),
        backgroundColor: Colors.teal,
      ),
      body: _results.isEmpty
          ? _buildEmptyState()
          : AnalysisResultsView(
              currentUser: widget.currentUser,
              pageTitle: 'Ayak Sağlığı Analiz Sonuçları',
              results: _results,
            ),
    );
  }
}