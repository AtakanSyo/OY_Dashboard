class CorporateScanProject {
  const CorporateScanProject({
    required this.id,
    required this.companyName,
    required this.status,
    required this.createdAt,
    this.corporateUserId,
    this.corporateProfileId,
    this.factoryName,
    this.location,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.deviceId,
    this.startsAt,
    this.endsAt,
    this.targetEmployeeCount = 0,
    this.notes,
    this.createdByUserId,
    this.updatedAt,
  });

  final String id;
  final String? corporateUserId;
  final int? corporateProfileId;
  final String companyName;
  final String? factoryName;
  final String? location;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? deviceId;
  final String status;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int targetEmployeeCount;
  final String? notes;
  final String? createdByUserId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory CorporateScanProject.fromMap(Map<String, dynamic> map) {
    return CorporateScanProject(
      id: map['id']?.toString() ?? '',
      corporateUserId: map['corporate_user_id']?.toString(),
      corporateProfileId: _parseIntOrNull(map['corporate_profile_id']),
      companyName: map['company_name']?.toString() ?? 'Kurumsal proje',
      factoryName: map['factory_name']?.toString(),
      location: map['location']?.toString(),
      contactName: map['contact_name']?.toString(),
      contactPhone: map['contact_phone']?.toString(),
      contactEmail: map['contact_email']?.toString(),
      deviceId: map['device_id']?.toString(),
      status: map['status']?.toString() ?? 'preparing',
      startsAt: _parseDate(map['starts_at']),
      endsAt: _parseDate(map['ends_at']),
      targetEmployeeCount: _parseInt(map['target_employee_count']),
      notes: map['notes']?.toString(),
      createdByUserId: map['created_by_user_id']?.toString(),
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  String get displayName {
    final factory = factoryName?.trim();
    if (factory == null || factory.isEmpty) return companyName;
    return '$companyName - $factory';
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif tarama';
      case 'paused':
        return 'Duraklatıldı';
      case 'completed':
        return 'Tamamlandı';
      case 'closed':
        return 'Kapandı';
      case 'preparing':
      default:
        return 'Hazırlıkta';
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class CorporateScanProjectStats {
  const CorporateScanProjectStats({
    this.importedEmployees = 0,
    this.completedScans = 0,
    this.failedScans = 0,
    this.pendingScans = 0,
    this.lastScanAt,
  });

  final int importedEmployees;
  final int completedScans;
  final int failedScans;
  final int pendingScans;
  final DateTime? lastScanAt;

  double get completionRate {
    if (importedEmployees == 0) return 0;
    return (completedScans / importedEmployees).clamp(0, 1).toDouble();
  }
}

class CorporateScanProjectOverview {
  const CorporateScanProjectOverview({
    required this.project,
    required this.stats,
  });

  final CorporateScanProject project;
  final CorporateScanProjectStats stats;
}
