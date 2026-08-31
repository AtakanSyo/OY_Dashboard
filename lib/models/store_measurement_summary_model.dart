class StoreMeasurementSummary {
  final int? sessionId;
  final String sessionCode;
  final DateTime analysisDate;
  final String locationLabel;
  final String shortMessage;

  const StoreMeasurementSummary({
    this.sessionId,
    required this.sessionCode,
    required this.analysisDate,
    required this.locationLabel,
    required this.shortMessage,
  });

  String get formattedDate {
    return '${analysisDate.day.toString().padLeft(2, '0')}.'
        '${analysisDate.month.toString().padLeft(2, '0')}.'
        '${analysisDate.year}';
  }
}
