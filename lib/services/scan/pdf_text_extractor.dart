import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfTextExtractorService {
  const PdfTextExtractorService();

  Future<String> extractText(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);

    final text = extractor.extractText();

    document.dispose();

    return text;
  }
}