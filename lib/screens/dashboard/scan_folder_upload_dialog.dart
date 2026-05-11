import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/constants/scan_report_labels.dart';
import 'package:oy_site/data/repositories/supabase_analysis_repository.dart';
import 'package:oy_site/data/repositories/supabase_session_scan_repository.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/models/session_scan_assets.dart';
import 'package:oy_site/services/analysis/analysis_runtime_cache.dart';
import 'package:oy_site/services/analysis/plantar_pressure_mock_factory.dart';
import 'package:oy_site/services/scan/scan_report_pdf_parser_service.dart';
import 'package:oy_site/services/scan/session_scan_assets_parser.dart';
import 'package:oy_site/services/session_analysis_service.dart';

class ScanFolderUploadResult {
  final String folderPath;
  final List<String> fileNames;
  final String? detectedPdfPath;
  final ParsedScanReport? parsedReport;

  const ScanFolderUploadResult({
    required this.folderPath,
    required this.fileNames,
    this.detectedPdfPath,
    this.parsedReport,
  });
}

class ScanFolderUploadDialog extends StatefulWidget {
  final int? targetUserId;
  final int? sessionId;
  final int? patientId;
  final int? expertUserId;

  const ScanFolderUploadDialog({
    super.key,
    this.targetUserId,
    this.sessionId,
    this.patientId,
    this.expertUserId,
  });

  @override
  State<ScanFolderUploadDialog> createState() => _ScanFolderUploadDialogState();
}

class _ScanFolderUploadDialogState extends State<ScanFolderUploadDialog> {
  final ScanReportPdfParserService _pdfParserService =
      const ScanReportPdfParserService();

  final SessionScanAssetsParser _assetsParser = const SessionScanAssetsParser();

  final SupabaseAnalysisRepository _analysisRepository =
      SupabaseAnalysisRepository();

  final SupabaseSessionScanRepository _scanRepository =
      SupabaseSessionScanRepository();

  String? _selectedFolderPath;
  List<String> _fileNames = [];

  bool _isLoading = false;
  bool _isProcessingUpload = false;
  bool _isSavingAnalysis = false;
  bool _analysisSaved = false;

  String? _errorMessage;
  String? _saveMessage;

  String? _detectedPdfPath;
  ParsedScanReport? _parsedReport;
  SessionScanAssets? _scanAssets;

  Future<void> _pickFolder() async {
    setState(() {
      _isLoading = true;
      _isProcessingUpload = false;
      _isSavingAnalysis = false;
      _analysisSaved = false;
      _errorMessage = null;
      _saveMessage = null;
      _detectedPdfPath = null;
      _parsedReport = null;
      _scanAssets = null;
      _selectedFolderPath = null;
      _fileNames = [];
    });

    try {
      final folderPath = await FilePicker.getDirectoryPath(
        dialogTitle: '3D tarama klasörünü seç',
      );

      if (folderPath == null || folderPath.trim().isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dir = Directory(folderPath);

      if (!dir.existsSync()) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Seçilen klasör bulunamadı.';
          _isLoading = false;
        });
        return;
      }

      final entries = dir.listSync();
      final files = entries.whereType<File>().toList();

      final fileNames = files.map((file) => file.uri.pathSegments.last).toList()
        ..sort();

      String? detectedPdfPath;
      for (final file in files) {
        if (file.path.toLowerCase().endsWith('.pdf')) {
          detectedPdfPath = file.path;
          break;
        }
      }

      ParsedScanReport? parsedReport;
      if (detectedPdfPath != null) {
        try {
          parsedReport = await _pdfParserService.parsePdfFile(detectedPdfPath);
        } catch (e) {
          _errorMessage = 'PDF bulundu ancak parse edilemedi: $e';
        }
      }

      SessionScanAssets? scanAssets;
      try {
        scanAssets = _assetsParser.parseFolder(folderPath);
      } catch (e) {
        debugPrint('Assets parse hatası: $e');
      }

      if (!mounted) return;

      setState(() {
        _selectedFolderPath = folderPath;
        _fileNames = fileNames;
        _detectedPdfPath = detectedPdfPath;
        _parsedReport = parsedReport;
        _scanAssets = scanAssets;
        _isLoading = false;
        _isProcessingUpload = true;
        _saveMessage =
            '3D scan dosyaları ve analiz verileri Supabase’e kaydediliyor. Lütfen bekleyin.';
      });

      await _saveScanDataToSupabase();

      if (parsedReport != null) {
        await _saveParsedReportAsAnalysisResult();
      } else {
        if (!mounted) return;
        setState(() {
          _saveMessage =
              '3D scan verileri kaydedildi. PDF parse edilemediği için analiz sonucu oluşturulmadı.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Klasör seçilirken hata oluştu: $e';
        _isLoading = false;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessingUpload = false;
        _isSavingAnalysis = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedFolderPath == null) return;
    if (_isLoading || _isProcessingUpload || _isSavingAnalysis) return;

    Navigator.pop(
      context,
      ScanFolderUploadResult(
        folderPath: _selectedFolderPath!,
        fileNames: _fileNames,
        detectedPdfPath: _detectedPdfPath,
        parsedReport: _parsedReport,
      ),
    );
  }

  Future<void> _saveScanDataToSupabase() async {
    final sessionId = widget.sessionId;
    final patientId = widget.patientId;
    final expertUserId = widget.expertUserId;

    if (sessionId == null || patientId == null || expertUserId == null) {
      if (!mounted) return;
      setState(() {
        _saveMessage =
            '3D scan verileri geçici olarak hazırlandı. Session/patient/expert ID eksik olduğu için Supabase’e kaydedilmedi.';
      });
      return;
    }

    if (_parsedReport == null && _scanAssets == null) {
      if (!mounted) return;
      setState(() {
        _saveMessage =
            'Kaydedilecek 3D scan raporu veya dosya varlığı bulunamadı.';
      });
      return;
    }

    try {
      await _scanRepository.saveScanData(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        parsedReport: _parsedReport,
        assets: _scanAssets,
        detectedPdfPath: _detectedPdfPath,
      );

      if (!mounted) return;

      setState(() {
        _saveMessage = '3D scan verileri Supabase’e kaydedildi.';
      });
    } catch (e) {
      debugPrint('3D scan kayıt hatası: $e');

      if (!mounted) return;

      setState(() {
        _saveMessage = '3D scan verileri kaydedilemedi: $e';
      });
    }
  }

  Future<void> _saveParsedReportAsAnalysisResult() async {
    final report = _parsedReport;
    final assets = _scanAssets;
    final userId = widget.targetUserId;
    final patientId = widget.patientId;
    final sessionId = widget.sessionId;

    if (report == null) return;

    setState(() {
      _isSavingAnalysis = true;
      _analysisSaved = false;
      _saveMessage = 'Analiz sonucu Supabase’e kaydediliyor...';
    });

    try {
      final pressure = const PlantarPressureMockFactory().buildDefaultForTest();

      final analysisResult = SessionAnalysisService().analyze(
        report: report,
        pressure: pressure,
        analysisDate: DateTime.now(),
        sessionCode: report.reportNo ?? 'REAL-PARSE-SESSION',
        locationLabel: report.storeCode ?? report.address ?? 'Yüklenen Ölçüm',
        visuals: CustomerAnalysisVisualSet(
          sessionCode: report.reportNo ?? 'REAL-PARSE-SESSION',
          archLeftImagePath: assets?.archLeftPath,
          archRightImagePath: assets?.archRightPath,
          archSectionLeftImagePath: assets?.archSectionLeftPath,
          archSectionRightImagePath: assets?.archSectionRightPath,
          foot2dLeftImagePath: assets?.foot2dLeftPath,
          foot2dRightImagePath: assets?.foot2dRightPath,
          pronatorLeftImagePath: assets?.pronatorLeftPath,
          pronatorRightImagePath: assets?.pronatorRightPath,
          leftStlPath: assets?.stlLeftPath,
          rightStlPath: assets?.stlRightPath,
        ),
      );

      AnalysisRuntimeCache.instance.saveLatest(analysisResult);

      if (userId == null && patientId == null) {
        if (!mounted) return;

        setState(() {
          _isSavingAnalysis = false;
          _analysisSaved = false;
          _saveMessage =
              'Analiz geçici olarak hazırlandı. Kullanıcı veya hasta ID olmadığı için Supabase’e kaydedilmedi.';
        });
        return;
      }

      await _analysisRepository.saveAnalysisResult(
        userId: userId,
        patientId: patientId,
        sessionId: sessionId,
        result: analysisResult,
      );

      if (!mounted) return;

      setState(() {
        _isSavingAnalysis = false;
        _analysisSaved = true;
        _saveMessage = 'Analiz Supabase’e kaydedildi. Yüklemeyi onaylayabilirsiniz.';
      });
    } catch (e) {
      debugPrint('Supabase analiz kayıt hatası: $e');

      if (!mounted) return;

      setState(() {
        _isSavingAnalysis = false;
        _analysisSaved = false;
        _saveMessage =
            'Analiz geçici olarak hazırlandı ancak Supabase’e kaydedilemedi: $e';
      });
    }
  }

  String _displayValue(Object? value) {
    if (value == null) return '—';
    return value.toString();
  }

  Widget _buildParsedReportPreview() {
    final report = _parsedReport;

    if (report == null) {
      if (_detectedPdfPath == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            'Klasörde parse edilecek PDF bulunamadı.',
            style: TextStyle(color: Colors.grey[700]),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: Text(
          'PDF bulundu ancak veri önizlemesi oluşturulamadı.',
          style: TextStyle(color: Colors.orange[900]),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PDF Analiz Önizlemesi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildSaveStatusBox(),
          _buildPreviewSection(
            title: 'Rapor Bilgileri',
            children: [
              _buildPreviewRow('Rapor No', _displayValue(report.reportNo)),
              _buildPreviewRow('Tarih', _displayValue(report.reportDate)),
              _buildPreviewRow('Saat', _displayValue(report.reportTime)),
              _buildPreviewRow('Mağaza', _displayValue(report.storeCode)),
              _buildPreviewRow('Adres', _displayValue(report.address)),
            ],
          ),
          _buildPreviewSection(
            title: 'Kullanıcı Bilgileri',
            children: [
              _buildPreviewRow('Ad', _displayValue(report.customerName)),
              _buildPreviewRow('Cinsiyet', _displayValue(report.gender)),
              _buildPreviewRow('Yaş', _displayValue(report.age)),
              _buildPreviewRow('Telefon', _displayValue(report.phone)),
            ],
          ),
          _buildPreviewSection(
            title: 'Uzunluk Ölçümleri',
            children: [
              _buildPairPreviewRow(
                ScanReportLabels.tr('Foot length'),
                report.leftFootLength,
                report.rightFootLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Sole length'),
                report.leftSoleLength,
                report.rightSoleLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Arch length'),
                report.leftArchLength,
                report.rightArchLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('First meta length'),
                report.leftFirstMetaLength,
                report.rightFirstMetaLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Fifth meta length'),
                report.leftFifthMetaLength,
                report.rightFifthMetaLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Hallux bumps length'),
                report.leftHalluxBumpsLength,
                report.rightHalluxBumpsLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Foot flank length'),
                report.leftFootFlankLength,
                report.rightFootFlankLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Heel center length'),
                report.leftHeelCenterLength,
                report.rightHeelCenterLength,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Heel margin length'),
                report.leftHeelMarginLength,
                report.rightHeelMarginLength,
              ),
            ],
          ),
          _buildPreviewSection(
            title: 'Genişlik Ölçümleri',
            children: [
              _buildPairPreviewRow(
                ScanReportLabels.tr('Foot width'),
                report.leftFootWidth,
                report.rightFootWidth,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Slant width'),
                report.leftSlantWidth,
                report.rightSlantWidth,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Toe width'),
                report.leftToeWidth,
                report.rightToeWidth,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Arch outside width'),
                report.leftArchOutsideWidth,
                report.rightArchOutsideWidth,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Foot flank width'),
                report.leftFootFlankWidth,
                report.rightFootFlankWidth,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Heel center width'),
                report.leftHeelCenterWidth,
                report.rightHeelCenterWidth,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Total heel width'),
                report.leftTotalHeelWidth,
                report.rightTotalHeelWidth,
              ),
            ],
          ),
          _buildPreviewSection(
            title: 'Yükseklik Ölçümleri',
            children: [
              _buildPairPreviewRow(
                ScanReportLabels.tr('Arch height'),
                report.leftArchHeight,
                report.rightArchHeight,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('First meta joint height'),
                report.leftFirstMetaJointHeight,
                report.rightFirstMetaJointHeight,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Heel protrusion height'),
                report.leftHeelProtrusionHeight,
                report.rightHeelProtrusionHeight,
              ),
            ],
          ),
          _buildPreviewSection(
            title: 'Kemer Analizi',
            children: [
              _buildPairPreviewRow(
                ScanReportLabels.tr('Arch type'),
                report.leftArchType,
                report.rightArchType,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Arch index'),
                report.leftArchIndex,
                report.rightArchIndex,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Arch width index'),
                report.leftArchWidthIndex,
                report.rightArchWidthIndex,
              ),
            ],
          ),
          _buildPreviewSection(
            title: 'Halluks Analizi',
            children: [
              _buildPairPreviewRow(
                ScanReportLabels.tr('Hallux angle'),
                report.leftHalluxAngle,
                report.rightHalluxAngle,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Hallux type'),
                report.leftHalluxType,
                report.rightHalluxType,
              ),
            ],
          ),
          _buildPreviewSection(
            title: 'Topuk Analizi',
            children: [
              _buildPairPreviewRow(
                'Topuk Açısı (°)',
                report.leftPronatorAngle,
                report.rightPronatorAngle,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Heel type'),
                report.leftHeelType,
                report.rightHeelType,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Knee angle'),
                report.leftKneeAngle,
                report.rightKneeAngle,
              ),
              _buildPairPreviewRow(
                ScanReportLabels.tr('Knee type'),
                report.leftKneeType,
                report.rightKneeType,
              ),
            ],
          ),
          if ((report.recommendationText ?? '').isNotEmpty)
            _buildPreviewSection(
              title: 'Genel Öneri',
              children: [
                Text(
                  report.recommendationText!,
                  style: TextStyle(
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSaveStatusBox() {
    if (_saveMessage == null && !_isProcessingUpload && !_isSavingAnalysis) {
      return const SizedBox.shrink();
    }

    final hasError = (_saveMessage ?? '').contains('kaydedilemedi');
    final isBusy = _isProcessingUpload || _isSavingAnalysis;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasError
            ? Colors.orange.withOpacity(0.10)
            : Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError
              ? Colors.orange.withOpacity(0.25)
              : Colors.teal.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          if (isBusy) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ] else ...[
            Icon(
              hasError ? Icons.warning_amber_outlined : Icons.check_circle_outline,
              size: 18,
              color: hasError ? Colors.orange : Colors.teal,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              _saveMessage ?? 'Kaydediliyor...',
              style: TextStyle(
                color: hasError ? Colors.orange[900] : Colors.teal[900],
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairPreviewRow(
    String label,
    Object? leftValue,
    Object? rightValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Sol Ayak: ${_displayValue(leftValue)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sağ Ayak: ${_displayValue(rightValue)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSaveStatusBox() {
    if (_saveMessage == null && !_isProcessingUpload && !_isSavingAnalysis) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          if (_isProcessingUpload || _isSavingAnalysis) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
          ] else ...[
            const Icon(
              Icons.info_outline,
              color: Colors.teal,
              size: 18,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              _saveMessage ?? 'Kaydediliyor...',
              style: TextStyle(
                color: Colors.teal[900],
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActionDisabled =
        _selectedFolderPath == null || _isLoading || _isProcessingUpload;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 900,
        height: 680,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '3D Tarama Klasörü Yükle',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isProcessingUpload
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '3D tarama klasörünü seç. Klasörde PDF varsa otomatik parse edilerek temel analiz verileri gösterilir.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading || _isProcessingUpload
                        ? null
                        : _pickFolder,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Klasör Seç'),
                  ),
                  const SizedBox(width: 12),
                  if (_selectedFolderPath != null)
                    Expanded(
                      child: Text(
                        _selectedFolderPath!,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGlobalSaveStatusBox(),
              if (_detectedPdfPath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Bulunan PDF: $_detectedPdfPath',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessage != null
                                ? Center(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  )
                                : _fileNames.isEmpty
                                    ? Center(
                                        child: Text(
                                          'Henüz klasör seçilmedi.',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bulunan dosyalar (${_fileNames.length})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: ListView.separated(
                                              itemCount: _fileNames.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 8),
                                              itemBuilder: (context, index) {
                                                final fileName = _fileNames[index];

                                                return Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade300,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .insert_drive_file_outlined,
                                                        color: Colors.teal,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          fileName,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildParsedReportPreview(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessingUpload
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isActionDisabled ? null : _confirmSelection,
                    child: _isProcessingUpload
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Kaydediliyor...'),
                            ],
                          )
                        : const Text('Yüklemeyi Onayla'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}