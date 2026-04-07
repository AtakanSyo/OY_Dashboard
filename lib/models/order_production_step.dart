class OrderProductionStep {
  final int? stepId;
  final int orderId;
  final String stepCode;
  final String stepName;
  final String stepDescription;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedByUserName;
  final String? note;
  final int sortOrder;

  const OrderProductionStep({
    this.stepId,
    required this.orderId,
    required this.stepCode,
    required this.stepName,
    required this.stepDescription,
    required this.isCompleted,
    this.completedAt,
    this.completedByUserName,
    this.note,
    required this.sortOrder,
  });

  OrderProductionStep copyWith({
    int? stepId,
    int? orderId,
    String? stepCode,
    String? stepName,
    String? stepDescription,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedByUserName,
    String? note,
    int? sortOrder,
  }) {
    return OrderProductionStep(
      stepId: stepId ?? this.stepId,
      orderId: orderId ?? this.orderId,
      stepCode: stepCode ?? this.stepCode,
      stepName: stepName ?? this.stepName,
      stepDescription: stepDescription ?? this.stepDescription,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedByUserName: completedByUserName ?? this.completedByUserName,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}