class PatientConsentRequestModel {
  final int? requestId;
  final int patientId;
  final int? expertUserId;

  final String email;
  final String? patientName;
  final String token;
  final String status;

  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientConsentRequestModel({
    this.requestId,
    required this.patientId,
    this.expertUserId,
    required this.email,
    this.patientName,
    required this.token,
    required this.status,
    required this.expiresAt,
    this.acceptedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == PatientConsentStatuses.pending;
  bool get isAccepted => status == PatientConsentStatuses.accepted;

  bool get isExpired {
    return isPending && expiresAt.isBefore(DateTime.now());
  }

  bool get isStillValid {
    return isPending && expiresAt.isAfter(DateTime.now());
  }

  String get consentUrl {
    return 'https://optiyou.fit/#/legal-consent?token=$token';
  }

  factory PatientConsentRequestModel.fromMap(Map<String, dynamic> map) {
    return PatientConsentRequestModel(
      requestId: _toInt(map['id'] ?? map['request_id']),
      patientId: _toInt(map['patient_id']) ?? 0,
      expertUserId: _toInt(map['expert_user_id']),
      email: map['email']?.toString() ?? '',
      patientName: map['patient_name']?.toString(),
      token: map['token']?.toString() ?? '',
      status: map['status']?.toString() ?? PatientConsentStatuses.pending,
      expiresAt: _parseDate(map['expires_at']) ??
          DateTime.now().add(const Duration(days: 14)),
      acceptedAt: _parseDate(map['accepted_at']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'patient_id': patientId,
      'expert_user_id': expertUserId,
      'email': email,
      'patient_name': patientName,
      'token': token,
      'status': status,
      'expires_at': expiresAt.toIso8601String(),
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

class PatientConsentStatuses {
  static const String pending = 'pending';
  static const String accepted = 'accepted';

  static const List<String> values = [
    pending,
    accepted,
  ];
}
