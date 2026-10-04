import 'dart:typed_data';

/// Sabitler, üreticinin "Insole sensor communication protocol" belgesinden ve
/// cihazın kullandığı Transparent UART profilinden alınmıştır. Belgedeki UUID'ler
/// standart tireli biçime normalize edilmiştir.
abstract final class InsoleProtocolConstants {
  static const String deviceNamePrefix = 'JYS_B_';
  static const String pairingCode = '654321';

  /// Üretici belgesindeki özel servis UUID'si.
  static const String serviceUuid = '55535343-fe7d-4ae5-8fa9-9fafd205e455';

  /// Bazı firmware sürümlerinin kullandığı standart ISSC Transparent UART
  /// servis UUID'si.
  static const String standardServiceUuid =
      '49535343-fe7d-4ae5-8fa9-9fafd205e455';

  /// JYS_B_001/JYS_B_002 cihazlarında keşfedilen ikinci üretici servisi.
  /// Bu servis de kanal test ekranında ayrı bir aday olarak gösterilir.
  static const String diagnosticServiceUuid =
      '5833ff01-9b8b-5191-6142-22a4536ef123';

  /// Cihazdan uygulamaya veri taşıyan, Notify özellikli Transparent UART TX.
  static const String notifyCharacteristicUuid =
      '49535343-1e4d-4bd9-ba61-23c647249616';

  /// PDF'de BLETX olarak yazılmış olsa da cihazın GATT tablosunda bu UUID
  /// uygulamadan cihaza yazılan RX kanalına karşılık gelir.
  static const String documentedWriteCharacteristicUuid =
      '49535343-8841-43f4-a8d4-ecbe34729bb3';

  static const List<String> supportedServiceUuids = [
    serviceUuid,
    standardServiceUuid,
    diagnosticServiceUuid,
  ];
  static const Duration nominalFrameInterval = Duration(milliseconds: 50);

  static const int pressureFunctionCode = 0x01;
  static const int frameTail = 0x5A;
}

class InsolePressureFrame {
  final int rows;
  final int columns;
  final int bytesPerSample;
  final List<List<int>> matrix;
  final Uint8List rawFrame;

  const InsolePressureFrame({
    required this.rows,
    required this.columns,
    required this.bytesPerSample,
    required this.matrix,
    required this.rawFrame,
  });

  int get pointCount => rows * columns;

  String get matrixLabel =>
      columns == 9 && rows == 12 ? '9×12' : '$columns×$rows';

  int get maximumValue {
    var maximum = 0;
    for (final row in matrix) {
      for (final value in row) {
        if (value > maximum) maximum = value;
      }
    }
    return maximum;
  }

  double get averageValue {
    var sum = 0;
    var count = 0;
    for (final row in matrix) {
      for (final value in row) {
        sum += value;
        count++;
      }
    }
    return count == 0 ? 0 : sum / count;
  }
}

/// BLE bildirimleri bir çerçeveyi birden fazla parçaya bölebilir. Bu ayrıştırıcı
/// parçaları biriktirir, 55 AA başlığını bulur, uzunluk/son/checksum alanlarını
/// doğrular ve yalnızca geçerli basınç çerçevelerini döndürür.
///
/// Üretici belgesi örnek başına 1 ve 2 bayt ile 9×12 ve 16×16 matrisleri farklı
/// yerlerde belirtir. Ayrıştırıcı bu dört geçerli yük boyutunu otomatik tanır.
class InsoleProtocolParser {
  static const int _headerLow = 0x55;
  static const int _headerHigh = 0xAA;
  static const Set<int> _supportedDeclaredLengths = {
    1, // 0x81 geri bildirim, içerik yok
    109, // fonksiyon + 9x12 tek bayt
    217, // fonksiyon + 9x12 iki bayt
    257, // fonksiyon + 16x16 tek bayt
    513, // fonksiyon + 16x16 iki bayt
  };

  final List<int> _buffer = <int>[];

  int invalidFrameCount = 0;

  List<InsolePressureFrame> addBytes(List<int> bytes) {
    _buffer.addAll(bytes.map((value) => value & 0xFF));
    final frames = <InsolePressureFrame>[];

    while (true) {
      final headerIndex = _findHeader();
      if (headerIndex < 0) {
        _preservePossibleHeaderPrefix();
        break;
      }

      if (headerIndex > 0) {
        _buffer.removeRange(0, headerIndex);
      }

      if (_buffer.length < 4) break;

      final declaredLength = _buffer[2] | (_buffer[3] << 8);
      if (!_supportedDeclaredLengths.contains(declaredLength)) {
        invalidFrameCount++;
        _buffer.removeAt(0);
        continue;
      }

      final frameLength = declaredLength + 6;
      if (_buffer.length < frameLength) break;

      final candidate = _buffer.sublist(0, frameLength);
      final checksumIndex = 4 + declaredLength;
      final hasValidTail = candidate.last == InsoleProtocolConstants.frameTail;
      final expectedChecksum = checksumFor(candidate.sublist(0, checksumIndex));
      final hasValidChecksum = candidate[checksumIndex] == expectedChecksum;

      if (!hasValidTail || !hasValidChecksum) {
        invalidFrameCount++;
        _buffer.removeAt(0);
        continue;
      }

      _buffer.removeRange(0, frameLength);

      if (candidate[4] != InsoleProtocolConstants.pressureFunctionCode) {
        continue;
      }

      final content = candidate.sublist(5, checksumIndex);
      final layout = _layoutForContentLength(content.length);
      if (layout == null) {
        invalidFrameCount++;
        continue;
      }

      frames.add(
        InsolePressureFrame(
          rows: layout.rows,
          columns: layout.columns,
          bytesPerSample: layout.bytesPerSample,
          matrix: _decodeMatrix(content, layout),
          rawFrame: Uint8List.fromList(candidate),
        ),
      );
    }

    return frames;
  }

  void reset() {
    _buffer.clear();
    invalidFrameCount = 0;
  }

  static int checksumFor(Iterable<int> bytes) {
    var sum = 0;
    for (final byte in bytes) {
      sum = (sum + (byte & 0xFF)) & 0xFF;
    }
    return (256 - sum) & 0xFF;
  }

  int _findHeader() {
    for (var index = 0; index < _buffer.length - 1; index++) {
      if (_buffer[index] == _headerLow && _buffer[index + 1] == _headerHigh) {
        return index;
      }
    }
    return -1;
  }

  void _preservePossibleHeaderPrefix() {
    final keepLastByte = _buffer.isNotEmpty && _buffer.last == _headerLow;
    final lastByte = keepLastByte ? _buffer.last : null;
    _buffer.clear();
    if (lastByte != null) _buffer.add(lastByte);
  }

  _InsoleMatrixLayout? _layoutForContentLength(int length) {
    return switch (length) {
      108 => const _InsoleMatrixLayout(rows: 12, columns: 9, bytesPerSample: 1),
      216 => const _InsoleMatrixLayout(rows: 12, columns: 9, bytesPerSample: 2),
      256 => const _InsoleMatrixLayout(
        rows: 16,
        columns: 16,
        bytesPerSample: 1,
      ),
      512 => const _InsoleMatrixLayout(
        rows: 16,
        columns: 16,
        bytesPerSample: 2,
      ),
      _ => null,
    };
  }

  List<List<int>> _decodeMatrix(List<int> content, _InsoleMatrixLayout layout) {
    final values = <int>[];

    if (layout.bytesPerSample == 1) {
      values.addAll(content);
    } else {
      for (var index = 0; index < content.length; index += 2) {
        // Dokümandaki uzunluk alanı gibi örnekler de düşük bayt önce kabul
        // edilir. Böylece 0-5000 mV aralığı kayıpsız taşınır.
        values.add(content[index] | (content[index + 1] << 8));
      }
    }

    return List<List<int>>.generate(
      layout.rows,
      (row) => List<int>.generate(
        layout.columns,
        (column) => values[(row * layout.columns) + column],
        growable: false,
      ),
      growable: false,
    );
  }
}

class _InsoleMatrixLayout {
  final int rows;
  final int columns;
  final int bytesPerSample;

  const _InsoleMatrixLayout({
    required this.rows,
    required this.columns,
    required this.bytesPerSample,
  });
}
