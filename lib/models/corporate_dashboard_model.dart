class CorporateKpiItem {
  final String title;
  final String value;
  final String subtitle;

  const CorporateKpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class CorporateRiskDistributionItem {
  final String label;
  final int count;

  const CorporateRiskDistributionItem({
    required this.label,
    required this.count,
  });
}

class CorporateIssueItem {
  final String title;
  final String percentage;
  final String description;

  const CorporateIssueItem({
    required this.title,
    required this.percentage,
    required this.description,
  });
}

class CorporateAlertItem {
  final String title;
  final String description;

  const CorporateAlertItem({required this.title, required this.description});
}

class CorporateDepartmentInsightItem {
  final String departmentName;
  final String keyFinding;
  final String riskLevel;

  const CorporateDepartmentInsightItem({
    required this.departmentName,
    required this.keyFinding,
    required this.riskLevel,
  });
}

class CorporateDepartmentItem {
  final String departmentName;
  final int employeeCount;
  final double avgRiskScore;
  final String topIssue;
  final String trendLabel;

  const CorporateDepartmentItem({
    required this.departmentName,
    required this.employeeCount,
    required this.avgRiskScore,
    required this.topIssue,
    required this.trendLabel,
  });
}

class CorporateTrendPoint {
  final String label;
  final double value;

  const CorporateTrendPoint({required this.label, required this.value});
}

enum CorporateScanStatus { waiting, scanning, completed, failed, needsRepeat }

class CorporateEmployeeItem {
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String departmentName;
  final String jobTitle;
  final String shift;
  final String? phone;
  final String? email;
  final String? gender;
  final DateTime? birthDate;
  final int? shoeSize;
  final CorporateScanStatus scanStatus;
  final DateTime? lastScanAt;
  final String? localScanOutputPath;
  final String? scanErrorMessage;
  final bool hasPersonalAccount;

  const CorporateEmployeeItem({
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.departmentName,
    required this.jobTitle,
    required this.shift,
    this.phone,
    this.email,
    this.gender,
    this.birthDate,
    this.shoeSize,
    this.scanStatus = CorporateScanStatus.waiting,
    this.lastScanAt,
    this.localScanOutputPath,
    this.scanErrorMessage,
    this.hasPersonalAccount = false,
  });

  String get fullName => '$firstName $lastName';

  bool get isCompleted => scanStatus == CorporateScanStatus.completed;

  CorporateEmployeeItem copyWith({
    CorporateScanStatus? scanStatus,
    DateTime? lastScanAt,
    String? localScanOutputPath,
    String? scanErrorMessage,
    bool? hasPersonalAccount,
  }) {
    return CorporateEmployeeItem(
      employeeCode: employeeCode,
      firstName: firstName,
      lastName: lastName,
      departmentName: departmentName,
      jobTitle: jobTitle,
      shift: shift,
      phone: phone,
      email: email,
      gender: gender,
      birthDate: birthDate,
      shoeSize: shoeSize,
      scanStatus: scanStatus ?? this.scanStatus,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      localScanOutputPath: localScanOutputPath ?? this.localScanOutputPath,
      scanErrorMessage: scanErrorMessage ?? this.scanErrorMessage,
      hasPersonalAccount: hasPersonalAccount ?? this.hasPersonalAccount,
    );
  }

  factory CorporateEmployeeItem.fromCsvMap(Map<String, String> row) {
    return CorporateEmployeeItem(
      employeeCode: _read(row, 'employee_code'),
      firstName: _read(row, 'first_name'),
      lastName: _read(row, 'last_name'),
      departmentName: _read(row, 'department'),
      jobTitle: _read(row, 'job_title'),
      shift: _read(row, 'shift'),
      phone: _readOptional(row, 'phone'),
      email: _readOptional(row, 'email'),
      gender: _readOptional(row, 'gender'),
      birthDate: _parseDate(_readOptional(row, 'birth_date')),
      shoeSize: int.tryParse(_read(row, 'shoe_size')),
      scanStatus: _parseStatus(_readOptional(row, 'scan_status')),
      lastScanAt: _parseDate(_readOptional(row, 'last_scan_at')),
      hasPersonalAccount: _parseBool(
        _readOptional(row, 'has_personal_account'),
      ),
    );
  }

  static String _read(Map<String, String> row, String key) {
    return (row[key] ?? '').trim();
  }

  static String? _readOptional(Map<String, String> row, String key) {
    final value = _read(row, key);
    return value.isEmpty ? null : value;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  static bool _parseBool(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'evet':
        return true;
      default:
        return false;
    }
  }

  static CorporateScanStatus _parseStatus(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'scanning':
      case 'taraniyor':
      case 'taranıyor':
        return CorporateScanStatus.scanning;
      case 'completed':
      case 'tamamlandi':
      case 'tamamlandı':
        return CorporateScanStatus.completed;
      case 'failed':
      case 'hata':
        return CorporateScanStatus.failed;
      case 'needs_repeat':
      case 'tekrar':
        return CorporateScanStatus.needsRepeat;
      case 'waiting':
      case 'bekliyor':
      default:
        return CorporateScanStatus.waiting;
    }
  }
}

class CorporateScanSessionItem {
  final int? id;
  final int corporateUserId;
  final int? patientId;
  final String patientCode;
  final CorporateScanStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final String? localOutputPath;
  final DateTime? updatedAt;

  const CorporateScanSessionItem({
    this.id,
    required this.corporateUserId,
    this.patientId,
    required this.patientCode,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.localOutputPath,
    this.updatedAt,
  });

  DateTime? get displayDate => completedAt ?? startedAt ?? updatedAt;

  factory CorporateScanSessionItem.fromMap(Map<String, dynamic> map) {
    return CorporateScanSessionItem(
      id: _toInt(map['id']),
      corporateUserId: _toInt(map['corporate_user_id']) ?? 0,
      patientId: _toInt(map['patient_id']),
      patientCode: map['patient_code']?.toString() ?? '',
      status: CorporateEmployeeItem._parseStatus(map['status']?.toString()),
      startedAt: CorporateEmployeeItem._parseDate(
        map['started_at']?.toString(),
      ),
      completedAt: CorporateEmployeeItem._parseDate(
        map['completed_at']?.toString(),
      ),
      errorMessage: map['error_message']?.toString(),
      localOutputPath: map['local_output_path']?.toString(),
      updatedAt: CorporateEmployeeItem._parseDate(
        map['updated_at']?.toString(),
      ),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class CorporateScanSummary {
  final int total;
  final int completed;
  final int waiting;
  final int failed;
  final int needsRepeat;

  const CorporateScanSummary({
    required this.total,
    required this.completed,
    required this.waiting,
    required this.failed,
    required this.needsRepeat,
  });

  int get remaining => waiting + failed + needsRepeat;
  double get completionRatio => total == 0 ? 0 : completed / total;

  factory CorporateScanSummary.fromEmployees(
    List<CorporateEmployeeItem> employees,
  ) {
    var completed = 0;
    var waiting = 0;
    var failed = 0;
    var needsRepeat = 0;

    for (final employee in employees) {
      switch (employee.scanStatus) {
        case CorporateScanStatus.completed:
          completed++;
        case CorporateScanStatus.failed:
          failed++;
        case CorporateScanStatus.needsRepeat:
          needsRepeat++;
        case CorporateScanStatus.waiting:
        case CorporateScanStatus.scanning:
          waiting++;
      }
    }

    return CorporateScanSummary(
      total: employees.length,
      completed: completed,
      waiting: waiting,
      failed: failed,
      needsRepeat: needsRepeat,
    );
  }
}

class CorporateReportItem {
  final String title;
  final String description;
  final String date;
  final String status;

  const CorporateReportItem({
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });
}

class CorporateDashboardModel {
  final List<CorporateKpiItem> kpis;
  final List<CorporateRiskDistributionItem> riskDistribution;
  final List<CorporateIssueItem> topIssues;
  final List<CorporateAlertItem> alerts;
  final List<CorporateDepartmentInsightItem> departmentInsights;

  const CorporateDashboardModel({
    required this.kpis,
    required this.riskDistribution,
    required this.topIssues,
    required this.alerts,
    required this.departmentInsights,
  });
}
