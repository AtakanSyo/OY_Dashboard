import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/services/analysis/hallux_heat_position_mapper.dart';

void main() {
  test('uses the measured angle when it is available', () {
    final position = HalluxHeatPositionMapper.resolve(
      angle: 12,
      type: 'Normal Hallux',
    );

    expect(position, closeTo(0.7, 0.0001));
  });

  test('places a normal Hallux type at the center without an angle', () {
    final position = HalluxHeatPositionMapper.resolve(
      angle: null,
      type: 'Normal Hallux',
    );

    expect(position, 0.5);
  });

  test('maps localized severity types when the angle is absent', () {
    expect(
      HalluxHeatPositionMapper.resolve(angle: null, type: 'Hafif valgus'),
      closeTo(0.68, 0.0001),
    );
    expect(
      HalluxHeatPositionMapper.resolve(angle: null, type: 'İleri Düzey'),
      closeTo(0.95, 0.0001),
    );
  });

  test('keeps the marker hidden when neither angle nor type is meaningful', () {
    expect(
      HalluxHeatPositionMapper.resolve(angle: null, type: null),
      isNull,
    );
  });
}
