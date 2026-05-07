import 'package:oy_site/models/parsed_scan_report.dart';

class SessionScanReportModel {
  final int? id;
  final int sessionId;
  final int? patientId;
  final int? expertUserId;

  final String? reportNo;
  final String? reportDate;
  final String? reportTime;

  final Map<String, dynamic> parsedReportJson;
  final String? rawText;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SessionScanReportModel({
    this.id,
    required this.sessionId,
    this.patientId,
    this.expertUserId,
    this.reportNo,
    this.reportDate,
    this.reportTime,
    required this.parsedReportJson,
    this.rawText,
    this.createdAt,
    this.updatedAt,
  });

  factory SessionScanReportModel.fromParsedReport({
    required int sessionId,
    required int patientId,
    required int expertUserId,
    required ParsedScanReport report,
  }) {
    return SessionScanReportModel(
      sessionId: sessionId,
      patientId: patientId,
      expertUserId: expertUserId,
      reportNo: report.reportNo,
      reportDate: report.reportDate,
      reportTime: report.reportTime,
      parsedReportJson: _parsedScanReportToMap(report),
      rawText: report.rawText,
    );
  }

  factory SessionScanReportModel.fromMap(Map<String, dynamic> map) {
    return SessionScanReportModel(
      id: _toInt(map['id']),
      sessionId: _toInt(map['session_id']) ?? 0,
      patientId: _toInt(map['patient_id']),
      expertUserId: _toInt(map['expert_user_id']),
      reportNo: map['report_no']?.toString(),
      reportDate: map['report_date']?.toString(),
      reportTime: map['report_time']?.toString(),
      parsedReportJson: _toMap(map['parsed_report_json']) ?? {},
      rawText: map['raw_text']?.toString(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'session_id': sessionId,
      'patient_id': patientId,
      'expert_user_id': expertUserId,
      'report_no': reportNo,
      'report_date': reportDate,
      'report_time': reportTime,
      'parsed_report_json': parsedReportJson,
      'raw_text': rawText,
    };
  }

  static Map<String, dynamic> _parsedScanReportToMap(
    ParsedScanReport report,
  ) {
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
      'leftFootWidth': report.leftFootWidth,
      'rightFootWidth': report.rightFootWidth,
      'leftArchHeight': report.leftArchHeight,
      'rightArchHeight': report.rightArchHeight,

      'leftArchType': report.leftArchType,
      'rightArchType': report.rightArchType,
      'leftArchIndex': report.leftArchIndex,
      'rightArchIndex': report.rightArchIndex,
      'leftArchWidthIndex': report.leftArchWidthIndex,
      'rightArchWidthIndex': report.rightArchWidthIndex,

      'leftHalluxAngle': report.leftHalluxAngle,
      'rightHalluxAngle': report.rightHalluxAngle,
      'leftHalluxType': report.leftHalluxType,
      'rightHalluxType': report.rightHalluxType,

      'leftPronatorAngle': report.leftPronatorAngle,
      'rightPronatorAngle': report.rightPronatorAngle,
      'leftHeelType': report.leftHeelType,
      'rightHeelType': report.rightHeelType,
      'leftKneeAngle': report.leftKneeAngle,
      'rightKneeAngle': report.rightKneeAngle,
      'leftKneeType': report.leftKneeType,
      'rightKneeType': report.rightKneeType,

      'leftShoeSize': report.leftShoeSize,
      'rightShoeSize': report.rightShoeSize,
      'leftInsoleRecommendation': report.leftInsoleRecommendation,
      'rightInsoleRecommendation': report.rightInsoleRecommendation,

      'recommendationText': report.recommendationText,
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}