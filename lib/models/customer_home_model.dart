class CustomerHomeData {
  final String patientName;
  final DateTime lastAnalysisDate;
  final String analysisStatus;
  final String summary;
  final List<String> analysisHighlights;
  final String recommendationNote;
  final DateTime recommendationUpdatedAt;

  final String orderNo;
  final String orderStatus;
  final int orderProgressStep;
  final String productName;
  final DateTime? estimatedDelivery;

  final String suggestedProductName;
  final String suggestedProductDescription;
  final String suggestedProductReason;
  final double suggestedProductPrice;
  final String suggestedProductImagePath;

  const CustomerHomeData({
    required this.patientName,
    required this.lastAnalysisDate,
    required this.analysisStatus,
    required this.summary,
    required this.analysisHighlights,
    required this.recommendationNote,
    required this.recommendationUpdatedAt,
    required this.orderNo,
    required this.orderStatus,
    required this.orderProgressStep,
    required this.productName,
    required this.estimatedDelivery,
    required this.suggestedProductName,
    required this.suggestedProductDescription,
    required this.suggestedProductReason,
    required this.suggestedProductPrice,
    required this.suggestedProductImagePath,
  });
}
