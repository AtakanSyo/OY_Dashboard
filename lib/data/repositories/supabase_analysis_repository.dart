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

  Future<List<CustomerAnalysisResult>>
  getAnalysisHistoryForCurrentCustomer() async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      throw Exception('Oturum açmış kullanıcı bulunamadı.');
    }

    final patientResponse = await _client
        .from('patients')
        .select('id, clinic_id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();

    if (patientResponse == null) {
      return [];
    }

    final patientId = _asInt(patientResponse['id']);

    if (patientId == null) {
      return [];
    }

    final response = await _client
        .from('analysis_results')
        .select()
        .eq('patient_id', patientId)
        .order('analysis_date', ascending: false);

    final rows = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    return _withClinicNames(
      rows,
      fallbackClinicId: _asInt(patientResponse['clinic_id']),
    );
  }

  Future<List<CustomerAnalysisResult>> _withClinicNames(
    List<Map<String, dynamic>> rows, {
    int? fallbackClinicId,
  }) async {
    if (rows.isEmpty) return const [];

    final sessionIds = rows
        .map((row) => _asInt(row['session_id']))
        .whereType<int>()
        .toSet()
        .toList();
    final clinicIdBySession = <int, int>{};

    if (sessionIds.isNotEmpty) {
      final sessionRows = await _client
          .from('measurement_sessions')
          .select('id, clinic_id')
          .inFilter('id', sessionIds);

      for (final raw in sessionRows as List<dynamic>) {
        final row = Map<String, dynamic>.from(raw as Map);
        final sessionId = _asInt(row['id']);
        final clinicId = _asInt(row['clinic_id']);
        if (sessionId != null && clinicId != null) {
          clinicIdBySession[sessionId] = clinicId;
        }
      }
    }

    final clinicIds = <int>{...clinicIdBySession.values, ?fallbackClinicId};
    final clinicNameById = <int, String>{};

    if (clinicIds.isNotEmpty) {
      final clinicRows = await _client
          .from('clinics')
          .select('id, clinic_name')
          .inFilter('id', clinicIds.toList());

      for (final raw in clinicRows as List<dynamic>) {
        final row = Map<String, dynamic>.from(raw as Map);
        final clinicId = _asInt(row['id']);
        final clinicName = (row['clinic_name'] ?? '').toString().trim();
        if (clinicId != null && clinicName.isNotEmpty) {
          clinicNameById[clinicId] = clinicName;
        }
      }
    }

    return rows.map((row) {
      final result = CustomerAnalysisResult.fromMap(row);
      final sessionId = _asInt(row['session_id']);
      final clinicId = sessionId == null
          ? fallbackClinicId
          : clinicIdBySession[sessionId] ?? fallbackClinicId;
      return result.copyWith(
        locationLabel: clinicId == null ? '' : clinicNameById[clinicId] ?? '',
      );
    }).toList();
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
    await _client
        .from('analysis_results')
        .insert(
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
    await _client
        .from('analysis_results')
        .upsert(
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

  Future<void> deleteAnalysisResult({required int analysisResultId}) async {
    await _client.from('analysis_results').delete().eq('id', analysisResultId);
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
      throw Exception(
        'Değerlendirme sorgusu için sessionId, patientId veya sessionCode gerekli.',
      );
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

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
