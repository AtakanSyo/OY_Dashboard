import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/services/analysis/arch_width_coefficient_mapper.dart';

void main() {
  test('maps the eight reference coefficient types across the heat bar', () {
    final cases = <double, ArchWidthCoefficientType>{
      3.2: ArchWidthCoefficientType.severeHighArch,
      3.0: ArchWidthCoefficientType.moderateHighArch,
      2.0: ArchWidthCoefficientType.mildHighArch,
      1.57: ArchWidthCoefficientType.normalType4,
      1 / 1.12: ArchWidthCoefficientType.normalType5,
      1 / 2: ArchWidthCoefficientType.mildFlatFoot,
      1 / 3: ArchWidthCoefficientType.moderateFlatFoot,
      0.3: ArchWidthCoefficientType.severeFlatFoot,
    };

    for (final entry in cases.entries) {
      final assessment = ArchWidthCoefficientMapper.resolve(entry.key);
      expect(assessment?.type, entry.value);
      expect(
        assessment?.position,
        closeTo(entry.value.index / 7, 0.0001),
      );
    }
  });

  test('maps observed report values to their nearest reference types', () {
    expect(
      ArchWidthCoefficientMapper.resolve(0.462)?.type,
      ArchWidthCoefficientType.mildFlatFoot,
    );
    expect(
      ArchWidthCoefficientMapper.resolve(0.341)?.type,
      ArchWidthCoefficientType.moderateFlatFoot,
    );
  });

  test('does not create a marker for invalid coefficients', () {
    expect(ArchWidthCoefficientMapper.resolve(null), isNull);
    expect(ArchWidthCoefficientMapper.resolve(0), isNull);
  });
}
