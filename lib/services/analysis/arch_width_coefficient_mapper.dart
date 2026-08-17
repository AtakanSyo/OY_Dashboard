import 'dart:math' as math;

enum ArchWidthCoefficientType {
  severeHighArch,
  moderateHighArch,
  mildHighArch,
  normalType4,
  normalType5,
  mildFlatFoot,
  moderateFlatFoot,
  severeFlatFoot,
}

class ArchWidthCoefficientAssessment {
  final ArchWidthCoefficientType type;
  final double position;

  const ArchWidthCoefficientAssessment({
    required this.type,
    required this.position,
  });
}

class ArchWidthCoefficientMapper {
  const ArchWidthCoefficientMapper._();

  static const _oneToOnePointTwelve = 1 / 1.12;
  static const _oneToTwo = 1 / 2;
  static const _oneToThree = 1 / 3;

  static final _moderateHighBoundary = math.sqrt(3 * 2);
  static final _mildHighBoundary = math.sqrt(2 * 1.57);
  static final _normalTypeBoundary = math.sqrt(
    1.57 * _oneToOnePointTwelve,
  );
  static final _mildFlatBoundary = math.sqrt(
    _oneToOnePointTwelve * _oneToTwo,
  );
  static final _moderateFlatBoundary = math.sqrt(
    _oneToTwo * _oneToThree,
  );

  static ArchWidthCoefficientAssessment? resolve(double? value) {
    if (value == null || !value.isFinite || value <= 0) return null;

    final type = value > 3
        ? ArchWidthCoefficientType.severeHighArch
        : value >= _moderateHighBoundary
        ? ArchWidthCoefficientType.moderateHighArch
        : value >= _mildHighBoundary
        ? ArchWidthCoefficientType.mildHighArch
        : value >= _normalTypeBoundary
        ? ArchWidthCoefficientType.normalType4
        : value >= _mildFlatBoundary
        ? ArchWidthCoefficientType.normalType5
        : value >= _moderateFlatBoundary
        ? ArchWidthCoefficientType.mildFlatFoot
        : value >= _oneToThree
        ? ArchWidthCoefficientType.moderateFlatFoot
        : ArchWidthCoefficientType.severeFlatFoot;

    return ArchWidthCoefficientAssessment(
      type: type,
      position: type.index / (ArchWidthCoefficientType.values.length - 1),
    );
  }
}
