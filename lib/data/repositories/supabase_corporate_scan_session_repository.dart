import 'package:oy_site/models/corporate_dashboard_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCorporateScanSessionRepository {
  const SupabaseCorporateScanSessionRepository();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Set<int>> getCompletedPatientIds({
    required int corporateUserId,
  }) async {
    final response = await _client
        .from('corporate_scan_sessions')
        .select('patient_id')
        .eq('corporate_user_id', corporateUserId)
        .eq('status', 'completed');

    return (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map)['patient_id'])
        .whereType<int>()
        .toSet();
  }

  Future<List<CorporateScanSessionItem>> getSessions({
    required int corporateUserId,
  }) async {
    final response = await _client
        .from('corporate_scan_sessions')
        .select()
        .eq('corporate_user_id', corporateUserId)
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .whereType<Map>()
        .map(
          (item) =>
              CorporateScanSessionItem.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> upsertSession({
    required int corporateUserId,
    required int patientId,
    required String patientCode,
    required String status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? localOutputPath,
  }) async {
    await _client.from('corporate_scan_sessions').upsert({
      'corporate_user_id': corporateUserId,
      'patient_id': patientId,
      'patient_code': patientCode,
      'status': status,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'error_message': errorMessage,
      'local_output_path': localOutputPath,
    }, onConflict: 'corporate_user_id,patient_id');
  }
}
