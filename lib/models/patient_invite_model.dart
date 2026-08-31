class PatientInviteModel {
  final int? inviteId;
  final int patientId;
  final int? sessionId;
  final int? expertUserId;

  final String? email;
  final String token;
  final String status;

  final DateTime expiresAt;
  final DateTime? usedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientInviteModel({
    this.inviteId,
    required this.patientId,
    this.sessionId,
    this.expertUserId,
    this.email,
    required this.token,
    required this.status,
    required this.expiresAt,
    this.usedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == PatientInviteStatuses.pending;
  bool get isUsed => status == PatientInviteStatuses.used;
  bool get isExpired => status == PatientInviteStatuses.expired;
  bool get isCancelled => status == PatientInviteStatuses.cancelled;

  bool get isStillValid {
    return isPending && expiresAt.isAfter(DateTime.now());
  }

  String get registrationUrl {
    return 'https://optiyou.fit/#/register?invite=$token';
  }

  PatientInviteModel copyWith({
    int? inviteId,
    int? patientId,
    int? sessionId,
    int? expertUserId,
    String? email,
    String? token,
    String? status,
    DateTime? expiresAt,
    DateTime? usedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientInviteModel(
      inviteId: inviteId ?? this.inviteId,
      patientId: patientId ?? this.patientId,
      sessionId: sessionId ?? this.sessionId,
      expertUserId: expertUserId ?? this.expertUserId,
      email: email ?? this.email,
      token: token ?? this.token,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PatientInviteModel.fromMap(Map<String, dynamic> map) {
    return PatientInviteModel(
      inviteId: _toInt(map['id'] ?? map['invite_id']),
      patientId: _toInt(map['patient_id']) ?? 0,
      sessionId: _toInt(map['session_id']),
      expertUserId: _toInt(map['expert_user_id']),
      email: map['email']?.toString(),
      token: map['token']?.toString() ?? '',
      status: map['status']?.toString() ?? PatientInviteStatuses.pending,
      expiresAt: _parseDate(map['expires_at']) ??
          DateTime.now().add(const Duration(days: 14)),
      usedAt: _parseDate(map['used_at']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'patient_id': patientId,
      'session_id': sessionId,
      'expert_user_id': expertUserId,
      'email': email,
      'token': token,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'email': email,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class PatientInviteStatuses {
  static const String pending = 'pending';
  static const String used = 'used';
  static const String expired = 'expired';
  static const String cancelled = 'cancelled';

  static const List<String> values = [
    pending,
    used,
    expired,
    cancelled,
  ];
}