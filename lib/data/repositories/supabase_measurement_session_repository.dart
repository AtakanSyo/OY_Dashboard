import 'package:oy_site/models/measurement_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMeasurementSessionRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<MeasurementSession>> getSessionsByPatient({
    required int patientId,
  }) async {
    final response = await _client
        .from('measurement_sessions')
        .select()
        .eq('patient_id', patientId)
        .order('session_date', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => MeasurementSession.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<MeasurementSession>> getSessionsByExpert({
    required int expertUserId,
  }) async {
    final response = await _client
        .from('measurement_sessions')
        .select()
        .eq('expert_user_id', expertUserId)
        .order('session_date', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => MeasurementSession.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<MeasurementSession> createSession({
    required MeasurementSession session,
  }) async {
    final response = await _client
        .from('measurement_sessions')
        .insert(session.toInsertMap())
        .select()
        .single();

    return MeasurementSession.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> updateSession({
    required MeasurementSession session,
  }) async {
    if (session.sessionId == null) {
      throw Exception('Oturum ID bulunamadı.');
    }

    await _client
        .from('measurement_sessions')
        .update(session.toUpdateMap())
        .eq('id', session.sessionId!);
  }
}