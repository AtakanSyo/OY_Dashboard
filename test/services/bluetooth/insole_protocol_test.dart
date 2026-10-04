import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/services/bluetooth/insole_protocol.dart';

void main() {
  group('InsoleProtocolParser', () {
    test('üretici dokümanındaki checksum örneğini doğrular', () {
      expect(
        InsoleProtocolParser.checksumFor([0x55, 0xAA, 0x01, 0x00, 0x81]),
        0x7F,
      );
    });

    test('parçalara bölünmüş 16x16 tek bayt çerçeveyi birleştirir', () {
      final parser = InsoleProtocolParser();
      final content = List<int>.generate(256, (index) => index);
      final frame = _buildFrame(content);

      expect(parser.addBytes(frame.sublist(0, 1)), isEmpty);
      expect(parser.addBytes(frame.sublist(1, 27)), isEmpty);

      final parsed = parser.addBytes(frame.sublist(27));

      expect(parsed, hasLength(1));
      expect(parsed.single.rows, 16);
      expect(parsed.single.columns, 16);
      expect(parsed.single.bytesPerSample, 1);
      expect(parsed.single.matrix.first.first, 0);
      expect(parsed.single.matrix.last.last, 255);
      expect(parsed.single.maximumValue, 255);
      expect(parser.invalidFrameCount, 0);
    });

    test('9x12 iki bayt örnekleri little-endian olarak çözer', () {
      final parser = InsoleProtocolParser();
      final values = List<int>.generate(108, (index) => index * 37);
      final content = values
          .expand((value) => [value & 0xFF, (value >> 8) & 0xFF])
          .toList();

      final parsed = parser.addBytes(_buildFrame(content)).single;

      expect(parsed.rows, 12);
      expect(parsed.columns, 9);
      expect(parsed.bytesPerSample, 2);
      expect(parsed.matrix[0][1], 37);
      expect(parsed.matrix[11][8], values.last);
      expect(
        parsed.averageValue,
        closeTo(values.reduce((a, b) => a + b) / 108, 0.001),
      );
    });

    test('bozuk checksum paketini atlayıp sonraki geçerli kareyi bulur', () {
      final parser = InsoleProtocolParser();
      final badFrame = _buildFrame(List<int>.filled(108, 3));
      badFrame[badFrame.length - 2] ^= 0xFF;
      final goodFrame = _buildFrame(List<int>.filled(108, 7));

      final parsed = parser.addBytes([0x10, 0x20, ...badFrame, ...goodFrame]);

      expect(parsed, hasLength(1));
      expect(parsed.single.matrix[0][0], 7);
      expect(parser.invalidFrameCount, greaterThanOrEqualTo(1));
    });

    test('geri bildirim çerçevesini basınç karesi olarak yayınlamaz', () {
      final parser = InsoleProtocolParser();
      const feedback = [0x55, 0xAA, 0x01, 0x00, 0x81, 0x7F, 0x5A];

      expect(parser.addBytes(feedback), isEmpty);
      expect(parser.invalidFrameCount, 0);
    });
  });
}

Uint8List _buildFrame(List<int> content) {
  final declaredLength = content.length + 1;
  final frameWithoutChecksum = <int>[
    0x55,
    0xAA,
    declaredLength & 0xFF,
    (declaredLength >> 8) & 0xFF,
    InsoleProtocolConstants.pressureFunctionCode,
    ...content,
  ];

  return Uint8List.fromList([
    ...frameWithoutChecksum,
    InsoleProtocolParser.checksumFor(frameWithoutChecksum),
    InsoleProtocolConstants.frameTail,
  ]);
}
