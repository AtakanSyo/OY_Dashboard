class OptiYouOperationColumn {
  final String code;
  final String title;

  const OptiYouOperationColumn({
    required this.code,
    required this.title,
  });
}

class OptiYouOperationColumnCodes {
  static const String designWaiting = 'design_waiting';
  static const String designing = 'designing';
  static const String productionWaiting = 'production_waiting';
  static const String production = 'production';
  static const String qualityControl = 'quality_control';
  static const String packagingShipping = 'packaging_shipping';
  static const String completed = 'completed';

  static const List<OptiYouOperationColumn> all = [
    OptiYouOperationColumn(
      code: designWaiting,
      title: 'Tasarım Bekliyor',
    ),
    OptiYouOperationColumn(
      code: designing,
      title: 'Tasarımda',
    ),
    OptiYouOperationColumn(
      code: productionWaiting,
      title: 'Üretim Bekliyor',
    ),
    OptiYouOperationColumn(
      code: production,
      title: 'Üretimde',
    ),
    OptiYouOperationColumn(
      code: qualityControl,
      title: 'Kalite Kontrol',
    ),
    OptiYouOperationColumn(
      code: packagingShipping,
      title: 'Paketleme / Kargo',
    ),
    OptiYouOperationColumn(
      code: completed,
      title: 'Tamamlandı',
    ),
  ];
}