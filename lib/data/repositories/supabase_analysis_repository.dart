import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAnalysisRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<CustomerAnalysisResult>> getAnalysisHistory({
    required int userId,
  }) async {
    final response = await _client
        .from('analysis_results')
        .select()
        .eq('user_id', userId)
        .order('analysis_date', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => CustomerAnalysisResult.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<CustomerAnalysisResult>> getAnalysisHistoryForCurrentCustomer() async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      throw Exception('Oturum açmış kullanıcı bulunamadı.');
    }

    final patientResponse = await _client
        .from('patients')
        .select('id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (patientResponse == null) {
      return [];
    }

    final patientId = patientResponse['id'] as int?;

    if (patientId == null) {
      return [];
    }

    final response = await _client
        .from('analysis_results')
        .select()
        .eq('patient_id', patientId)
        .order('analysis_date', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => CustomerAnalysisResult.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<CustomerAnalysisResult?> getLatestAnalysis({
    required int userId,
  }) async {
    final response = await _client
        .from('analysis_results')
        .select()
        .eq('user_id', userId)
        .order('analysis_date', ascending: false)
        .limit(1);

    final list = response as List<dynamic>;

    if (list.isEmpty) return null;

    return CustomerAnalysisResult.fromMap(
      Map<String, dynamic>.from(list.first as Map),
    );
  }

  Future<CustomerAnalysisResult?> getLatestAnalysisForCurrentCustomer() async {
    final results = await getAnalysisHistoryForCurrentCustomer();

    if (results.isEmpty) return null;

    return results.first;
  }

  Future<void> saveAnalysisResult({
    int? userId,
    int? patientId,
    int? sessionId,
    required CustomerAnalysisResult result,
  }) async {
    await _client.from('analysis_results').insert(
          result.toMap(
            userId: userId,
            patientId: patientId,
            sessionId: sessionId,
          ),
        );
  }

  Future<void> upsertAnalysisResult({
    int? userId,
    int? patientId,
    int? sessionId,
    required CustomerAnalysisResult result,
  }) async {
    await _client.from('analysis_results').upsert(
          result.toMap(
            userId: userId,
            patientId: patientId,
            sessionId: sessionId,
          ),
          onConflict: patientId != null && sessionId != null
              ? 'patient_id,session_id'
              : 'user_id,session_code',
        );
  }

  Future<void> deleteAnalysisResult({
    required int analysisResultId,
  }) async {
    await _client
        .from('analysis_results')
        .delete()
        .eq('id', analysisResultId);
  }

  Future<List<CustomerAnalysisResult>> getAnalysisHistoryBySession({
    int? sessionId,
    int? patientId,
    String? sessionCode,
  }) async {
    var query = _client.from('analysis_results').select();

    if (sessionId != null) {
      query = query.eq('session_id', sessionId);
    } else if (patientId != null) {
      query = query.eq('patient_id', patientId);
    } else if (sessionCode != null && sessionCode.trim().isNotEmpty) {
      query = query.eq('session_code', sessionCode.trim());
    } else {
      throw Exception('Analiz sorgusu için sessionId, patientId veya sessionCode gerekli.');
    }

    final response = await query.order('analysis_date', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => CustomerAnalysisResult.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }
}