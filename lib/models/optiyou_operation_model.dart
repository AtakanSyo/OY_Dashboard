class OptiYouOperationColumn {
  final String code;
  final String title;
  final int sortOrder;

  const OptiYouOperationColumn({
    required this.code,
    required this.title,
    required this.sortOrder,
  });
}

class OptiYouOperationColumnCodes {
  static const String orderReceived = 'order_received';
  static const String infoMailSent = 'info_mail_sent';
  static const String kvkkShared = 'kvkk_shared';
  static const String technicalReview = 'technical_review';
  static const String designWaiting = 'design_waiting';
  static const String designCompleted = 'design_completed';
  static const String stlUploaded = 'stl_uploaded';
  static const String productionStarted = 'production_started';
  static const String productionCompleted = 'production_completed';
  static const String qualityControl = 'quality_control';
  static const String packaging = 'packaging';
  static const String shipped = 'shipped';
  static const String postInfoMailSent = 'post_info_mail_sent';
  static const String satisfactionSurveySent = 'satisfaction_survey_sent';
  static const String closed = 'closed';

  static const List<OptiYouOperationColumn> all = [
    OptiYouOperationColumn(
      code: orderReceived,
      title: 'Sipariş Alındı',
      sortOrder: 1,
    ),
    OptiYouOperationColumn(
      code: infoMailSent,
      title: 'Bilgi Maili Atıldı',
      sortOrder: 2,
    ),
    OptiYouOperationColumn(
      code: kvkkShared,
      title: 'KVKK Paylaşıldı',
      sortOrder: 3,
    ),
    OptiYouOperationColumn(
      code: technicalReview,
      title: 'Teknik Kontrol',
      sortOrder: 4,
    ),
    OptiYouOperationColumn(
      code: designWaiting,
      title: 'Tasarım Bekleniyor',
      sortOrder: 5,
    ),
    OptiYouOperationColumn(
      code: designCompleted,
      title: 'Tasarım Tamamlandı',
      sortOrder: 6,
    ),
    OptiYouOperationColumn(
      code: stlUploaded,
      title: 'STL Yüklendi',
      sortOrder: 7,
    ),
    OptiYouOperationColumn(
      code: productionStarted,
      title: 'Üretimde',
      sortOrder: 8,
    ),
    OptiYouOperationColumn(
      code: productionCompleted,
      title: 'Üretim Tamamlandı',
      sortOrder: 9,
    ),
    OptiYouOperationColumn(
      code: qualityControl,
      title: 'Kalite Kontrol',
      sortOrder: 10,
    ),
    OptiYouOperationColumn(
      code: packaging,
      title: 'Paketleme',
      sortOrder: 11,
    ),
    OptiYouOperationColumn(
      code: shipped,
      title: 'Kargoya Verildi',
      sortOrder: 12,
    ),
    OptiYouOperationColumn(
      code: postInfoMailSent,
      title: 'Sipariş Sonrası Mail',
      sortOrder: 13,
    ),
    OptiYouOperationColumn(
      code: satisfactionSurveySent,
      title: 'Memnuniyet Anketi',
      sortOrder: 14,
    ),
    OptiYouOperationColumn(
      code: closed,
      title: 'Kapandı',
      sortOrder: 15,
    ),
  ];
}