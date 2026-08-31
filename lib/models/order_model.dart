class OrderModel {
  final int? orderId;
  final int sessionId;
  final int patientId;
  final int clinicId;
  final int expertUserId;
  final int? assignedOptityouUserId;

  final int? deliveryAddressId;
  final Map<String, dynamic>? deliveryAddressSnapshot;

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
    this.deliveryAddressId,
    this.deliveryAddressSnapshot,
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

  OrderModel copyWith({
    int? orderId,
    int? sessionId,
    int? patientId,
    int? clinicId,
    int? expertUserId,
    int? assignedOptityouUserId,
    int? deliveryAddressId,
    Map<String, dynamic>? deliveryAddressSnapshot,
    String? orderNo,
    String? productType,
    String? orderStatus,
    String? currencyCode,
    double? grossAmount,
    double? discountAmount,
    double? netAmount,
    DateTime? orderedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      sessionId: sessionId ?? this.sessionId,
      patientId: patientId ?? this.patientId,
      clinicId: clinicId ?? this.clinicId,
      expertUserId: expertUserId ?? this.expertUserId,
      assignedOptityouUserId:
          assignedOptityouUserId ?? this.assignedOptityouUserId,
      deliveryAddressId: deliveryAddressId ?? this.deliveryAddressId,
      deliveryAddressSnapshot:
          deliveryAddressSnapshot ?? this.deliveryAddressSnapshot,
      orderNo: orderNo ?? this.orderNo,
      productType: productType ?? this.productType,
      orderStatus: orderStatus ?? this.orderStatus,
      currencyCode: currencyCode ?? this.currencyCode,
      grossAmount: grossAmount ?? this.grossAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      netAmount: netAmount ?? this.netAmount,
      orderedAt: orderedAt ?? this.orderedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: _toInt(map['id'] ?? map['order_id']),
      sessionId: _toInt(map['session_id']) ?? 0,
      patientId: _toInt(map['patient_id']) ?? 0,
      clinicId: _toInt(map['clinic_id']) ?? 0,
      expertUserId: _toInt(map['expert_user_id']) ?? 0,
      assignedOptityouUserId: _toInt(map['assigned_optityou_user_id']),
      deliveryAddressId: _toInt(map['delivery_address_id']),
      deliveryAddressSnapshot: _toMap(map['delivery_address_snapshot']),
      orderNo: map['order_no']?.toString() ?? '',
      productType: map['product_type']?.toString() ?? '',
      orderStatus: map['order_status']?.toString() ?? OrderStatuses.pending,
      currencyCode: map['currency_code']?.toString() ?? 'TRY',
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
      if (orderId != null) 'id': orderId,
      'session_id': sessionId,
      'patient_id': patientId,
      'clinic_id': clinicId,
      'expert_user_id': expertUserId,
      'assigned_optityou_user_id': assignedOptityouUserId,
      'delivery_address_id': deliveryAddressId,
      'delivery_address_snapshot': deliveryAddressSnapshot,
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

  Map<String, dynamic> toInsertMap() {
    return {
      'session_id': sessionId,
      'patient_id': patientId,
      'clinic_id': clinicId,
      'expert_user_id': expertUserId,
      'assigned_optityou_user_id': assignedOptityouUserId,
      'delivery_address_id': deliveryAddressId,
      'delivery_address_snapshot': deliveryAddressSnapshot,
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

  Map<String, dynamic> toUpdateMap() {
    return {
      'assigned_optityou_user_id': assignedOptityouUserId,
      'delivery_address_id': deliveryAddressId,
      'delivery_address_snapshot': deliveryAddressSnapshot,
      'product_type': productType,
      'order_status': orderStatus,
      'currency_code': currencyCode,
      'gross_amount': grossAmount,
      'discount_amount': discountAmount,
      'net_amount': netAmount,
      'shipped_at': shippedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
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