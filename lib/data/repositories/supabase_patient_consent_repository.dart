import 'dart:math';

import 'package:oy_site/models/patient_consent_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePatientConsentRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<PatientConsentRequestModel> createConsentRequest({
    required int patientId,
    required int expertUserId,
    required String email,
    String? patientName,
    int validDays = 14,
  }) async {
    final request = PatientConsentRequestModel(
      patientId: patientId,
      expertUserId: expertUserId,
      email: email,
      patientName: patientName,
      token: _generateToken(),
      status: PatientConsentStatuses.pending,
      expiresAt: DateTime.now().add(Duration(days: validDays)),
    );

    final response = await _client
        .from('patient_consent_requests')
        .insert(request.toInsertMap())
        .select()
        .single();

    return PatientConsentRequestModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<PatientConsentRequestModel?> getByToken({
    required String token,
  }) async {
    final response = await _client
        .from('patient_consent_requests')
        .select()
        .eq('token', token)
        .maybeSingle();

    if (response == null) return null;

    return PatientConsentRequestModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<PatientConsentRequestModel?> getLatestForPatient({
    required int patientId,
  }) async {
    final response = await _client
        .from('patient_consent_requests')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return PatientConsentRequestModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<PatientConsentRequestModel> acceptByToken({
    required String token,
  }) async {
    final response = await _client
        .from('patient_consent_requests')
        .update({
          'status': PatientConsentStatuses.accepted,
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('token', token)
        .select()
        .single();

    return PatientConsentRequestModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    final part = List.generate(
      40,
      (_) => chars[random.nextInt(chars.length)],
    ).join();

    return 'consent_$part';
  }
}
