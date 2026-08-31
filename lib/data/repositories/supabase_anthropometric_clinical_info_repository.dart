import 'package:oy_site/models/anthropometric_clinical_info_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAnthropometricClinicalInfoRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<AnthropometricClinicalInfoModel?> getBySessionId(
    int sessionId,
  ) async {
    final response = await _client
        .from('anthropometric_clinical_infos')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    return AnthropometricClinicalInfoModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<AnthropometricClinicalInfoModel> upsert({
    required AnthropometricClinicalInfoModel model,
    required int patientId,
    required int expertUserId,
  }) async {
    final payload = {
      ...model.toMap(),
      'patient_id': patientId,
      'expert_user_id': expertUserId,
    };

    payload.remove('anthropometric_id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final response = await _client
        .from('anthropometric_clinical_infos')
        .upsert(
          payload,
          onConflict: 'session_id',
        )
        .select()
        .single();

    return AnthropometricClinicalInfoModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> deleteBySessionId(int sessionId) async {
    await _client
        .from('anthropometric_clinical_infos')
        .delete()
        .eq('session_id', sessionId);
  }
}