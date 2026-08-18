import 'dart:math';

import 'package:oy_site/models/patient_invite_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePatientInviteRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<PatientInviteModel> createInvite({
    required int patientId,
    required int sessionId,
    required int expertUserId,
    String? email,
    int validDays = 14,
  }) async {
    final invite = PatientInviteModel(
      patientId: patientId,
      sessionId: sessionId,
      expertUserId: expertUserId,
      email: email,
      token: _generateToken(),
      status: PatientInviteStatuses.pending,
      expiresAt: DateTime.now().add(Duration(days: validDays)),
    );

    final response = await _client
        .from('patient_invites')
        .insert(invite.toInsertMap())
        .select()
        .single();

    return PatientInviteModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<PatientInviteModel?> getLatestInviteForSession({
    required int sessionId,
  }) async {
    final response = await _client
        .from('patient_invites')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return PatientInviteModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<PatientInviteModel?> getInviteByToken({required String token}) async {
    final response = await _client
        .rpc('get_patient_invite_by_token', params: {'p_token': token.trim()})
        .maybeSingle();

    if (response == null) return null;

    return PatientInviteModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<PatientInviteModel> claimInvite({required String token}) async {
    final response = await _client
        .rpc('claim_patient_invite', params: {'p_token': token.trim()})
        .single();

    return PatientInviteModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<void> markInviteAsUsed({required int inviteId}) async {
    await _client
        .from('patient_invites')
        .update({
          'status': PatientInviteStatuses.used,
          'used_at': DateTime.now().toIso8601String(),
        })
        .eq('id', inviteId);
  }

  Future<void> cancelInvite({required int inviteId}) async {
    await _client
        .from('patient_invites')
        .update({'status': PatientInviteStatuses.cancelled})
        .eq('id', inviteId);
  }

  String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();

    final part = List.generate(
      40,
      (_) => chars[random.nextInt(chars.length)],
    ).join();

    return 'inv_$part';
  }
}
