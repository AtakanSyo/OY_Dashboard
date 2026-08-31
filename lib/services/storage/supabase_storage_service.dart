import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  SupabaseClient get _client => Supabase.instance.client;

  static const String defaultBucket = 'session-files';

  Future<StorageUploadResult> uploadLocalFile({
    required String localFilePath,
    required String storagePath,
    String bucket = defaultBucket,
    bool upsert = true,
  }) async {
    final file = File(localFilePath);

    if (!file.existsSync()) {
      throw Exception('Dosya bulunamadı: $localFilePath');
    }

    final normalizedPath = _normalizeStoragePath(storagePath);

    await _client.storage.from(bucket).upload(
          normalizedPath,
          file,
          fileOptions: FileOptions(
            upsert: upsert,
          ),
        );

    return StorageUploadResult(
      bucket: bucket,
      storagePath: normalizedPath,
      sizeBytes: file.lengthSync(),
    );
  }

  Future<StorageUploadResult> uploadBytes({
    required List<int> bytes,
    required String storagePath,
    String bucket = defaultBucket,
    bool upsert = true,
  }) async {
    final normalizedPath = _normalizeStoragePath(storagePath);

    final uint8Bytes = bytes is Uint8List
        ? bytes
        : Uint8List.fromList(bytes);

    await _client.storage.from(bucket).uploadBinary(
          normalizedPath,
          uint8Bytes,
          fileOptions: FileOptions(
            upsert: upsert,
          ),
        );

    return StorageUploadResult(
      bucket: bucket,
      storagePath: normalizedPath,
      sizeBytes: uint8Bytes.length,
    );
  }

  Future<String> createSignedUrl({
    required String storagePath,
    String bucket = defaultBucket,
    int expiresInSeconds = 3600,
  }) async {
    final normalizedPath = _normalizeStoragePath(storagePath);

    return _client.storage.from(bucket).createSignedUrl(
          normalizedPath,
          expiresInSeconds,
        );
  }

  Future<void> removeFile({
    required String storagePath,
    String bucket = defaultBucket,
  }) async {
    final normalizedPath = _normalizeStoragePath(storagePath);

    await _client.storage.from(bucket).remove([normalizedPath]);
  }

  String buildSessionScanPath({
    required int sessionId,
    required String fileType,
    required String fileName,
  }) {
    return _normalizeStoragePath(
      'sessions/$sessionId/scan/$fileType/${_safeFileName(fileName)}',
    );
  }

  String buildReferencePhotoPath({
    required int sessionId,
    required String photoType,
    required String fileName,
  }) {
    return _normalizeStoragePath(
      'sessions/$sessionId/reference-photos/$photoType/${_safeFileName(fileName)}',
    );
  }

  String buildPressureRecordingPath({
    required int sessionId,
    required String recordingId,
  }) {
    return _normalizeStoragePath(
      'sessions/$sessionId/pressure/$recordingId.json',
    );
  }

  String _normalizeStoragePath(String path) {
    return path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
  }

  String _safeFileName(String fileName) {
    return fileName
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }
}

class StorageUploadResult {
  final String bucket;
  final String storagePath;
  final int sizeBytes;

  const StorageUploadResult({
    required this.bucket,
    required this.storagePath,
    required this.sizeBytes,
  });
}