import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/screens/dashboard/analysis_results_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final SupabaseAnalysisRepository _supabaseRepository =
      SupabaseAnalysisRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<CustomerAnalysisResult> _results = [];

  final List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
  }

  void _addDebug(String message) {
    if (!mounted) return;

    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    setState(() {
      _debugLogs.add('[$time]\n$message');
    });
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
      _debugLogs.clear();
    });

    try {
      final authUser = Supabase.instance.client.auth.currentUser;

      _addDebug(
        'LOAD START\n'
        'currentUser.userId=${widget.currentUser.userId}\n'
        'currentUser.email=${widget.currentUser.email}\n'
        'currentUser.roleCode=${widget.currentUser.roleCode}\n'
        'authUser.id=${authUser?.id}\n'
        'authUser.email=${authUser?.email}',
      );

      if (authUser == null) {
        throw Exception('Oturum açmış Supabase kullanıcısı bulunamadı.');
      }

      _addDebug(
        'PATIENT LINK CHECK START\n'
        'patients.auth_user_id = ${authUser.id}',
      );

      final patientResponse = await Supabase.instance.client
          .from('patients')
          .select('id, first_name, last_name, email, auth_user_id')
          .eq('auth_user_id', authUser.id);

      final patientRows = patientResponse as List<dynamic>;

      _addDebug(
        'PATIENT LINK CHECK RESULT\n'
        'count=${patientRows.length}\n'
        'rows=$patientRows',
      );

      if (patientRows.isEmpty) {
        _addDebug(
          'WARNING\n'
          'Bu auth user ile eşleşen patient kaydı bulunamadı. '
          'Bu durumda analiz sonuçları gelmez.',
        );
      }

      _addDebug(
        'ANALYSIS FETCH START\n'
        'method=getAnalysisHistoryForCurrentCustomer()',
      );

      final results =
          await _supabaseRepository.getAnalysisHistoryForCurrentCustomer();

      _addDebug(
        'ANALYSIS FETCH RESULT\n'
        'count=${results.length}\n'
        'sessionCodes=${results.map((e) => e.sessionCode).join(', ')}',
      );

      if (patientRows.isNotEmpty) {
        final patientId = patientRows.first['id'];

        _addDebug(
          'DIRECT ANALYSIS TABLE CHECK START\n'
          'patient_id=$patientId',
        );

        final analysisRows = await Supabase.instance.client
            .from('analysis_results')
            .select('id, patient_id, session_id, session_code, analysis_date')
            .eq('patient_id', patientId)
            .order('analysis_date', ascending: false);

        _addDebug(
          'DIRECT ANALYSIS TABLE CHECK RESULT\n'
          'count=${(analysisRows as List<dynamic>).length}\n'
          'rows=$analysisRows',
        );
      }

      if (!mounted) return;

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      _addDebug(
        'LOAD ERROR\n'
        'error=$e',
      );

      setState(() {
        _errorMessage = 'Analiz sonuçları yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildDebugPanel() {
    if (_debugLogs.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 260),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          _debugLogs.join('\n\n----------------\n\n'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            height: 1.35,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
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
              'Analiz sonucu bulunamadı.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ölçüm sonuçlarınız hesabınıza bağlandığında burada görüntülenecektir.',
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

  Widget _buildBody() {
    if (_isLoading) {
      return Column(
        children: [
          _buildDebugPanel(),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            _buildDebugPanel(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Column(
        children: [
          _buildDebugPanel(),
          Expanded(
            child: _buildEmptyState(),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildDebugPanel(),
        Expanded(
          child: AnalysisResultsView(
            currentUser: widget.currentUser,
            pageTitle: 'Analiz Sonuçlarım',
            results: _results,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analiz Sonuçlarım'),
        backgroundColor: Colors.teal,
      ),
      body: _buildBody(),
    );
  }
}