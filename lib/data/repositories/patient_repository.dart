import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oy_site/models/patient.dart';

class SupabasePatientRepository {
  final _client = Supabase.instance.client;

  Future<Patient> createPatient(Patient patient) async {
    final response = await _client
        .from('patients')
        .insert({
          'clinic_id': patient.clinicId,
          'created_by_user_id': patient.createdByUserId,
          'patient_code': patient.patientCode,
          'first_name': patient.firstName,
          'last_name': patient.lastName,
          'email': patient.email,
          'phone': patient.phone,
          'gender': patient.gender,
          'birth_date': patient.birthDate?.toIso8601String(),
          'notes': patient.notes,
        })
        .select()
        .single();

    return patient.copyWith(
      patientId: response['id'],
    );
  }
}