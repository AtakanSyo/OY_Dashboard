class OrderOperationStateModel {
  final int? id;
  final int orderId;
  final int? sessionId;
  final int? patientId;
  final int? assignedUserId;

  final String boardColumnCode;

  final bool designCompleted;
  final bool productionStarted;
  final bool productionCompleted;

  final bool qcDesignMatch;
  final bool qcMeasurementDone;
  final bool qcSurfaceChecked;
  final bool qcReadyForDelivery;
  final String? qcNote;

  final bool packagingCompleted;
  final String? shippingTrackingNo;

  final bool orderClosed;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderOperationStateModel({
    this.id,
    required this.orderId,
    this.sessionId,
    this.patientId,
    this.assignedUserId,
    this.boardColumnCode = 'design_waiting',
    this.designCompleted = false,
    this.productionStarted = false,
    this.productionCompleted = false,
    this.qcDesignMatch = false,
    this.qcMeasurementDone = false,
    this.qcSurfaceChecked = false,
    this.qcReadyForDelivery = false,
    this.qcNote,
    this.packagingCompleted = false,
    this.shippingTrackingNo,
    this.orderClosed = false,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderOperationStateModel.empty({
    required int orderId,
    int? sessionId,
    int? patientId,
    int? assignedUserId,
  }) {
    return OrderOperationStateModel(
      orderId: orderId,
      sessionId: sessionId,
      patientId: patientId,
      assignedUserId: assignedUserId,
      boardColumnCode: 'design_waiting',
    );
  }

  factory OrderOperationStateModel.fromMap(Map<String, dynamic> map) {
    return OrderOperationStateModel(
      id: _toInt(map['id']),
      orderId: _toInt(map['order_id']) ?? 0,
      sessionId: _toInt(map['session_id']),
      patientId: _toInt(map['patient_id']),
      assignedUserId: _toInt(map['assigned_user_id']),
      boardColumnCode:
          map['board_column_code']?.toString() ?? 'design_waiting',
      designCompleted: map['design_completed'] as bool? ?? false,
      productionStarted: map['production_started'] as bool? ?? false,
      productionCompleted: map['production_completed'] as bool? ?? false,
      qcDesignMatch: map['qc_design_match'] as bool? ?? false,
      qcMeasurementDone: map['qc_measurement_done'] as bool? ?? false,
      qcSurfaceChecked: map['qc_surface_checked'] as bool? ?? false,
      qcReadyForDelivery: map['qc_ready_for_delivery'] as bool? ?? false,
      qcNote: map['qc_note']?.toString(),
      packagingCompleted: map['packaging_completed'] as bool? ?? false,
      shippingTrackingNo: map['shipping_tracking_no']?.toString(),
      orderClosed: map['order_closed'] as bool? ?? false,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  OrderOperationStateModel copyWith({
    int? id,
    int? orderId,
    int? sessionId,
    int? patientId,
    int? assignedUserId,
    String? boardColumnCode,
    bool? designCompleted,
    bool? productionStarted,
    bool? productionCompleted,
    bool? qcDesignMatch,
    bool? qcMeasurementDone,
    bool? qcSurfaceChecked,
    bool? qcReadyForDelivery,
    String? qcNote,
    bool? packagingCompleted,
    String? shippingTrackingNo,
    bool? orderClosed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderOperationStateModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      sessionId: sessionId ?? this.sessionId,
      patientId: patientId ?? this.patientId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      boardColumnCode: boardColumnCode ?? this.boardColumnCode,
      designCompleted: designCompleted ?? this.designCompleted,
      productionStarted: productionStarted ?? this.productionStarted,
      productionCompleted: productionCompleted ?? this.productionCompleted,
      qcDesignMatch: qcDesignMatch ?? this.qcDesignMatch,
      qcMeasurementDone: qcMeasurementDone ?? this.qcMeasurementDone,
      qcSurfaceChecked: qcSurfaceChecked ?? this.qcSurfaceChecked,
      qcReadyForDelivery: qcReadyForDelivery ?? this.qcReadyForDelivery,
      qcNote: qcNote ?? this.qcNote,
      packagingCompleted: packagingCompleted ?? this.packagingCompleted,
      shippingTrackingNo: shippingTrackingNo ?? this.shippingTrackingNo,
      orderClosed: orderClosed ?? this.orderClosed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toUpsertMap() {
    return {
      'order_id': orderId,
      'session_id': sessionId,
      'patient_id': patientId,
      'assigned_user_id': assignedUserId,
      'board_column_code': boardColumnCode,
      'design_completed': designCompleted,
      'production_started': productionStarted,
      'production_completed': productionCompleted,
      'qc_design_match': qcDesignMatch,
      'qc_measurement_done': qcMeasurementDone,
      'qc_surface_checked': qcSurfaceChecked,
      'qc_ready_for_delivery': qcReadyForDelivery,
      'qc_note': qcNote,
      'packaging_completed': packagingCompleted,
      'shipping_tracking_no': shippingTrackingNo,
      'order_closed': orderClosed,
    };
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