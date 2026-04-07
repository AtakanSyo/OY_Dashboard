import 'package:oy_site/models/order_model.dart';

class OptiYouOrderOperationItem {
  final OrderModel order;
  final String expertName;
  final String clinicName;
  final bool hasMissingData;
  final String missingDataSummary;
  final String priorityLabel;
  final String currentColumnCode;

  const OptiYouOrderOperationItem({
    required this.order,
    required this.expertName,
    required this.clinicName,
    required this.hasMissingData,
    required this.missingDataSummary,
    required this.priorityLabel,
    required this.currentColumnCode,
  });

  bool get isHighPriority => priorityLabel.toLowerCase() == 'yüksek';
  bool get isMediumPriority => priorityLabel.toLowerCase() == 'orta';
  bool get isLowPriority => priorityLabel.toLowerCase() == 'düşük';

  OptiYouOrderOperationItem copyWith({
    OrderModel? order,
    String? expertName,
    String? clinicName,
    bool? hasMissingData,
    String? missingDataSummary,
    String? priorityLabel,
    String? currentColumnCode,
  }) {
    return OptiYouOrderOperationItem(
      order: order ?? this.order,
      expertName: expertName ?? this.expertName,
      clinicName: clinicName ?? this.clinicName,
      hasMissingData: hasMissingData ?? this.hasMissingData,
      missingDataSummary: missingDataSummary ?? this.missingDataSummary,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      currentColumnCode: currentColumnCode ?? this.currentColumnCode,
    );
  }
}