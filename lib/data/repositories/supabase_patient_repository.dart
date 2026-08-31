import 'package:oy_site/models/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePatientRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<Patient> createPatient(Patient patient) async {
    final response = await _client
        .from('patients')
        .insert(patient.toInsertMap())
        .select()
        .single();

    return Patient.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<Patient>> getPatientsByExpert({
    required int expertUserId,
  }) async {
    final response = await _client
        .from('patients')
        .select()
        .eq('created_by_user_id', expertUserId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((item) => Patient.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<Patient?> getPatientById({
    required int patientId,
  }) async {
    final response = await _client
        .from('patients')
        .select()
        .eq('id', patientId)
        .maybeSingle();

    if (response == null) return null;

    return Patient.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> linkAuthUserToPatient({
    required int patientId,
    required String authUserId,
  }) async {
    final response = await _client
        .from('patients')
        .update({
          'auth_user_id': authUserId,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', patientId)
        .select('id, auth_user_id')
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'Patient auth_user_id güncellenemedi. patientId=$patientId',
      );
    }

    final updated = Map<String, dynamic>.from(response as Map);
    final updatedAuthUserId = updated['auth_user_id']?.toString();

    if (updatedAuthUserId != authUserId) {
      throw Exception(
        'Patient auth_user_id eşleşmiyor. '
        'expected=$authUserId, actual=$updatedAuthUserId',
      );
    }
  }
}