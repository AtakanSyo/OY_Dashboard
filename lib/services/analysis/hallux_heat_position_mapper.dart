class HalluxHeatPositionMapper {
  const HalluxHeatPositionMapper._();

  static double? resolve({
    required double? angle,
    required String? type,
    double severeThreshold = 30,
  }) {
    if (angle != null && angle.isFinite && severeThreshold > 0) {
      return (0.5 + (angle / severeThreshold) * 0.5).clamp(0.0, 1.0);
    }

    final normalized = _normalize(type);
    if (normalized.isEmpty) return null;

    if (_containsAny(normalized, const ['normal', 'neutral', 'notr'])) {
      return 0.5;
    }

    final pointsRight = !normalized.contains('varus');
    final offset = _containsAny(
      normalized,
      const ['severe', 'ileri', 'marked', 'belirgin'],
    )
        ? 0.45
        : _containsAny(normalized, const ['moderate', 'orta'])
        ? 0.32
        : _containsAny(normalized, const ['mild', 'hafif'])
        ? 0.18
        : normalized.contains('valgus') || normalized.contains('varus')
        ? 0.32
        : null;

    if (offset == null) return null;
    return pointsRight ? 0.5 + offset : 0.5 - offset;
  }

  static String _normalize(String? value) {
    return (value ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  static bool _containsAny(String value, List<String> candidates) {
    return candidates.any(value.contains);
  }
}
