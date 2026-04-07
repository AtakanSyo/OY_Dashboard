class CustomerHomeData {
  final String patientName;
  final DateTime lastAnalysisDate;
  final String summary;
  final String recommendationNote;

  final String orderNo;
  final String orderStatus;
  final String productName;
  final DateTime? estimatedDelivery;

  final String suggestedProductName;
  final String suggestedProductDescription;
  final double suggestedProductPrice;

  const CustomerHomeData({
    required this.patientName,
    required this.lastAnalysisDate,
    required this.summary,
    required this.recommendationNote,
    required this.orderNo,
    required this.orderStatus,
    required this.productName,
    required this.estimatedDelivery,
    required this.suggestedProductName,
    required this.suggestedProductDescription,
    required this.suggestedProductPrice,
  });
}