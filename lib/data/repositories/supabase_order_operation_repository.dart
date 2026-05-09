import 'dart:io';

import 'package:oy_site/models/order_operation_file_model.dart';
import 'package:oy_site/models/order_operation_state_model.dart';
import 'package:oy_site/services/storage/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOrderOperationRepository {
  SupabaseClient get _client => Supabase.instance.client;

  final SupabaseStorageService _storageService = SupabaseStorageService();

  Future<OrderOperationStateModel?> getStateByOrderId({
    required int orderId,
  }) async {
    final response = await _client
        .from('order_operation_states')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();

    if (response == null) return null;

    return OrderOperationStateModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<OrderOperationStateModel> upsertState({
    required OrderOperationStateModel state,
  }) async {
    final response = await _client
        .from('order_operation_states')
        .upsert(
          state.toUpsertMap(),
          onConflict: 'order_id',
        )
        .select()
        .single();

    return OrderOperationStateModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<OrderOperationStateModel> updateBoardColumn({
    required int orderId,
    required String boardColumnCode,
    int? sessionId,
    int? patientId,
    int? assignedUserId,
  }) async {
    final existing = await getStateByOrderId(orderId: orderId);

    final state = existing == null
        ? OrderOperationStateModel.empty(
            orderId: orderId,
            sessionId: sessionId,
            patientId: patientId,
            assignedUserId: assignedUserId,
          ).copyWith(
            boardColumnCode: boardColumnCode,
          )
        : existing.copyWith(
            boardColumnCode: boardColumnCode,
            sessionId: existing.sessionId ?? sessionId,
            patientId: existing.patientId ?? patientId,
            assignedUserId: existing.assignedUserId ?? assignedUserId,
          );

    return upsertState(state: state);
  }

  Future<List<OrderOperationFileModel>> getFilesByOrderId({
    required int orderId,
  }) async {
    final response = await _client
        .from('order_operation_files')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map(
          (item) => OrderOperationFileModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<OrderOperationFileModel> uploadOperationFile({
    required int orderId,
    required int sessionId,
    required int patientId,
    required int uploadedByUserId,
    required String fileType,
    required String localFilePath,
    String? fileName,
    String? mimeType,
  }) async {
    final file = File(localFilePath);

    if (!file.existsSync()) {
      throw Exception('Dosya bulunamadı: $localFilePath');
    }

    final safeFileName =
        fileName ?? localFilePath.split(Platform.pathSeparator).last;

    final storagePath = 'orders/$orderId/operation/$fileType/$safeFileName';

    final uploadResult = await _storageService.uploadLocalFile(
      localFilePath: localFilePath,
      storagePath: storagePath,
    );

    final model = OrderOperationFileModel(
      orderId: orderId,
      sessionId: sessionId,
      patientId: patientId,
      uploadedByUserId: uploadedByUserId,
      fileType: fileType,
      fileName: safeFileName,
      mimeType: mimeType ?? _guessMimeType(safeFileName),
      sizeBytes: uploadResult.sizeBytes,
      localFilePath: localFilePath,
      storageBucket: uploadResult.bucket,
      storagePath: uploadResult.storagePath,
      publicUrl: null,
      uploadStatus: OrderOperationFileUploadStatuses.uploaded,
    );

    final response = await _client
        .from('order_operation_files')
        .upsert(
          model.toUpsertMap(),
          onConflict: 'order_id,file_type',
        )
        .select()
        .single();

    return OrderOperationFileModel.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<String> createSignedUrl({
    required OrderOperationFileModel file,
    int expiresInSeconds = 3600,
  }) async {
    final bucket = file.storageBucket;
    final path = file.storagePath;

    if (bucket == null || path == null) {
      throw Exception('Dosya Storage üzerinde bulunamadı.');
    }

    return _storageService.createSignedUrl(
      bucket: bucket,
      storagePath: path,
      expiresInSeconds: expiresInSeconds,
    );
  }

  String? _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.stl')) return 'model/stl';
    if (lower.endsWith('.gcode')) return 'text/plain';
    if (lower.endsWith('.nc')) return 'text/plain';
    if (lower.endsWith('.tap')) return 'text/plain';
    if (lower.endsWith('.txt')) return 'text/plain';

    return null;
  }
}