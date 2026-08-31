import 'package:oy_site/models/parsed_scan_report.dart';

class CustomerFootSummary {
  final String side; // left / right
  final String footType;
  final String pressureSummary;
  final String balanceSummary;
  final String archSupportNeed;
  final String mainFinding;
  final double pressureScore;
  final double stabilityScore;
  final double archScore;

  const CustomerFootSummary({
    required this.side,
    required this.footType,
    required this.pressureSummary,
    required this.balanceSummary,
    required this.archSupportNeed,
    required this.mainFinding,
    required this.pressureScore,
    required this.stabilityScore,
    required this.archScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'side': side,
      'footType': footType,
      'pressureSummary': pressureSummary,
      'balanceSummary': balanceSummary,
      'archSupportNeed': archSupportNeed,
      'mainFinding': mainFinding,
      'pressureScore': pressureScore,
      'stabilityScore': stabilityScore,
      'archScore': archScore,
    };
  }

  factory CustomerFootSummary.fromMap(Map<String, dynamic> map) {
    return CustomerFootSummary(
      side: map['side']?.toString() ?? '',
      footType: map['footType']?.toString() ?? '',
      pressureSummary: map['pressureSummary']?.toString() ?? '',
      balanceSummary: map['balanceSummary']?.toString() ?? '',
      archSupportNeed: map['archSupportNeed']?.toString() ?? '',
      mainFinding: map['mainFinding']?.toString() ?? '',
      pressureScore: _toDouble(map['pressureScore']),
      stabilityScore: _toDouble(map['stabilityScore']),
      archScore: _toDouble(map['archScore']),
    );
  }
}

class CustomerAnalysisMetric {
  final String label;
  final String value;
  final String description;

  const CustomerAnalysisMetric({
    required this.label,
    required this.value,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {'label': label, 'value': value, 'description': description};
  }

  factory CustomerAnalysisMetric.fromMap(Map<String, dynamic> map) {
    return CustomerAnalysisMetric(
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }
}

class CustomerRecommendationItem {
  final String title;
  final String description;

  const CustomerRecommendationItem({
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {'title': title, 'description': description};
  }

  factory CustomerRecommendationItem.fromMap(Map<String, dynamic> map) {
    return CustomerRecommendationItem(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
    );
  }
}

class CustomerAnalysisResult {
  /// Supabase measurement_sessions.id değeri.
  ///
  /// Basınç ölçüm kayıtlarını ve diğer oturum verilerini değerlendirme sonucu ile
  /// ilişkilendirmek için kullanılır.
  final int? sessionId;

  final String sessionCode;
  final String locationLabel;
  final DateTime analysisDate;
  final String overallSummary;
  final String generalRiskNote;
  final CustomerFootSummary leftFoot;
  final CustomerFootSummary rightFoot;
  final List<CustomerAnalysisMetric> metrics;
  final List<CustomerRecommendationItem> recommendations;
  final CustomerAnalysisVisualSet visuals;
  final ParsedScanReport? parsedReport;

  const CustomerAnalysisResult({
    this.sessionId,
    required this.sessionCode,
    required this.locationLabel,
    required this.analysisDate,
    required this.overallSummary,
    required this.generalRiskNote,
    required this.leftFoot,
    required this.rightFoot,
    required this.metrics,
    required this.recommendations,
    required this.visuals,
    this.parsedReport,
  });

  Map<String, dynamic> toMap({
    int? userId,
    int? patientId,

    /// Geriye dönük uyumluluk için korunmuştur.
    ///
    /// Metoda bir sessionId verilirse bu değer kullanılır. Verilmezse modelin
    /// kendi sessionId alanı kullanılır.
    int? sessionId,
  }) {
    return {
      'user_id': userId,
      'patient_id': patientId,
      'session_id': sessionId ?? this.sessionId,
      'session_code': sessionCode,
      'analysis_date': analysisDate.toIso8601String(),
      'location_label': locationLabel,
      'overall_summary': overallSummary,
      'general_risk_note': generalRiskNote,
      'left_foot': leftFoot.toMap(),
      'right_foot': rightFoot.toMap(),
      'metrics': metrics.map((item) => item.toMap()).toList(),
      'recommendations': recommendations.map((item) => item.toMap()).toList(),
      'visuals': visuals.toMap(),
      'parsed_report': parsedReport == null
          ? null
          : _parsedScanReportToMap(parsedReport!),
    };
  }

  factory CustomerAnalysisResult.fromMap(Map<String, dynamic> map) {
    return CustomerAnalysisResult(
      sessionId: _toInt(map['session_id']),
      sessionCode: map['session_code']?.toString() ?? '',
      locationLabel: map['location_label']?.toString() ?? '',
      analysisDate: _toDateTime(map['analysis_date']),
      overallSummary: map['overall_summary']?.toString() ?? '',
      generalRiskNote: map['general_risk_note']?.toString() ?? '',
      leftFoot: CustomerFootSummary.fromMap(_asMap(map['left_foot'])),
      rightFoot: CustomerFootSummary.fromMap(_asMap(map['right_foot'])),
      metrics: _asList(
        map['metrics'],
      ).map((item) => CustomerAnalysisMetric.fromMap(_asMap(item))).toList(),
      recommendations: _asList(map['recommendations'])
          .map((item) => CustomerRecommendationItem.fromMap(_asMap(item)))
          .toList(),
      visuals: CustomerAnalysisVisualSet.fromMap(_asMap(map['visuals'])),
      parsedReport: map['parsed_report'] == null
          ? null
          : _parsedScanReportFromMap(_asMap(map['parsed_report'])),
    );
  }

  CustomerAnalysisResult copyWith({
    int? sessionId,
    bool clearSessionId = false,
    String? sessionCode,
    String? locationLabel,
    DateTime? analysisDate,
    String? overallSummary,
    String? generalRiskNote,
    CustomerFootSummary? leftFoot,
    CustomerFootSummary? rightFoot,
    List<CustomerAnalysisMetric>? metrics,
    List<CustomerRecommendationItem>? recommendations,
    CustomerAnalysisVisualSet? visuals,
    ParsedScanReport? parsedReport,
    bool clearParsedReport = false,
  }) {
    return CustomerAnalysisResult(
      sessionId: clearSessionId ? null : sessionId ?? this.sessionId,
      sessionCode: sessionCode ?? this.sessionCode,
      locationLabel: locationLabel ?? this.locationLabel,
      analysisDate: analysisDate ?? this.analysisDate,
      overallSummary: overallSummary ?? this.overallSummary,
      generalRiskNote: generalRiskNote ?? this.generalRiskNote,
      leftFoot: leftFoot ?? this.leftFoot,
      rightFoot: rightFoot ?? this.rightFoot,
      metrics: metrics ?? this.metrics,
      recommendations: recommendations ?? this.recommendations,
      visuals: visuals ?? this.visuals,
      parsedReport: clearParsedReport
          ? null
          : parsedReport ?? this.parsedReport,
    );
  }
}

class CustomerAnalysisVisualSet {
  final String sessionCode;

  final String? archLeftImagePath;
  final String? archRightImagePath;

  final String? archSectionLeftImagePath;
  final String? archSectionRightImagePath;

  final String? foot2dLeftImagePath;
  final String? foot2dRightImagePath;

  final String? pronatorLeftImagePath;
  final String? pronatorRightImagePath;

  final String? leftStlPath;
  final String? rightStlPath;

  const CustomerAnalysisVisualSet({
    required this.sessionCode,
    this.archLeftImagePath,
    this.archRightImagePath,
    this.archSectionLeftImagePath,
    this.archSectionRightImagePath,
    this.foot2dLeftImagePath,
    this.foot2dRightImagePath,
    this.pronatorLeftImagePath,
    this.pronatorRightImagePath,
    this.leftStlPath,
    this.rightStlPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionCode': sessionCode,
      'archLeftImagePath': archLeftImagePath,
      'archRightImagePath': archRightImagePath,
      'archSectionLeftImagePath': archSectionLeftImagePath,
      'archSectionRightImagePath': archSectionRightImagePath,
      'foot2dLeftImagePath': foot2dLeftImagePath,
      'foot2dRightImagePath': foot2dRightImagePath,
      'pronatorLeftImagePath': pronatorLeftImagePath,
      'pronatorRightImagePath': pronatorRightImagePath,
      'leftStlPath': leftStlPath,
      'rightStlPath': rightStlPath,
    };
  }

  factory CustomerAnalysisVisualSet.fromMap(Map<String, dynamic> map) {
    return CustomerAnalysisVisualSet(
      sessionCode: map['sessionCode']?.toString() ?? '',
      archLeftImagePath: _toNullableString(map['archLeftImagePath']),
      archRightImagePath: _toNullableString(map['archRightImagePath']),
      archSectionLeftImagePath: _toNullableString(
        map['archSectionLeftImagePath'],
      ),
      archSectionRightImagePath: _toNullableString(
        map['archSectionRightImagePath'],
      ),
      foot2dLeftImagePath: _toNullableString(map['foot2dLeftImagePath']),
      foot2dRightImagePath: _toNullableString(map['foot2dRightImagePath']),
      pronatorLeftImagePath: _toNullableString(map['pronatorLeftImagePath']),
      pronatorRightImagePath: _toNullableString(map['pronatorRightImagePath']),
      leftStlPath: _toNullableString(map['leftStlPath']),
      rightStlPath: _toNullableString(map['rightStlPath']),
    );
  }
}

// -----------------------------------------------------------------------------
// ParsedScanReport serialization helpers
// -----------------------------------------------------------------------------

Map<String, dynamic> _parsedScanReportToMap(ParsedScanReport report) {
  return {
    'reportNo': report.reportNo,
    'reportDate': report.reportDate,
    'reportTime': report.reportTime,
    'storeCode': report.storeCode,
    'address': report.address,
    'customerName': report.customerName,
    'gender': report.gender,
    'age': report.age,
    'phone': report.phone,

    'leftFootLength': report.leftFootLength,
    'rightFootLength': report.rightFootLength,
    'leftSoleLength': report.leftSoleLength,
    'rightSoleLength': report.rightSoleLength,
    'leftArchLength': report.leftArchLength,
    'rightArchLength': report.rightArchLength,
    'leftFirstMetaLength': report.leftFirstMetaLength,
    'rightFirstMetaLength': report.rightFirstMetaLength,
    'leftFifthMetaLength': report.leftFifthMetaLength,
    'rightFifthMetaLength': report.rightFifthMetaLength,
    'leftHalluxBumpsLength': report.leftHalluxBumpsLength,
    'rightHalluxBumpsLength': report.rightHalluxBumpsLength,
    'leftFootFlankLength': report.leftFootFlankLength,
    'rightFootFlankLength': report.rightFootFlankLength,
    'leftHeelCenterLength': report.leftHeelCenterLength,
    'rightHeelCenterLength': report.rightHeelCenterLength,
    'leftHeelMarginLength': report.leftHeelMarginLength,
    'rightHeelMarginLength': report.rightHeelMarginLength,

    'leftFootWidth': report.leftFootWidth,
    'rightFootWidth': report.rightFootWidth,
    'leftSlantWidth': report.leftSlantWidth,
    'rightSlantWidth': report.rightSlantWidth,
    'leftToeWidth': report.leftToeWidth,
    'rightToeWidth': report.rightToeWidth,
    'leftArchOutsideWidth': report.leftArchOutsideWidth,
    'rightArchOutsideWidth': report.rightArchOutsideWidth,
    'leftFootFlankWidth': report.leftFootFlankWidth,
    'rightFootFlankWidth': report.rightFootFlankWidth,
    'leftHeelCenterWidth': report.leftHeelCenterWidth,
    'rightHeelCenterWidth': report.rightHeelCenterWidth,
    'leftTotalHeelWidth': report.leftTotalHeelWidth,
    'rightTotalHeelWidth': report.rightTotalHeelWidth,

    'leftArchHeight': report.leftArchHeight,
    'rightArchHeight': report.rightArchHeight,
    'leftFirstMetaJointHeight': report.leftFirstMetaJointHeight,
    'rightFirstMetaJointHeight': report.rightFirstMetaJointHeight,
    'leftHeelProtrusionHeight': report.leftHeelProtrusionHeight,
    'rightHeelProtrusionHeight': report.rightHeelProtrusionHeight,

    'leftHalluxAngle': report.leftHalluxAngle,
    'rightHalluxAngle': report.rightHalluxAngle,
    'leftPronatorAngle': report.leftPronatorAngle,
    'rightPronatorAngle': report.rightPronatorAngle,
    'leftKneeAngle': report.leftKneeAngle,
    'rightKneeAngle': report.rightKneeAngle,

    'leftShoeSize': report.leftShoeSize,
    'rightShoeSize': report.rightShoeSize,
    'leftInsoleRecommendation': report.leftInsoleRecommendation,
    'rightInsoleRecommendation': report.rightInsoleRecommendation,

    'leftArchType': report.leftArchType,
    'rightArchType': report.rightArchType,
    'leftArchIndex': report.leftArchIndex,
    'rightArchIndex': report.rightArchIndex,
    'leftArchWidthIndex': report.leftArchWidthIndex,
    'rightArchWidthIndex': report.rightArchWidthIndex,

    'leftHalluxType': report.leftHalluxType,
    'rightHalluxType': report.rightHalluxType,
    'leftHeelType': report.leftHeelType,
    'rightHeelType': report.rightHeelType,
    'leftKneeType': report.leftKneeType,
    'rightKneeType': report.rightKneeType,

    'recommendationText': report.recommendationText,
    'rawText': report.rawText,
  };
}

ParsedScanReport _parsedScanReportFromMap(Map<String, dynamic> map) {
  return ParsedScanReport(
    reportNo: _toNullableString(map['reportNo']),
    reportDate: _toNullableString(map['reportDate']),
    reportTime: _toNullableString(map['reportTime']),
    storeCode: _toNullableString(map['storeCode']),
    address: _toNullableString(map['address']),
    customerName: _toNullableString(map['customerName']),
    gender: _toNullableString(map['gender']),
    age: _toNullableString(map['age']),
    phone: _toNullableString(map['phone']),

    leftFootLength: _toNullableDouble(map['leftFootLength']),
    rightFootLength: _toNullableDouble(map['rightFootLength']),
    leftSoleLength: _toNullableDouble(map['leftSoleLength']),
    rightSoleLength: _toNullableDouble(map['rightSoleLength']),
    leftArchLength: _toNullableDouble(map['leftArchLength']),
    rightArchLength: _toNullableDouble(map['rightArchLength']),
    leftFirstMetaLength: _toNullableDouble(map['leftFirstMetaLength']),
    rightFirstMetaLength: _toNullableDouble(map['rightFirstMetaLength']),
    leftFifthMetaLength: _toNullableDouble(map['leftFifthMetaLength']),
    rightFifthMetaLength: _toNullableDouble(map['rightFifthMetaLength']),
    leftHalluxBumpsLength: _toNullableDouble(map['leftHalluxBumpsLength']),
    rightHalluxBumpsLength: _toNullableDouble(map['rightHalluxBumpsLength']),
    leftFootFlankLength: _toNullableDouble(map['leftFootFlankLength']),
    rightFootFlankLength: _toNullableDouble(map['rightFootFlankLength']),
    leftHeelCenterLength: _toNullableDouble(map['leftHeelCenterLength']),
    rightHeelCenterLength: _toNullableDouble(map['rightHeelCenterLength']),
    leftHeelMarginLength: _toNullableDouble(map['leftHeelMarginLength']),
    rightHeelMarginLength: _toNullableDouble(map['rightHeelMarginLength']),

    leftFootWidth: _toNullableDouble(map['leftFootWidth']),
    rightFootWidth: _toNullableDouble(map['rightFootWidth']),
    leftSlantWidth: _toNullableDouble(map['leftSlantWidth']),
    rightSlantWidth: _toNullableDouble(map['rightSlantWidth']),
    leftToeWidth: _toNullableDouble(map['leftToeWidth']),
    rightToeWidth: _toNullableDouble(map['rightToeWidth']),
    leftArchOutsideWidth: _toNullableDouble(map['leftArchOutsideWidth']),
    rightArchOutsideWidth: _toNullableDouble(map['rightArchOutsideWidth']),
    leftFootFlankWidth: _toNullableDouble(map['leftFootFlankWidth']),
    rightFootFlankWidth: _toNullableDouble(map['rightFootFlankWidth']),
    leftHeelCenterWidth: _toNullableDouble(map['leftHeelCenterWidth']),
    rightHeelCenterWidth: _toNullableDouble(map['rightHeelCenterWidth']),
    leftTotalHeelWidth: _toNullableDouble(map['leftTotalHeelWidth']),
    rightTotalHeelWidth: _toNullableDouble(map['rightTotalHeelWidth']),

    leftArchHeight: _toNullableDouble(map['leftArchHeight']),
    rightArchHeight: _toNullableDouble(map['rightArchHeight']),
    leftFirstMetaJointHeight: _toNullableDouble(
      map['leftFirstMetaJointHeight'],
    ),
    rightFirstMetaJointHeight: _toNullableDouble(
      map['rightFirstMetaJointHeight'],
    ),
    leftHeelProtrusionHeight: _toNullableDouble(
      map['leftHeelProtrusionHeight'],
    ),
    rightHeelProtrusionHeight: _toNullableDouble(
      map['rightHeelProtrusionHeight'],
    ),

    leftHalluxAngle: _toNullableDouble(map['leftHalluxAngle']),
    rightHalluxAngle: _toNullableDouble(map['rightHalluxAngle']),
    leftPronatorAngle: _toNullableDouble(map['leftPronatorAngle']),
    rightPronatorAngle: _toNullableDouble(map['rightPronatorAngle']),
    leftKneeAngle: _toNullableDouble(map['leftKneeAngle']),
    rightKneeAngle: _toNullableDouble(map['rightKneeAngle']),

    leftShoeSize: _toNullableString(map['leftShoeSize']),
    rightShoeSize: _toNullableString(map['rightShoeSize']),
    leftInsoleRecommendation: _toNullableString(
      map['leftInsoleRecommendation'],
    ),
    rightInsoleRecommendation: _toNullableString(
      map['rightInsoleRecommendation'],
    ),

    leftArchType: _toNullableString(map['leftArchType']),
    rightArchType: _toNullableString(map['rightArchType']),
    leftArchIndex: _toNullableDouble(map['leftArchIndex']),
    rightArchIndex: _toNullableDouble(map['rightArchIndex']),
    leftArchWidthIndex: _toNullableDouble(map['leftArchWidthIndex']),
    rightArchWidthIndex: _toNullableDouble(map['rightArchWidthIndex']),

    leftHalluxType: _toNullableString(map['leftHalluxType']),
    rightHalluxType: _toNullableString(map['rightHalluxType']),
    leftHeelType: _toNullableString(map['leftHeelType']),
    rightHeelType: _toNullableString(map['rightHeelType']),
    leftKneeType: _toNullableString(map['leftKneeType']),
    rightKneeType: _toNullableString(map['rightKneeType']),

    recommendationText: _toNullableString(map['recommendationText']),
    rawText: _toNullableString(map['rawText']),
  );
}

// -----------------------------------------------------------------------------
// Safe conversion helpers
// -----------------------------------------------------------------------------

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return <dynamic>[];
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;

  return int.tryParse(normalized);
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();

  return double.tryParse(value.toString().trim().replaceAll(',', '.')) ?? 0.0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();

  final normalized = value.toString().trim().replaceAll(',', '.');

  if (normalized.isEmpty) return null;

  return double.tryParse(normalized);
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;

  final normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime _toDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;

  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
