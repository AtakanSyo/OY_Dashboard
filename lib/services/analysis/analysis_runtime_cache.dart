import 'package:oy_site/models/customer_analysis_result_model.dart';

class AnalysisRuntimeCache {
  AnalysisRuntimeCache._();

  static final AnalysisRuntimeCache instance = AnalysisRuntimeCache._();

  CustomerAnalysisResult? _latestResult;

  CustomerAnalysisResult? get latestResult => _latestResult;

  void saveLatest(CustomerAnalysisResult result) {
    _latestResult = result;
  }

  void clear() {
    _latestResult = null;
  }
}