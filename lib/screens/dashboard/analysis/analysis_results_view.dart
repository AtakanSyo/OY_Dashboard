import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:oy_site/data/repositories/supabase_session_pressure_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/data/repositories/supabase_session_scan_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/parsed_scan_report.dart';
import 'package:oy_site/models/session_pressure_recording_model.dart';
import 'package:oy_site/screens/dashboard/analysis/widgets/analysis_comparison_widgets.dart';
import 'package:oy_site/services/report/analysis_pdf_report_service.dart';
import 'package:oy_site/services/scan/scan_report_text_parser.dart';
import 'package:oy_site/services/analysis/hallux_heat_position_mapper.dart';
import 'package:oy_site/services/analysis/arch_width_coefficient_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisResultsView extends StatefulWidget {
  final AppUser currentUser;
  final String pageTitle;
  final List<CustomerAnalysisResult> results;
  final int initialSelectedIndex;
  final bool embedded;

  const AnalysisResultsView({
    super.key,
    required this.currentUser,
    required this.pageTitle,
    required this.results,
    this.initialSelectedIndex = 0,
    this.embedded = false,
  });

  @override
  State<AnalysisResultsView> createState() => _AnalysisResultsViewState();
}

class _AnalysisResultsViewState extends State<AnalysisResultsView> {
  bool get _isEnglish => Localizations.localeOf(context).languageCode == 'en';

  SupabaseClient get _client => Supabase.instance.client;

  final SupabaseSessionPressureRepository _pressureRepository =
      SupabaseSessionPressureRepository();
  final SupabaseSessionScanRepository _scanRepository =
      SupabaseSessionScanRepository();
  final AnalysisPdfReportService _pdfReportService = AnalysisPdfReportService();

  late int _selectedIndex;
  bool _isExportingPdf = false;
  bool _isInitialPageLoading = true;

  // ---------------------------------------------------------------------------
  // Değerlendirme görselleri
  // ---------------------------------------------------------------------------

  bool _isLoadingEvaluationVisuals = false;
  String? _evaluationVisualsError;

  /// session_scan_files.file_type → signed URL
  final Map<String, String> _evaluationVisualUrls = {};
  final Map<String, Uint8List> _evaluationVisualBytes = {};
  ParsedScanReport? _sessionScanReport;

  // ---------------------------------------------------------------------------
  // Basınç ölçümleri
  // ---------------------------------------------------------------------------

  bool _isLoadingPressureRecords = false;
  bool _isLoadingPressureData = false;

  String? _pressureRecordsError;
  String? _pressureDataError;

  List<SessionPressureRecordingModel> _pressureRecordings = [];

  SessionPressureRecordingModel? _selectedPressureRecording;
  _PressureRecordingData? _selectedPressureData;

  int _selectedPressureFrameIndex = 0;
  _PressurePointSelection? _selectedPressurePoint;

  CustomerAnalysisResult? get _selectedResult {
    if (widget.results.isEmpty) return null;

    if (_selectedIndex < 0 || _selectedIndex >= widget.results.length) {
      return null;
    }

    return widget.results[_selectedIndex];
  }

  String get _displayPageTitle {
    return AppLocalizations.of(context).assessmentResults;
  }

  @override
  void initState() {
    super.initState();

    if (widget.results.isEmpty) {
      _selectedIndex = 0;
    } else {
      _selectedIndex = widget.initialSelectedIndex
          .clamp(0, widget.results.length - 1)
          .toInt();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadSelectedSessionData();
    });
  }

  Future<void> _reloadSelectedSessionData() async {
    if (mounted) setState(() => _isInitialPageLoading = true);
    try {
      await Future.wait([
        _loadEvaluationVisuals(),
        _loadPressureRecordings(),
        _loadSessionScanReport(),
      ]);
    } finally {
      if (mounted) setState(() => _isInitialPageLoading = false);
    }
  }

  Future<void> _selectResult(int index) async {
    if (index < 0 || index >= widget.results.length) {
      return;
    }

    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;

      _evaluationVisualUrls.clear();
      _evaluationVisualBytes.clear();
      _sessionScanReport = null;
      _evaluationVisualsError = null;

      _pressureRecordings = [];
      _selectedPressureRecording = null;
      _selectedPressureData = null;
      _selectedPressureFrameIndex = 0;
      _selectedPressurePoint = null;
      _pressureRecordsError = null;
      _pressureDataError = null;
    });

    await _reloadSelectedSessionData();
  }

  Future<void> _loadSessionScanReport() async {
    final sessionId = _selectedResult?.sessionId;
    if (sessionId == null) return;

    try {
      final stored = await _scanRepository.getReportBySessionId(
        sessionId: sessionId,
      );
      if (!mounted || _selectedResult?.sessionId != sessionId) return;
      final storedParsed = stored?.toParsedScanReport();
      final rawText = stored?.rawText?.trim();
      final reparsed = rawText == null || rawText.isEmpty
          ? null
          : const ScanReportTextParser().parse(rawText);
      final parsed = ParsedScanReport.merge(
        preferred: storedParsed,
        fallback: reparsed,
      );
      setState(() {
        _sessionScanReport = parsed.hasAnyCoreMeasurement ? parsed : null;
      });
    } catch (e) {
      debugPrint('Oturum tarama raporu yüklenemedi: $e');
    }
  }

  ParsedScanReport? _reportFor(CustomerAnalysisResult result) {
    if (_sessionScanReport == null) return result.parsedReport;
    return ParsedScanReport.merge(
      preferred: _sessionScanReport,
      fallback: result.parsedReport,
    );
  }

  // ---------------------------------------------------------------------------
  // Değerlendirme görsellerinin Supabase'den yüklenmesi
  // ---------------------------------------------------------------------------

  Future<void> _loadEvaluationVisuals() async {
    final result = _selectedResult;
    final sessionId = result?.sessionId;

    if (result == null) return;

    if (sessionId == null) {
      if (!mounted) return;

      setState(() {
        _evaluationVisualUrls.clear();
        _evaluationVisualBytes.clear();
        _evaluationVisualsError = AppLocalizations.of(context).sessionIdMissing;
        _isLoadingEvaluationVisuals = false;
      });

      return;
    }

    final requestedSessionId = sessionId;

    setState(() {
      _isLoadingEvaluationVisuals = true;
      _evaluationVisualsError = null;
      _evaluationVisualUrls.clear();
      _evaluationVisualBytes.clear();
    });

    try {
      final response = await _client
          .from('session_scan_files')
          .select('''
            id,
            file_type,
            file_name,
            storage_bucket,
            storage_path,
            upload_status,
            created_at
          ''')
          .eq('session_id', requestedSessionId)
          .eq('upload_status', 'uploaded')
          .order('created_at', ascending: false);

      final rows = (response as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      const supportedImageTypes = <String>{
        'arch_left_image',
        'arch_right_image',
        'arch_section_left',
        'arch_section_right',
        'foot_2d_left',
        'foot_2d_right',
        'pronator_left',
        'pronator_right',
      };

      final urls = <String, String>{};
      final imageBytes = <String, Uint8List>{};

      for (final row in rows) {
        final fileType = row['file_type']?.toString().trim() ?? '';

        if (!supportedImageTypes.contains(fileType)) {
          continue;
        }

        // Aynı türden birden fazla kayıt varsa sorgu en yeniden
        // eskiye sıralandığı için ilk kayıt kullanılır.
        if (urls.containsKey(fileType)) {
          continue;
        }

        final bucket = row['storage_bucket']?.toString().trim() ?? '';

        final storagePath = row['storage_path']?.toString().trim() ?? '';

        if (bucket.isEmpty || storagePath.isEmpty) {
          continue;
        }

        try {
          final signedUrl = await _client.storage
              .from(bucket)
              .createSignedUrl(_normalizeStoragePath(storagePath), 60 * 60 * 6);

          urls[fileType] = signedUrl;

          try {
            imageBytes[fileType] = await _client.storage
                .from(bucket)
                .download(_normalizeStoragePath(storagePath));
          } catch (e) {
            debugPrint(
              'PDF için görsel indirilemedi. '
              'Tür: $fileType, yol: $storagePath, hata: $e',
            );
          }
        } catch (e) {
          debugPrint(
            'Signed URL oluşturulamadı. '
            'Tür: $fileType, yol: $storagePath, hata: $e',
          );
        }
      }

      if (!mounted) return;

      // Kullanıcı bu sırada başka ölçüme geçtiyse eski sonucu uygulama.
      if (_selectedResult?.sessionId != requestedSessionId) {
        return;
      }

      setState(() {
        _evaluationVisualUrls
          ..clear()
          ..addAll(urls);
        _evaluationVisualBytes
          ..clear()
          ..addAll(imageBytes);

        _isLoadingEvaluationVisuals = false;

        if (urls.isEmpty) {
          _evaluationVisualsError = AppLocalizations.of(
            context,
          ).assessmentImagesUnavailable;
        }
      });

      debugPrint(
        'Oturum $requestedSessionId görselleri: '
        '${urls.keys.join(', ')}',
      );
    } catch (e) {
      if (!mounted) return;

      if (_selectedResult?.sessionId != requestedSessionId) {
        return;
      }

      setState(() {
        _isLoadingEvaluationVisuals = false;
        _evaluationVisualsError = AppLocalizations.of(
          context,
        ).assessmentImagesLoadError(e.toString());
      });

      debugPrint('Değerlendirme görselleri yüklenemedi: $e');
    }
  }

  String _normalizeStoragePath(String value) {
    var path = value.trim().replaceAll('\\', '/');

    while (path.startsWith('/')) {
      path = path.substring(1);
    }

    return path;
  }

  // ---------------------------------------------------------------------------
  // Basınç ölçümlerinin yüklenmesi
  // ---------------------------------------------------------------------------

  Future<void> _loadPressureRecordings() async {
    final result = _selectedResult;
    final sessionId = result?.sessionId;

    if (result == null) return;

    if (sessionId == null) {
      if (!mounted) return;

      setState(() {
        _pressureRecordings = [];
        _selectedPressureRecording = null;
        _selectedPressureData = null;
        _pressureRecordsError =
            'Bu değerlendirme için oturum ID bulunmadığı '
            'için basınç kayıtları yüklenemedi.';
        _isLoadingPressureRecords = false;
      });

      return;
    }

    final requestedSessionId = sessionId;

    setState(() {
      _isLoadingPressureRecords = true;
      _pressureRecordsError = null;
      _pressureDataError = null;
      _pressureRecordings = [];
      _selectedPressureRecording = null;
      _selectedPressureData = null;
      _selectedPressureFrameIndex = 0;
      _selectedPressurePoint = null;
    });

    try {
      final records = await _pressureRepository.getRecordingsBySessionId(
        sessionId: requestedSessionId,
      );

      if (!mounted) return;

      if (_selectedResult?.sessionId != requestedSessionId) {
        return;
      }

      setState(() {
        _pressureRecordings = records;
        _isLoadingPressureRecords = false;
      });

      if (records.isNotEmpty) {
        await _openPressureRecording(records.first);
      }
    } catch (e) {
      if (!mounted) return;

      if (_selectedResult?.sessionId != requestedSessionId) {
        return;
      }

      setState(() {
        _isLoadingPressureRecords = false;
        _pressureRecordsError = AppLocalizations.of(
          context,
        ).pressureRecordingsLoadError(e.toString());
      });
    }
  }

  Future<void> _openPressureRecording(
    SessionPressureRecordingModel recording,
  ) async {
    if (_isLoadingPressureData) {
      return;
    }

    final requestedSessionId = recording.sessionId;

    setState(() {
      _selectedPressureRecording = recording;
      _selectedPressureData = null;
      _selectedPressureFrameIndex = 0;
      _isLoadingPressureData = true;
      _pressureDataError = null;
    });

    try {
      Map<String, dynamic>? jsonMap;

      if (recording.rawFramesJson != null) {
        jsonMap = Map<String, dynamic>.from(recording.rawFramesJson!);
      }

      if (jsonMap == null) {
        final bucket = recording.storageBucket;
        final storagePath = recording.storagePath;

        if (bucket == null ||
            bucket.trim().isEmpty ||
            storagePath == null ||
            storagePath.trim().isEmpty) {
          throw Exception(
            'Kayıt için Storage bucket veya dosya yolu '
            'bulunamadı.',
          );
        }

        final Uint8List bytes = await _client.storage
            .from(bucket)
            .download(_normalizeStoragePath(storagePath));

        final decoded = jsonDecode(utf8.decode(bytes));

        if (decoded is! Map) {
          throw Exception('Basınç kayıt dosyasının JSON yapısı geçersiz.');
        }

        jsonMap = Map<String, dynamic>.from(decoded);
      }

      final data = _PressureRecordingData.fromJson(jsonMap);

      if (!mounted) return;

      if (_selectedResult?.sessionId != requestedSessionId) {
        return;
      }

      setState(() {
        _selectedPressureData = data;

        _selectedPressureFrameIndex = data.frames.isEmpty
            ? 0
            : data.frames.length ~/ 2;

        _isLoadingPressureData = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (_selectedResult?.sessionId != requestedSessionId) {
        return;
      }

      setState(() {
        _isLoadingPressureData = false;
        _pressureDataError = AppLocalizations.of(
          context,
        ).pressureDataOpenError(e.toString());
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Format helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';

    return DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm().format(date);
  }

  String _formatDuration(int durationMs) {
    if (durationMs <= 0) return '—';

    final duration = Duration(milliseconds: durationMs);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    if (minutes > 0) {
      final minuteUnit = Localizations.localeOf(context).languageCode == 'en'
          ? 'min'
          : 'dk';
      final secondUnit = Localizations.localeOf(context).languageCode == 'en'
          ? 'sec'
          : 'sn';
      return '$minutes $minuteUnit '
          '${seconds.toString().padLeft(2, '0')} $secondUnit';
    }

    final secondUnit = Localizations.localeOf(context).languageCode == 'en'
        ? 'sec'
        : 'sn';
    return '$seconds.${milliseconds ~/ 100} $secondUnit';
  }

  String _formatMillimeter(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)} mm';
  }

  String _formatDegree(double? value) {
    if (value == null) return '—';
    return '${value.abs().toStringAsFixed(1)}°';
  }

  String _formatDecimal(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(3);
  }

  String _safeText(String? value, {String fallback = '—'}) {
    final normalized = (value ?? '').trim();
    return _translateAssessmentText(normalized.isEmpty ? fallback : normalized);
  }

  String _translateAssessmentText(String value) {
    var translated = value;
    final english = Localizations.localeOf(context).languageCode == 'en';
    final replacements = english
        ? const <String, String>{
            'İleri Düzey Düz Taban': 'Severe Flat Foot',
            'Orta Düzey Düz Taban': 'Moderate Flat Foot',
            'Hafif Düz Taban': 'Mild Flat Foot',
            'Düz Taban': 'Flat Foot',
            'Yüksek Ark': 'High Arch',
            'Normal Ark': 'Normal Arch',
            'Normal Halluks': 'Normal Hallux',
            'Normal Topuk': 'Normal Heel',
            'Nötr': 'Neutral',
            'İleri Düzey': 'Severe',
            'Orta Düzey': 'Moderate',
            'Hafif': 'Mild',
          }
        : const <String, String>{
            'Severe Flat': 'İleri Düzey Düz Taban',
            'Moderate Flat': 'Orta Düzey Düz Taban',
            'Mild Flat': 'Hafif Düz Taban',
            'Flat Foot': 'Düz Taban',
            'High Arch': 'Yüksek Ark',
            'Normal Arch': 'Normal Ark',
            'Normal Hallgux': 'Normal Halluks',
            'Normal Hallux': 'Normal Halluks',
            'Normal Heel': 'Normal Topuk',
            'Neutral': 'Nötr',
            'Severity': 'İleri Düzey',
            'Severe': 'İleri Düzey',
            'Moderate': 'Orta Düzey',
            'Mild': 'Hafif',
            'Flat': 'Düz Taban',
            'Normal': 'Normal',
          };
    for (final entry in replacements.entries) {
      translated = translated.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false),
        entry.value,
      );
    }
    return translated;
  }

  String _archAssessmentLabel(double? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null) return l10n.noData;
    if (value < 0.21) return l10n.highArch;
    if (value <= 0.26) return l10n.normalArch;
    if (value <= 0.28) return l10n.mildFlatFoot;
    if (value <= 0.30) return l10n.moderateFlatFoot;
    return l10n.severeFlatFoot;
  }

  double? _archHeatPosition(double? value) {
    if (value == null) return null;
    if (value < 0.21) {
      return (0.25 * (value / 0.21)).clamp(0.0, 0.25);
    }
    if (value <= 0.26) {
      return (0.4 + ((value - 0.21) / 0.05) * 0.2).clamp(0.4, 0.6);
    }
    return (0.6 + ((value - 0.26) / 0.08) * 0.4).clamp(0.6, 1.0);
  }

  double? _archWidthHeatPosition(double? value) {
    return ArchWidthCoefficientMapper.resolve(value)?.position;
  }

  String _archWidthAssessmentLabel(double? value) {
    final l10n = AppLocalizations.of(context);
    final assessment = ArchWidthCoefficientMapper.resolve(value);
    if (assessment == null) return l10n.noData;

    return switch (assessment.type) {
      ArchWidthCoefficientType.severeHighArch =>
        '${l10n.severe} ${l10n.highArch}',
      ArchWidthCoefficientType.moderateHighArch =>
        '${l10n.moderate} ${l10n.highArch}',
      ArchWidthCoefficientType.mildHighArch => '${l10n.mild} ${l10n.highArch}',
      ArchWidthCoefficientType.normalType4 ||
      ArchWidthCoefficientType.normalType5 => l10n.normalArch,
      ArchWidthCoefficientType.mildFlatFoot => l10n.mildFlatFoot,
      ArchWidthCoefficientType.moderateFlatFoot => l10n.moderateFlatFoot,
      ArchWidthCoefficientType.severeFlatFoot => l10n.severeFlatFoot,
    };
  }

  String _assessmentWithValue(String assessment, String value) {
    if (value == '—') return assessment;
    return '$assessment • $value';
  }

  String _angleAssessmentLabel(
    double? value, {
    required double mild,
    required double moderate,
    required double severe,
  }) {
    final l10n = AppLocalizations.of(context);
    if (value == null) return l10n.noData;
    final magnitude = value.abs();
    if (magnitude < mild) return l10n.normal;
    if (magnitude < moderate) return l10n.mild;
    if (magnitude < severe) return l10n.moderate;
    return l10n.severe;
  }

  String _halluxAssessmentLabel(String? reportType, double? angle) {
    final normalizedType = (reportType ?? '').trim();
    if (normalizedType.isNotEmpty) {
      return _translateAssessmentText(normalizedType);
    }
    return _angleAssessmentLabel(angle, mild: 10, moderate: 20, severe: 30);
  }

  double? _angleHeatPosition(double? value, double severeThreshold) {
    if (value == null) return null;
    return (0.5 + (value / severeThreshold) * 0.5).clamp(0.0, 1.0);
  }

  AnalysisPdfPressureSnapshot? _pdfPressureSnapshot() {
    final data = _selectedPressureData;
    if (data == null || data.frames.isEmpty) return null;

    final frameIndex = _selectedPressureFrameIndex
        .clamp(0, data.frames.length - 1)
        .toInt();
    return AnalysisPdfPressureSnapshot(
      matrix: data.frames[frameIndex].matrix,
      maxVisualValue: data.maxVisualValue,
      threshold: data.threshold,
      weightKg: data.weightKg,
      cellAreaCm2: data.cellAreaCm2,
    );
  }

  Future<void> _saveSelectedResultAsPdf() async {
    final result = _selectedResult;
    if (result == null || _isExportingPdf) return;

    setState(() {
      _isExportingPdf = true;
    });

    try {
      final saved = await _pdfReportService.saveReport(
        result: result,
        pageTitle: _displayPageTitle,
        imageUrls: Map<String, String>.from(_evaluationVisualUrls),
        imageBytes: Map<String, Uint8List>.from(_evaluationVisualBytes),
        reportOverride: _reportFor(result),
        pressureSnapshot: _pdfPressureSnapshot(),
        languageCode: Localizations.localeOf(context).languageCode,
      );

      if (!mounted || !saved) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pdfSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).pdfCreateError(error.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final selected = _selectedResult;
    final l10n = AppLocalizations.of(context);

    if (widget.results.isEmpty || selected == null) {
      return Center(child: Text(l10n.assessmentNotFound));
    }

    if (_isInitialPageLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(strokeWidth: 4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.preparingAssessment,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(selected),
              const SizedBox(height: 18),
              _buildSectionCard(
                title: l10n.measurementHistoryTitle,
                subtitle: l10n.selectMeasurementSession,
                child: _buildSessionCards(),
              ),
              const SizedBox(height: 18),
              _buildEvaluationFindingsSection(selected),
              const SizedBox(height: 18),
              _buildPressureMeasurementsSection(),
              const SizedBox(height: 18),
              _buildAnatomicalMeasurementsSection(selected),
              const SizedBox(height: 18),
              _buildProductSection(),
            ],
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return SingleChildScrollView(child: content);
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(CustomerAnalysisResult result) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 720;

          final icon = Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              size: 34,
              color: Colors.teal,
            ),
          );

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _isExportingPdf ? null : _saveSelectedResultAsPdf,
                icon: _isExportingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(_isExportingPdf ? l10n.preparingPdf : l10n.savePdf),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.teal.shade800,
                  side: BorderSide(color: Colors.teal.shade300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _displayPageTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                l10n.assessmentIntro,
                style: TextStyle(color: Colors.grey.shade700, height: 1.4),
              ),
            ],
          );

          final metadata = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: isNarrow
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                _headerMetaRow(Icons.badge_outlined, result.sessionCode),
                const SizedBox(height: 7),
                _headerMetaRow(
                  Icons.calendar_today_outlined,
                  _formatDate(result.analysisDate),
                ),
                const SizedBox(height: 7),
                _headerMetaRow(
                  Icons.location_on_outlined,
                  result.locationLabel.trim().isEmpty
                      ? l10n.locationNotSpecified
                      : result.locationLabel,
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 14),
                information,
                const SizedBox(height: 16),
                metadata,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 18),
              Expanded(child: information),
              const SizedBox(width: 18),
              metadata,
            ],
          );
        },
      ),
    );
  }

  Widget _headerMetaRow(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.teal),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Session cards
  // ---------------------------------------------------------------------------

  Widget _buildSessionCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(widget.results.length, (index) {
        final result = widget.results[index];
        final isSelected = index == _selectedIndex;

        return InkWell(
          onTap: () => _selectResult(index),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 230,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.teal.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        result.sessionCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.teal,
                        size: 19,
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                _smallInformationRow(
                  Icons.calendar_today_outlined,
                  _formatDate(result.analysisDate),
                ),
                const SizedBox(height: 7),
                _smallInformationRow(
                  Icons.location_on_outlined,
                  result.locationLabel.trim().isEmpty
                      ? '—'
                      : result.locationLabel,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _smallInformationRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade700),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Anatomical measurements
  // ---------------------------------------------------------------------------

  Widget _buildAnatomicalMeasurementsSection(CustomerAnalysisResult result) {
    final l10n = AppLocalizations.of(context);
    final report = _reportFor(result);

    if (report == null) {
      return _buildExpandableSectionCard(
        title: l10n.anatomicalMeasurements,
        subtitle: l10n.anatomicalMeasurementsSubtitle,
        icon: Icons.straighten_outlined,
        initiallyExpanded: false,
        child: _emptyInformationState(
          icon: Icons.straighten_outlined,
          message: l10n.noParsedScanReport,
        ),
      );
    }

    final measurements = <AnalysisComparisonValue>[
      AnalysisComparisonValue(
        label: l10n.footLength,
        leftValue: _formatMillimeter(report.leftFootLength),
        rightValue: _formatMillimeter(report.rightFootLength),
        icon: Icons.straighten,
        description: l10n.footLengthDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.soleLength,
        leftValue: _formatMillimeter(report.leftSoleLength),
        rightValue: _formatMillimeter(report.rightSoleLength),
        icon: Icons.linear_scale,
        description: l10n.soleLengthDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.footWidth,
        leftValue: _formatMillimeter(report.leftFootWidth),
        rightValue: _formatMillimeter(report.rightFootWidth),
        icon: Icons.swap_horiz,
        description: l10n.footWidthDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.forefootWidth,
        leftValue: _formatMillimeter(report.leftToeWidth),
        rightValue: _formatMillimeter(report.rightToeWidth),
        icon: Icons.compare_arrows,
        description: l10n.forefootWidthDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.archLength,
        leftValue: _formatMillimeter(report.leftArchLength),
        rightValue: _formatMillimeter(report.rightArchLength),
        icon: Icons.architecture,
        description: l10n.archLengthDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.archHeight,
        leftValue: _formatMillimeter(report.leftArchHeight),
        rightValue: _formatMillimeter(report.rightArchHeight),
        icon: Icons.height,
        description: l10n.archHeightDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.outerArchWidth,
        leftValue: _formatMillimeter(report.leftArchOutsideWidth),
        rightValue: _formatMillimeter(report.rightArchOutsideWidth),
        icon: Icons.open_in_full,
        description: l10n.outerArchWidthDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.heelWidth,
        leftValue: _formatMillimeter(report.leftTotalHeelWidth),
        rightValue: _formatMillimeter(report.rightTotalHeelWidth),
        icon: Icons.horizontal_rule,
        description: l10n.heelWidthDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.firstMetatarsalLength,
        leftValue: _formatMillimeter(report.leftFirstMetaLength),
        rightValue: _formatMillimeter(report.rightFirstMetaLength),
        icon: Icons.looks_one_outlined,
        description: l10n.firstMetatarsalDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.fifthMetatarsalLength,
        leftValue: _formatMillimeter(report.leftFifthMetaLength),
        rightValue: _formatMillimeter(report.rightFifthMetaLength),
        icon: Icons.filter_5,
        description: l10n.fifthMetatarsalDescription,
      ),
      AnalysisComparisonValue(
        label: l10n.metatarsalJointHeight,
        leftValue: _formatMillimeter(report.leftFirstMetaJointHeight),
        rightValue: _formatMillimeter(report.rightFirstMetaJointHeight),
        icon: Icons.vertical_align_top,
        description: l10n.metatarsalJointDescription,
      ),
    ];

    return _buildExpandableSectionCard(
      title: l10n.anatomicalMeasurements,
      subtitle: l10n.anatomicalMeasurementsSubtitle,
      icon: Icons.straighten_outlined,
      initiallyExpanded: false,
      child: AnalysisComparisonTable(values: measurements),
    );
  }
  // ---------------------------------------------------------------------------
  // Evaluation findings
  // ---------------------------------------------------------------------------

  Widget _buildEvaluationFindingsSection(CustomerAnalysisResult result) {
    final l10n = AppLocalizations.of(context);
    final report = _reportFor(result);
    final leftFoot = result.leftFoot;
    final rightFoot = result.rightFoot;

    final findings = <AnalysisFindingComparisonData>[
      AnalysisFindingComparisonData(
        title: l10n.archStructure,
        subtitle: l10n.archStructureSubtitle,
        icon: Icons.architecture_outlined,
        leftDescription: _isEnglish
            ? _archAssessmentLabel(report?.leftArchIndex)
            : leftFoot.archSupportNeed.trim().isNotEmpty
            ? leftFoot.archSupportNeed
            : _safeText(
                report?.recommendationText,
                fallback: l10n.leftArchDescriptionUnavailable,
              ),
        rightDescription: _isEnglish
            ? _archAssessmentLabel(report?.rightArchIndex)
            : rightFoot.archSupportNeed.trim().isNotEmpty
            ? rightFoot.archSupportNeed
            : _safeText(
                report?.recommendationText,
                fallback: l10n.rightArchDescriptionUnavailable,
              ),
        images: [
          AnalysisFindingImage(
            title: l10n.archHeightMap,
            leftUrl: _evaluationVisualUrls['arch_left_image'],
            rightUrl: _evaluationVisualUrls['arch_right_image'],
            assessments: [
              AnalysisAssessmentData(
                title: l10n.archIndex,
                leftLabel: _assessmentWithValue(
                  _archAssessmentLabel(report?.leftArchIndex),
                  _formatDecimal(report?.leftArchIndex),
                ),
                rightLabel: _assessmentWithValue(
                  _archAssessmentLabel(report?.rightArchIndex),
                  _formatDecimal(report?.rightArchIndex),
                ),
                leftPosition: _archHeatPosition(report?.leftArchIndex),
                rightPosition: _archHeatPosition(report?.rightArchIndex),
              ),
            ],
          ),
          AnalysisFindingImage(
            title: l10n.archSectionImage,
            leftUrl: _evaluationVisualUrls['arch_section_left'],
            rightUrl: _evaluationVisualUrls['arch_section_right'],
            assessments: [
              AnalysisAssessmentData(
                title: l10n.archWidthIndex,
                leftLabel: _assessmentWithValue(
                  _archWidthAssessmentLabel(report?.leftArchWidthIndex),
                  _formatDecimal(report?.leftArchWidthIndex),
                ),
                rightLabel: _assessmentWithValue(
                  _archWidthAssessmentLabel(report?.rightArchWidthIndex),
                  _formatDecimal(report?.rightArchWidthIndex),
                ),
                leftPosition: _archWidthHeatPosition(
                  report?.leftArchWidthIndex,
                ),
                rightPosition: _archWidthHeatPosition(
                  report?.rightArchWidthIndex,
                ),
              ),
            ],
          ),
        ],
        metrics: [
          AnalysisComparisonValue(
            label: l10n.archHeight,
            leftValue: _formatMillimeter(report?.leftArchHeight),
            rightValue: _formatMillimeter(report?.rightArchHeight),
            icon: Icons.height,
          ),
        ],
      ),
      AnalysisFindingComparisonData(
        title: l10n.footFormHallux,
        subtitle: l10n.footFormHalluxSubtitle,
        icon: Icons.accessibility_new_outlined,
        leftDescription: _isEnglish
            ? _halluxDescription(report?.leftHalluxAngle)
            : leftFoot.mainFinding.trim().isNotEmpty
            ? leftFoot.mainFinding
            : _halluxDescription(report?.leftHalluxAngle),
        rightDescription: _isEnglish
            ? _halluxDescription(report?.rightHalluxAngle)
            : rightFoot.mainFinding.trim().isNotEmpty
            ? rightFoot.mainFinding
            : _halluxDescription(report?.rightHalluxAngle),
        images: [
          AnalysisFindingImage(
            title: l10n.footImage,
            leftUrl: _evaluationVisualUrls['foot_2d_left'],
            rightUrl: _evaluationVisualUrls['foot_2d_right'],
            assessments: [
              AnalysisAssessmentData(
                title: l10n.halluxAngleType,
                leftLabel: _assessmentWithValue(
                  _halluxAssessmentLabel(
                    report?.leftHalluxType,
                    report?.leftHalluxAngle,
                  ),
                  _formatDegree(report?.leftHalluxAngle),
                ),
                rightLabel: _assessmentWithValue(
                  _halluxAssessmentLabel(
                    report?.rightHalluxType,
                    report?.rightHalluxAngle,
                  ),
                  _formatDegree(report?.rightHalluxAngle),
                ),
                leftPosition: HalluxHeatPositionMapper.resolve(
                  angle: report?.leftHalluxAngle,
                  type: report?.leftHalluxType,
                ),
                rightPosition: HalluxHeatPositionMapper.resolve(
                  angle: report?.rightHalluxAngle,
                  type: report?.rightHalluxType,
                ),
              ),
            ],
          ),
        ],
        metrics: [
          AnalysisComparisonValue(
            label: l10n.footWidth,
            leftValue: _formatMillimeter(report?.leftFootWidth),
            rightValue: _formatMillimeter(report?.rightFootWidth),
            icon: Icons.swap_horiz,
          ),
          AnalysisComparisonValue(
            label: l10n.toeWidth,
            leftValue: _formatMillimeter(report?.leftToeWidth),
            rightValue: _formatMillimeter(report?.rightToeWidth),
            icon: Icons.compare_arrows,
          ),
        ],
      ),
      AnalysisFindingComparisonData(
        title: l10n.rearfootPronation,
        subtitle: l10n.rearfootPronationSubtitle,
        icon: Icons.rotate_90_degrees_ccw,
        leftDescription: _isEnglish
            ? _pronationDescription(report?.leftPronatorAngle)
            : leftFoot.balanceSummary.trim().isNotEmpty
            ? leftFoot.balanceSummary
            : _pronationDescription(report?.leftPronatorAngle),
        rightDescription: _isEnglish
            ? _pronationDescription(report?.rightPronatorAngle)
            : rightFoot.balanceSummary.trim().isNotEmpty
            ? rightFoot.balanceSummary
            : _pronationDescription(report?.rightPronatorAngle),
        images: [
          AnalysisFindingImage(
            title: l10n.ankleAlignment,
            leftUrl: _evaluationVisualUrls['pronator_left'],
            rightUrl: _evaluationVisualUrls['pronator_right'],
            assessments: [
              AnalysisAssessmentData(
                title: l10n.pronationAngleHeelType,
                leftLabel: _assessmentWithValue(
                  _angleAssessmentLabel(
                    report?.leftPronatorAngle,
                    mild: 4,
                    moderate: 8,
                    severe: 15,
                  ),
                  _formatDegree(report?.leftPronatorAngle),
                ),
                rightLabel: _assessmentWithValue(
                  _angleAssessmentLabel(
                    report?.rightPronatorAngle,
                    mild: 4,
                    moderate: 8,
                    severe: 15,
                  ),
                  _formatDegree(report?.rightPronatorAngle),
                ),
                leftPosition: _angleHeatPosition(report?.leftPronatorAngle, 15),
                rightPosition: _angleHeatPosition(
                  report?.rightPronatorAngle,
                  15,
                ),
              ),
              AnalysisAssessmentData(
                title: l10n.kneeAngleAlignment,
                leftLabel: _assessmentWithValue(
                  _angleAssessmentLabel(
                    report?.leftKneeAngle,
                    mild: 4,
                    moderate: 8,
                    severe: 15,
                  ),
                  _formatDegree(report?.leftKneeAngle),
                ),
                rightLabel: _assessmentWithValue(
                  _angleAssessmentLabel(
                    report?.rightKneeAngle,
                    mild: 4,
                    moderate: 8,
                    severe: 15,
                  ),
                  _formatDegree(report?.rightKneeAngle),
                ),
                leftPosition: _angleHeatPosition(report?.leftKneeAngle, 15),
                rightPosition: _angleHeatPosition(report?.rightKneeAngle, 15),
              ),
            ],
          ),
        ],
        metrics: [],
      ),
    ];

    return _buildSectionCard(
      title: l10n.findingsAndImages,
      subtitle: l10n.findingsAndImagesSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingEvaluationVisuals) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              l10n.loadingImages,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
          ],
          if (_evaluationVisualsError != null &&
              !_isLoadingEvaluationVisuals) ...[
            _errorInformationState(
              _evaluationVisualsError!,
              onRetry: _loadEvaluationVisuals,
            ),
            const SizedBox(height: 14),
          ],
          _buildFindingTileColumns(findings),
        ],
      ),
    );
  }

  Widget _buildFindingTileColumns(
    List<AnalysisFindingComparisonData> findings,
  ) {
    Widget buildColumn(Iterable<AnalysisFindingComparisonData> items) {
      return Column(
        children: items
            .map(
              (finding) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnalysisFindingComparisonPanel(
                  data: finding,
                  imageBuilder: _buildComparisonImage,
                ),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return buildColumn(findings);
        }

        final left = findings.isEmpty
            ? <AnalysisFindingComparisonData>[]
            : <AnalysisFindingComparisonData>[findings.first];
        final right = findings.length <= 1
            ? <AnalysisFindingComparisonData>[]
            : findings.skip(1).toList();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buildColumn(left)),
            const SizedBox(width: 14),
            Expanded(child: buildColumn(right)),
          ],
        );
      },
    );
  }

  Widget _buildProductSection() {
    final l10n = AppLocalizations.of(context);
    return _buildSectionCard(
      title: l10n.productAssessment,
      subtitle: l10n.productAssessmentSubtitle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.design_services_outlined,
              color: Colors.teal,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.productRecommended,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(l10n.productNotDetermined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonImage(String? source, String title) {
    final l10n = AppLocalizations.of(context);
    final aspectRatio = _evaluationImageAspectRatio(title);
    final normalized = (source ?? '').trim();
    if (normalized.isEmpty) {
      return AspectRatio(
        aspectRatio: aspectRatio,
        child: _imageUnavailableState(l10n.imageNotFound),
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _evaluationImageTile(
        title: title,
        source: normalized,
        fit:
            (title.toLowerCase().contains('ark yükseklik') ||
                title.toLowerCase().contains('arch height'))
            ? BoxFit.cover
            : BoxFit.contain,
      ),
    );
  }

  double _evaluationImageAspectRatio(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('ark kesit') ||
        normalized.contains('cross-section')) {
      return 1.9;
    }
    if (normalized.contains('ark yükseklik') ||
        normalized.contains('arch height')) {
      return 0.58;
    }
    if (normalized.contains('ayak-bilek') ||
        normalized.contains('foot-ankle')) {
      return 1.15;
    }
    return 0.68;
  }

  Widget _evaluationImageTile({
    required String title,
    required String source,
    required BoxFit fit,
  }) {
    final normalizedSource = source.trim();

    return InkWell(
      onTap: () {
        _openImagePreview(title, normalizedSource);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image_outlined, size: 17, color: Colors.teal),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(Icons.open_in_full, size: 16, color: Colors.black45),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildNetworkImage(normalizedSource, fit: fit),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String source, {BoxFit fit = BoxFit.contain}) {
    final l10n = AppLocalizations.of(context);
    if (source.trim().isEmpty) {
      return _imageUnavailableState(l10n.imagePathNotFound);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: Image.network(
        source,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'Görsel gösterilemedi:\n'
            '$source\n'
            '$error',
          );

          return _imageUnavailableState(l10n.imageCouldNotOpen);
        },
      ),
    );
  }

  Widget _imageUnavailableState(String message) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: Colors.grey.shade500,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _openImagePreview(String title, String source) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050, maxHeight: 780),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.close,
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 8,
                        child: Center(
                          child: Image.network(
                            source,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const CircularProgressIndicator();
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Padding(
                                padding: const EdgeInsets.all(30),
                                child: Text(l10n.imageCouldNotOpen),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _halluxDescription(double? angle) {
    final l10n = AppLocalizations.of(context);
    if (angle == null) {
      return l10n.halluxNoData;
    }

    final absolute = angle.abs();

    if (absolute <= 10) {
      return l10n.halluxNormal;
    }

    if (absolute <= 20) {
      return l10n.halluxMild;
    }

    return l10n.halluxMarked;
  }

  String _pronationDescription(double? angle) {
    final l10n = AppLocalizations.of(context);
    if (angle == null) {
      return l10n.pronationNoData;
    }

    final absolute = angle.abs();

    if (absolute <= 4) {
      return l10n.pronationNormal;
    }

    if (absolute <= 8) {
      return l10n.pronationMild;
    }

    return l10n.pronationMarked;
  }

  // ---------------------------------------------------------------------------
  // Pressure measurements
  // ---------------------------------------------------------------------------

  Widget _buildPressureMeasurementsSection() {
    final l10n = AppLocalizations.of(context);
    return _buildSectionCard(
      title: l10n.plantarPressureMeasurements,
      subtitle: l10n.plantarPressureSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingPressureRecords)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_pressureRecordsError != null)
            _errorInformationState(
              _pressureRecordsError!,
              onRetry: _loadPressureRecordings,
            )
          else if (_pressureRecordings.isEmpty)
            _emptyInformationState(
              icon: Icons.speed_outlined,
              message: l10n.noPressureRecordings,
            )
          else ...[
            _buildPressureRecordingSelector(),
            const SizedBox(height: 16),
            _buildSelectedPressureRecording(),
          ],
        ],
      ),
    );
  }

  Widget _buildPressureRecordingSelector() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _pressureRecordings.map((recording) {
        final selected = recording.id == _selectedPressureRecording?.id;

        return InkWell(
          onTap: () {
            if (!selected) {
              _openPressureRecording(recording);
            }
          },
          borderRadius: BorderRadius.circular(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 235,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.indigo.withValues(alpha: 0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected ? Colors.indigo : Colors.grey.shade300,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monitor_heart_outlined,
                      size: 18,
                      color: selected ? Colors.indigo : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        recording.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(recording.recordedAt),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  '${l10n.framesRecorded(recording.frameCount)} • '
                  '${_formatDuration(recording.durationMs)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedPressureRecording() {
    final l10n = AppLocalizations.of(context);
    final recording = _selectedPressureRecording;

    if (recording == null) {
      return _emptyInformationState(
        icon: Icons.touch_app_outlined,
        message: l10n.selectPressureRecording,
      );
    }

    if (_isLoadingPressureData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pressureDataError != null) {
      return _errorInformationState(
        _pressureDataError!,
        onRetry: () {
          _openPressureRecording(recording);
        },
      );
    }

    final data = _selectedPressureData;

    if (data == null || data.frames.isEmpty) {
      return _buildPressureSummaryWithoutFrames(recording);
    }

    final frameIndex = _selectedPressureFrameIndex
        .clamp(0, data.frames.length - 1)
        .toInt();

    final frame = data.frames[frameIndex];

    final stats = _calculatePressureFrameStats(
      frame.matrix,
      threshold: data.threshold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 850;

            final heatmap = _buildPressureHeatmapPanel(
              data: data,
              frame: frame,
              frameIndex: frameIndex,
              stats: stats,
            );

            final metrics = _buildPressureMetricsPanel(
              data: data,
              stats: stats,
            );

            if (isNarrow) {
              return Column(
                children: [metrics, const SizedBox(height: 16), heatmap],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 1, child: metrics),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: heatmap),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPressureHeatmapPanel({
    required _PressureRecordingData data,
    required _PressureFrameData frame,
    required int frameIndex,
    required _PressureFrameStats stats,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.pressureHeatmap,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                l10n.frameCounter(frameIndex + 1, data.frames.length),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          AspectRatio(
            aspectRatio: 452 / 344,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      _selectPressurePoint(
                        position: details.localPosition,
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        matrix: frame.matrix,
                        data: data,
                        stats: stats,
                      );
                    },
                    child: CustomPaint(
                      painter: _PressureHeatmapPainter(
                        matrix: frame.matrix,
                        configuredMaxValue: data.maxVisualValue,
                        threshold: data.threshold,
                        centerOfPressureX: stats.centerOfPressureX,
                        centerOfPressureY: stats.centerOfPressureY,
                        selectedRow: _selectedPressurePoint?.row,
                        selectedCol: _selectedPressurePoint?.col,
                        selectedPressureKpa:
                            _selectedPressurePoint?.pressureKpa,
                        selectedForceNewton:
                            _selectedPressurePoint?.forceNewton,
                        physicalValueUnavailableLabel:
                            l10n.physicalValueUnavailable,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (data.frames.length > 1)
            Slider(
              min: 0,
              max: (data.frames.length - 1).toDouble(),
              divisions: data.frames.length - 1,
              value: frameIndex.toDouble(),
              label: '${frameIndex + 1}',
              onChanged: (value) {
                setState(() {
                  _selectedPressureFrameIndex = value.round();
                  _selectedPressurePoint = null;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPressureMetricsPanel({
    required _PressureRecordingData data,
    required _PressureFrameStats stats,
  }) {
    final l10n = AppLocalizations.of(context);
    final totalLoad = stats.totalLoad;

    final leftPercent = totalLoad <= 0 ? 0.0 : stats.leftLoad / totalLoad * 100;

    final rightPercent = totalLoad <= 0
        ? 0.0
        : stats.rightLoad / totalLoad * 100;

    final forefootPercent = totalLoad <= 0
        ? 0.0
        : stats.forefootLoad / totalLoad * 100;

    final heelPercent = totalLoad <= 0 ? 0.0 : stats.heelLoad / totalLoad * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.loadDistribution,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (data.weightKg != null) ...[
            const SizedBox(height: 13),
            _pressureMetricTile(
              l10n.weight,
              '${data.weightKg!.toStringAsFixed(1)} kg',
              Icons.monitor_weight_outlined,
            ),
          ],
          const SizedBox(height: 17),
          _percentageDistribution(
            title: l10n.leftRightLoad,
            firstLabel: l10n.left,
            firstValue: leftPercent,
            secondLabel: l10n.right,
            secondValue: rightPercent,
          ),
          const SizedBox(height: 15),
          _percentageDistribution(
            title: l10n.forefootHeelLoad,
            firstLabel: l10n.forefoot,
            firstValue: forefootPercent,
            secondLabel: l10n.heel,
            secondValue: heelPercent,
          ),
        ],
      ),
    );
  }

  void _selectPressurePoint({
    required Offset position,
    required Size size,
    required List<List<double>> matrix,
    required _PressureRecordingData data,
    required _PressureFrameStats stats,
  }) {
    if (matrix.isEmpty || size.width <= 0 || size.height <= 0) return;
    final rows = matrix.length;
    final cols = matrix.map((row) => row.length).fold<int>(0, math.max);
    if (rows <= 0 || cols <= 0) return;

    final col = (position.dx / size.width * cols).floor().clamp(0, cols - 1);
    final row = (position.dy / size.height * rows).floor().clamp(0, rows - 1);
    final value = col < matrix[row].length ? matrix[row][col] : 0.0;

    double? forceNewton;
    double? pressureKpa;
    final weightKg = data.weightKg;
    final cellAreaCm2 = data.cellAreaCm2;
    if (weightKg != null &&
        weightKg > 0 &&
        cellAreaCm2 != null &&
        cellAreaCm2 > 0 &&
        stats.totalLoad > 0) {
      forceNewton = weightKg * 9.80665 * (value / stats.totalLoad);
      pressureKpa = forceNewton / (cellAreaCm2 / 10000) / 1000;
    }

    setState(() {
      _selectedPressurePoint = _PressurePointSelection(
        row: row,
        col: col,
        forceNewton: forceNewton,
        pressureKpa: pressureKpa,
      );
    });
  }

  Widget _pressureMetricTile(String label, String value, IconData icon) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _percentageDistribution({
    required String title,
    required String firstLabel,
    required double firstValue,
    required String secondLabel,
    required double secondValue,
  }) {
    final normalizedFirst = (firstValue / 100).clamp(0.0, 1.0).toDouble();

    final firstFlex = math.max(1, (normalizedFirst * 1000).round());

    final secondFlex = math.max(1, ((1 - normalizedFirst) * 1000).round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: firstFlex,
                  child: Container(color: Colors.teal),
                ),
                Expanded(
                  flex: secondFlex,
                  child: Container(color: Colors.indigo),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                '$firstLabel %${firstValue.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '$secondLabel %${secondValue.toStringAsFixed(1)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPressureSummaryWithoutFrames(
    SessionPressureRecordingModel recording,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recording.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pressureMetricTile(
                l10n.frameCount,
                '${recording.frameCount}',
                Icons.filter_frames,
              ),
              _pressureMetricTile(
                l10n.duration,
                _formatDuration(recording.durationMs),
                Icons.timer_outlined,
              ),
              _pressureMetricTile(
                l10n.maximumRawValue,
                recording.maxPressure?.toStringAsFixed(1) ?? '—',
                Icons.trending_up,
              ),
              _pressureMetricTile(
                l10n.averageRawValue,
                recording.avgPressure?.toStringAsFixed(2) ?? '—',
                Icons.analytics_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  _PressureFrameStats _calculatePressureFrameStats(
    List<List<double>> matrix, {
    required double threshold,
  }) {
    if (matrix.isEmpty) {
      return const _PressureFrameStats.empty();
    }

    final rows = matrix.length;

    final cols = matrix
        .map((row) => row.length)
        .fold<int>(0, (current, value) => math.max(current, value));

    double totalLoad = 0;
    double leftLoad = 0;
    double rightLoad = 0;
    double forefootLoad = 0;
    double heelLoad = 0;

    double maxValue = 0;
    double weightedX = 0;
    double weightedY = 0;

    double contactSum = 0;
    int contactCellCount = 0;

    for (int row = 0; row < rows; row++) {
      final rowData = matrix[row];

      for (int col = 0; col < rowData.length; col++) {
        final value = rowData[col];

        if (value > maxValue) {
          maxValue = value;
        }

        if (value <= threshold) {
          continue;
        }

        totalLoad += value;
        contactSum += value;
        contactCellCount++;

        weightedX += col * value;
        weightedY += row * value;

        if (col < cols / 2) {
          leftLoad += value;
        } else {
          rightLoad += value;
        }

        // PressureMeasurementDialog içindeki matris yönüne uygun:
        // üst satırlar topuk, alt satırlar ön ayak kabul edilir.
        if (row < rows / 2) {
          heelLoad += value;
        } else {
          forefootLoad += value;
        }
      }
    }

    return _PressureFrameStats(
      maxValue: maxValue,
      totalLoad: totalLoad,
      averageContactValue: contactCellCount == 0
          ? 0
          : contactSum / contactCellCount,
      contactCellCount: contactCellCount,
      leftLoad: leftLoad,
      rightLoad: rightLoad,
      forefootLoad: forefootLoad,
      heelLoad: heelLoad,
      centerOfPressureX: totalLoad <= 0 ? null : weightedX / totalLoad,
      centerOfPressureY: totalLoad <= 0 ? null : weightedY / totalLoad,
    );
  }

  // ---------------------------------------------------------------------------
  // Generic cards and states
  // ---------------------------------------------------------------------------

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
          ],
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildExpandableSectionCard({
    required String title,
    required Widget child,
    required IconData icon,
    String? subtitle,
    bool initiallyExpanded = false,
  }) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.teal, size: 21),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          subtitle: subtitle == null || subtitle.trim().isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                  ),
                ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _emptyInformationState({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorInformationState(
    String message, {
    required VoidCallback onRetry,
  }) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.red, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    );
  }
}

// -----------------------------------------------------------------------------
// Pressure heatmap
// -----------------------------------------------------------------------------

class _PressureHeatmapPainter extends CustomPainter {
  final List<List<double>> matrix;
  final double configuredMaxValue;
  final double threshold;
  final double? centerOfPressureX;
  final double? centerOfPressureY;
  final int? selectedRow;
  final int? selectedCol;
  final double? selectedPressureKpa;
  final double? selectedForceNewton;
  final String physicalValueUnavailableLabel;

  const _PressureHeatmapPainter({
    required this.matrix,
    required this.configuredMaxValue,
    required this.threshold,
    required this.centerOfPressureX,
    required this.centerOfPressureY,
    required this.selectedRow,
    required this.selectedCol,
    required this.selectedPressureKpa,
    required this.selectedForceNewton,
    required this.physicalValueUnavailableLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF07111F),
    );

    if (matrix.isEmpty) return;

    final rows = matrix.length;

    final cols = matrix
        .map((row) => row.length)
        .fold<int>(0, (current, value) => math.max(current, value));

    if (rows <= 0 || cols <= 0) return;

    double matrixMax = 0;

    for (final row in matrix) {
      for (final value in row) {
        if (value > matrixMax) {
          matrixMax = value;
        }
      }
    }

    final effectiveMax = configuredMaxValue > 0
        ? math.max(configuredMaxValue, matrixMax)
        : math.max(1.0, matrixMax);

    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        math.max(cellWidth, cellHeight) * 0.28,
      );

    for (int row = 0; row < rows; row++) {
      final rowData = matrix[row];

      for (int col = 0; col < cols; col++) {
        final value = col < rowData.length ? rowData[col] : 0.0;

        if (value <= threshold) continue;
        final normalized = (value / effectiveMax).clamp(0.0, 1.0).toDouble();
        paint.color = _heatmapColor(
          normalized,
        ).withValues(alpha: 0.78 + normalized * 0.22);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset((col + 0.5) * cellWidth, (row + 0.5) * cellHeight),
            width: cellWidth * 1.65,
            height: cellHeight * 1.65,
          ),
          paint,
        );
      }
    }

    if (centerOfPressureX != null && centerOfPressureY != null) {
      final center = Offset(
        (centerOfPressureX! + 0.5) * cellWidth,
        (centerOfPressureY! + 0.5) * cellHeight,
      );
      canvas.drawCircle(
        center,
        9,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        9,
        Paint()
          ..color = const Color(0xFF00E5FF)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(
        center - const Offset(13, 0),
        center + const Offset(13, 0),
        Paint()
          ..color = const Color(0xFF00E5FF)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        center - const Offset(0, 13),
        center + const Offset(0, 13),
        Paint()
          ..color = const Color(0xFF00E5FF)
          ..strokeWidth = 2,
      );
    }

    if (selectedRow != null && selectedCol != null) {
      final selected = Offset(
        (selectedCol! + 0.5) * cellWidth,
        (selectedRow! + 0.5) * cellHeight,
      );
      canvas.drawCircle(
        selected,
        8,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );

      final label = selectedPressureKpa == null || selectedForceNewton == null
          ? physicalValueUnavailableLabel
          : '${selectedPressureKpa!.toStringAsFixed(1)} kPa  •  '
                '${selectedForceNewton!.toStringAsFixed(2)} N';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(120, size.width * 0.42));
      const padding = 8.0;
      final bubbleWidth = textPainter.width + padding * 2;
      final bubbleHeight = textPainter.height + padding * 2;
      var bubbleLeft = selected.dx + 14;
      if (bubbleLeft + bubbleWidth > size.width - 4) {
        bubbleLeft = selected.dx - bubbleWidth - 14;
      }
      bubbleLeft = bubbleLeft.clamp(4.0, size.width - bubbleWidth - 4);
      final bubbleTop = (selected.dy - bubbleHeight / 2).clamp(
        4.0,
        size.height - bubbleHeight - 4,
      );
      final bubbleRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleWidth, bubbleHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(bubbleRect, Paint()..color = const Color(0xE6222B45));
      canvas.drawRRect(
        bubbleRect,
        Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke,
      );
      textPainter.paint(
        canvas,
        Offset(bubbleRect.left + padding, bubbleRect.top + padding),
      );
    }
  }

  static Color _heatmapColor(double value) {
    if (value <= 0.20) {
      return Color.lerp(
        const Color(0xFF0D47A1),
        const Color(0xFF00BCD4),
        value / 0.20,
      )!;
    }

    if (value <= 0.40) {
      return Color.lerp(
        const Color(0xFF00BCD4),
        const Color(0xFF4CAF50),
        (value - 0.20) / 0.20,
      )!;
    }

    if (value <= 0.60) {
      return Color.lerp(
        const Color(0xFF4CAF50),
        const Color(0xFFFFEB3B),
        (value - 0.40) / 0.20,
      )!;
    }

    if (value <= 0.80) {
      return Color.lerp(
        const Color(0xFFFFEB3B),
        const Color(0xFFFF9800),
        (value - 0.60) / 0.20,
      )!;
    }

    return Color.lerp(
      const Color(0xFFFF9800),
      const Color(0xFFF44336),
      (value - 0.80) / 0.20,
    )!;
  }

  @override
  bool shouldRepaint(covariant _PressureHeatmapPainter oldDelegate) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.configuredMaxValue != configuredMaxValue ||
        oldDelegate.threshold != threshold ||
        oldDelegate.centerOfPressureX != centerOfPressureX ||
        oldDelegate.centerOfPressureY != centerOfPressureY ||
        oldDelegate.selectedRow != selectedRow ||
        oldDelegate.selectedCol != selectedCol ||
        oldDelegate.selectedPressureKpa != selectedPressureKpa ||
        oldDelegate.selectedForceNewton != selectedForceNewton ||
        oldDelegate.physicalValueUnavailableLabel !=
            physicalValueUnavailableLabel;
  }
}

// -----------------------------------------------------------------------------
// View data classes
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Pressure JSON models
// -----------------------------------------------------------------------------

class _PressureRecordingData {
  final int rows;
  final int cols;
  final int durationMs;

  final double maxVisualValue;
  final double threshold;

  final double? weightKg;
  final double? cellAreaCm2;

  final List<_PressureFrameData> frames;

  const _PressureRecordingData({
    required this.rows,
    required this.cols,
    required this.durationMs,
    required this.maxVisualValue,
    required this.threshold,
    required this.weightKg,
    required this.cellAreaCm2,
    required this.frames,
  });

  factory _PressureRecordingData.fromJson(Map<String, dynamic> map) {
    final visualSettings = _asMap(map['visual_settings']);

    final anthropometric = _asMap(map['anthropometric']);

    final rawFrames = _asList(map['frames']);

    final frames = rawFrames
        .map((item) => _PressureFrameData.fromJson(_asMap(item)))
        .where((frame) => frame.matrix.isNotEmpty)
        .toList();

    final detectedRows = frames.isEmpty ? 0 : frames.first.matrix.length;

    final detectedCols = frames.isEmpty || frames.first.matrix.isEmpty
        ? 0
        : frames.first.matrix.first.length;

    final rows = _toInt(map['rows']) ?? detectedRows;
    final cols = _toInt(map['cols']) ?? detectedCols;

    final storedCellAreaCm2 = _toDouble(
      anthropometric['cell_area_cm2'] ?? map['cell_area_cm2'],
    );

    double? calculatedCellAreaCm2 = storedCellAreaCm2;

    // PressureMeasurementDialog içindeki sensör ölçüsü:
    // 452 × 344 mm, 64 × 32 hücre.
    if (calculatedCellAreaCm2 == null && rows > 0 && cols > 0) {
      final cellWidthMm = 452.0 / cols;
      final cellHeightMm = 344.0 / rows;

      calculatedCellAreaCm2 = (cellWidthMm * cellHeightMm) / 100;
    }

    return _PressureRecordingData(
      rows: rows,
      cols: cols,
      durationMs: _toInt(map['duration_ms']) ?? 0,
      maxVisualValue:
          _toDouble(visualSettings['max_value'] ?? map['max_value']) ?? 0,
      threshold:
          _toDouble(visualSettings['threshold'] ?? map['threshold']) ?? 0,
      weightKg: _toDouble(anthropometric['weight_kg'] ?? map['weight_kg']),
      cellAreaCm2: calculatedCellAreaCm2,
      frames: frames,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return <dynamic>[];
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}

class _PressureFrameData {
  final DateTime? timestamp;
  final List<List<double>> matrix;

  const _PressureFrameData({required this.timestamp, required this.matrix});

  factory _PressureFrameData.fromJson(Map<String, dynamic> map) {
    final rawMatrix = map['matrix'];

    final matrix = <List<double>>[];

    if (rawMatrix is List) {
      for (final rawRow in rawMatrix) {
        if (rawRow is! List) continue;

        matrix.add(
          rawRow.map((value) {
            if (value is num) {
              return value.toDouble();
            }

            return double.tryParse(value.toString()) ?? 0.0;
          }).toList(),
        );
      }
    }

    return _PressureFrameData(
      timestamp: DateTime.tryParse((map['timestamp'] ?? '').toString()),
      matrix: matrix,
    );
  }
}

class _PressurePointSelection {
  final int row;
  final int col;
  final double? forceNewton;
  final double? pressureKpa;

  const _PressurePointSelection({
    required this.row,
    required this.col,
    required this.forceNewton,
    required this.pressureKpa,
  });
}

class _PressureFrameStats {
  final double maxValue;
  final double totalLoad;
  final double averageContactValue;
  final int contactCellCount;

  final double leftLoad;
  final double rightLoad;
  final double forefootLoad;
  final double heelLoad;

  final double? centerOfPressureX;
  final double? centerOfPressureY;

  const _PressureFrameStats({
    required this.maxValue,
    required this.totalLoad,
    required this.averageContactValue,
    required this.contactCellCount,
    required this.leftLoad,
    required this.rightLoad,
    required this.forefootLoad,
    required this.heelLoad,
    required this.centerOfPressureX,
    required this.centerOfPressureY,
  });

  const _PressureFrameStats.empty()
    : maxValue = 0,
      totalLoad = 0,
      averageContactValue = 0,
      contactCellCount = 0,
      leftLoad = 0,
      rightLoad = 0,
      forefootLoad = 0,
      heelLoad = 0,
      centerOfPressureX = null,
      centerOfPressureY = null;
}
