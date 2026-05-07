class SessionReferencePhotoModel {
  final int? id;
  final int sessionId;
  final int? patientId;
  final int? expertUserId;

  final String photoType;

  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;

  final String? localFilePath;

  final String? storageBucket;
  final String? storagePath;
  final String? publicUrl;

  final String uploadStatus;
  final String? note;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SessionReferencePhotoModel({
    this.id,
    required this.sessionId,
    this.patientId,
    this.expertUserId,
    required this.photoType,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.localFilePath,
    this.storageBucket,
    this.storagePath,
    this.publicUrl,
    this.uploadStatus = ReferencePhotoUploadStatuses.local,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory SessionReferencePhotoModel.fromMap(Map<String, dynamic> map) {
    return SessionReferencePhotoModel(
      id: _toInt(map['id']),
      sessionId: _toInt(map['session_id']) ?? 0,
      patientId: _toInt(map['patient_id']),
      expertUserId: _toInt(map['expert_user_id']),
      photoType: map['photo_type']?.toString() ?? '',
      fileName: map['file_name']?.toString(),
      mimeType: map['mime_type']?.toString(),
      sizeBytes: _toInt(map['size_bytes']),
      localFilePath: map['local_file_path']?.toString(),
      storageBucket: map['storage_bucket']?.toString(),
      storagePath: map['storage_path']?.toString(),
      publicUrl: map['public_url']?.toString(),
      uploadStatus: map['upload_status']?.toString() ??
          ReferencePhotoUploadStatuses.local,
      note: map['note']?.toString(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'session_id': sessionId,
      'patient_id': patientId,
      'expert_user_id': expertUserId,
      'photo_type': photoType,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'local_file_path': localFilePath,
      'storage_bucket': storageBucket,
      'storage_path': storagePath,
      'public_url': publicUrl,
      'upload_status': uploadStatus,
      'note': note,
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

class SessionReferencePhotoTypes {
  static const String insolePhoto = 'insole_photo';
  static const String footPhoto = 'foot_photo';
  static const String referencePhoto = 'reference_photo';
  static const String pressureScreenshot = 'pressure_screenshot';
}

class ReferencePhotoUploadStatuses {
  static const String local = 'local';
  static const String uploaded = 'uploaded';
  static const String failed = 'failed';
}