import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/analysis/models/plantar_pressure_summary.dart';

class FootSummaryEngine {
  static CustomerFootSummary build({
    required bool isLeft,
    required ParsedScanReport report,
    required PlantarPressureSummary pressure,
  }) {
    final side = isLeft ? 'left' : 'right';

    final archType = isLeft ? report.leftArchType : report.rightArchType;
    final halluxType = isLeft ? report.leftHalluxType : report.rightHalluxType;
    final heelType = isLeft ? report.leftHeelType : report.rightHeelType;
    final kneeType = isLeft ? report.leftKneeType : report.rightKneeType;

    final archHeight = isLeft ? report.leftArchHeight : report.rightArchHeight;
    final archIndex = isLeft ? report.leftArchIndex : report.rightArchIndex;
    final halluxAngle =
        isLeft ? report.leftHalluxAngle : report.rightHalluxAngle;
    final pronatorAngle =
        isLeft ? report.leftPronatorAngle : report.rightPronatorAngle;

    final insoleRecommendation = isLeft
        ? report.leftInsoleRecommendation
        : report.rightInsoleRecommendation;

    return CustomerFootSummary(
      side: side,
      footType: _buildFootType(
        archType: archType,
        archIndex: archIndex,
        archHeight: archHeight,
      ),
      pressureSummary: _buildPressureSummary(
        pressure: pressure,
        isLeft: isLeft,
      ),
      balanceSummary: _buildBalanceSummary(
        pressure: pressure,
        isLeft: isLeft,
      ),
      archSupportNeed: _buildArchSupportNeed(
        archType: archType,
        archIndex: archIndex,
        insoleRecommendation: insoleRecommendation,
      ),
      mainFinding: _buildMainFinding(
        archType: archType,
        halluxType: halluxType,
        heelType: heelType,
        kneeType: kneeType,
        halluxAngle: halluxAngle,
        pronatorAngle: pronatorAngle,
      ),
      pressureScore: _calculatePressureScore(
        pressure: pressure,
        isLeft: isLeft,
      ),
      stabilityScore: _calculateStabilityScore(
        pressure: pressure,
        isLeft: isLeft,
        pronatorAngle: pronatorAngle,
      ),
      archScore: _calculateArchScore(
        archType: archType,
        archIndex: archIndex,
        archHeight: archHeight,
      ),
    );
  }

  static String _buildFootType({
    required String? archType,
    required double? archIndex,
    required double? archHeight,
  }) {
    final normalized = _normalize(archType);

    if (_containsAny(normalized, [
      'flat',
      'low',
      'düz',
      'dus',
      'pes planus',
      'planus',
    ])) {
      return 'Düz taban eğilimi';
    }

    if (_containsAny(normalized, [
      'high',
      'yüksek',
      'yuksek',
      'pes cavus',
      'cavus',
    ])) {
      return 'Yüksek kemer eğilimi';
    }

    if (_containsAny(normalized, [
      'normal',
      'neutral',
      'nötr',
      'notr',
    ])) {
      return 'Nötr ark yapısı';
    }

    if (archIndex != null) {
      if (archIndex >= 0.26) return 'Düz taban eğilimi';
      if (archIndex <= 0.20) return 'Yüksek kemer eğilimi';
      return 'Nötr ark yapısı';
    }

    if (archHeight != null) {
      if (archHeight < 22) return 'Düşük kemer eğilimi';
      if (archHeight > 35) return 'Yüksek kemer eğilimi';
      return 'Nötr ark yapısı';
    }

    return 'Değerlendirilemedi';
  }

  static String _buildPressureSummary({
    required PlantarPressureSummary pressure,
    required bool isLeft,
  }) {
    final load = isLeft
        ? pressure.leftLoadPercentage
        : pressure.rightLoadPercentage;

    if (load >= 56) {
      return 'Bu ayakta yüklenme artışı görülmektedir.';
    }

    if (load <= 44) {
      return 'Bu ayakta yüklenme diğer ayağa göre daha düşüktür.';
    }

    if (pressure.peakPressure >= 350) {
      return '${pressure.peakPressureRegion} bölgesinde yüksek basınç görülmektedir.';
    }

    if (pressure.peakPressure >= 280) {
      return '${pressure.peakPressureRegion} bölgesinde orta düzey basınç artışı vardır.';
    }

    return 'Basınç dağılımı dengeli görünmektedir.';
  }

  static String _buildBalanceSummary({
    required PlantarPressureSummary pressure,
    required bool isLeft,
  }) {
    final diff =
        (pressure.leftLoadPercentage - pressure.rightLoadPercentage).abs();

    if (diff >= 12) {
      return isLeft
          ? 'Sol / sağ yük dağılımında belirgin fark vardır.'
          : 'Sağ / sol yük dağılımında belirgin fark vardır.';
    }

    if (diff >= 6) {
      return 'Yük dağılımında hafif dengesizlik görülmektedir.';
    }

    return 'Sol ve sağ ayak yük dağılımı dengeli görünmektedir.';
  }

  static String _buildArchSupportNeed({
    required String? archType,
    required double? archIndex,
    required String? insoleRecommendation,
  }) {
    final recommendation = _normalize(insoleRecommendation);
    final normalizedArch = _normalize(archType);

    if (_containsAny(recommendation, [
      'high',
      'yüksek',
      'yuksek',
      'strong',
      'support',
      'destek',
    ])) {
      return 'Yüksek';
    }

    if (_containsAny(normalizedArch, [
      'flat',
      'low',
      'düz',
      'dus',
      'pes planus',
      'planus',
    ])) {
      return 'Yüksek';
    }

    if (_containsAny(normalizedArch, [
      'high',
      'yüksek',
      'yuksek',
      'pes cavus',
      'cavus',
    ])) {
      return 'Orta-Yüksek';
    }

    if (archIndex != null) {
      if (archIndex >= 0.26) return 'Yüksek';
      if (archIndex <= 0.20) return 'Orta-Yüksek';
      return 'Orta';
    }

    if (_containsAny(normalizedArch, ['normal', 'neutral', 'nötr', 'notr'])) {
      return 'Orta';
    }

    return 'Belirlenemedi';
  }

  static String _buildMainFinding({
    required String? archType,
    required String? halluxType,
    required String? heelType,
    required String? kneeType,
    required double? halluxAngle,
    required double? pronatorAngle,
  }) {
    final normalizedArch = _normalize(archType);
    final normalizedHallux = _normalize(halluxType);
    final normalizedHeel = _normalize(heelType);
    final normalizedKnee = _normalize(kneeType);

    if (_containsAny(normalizedArch, [
      'flat',
      'low',
      'düz',
      'dus',
      'pes planus',
      'planus',
    ])) {
      return 'Düşük kemer yapısı ve destek ihtiyacı öne çıkmaktadır.';
    }

    if (_containsAny(normalizedArch, [
      'high',
      'yüksek',
      'yuksek',
      'pes cavus',
      'cavus',
    ])) {
      return 'Yüksek kemer yapısı nedeniyle basınç dağılımı takip edilmelidir.';
    }

    if (_containsAny(normalizedHallux, ['valgus', 'hallux valgus']) ||
        (halluxAngle != null && halluxAngle >= 15)) {
      return 'Halluks açısında sapma eğilimi görülmektedir.';
    }

    if (pronatorAngle != null && pronatorAngle >= 12) {
      return 'Belirgin pronasyon artışı gözlemlenmektedir.';
    }

    if (pronatorAngle != null && pronatorAngle >= 8) {
      return 'Hafif pronasyon eğilimi gözlemlenmektedir.';
    }

    if (_containsAny(normalizedHeel, ['valgus', 'varus'])) {
      return 'Topuk hizalanmasında takip edilmesi gereken sapma görülmektedir.';
    }

    if (_containsAny(normalizedKnee, ['valgus', 'varus'])) {
      return 'Diz hizalanması ile ilişkili destek ihtiyacı değerlendirilebilir.';
    }

    return 'Genel ayak yapısı dengeli görünmektedir.';
  }

  static double _calculatePressureScore({
    required PlantarPressureSummary pressure,
    required bool isLeft,
  }) {
    final load = isLeft
        ? pressure.leftLoadPercentage
        : pressure.rightLoadPercentage;

    final loadDeviation = (load - 50).abs();
    var score = 100 - (loadDeviation * 3);

    if (pressure.peakPressure >= 350) {
      score -= 15;
    } else if (pressure.peakPressure >= 280) {
      score -= 8;
    }

    return score.clamp(35, 100).toDouble();
  }

  static double _calculateStabilityScore({
    required PlantarPressureSummary pressure,
    required bool isLeft,
    required double? pronatorAngle,
  }) {
    final load = isLeft
        ? pressure.leftLoadPercentage
        : pressure.rightLoadPercentage;

    final loadDeviation = (load - 50).abs();
    final pronationPenalty = pronatorAngle == null ? 0 : pronatorAngle * 2.2;

    var score = 100 - (loadDeviation * 2) - pronationPenalty;

    if (pressure.stabilityScore > 0) {
      score = (score + pressure.stabilityScore) / 2;
    }

    return score.clamp(35, 100).toDouble();
  }

  static double _calculateArchScore({
    required String? archType,
    required double? archIndex,
    required double? archHeight,
  }) {
    final normalized = _normalize(archType);

    if (_containsAny(normalized, [
      'normal',
      'neutral',
      'nötr',
      'notr',
    ])) {
      return 85;
    }

    if (_containsAny(normalized, [
      'flat',
      'low',
      'düz',
      'dus',
      'pes planus',
      'planus',
    ])) {
      return 52;
    }

    if (_containsAny(normalized, [
      'high',
      'yüksek',
      'yuksek',
      'pes cavus',
      'cavus',
    ])) {
      return 62;
    }

    if (archIndex != null) {
      if (archIndex >= 0.26) return 52;
      if (archIndex <= 0.20) return 62;
      return 85;
    }

    if (archHeight != null) {
      if (archHeight < 22) return 55;
      if (archHeight > 35) return 65;
      return 82;
    }

    return 70;
  }

  static String _normalize(String? value) {
    return value?.toLowerCase().trim() ?? '';
  }

  static bool _containsAny(String source, List<String> values) {
    return values.any(source.contains);
  }
}