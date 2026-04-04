class MeasurementSession {
  final int? sessionId;
  final int clinicId;
  final int patientId;
  final int expertUserId;
  final int? assignedOptityouUserId;

  final String sessionCode;
  final DateTime sessionDate;
  final String? sessionTime;
  final String status;

  final bool has3dScan;
  final bool hasPlantarCsv;
  final bool hasInsolePhoto;
  final bool orderCreated;

  // UI workflow için geçici alanlar
  final bool clinicalInfoCompleted;
  final bool designFormCompleted;

  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MeasurementSession({
    this.sessionId,
    required this.clinicId,
    required this.patientId,
    required this.expertUserId,
    this.assignedOptityouUserId,
    required this.sessionCode,
    required this.sessionDate,
    this.sessionTime,
    required this.status,
    this.has3dScan = false,
    this.hasPlantarCsv = false,
    this.hasInsolePhoto = false,
    this.orderCreated = false,
    this.clinicalInfoCompleted = false,
    this.designFormCompleted = false,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDraft => effectiveStatus == SessionStatuses.draft;
  bool get isInProgress => effectiveStatus == SessionStatuses.inProgress;
  bool get isCompleted => effectiveStatus == SessionStatuses.completed;
  bool get isCancelled => effectiveStatus == SessionStatuses.cancelled;

  List<bool> get workflowSteps => [
        clinicalInfoCompleted,
        has3dScan,
        hasPlantarCsv,
        hasInsolePhoto,
        designFormCompleted,
        orderCreated,
      ];

  int get completedStepCount => workflowSteps.where((e) => e).length;
  int get totalStepCount => workflowSteps.length;

  bool get hasAnyStepCompleted => completedStepCount > 0;
  bool get allStepsCompleted => completedStepCount == totalStepCount;

  String get effectiveStatus {
    if (status == SessionStatuses.cancelled) {
      return SessionStatuses.cancelled;
    }

    if (!hasAnyStepCompleted) {
      return SessionStatuses.draft;
    }

    if (allStepsCompleted) {
      return SessionStatuses.completed;
    }

    return SessionStatuses.inProgress;
  }

  bool get canCreateOrder =>
      clinicalInfoCompleted &&
      has3dScan &&
      hasPlantarCsv &&
      hasInsolePhoto &&
      designFormCompleted;

  MeasurementSession copyWith({
    int? sessionId,
    int? clinicId,
    int? patientId,
    int? expertUserId,
    int? assignedOptityouUserId,
    String? sessionCode,
    DateTime? sessionDate,
    String? sessionTime,
    String? status,
    bool? has3dScan,
    bool? hasPlantarCsv,
    bool? hasInsolePhoto,
    bool? orderCreated,
    bool? clinicalInfoCompleted,
    bool? designFormCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MeasurementSession(
      sessionId: sessionId ?? this.sessionId,
      clinicId: clinicId ?? this.clinicId,
      patientId: patientId ?? this.patientId,
      expertUserId: expertUserId ?? this.expertUserId,
      assignedOptityouUserId:
          assignedOptityouUserId ?? this.assignedOptityouUserId,
      sessionCode: sessionCode ?? this.sessionCode,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionTime: sessionTime ?? this.sessionTime,
      status: status ?? this.status,
      has3dScan: has3dScan ?? this.has3dScan,
      hasPlantarCsv: hasPlantarCsv ?? this.hasPlantarCsv,
      hasInsolePhoto: hasInsolePhoto ?? this.hasInsolePhoto,
      orderCreated: orderCreated ?? this.orderCreated,
      clinicalInfoCompleted:
          clinicalInfoCompleted ?? this.clinicalInfoCompleted,
      designFormCompleted: designFormCompleted ?? this.designFormCompleted,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MeasurementSession.fromMap(Map<String, dynamic> map) {
    return MeasurementSession(
      sessionId: map['session_id'] as int?,
      clinicId: map['clinic_id'] as int? ?? 0,
      patientId: map['patient_id'] as int? ?? 0,
      expertUserId: map['expert_user_id'] as int? ?? 0,
      assignedOptityouUserId: map['assigned_optityou_user_id'] as int?,
      sessionCode: map['session_code'] as String? ?? '',
      sessionDate: _parseDate(map['session_date']) ?? DateTime.now(),
      sessionTime: map['session_time']?.toString(),
      status: map['status'] as String? ?? SessionStatuses.draft,
      has3dScan: map['has_3d_scan'] as bool? ?? false,
      hasPlantarCsv: map['has_plantar_csv'] as bool? ?? false,
      hasInsolePhoto: map['has_insole_photo'] as bool? ?? false,
      orderCreated: map['order_created'] as bool? ?? false,
      clinicalInfoCompleted: map['clinical_info_completed'] as bool? ?? false,
      designFormCompleted: map['design_form_completed'] as bool? ?? false,
      completedAt: _parseDate(map['completed_at']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'clinic_id': clinicId,
      'patient_id': patientId,
      'expert_user_id': expertUserId,
      'assigned_optityou_user_id': assignedOptityouUserId,
      'session_code': sessionCode,
      'session_date': sessionDate.toIso8601String(),
      'session_time': sessionTime,
      'status': status,
      'has_3d_scan': has3dScan,
      'has_plantar_csv': hasPlantarCsv,
      'has_insole_photo': hasInsolePhoto,
      'order_created': orderCreated,
      'clinical_info_completed': clinicalInfoCompleted,
      'design_form_completed': designFormCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class SessionStatuses {
  static const String draft = 'draft';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> values = [
    draft,
    inProgress,
    completed,
    cancelled,
  ];
}