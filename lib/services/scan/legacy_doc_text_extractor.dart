import 'dart:io';
import 'dart:typed_data';

/// Extracts the text stream from legacy Word 97-2003 `.doc` files.
///
/// These files are OLE Compound Binary documents, not ZIP/XML documents. The
/// scanner reports store their table text in the `WordDocument` stream using a
/// mixture of UTF-16LE and single-byte text runs separated by Word cell marks.
class LegacyDocTextExtractor {
  const LegacyDocTextExtractor();

  Future<String> extractText(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return extractTextFromBytes(bytes);
  }

  String extractTextFromBytes(Uint8List bytes) {
    final compoundFile = _CompoundBinaryFile(bytes);
    final wordDocument = compoundFile.readStream('WordDocument');
    final tokens = _extractTextTokens(wordDocument);

    final reportStart = tokens.indexWhere(
      (token) => token.toLowerCase() == 'no.',
    );
    final reportTokens = reportStart < 0 ? tokens : tokens.sublist(reportStart);
    final text = reportTokens.join('\n').trim();

    if (text.isEmpty || !text.toLowerCase().contains('foot length')) {
      throw const FormatException(
        'Word raporunda beklenen 3D tarama metni bulunamadı.',
      );
    }

    return text;
  }

  List<String> _extractTextTokens(Uint8List bytes) {
    final tokens = <String>[];
    var index = 0;

    while (index < bytes.length) {
      if (_isPrintableAscii(bytes[index]) &&
          index + 1 < bytes.length &&
          bytes[index + 1] == 0) {
        final buffer = StringBuffer();

        while (index + 1 < bytes.length &&
            _isPrintableAscii(bytes[index]) &&
            bytes[index + 1] == 0) {
          buffer.writeCharCode(bytes[index]);
          index += 2;
        }

        // Some scanner reports switch from UTF-16LE to ANSI for the final
        // character immediately before a Word table-cell marker (0x07).
        if (index + 1 < bytes.length &&
            _isAsciiLetter(bytes[index]) &&
            bytes[index + 1] == 0x07) {
          buffer.writeCharCode(bytes[index]);
          index++;
        }

        _addToken(tokens, buffer.toString(), trustedUnicodeRun: true);
        continue;
      }

      if (_isPrintableAscii(bytes[index])) {
        final start = index;
        while (index < bytes.length && _isPrintableAscii(bytes[index])) {
          index++;
        }
        _addToken(
          tokens,
          String.fromCharCodes(bytes.sublist(start, index)),
          trustedUnicodeRun: false,
        );
        continue;
      }

      index++;
    }

    return tokens;
  }

  void _addToken(
    List<String> tokens,
    String rawValue, {
    required bool trustedUnicodeRun,
  }) {
    final value = rawValue.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (!_isMeaningfulToken(value, trustedUnicodeRun: trustedUnicodeRun)) {
      return;
    }

    final repeatedMeasurement =
        tokens.isNotEmpty &&
        tokens.last == value &&
        RegExp(r'^-?\d+(?:[.,]\d+)?$').hasMatch(value);

    // Sol ve sağ ölçümler aynı olduğunda Word akışında aynı sayı art arda
    // gelebilir. Bunlar yinelenen metin değil, iki ayrı tablo hücresidir.
    if (tokens.isEmpty || tokens.last != value || repeatedMeasurement) {
      tokens.add(value);
    }
  }

  bool _isMeaningfulToken(String value, {required bool trustedUnicodeRun}) {
    if (value.isEmpty || value.length > 240) return false;

    if (RegExp(r'^-?\d+(?:[.,]\d+)?$').hasMatch(value) ||
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
        RegExp(r'^\d{1,2}:\d{2}(?::\d{2})?$').hasMatch(value)) {
      return true;
    }

    const shortReportTokens = {
      'No.',
      'Age',
      'Tel',
      'Male',
      'Female',
      'Yes',
      'No',
      'mm',
    };
    if (shortReportTokens.contains(value)) return true;

    final minimumLength = trustedUnicodeRun ? 2 : 4;
    if (value.length < minimumLength || !RegExp(r'[A-Za-z]').hasMatch(value)) {
      return false;
    }

    return RegExp(r'^[A-Za-z0-9 .,:;()/%~<>|+\-]+$').hasMatch(value);
  }

  bool _isPrintableAscii(int value) => value >= 0x20 && value <= 0x7e;

  bool _isAsciiLetter(int value) =>
      (value >= 0x41 && value <= 0x5a) || (value >= 0x61 && value <= 0x7a);
}

class _CompoundBinaryFile {
  static const _signature = <int>[
    0xd0,
    0xcf,
    0x11,
    0xe0,
    0xa1,
    0xb1,
    0x1a,
    0xe1,
  ];
  static const _freeSector = 0xffffffff;
  static const _endOfChain = 0xfffffffe;

  final Uint8List bytes;
  late final ByteData _data = ByteData.sublistView(bytes);
  late final int _sectorSize;
  late final List<int> _fat;
  late final Map<String, _CompoundDirectoryEntry> _directory;

  _CompoundBinaryFile(this.bytes) {
    if (bytes.length < 512 ||
        !_signature.asMap().entries.every(
          (entry) => bytes[entry.key] == entry.value,
        )) {
      throw const FormatException('Dosya geçerli bir legacy Word DOC değil.');
    }

    _sectorSize = 1 << _uint16(0x1e);
    if (_sectorSize != 512 && _sectorSize != 4096) {
      throw FormatException('Desteklenmeyen OLE sektör boyutu: $_sectorSize');
    }

    _fat = _readFat();
    _directory = _readDirectory();
  }

  Uint8List readStream(String name) {
    final entry = _directory[name.toLowerCase()];
    if (entry == null || entry.type != 2) {
      throw FormatException('DOC stream bulunamadı: $name');
    }

    final stream = _readChain(entry.startSector);
    if (entry.size > stream.length) {
      throw FormatException('$name stream boyutu geçersiz.');
    }
    return Uint8List.sublistView(stream, 0, entry.size);
  }

  List<int> _readFat() {
    final fatSectorCount = _uint32(0x2c);
    final fatSectorIds = <int>[];

    for (var index = 0; index < 109; index++) {
      final sectorId = _uint32(0x4c + index * 4);
      if (sectorId != _freeSector && sectorId != _endOfChain) {
        fatSectorIds.add(sectorId);
      }
    }

    var difatSector = _uint32(0x44);
    final difatSectorCount = _uint32(0x48);
    for (
      var chainIndex = 0;
      chainIndex < difatSectorCount && difatSector != _endOfChain;
      chainIndex++
    ) {
      final sector = _sector(difatSector);
      final sectorData = ByteData.sublistView(sector);
      final entryCount = _sectorSize ~/ 4 - 1;
      for (var index = 0; index < entryCount; index++) {
        final sectorId = sectorData.getUint32(index * 4, Endian.little);
        if (sectorId != _freeSector && sectorId != _endOfChain) {
          fatSectorIds.add(sectorId);
        }
      }
      difatSector = sectorData.getUint32(_sectorSize - 4, Endian.little);
    }

    if (fatSectorIds.length < fatSectorCount) {
      throw const FormatException('DOC FAT tablosu eksik.');
    }

    final fat = <int>[];
    for (final sectorId in fatSectorIds.take(fatSectorCount)) {
      final sectorData = ByteData.sublistView(_sector(sectorId));
      for (var offset = 0; offset < _sectorSize; offset += 4) {
        fat.add(sectorData.getUint32(offset, Endian.little));
      }
    }
    return fat;
  }

  Map<String, _CompoundDirectoryEntry> _readDirectory() {
    final directoryStream = _readChain(_uint32(0x30));
    final entries = <String, _CompoundDirectoryEntry>{};

    for (
      var offset = 0;
      offset + 128 <= directoryStream.length;
      offset += 128
    ) {
      final entryData = ByteData.sublistView(
        directoryStream,
        offset,
        offset + 128,
      );
      final nameLength = entryData.getUint16(64, Endian.little);
      final type = entryData.getUint8(66);
      if (nameLength < 2 || nameLength > 64 || type == 0) continue;

      final nameCodes = <int>[];
      for (var nameOffset = 0; nameOffset < nameLength - 2; nameOffset += 2) {
        nameCodes.add(entryData.getUint16(nameOffset, Endian.little));
      }
      final name = String.fromCharCodes(nameCodes);
      final startSector = entryData.getUint32(116, Endian.little);
      final sizeLow = entryData.getUint32(120, Endian.little);
      final sizeHigh = entryData.getUint32(124, Endian.little);
      final size = sizeLow + (sizeHigh << 32);

      entries[name.toLowerCase()] = _CompoundDirectoryEntry(
        type: type,
        startSector: startSector,
        size: size,
      );
    }
    return entries;
  }

  Uint8List _readChain(int startSector) {
    final output = BytesBuilder(copy: false);
    var sectorId = startSector;
    final visited = <int>{};

    while (sectorId != _endOfChain && sectorId != _freeSector) {
      if (sectorId >= _fat.length || !visited.add(sectorId)) {
        throw const FormatException('DOC sektör zinciri geçersiz.');
      }
      output.add(_sector(sectorId));
      sectorId = _fat[sectorId];
    }
    return output.takeBytes();
  }

  Uint8List _sector(int sectorId) {
    final offset = (sectorId + 1) * _sectorSize;
    final end = offset + _sectorSize;
    if (sectorId < 0 || offset < 0 || end > bytes.length) {
      throw const FormatException('DOC sektör adresi dosya dışında.');
    }
    return Uint8List.sublistView(bytes, offset, end);
  }

  int _uint16(int offset) => _data.getUint16(offset, Endian.little);

  int _uint32(int offset) => _data.getUint32(offset, Endian.little);
}

class _CompoundDirectoryEntry {
  final int type;
  final int startSector;
  final int size;

  const _CompoundDirectoryEntry({
    required this.type,
    required this.startSector,
    required this.size,
  });
}
