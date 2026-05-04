import 'package:oy_site/models/parsed_scan_report.dart';

class ScanReportTextParser {
  const ScanReportTextParser();

  ParsedScanReport parse(String rawText) {
    final text = _normalize(rawText);

    return ParsedScanReport(
      reportNo: _extractSingleValue(text, 'No.'),
      reportDate: _extractSingleValue(text, 'Date'),
      reportTime: _extractSingleValue(text, 'Time'),
      storeCode: _extractSingleValue(text, 'Store'),
      address: _extractAddress(text),
      customerName: _extractSingleValue(text, 'Name'),
      gender: _extractSingleValue(text, 'Gender'),
      age: _extractSingleValue(text, 'Age'),
      phone: _extractSingleValue(text, 'Tel'),

      leftFootLength: _extractPairDouble(text, 'Foot length', isLeft: true),
      rightFootLength: _extractPairDouble(text, 'Foot length', isLeft: false),

      leftSoleLength: _extractPairDouble(text, 'Sole length', isLeft: true),
      rightSoleLength: _extractPairDouble(text, 'Sole length', isLeft: false),

      leftArchLength: _extractPairDouble(text, 'Arch length', isLeft: true),
      rightArchLength: _extractPairDouble(text, 'Arch length', isLeft: false),

      leftFirstMetaLength:
          _extractPairDouble(text, 'First meta length', isLeft: true),
      rightFirstMetaLength:
          _extractPairDouble(text, 'First meta length', isLeft: false),

      leftFifthMetaLength:
          _extractPairDouble(text, 'Fifth meta length', isLeft: true),
      rightFifthMetaLength:
          _extractPairDouble(text, 'Fifth meta length', isLeft: false),

      leftHalluxBumpsLength:
          _extractPairDouble(text, 'Hallux bumps length', isLeft: true),
      rightHalluxBumpsLength:
          _extractPairDouble(text, 'Hallux bumps length', isLeft: false),

      leftFootFlankLength:
          _extractPairDouble(text, 'Foot flank length', isLeft: true),
      rightFootFlankLength:
          _extractPairDouble(text, 'Foot flank length', isLeft: false),

      leftHeelCenterLength:
          _extractPairDouble(text, 'Heel center length', isLeft: true),
      rightHeelCenterLength:
          _extractPairDouble(text, 'Heel center length', isLeft: false),

      leftHeelMarginLength:
          _extractPairDouble(text, 'Heel margin length', isLeft: true),
      rightHeelMarginLength:
          _extractPairDouble(text, 'Heel margin length', isLeft: false),

      leftFootWidth: _extractPairDouble(text, 'Foot width', isLeft: true),
      rightFootWidth: _extractPairDouble(text, 'Foot width', isLeft: false),

      leftSlantWidth: _extractPairDouble(text, 'Slant width', isLeft: true),
      rightSlantWidth: _extractPairDouble(text, 'Slant width', isLeft: false),

      leftToeWidth: _extractPairDouble(text, 'Toe width', isLeft: true),
      rightToeWidth: _extractPairDouble(text, 'Toe width', isLeft: false),

      leftArchOutsideWidth:
          _extractPairDouble(text, 'Arch outside width', isLeft: true),
      rightArchOutsideWidth:
          _extractPairDouble(text, 'Arch outside width', isLeft: false),

      leftFootFlankWidth:
          _extractPairDouble(text, 'Foot flank width', isLeft: true),
      rightFootFlankWidth:
          _extractPairDouble(text, 'Foot flank width', isLeft: false),

      leftHeelCenterWidth:
          _extractPairDouble(text, 'Heel center width', isLeft: true),
      rightHeelCenterWidth:
          _extractPairDouble(text, 'Heel center width', isLeft: false),

      leftTotalHeelWidth:
          _extractPairDouble(text, 'Total heel width', isLeft: true),
      rightTotalHeelWidth:
          _extractPairDouble(text, 'Total heel width', isLeft: false),

      leftArchHeight: _extractPairDouble(text, 'Arch height', isLeft: true),
      rightArchHeight: _extractPairDouble(text, 'Arch height', isLeft: false),

      leftFirstMetaJointHeight:
          _extractPairDouble(text, 'First meta joint height', isLeft: true),
      rightFirstMetaJointHeight:
          _extractPairDouble(text, 'First meta joint height', isLeft: false),

      leftHeelProtrusionHeight:
          _extractPairDouble(text, 'Heel protrusion height', isLeft: true),
      rightHeelProtrusionHeight:
          _extractPairDouble(text, 'Heel protrusion height', isLeft: false),

      leftHalluxAngle: _extractPairDouble(text, 'Hallux angle', isLeft: true),
      rightHalluxAngle:
          _extractPairDouble(text, 'Hallux angle', isLeft: false),

      leftPronatorAngle:
          _extractPairDouble(text, 'Pronator angle', isLeft: true),
      rightPronatorAngle:
          _extractPairDouble(text, 'Pronator angle', isLeft: false),

      leftKneeAngle: _extractPairDouble(text, 'Knee angle', isLeft: true),
      rightKneeAngle: _extractPairDouble(text, 'Knee angle', isLeft: false),

      leftShoeSize: _extractPairString(text, 'Shoe size', isLeft: true),
      rightShoeSize: _extractPairString(text, 'Shoe size', isLeft: false),

      leftInsoleRecommendation: _extractPairString(
        text,
        'Insole recommendation',
        isLeft: true,
      ),
      rightInsoleRecommendation: _extractPairString(
        text,
        'Insole recommendation',
        isLeft: false,
      ),

      leftArchType: _extractArchType(text, isLeft: true),
      rightArchType: _extractArchType(text, isLeft: false),

      leftArchIndex: _extractArchIndex(text, isLeft: true),
      rightArchIndex: _extractArchIndex(text, isLeft: false),

      leftArchWidthIndex: _extractArchWidthIndex(text, isLeft: true),
      rightArchWidthIndex: _extractArchWidthIndex(text, isLeft: false),

      leftHalluxType: _extractNamedType(text, 'Hallux Type', isLeft: true) ??
          _extractNamedType(text, 'Hallgux Type', isLeft: true),
      rightHalluxType: _extractNamedType(text, 'Hallux Type', isLeft: false) ??
          _extractNamedType(text, 'Hallgux Type', isLeft: false),

      leftHeelType: _extractNamedType(text, 'Heel type', isLeft: true),
      rightHeelType: _extractNamedType(text, 'Heel type', isLeft: false),

      leftKneeType: _extractNamedType(text, 'Knee type', isLeft: true),
      rightKneeType: _extractNamedType(text, 'Knee type', isLeft: false),

    );
  }

  String _normalize(String input) {
    return input
        .replaceAll('\r', ' ')
        .replaceAll('\n', ' ')
        .replaceAll('：', ':')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .replaceAll('°', '°')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _extractSingleValue(String text, String label) {
    final escaped = RegExp.escape(label);

    final patterns = <RegExp>[
      RegExp('$escaped\\s+([^\\s]+)', caseSensitive: false),
      RegExp('$escaped\\s*:\\s*([^\\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    return null;
  }

  String? _extractAddress(String text) {
    final pattern = RegExp(
      r'Address\s+(.*?)(?=\s+Name\s+|\s+Arch analysis|\s+Arch analysis:|$)',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    final value = match?.group(1)?.trim();

    if (value == null || value.isEmpty) return null;
    return value;
  }

  double? _extractPairDouble(
    String text,
    String label, {
    required bool isLeft,
  }) {
    final escapedLabel = _labelPattern(label);

    final patterns = <RegExp>[
      // Table format:
      // Foot length 250.8 248.8
      // Knee angle 0.6 -2.3
      RegExp(
        '$escapedLabel\\s+($_numberPattern)\\s+($_numberPattern)',
        caseSensitive: false,
      ),

      // Visual/report format:
      // 13.5 Arch height(mm) 12.4
      // 2.4 Hallux angle(°) 1.1
      // 0.6 Knee angle(°) 2.3
      RegExp(
        '($_numberPattern)\\s+$escapedLabel\\s+($_numberPattern)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = isLeft ? match.group(1) : match.group(2);
      return _toDouble(raw);
    }

    return null;
  }

  String? _extractPairString(
    String text,
    String label, {
    required bool isLeft,
  }) {
    final escapedLabel = _labelPattern(label);

    final pattern = RegExp(
      '$escapedLabel'
      r'\s+(.+?)\s+(.+?)(?=\s+(?:Service demand|Recommendation|tel:|Shenzhen|Item description|$))',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final left = match.group(1)?.trim();
    final right = match.group(2)?.trim();

    final value = isLeft ? left : right;
    return _cleanTypeValue(value);
  }

  String? _extractArchType(String text, {required bool isLeft}) {
    final patterns = <RegExp>[
      // Page 1 extracted text:
      // Left foot Right foot Severe Flat Arch Type Severe Flat
      RegExp(
        r'Left foot\s+Right foot\s+(.+?)\s+Arch Type\s+(.+?)(?=\s+\d|\s+low|\s+high|\s+High arch foot|\s+Arch height|$)',
        caseSensitive: false,
      ),

      // More direct:
      // Severe Flat Arch Type Severe Flat
      RegExp(
        r'(.+?)\s+Arch Type\s+(.+?)(?=\s+\d|\s+low|\s+high|\s+High arch foot|\s+Arch height|$)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = isLeft ? match.group(1) : match.group(2);
      return _cleanTypeValue(raw);
    }

    return null;
  }

  double? _extractArchIndex(String text, {required bool isLeft}) {
    final pattern = RegExp(
      '(${_numberPattern})\\s+Arch Index\\s+(${_numberPattern})',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final raw = isLeft ? match.group(1) : match.group(2);
    return _toDouble(raw);
  }

  double? _extractArchWidthIndex(String text, {required bool isLeft}) {
    final patterns = <RegExp>[
      RegExp(
        '($_numberPattern)\\s+Arch\\s+width\\s+Index\\s+($_numberPattern)',
        caseSensitive: false,
      ),
      RegExp(
        '($_numberPattern)\\s+Arch\\s+Width\\s+Index\\s+($_numberPattern)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = isLeft ? match.group(1) : match.group(2);
      return _toDouble(raw);
    }

    return null;
  }

  String? _extractNamedType(
    String text,
    String label, {
    required bool isLeft,
  }) {
    final escapedLabel = _labelPattern(label);

    final patterns = <RegExp>[
      RegExp(
        r'([A-Za-zÇĞİÖŞÜçğıöşü\s]+?)\s+' +
            escapedLabel +
            r'\s+([A-Za-zÇĞİÖŞÜçğıöşü\s]+?)(?=\s+-?\d|\s+Evaluation criteria|\s+Normal:|\s+Schematic|\s+tel:|\s+Item description|\s+Service demand|$)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;

      final raw = isLeft ? match.group(1) : match.group(2);
      return _cleanTypeValue(raw);
    }

    return null;
  }

  String _labelPattern(String label) {
    final normalizedLabel = label
        .replaceAll('Hallgux', 'Hall(?:u|gu)x')
        .replaceAll('Hallux', 'Hall(?:u|gu)x');

    final parts = normalizedLabel.trim().split(RegExp(r'\s+'));

    final escapedParts = parts.map((part) {
      if (part.contains('(?:')) return part;

      final lower = part.toLowerCase();
      final escaped = RegExp.escape(part);

      if (lower == 'angle') {
        return r'angle\s*(?:\([^)]*\))?';
      }

      if (lower == 'height') {
        return r'height\s*(?:\([^)]*\))?';
      }

      if (lower == 'length') {
        return r'length\s*(?:\([^)]*\))?';
      }

      if (lower == 'width') {
        return r'width\s*';
      }

      if (lower == 'type') {
        return r'type';
      }

      return escaped;
    }).toList();

    return escapedParts.join(r'\s+');
  }

  String? _cleanTypeValue(String? value) {
    if (value == null) return null;

    var cleaned = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^(Left foot|Right foot)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+(Left foot|Right foot)$', caseSensitive: false), '')
        .trim();

    cleaned = cleaned
        .replaceAll(RegExp(r'\s+Evaluation criteria.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Normal:.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Schematic.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Item description.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Service demand.*$', caseSensitive: false), '')
        .trim();

    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  double? _toDouble(String? value) {
    if (value == null) return null;
    return double.tryParse(value.replaceAll(',', '.').trim());
  }

  String get _numberPattern => r'-?\d+(?:\.\d+)?';
}