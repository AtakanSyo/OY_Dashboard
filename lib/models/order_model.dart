class OrderModel {
  final int? orderId;
  final int sessionId;
  final int patientId;
  final int clinicId;
  final int expertUserId;
  final int? assignedOptityouUserId;

  final String orderNo;
  final String productType;
  final String orderStatus;
  final String currencyCode;

  final double grossAmount;
  final double discountAmount;
  final double netAmount;

  final DateTime orderedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const OrderModel({
    this.orderId,
    required this.sessionId,
    required this.patientId,
    required this.clinicId,
    required this.expertUserId,
    this.assignedOptityouUserId,
    required this.orderNo,
    required this.productType,
    required this.orderStatus,
    this.currencyCode = 'TRY',
    this.grossAmount = 0,
    this.discountAmount = 0,
    this.netAmount = 0,
    required this.orderedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  bool get isPending => orderStatus == OrderStatuses.pending;
  bool get isDesigning => orderStatus == OrderStatuses.designing;
  bool get isProduction => orderStatus == OrderStatuses.production;
  bool get isShipped => orderStatus == OrderStatuses.shipped;
  bool get isDelivered => orderStatus == OrderStatuses.delivered;
  bool get isCancelled => orderStatus == OrderStatuses.cancelled;

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['order_id'] as int?,
      sessionId: map['session_id'] as int? ?? 0,
      patientId: map['patient_id'] as int? ?? 0,
      clinicId: map['clinic_id'] as int? ?? 0,
      expertUserId: map['expert_user_id'] as int? ?? 0,
      assignedOptityouUserId: map['assigned_optityou_user_id'] as int?,
      orderNo: map['order_no'] as String? ?? '',
      productType: map['product_type'] as String? ?? '',
      orderStatus: map['order_status'] as String? ?? OrderStatuses.pending,
      currencyCode: map['currency_code'] as String? ?? 'TRY',
      grossAmount: _toDouble(map['gross_amount']),
      discountAmount: _toDouble(map['discount_amount']),
      netAmount: _toDouble(map['net_amount']),
      orderedAt: _parseDate(map['ordered_at']) ?? DateTime.now(),
      shippedAt: _parseDate(map['shipped_at']),
      deliveredAt: _parseDate(map['delivered_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'session_id': sessionId,
      'patient_id': patientId,
      'clinic_id': clinicId,
      'expert_user_id': expertUserId,
      'assigned_optityou_user_id': assignedOptityouUserId,
      'order_no': orderNo,
      'product_type': productType,
      'order_status': orderStatus,
      'currency_code': currencyCode,
      'gross_amount': grossAmount,
      'discount_amount': discountAmount,
      'net_amount': netAmount,
      'ordered_at': orderedAt.toIso8601String(),
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class OrderStatuses {
  static const String pending = 'pending';
  static const String designing = 'designing';
  static const String production = 'production';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static const List<String> values = [
    pending,
    designing,
    production,
    shipped,
    delivered,
    cancelled,
  ];
}