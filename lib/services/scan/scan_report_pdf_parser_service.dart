import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/scan/pdf_text_extractor.dart';
import 'package:oy_site/services/scan/scan_report_text_parser.dart';

class ScanReportPdfParserService {
  final PdfTextExtractorService _pdfTextExtractorService;
  final ScanReportTextParser _scanReportTextParser;

  const ScanReportPdfParserService({
    PdfTextExtractorService pdfTextExtractorService =
        const PdfTextExtractorService(),
    ScanReportTextParser scanReportTextParser =
        const ScanReportTextParser(),
  })  : _pdfTextExtractorService = pdfTextExtractorService,
        _scanReportTextParser = scanReportTextParser;

  Future<ParsedScanReport> parsePdfFile(String filePath) async {
    final rawText = await _pdfTextExtractorService.extractText(filePath);
    return _scanReportTextParser.parse(rawText);
  }
}