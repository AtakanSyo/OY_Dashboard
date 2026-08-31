class AppUser {
  final int? userId;
  final int? roleId;
  final int? clinicId;

  final String firstName;
  final String lastName;
  final String email;
  final String? username;
  final String? phone;
  final String? title;
  final String? commissionProfileName;

  final String roleCode;
  final String roleName;

  final String? clinicCode;
  final String? clinicName;
  final String? clinicType;

  final bool isActive;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    this.userId,
    this.roleId,
    this.clinicId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.username,
    this.phone,
    this.title,
    this.commissionProfileName,
    required this.roleCode,
    required this.roleName,
    this.clinicCode,
    this.clinicName,
    this.clinicType,
    this.isActive = true,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => "$firstName $lastName";

  String get displayName {
    if ((title ?? '').trim().isNotEmpty) {
      return "${title!.trim()} $firstName $lastName";
    }
    return fullName;
  }

  bool get isExpert => roleCode == RoleCodes.expert;
  bool get isCustomer => roleCode == RoleCodes.customer;
  bool get isCorporate => roleCode == RoleCodes.corporate;
  bool get isOptiYouTeam => roleCode == RoleCodes.optiYouTeam;

  AppUser copyWith({
    int? userId,
    int? roleId,
    int? clinicId,
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    String? phone,
    String? title,
    String? commissionProfileName,
    String? roleCode,
    String? roleName,
    String? clinicCode,
    String? clinicName,
    String? clinicType,
    bool? isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
      clinicId: clinicId ?? this.clinicId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      title: title ?? this.title,
      commissionProfileName:
          commissionProfileName ?? this.commissionProfileName,
      roleCode: roleCode ?? this.roleCode,
      roleName: roleName ?? this.roleName,
      clinicCode: clinicCode ?? this.clinicCode,
      clinicName: clinicName ?? this.clinicName,
      clinicType: clinicType ?? this.clinicType,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'] as int?,
      roleId: map['role_id'] as int?,
      clinicId: map['clinic_id'] as int?,
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String?,
      phone: map['phone'] as String?,
      title: map['title'] as String?,
      commissionProfileName: map['commission_profile_name'] as String?,
      roleCode: map['role_code'] as String? ?? '',
      roleName: map['role_name'] as String? ?? '',
      clinicCode: map['clinic_code'] as String?,
      clinicName: map['clinic_name'] as String?,
      clinicType: map['clinic_type'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      lastLoginAt: _parseDate(map['last_login_at']),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'role_id': roleId,
      'clinic_id': clinicId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'username': username,
      'phone': phone,
      'title': title,
      'commission_profile_name': commissionProfileName,
      'role_code': roleCode,
      'role_name': roleName,
      'clinic_code': clinicCode,
      'clinic_name': clinicName,
      'clinic_type': clinicType,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
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

class RoleCodes {
  static const String expert = 'EXPERT';
  static const String customer = 'CUSTOMER';
  static const String corporate = 'CORPORATE';
  static const String optiYouTeam = 'OPTIYOU_TEAM';

  static const List<String> values = [
    expert,
    customer,
    corporate,
    optiYouTeam,
  ];
}