class Patient {
  final int? patientId;
  final int? clinicId;
  final int? createdByUserId;

  final String patientCode;
  final String firstName;
  final String lastName;
  final String? email;
  final DateTime? birthDate;
  final String? gender;
  final String? phone;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Patient({
    this.patientId,
    this.clinicId,
    this.createdByUserId,
    required this.patientCode,
    required this.firstName,
    required this.lastName,
    this.email,
    this.birthDate,
    this.gender,
    this.phone,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  String get displayEmail {
    final value = (email ?? '').trim();
    return value.isEmpty ? 'E-posta yok' : value;
  }

  String get displayPhone {
    final value = (phone ?? '').trim();
    return value.isEmpty ? 'Telefon yok' : value;
  }

  String get displayGender {
    switch ((gender ?? '').toLowerCase()) {
      case 'female':
        return 'Kadın';
      case 'male':
        return 'Erkek';
      case 'other':
        return 'Diğer';
      case 'unspecified':
      default:
        return 'Belirtilmemiş';
    }
  }

  Patient copyWith({
    int? patientId,
    int? clinicId,
    int? createdByUserId,
    String? patientCode,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? birthDate,
    String? gender,
    String? phone,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Patient(
      patientId: patientId ?? this.patientId,
      clinicId: clinicId ?? this.clinicId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      patientCode: patientCode ?? this.patientCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      patientId: _toInt(map['id'] ?? map['patient_id']),
      clinicId: _toInt(map['clinic_id']),
      createdByUserId: _toInt(map['created_by_user_id']),
      patientCode: map['patient_code']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      email: map['email']?.toString(),
      birthDate: _parseDate(map['birth_date']),
      gender: map['gender']?.toString(),
      phone: map['phone']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (patientId != null) 'id': patientId,
      'clinic_id': clinicId,
      'created_by_user_id': createdByUserId,
      'patient_code': patientCode,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'notes': notes,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'clinic_id': clinicId,
      'created_by_user_id': createdByUserId,
      'patient_code': patientCode,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'notes': notes,
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