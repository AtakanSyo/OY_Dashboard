import 'package:oy_site/models/orthotic_design_form_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOrthoticDesignFormRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<OrthoticDesignFormModel?> getBySessionId(
    int sessionId,
  ) async {
    final response = await _client
        .from('orthotic_design_forms')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    return OrthoticDesignFormModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<OrthoticDesignFormModel> upsert({
    required OrthoticDesignFormModel model,
    required int patientId,
  }) async {
    final payload = {
      ...model.toMap(),
      'patient_id': patientId,
      'form_json': {
        'heelPad': model.heelPad,
        'deepHeelCupMm': model.deepHeelCupMm,
        'heelRaiseMm': model.heelRaiseMm,
        'medialArchSupport': model.medialArchSupport,
        'metatarsalPad': model.metatarsalPad,
        'transverseArchSupport': model.transverseArchSupport,
        'posteriorReliefMm': model.posteriorReliefMm,
        'mortonRelief': model.mortonRelief,
        'bunionPad': model.bunionPad,
        'expertNotes': model.expertNotes,
      }
    };

    payload.remove('design_form_id');
    payload.remove('created_at');
    payload.remove('updated_at');

    final response = await _client
        .from('orthotic_design_forms')
        .upsert(
          payload,
          onConflict: 'session_id',
        )
        .select()
        .single();

    return OrthoticDesignFormModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }
}