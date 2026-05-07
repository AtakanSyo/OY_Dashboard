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

  Future<void> deletePhoto({
    required int photoId,
  }) async {
    await _client.from('session_reference_photos').delete().eq('id', photoId);
  }
}