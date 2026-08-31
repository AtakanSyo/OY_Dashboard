import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/scan/legacy_doc_text_extractor.dart';
import 'package:oy_site/services/scan/scan_report_text_parser.dart';

class ScanReportWordParserService {
  final LegacyDocTextExtractor _textExtractor;
  final ScanReportTextParser _scanReportTextParser;

  const ScanReportWordParserService({
    LegacyDocTextExtractor textExtractor = const LegacyDocTextExtractor(),
    ScanReportTextParser scanReportTextParser = const ScanReportTextParser(),
  }) : _textExtractor = textExtractor,
       _scanReportTextParser = scanReportTextParser;

  Future<ParsedScanReport> parseWordFile(String filePath) async {
    final rawText = await _textExtractor.extractText(filePath);
    final report = _scanReportTextParser.parse(rawText);

    if (!_hasMinimumReportData(report)) {
      throw const FormatException(
        'Word raporu okundu ancak yeterli ölçüm alanı ayrıştırılamadı.',
      );
    }

    return report;
  }

  bool _hasMinimumReportData(ParsedScanReport report) {
    final measurements = <double?>[
      report.leftFootLength,
      report.rightFootLength,
      report.leftFootWidth,
      report.rightFootWidth,
      report.leftArchHeight,
      report.rightArchHeight,
      report.leftHalluxAngle,
      report.rightHalluxAngle,
      report.leftPronatorAngle,
      report.rightPronatorAngle,
    ];

    return measurements.whereType<double>().length >= 6;
  }
}
