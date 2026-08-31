import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_codec;
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/analysis/hallux_heat_position_mapper.dart';
import 'package:oy_site/services/analysis/arch_width_coefficient_mapper.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// The pressure frame that is visible on the analysis screen while the PDF is
/// being exported.
class AnalysisPdfPressureSnapshot {
  final List<List<double>> matrix;
  final double maxVisualValue;
  final double threshold;
  final double? weightKg;
  final double? cellAreaCm2;

  const AnalysisPdfPressureSnapshot({
    required this.matrix,
    required this.maxVisualValue,
    required this.threshold,
    this.weightKg,
    this.cellAreaCm2,
  });
}

class AnalysisPdfReportService {
  static final _teal = PdfColor(0, 121, 107);
  static final _indigo = PdfColor(57, 73, 171);
  static final _dark = PdfColor(38, 50, 56);
  static final _muted = PdfColor(96, 125, 139);
  static final _line = PdfColor(220, 226, 230);
  static final _soft = PdfColor(246, 249, 250);
  static final _tealSoft = PdfColor(232, 245, 243);
  static final _indigoSoft = PdfColor(238, 240, 252);

  Future<bool> saveReport({
    required CustomerAnalysisResult result,
    required String pageTitle,
    required Map<String, String> imageUrls,
    Map<String, Uint8List> imageBytes = const {},
    ParsedScanReport? reportOverride,
    AnalysisPdfPressureSnapshot? pressureSnapshot,
    String languageCode = 'tr',
  }) async {
    final copy = _PdfCopy(languageCode);
    final bytes = await buildReport(
      result: result,
      pageTitle: pageTitle,
      imageUrls: imageUrls,
      imageBytes: imageBytes,
      reportOverride: reportOverride,
      pressureSnapshot: pressureSnapshot,
      languageCode: languageCode,
    );

    final path = await FilePicker.saveFile(
      dialogTitle: copy.saveDialogTitle,
      fileName:
          '${_safeFileName(result.sessionCode)}_${copy.fileNameSuffix}.pdf',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );

    // On the web, the browser starts the download but does not return a path.
    return kIsWeb || path != null;
  }

  Future<Uint8List> buildReport({
    required CustomerAnalysisResult result,
    required String pageTitle,
    required Map<String, String> imageUrls,
    Map<String, Uint8List> imageBytes = const {},
    ParsedScanReport? reportOverride,
    AnalysisPdfPressureSnapshot? pressureSnapshot,
    String languageCode = 'tr',
  }) async {
    final copy = _PdfCopy(languageCode);
    final report = reportOverride ?? result.parsedReport;
    final downloadedImages = <String, Uint8List>{
      ...await _downloadImages(imageUrls),
      ...imageBytes,
    };

    final regularBytes = (await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    )).buffer.asUint8List();
    final boldBytes = (await rootBundle.load(
      'assets/fonts/Roboto-Bold.ttf',
    )).buffer.asUint8List();

    final fonts = _PdfFonts(
      regular: PdfTrueTypeFont(regularBytes, 8.5),
      small: PdfTrueTypeFont(regularBytes, 7.2),
      bold: PdfTrueTypeFont(boldBytes, 8.5, style: PdfFontStyle.bold),
      metric: PdfTrueTypeFont(boldBytes, 13, style: PdfFontStyle.bold),
      panel: PdfTrueTypeFont(boldBytes, 11.5, style: PdfFontStyle.bold),
      section: PdfTrueTypeFont(boldBytes, 13.5, style: PdfFontStyle.bold),
      title: PdfTrueTypeFont(boldBytes, 20, style: PdfFontStyle.bold),
    );

    final document = PdfDocument();
    document.pageSettings
      ..size = PdfPageSize.a4
      ..margins.all = 30;
    _configureFooter(document, fonts, copy);

    final layout = _PdfLayout(document: document, fonts: fonts);
    layout.addPage();

    _drawReportHeader(
      layout,
      title: _normalizedTitle(pageTitle, copy),
      result: result,
      customerName: report?.customerName,
      copy: copy,
    );

    _drawSectionHeading(
      layout,
      copy.findingsAndImages,
      copy.findingsAndImagesSubtitle,
      minimumFollowingHeight: 245,
    );
    _drawArchSection(layout, downloadedImages, report, copy);
    _drawHalluxSection(layout, downloadedImages, report, copy);
    _drawPronationSection(layout, downloadedImages, report, copy);

    _drawSectionHeading(
      layout,
      copy.plantarPressureMeasurements,
      copy.plantarPressureSubtitle,
      minimumFollowingHeight: 297,
    );
    _drawPressureSection(layout, pressureSnapshot, copy);

    _drawSectionHeading(
      layout,
      copy.anatomicalMeasurements,
      copy.anatomicalMeasurementsSubtitle,
      minimumFollowingHeight: 70,
    );
    _drawAnatomicalMeasurements(layout, report, copy);

    _drawSectionHeading(
      layout,
      copy.productAssessment,
      copy.productAssessmentSubtitle,
      minimumFollowingHeight: 84,
    );
    _drawProductAssessment(layout, copy);

    final output = Uint8List.fromList(await document.save());
    document.dispose();
    return output;
  }

  void _configureFooter(PdfDocument document, _PdfFonts fonts, _PdfCopy copy) {
    final footer = PdfPageTemplateElement(
      Rect.fromLTWH(0, 0, PdfPageSize.a4.width, 24),
    );
    footer.graphics.drawString(
      copy.footerTitle,
      fonts.small,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(30, 5, 330, 12),
    );
    final pageNumber = PdfPageNumberField(
      font: fonts.small,
      brush: PdfSolidBrush(_muted),
    );
    final pageCount = PdfPageCountField(
      font: fonts.small,
      brush: PdfSolidBrush(_muted),
    );
    final pageField = PdfCompositeField(
      font: fonts.small,
      brush: PdfSolidBrush(_muted),
      text: copy.pageCounter,
      fields: <PdfAutomaticField>[pageNumber, pageCount],
    );
    pageField.bounds = Rect.fromLTWH(0, 0, 86, 12);
    pageField.draw(footer.graphics, Offset(PdfPageSize.a4.width - 116, 5));
    document.template.bottom = footer;
  }

  void _drawReportHeader(
    _PdfLayout layout, {
    required String title,
    required CustomerAnalysisResult result,
    required String? customerName,
    required _PdfCopy copy,
  }) {
    const height = 126.0;
    final page = layout.page;
    final y = layout.y;
    final width = layout.width;

    page.graphics.drawRectangle(
      pen: PdfPen(_line),
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(0, y, width, height),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(0, y, 58, height),
    );
    page.graphics.drawString(
      'OY',
      layout.fonts.panel,
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(0, y + 49, 58, 22),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );

    page.graphics.drawString(
      title,
      layout.fonts.title,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(73, y + 13, 274, 29),
    );
    page.graphics.drawString(
      copy.assessmentIntro,
      layout.fonts.regular,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(73, y + 46, 270, 34),
      format: PdfStringFormat(lineSpacing: 2),
    );

    final normalizedCustomer = (customerName ?? '').trim();
    if (normalizedCustomer.isNotEmpty) {
      page.graphics.drawString(
        '${copy.client}: $normalizedCustomer',
        layout.fonts.bold,
        brush: PdfSolidBrush(_dark),
        bounds: Rect.fromLTWH(73, y + 91, 270, 17),
      );
    }

    final metadataX = width - 164;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_soft),
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(metadataX, y + 11, 151, 104),
    );
    _drawMetaLine(
      page,
      metadataX + 10,
      y + 21,
      131,
      copy.session,
      result.sessionCode,
      layout.fonts,
    );
    _drawMetaLine(
      page,
      metadataX + 10,
      y + 51,
      131,
      copy.date,
      _date(result.analysisDate, copy.isEnglish),
      layout.fonts,
    );
    _drawMetaLine(
      page,
      metadataX + 10,
      y + 81,
      131,
      copy.location,
      result.locationLabel.trim().isEmpty
          ? copy.locationNotSpecified
          : result.locationLabel.trim(),
      layout.fonts,
    );

    layout.y += height + 16;
  }

  void _drawMetaLine(
    PdfPage page,
    double x,
    double y,
    double width,
    String label,
    String value,
    _PdfFonts fonts,
  ) {
    page.graphics.drawString(
      label.toUpperCase(),
      fonts.small,
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(x, y, width, 10),
    );
    page.graphics.drawString(
      value,
      fonts.bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(x, y + 11, width, 14),
    );
  }

  void _drawSectionHeading(
    _PdfLayout layout,
    String title,
    String subtitle, {
    double minimumFollowingHeight = 0,
  }) {
    layout.ensureSpace(63 + minimumFollowingHeight);
    final y = layout.y;
    layout.page.graphics.drawRectangle(
      brush: PdfSolidBrush(_tealSoft),
      bounds: Rect.fromLTWH(0, y, layout.width, 51),
    );
    layout.page.graphics.drawRectangle(
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(0, y, 5, 51),
    );
    layout.page.graphics.drawString(
      title,
      layout.fonts.section,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(16, y + 8, layout.width - 26, 18),
    );
    layout.page.graphics.drawString(
      subtitle,
      layout.fonts.regular,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(16, y + 29, layout.width - 26, 14),
    );
    layout.y += 63;
  }

  void _drawFindingHeader(
    _PdfLayout layout,
    String title,
    String subtitle, {
    double minimumFollowingHeight = 160,
  }) {
    layout.ensureSpace(53 + minimumFollowingHeight);
    final y = layout.y;
    layout.page.graphics.drawRectangle(
      brush: PdfBrushes.white,
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(0, y, layout.width, 46),
    );
    layout.page.graphics.drawRectangle(
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(10, y + 9, 28, 28),
    );
    layout.page.graphics.drawString(
      title.substring(0, 1),
      layout.fonts.bold,
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(10, y + 9, 28, 28),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
    layout.page.graphics.drawString(
      title,
      layout.fonts.panel,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(48, y + 7, layout.width - 58, 17),
    );
    layout.page.graphics.drawString(
      subtitle,
      layout.fonts.small,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(48, y + 25, layout.width - 58, 13),
    );
    layout.y += 54;
  }

  void _drawArchSection(
    _PdfLayout layout,
    Map<String, Uint8List> images,
    ParsedScanReport? report,
    _PdfCopy copy,
  ) {
    _drawFindingHeader(
      layout,
      copy.archStructure,
      copy.archStructureSubtitle,
      minimumFollowingHeight: 225,
    );
    _drawImagePair(
      layout,
      copy.archHeightMap,
      images['arch_left_image'],
      images['arch_right_image'],
      copy,
      cellHeight: 190,
    );
    _drawAssessmentHeatBar(
      layout,
      title: copy.archIndex,
      leftLabel: _assessmentWithValue(
        _archAssessment(report?.leftArchIndex, copy),
        _decimal(report?.leftArchIndex),
      ),
      rightLabel: _assessmentWithValue(
        _archAssessment(report?.rightArchIndex, copy),
        _decimal(report?.rightArchIndex),
      ),
      leftPosition: _archHeatPosition(report?.leftArchIndex),
      rightPosition: _archHeatPosition(report?.rightArchIndex),
      copy: copy,
    );
    _drawImagePair(
      layout,
      copy.archSectionImage,
      images['arch_section_left'],
      images['arch_section_right'],
      copy,
      cellHeight: 104,
    );
    _drawAssessmentHeatBar(
      layout,
      title: copy.archWidthIndex,
      leftLabel: _assessmentWithValue(
        _archWidthAssessment(report?.leftArchWidthIndex, copy),
        _decimal(report?.leftArchWidthIndex),
      ),
      rightLabel: _assessmentWithValue(
        _archWidthAssessment(report?.rightArchWidthIndex, copy),
        _decimal(report?.rightArchWidthIndex),
      ),
      leftPosition: _archWidthHeatPosition(report?.leftArchWidthIndex),
      rightPosition: _archWidthHeatPosition(report?.rightArchWidthIndex),
      copy: copy,
    );
    _drawComparisonMetric(
      layout,
      copy.archHeight,
      _millimeter(report?.leftArchHeight),
      _millimeter(report?.rightArchHeight),
    );
    layout.y += 12;
  }

  void _drawHalluxSection(
    _PdfLayout layout,
    Map<String, Uint8List> images,
    ParsedScanReport? report,
    _PdfCopy copy,
  ) {
    _drawFindingHeader(
      layout,
      copy.footFormHallux,
      copy.footFormHalluxSubtitle,
      minimumFollowingHeight: 238,
    );
    _drawImagePair(
      layout,
      copy.footImage,
      images['foot_2d_left'],
      images['foot_2d_right'],
      copy,
      cellHeight: 210,
    );
    _drawAssessmentHeatBar(
      layout,
      title: copy.halluxAngleType,
      leftLabel: _assessmentWithValue(
        _angleAssessment(report?.leftHalluxAngle, 10, 20, 30, copy),
        _degree(report?.leftHalluxAngle),
      ),
      rightLabel: _assessmentWithValue(
        _angleAssessment(report?.rightHalluxAngle, 10, 20, 30, copy),
        _degree(report?.rightHalluxAngle),
      ),
      leftPosition: HalluxHeatPositionMapper.resolve(
        angle: report?.leftHalluxAngle,
        type: report?.leftHalluxType,
      ),
      rightPosition: HalluxHeatPositionMapper.resolve(
        angle: report?.rightHalluxAngle,
        type: report?.rightHalluxType,
      ),
      copy: copy,
    );
    _drawComparisonMetric(
      layout,
      copy.footWidth,
      _millimeter(report?.leftFootWidth),
      _millimeter(report?.rightFootWidth),
    );
    _drawComparisonMetric(
      layout,
      copy.toeWidth,
      _millimeter(report?.leftToeWidth),
      _millimeter(report?.rightToeWidth),
    );
    layout.y += 12;
  }

  void _drawPronationSection(
    _PdfLayout layout,
    Map<String, Uint8List> images,
    ParsedScanReport? report,
    _PdfCopy copy,
  ) {
    _drawFindingHeader(
      layout,
      copy.rearfootPronation,
      copy.rearfootPronationSubtitle,
      minimumFollowingHeight: 238,
    );
    _drawImagePair(
      layout,
      copy.ankleAlignment,
      images['pronator_left'],
      images['pronator_right'],
      copy,
      cellHeight: 210,
    );
    _drawAssessmentHeatBar(
      layout,
      title: copy.pronationAngleHeelType,
      leftLabel: _assessmentWithValue(
        _angleAssessment(report?.leftPronatorAngle, 4, 8, 15, copy),
        _degree(report?.leftPronatorAngle),
      ),
      rightLabel: _assessmentWithValue(
        _angleAssessment(report?.rightPronatorAngle, 4, 8, 15, copy),
        _degree(report?.rightPronatorAngle),
      ),
      leftPosition: _angleHeatPosition(report?.leftPronatorAngle, 15),
      rightPosition: _angleHeatPosition(report?.rightPronatorAngle, 15),
      copy: copy,
    );
    _drawAssessmentHeatBar(
      layout,
      title: copy.kneeAngleAlignment,
      leftLabel: _assessmentWithValue(
        _angleAssessment(report?.leftKneeAngle, 4, 8, 15, copy),
        _degree(report?.leftKneeAngle),
      ),
      rightLabel: _assessmentWithValue(
        _angleAssessment(report?.rightKneeAngle, 4, 8, 15, copy),
        _degree(report?.rightKneeAngle),
      ),
      leftPosition: _angleHeatPosition(report?.leftKneeAngle, 15),
      rightPosition: _angleHeatPosition(report?.rightKneeAngle, 15),
      copy: copy,
    );
    layout.y += 12;
  }

  void _drawImagePair(
    _PdfLayout layout,
    String title,
    Uint8List? leftBytes,
    Uint8List? rightBytes,
    _PdfCopy copy, {
    required double cellHeight,
  }) {
    final totalHeight = cellHeight + 31;
    layout.ensureSpace(totalHeight + 8);
    final page = layout.page;
    final y = layout.y;
    page.graphics.drawString(
      title,
      layout.fonts.bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(0, y, layout.width, 16),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    final cellWidth = (layout.width - 9) / 2;
    _drawImageCell(
      page,
      0,
      y + 22,
      cellWidth,
      cellHeight,
      leftBytes,
      copy.leftFoot,
      copy.imageUnavailable,
      layout.fonts,
    );
    _drawImageCell(
      page,
      cellWidth + 9,
      y + 22,
      cellWidth,
      cellHeight,
      rightBytes,
      copy.rightFoot,
      copy.imageUnavailable,
      layout.fonts,
    );
    layout.y += totalHeight + 8;
  }

  void _drawImageCell(
    PdfPage page,
    double x,
    double y,
    double width,
    double height,
    Uint8List? bytes,
    String label,
    String unavailableLabel,
    _PdfFonts fonts,
  ) {
    page.graphics.drawRectangle(
      pen: PdfPen(_line),
      brush: PdfSolidBrush(_soft),
      bounds: Rect.fromLTWH(x, y, width, height),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(label == unavailableLabel ? _muted : _tealSoft),
      bounds: Rect.fromLTWH(x, y, width, 22),
    );
    page.graphics.drawString(
      label,
      fonts.bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(x + 7, y + 6, width - 14, 12),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );

    if (bytes == null) {
      page.graphics.drawString(
        unavailableLabel,
        fonts.regular,
        brush: PdfSolidBrush(_muted),
        bounds: Rect.fromLTWH(x + 8, y + 22, width - 16, height - 22),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        ),
      );
      return;
    }

    try {
      final bitmap = PdfBitmap(_pdfCompatibleImage(bytes));
      final imageSize = bitmap.physicalDimension;
      final availableWidth = width - 14;
      final availableHeight = height - 30;
      final scale = math.min(
        availableWidth / imageSize.width,
        availableHeight / imageSize.height,
      );
      final drawWidth = imageSize.width * scale;
      final drawHeight = imageSize.height * scale;
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(
          x + (width - drawWidth) / 2,
          y + 26 + (availableHeight - drawHeight) / 2,
          drawWidth,
          drawHeight,
        ),
      );
    } catch (_) {
      page.graphics.drawString(
        unavailableLabel,
        fonts.regular,
        brush: PdfSolidBrush(_muted),
        bounds: Rect.fromLTWH(x + 8, y + 22, width - 16, height - 22),
        format: PdfStringFormat(
          alignment: PdfTextAlignment.center,
          lineAlignment: PdfVerticalAlignment.middle,
        ),
      );
    }
  }

  void _drawAssessmentHeatBar(
    _PdfLayout layout, {
    required String title,
    required String leftLabel,
    required String rightLabel,
    required double? leftPosition,
    required double? rightPosition,
    required _PdfCopy copy,
  }) {
    const height = 63.0;
    layout.ensureSpace(height + 8);
    final page = layout.page;
    final y = layout.y;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_soft),
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(0, y, layout.width, height),
    );
    page.graphics.drawString(
      title,
      layout.fonts.bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(10, y + 7, layout.width - 20, 13),
    );

    final sideWidth = (layout.width - 31) / 2;
    _drawHeatBarSide(
      page,
      x: 10,
      y: y + 24,
      width: sideWidth,
      side: copy.left,
      label: leftLabel,
      position: leftPosition,
      markerColor: _teal,
      fonts: layout.fonts,
    );
    _drawHeatBarSide(
      page,
      x: 21 + sideWidth,
      y: y + 24,
      width: sideWidth,
      side: copy.right,
      label: rightLabel,
      position: rightPosition,
      markerColor: _indigo,
      fonts: layout.fonts,
    );
    layout.y += height + 8;
  }

  void _drawHeatBarSide(
    PdfPage page, {
    required double x,
    required double y,
    required double width,
    required String side,
    required String label,
    required double? position,
    required PdfColor markerColor,
    required _PdfFonts fonts,
  }) {
    page.graphics.drawString(
      side,
      fonts.bold,
      brush: PdfSolidBrush(markerColor),
      bounds: Rect.fromLTWH(x, y, 40, 12),
    );
    page.graphics.drawString(
      label,
      fonts.small,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(x + 42, y, width - 42, 12),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );

    final barY = y + 18;
    const segments = 64;
    final segmentWidth = width / segments;
    for (var index = 0; index < segments; index++) {
      final normalized = index / (segments - 1);
      page.graphics.drawRectangle(
        brush: PdfSolidBrush(_assessmentColor(normalized)),
        bounds: Rect.fromLTWH(
          x + index * segmentWidth,
          barY,
          segmentWidth + 0.4,
          9,
        ),
      );
    }

    if (position != null) {
      final normalized = position.clamp(0.0, 1.0);
      final markerX = x + normalized * (width - 10);
      page.graphics.drawEllipse(
        Rect.fromLTWH(markerX, barY - 4, 10, 17),
        pen: PdfPen(markerColor, width: 2.2),
        brush: PdfBrushes.white,
      );
    }
  }

  void _drawComparisonMetric(
    _PdfLayout layout,
    String label,
    String leftValue,
    String rightValue, {
    String? description,
  }) {
    final height = description == null ? 47.0 : 56.0;
    layout.ensureSpace(height + 7);
    final y = layout.y;
    final page = layout.page;
    page.graphics.drawRectangle(
      brush: PdfBrushes.white,
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(0, y, layout.width, height),
    );

    const centerWidth = 205.0;
    final valueWidth = (layout.width - centerWidth) / 2;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_tealSoft),
      bounds: Rect.fromLTWH(1, y + 1, valueWidth - 1, height - 2),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_indigoSoft),
      bounds: Rect.fromLTWH(
        valueWidth + centerWidth,
        y + 1,
        valueWidth - 1,
        height - 2,
      ),
    );

    page.graphics.drawString(
      leftValue,
      layout.fonts.metric,
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(8, y + 10, valueWidth - 16, 22),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
    page.graphics.drawString(
      label,
      layout.fonts.bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(valueWidth + 8, y + 8, centerWidth - 16, 16),
      format: PdfStringFormat(alignment: PdfTextAlignment.center),
    );
    if (description != null) {
      page.graphics.drawString(
        description,
        layout.fonts.small,
        brush: PdfSolidBrush(_muted),
        bounds: Rect.fromLTWH(valueWidth + 8, y + 25, centerWidth - 16, 23),
        format: PdfStringFormat(alignment: PdfTextAlignment.center),
      );
    }
    page.graphics.drawString(
      rightValue,
      layout.fonts.metric,
      brush: PdfSolidBrush(_indigo),
      bounds: Rect.fromLTWH(
        valueWidth + centerWidth + 8,
        y + 10,
        valueWidth - 16,
        22,
      ),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
    layout.y += height + 7;
  }

  void _drawPressureSection(
    _PdfLayout layout,
    AnalysisPdfPressureSnapshot? snapshot,
    _PdfCopy copy,
  ) {
    if (snapshot == null || snapshot.matrix.isEmpty) {
      _drawEmptyState(layout, copy.noPressureData);
      return;
    }

    const height = 285.0;
    layout.ensureSpace(height + 12);
    final y = layout.y;
    final page = layout.page;
    final stats = _pressureStats(snapshot.matrix, snapshot.threshold);

    const summaryWidth = 157.0;
    page.graphics.drawRectangle(
      brush: PdfBrushes.white,
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(0, y, summaryWidth, height),
    );
    page.graphics.drawString(
      copy.loadDistribution,
      layout.fonts.panel,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(11, y + 12, summaryWidth - 22, 16),
    );

    var summaryY = y + 39;
    if (snapshot.weightKg != null) {
      _drawPressureValueCard(
        page,
        11,
        summaryY,
        summaryWidth - 22,
        copy.weight,
        '${snapshot.weightKg!.toStringAsFixed(1)} kg',
        layout.fonts,
      );
      summaryY += 54;
    }
    final total = stats.totalLoad;
    final left = total <= 0 ? 0.0 : stats.leftLoad / total;
    final forefoot = total <= 0 ? 0.0 : stats.forefootLoad / total;
    _drawDistribution(
      page,
      11,
      summaryY,
      summaryWidth - 22,
      copy.leftRightLoad,
      copy.left,
      copy.right,
      left,
      layout.fonts,
    );
    _drawDistribution(
      page,
      11,
      summaryY + 79,
      summaryWidth - 22,
      copy.forefootHeelLoad,
      copy.forefoot,
      copy.heel,
      forefoot,
      layout.fonts,
    );

    final heatmapX = summaryWidth + 10;
    final heatmapWidth = layout.width - heatmapX;
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_soft),
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(heatmapX, y, heatmapWidth, height),
    );
    page.graphics.drawString(
      copy.pressureHeatmap,
      layout.fonts.panel,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(heatmapX + 11, y + 12, heatmapWidth - 22, 16),
    );
    final heatmapBytes = _buildHeatmapImage(snapshot, stats);
    final bitmap = PdfBitmap(heatmapBytes);
    final availableWidth = heatmapWidth - 20;
    final availableHeight = height - 48;
    final aspectHeight = availableWidth * 344 / 452;
    final drawHeight = math.min(availableHeight, aspectHeight);
    final drawWidth = drawHeight * 452 / 344;
    page.graphics.drawImage(
      bitmap,
      Rect.fromLTWH(
        heatmapX + (heatmapWidth - drawWidth) / 2,
        y + 37 + (availableHeight - drawHeight) / 2,
        drawWidth,
        drawHeight,
      ),
    );
    layout.y += height + 12;
  }

  void _drawPressureValueCard(
    PdfPage page,
    double x,
    double y,
    double width,
    String label,
    String value,
    _PdfFonts fonts,
  ) {
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_indigoSoft),
      pen: PdfPen(PdfColor(215, 219, 242)),
      bounds: Rect.fromLTWH(x, y, width, 44),
    );
    page.graphics.drawString(
      value,
      fonts.metric,
      brush: PdfSolidBrush(_indigo),
      bounds: Rect.fromLTWH(x + 8, y + 7, width - 16, 18),
    );
    page.graphics.drawString(
      label,
      fonts.small,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(x + 8, y + 27, width - 16, 11),
    );
  }

  void _drawDistribution(
    PdfPage page,
    double x,
    double y,
    double width,
    String title,
    String firstLabel,
    String secondLabel,
    double firstRatio,
    _PdfFonts fonts,
  ) {
    final normalized = firstRatio.clamp(0.0, 1.0);
    page.graphics.drawString(
      title,
      fonts.bold,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(x, y, width, 24),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(x, y + 29, width * normalized, 10),
    );
    page.graphics.drawRectangle(
      brush: PdfSolidBrush(_indigo),
      bounds: Rect.fromLTWH(
        x + width * normalized,
        y + 29,
        width * (1 - normalized),
        10,
      ),
    );
    page.graphics.drawString(
      '$firstLabel %${(normalized * 100).toStringAsFixed(1)}',
      fonts.small,
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(x, y + 44, width / 2, 12),
    );
    page.graphics.drawString(
      '$secondLabel %${((1 - normalized) * 100).toStringAsFixed(1)}',
      fonts.small,
      brush: PdfSolidBrush(_indigo),
      bounds: Rect.fromLTWH(x + width / 2, y + 44, width / 2, 12),
      format: PdfStringFormat(alignment: PdfTextAlignment.right),
    );
  }

  void _drawAnatomicalMeasurements(
    _PdfLayout layout,
    ParsedScanReport? report,
    _PdfCopy copy,
  ) {
    final rows =
        <({String label, String left, String right, String description})>[
          (
            label: copy.footLength,
            left: _millimeter(report?.leftFootLength),
            right: _millimeter(report?.rightFootLength),
            description: copy.footLengthDescription,
          ),
          (
            label: copy.soleLength,
            left: _millimeter(report?.leftSoleLength),
            right: _millimeter(report?.rightSoleLength),
            description: copy.soleLengthDescription,
          ),
          (
            label: copy.footWidth,
            left: _millimeter(report?.leftFootWidth),
            right: _millimeter(report?.rightFootWidth),
            description: copy.footWidthDescription,
          ),
          (
            label: copy.forefootWidth,
            left: _millimeter(report?.leftToeWidth),
            right: _millimeter(report?.rightToeWidth),
            description: copy.forefootWidthDescription,
          ),
          (
            label: copy.archLength,
            left: _millimeter(report?.leftArchLength),
            right: _millimeter(report?.rightArchLength),
            description: copy.archLengthDescription,
          ),
          (
            label: copy.archHeight,
            left: _millimeter(report?.leftArchHeight),
            right: _millimeter(report?.rightArchHeight),
            description: copy.archHeightDescription,
          ),
          (
            label: copy.outerArchWidth,
            left: _millimeter(report?.leftArchOutsideWidth),
            right: _millimeter(report?.rightArchOutsideWidth),
            description: copy.outerArchWidthDescription,
          ),
          (
            label: copy.heelWidth,
            left: _millimeter(report?.leftTotalHeelWidth),
            right: _millimeter(report?.rightTotalHeelWidth),
            description: copy.heelWidthDescription,
          ),
          (
            label: copy.firstMetatarsalLength,
            left: _millimeter(report?.leftFirstMetaLength),
            right: _millimeter(report?.rightFirstMetaLength),
            description: copy.firstMetatarsalDescription,
          ),
          (
            label: copy.fifthMetatarsalLength,
            left: _millimeter(report?.leftFifthMetaLength),
            right: _millimeter(report?.rightFifthMetaLength),
            description: copy.fifthMetatarsalDescription,
          ),
          (
            label: copy.metatarsalJointHeight,
            left: _millimeter(report?.leftFirstMetaJointHeight),
            right: _millimeter(report?.rightFirstMetaJointHeight),
            description: copy.metatarsalJointDescription,
          ),
        ];

    for (final row in rows) {
      _drawComparisonMetric(
        layout,
        row.label,
        row.left,
        row.right,
        description: row.description,
      );
    }
  }

  void _drawProductAssessment(_PdfLayout layout, _PdfCopy copy) {
    layout.ensureSpace(84);
    final y = layout.y;
    layout.page.graphics.drawRectangle(
      brush: PdfSolidBrush(_tealSoft),
      pen: PdfPen(PdfColor(180, 220, 215)),
      bounds: Rect.fromLTWH(0, y, layout.width, 68),
    );
    layout.page.graphics.drawRectangle(
      brush: PdfSolidBrush(_teal),
      bounds: Rect.fromLTWH(13, y + 13, 42, 42),
    );
    layout.page.graphics.drawString(
      '+',
      layout.fonts.title,
      brush: PdfBrushes.white,
      bounds: Rect.fromLTWH(13, y + 12, 42, 42),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
    layout.page.graphics.drawString(
      copy.productRecommended,
      layout.fonts.panel,
      brush: PdfSolidBrush(_dark),
      bounds: Rect.fromLTWH(69, y + 16, layout.width - 82, 17),
    );
    layout.page.graphics.drawString(
      copy.productNotDetermined,
      layout.fonts.regular,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(69, y + 37, layout.width - 82, 15),
    );
    layout.y += 80;
  }

  void _drawEmptyState(_PdfLayout layout, String message) {
    layout.ensureSpace(74);
    final y = layout.y;
    layout.page.graphics.drawRectangle(
      brush: PdfSolidBrush(_soft),
      pen: PdfPen(_line),
      bounds: Rect.fromLTWH(0, y, layout.width, 58),
    );
    layout.page.graphics.drawString(
      message,
      layout.fonts.regular,
      brush: PdfSolidBrush(_muted),
      bounds: Rect.fromLTWH(18, y + 18, layout.width - 36, 20),
      format: PdfStringFormat(
        alignment: PdfTextAlignment.center,
        lineAlignment: PdfVerticalAlignment.middle,
      ),
    );
    layout.y += 70;
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
        // A missing image must not prevent the text report from being created.
      }
    }
    return result;
  }

  Uint8List _buildHeatmapImage(
    AnalysisPdfPressureSnapshot snapshot,
    _PressureStats stats,
  ) {
    const width = 904;
    const height = 688;
    const background = (r: 7, g: 17, b: 31);
    final output = image_codec.Image(width: width, height: height);
    final matrix = snapshot.matrix;
    final rows = matrix.length;
    final cols = matrix.map((row) => row.length).fold<int>(0, math.max);
    var matrixMax = 0.0;
    for (final row in matrix) {
      for (final value in row) {
        matrixMax = math.max(matrixMax, value);
      }
    }
    final effectiveMax = snapshot.maxVisualValue > 0
        ? math.max(snapshot.maxVisualValue, matrixMax)
        : math.max(1.0, matrixMax);

    for (var y = 0; y < height; y++) {
      final sourceY = rows <= 1 ? 0.0 : y / (height - 1) * (rows - 1);
      final y0 = sourceY.floor().clamp(0, rows - 1);
      final y1 = math.min(rows - 1, y0 + 1);
      final ty = sourceY - y0;
      for (var x = 0; x < width; x++) {
        final sourceX = cols <= 1 ? 0.0 : x / (width - 1) * (cols - 1);
        final x0 = sourceX.floor().clamp(0, cols - 1);
        final x1 = math.min(cols - 1, x0 + 1);
        final tx = sourceX - x0;
        final top =
            _matrixValue(matrix, y0, x0) * (1 - tx) +
            _matrixValue(matrix, y0, x1) * tx;
        final bottom =
            _matrixValue(matrix, y1, x0) * (1 - tx) +
            _matrixValue(matrix, y1, x1) * tx;
        final value = top * (1 - ty) + bottom * ty;
        if (value <= snapshot.threshold) {
          output.setPixelRgba(
            x,
            y,
            background.r,
            background.g,
            background.b,
            255,
          );
          continue;
        }
        final normalized = (value / effectiveMax).clamp(0.0, 1.0);
        final heat = _heatmapRgb(normalized);
        final alpha = (0.76 + normalized * 0.24).clamp(0.0, 1.0);
        output.setPixelRgba(
          x,
          y,
          (background.r * (1 - alpha) + heat.r * alpha).round(),
          (background.g * (1 - alpha) + heat.g * alpha).round(),
          (background.b * (1 - alpha) + heat.b * alpha).round(),
          255,
        );
      }
    }

    if (stats.centerOfPressureX != null && stats.centerOfPressureY != null) {
      final centerX = ((stats.centerOfPressureX! + 0.5) / cols * width).round();
      final centerY = ((stats.centerOfPressureY! + 0.5) / rows * height)
          .round();
      _drawCenterMarker(output, centerX, centerY);
    }
    return Uint8List.fromList(image_codec.encodePng(output, level: 6));
  }

  void _drawCenterMarker(image_codec.Image image, int centerX, int centerY) {
    const outerRadius = 25;
    const innerRadius = 16;
    for (var dy = -outerRadius; dy <= outerRadius; dy++) {
      for (var dx = -outerRadius; dx <= outerRadius; dx++) {
        final x = centerX + dx;
        final y = centerY + dy;
        if (x < 0 || y < 0 || x >= image.width || y >= image.height) continue;
        final distance = math.sqrt((dx * dx + dy * dy).toDouble());
        if (distance >= innerRadius && distance <= outerRadius) {
          image.setPixelRgba(x, y, 0, 229, 255, 255);
        } else if (distance < innerRadius) {
          image.setPixelRgba(x, y, 255, 255, 255, 255);
        }
      }
    }
    for (var offset = -34; offset <= 34; offset++) {
      final horizontalX = centerX + offset;
      final verticalY = centerY + offset;
      if (horizontalX >= 0 && horizontalX < image.width) {
        image.setPixelRgba(horizontalX, centerY, 0, 229, 255, 255);
      }
      if (verticalY >= 0 && verticalY < image.height) {
        image.setPixelRgba(centerX, verticalY, 0, 229, 255, 255);
      }
    }
  }

  _PressureStats _pressureStats(List<List<double>> matrix, double threshold) {
    final rows = matrix.length;
    final cols = matrix.map((row) => row.length).fold<int>(0, math.max);
    var total = 0.0;
    var left = 0.0;
    var right = 0.0;
    var forefoot = 0.0;
    var heel = 0.0;
    var weightedX = 0.0;
    var weightedY = 0.0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < matrix[row].length; col++) {
        final value = matrix[row][col];
        if (value <= threshold) continue;
        total += value;
        weightedX += col * value;
        weightedY += row * value;
        if (col < cols / 2) {
          left += value;
        } else {
          right += value;
        }
        if (row < rows / 2) {
          heel += value;
        } else {
          forefoot += value;
        }
      }
    }
    return _PressureStats(
      totalLoad: total,
      leftLoad: left,
      rightLoad: right,
      forefootLoad: forefoot,
      heelLoad: heel,
      centerOfPressureX: total <= 0 ? null : weightedX / total,
      centerOfPressureY: total <= 0 ? null : weightedY / total,
    );
  }

  double _matrixValue(List<List<double>> matrix, int row, int col) {
    if (row < 0 || row >= matrix.length) return 0;
    if (col < 0 || col >= matrix[row].length) return 0;
    return matrix[row][col];
  }

  Uint8List _pdfCompatibleImage(Uint8List bytes) {
    if (_isPng(bytes) || _isJpeg(bytes)) return bytes;
    final decoded = image_codec.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Image format could not be decoded.');
    }
    return Uint8List.fromList(image_codec.encodePng(decoded));
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
      bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8;

  static String _normalizedTitle(String value, _PdfCopy copy) {
    final title = value.trim();
    return title.isEmpty ? copy.assessmentResults : title;
  }

  static String _safeFileName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    return normalized.isEmpty ? 'analysis' : normalized;
  }

  static String _date(DateTime value, bool isEnglish) {
    if (isEnglish) {
      return '${value.month.toString().padLeft(2, '0')}/'
          '${value.day.toString().padLeft(2, '0')}/${value.year}';
    }
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.${value.year}';
  }

  static String _millimeter(double? value) =>
      value == null ? '-' : '${value.toStringAsFixed(1)} mm';

  static String _degree(double? value) =>
      value == null ? '-' : '${value.abs().toStringAsFixed(1)}°';

  static String _decimal(double? value) =>
      value == null ? '-' : value.toStringAsFixed(3);

  static String _assessmentWithValue(String assessment, String value) =>
      value == '-' ? assessment : '$assessment | $value';

  static String _archAssessment(double? value, _PdfCopy copy) {
    if (value == null) return copy.noData;
    if (value < 0.21) return copy.highArch;
    if (value <= 0.26) return copy.normalArch;
    if (value <= 0.28) return copy.mildFlatFoot;
    if (value <= 0.30) return copy.moderateFlatFoot;
    return copy.severeFlatFoot;
  }

  static String _angleAssessment(
    double? value,
    double mild,
    double moderate,
    double severe,
    _PdfCopy copy,
  ) {
    if (value == null) return copy.noData;
    final magnitude = value.abs();
    if (magnitude < mild) return copy.normal;
    if (magnitude < moderate) return copy.mild;
    if (magnitude < severe) return copy.moderate;
    return copy.severe;
  }

  static double? _archHeatPosition(double? value) {
    if (value == null) return null;
    if (value < 0.21) {
      return (0.25 * (value / 0.21)).clamp(0.0, 0.25);
    }
    if (value <= 0.26) {
      return (0.4 + ((value - 0.21) / 0.05) * 0.2).clamp(0.4, 0.6);
    }
    return (0.6 + ((value - 0.26) / 0.08) * 0.4).clamp(0.6, 1.0);
  }

  static double? _archWidthHeatPosition(double? value) =>
      ArchWidthCoefficientMapper.resolve(value)?.position;

  static String _archWidthAssessment(double? value, _PdfCopy copy) {
    final assessment = ArchWidthCoefficientMapper.resolve(value);
    if (assessment == null) return copy.noData;

    return switch (assessment.type) {
      ArchWidthCoefficientType.severeHighArch =>
        '${copy.severe} ${copy.highArch}',
      ArchWidthCoefficientType.moderateHighArch =>
        '${copy.moderate} ${copy.highArch}',
      ArchWidthCoefficientType.mildHighArch =>
        '${copy.mild} ${copy.highArch}',
      ArchWidthCoefficientType.normalType4 ||
      ArchWidthCoefficientType.normalType5 => copy.normalArch,
      ArchWidthCoefficientType.mildFlatFoot => copy.mildFlatFoot,
      ArchWidthCoefficientType.moderateFlatFoot => copy.moderateFlatFoot,
      ArchWidthCoefficientType.severeFlatFoot => copy.severeFlatFoot,
    };
  }

  static double? _angleHeatPosition(double? value, double severeThreshold) =>
      value == null
      ? null
      : (0.5 + (value / severeThreshold) * 0.5).clamp(0.0, 1.0);

  static PdfColor _assessmentColor(double value) {
    if (value <= 0.25) {
      return _lerpPdfColor(
        PdfColor(211, 47, 47),
        PdfColor(255, 193, 7),
        value / 0.25,
      );
    }
    if (value <= 0.5) {
      return _lerpPdfColor(
        PdfColor(255, 193, 7),
        PdfColor(67, 160, 71),
        (value - 0.25) / 0.25,
      );
    }
    if (value <= 0.75) {
      return _lerpPdfColor(
        PdfColor(67, 160, 71),
        PdfColor(255, 193, 7),
        (value - 0.5) / 0.25,
      );
    }
    return _lerpPdfColor(
      PdfColor(255, 193, 7),
      PdfColor(211, 47, 47),
      (value - 0.75) / 0.25,
    );
  }

  static PdfColor _lerpPdfColor(PdfColor a, PdfColor b, double t) {
    return PdfColor(
      (a.r + (b.r - a.r) * t).round(),
      (a.g + (b.g - a.g) * t).round(),
      (a.b + (b.b - a.b) * t).round(),
    );
  }

  static ({int r, int g, int b}) _heatmapRgb(double value) {
    if (value <= 0.2) {
      return _lerpRgb(
        (r: 13, g: 71, b: 161),
        (r: 0, g: 188, b: 212),
        value / 0.2,
      );
    }
    if (value <= 0.4) {
      return _lerpRgb(
        (r: 0, g: 188, b: 212),
        (r: 76, g: 175, b: 80),
        (value - 0.2) / 0.2,
      );
    }
    if (value <= 0.6) {
      return _lerpRgb(
        (r: 76, g: 175, b: 80),
        (r: 255, g: 235, b: 59),
        (value - 0.4) / 0.2,
      );
    }
    if (value <= 0.8) {
      return _lerpRgb(
        (r: 255, g: 235, b: 59),
        (r: 255, g: 152, b: 0),
        (value - 0.6) / 0.2,
      );
    }
    return _lerpRgb(
      (r: 255, g: 152, b: 0),
      (r: 244, g: 67, b: 54),
      (value - 0.8) / 0.2,
    );
  }

  static ({int r, int g, int b}) _lerpRgb(
    ({int r, int g, int b}) a,
    ({int r, int g, int b}) b,
    double t,
  ) {
    return (
      r: (a.r + (b.r - a.r) * t).round(),
      g: (a.g + (b.g - a.g) * t).round(),
      b: (a.b + (b.b - a.b) * t).round(),
    );
  }
}

class _PdfLayout {
  final PdfDocument document;
  final _PdfFonts fonts;
  late PdfPage page;
  double y = 0;

  _PdfLayout({required this.document, required this.fonts});

  double get width => page.getClientSize().width;
  double get height => page.getClientSize().height;

  void addPage() {
    page = document.pages.add();
    y = 0;
  }

  void ensureSpace(double requiredHeight) {
    if (y + requiredHeight > height) addPage();
  }
}

class _PdfFonts {
  final PdfFont regular;
  final PdfFont small;
  final PdfFont bold;
  final PdfFont metric;
  final PdfFont panel;
  final PdfFont section;
  final PdfFont title;

  const _PdfFonts({
    required this.regular,
    required this.small,
    required this.bold,
    required this.metric,
    required this.panel,
    required this.section,
    required this.title,
  });
}

class _PressureStats {
  final double totalLoad;
  final double leftLoad;
  final double rightLoad;
  final double forefootLoad;
  final double heelLoad;
  final double? centerOfPressureX;
  final double? centerOfPressureY;

  const _PressureStats({
    required this.totalLoad,
    required this.leftLoad,
    required this.rightLoad,
    required this.forefootLoad,
    required this.heelLoad,
    required this.centerOfPressureX,
    required this.centerOfPressureY,
  });
}

class _PdfCopy {
  final bool isEnglish;

  _PdfCopy(String languageCode)
    : isEnglish = languageCode.toLowerCase().startsWith('en');

  String text(String tr, String en) => isEnglish ? en : tr;

  String get saveDialogTitle =>
      text('Değerlendirme raporunu kaydet', 'Save assessment report');
  String get fileNameSuffix =>
      isEnglish ? 'assessment_report' : 'degerlendirme_raporu';
  String get footerTitle => text(
    'OptiYou - Ayak Sağlığı Değerlendirme Raporu',
    'OptiYou - Foot Health Assessment Report',
  );
  String get pageCounter => text('Sayfa {0} / {1}', 'Page {0} / {1}');
  String get assessmentResults =>
      text('Değerlendirme Sonuçları', 'Assessment Results');
  String get assessmentIntro => text(
    '3D anatomik ölçümler, görsel incelemeler ve plantar basınç ölçüm sonuçları.',
    '3D anatomical measurements, visual assessments, and plantar pressure results.',
  );
  String get client => text('Danışan', 'Client');
  String get session => text('Oturum', 'Session');
  String get date => text('Tarih', 'Date');
  String get location => text('Konum', 'Location');
  String get locationNotSpecified =>
      text('Konum belirtilmedi', 'Location not specified');
  String get findingsAndImages => text(
    'Değerlendirme Bulguları ve Görseller',
    'Assessment Findings and Images',
  );
  String get findingsAndImagesSubtitle => text(
    'Sol ve sağ ayak görselleri, değerlendirmeleri ve ölçülen değerleri birlikte gösterilir.',
    'Left and right foot images, assessments, and measured values are shown together.',
  );
  String get archStructure => text('Ark ve Kemer Yapısı', 'Arch Structure');
  String get archStructureSubtitle => text(
    'Ayak kemeri yüksekliği, genişliği ve yüzey formu.',
    'Arch height, width, and surface form.',
  );
  String get archHeightMap => text('Ark Yükseklik Haritası', 'Arch Height Map');
  String get archIndex => text('Ark İndeksi', 'Arch Index');
  String get archSectionImage =>
      text('Ark Kesit Görüntüsü', 'Arch Cross-Section Image');
  String get archWidthIndex => text('Ark Genişlik İndeksi', 'Arch Width Index');
  String get archHeight => text('Ark Yüksekliği', 'Arch Height');
  String get footFormHallux => text(
    'Ayak Formu ve Başparmak Hizalanması',
    'Foot Form and Hallux Alignment',
  );
  String get footFormHalluxSubtitle => text(
    'Ön ayak formu ve halluks açısının iki taraflı görünümü.',
    'Bilateral view of forefoot form and hallux angle.',
  );
  String get footImage => text('Ayak Görüntüsü', 'Foot Image');
  String get halluxAngleType =>
      text('Halluks Açısı ve Tipi', 'Hallux Angle and Type');
  String get rearfootPronation =>
      text('Arka Ayak ve Pronasyon', 'Rearfoot and Pronation');
  String get rearfootPronationSubtitle => text(
    'Topuk-bilek, pronasyon ve diz hizalanması.',
    'Heel-ankle, pronation, and knee alignment.',
  );
  String get ankleAlignment =>
      text('Ayak-Bilek Hizalanması', 'Foot-Ankle Alignment');
  String get pronationAngleHeelType =>
      text('Pronasyon Açısı ve Topuk Tipi', 'Pronation Angle and Heel Type');
  String get kneeAngleAlignment =>
      text('Diz Açısı ve Hizalanması', 'Knee Angle and Alignment');
  String get left => text('Sol', 'Left');
  String get right => text('Sağ', 'Right');
  String get leftFoot => text('Sol Ayak', 'Left Foot');
  String get rightFoot => text('Sağ Ayak', 'Right Foot');
  String get imageUnavailable => text('Görsel bulunamadı', 'Image unavailable');
  String get noData => text('Veri bulunmuyor', 'No data');
  String get normal => 'Normal';
  String get mild => text('Hafif', 'Mild');
  String get moderate => text('Orta Düzey', 'Moderate');
  String get severe => text('İleri Düzey', 'Severe');
  String get highArch => text('Yüksek Ark', 'High Arch');
  String get normalArch => text('Normal Ark', 'Normal Arch');
  String get mildFlatFoot => text('Hafif Düz Taban', 'Mild Flat Foot');
  String get moderateFlatFoot =>
      text('Orta Düzey Düz Taban', 'Moderate Flat Foot');
  String get severeFlatFoot =>
      text('İleri Düzey Düz Taban', 'Severe Flat Foot');
  String get plantarPressureMeasurements =>
      text('Plantar Basınç Ölçümleri', 'Plantar Pressure Measurements');
  String get plantarPressureSubtitle => text(
    'Seçili kaydın basınç ısı haritası ve yük dağılımları.',
    'Pressure heatmap and load distributions for the selected recording.',
  );
  String get pressureHeatmap => text('Basınç Isı Haritası', 'Pressure Heatmap');
  String get loadDistribution => text('Yük Dağılımı', 'Load Distribution');
  String get weight => text('Kilo', 'Weight');
  String get leftRightLoad =>
      text('Sol / Sağ Yük Dağılımı', 'Left / Right Load Distribution');
  String get forefootHeelLoad =>
      text('Ön Ayak / Topuk Dağılımı', 'Forefoot / Heel Distribution');
  String get forefoot => text('Ön Ayak', 'Forefoot');
  String get heel => text('Topuk', 'Heel');
  String get noPressureData => text(
    'Bu değerlendirme için plantar basınç verisi bulunmuyor.',
    'No plantar pressure data is available for this assessment.',
  );
  String get anatomicalMeasurements =>
      text('Anatomik Ölçümler', 'Anatomical Measurements');
  String get anatomicalMeasurementsSubtitle => text(
    '3D taramadan alınan anatomik ölçüm değerleri.',
    'Anatomical measurements obtained from the 3D scan.',
  );
  String get footLength => text('Ayak Uzunluğu', 'Foot Length');
  String get soleLength => text('Taban Uzunluğu', 'Sole Length');
  String get footWidth => text('Ayak Genişliği', 'Foot Width');
  String get forefootWidth => text('Parmak Önü Genişliği', 'Forefoot Width');
  String get toeWidth => text('Parmak Genişliği', 'Toe Width');
  String get archLength => text('Ark Uzunluğu', 'Arch Length');
  String get outerArchWidth => text('Dış Ark Genişliği', 'Outer Arch Width');
  String get heelWidth => text('Topuk Genişliği', 'Heel Width');
  String get firstMetatarsalLength =>
      text('1. Metatars Uzunluğu', '1st Metatarsal Length');
  String get fifthMetatarsalLength =>
      text('5. Metatars Uzunluğu', '5th Metatarsal Length');
  String get metatarsalJointHeight =>
      text('Metatars Eklem Yüksekliği', 'Metatarsal Joint Height');
  String get footLengthDescription => text(
    'Topuk ile en uzun parmak arasındaki mesafe.',
    'Distance from the heel to the longest toe.',
  );
  String get soleLengthDescription => text(
    'Ayak tabanının anatomik temas uzunluğu.',
    'Anatomical contact length of the sole.',
  );
  String get footWidthDescription => text(
    'Ön ayaktaki en geniş anatomik mesafe.',
    'Widest anatomical distance across the forefoot.',
  );
  String get forefootWidthDescription => text(
    'Parmak kökleri seviyesindeki genişlik.',
    'Width at the level of the toe joints.',
  );
  String get archLengthDescription => text(
    'Medial longitudinal ark uzunluğu.',
    'Length of the medial longitudinal arch.',
  );
  String get archHeightDescription => text(
    'Ayak kemerinin maksimum yüksekliği.',
    'Maximum height of the foot arch.',
  );
  String get outerArchWidthDescription => text(
    'Ark bölgesinin dış genişlik ölçümü.',
    'Outer width measurement of the arch region.',
  );
  String get heelWidthDescription => text(
    'Topuk bölgesinin toplam genişliği.',
    'Total width of the heel region.',
  );
  String get firstMetatarsalDescription => text(
    'Birinci metatars kemiğinin ölçülen uzunluğu.',
    'Measured length of the first metatarsal.',
  );
  String get fifthMetatarsalDescription => text(
    'Beşinci metatars kemiğinin ölçülen uzunluğu.',
    'Measured length of the fifth metatarsal.',
  );
  String get metatarsalJointDescription => text(
    'Metatars ekleminin tabana göre yüksekliği.',
    'Height of the metatarsal joint relative to the sole.',
  );
  String get productAssessment =>
      text('Ürün Değerlendirmesi', 'Product Assessment');
  String get productAssessmentSubtitle => text(
    'Değerlendirme sonucuna göre önerilen ürün.',
    'Product recommended based on the assessment result.',
  );
  String get productRecommended =>
      text('Size Önerilen Ürün', 'Recommended Product');
  String get productNotDetermined =>
      text('Ürün belirlenmedi.', 'No product has been determined.');
}
