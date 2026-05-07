import 'dart:io';

class SessionScanFileModel {
  final int? id;
  final int sessionId;
  final int? patientId;
  final int? expertUserId;

  final String fileType;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;

  final String? localFilePath;

  final String? storageBucket;
  final String? storagePath;
  final String? publicUrl;
  final DateTime? signedUrlExpiresAt;

  final String uploadStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SessionScanFileModel({
    this.id,
    required this.sessionId,
    this.patientId,
    this.expertUserId,
    required this.fileType,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.localFilePath,
    this.storageBucket,
    this.storagePath,
    this.publicUrl,
    this.signedUrlExpiresAt,
    this.uploadStatus = ScanFileUploadStatuses.local,
    this.createdAt,
    this.updatedAt,
  });

  factory SessionScanFileModel.local({
    required int sessionId,
    required int patientId,
    required int expertUserId,
    required String fileType,
    required String? path,
  }) {
    if (path == null || path.trim().isEmpty) {
      return SessionScanFileModel(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        fileType: fileType,
      );
    }

    final file = File(path);
    final exists = file.existsSync();

    return SessionScanFileModel(
      sessionId: sessionId,
      patientId: patientId,
      expertUserId: expertUserId,
      fileType: fileType,
      fileName: path.split(Platform.pathSeparator).last,
      sizeBytes: exists ? file.lengthSync() : null,
      localFilePath: path,
      uploadStatus: ScanFileUploadStatuses.local,
    );
  }

  factory SessionScanFileModel.fromMap(Map<String, dynamic> map) {
    return SessionScanFileModel(
      id: _toInt(map['id']),
      sessionId: _toInt(map['session_id']) ?? 0,
      patientId: _toInt(map['patient_id']),
      expertUserId: _toInt(map['expert_user_id']),
      fileType: map['file_type']?.toString() ?? '',
      fileName: map['file_name']?.toString(),
      mimeType: map['mime_type']?.toString(),
      sizeBytes: _toInt(map['size_bytes']),
      localFilePath: map['local_file_path']?.toString(),
      storageBucket: map['storage_bucket']?.toString(),
      storagePath: map['storage_path']?.toString(),
      publicUrl: map['public_url']?.toString(),
      signedUrlExpiresAt: _parseDate(map['signed_url_expires_at']),
      uploadStatus:
          map['upload_status']?.toString() ?? ScanFileUploadStatuses.local,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'session_id': sessionId,
      'patient_id': patientId,
      'expert_user_id': expertUserId,
      'file_type': fileType,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'local_file_path': localFilePath,
      'storage_bucket': storageBucket,
      'storage_path': storagePath,
      'public_url': publicUrl,
      'signed_url_expires_at': signedUrlExpiresAt?.toIso8601String(),
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

class SessionScanFileTypes {
  static const String pdfReport = 'pdf_report';

  static const String archLeftImage = 'arch_left_image';
  static const String archRightImage = 'arch_right_image';

  static const String archSectionLeft = 'arch_section_left';
  static const String archSectionRight = 'arch_section_right';

  static const String foot2dLeft = 'foot_2d_left';
  static const String foot2dRight = 'foot_2d_right';

  static const String pronatorLeft = 'pronator_left';
  static const String pronatorRight = 'pronator_right';

  static const String stlLeft = 'stl_left';
  static const String stlRight = 'stl_right';
}

class ScanFileUploadStatuses {
  static const String local = 'local';
  static const String uploaded = 'uploaded';
  static const String failed = 'failed';
}