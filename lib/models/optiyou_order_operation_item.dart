import 'package:oy_site/models/order_model.dart';

class OptiYouOrderOperationItem {
  final OrderModel order;
  final String expertName;
  final String clinicName;
  final bool hasMissingData;
  final String missingDataSummary;
  final String priorityLabel;

  const OptiYouOrderOperationItem({
    required this.order,
    required this.expertName,
    required this.clinicName,
    required this.hasMissingData,
    required this.missingDataSummary,
    required this.priorityLabel,
  });

  bool get isHighPriority => priorityLabel.toLowerCase() == 'yüksek';
  bool get isMediumPriority => priorityLabel.toLowerCase() == 'orta';
  bool get isLowPriority => priorityLabel.toLowerCase() == 'düşük';
}