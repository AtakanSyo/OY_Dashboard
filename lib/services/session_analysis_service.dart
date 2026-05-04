import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/analysis/engines/foot_summary_engine.dart';
import 'package:oy_site/services/analysis/engines/metrics_engine.dart';
import 'package:oy_site/services/analysis/engines/recommendation_engine.dart';
import 'package:oy_site/services/analysis/models/plantar_pressure_summary.dart';

class SessionAnalysisService {
  CustomerAnalysisResult analyze({
    required ParsedScanReport report,
    required PlantarPressureSummary pressure,
    required CustomerAnalysisVisualSet visuals,
    DateTime? analysisDate,
    String? sessionCode,
    String? locationLabel,
  }) {
    final leftFoot = FootSummaryEngine.build(
      isLeft: true,
      report: report,
      pressure: pressure,
    );

    final rightFoot = FootSummaryEngine.build(
      isLeft: false,
      report: report,
      pressure: pressure,
    );

    final metrics = MetricsEngine.build(
      report: report,
      pressure: pressure,
    );

    final recommendations = RecommendationEngine.build(
      report: report,
      pressure: pressure,
    );

    return CustomerAnalysisResult(
      analysisDate: analysisDate ?? DateTime.now(),
      sessionCode: sessionCode ?? report.reportNo ?? 'UNKNOWN-SESSION',
      locationLabel: locationLabel ?? report.storeCode ?? report.address ?? 'Bilinmeyen Lokasyon',
      overallSummary: _buildOverallSummary(report, pressure),
      generalRiskNote: _buildGeneralRiskNote(report, pressure),
      leftFoot: leftFoot,
      rightFoot: rightFoot,
      metrics: metrics,
      recommendations: recommendations,
      visuals: visuals,
      parsedReport: report,
    );
  }

  String _buildOverallSummary(
    ParsedScanReport report,
    PlantarPressureSummary pressure,
  ) {
    final loadDiff =
        (pressure.leftLoadPercentage - pressure.rightLoadPercentage).abs();

    final hasArchNeed =
        _isRiskyArch(report.leftArchType) || _isRiskyArch(report.rightArchType);

    final hasPronationRisk =
        (report.leftPronatorAngle ?? 0) >= 8 ||
        (report.rightPronatorAngle ?? 0) >= 8;

    if (hasArchNeed && loadDiff >= 6) {
      return 'Ayak analizinde kemer desteği ihtiyacı ve yük dağılımında dengesizlik görülmektedir. Kişisel destek kullanımı konforu artırabilir.';
    }

    if (hasPronationRisk) {
      return 'Ayak analizinde pronasyon eğilimi dikkat çekmektedir. Stabiliteyi artıran destek yapıları değerlendirilebilir.';
    }

    if (hasArchNeed) {
      return 'Ayak analizinde kemer yapısına bağlı destek ihtiyacı görülmektedir. Günlük kullanımda kişisel iç taban desteği faydalı olabilir.';
    }

    if (loadDiff >= 6) {
      return 'Sol ve sağ ayak yük dağılımında fark görülmektedir. Dengeleyici destek yapıları değerlendirilebilir.';
    }

    return 'Ayak analizinde genel yapı dengeli görünmektedir. Konforu korumaya yönelik kişisel destek önerilebilir.';
  }

  String _buildGeneralRiskNote(
    ParsedScanReport report,
    PlantarPressureSummary pressure,
  ) {
    final loadDiff =
        (pressure.leftLoadPercentage - pressure.rightLoadPercentage).abs();

    final maxPronation = _maxNullable(
      report.leftPronatorAngle,
      report.rightPronatorAngle,
    );

    if (pressure.peakPressure >= 350) {
      return 'Yüksek basınç değerleri uzun süreli kullanımda konfor kaybını artırabilir.';
    }

    if (loadDiff >= 10) {
      return 'Yük dağılımındaki belirgin fark, uzun süre ayakta kalındığında yorgunluk hissini artırabilir.';
    }

    if ((maxPronation ?? 0) >= 10) {
      return 'Pronasyon açısındaki artış, stabilite ve yorgunluk açısından takip edilmelidir.';
    }

    return 'Belirgin yüksek risk görülmemekle birlikte düzenli takip ve uygun destek önerilir.';
  }

  bool _isRiskyArch(String? value) {
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

  double? _maxNullable(double? a, double? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a > b ? a : b;
  }
}