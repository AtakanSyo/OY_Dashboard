class CustomerAddressModel {
  final int? addressId;
  final int? userId;
  final int? patientId;

  final String title;
  final String fullName;
  final String phone;
  final String city;
  final String district;
  final String addressLine;
  final bool isDefault;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerAddressModel({
    this.addressId,
    this.userId,
    this.patientId,
    required this.title,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.district,
    required this.addressLine,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  String get displayText {
    return '$title\n'
        '$fullName • $phone\n'
        '$addressLine, $district/$city';
  }

  CustomerAddressModel copyWith({
    int? addressId,
    int? userId,
    int? patientId,
    String? title,
    String? fullName,
    String? phone,
    String? city,
    String? district,
    String? addressLine,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerAddressModel(
      addressId: addressId ?? this.addressId,
      userId: userId ?? this.userId,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      district: district ?? this.district,
      addressLine: addressLine ?? this.addressLine,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerAddressModel.fromMap(Map<String, dynamic> map) {
    return CustomerAddressModel(
      addressId: _toInt(map['id'] ?? map['address_id']),
      userId: _toInt(map['user_id']),
      patientId: _toInt(map['patient_id']),
      title: map['title']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      district: map['district']?.toString() ?? '',
      addressLine: map['address_line']?.toString() ?? '',
      isDefault: map['is_default'] as bool? ?? false,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (addressId != null) 'id': addressId,
      'user_id': userId,
      'patient_id': patientId,
      'title': title,
      'full_name': fullName,
      'phone': phone,
      'city': city,
      'district': district,
      'address_line': addressLine,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'patient_id': patientId,
      'title': title,
      'full_name': fullName,
      'phone': phone,
      'city': city,
      'district': district,
      'address_line': addressLine,
      'is_default': isDefault,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'full_name': fullName,
      'phone': phone,
      'city': city,
      'district': district,
      'address_line': addressLine,
      'is_default': isDefault,
    };
  }

  Map<String, dynamic> toSnapshotMap() {
    return {
      'title': title,
      'full_name': fullName,
      'phone': phone,
      'city': city,
      'district': district,
      'address_line': addressLine,
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