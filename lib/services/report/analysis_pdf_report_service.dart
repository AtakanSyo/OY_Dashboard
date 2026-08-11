import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_codec;
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class AnalysisPdfReportService {
  static final _teal = PdfColor(0, 121, 107);
  static final _indigo = PdfColor(57, 73, 171);
  static final _dark = PdfColor(38, 50, 56);
  static final _muted = PdfColor(96, 125, 139);
  static final _line = PdfColor(220, 226, 230);
  static final _soft = PdfColor(244, 248, 248);

  Future<bool> saveReport({
    required CustomerAnalysisResult result,
    required String pageTitle,
    required Map<String, String> imageUrls,
    Map<String, Uint8List> imageBytes = const {},
    ParsedScanReport? reportOverride,
  }) async {
    final bytes = await buildReport(
      result: result,
      pageTitle: pageTitle,
      imageUrls: imageUrls,
      imageBytes: imageBytes,
      reportOverride: reportOverride,
    );

    final path = await FilePicker.saveFile(
      dialogTitle: 'Analiz raporunu kaydet',
      fileName: '${_safeFileName(result.sessionCode)}_ayak_analiz_raporu.pdf',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    // Web'de tarayıcı indirmeyi başlatır ancak yerel dosya yolu döndürmez.
    return kIsWeb || path != null;
  }

  Future<Uint8List> buildReport({
    required CustomerAnalysisResult result,
    required String pageTitle,
    required Map<String, String> imageUrls,
    Map<String, Uint8List> imageBytes = const {},
    ParsedScanReport? reportOverride,
  }) async {
    final regularBytes = (await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    )).buffer.asUint8List();
    final boldBytes = (await rootBundle.load(
      'assets/fonts/Roboto-Bold.ttf',
    )).buffer.asUint8List();

    final regular = PdfTrueTypeFont(regularBytes, 9);
    final small = PdfTrueTypeFont(regularBytes, 7.5);
    final bold = PdfTrueTypeFont(boldBytes, 9, style: PdfFontStyle.bold);
    final titleFont = PdfTrueTypeFont(boldBytes, 21, style: PdfFontStyle.bold);
    final sectionFont = PdfTrueTypeFont(
      boldBytes,
      13,
      style: PdfFontStyle.bold,
    );

    final document = PdfDocument();
    document.pageSettings
      ..size = PdfPageSize.a4
      ..margins.all = 34;

    final footer = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, PdfPageSize.a4.width, 24),
    );
    footer.graphics.drawString(
      'OptiYou - Ayak Sağlığı Değerlendirme Raporu',
      small,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(34, 4, 350, 14),
    );
    final pageNumber = PdfPageNumberField(
      font: small,
      brush: PdfSolidBrush(_muted),
    );
    final pageCount = PdfPageCountField(
      font: small,
      brush: PdfSolidBrush(_muted),
    );
    final pageField = PdfCompositeField(
      font: small,
      brush: PdfSolidBrush(_muted),
      text: 'Sayfa {0} / {1}',
      fields: <PdfAutomaticField>[pageNumber, pageCount],
    );
    pageField.bounds = Rect.fromLTWH(0, 0, 80, 14);
    pageField.draw(footer.graphics, Offset(PdfPageSize.a4.width - 114, 4));
    document.template.bottom = footer;

    var page = document.pages.add();
    var y = 0.0;
    final width = page.getClientSize().width;

    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(0, 0, 7, 70),
    );
    page.graphics.drawString(
      _normalizedTitle(pageTitle),
      titleFont,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(22, 3, width - 22, 30),
    );
    page.graphics.drawString(
      'Sol ve sağ ayak karşılaştırmalı değerlendirme raporu',
      regular,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(22, 37, width - 22, 18),
    );
    page.graphics.drawString(
      '${result.sessionCode}  |  ${_date(result.analysisDate)}  |  '
      '${result.locationLabel.trim().isEmpty ? 'Konum belirtilmedi' : result.locationLabel}',
      bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(22, 57, width - 22, 18),
    );
    y = 88;

    final report = reportOverride ?? result.parsedReport;
    if ((report?.customerName ?? '').trim().isNotEmpty) {
      y = _drawInfoBox(
        page,
        y,
        width,
        'Danışan',
        report!.customerName!.trim(),
        bold,
        regular,
      );
    }

    final anatomyRows = <List<String>>[
      [
        'Ayak Uzunluğu',
        _mm(report?.leftFootLength),
        _mm(report?.rightFootLength),
      ],
      [
        'Taban Uzunluğu',
        _mm(report?.leftSoleLength),
        _mm(report?.rightSoleLength),
      ],
      [
        'Ayak Genişliği',
        _mm(report?.leftFootWidth),
        _mm(report?.rightFootWidth),
      ],
      [
        'Parmak Önü Genişliği',
        _mm(report?.leftToeWidth),
        _mm(report?.rightToeWidth),
      ],
      [
        'Ark Uzunluğu',
        _mm(report?.leftArchLength),
        _mm(report?.rightArchLength),
      ],
      [
        'Ark Yüksekliği',
        _mm(report?.leftArchHeight),
        _mm(report?.rightArchHeight),
      ],
      [
        'Dış Ark Genişliği',
        _mm(report?.leftArchOutsideWidth),
        _mm(report?.rightArchOutsideWidth),
      ],
      [
        'Topuk Genişliği',
        _mm(report?.leftTotalHeelWidth),
        _mm(report?.rightTotalHeelWidth),
      ],
      [
        '1. Metatars Uzunluğu',
        _mm(report?.leftFirstMetaLength),
        _mm(report?.rightFirstMetaLength),
      ],
      [
        '5. Metatars Uzunluğu',
        _mm(report?.leftFifthMetaLength),
        _mm(report?.rightFifthMetaLength),
      ],
      [
        'Metatars Eklem Yüksekliği',
        _mm(report?.leftFirstMetaJointHeight),
        _mm(report?.rightFirstMetaJointHeight),
      ],
    ];
    y = _drawSectionTitle(
      page,
      y,
      page.getClientSize().width,
      'Açıklamalar ve Öneriler',
      sectionFont,
    );
    y = _drawNarrativeComparison(
      document,
      page,
      y,
      'Denge ve Pronasyon',
      _text(result.leftFoot.balanceSummary),
      _text(result.rightFoot.balanceSummary),
      regular,
      bold,
    );
    page = document.pages[document.pages.count - 1];
    y = _drawNarrativeComparison(
      document,
      page,
      y,
      'İç Taban Önerisi',
      _text(report?.leftInsoleRecommendation, report?.recommendationText),
      _text(report?.rightInsoleRecommendation, report?.recommendationText),
      regular,
      bold,
    );

    final downloadedImages = <String, Uint8List>{
      ...await _downloadImages(imageUrls),
      ...imageBytes,
    };
    if (downloadedImages.isNotEmpty) {
      page = document.pages.add();
      y = _drawSectionTitle(
        page,
        0,
        page.getClientSize().width,
        'Tarama Görselleri',
        sectionFont,
      );
      y = _drawVisualAssessmentSections(
        document,
        page,
        y,
        downloadedImages,
        report,
        regular,
        bold,
        sectionFont,
      );
    }

    final hasGeneralEvaluation =
        result.overallSummary.trim().isNotEmpty ||
        result.generalRiskNote.trim().isNotEmpty;
    if (hasGeneralEvaluation) {
      page = document.pages.add();
      y = _drawSectionTitle(
        page,
        0,
        page.getClientSize().width,
        'Genel Değerlendirme',
        sectionFont,
      );
      if (result.overallSummary.trim().isNotEmpty) {
        y = _drawParagraph(
          page,
          y,
          'Genel Özet',
          result.overallSummary,
          regular,
          bold,
        );
      }
      if (result.generalRiskNote.trim().isNotEmpty) {
        y = _drawParagraph(
          page,
          y + 10,
          'Dikkat Notu',
          result.generalRiskNote,
          regular,
          bold,
        );
      }
    }

    if (!hasGeneralEvaluation) {
      page = document.pages.add();
      y = 0;
    } else if (y + 500 > page.getClientSize().height) {
      page = document.pages.add();
      y = 0;
    } else {
      y += 22;
    }
    y = _drawSectionTitle(
      page,
      y,
      page.getClientSize().width,
      'Anatomik Ölçümler',
      sectionFont,
    );
    _drawComparisonGrid(document, page, y, anatomyRows, regular, bold);

    final output = Uint8List.fromList(await document.save());
    document.dispose();
    return output;
  }

  double _drawSectionTitle(
    PdfPage page,
    double y,
    double width,
    String title,
    PdfFont font,
  ) {
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_soft),
      bounds: Rect.fromLTWH(0, y, width, 30),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(0, y, 4, 30),
    );
    page.graphics.drawString(
      title,
      font,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(13, y + 7, width - 13, 18),
    );
    return y + 40;
  }

  double _drawComparisonGrid(
    PdfDocument document,
    PdfPage page,
    double y,
    List<List<String>> rows,
    PdfFont regular,
    PdfFont bold,
  ) {
    final grid = PdfGrid();
    grid.columns.add(count: 3);
    grid.headers.add(1);
    final header = grid.headers[0];
    header.cells[0].value = 'Sol Ayak';
    header.cells[1].value = 'Ölçüm / Bulgu';
    header.cells[2].value = 'Sağ Ayak';
    for (final rowData in rows) {
      final row = grid.rows.add();
      row.cells[0].value = rowData[1];
      row.cells[1].value = rowData[0];
      row.cells[2].value = rowData[2];
    }
    grid.columns[0].width = 150;
    grid.columns[1].width = 195;
    grid.columns[2].width = 150;
    grid.style = PdfGridStyle(
      font: regular,
      cellPadding: PdfPaddings(left: 8, right: 8, top: 7, bottom: 7),
    );
    for (var i = 0; i < header.cells.count; i++) {
      header.cells[i].style = PdfGridCellStyle(
        backgroundBrush: PdfSolidBrush(i == 2 ? _indigo : _teal),
        textBrush: PdfBrushes.white,
        font: bold,
      );
      header.cells[i].stringFormat = PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      );
    }
    for (var rowIndex = 0; rowIndex < grid.rows.count; rowIndex++) {
      final row = grid.rows[rowIndex];
      row.cells[0].style.textBrush = PdfSolidBrush(_teal);
      row.cells[1].style.font = bold;
      row.cells[2].style.textBrush = PdfSolidBrush(_indigo);
      for (var i = 0; i < 3; i++) {
        row.cells[i].style.borders = PdfBorders(
          left: PdfPen(_line),
          right: PdfPen(_line),
          top: PdfPen(_line),
          bottom: PdfPen(_line),
        );
        row.cells[i].stringFormat = PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        );
      }
    }
    final result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, y, 0, 0),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    );
    return result?.bounds.bottom ?? y;
  }

  double _drawNarrativeComparison(
    PdfDocument document,
    PdfPage page,
    double y,
    String title,
    String left,
    String right,
    PdfFont regular,
    PdfFont bold,
  ) {
    final grid = PdfGrid();
    grid.columns.add(count: 3);
    final row = grid.rows.add();
    row.cells[0].value = left;
    row.cells[1].value = title;
    row.cells[2].value = right;
    grid.columns[0].width = 200;
    grid.columns[1].width = 95;
    grid.columns[2].width = 200;
    grid.style = PdfGridStyle(
      font: regular,
      cellPadding: PdfPaddings(left: 8, right: 8, top: 8, bottom: 8),
    );
    row.cells[0].style.textBrush = PdfSolidBrush(_teal);
    row.cells[1].style
      ..font = bold
      ..backgroundBrush = PdfSolidBrush(_soft);
    row.cells[2].style.textBrush = PdfSolidBrush(_indigo);
    for (var i = 0; i < 3; i++) {
      row.cells[i].style.borders = PdfBorders(
        left: PdfPen(_line),
        right: PdfPen(_line),
        top: PdfPen(_line),
        bottom: PdfPen(_line),
      );
      row.cells[i].stringFormat = PdfStringFormat(
        alignment: i == 2 ? PdfTextAlignment.right : PdfTextAlignment.left,
        lineAlignment: PdfVerticalAlignment.middle,
      );
    }
    final result = grid.draw(
      page: page,
      bounds: Rect.fromLTWH(0, y + 8, 0, 0),
      format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
    );
    return (result?.bounds.bottom ?? y) + 2;
  }

  double _drawInfoBox(
    PdfPage page,
    double y,
    double width,
    String label,
    String value,
    PdfFont bold,
    PdfFont regular,
  ) {
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_soft),
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(0, y, width, 34),
    );
    page.graphics.drawString(
      '$label: ',
      bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(10, y + 10, 65, 14),
    );
    page.graphics.drawString(
      value,
      regular,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(75, y + 10, width - 85, 14),
    );
    return y + 46;
  }

  double _drawParagraph(
    PdfPage page,
    double y,
    String title,
    String text,
    PdfFont regular,
    PdfFont bold,
  ) {
    page.graphics.drawString(
      title,
      bold,
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(0, y, page.getClientSize().width, 18),
    );
    final result =
        PdfTextElement(
          text: text,
          font: regular,
          brush: PdfSolidBrush(_dark),
          format: PdfStringFormat(lineSpacing: 3),
        ).draw(
          page: page,
          bounds: Rect.fromLTWH(0, y + 22, page.getClientSize().width, 0),
          format: PdfLayoutFormat(layoutType: PdfLayoutType.paginate),
        );
    return result?.bounds.bottom ?? y + 45;
  }

  Future<Map<String, Uint8List>> _downloadImages(
    Map<String, String> urls,
  ) async {
    final result = <String, Uint8List>{};
    for (final entry in urls.entries) {
      try {
        final data = await NetworkAssetBundle(Uri.parse(entry.value)).load('');
        result[entry.key] = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
      } catch (_) {
        // Görsel indirilemezse rapor metin ve ölçümlerle üretilmeye devam eder.
      }
    }
    return result;
  }

  double _drawVisualAssessmentSections(
    PdfDocument document,
    PdfPage page,
    double y,
    Map<String, Uint8List> images,
    ParsedScanReport? report,
    PdfFont regular,
    PdfFont bold,
    PdfFont sectionFont,
  ) {
    final sections =
        <
          ({
            String title,
            List<List<String>> imagePairs,
            List<List<String>> rows,
          })
        >[
          (
            title: 'Ark ve Kemer Yapısı',
            imagePairs: const [
              ['Ark Görünümü', 'arch_left_image', 'arch_right_image'],
              ['Ark Kesiti', 'arch_section_left', 'arch_section_right'],
            ],
            rows: [
              [
                'Ark Tipi',
                _archAssessment(report?.leftArchIndex),
                _archAssessment(report?.rightArchIndex),
              ],
              [
                'Ark İndeksi',
                _decimal(report?.leftArchIndex),
                _decimal(report?.rightArchIndex),
              ],
              [
                'Ark Genişlik İndeksi',
                _decimal(report?.leftArchWidthIndex),
                _decimal(report?.rightArchWidthIndex),
              ],
            ],
          ),
          (
            title: 'Başparmak Hizalanması',
            imagePairs: const [
              ['Ayak Görünümü', 'foot_2d_left', 'foot_2d_right'],
            ],
            rows: [
              [
                'Halluks Tipi',
                _angleAssessment(report?.leftHalluxAngle, 10, 20, 30),
                _angleAssessment(report?.rightHalluxAngle, 10, 20, 30),
              ],
              [
                'Halluks Açısı',
                _degree(report?.leftHalluxAngle),
                _degree(report?.rightHalluxAngle),
              ],
            ],
          ),
          (
            title: 'Arka Ayak ve Diz Hizalanması',
            imagePairs: const [
              ['Ayak-Bilek Hizalanması', 'pronator_left', 'pronator_right'],
            ],
            rows: [
              [
                'Topuk Tipi',
                _angleAssessment(report?.leftPronatorAngle, 4, 8, 15),
                _angleAssessment(report?.rightPronatorAngle, 4, 8, 15),
              ],
              [
                'Pronasyon Açısı',
                _degree(report?.leftPronatorAngle),
                _degree(report?.rightPronatorAngle),
              ],
              [
                'Diz Hizalanması',
                _angleAssessment(report?.leftKneeAngle, 4, 8, 15),
                _angleAssessment(report?.rightKneeAngle, 4, 8, 15),
              ],
              [
                'Diz Açısı',
                _degree(report?.leftKneeAngle),
                _degree(report?.rightKneeAngle),
              ],
            ],
          ),
        ];

    for (final section in sections) {
      final availablePairs = section.imagePairs.where((pair) {
        return images[pair[1]] != null || images[pair[2]] != null;
      }).toList();
      if (availablePairs.isEmpty) continue;

      final requiredHeight =
          50.0 + availablePairs.length * 212.0 + section.rows.length * 38.0;
      if (y + requiredHeight > page.getClientSize().height) {
        page = document.pages.add();
        y = 0;
      }
      y = _drawSectionTitle(
        page,
        y,
        page.getClientSize().width,
        section.title,
        sectionFont,
      );

      for (final pair in availablePairs) {
        if (y + 215 > page.getClientSize().height) {
          page = document.pages.add();
          y = 0;
        }
        final width = page.getClientSize().width;
        final columnWidth = (width - 18) / 2;
        page.graphics.drawString(
          pair[0],
          bold,
          brush: PdfSolidBrush(_dark),
          bounds: Rect.fromLTWH(0, y, width, 18),
        );
        y += 22;
        _drawImageCell(
          page,
          0,
          y,
          columnWidth,
          images[pair[1]],
          'Sol Ayak',
          regular,
        );
        _drawImageCell(
          page,
          columnWidth + 18,
          y,
          columnWidth,
          images[pair[2]],
          'Sağ Ayak',
          regular,
        );
        y += 190;
      }

      page = document.pages[document.pages.count - 1];
      y = _drawComparisonGrid(
        document,
        page,
        y + 4,
        section.rows,
        regular,
        bold,
      );
      page = document.pages[document.pages.count - 1];
      y += 18;
    }
    return y;
  }

  void _drawImageCell(
    PdfPage page,
    double x,
    double y,
    double width,
    Uint8List? bytes,
    String label,
    PdfFont font,
  ) {
    page.graphics.drawRectangle(
      pen: PdfPen(_line),
      brush: PdfSolidBrush(_soft),
      bounds: Rect.fromLTWH(x, y, width, 176),
    );
    page.graphics.drawString(
      label,
      font,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(x + 8, y + 7, width - 16, 14),
    );
    if (bytes == null) return;
    try {
      final bitmap = PdfBitmap(_pdfCompatibleImage(bytes));
      final imageSize = bitmap.physicalDimension;
      final availableWidth = width - 16;
      const availableHeight = 140.0;
      final scale = mathMin(
        availableWidth / imageSize.width,
        availableHeight / imageSize.height,
      );
      final drawWidth = imageSize.width * scale;
      final drawHeight = imageSize.height * scale;
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(
          x + (width - drawWidth) / 2,
          y + 28 + (availableHeight - drawHeight) / 2,
          drawWidth,
          drawHeight,
        ),
      );
    } catch (_) {
      // Desteklenmeyen görsel rapor üretimini engellemez.
    }
  }

  Uint8List _pdfCompatibleImage(Uint8List bytes) {
    if (_isPng(bytes) || _isJpeg(bytes)) return bytes;

    final decoded = image_codec.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Görsel formatı çözümlenemedi.');
    }
    return image_codec.encodePng(decoded);
  }

  bool _isPng(Uint8List bytes) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  bool _isJpeg(Uint8List bytes) =>
      bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

  static double mathMin(double a, double b) => a < b ? a : b;

  static String _normalizedTitle(String value) {
    final title = value.trim();
    return title.isEmpty ? 'Ayak Sağlığı Değerlendirmesi' : title;
  }

  static String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return normalized.isEmpty ? 'analiz' : normalized;
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  static String _mm(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)} mm';

  static String _degree(double? value) =>
      value == null ? '—' : '${value.abs().toStringAsFixed(1)}°';

  static String _decimal(double? value) =>
      value == null ? '—' : value.toStringAsFixed(3);

  static String _archAssessment(double? value) {
    if (value == null) return 'Veri bulunmuyor';
    if (value < 0.21) return 'Yüksek Ark';
    if (value <= 0.26) return 'Normal Ark';
    if (value <= 0.28) return 'Hafif Düz Taban';
    if (value <= 0.30) return 'Orta Düzey Düz Taban';
    return 'İleri Düzey Düz Taban';
  }

  static String _angleAssessment(
    double? value,
    double mild,
    double moderate,
    double severe,
  ) {
    if (value == null) return 'Veri bulunmuyor';
    final magnitude = value.abs();
    if (magnitude < mild) return 'Normal';
    if (magnitude < moderate) return 'Hafif';
    if (magnitude < severe) return 'Orta Düzey';
    return 'İleri Düzey';
  }

  static String _text(String? value, [String? fallback]) {
    final normalized = (value ?? '').trim();
    if (normalized.isNotEmpty) return _turkishAssessment(normalized);
    final alternative = (fallback ?? '').trim();
    return alternative.isEmpty ? '—' : _turkishAssessment(alternative);
  }

  static String _turkishAssessment(String value) {
    var translated = value;
    const replacements = <String, String>{
      'Severe Flat': 'İleri Düzey Düz Taban',
      'Moderate Flat': 'Orta Düzey Düz Taban',
      'Mild Flat': 'Hafif Düz Taban',
      'Normal Hallgux': 'Normal Halluks',
      'Normal Hallux': 'Normal Halluks',
      'Normal Heel': 'Normal Topuk',
      'High Arch': 'Yüksek Ark',
      'Normal Arch': 'Normal Ark',
      'Severe': 'İleri Düzey',
      'Moderate': 'Orta Düzey',
      'Mild': 'Hafif',
      'Neutral': 'Nötr',
    };
    for (final entry in replacements.entries) {
      translated = translated.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        entry.value,
      );
    }
    return translated;
  }
}
