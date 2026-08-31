class SessionPressureRecordingModel {
  final int? id;
  final int sessionId;
  final int? patientId;
  final int? expertUserId;

  final String title;
  final int frameCount;
  final int durationMs;

  final double? maxPressure;
  final double? avgPressure;

  final Map<String, dynamic>? rawFramesJson;
  final String? storageBucket;
  final String? storagePath;
  final String uploadStatus;

  final DateTime recordedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SessionPressureRecordingModel({
    this.id,
    required this.sessionId,
    this.patientId,
    this.expertUserId,
    required this.title,
    required this.frameCount,
    required this.durationMs,
    this.maxPressure,
    this.avgPressure,
    this.rawFramesJson,
    this.storageBucket,
    this.storagePath,
    this.uploadStatus = PressureUploadStatuses.local,
    required this.recordedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory SessionPressureRecordingModel.fromMap(Map<String, dynamic> map) {
    return SessionPressureRecordingModel(
      id: _toInt(map['id']),
      sessionId: _toInt(map['session_id']) ?? 0,
      patientId: _toInt(map['patient_id']),
      expertUserId: _toInt(map['expert_user_id']),
      title: map['title']?.toString() ?? '',
      frameCount: _toInt(map['frame_count']) ?? 0,
      durationMs: _toInt(map['duration_ms']) ?? 0,
      maxPressure: _toDouble(map['max_pressure']),
      avgPressure: _toDouble(map['avg_pressure']),
      rawFramesJson: _toMap(map['raw_frames_json']),
      storageBucket: map['storage_bucket']?.toString(),
      storagePath: map['storage_path']?.toString(),
      uploadStatus:
          map['upload_status']?.toString() ?? PressureUploadStatuses.local,
      recordedAt: _parseDate(map['recorded_at']) ?? DateTime.now(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'session_id': sessionId,
      'patient_id': patientId,
      'expert_user_id': expertUserId,
      'title': title,
      'frame_count': frameCount,
      'duration_ms': durationMs,
      'max_pressure': maxPressure,
      'avg_pressure': avgPressure,
      'raw_frames_json': rawFramesJson,
      'storage_bucket': storageBucket,
      'storage_path': storagePath,
      'upload_status': uploadStatus,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class PressureUploadStatuses {
  static const String local = 'local';
  static const String uploaded = 'uploaded';
  static const String failed = 'failed';
}