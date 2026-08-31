import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/analysis/models/plantar_pressure_summary.dart';

class MetricsEngine {
  static List<CustomerAnalysisMetric> build({
    required ParsedScanReport report,
    required PlantarPressureSummary pressure,
  }) {
    final loadDiff =
        (pressure.leftLoadPercentage - pressure.rightLoadPercentage).abs();

    return [
      CustomerAnalysisMetric(
        label: 'Sol / Sağ Denge',
        value:
            '%${pressure.leftLoadPercentage.toStringAsFixed(0)} / %${pressure.rightLoadPercentage.toStringAsFixed(0)}',
        description: _buildBalanceDescription(loadDiff),
      ),
      CustomerAnalysisMetric(
        label: 'Maksimum Basınç Bölgesi',
        value: pressure.peakPressureRegion,
        description:
            'En yüksek basınç ${pressure.peakPressureRegion} bölgesinde görülmektedir.',
      ),
      CustomerAnalysisMetric(
        label: 'Ark Desteği İhtiyacı',
        value: _buildOverallArchNeed(report),
        description:
            'Kemer yapısı ve ark tipi bilgilerine göre destek ihtiyacı değerlendirilmiştir.',
      ),
      CustomerAnalysisMetric(
        label: 'Gün Sonu Yorgunluk Riski',
        value: _buildFatigueRisk(report, pressure),
        description:
            'Basınç dağılımı, pronasyon ve kemer desteği ihtiyacına göre tahmini risk oluşturulmuştur.',
      ),
      CustomerAnalysisMetric(
        label: 'Pronasyon Durumu',
        value: _buildPronationStatus(report),
        description:
            'Sol ve sağ ayak pronasyon açıları birlikte değerlendirilmiştir.',
      ),
      CustomerAnalysisMetric(
        label: 'Halluks Durumu',
        value: _buildHalluxStatus(report),
        description:
            'Halluks açısı ve halluks tipi bilgileri birlikte değerlendirilmiştir.',
      ),
    ];
  }

  static String _buildBalanceDescription(double diff) {
    if (diff >= 12) {
      return 'Sol ve sağ ayak yük dağılımı arasında belirgin fark bulunmaktadır.';
    }
    if (diff >= 6) {
      return 'Sol ve sağ ayak yük dağılımı arasında hafif fark bulunmaktadır.';
    }
    return 'Sol ve sağ ayak yük dağılımı dengeli görünmektedir.';
  }

  static String _buildOverallArchNeed(ParsedScanReport report) {
    final leftNeed = _archNeedLevel(report.leftArchType);
    final rightNeed = _archNeedLevel(report.rightArchType);

    final maxNeed = leftNeed > rightNeed ? leftNeed : rightNeed;

    if (maxNeed >= 3) return 'Yüksek';
    if (maxNeed == 2) return 'Orta';
    if (maxNeed == 1) return 'Düşük';
    return 'Belirlenemedi';
  }

  static int _archNeedLevel(String? archType) {
    final normalized = archType?.toLowerCase().trim();

    if (normalized == null || normalized.isEmpty) return 0;

    if (normalized.contains('flat') ||
        normalized.contains('düz') ||
        normalized.contains('low') ||
        normalized.contains('pes planus')) {
      return 3;
    }

    if (normalized.contains('high') ||
        normalized.contains('yüksek') ||
        normalized.contains('pes cavus')) {
      return 2;
    }

    if (normalized.contains('normal') || normalized.contains('neutral')) {
      return 1;
    }

    return 1;
  }

  static String _buildFatigueRisk(
    ParsedScanReport report,
    PlantarPressureSummary pressure,
  ) {
    var risk = 0;

    final loadDiff =
        (pressure.leftLoadPercentage - pressure.rightLoadPercentage).abs();

    if (loadDiff >= 12) risk += 2;
    if (loadDiff >= 6) risk += 1;

    final maxPronation = _maxNullable(
      report.leftPronatorAngle,
      report.rightPronatorAngle,
    );

    if (maxPronation != null) {
      if (maxPronation >= 12) risk += 2;
      if (maxPronation >= 8) risk += 1;
    }

    final archNeed = _archNeedLevel(report.leftArchType) >
            _archNeedLevel(report.rightArchType)
        ? _archNeedLevel(report.leftArchType)
        : _archNeedLevel(report.rightArchType);

    if (archNeed >= 3) risk += 2;
    if (archNeed == 2) risk += 1;

    if (pressure.peakPressure >= 350) risk += 2;
    if (pressure.peakPressure >= 280) risk += 1;

    if (risk >= 5) return 'Yüksek';
    if (risk >= 3) return 'Orta-Yüksek';
    if (risk >= 1) return 'Orta';
    return 'Düşük';
  }

  static String _buildPronationStatus(ParsedScanReport report) {
    final left = report.leftPronatorAngle;
    final right = report.rightPronatorAngle;

    if (left == null && right == null) return 'Belirlenemedi';

    final maxValue = _maxNullable(left, right) ?? 0;

    if (maxValue >= 12) return 'Belirgin pronasyon';
    if (maxValue >= 8) return 'Hafif pronasyon';
    return 'Normal aralık';
  }

  static String _buildHalluxStatus(ParsedScanReport report) {
    final leftType = report.leftHalluxType?.toLowerCase();
    final rightType = report.rightHalluxType?.toLowerCase();

    final leftAngle = report.leftHalluxAngle;
    final rightAngle = report.rightHalluxAngle;

    final maxAngle = _maxNullable(leftAngle, rightAngle);

    if ((leftType?.contains('valgus') ?? false) ||
        (rightType?.contains('valgus') ?? false)) {
      return 'Halluks sapması mevcut';
    }

    if (maxAngle == null) return 'Belirlenemedi';

    if (maxAngle >= 15) return 'Belirgin açı artışı';
    if (maxAngle >= 10) return 'Hafif açı artışı';
    return 'Normal aralık';
  }

  static double? _maxNullable(double? a, double? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }
}