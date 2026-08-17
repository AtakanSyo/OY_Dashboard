class CustomerHomeData {
  final String patientName;
  final CustomerHomeAssessmentData? latestAssessment;
  final CustomerHomeOrderData? activeOrder;
  final CustomerHomeProductData? suggestedProduct;
  final bool analysisLoadFailed;
  final bool ordersLoadFailed;

  const CustomerHomeData({
    required this.patientName,
    this.latestAssessment,
    this.activeOrder,
    this.suggestedProduct,
    this.analysisLoadFailed = false,
    this.ordersLoadFailed = false,
  });
}

class CustomerHomeAssessmentData {
  final String sessionCode;
  final DateTime analysisDate;
  final String summary;
  final List<String> highlights;
  final String? recommendationTitle;
  final String? recommendationNote;

  const CustomerHomeAssessmentData({
    required this.sessionCode,
    required this.analysisDate,
    required this.summary,
    this.highlights = const [],
    this.recommendationTitle,
    this.recommendationNote,
  });
}

class CustomerHomeOrderData {
  final String orderNo;
  final String orderStatus;
  final String productType;
  final DateTime orderedAt;
  final int progressStep;

  const CustomerHomeOrderData({
    required this.orderNo,
    required this.orderStatus,
    required this.productType,
    required this.orderedAt,
    required this.progressStep,
  });
}

class CustomerHomeProductData {
  final String name;
  final String description;
  final String reason;
  final double price;
  final String imagePath;

  const CustomerHomeProductData({
    required this.name,
    required this.description,
    required this.reason,
    required this.price,
    required this.imagePath,
  });
}
