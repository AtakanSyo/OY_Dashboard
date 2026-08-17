import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/screens/dashboard/analysis/analysis_results_view.dart';

class CustomerAnalysisResultsScreen extends StatefulWidget {
  final AppUser currentUser;

  const CustomerAnalysisResultsScreen({super.key, required this.currentUser});

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
      final results = await _supabaseRepository
          .getAnalysisHistoryForCurrentCustomer();

      if (!mounted) return;

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = AppLocalizations.of(
          context,
        ).analysisResultsLoadError(e.toString());
        _isLoading = false;
      });
    }
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.noAnalysisResults,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.analysisWillAppear,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadAnalyses,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.checkAgain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    return AnalysisResultsView(
      currentUser: widget.currentUser,
      pageTitle: l10n.myAnalysisResults,
      results: _results,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }
}
