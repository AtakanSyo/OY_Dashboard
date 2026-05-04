import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/constants/scan_report_labels.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/services/scan/scan_report_pdf_parser_service.dart';

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
  const ScanFolderUploadDialog({super.key});

  @override
  State<ScanFolderUploadDialog> createState() => _ScanFolderUploadDialogState();
}

class _ScanFolderUploadDialogState extends State<ScanFolderUploadDialog> {
  final ScanReportPdfParserService _pdfParserService =
      const ScanReportPdfParserService();

  String? _selectedFolderPath;
  List<String> _fileNames = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _detectedPdfPath;
  ParsedScanReport? _parsedReport;

  Future<void> _pickFolder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _detectedPdfPath = null;
      _parsedReport = null;
    });

    try {
      final folderPath = await FilePicker.getDirectoryPath(
        dialogTitle: '3D tarama klasörünü seç',
      );

      if (folderPath == null || folderPath.trim().isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dir = Directory(folderPath);

      if (!dir.existsSync()) {
        setState(() {
          _errorMessage = 'Seçilen klasör bulunamadı.';
          _isLoading = false;
        });
        return;
      }

      final entries = dir.listSync();

      final files = entries.whereType<File>().toList();

      final fileNames = files
          .map((file) => file.uri.pathSegments.last)
          .toList()
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

      setState(() {
        _selectedFolderPath = folderPath;
        _fileNames = fileNames;
        _detectedPdfPath = detectedPdfPath;
        _parsedReport = parsedReport;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Klasör seçilirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedFolderPath == null) return;

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

  Widget _buildPairPreviewRow(String label, Object? leftValue, Object? rightValue) {
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

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => Navigator.pop(context),
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
                    onPressed: _isLoading ? null : _pickFolder,
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
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
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
                                                final fileName =
                                                    _fileNames[index];

                                                return Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Vazgeç'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedFolderPath == null
                        ? null
                        : _confirmSelection,
                    child: const Text('Yüklemeyi Onayla'),
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