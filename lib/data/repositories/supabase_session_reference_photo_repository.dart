import 'package:oy_site/models/session_reference_photo_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSessionReferencePhotoRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<SessionReferencePhotoModel> createPhoto({
    required SessionReferencePhotoModel photo,
  }) async {
    final response = await _client
        .from('session_reference_photos')
        .insert(photo.toInsertMap())
        .select()
        .single();

    return SessionReferencePhotoModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<SessionReferencePhotoModel>> getPhotosBySessionId({
    required int sessionId,
  }) async {
    final response = await _client
        .from('session_reference_photos')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => SessionReferencePhotoModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<SessionReferencePhotoModel>>
  getInsolePhotosForCurrentCustomer() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('Oturum açmış kullanıcı bulunamadı.');
    }

    final patient = await _client
        .from('patients')
        .select('id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
    final patientId = _toInt(patient?['id']);
    if (patientId == null) return [];

    final response = await _client
        .from('session_reference_photos')
        .select()
        .eq('patient_id', patientId)
        .eq('photo_type', SessionReferencePhotoTypes.insolePhoto)
        .eq('upload_status', ReferencePhotoUploadStatuses.uploaded)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => SessionReferencePhotoModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<CurrentCustomerSession?> getLatestSessionForCurrentCustomer() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw Exception('Oturum açmış kullanıcı bulunamadı.');
    }

    final patient = await _client
        .from('patients')
        .select('id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
    final patientId = _toInt(patient?['id']);
    if (patientId == null) return null;

    final rows = await _client
        .from('measurement_sessions')
        .select('id, patient_id, expert_user_id')
        .eq('patient_id', patientId)
        .order('session_date', ascending: false)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List<dynamic>;
    if (list.isEmpty) return null;
    final row = Map<String, dynamic>.from(list.first as Map);
    final sessionId = _toInt(row['id']);
    if (sessionId == null) return null;

    return CurrentCustomerSession(
      sessionId: sessionId,
      patientId: patientId,
      expertUserId: _toInt(row['expert_user_id']),
    );
  }

  Future<void> deletePhoto({required int photoId}) async {
    await _client.from('session_reference_photos').delete().eq('id', photoId);
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class CurrentCustomerSession {
  final int sessionId;
  final int patientId;
  final int? expertUserId;

  const CurrentCustomerSession({
    required this.sessionId,
    required this.patientId,
    this.expertUserId,
  });
}
