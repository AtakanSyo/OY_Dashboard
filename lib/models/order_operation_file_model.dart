class OrderOperationFileModel {
  final int? id;
  final int orderId;
  final int? sessionId;
  final int? patientId;
  final int? uploadedByUserId;

  final String fileType;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;

  final String? localFilePath;
  final String? storageBucket;
  final String? storagePath;
  final String? publicUrl;
  final String uploadStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderOperationFileModel({
    this.id,
    required this.orderId,
    this.sessionId,
    this.patientId,
    this.uploadedByUserId,
    required this.fileType,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.localFilePath,
    this.storageBucket,
    this.storagePath,
    this.publicUrl,
    this.uploadStatus = OrderOperationFileUploadStatuses.local,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderOperationFileModel.fromMap(Map<String, dynamic> map) {
    return OrderOperationFileModel(
      id: _toInt(map['id']),
      orderId: _toInt(map['order_id']) ?? 0,
      sessionId: _toInt(map['session_id']),
      patientId: _toInt(map['patient_id']),
      uploadedByUserId: _toInt(map['uploaded_by_user_id']),
      fileType: map['file_type']?.toString() ?? '',
      fileName: map['file_name']?.toString(),
      mimeType: map['mime_type']?.toString(),
      sizeBytes: _toInt(map['size_bytes']),
      localFilePath: map['local_file_path']?.toString(),
      storageBucket: map['storage_bucket']?.toString(),
      storagePath: map['storage_path']?.toString(),
      publicUrl: map['public_url']?.toString(),
      uploadStatus: map['upload_status']?.toString() ??
          OrderOperationFileUploadStatuses.local,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'order_id': orderId,
      'session_id': sessionId,
      'patient_id': patientId,
      'uploaded_by_user_id': uploadedByUserId,
      'file_type': fileType,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'local_file_path': localFilePath,
      'storage_bucket': storageBucket,
      'storage_path': storagePath,
      'public_url': publicUrl,
      'upload_status': uploadStatus,
    };
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class OrderOperationFileTypes {
  static const String leftDesignStl = 'left_design_stl';
  static const String rightDesignStl = 'right_design_stl';

  static const String leftProductionFile = 'left_production_file';
  static const String rightProductionFile = 'right_production_file';
}

class OrderOperationFileUploadStatuses {
  static const String local = 'local';
  static const String uploaded = 'uploaded';
  static const String failed = 'failed';
}