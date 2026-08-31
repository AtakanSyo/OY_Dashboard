import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/analysis/models/plantar_pressure_summary.dart';

class RecommendationEngine {
  static List<CustomerRecommendationItem> build({
    required ParsedScanReport report,
    required PlantarPressureSummary pressure,
  }) {
    final recommendations = <CustomerRecommendationItem>[];

    if (_hasHighArchSupportNeed(report)) {
      recommendations.add(
        const CustomerRecommendationItem(
          title: 'Kemer destekli iç taban önerilir',
          description:
              'Kemer yapısı ve ark tipi bilgilerine göre kişisel kemer desteği konforu artırabilir.',
        ),
      );
    }

    if (_hasLoadImbalance(pressure)) {
      recommendations.add(
        const CustomerRecommendationItem(
          title: 'Yük dağılımını dengeleyen yapı tercih edilmeli',
          description:
              'Sol ve sağ ayak yük dağılımı arasında fark olduğu için tabanlık tasarımında dengeleyici destek önerilir.',
        ),
      );
    }

    if (_hasHighPeakPressure(pressure)) {
      recommendations.add(
        CustomerRecommendationItem(
          title: 'Basınç azaltıcı destek önerilir',
          description:
              '${pressure.peakPressureRegion} bölgesinde yüksek basınç görüldüğü için yük dağıtıcı yapı tercih edilebilir.',
        ),
      );
    }

    if (_hasPronationRisk(report)) {
      recommendations.add(
        const CustomerRecommendationItem(
          title: 'Stabilite desteği değerlendirilmeli',
          description:
              'Pronasyon açısındaki artış nedeniyle topuk ve orta ayak stabilitesini destekleyen tasarım önerilir.',
        ),
      );
    }

    if (_hasHalluxRisk(report)) {
      recommendations.add(
        const CustomerRecommendationItem(
          title: 'Ön ayak konforu desteklenmeli',
          description:
              'Halluks açısı veya halluks tipi nedeniyle ön ayak bölgesinde rahatlatıcı ve yönlendirici destek değerlendirilebilir.',
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const CustomerRecommendationItem(
          title: 'Koruyucu destek önerilir',
          description:
              'Belirgin yüksek risk görülmese de günlük kullanımda konforu sürdürmek için kişisel destek tercih edilebilir.',
        ),
      );
    }

    return recommendations;
  }

  static bool _hasHighArchSupportNeed(ParsedScanReport report) {
    return _isRiskyArch(report.leftArchType) || _isRiskyArch(report.rightArchType);
  }

  static bool _isRiskyArch(String? value) {
    final normalized = value?.toLowerCase().trim();

    if (normalized == null || normalized.isEmpty) return false;

    return normalized.contains('flat') ||
        normalized.contains('düz') ||
        normalized.contains('low') ||
        normalized.contains('pes planus') ||
        normalized.contains('high') ||
        normalized.contains('yüksek') ||
        normalized.contains('pes cavus');
  }

  static bool _hasLoadImbalance(PlantarPressureSummary pressure) {
    final diff =
        (pressure.leftLoadPercentage - pressure.rightLoadPercentage).abs();

    return diff >= 6;
  }

  static bool _hasHighPeakPressure(PlantarPressureSummary pressure) {
    return pressure.peakPressure >= 280;
  }

  static bool _hasPronationRisk(ParsedScanReport report) {
    final left = report.leftPronatorAngle ?? 0;
    final right = report.rightPronatorAngle ?? 0;

    return left >= 8 || right >= 8;
  }

  static bool _hasHalluxRisk(ParsedScanReport report) {
    final leftType = report.leftHalluxType?.toLowerCase() ?? '';
    final rightType = report.rightHalluxType?.toLowerCase() ?? '';

    final leftAngle = report.leftHalluxAngle ?? 0;
    final rightAngle = report.rightHalluxAngle ?? 0;

    return leftType.contains('valgus') ||
        rightType.contains('valgus') ||
        leftAngle >= 10 ||
        rightAngle >= 10;
  }
}