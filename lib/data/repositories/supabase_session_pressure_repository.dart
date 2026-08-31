import 'package:oy_site/models/session_pressure_recording_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSessionPressureRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<SessionPressureRecordingModel> createRecording({
    required SessionPressureRecordingModel recording,
  }) async {
    final response = await _client
        .from('session_pressure_recordings')
        .insert(recording.toInsertMap())
        .select()
        .single();

    return SessionPressureRecordingModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<SessionPressureRecordingModel>> getRecordingsBySessionId({
    required int sessionId,
  }) async {
    final response = await _client
        .from('session_pressure_recordings')
        .select()
        .eq('session_id', sessionId)
        .order('recorded_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => SessionPressureRecordingModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> deleteRecording({
    required int recordingId,
  }) async {
    await _client
        .from('session_pressure_recordings')
        .delete()
        .eq('id', recordingId);
  }
}