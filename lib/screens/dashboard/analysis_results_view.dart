import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_session_pressure_repository.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_analysis_result_model.dart';
import 'package:oy_site/models/session_pressure_recording_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum FootSelectionSide {
  left,
  right,
}

class AnalysisResultsView extends StatefulWidget {
  final AppUser currentUser;
  final String pageTitle;
  final List<CustomerAnalysisResult> results;
  final int initialSelectedIndex;

  const AnalysisResultsView({
    super.key,
    required this.currentUser,
    required this.pageTitle,
    required this.results,
    this.initialSelectedIndex = 0,
  });

  @override
  State<AnalysisResultsView> createState() =>
      _AnalysisResultsViewState();
}

class _AnalysisResultsViewState extends State<AnalysisResultsView> {
  SupabaseClient get _client => Supabase.instance.client;

  final SupabaseSessionPressureRepository _pressureRepository =
      SupabaseSessionPressureRepository();

  late int _selectedIndex;

  FootSelectionSide _selectedFootSide =
      FootSelectionSide.left;

  // ---------------------------------------------------------------------------
  // Değerlendirme görselleri
  // ---------------------------------------------------------------------------

  bool _isLoadingEvaluationVisuals = false;
  String? _evaluationVisualsError;

  /// session_scan_files.file_type → signed URL
  final Map<String, String> _evaluationVisualUrls = {};

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

  CustomerAnalysisResult? get _selectedResult {
    if (widget.results.isEmpty) return null;

    if (_selectedIndex < 0 ||
        _selectedIndex >= widget.results.length) {
      return null;
    }

    return widget.results[_selectedIndex];
  }

  bool get _isLeftSelected {
    return _selectedFootSide == FootSelectionSide.left;
  }

  String get _displayPageTitle {
    final title = widget.pageTitle.trim();

    if (title.isEmpty) {
      return 'Ayak Sağlığı Değerlendirmesi';
    }

    return title
        .replaceAll(
          RegExp('analiz', caseSensitive: false),
          'Değerlendirme',
        )
        .replaceAll(
          RegExp('analizi', caseSensitive: false),
          'Değerlendirmesi',
        );
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
    await Future.wait([
      _loadEvaluationVisuals(),
      _loadPressureRecordings(),
    ]);
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
      _evaluationVisualsError = null;

      _pressureRecordings = [];
      _selectedPressureRecording = null;
      _selectedPressureData = null;
      _selectedPressureFrameIndex = 0;
      _pressureRecordsError = null;
      _pressureDataError = null;
    });

    await _reloadSelectedSessionData();
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
        _evaluationVisualsError =
            'Bu değerlendirme için oturum ID bulunamadı.';
        _isLoadingEvaluationVisuals = false;
      });

      return;
    }

    final requestedSessionId = sessionId;

    setState(() {
      _isLoadingEvaluationVisuals = true;
      _evaluationVisualsError = null;
      _evaluationVisualUrls.clear();
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
          .map(
            (item) => Map<String, dynamic>.from(
              item as Map,
            ),
          )
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

      for (final row in rows) {
        final fileType =
            row['file_type']?.toString().trim() ?? '';

        if (!supportedImageTypes.contains(fileType)) {
          continue;
        }

        // Aynı türden birden fazla kayıt varsa sorgu en yeniden
        // eskiye sıralandığı için ilk kayıt kullanılır.
        if (urls.containsKey(fileType)) {
          continue;
        }

        final bucket =
            row['storage_bucket']?.toString().trim() ?? '';

        final storagePath =
            row['storage_path']?.toString().trim() ?? '';

        if (bucket.isEmpty || storagePath.isEmpty) {
          continue;
        }

        try {
          final signedUrl = await _client.storage
              .from(bucket)
              .createSignedUrl(
                _normalizeStoragePath(storagePath),
                60 * 60 * 6,
              );

          urls[fileType] = signedUrl;
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

        _isLoadingEvaluationVisuals = false;

        if (urls.isEmpty) {
          _evaluationVisualsError =
              'Bu oturum için kullanılabilir değerlendirme '
              'görseli bulunamadı.';
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
        _evaluationVisualsError =
            'Değerlendirme görselleri yüklenemedi: $e';
      });

      debugPrint(
        'Değerlendirme görselleri yüklenemedi: $e',
      );
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
    });

    try {
      final records =
          await _pressureRepository.getRecordingsBySessionId(
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
        _pressureRecordsError =
            'Basınç ölçüm kayıtları yüklenemedi: $e';
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
        jsonMap = Map<String, dynamic>.from(
          recording.rawFramesJson!,
        );
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
            .download(
              _normalizeStoragePath(storagePath),
            );

        final decoded = jsonDecode(
          utf8.decode(bytes),
        );

        if (decoded is! Map) {
          throw Exception(
            'Basınç kayıt dosyasının JSON yapısı geçersiz.',
          );
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
        _pressureDataError =
            'Basınç kayıt verisi açılamadı: $e';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Format helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '—';

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int durationMs) {
    if (durationMs <= 0) return '—';

    final duration = Duration(milliseconds: durationMs);

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds =
        duration.inMilliseconds.remainder(1000);

    if (minutes > 0) {
      return '$minutes dk '
          '${seconds.toString().padLeft(2, '0')} sn';
    }

    return '$seconds.${milliseconds ~/ 100} sn';
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

  String _safeText(
    String? value, {
    String fallback = '—',
  }) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? fallback : normalized;
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _sideLabel() {
    return _isLeftSelected ? 'Sol Ayak' : 'Sağ Ayak';
  }

  CustomerFootSummary _selectedFoot(
    CustomerAnalysisResult result,
  ) {
    return _isLeftSelected
        ? result.leftFoot
        : result.rightFoot;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final selected = _selectedResult;

    if (widget.results.isEmpty || selected == null) {
      return const Center(
        child: Text(
          'Değerlendirme sonucu bulunamadı.',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1240,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(selected),
              const SizedBox(height: 18),
              _buildSectionCard(
                title: 'Ölçüm Geçmişi',
                subtitle:
                    'Görüntülemek istediğiniz ölçüm oturumunu seçin.',
                child: _buildSessionCards(),
              ),
              const SizedBox(height: 18),
              _buildFootSelectionSection(),
              const SizedBox(height: 18),
              _buildAnatomicalMeasurementsSection(selected),
              const SizedBox(height: 18),
              _buildEvaluationFindingsSection(selected),
              const SizedBox(height: 18),
              _buildPressureMeasurementsSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(CustomerAnalysisResult result) {
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
              color: Colors.teal.withOpacity(0.10),
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
              Text(
                _displayPageTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                '3D anatomik ölçümler, görsel incelemeler ve '
                'plantar basınç ölçüm sonuçları.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          );

          final metadata = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Column(
              crossAxisAlignment: isNarrow
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                _headerMetaRow(
                  Icons.badge_outlined,
                  result.sessionCode,
                ),
                const SizedBox(height: 7),
                _headerMetaRow(
                  Icons.calendar_today_outlined,
                  _formatDate(result.analysisDate),
                ),
                const SizedBox(height: 7),
                _headerMetaRow(
                  Icons.location_on_outlined,
                  result.locationLabel.trim().isEmpty
                      ? 'Konum belirtilmedi'
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

  Widget _headerMetaRow(
    IconData icon,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.teal,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
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
      children: List.generate(
        widget.results.length,
        (index) {
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
                    ? Colors.teal.withOpacity(0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? Colors.teal
                      : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                  ),
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
        },
      ),
    );
  }

  Widget _smallInformationRow(
    IconData icon,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Foot selection
  // ---------------------------------------------------------------------------

  Widget _buildFootSelectionSection() {
    return _buildSectionCard(
      title: 'Değerlendirilen Ayak',
      subtitle:
          'Anatomik değerler ve görseller seçilen ayağa göre güncellenir.',
      child: Row(
        children: [
          Expanded(
            child: _footSideButton(
              label: 'Sol Ayak',
              icon: Icons.keyboard_double_arrow_left,
              selected: _isLeftSelected,
              onTap: () {
                setState(() {
                  _selectedFootSide = FootSelectionSide.left;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _footSideButton(
              label: 'Sağ Ayak',
              icon: Icons.keyboard_double_arrow_right,
              selected: !_isLeftSelected,
              onTap: () {
                setState(() {
                  _selectedFootSide = FootSelectionSide.right;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _footSideButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.teal.withOpacity(0.10)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.teal
                : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? Colors.teal
                  : Colors.grey.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected
                    ? Colors.teal
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Anatomical measurements
  // ---------------------------------------------------------------------------

  Widget _buildAnatomicalMeasurementsSection(
    CustomerAnalysisResult result,
  ) {
    final report = result.parsedReport;

    if (report == null) {
      return _buildExpandableSectionCard(
        title: 'Anatomik Ölçümler',
        subtitle:
            '${_sideLabel()} için 3D tarama değerleri.',
        icon: Icons.straighten_outlined,
        initiallyExpanded: false,
        child: _emptyInformationState(
          icon: Icons.straighten_outlined,
          message:
              'Bu ölçüm için ayrıştırılmış 3D tarama '
              'raporu bulunmuyor.',
        ),
      );
    }

    final measurements = <_AnatomicalMeasurement>[
      _AnatomicalMeasurement(
        title: 'Ayak Uzunluğu',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftFootLength
              : report.rightFootLength,
        ),
        icon: Icons.straighten,
        description:
            'Topuk ile en uzun parmak arasındaki mesafe.',
      ),
      _AnatomicalMeasurement(
        title: 'Taban Uzunluğu',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftSoleLength
              : report.rightSoleLength,
        ),
        icon: Icons.linear_scale,
        description:
            'Ayak tabanının anatomik temas uzunluğu.',
      ),
      _AnatomicalMeasurement(
        title: 'Ayak Genişliği',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftFootWidth
              : report.rightFootWidth,
        ),
        icon: Icons.swap_horiz,
        description:
            'Ön ayaktaki en geniş anatomik mesafe.',
      ),
      _AnatomicalMeasurement(
        title: 'Parmak Önü Genişliği',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftToeWidth
              : report.rightToeWidth,
        ),
        icon: Icons.compare_arrows,
        description:
            'Parmak kökleri seviyesindeki genişlik.',
      ),
      _AnatomicalMeasurement(
        title: 'Ark Uzunluğu',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftArchLength
              : report.rightArchLength,
        ),
        icon: Icons.architecture,
        description:
            'Medial longitudinal ark uzunluğu.',
      ),
      _AnatomicalMeasurement(
        title: 'Ark Yüksekliği',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftArchHeight
              : report.rightArchHeight,
        ),
        icon: Icons.height,
        description:
            'Ayak kemerinin maksimum yüksekliği.',
      ),
      _AnatomicalMeasurement(
        title: 'Dış Ark Genişliği',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftArchOutsideWidth
              : report.rightArchOutsideWidth,
        ),
        icon: Icons.open_in_full,
        description:
            'Ark bölgesinin dış genişlik ölçümü.',
      ),
      _AnatomicalMeasurement(
        title: 'Topuk Genişliği',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftTotalHeelWidth
              : report.rightTotalHeelWidth,
        ),
        icon: Icons.horizontal_rule,
        description:
            'Topuk bölgesinin toplam genişliği.',
      ),
      _AnatomicalMeasurement(
        title: '1. Metatars Uzunluğu',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftFirstMetaLength
              : report.rightFirstMetaLength,
        ),
        icon: Icons.looks_one_outlined,
        description:
            'Birinci metatarsal anatomik uzunluğu.',
      ),
      _AnatomicalMeasurement(
        title: '5. Metatars Uzunluğu',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftFifthMetaLength
              : report.rightFifthMetaLength,
        ),
        icon: Icons.filter_5,
        description:
            'Beşinci metatarsal anatomik uzunluğu.',
      ),
      _AnatomicalMeasurement(
        title: 'Metatars Eklem Yüksekliği',
        value: _formatMillimeter(
          _isLeftSelected
              ? report.leftFirstMetaJointHeight
              : report.rightFirstMetaJointHeight,
        ),
        icon: Icons.vertical_align_top,
        description:
            'Birinci metatars eklem bölgesindeki yükseklik.',
      ),
      _AnatomicalMeasurement(
        title: 'Ayakkabı Numarası',
        value: _safeText(
          _isLeftSelected
              ? report.leftShoeSize
              : report.rightShoeSize,
        ),
        icon: Icons.shopping_bag_outlined,
        description:
            '3D tarama raporunda önerilen numara.',
      ),
    ];

    return _buildExpandableSectionCard(
      title: 'Anatomik Ölçümler',
      subtitle:
          '${_sideLabel()} için 3D tarama raporundan '
          'alınan anatomik veriler.',
      icon: Icons.straighten_outlined,
      initiallyExpanded: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount;

          if (constraints.maxWidth >= 1040) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 700) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth >= 440) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 1;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: measurements.length,
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 154,
            ),
            itemBuilder: (context, index) {
              return _buildAnatomicalMeasurementTile(
                measurements[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAnatomicalMeasurementTile(
    _AnatomicalMeasurement measurement,
  ) {
    final hasValue = measurement.value != '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasValue
            ? Colors.teal.withOpacity(0.045)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasValue
              ? Colors.teal.withOpacity(0.18)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: hasValue
                      ? Colors.teal.withOpacity(0.10)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  measurement.icon,
                  size: 18,
                  color: hasValue
                      ? Colors.teal
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  measurement.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            measurement.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: hasValue
                  ? Colors.teal.shade800
                  : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              measurement.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Evaluation findings
  // ---------------------------------------------------------------------------

  Widget _buildEvaluationFindingsSection(
    CustomerAnalysisResult result,
  ) {
    final report = result.parsedReport;
    final foot = _selectedFoot(result);

    final archImage = _isLeftSelected
        ? _evaluationVisualUrls['arch_left_image']
        : _evaluationVisualUrls['arch_right_image'];

    final archSectionImage = _isLeftSelected
        ? _evaluationVisualUrls['arch_section_left']
        : _evaluationVisualUrls['arch_section_right'];

    final foot2dImage = _isLeftSelected
        ? _evaluationVisualUrls['foot_2d_left']
        : _evaluationVisualUrls['foot_2d_right'];

    final pronatorImage = _isLeftSelected
        ? _evaluationVisualUrls['pronator_left']
        : _evaluationVisualUrls['pronator_right'];

    final archIndex = _isLeftSelected
        ? report?.leftArchIndex
        : report?.rightArchIndex;

    final archWidthIndex = _isLeftSelected
        ? report?.leftArchWidthIndex
        : report?.rightArchWidthIndex;

    final archType = _isLeftSelected
        ? report?.leftArchType
        : report?.rightArchType;

    final halluxAngle = _isLeftSelected
        ? report?.leftHalluxAngle
        : report?.rightHalluxAngle;

    final halluxType = _isLeftSelected
        ? report?.leftHalluxType
        : report?.rightHalluxType;

    final pronatorAngle = _isLeftSelected
        ? report?.leftPronatorAngle
        : report?.rightPronatorAngle;

    final heelType = _isLeftSelected
        ? report?.leftHeelType
        : report?.rightHeelType;

    final kneeAngle = _isLeftSelected
        ? report?.leftKneeAngle
        : report?.rightKneeAngle;

    final kneeType = _isLeftSelected
        ? report?.leftKneeType
        : report?.rightKneeType;

    final findings = <_EvaluationFindingPanelData>[
      _EvaluationFindingPanelData(
        title: 'Ark ve Kemer Yapısı',
        subtitle:
            'Ayak kemeri yüksekliği, genişliği ve yüzey formu.',
        icon: Icons.architecture_outlined,
        imageSource: archImage,
        secondaryImageSource: archSectionImage,
        imageTitle: 'Ark Yükseklik Haritası',
        secondaryImageTitle: 'Ark Kesit Görüntüsü',
        description: foot.archSupportNeed.trim().isNotEmpty
            ? foot.archSupportNeed
            : _safeText(
                report?.recommendationText,
                fallback:
                    'Ark yapısına ilişkin açıklama bulunmuyor.',
              ),
        metrics: [
          _FindingMetric(
            label: 'Ark Tipi',
            value: _safeText(
              archType,
              fallback: _safeText(foot.footType),
            ),
          ),
          _FindingMetric(
            label: 'Ark İndeksi',
            value: _formatDecimal(archIndex),
          ),
          _FindingMetric(
            label: 'Ark Genişlik İndeksi',
            value: _formatDecimal(archWidthIndex),
          ),
          _FindingMetric(
            label: 'Ark Yüksekliği',
            value: _formatMillimeter(
              _isLeftSelected
                  ? report?.leftArchHeight
                  : report?.rightArchHeight,
            ),
          ),
        ],
      ),
      _EvaluationFindingPanelData(
        title: 'Ayak Formu ve Başparmak Hizalanması',
        subtitle:
            'Ayak görünümü, ön ayak formu ve halluks açısı.',
        icon: Icons.accessibility_new_outlined,
        imageSource: foot2dImage,
        imageTitle: 'Ayak Görüntüsü',
        description: foot.mainFinding.trim().isNotEmpty
            ? foot.mainFinding
            : _halluxDescription(halluxAngle),
        metrics: [
          _FindingMetric(
            label: 'Halluks Açısı',
            value: _formatDegree(halluxAngle),
          ),
          _FindingMetric(
            label: 'Halluks Tipi',
            value: _safeText(halluxType),
          ),
          _FindingMetric(
            label: 'Ayak Genişliği',
            value: _formatMillimeter(
              _isLeftSelected
                  ? report?.leftFootWidth
                  : report?.rightFootWidth,
            ),
          ),
          _FindingMetric(
            label: 'Parmak Genişliği',
            value: _formatMillimeter(
              _isLeftSelected
                  ? report?.leftToeWidth
                  : report?.rightToeWidth,
            ),
          ),
        ],
      ),
      _EvaluationFindingPanelData(
        title: 'Arka Ayak ve Pronasyon',
        subtitle:
            'Topuk-bilek hizalanması ve pronasyon açısı.',
        icon: Icons.rotate_90_degrees_ccw,
        imageSource: pronatorImage,
        imageTitle: 'Ayak-Bilek Hizalanması',
        description: foot.balanceSummary.trim().isNotEmpty
            ? foot.balanceSummary
            : _pronationDescription(pronatorAngle),
        metrics: [
          _FindingMetric(
            label: 'Pronasyon Açısı',
            value: _formatDegree(pronatorAngle),
          ),
          _FindingMetric(
            label: 'Topuk Tipi',
            value: _safeText(heelType),
          ),
          _FindingMetric(
            label: 'Diz Açısı',
            value: _formatDegree(kneeAngle),
          ),
          _FindingMetric(
            label: 'Diz Hizalanması',
            value: _safeText(kneeType),
          ),
        ],
      ),
      _EvaluationFindingPanelData(
        title: 'İç Taban ve Ürün Değerlendirmesi',
        subtitle:
            'Anatomik sonuçlar doğrultusunda kayıtlı öneriler.',
        icon: Icons.design_services_outlined,
        description: _safeText(
          _isLeftSelected
              ? report?.leftInsoleRecommendation
              : report?.rightInsoleRecommendation,
          fallback: _safeText(
            report?.recommendationText,
            fallback:
                'Bu ölçüm için ürün önerisi kaydedilmemiş.',
          ),
        ),
        metrics: [
          _FindingMetric(
            label: 'Ayak Tipi',
            value: _safeText(
              foot.footType,
              fallback: _safeText(archType),
            ),
          ),
          _FindingMetric(
            label: 'Ayakkabı Numarası',
            value: _safeText(
              _isLeftSelected
                  ? report?.leftShoeSize
                  : report?.rightShoeSize,
            ),
          ),
          _FindingMetric(
            label: 'Ana Bulgu',
            value: _safeText(foot.mainFinding),
          ),
          _FindingMetric(
            label: 'Destek İhtiyacı',
            value: _safeText(foot.archSupportNeed),
          ),
        ],
      ),
    ];

    return _buildSectionCard(
      title: 'Değerlendirme Bulguları ve Görseller',
      subtitle:
          '${_sideLabel()} için 3D tarama görselleri ve '
          'ölçüm değerlendirmeleri.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingEvaluationVisuals) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'Görseller Supabase Storage üzerinden yükleniyor...',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
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
          ...findings.map(
            (finding) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildEvaluationFindingPanel(
                finding,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationFindingPanel(
    _EvaluationFindingPanelData data,
  ) {
    final hasImages = _hasText(data.imageSource) ||
        _hasText(data.secondaryImageSource);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 820;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      data.icon,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: data.metrics
                    .map(_buildFindingMetric)
                    .toList(),
              ),
              if (data.description.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.055),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.description,
                    style: const TextStyle(
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ],
          );

          final images = hasImages
              ? _buildFindingImages(data)
              : null;

          if (isNarrow || images == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (images != null) ...[
                  const SizedBox(height: 16),
                  images,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: content,
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: images,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFindingMetric(
    _FindingMetric metric,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 145,
        maxWidth: 220,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            metric.value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  /// Önceki sürümde Expanded doğrudan SizedBox altına
  /// yerleştirildiği için tek görselli kartlar dikey olarak uzuyordu.
  Widget _buildFindingImages(
    _EvaluationFindingPanelData data,
  ) {
    final imageWidgets = <Widget>[];

    if (_hasText(data.imageSource)) {
      imageWidgets.add(
        _evaluationImageTile(
          title: data.imageTitle ??
              'Değerlendirme Görseli',
          source: data.imageSource!,
        ),
      );
    }

    if (_hasText(data.secondaryImageSource)) {
      imageWidgets.add(
        _evaluationImageTile(
          title: data.secondaryImageTitle ??
              'İkinci Değerlendirme Görseli',
          source: data.secondaryImageSource!,
        ),
      );
    }

    if (imageWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    if (imageWidgets.length == 1) {
      return SizedBox(
        height: 270,
        child: imageWidgets.first,
      );
    }

    return SizedBox(
      height: 270,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: imageWidgets[0],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: imageWidgets[1],
          ),
        ],
      ),
    );
  }

  Widget _evaluationImageTile({
    required String title,
    required String source,
  }) {
    final normalizedSource = source.trim();

    return InkWell(
      onTap: () {
        _openImagePreview(
          title,
          normalizedSource,
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 17,
                  color: Colors.teal,
                ),
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
                const Icon(
                  Icons.open_in_full,
                  size: 16,
                  color: Colors.black45,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildNetworkImage(
                  normalizedSource,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(
    String source, {
    BoxFit fit = BoxFit.contain,
  }) {
    if (source.trim().isEmpty) {
      return _imageUnavailableState(
        'Görsel yolu bulunamadı.',
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      alignment: Alignment.center,
      child: Image.network(
        source,
        fit: fit,
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          debugPrint(
            'Görsel gösterilemedi:\n'
            '$source\n'
            '$error',
          );

          return _imageUnavailableState(
            'Görsel dosyası açılamadı.',
          );
        },
      ),
    );
  }

  Widget _imageUnavailableState(
    String message,
  ) {
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImagePreview(
    String title,
    String source,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1050,
              maxHeight: 780,
            ),
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
                        tooltip: 'Kapat',
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
                            loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                            ) {
                              if (loadingProgress == null) {
                                return child;
                              }

                              return const CircularProgressIndicator();
                            },
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Padding(
                                padding: EdgeInsets.all(30),
                                child: Text(
                                  'Görsel açılamadı.',
                                ),
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
    if (angle == null) {
      return 'Halluks açısına ilişkin değerlendirme '
          'verisi bulunmuyor.';
    }

    final absolute = angle.abs();

    if (absolute <= 10) {
      return 'Başparmak hizalanması normal açı '
          'aralığında görünüyor.';
    }

    if (absolute <= 20) {
      return 'Başparmak açısında hafif düzeyde '
          'hizalanma değişimi görülüyor.';
    }

    return 'Başparmak açısında belirgin hizalanma '
        'değişimi görülüyor.';
  }

  String _pronationDescription(double? angle) {
    if (angle == null) {
      return 'Pronasyon açısına ilişkin değerlendirme '
          'verisi bulunmuyor.';
    }

    final absolute = angle.abs();

    if (absolute <= 4) {
      return 'Arka ayak hizalanması normal açı '
          'aralığında görünüyor.';
    }

    if (absolute <= 8) {
      return 'Arka ayakta hafif pronasyon veya '
          'supinasyon eğilimi görülüyor.';
    }

    return 'Arka ayak hizalanmasında belirgin açı '
        'değişimi görülüyor.';
  }

  // ---------------------------------------------------------------------------
  // Pressure measurements
  // ---------------------------------------------------------------------------

  Widget _buildPressureMeasurementsSection() {
    return _buildSectionCard(
      title: 'Plantar Basınç Ölçümleri',
      subtitle:
          'Seçili oturum sırasında kaydedilen basınç ölçüm kayıtları.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingPressureRecords)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_pressureRecordsError != null)
            _errorInformationState(
              _pressureRecordsError!,
              onRetry: _loadPressureRecordings,
            )
          else if (_pressureRecordings.isEmpty)
            _emptyInformationState(
              icon: Icons.speed_outlined,
              message:
                  'Bu oturum için kayıtlı plantar basınç '
                  'ölçümü bulunmuyor.',
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _pressureRecordings.map((recording) {
        final selected =
            recording.id == _selectedPressureRecording?.id;

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
                  ? Colors.indigo.withOpacity(0.08)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: selected
                    ? Colors.indigo
                    : Colors.grey.shade300,
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
                      color: selected
                          ? Colors.indigo
                          : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        recording.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(recording.recordedAt),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${recording.frameCount} kare • '
                  '${_formatDuration(recording.durationMs)}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedPressureRecording() {
    final recording = _selectedPressureRecording;

    if (recording == null) {
      return _emptyInformationState(
        icon: Icons.touch_app_outlined,
        message:
            'Görüntülemek için bir basınç kaydı seçin.',
      );
    }

    if (_isLoadingPressureData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: CircularProgressIndicator(),
        ),
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
      return _buildPressureSummaryWithoutFrames(
        recording,
      );
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
        _buildPressureRecordingHeader(
          recording,
          data,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 850;

            final heatmap = _buildPressureHeatmapPanel(
              data: data,
              frame: frame,
              frameIndex: frameIndex,
            );

            final metrics = _buildPressureMetricsPanel(
              recording: recording,
              data: data,
              stats: stats,
            );

            if (isNarrow) {
              return Column(
                children: [
                  heatmap,
                  const SizedBox(height: 16),
                  metrics,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: heatmap,
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: metrics,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPressureRecordingHeader(
    SessionPressureRecordingModel recording,
    _PressureRecordingData data,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.16),
        ),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _pressureHeaderValue(
            'Kayıt',
            recording.title,
          ),
          _pressureHeaderValue(
            'Tarih',
            _formatDateTime(recording.recordedAt),
          ),
          _pressureHeaderValue(
            'Kare',
            '${data.frames.length}',
          ),
          _pressureHeaderValue(
            'Süre',
            _formatDuration(
              data.durationMs > 0
                  ? data.durationMs
                  : recording.durationMs,
            ),
          ),
          _pressureHeaderValue(
            'Matris',
            '${data.rows} × ${data.cols}',
          ),
        ],
      ),
    );
  }

  Widget _pressureHeaderValue(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPressureHeatmapPanel({
    required _PressureRecordingData data,
    required _PressureFrameData frame,
    required int frameIndex,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Basınç Isı Haritası',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                'Kare ${frameIndex + 1}/${data.frames.length}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (frame.timestamp != null) ...[
            const SizedBox(height: 5),
            Text(
              _formatDateTime(frame.timestamp),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 13),
          AspectRatio(
            aspectRatio: data.cols <= 0 || data.rows <= 0
                ? 2
                : data.cols / data.rows,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _PressureHeatmapPainter(
                  matrix: frame.matrix,
                  configuredMaxValue:
                      data.maxVisualValue,
                  threshold: data.threshold,
                ),
                child: const SizedBox.expand(),
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
                  _selectedPressureFrameIndex =
                      value.round();
                });
              },
            ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Düşük',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                ),
              ),
              Container(
                width: 150,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF00BCD4),
                      Color(0xFF4CAF50),
                      Color(0xFFFFEB3B),
                      Color(0xFFFF9800),
                      Color(0xFFF44336),
                    ],
                  ),
                ),
              ),
              Text(
                'Yüksek',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPressureMetricsPanel({
    required SessionPressureRecordingModel recording,
    required _PressureRecordingData data,
    required _PressureFrameStats stats,
  }) {
    final totalLoad = stats.totalLoad;

    final leftPercent = totalLoad <= 0
        ? 0.0
        : stats.leftLoad / totalLoad * 100;

    final rightPercent = totalLoad <= 0
        ? 0.0
        : stats.rightLoad / totalLoad * 100;

    final forefootPercent = totalLoad <= 0
        ? 0.0
        : stats.forefootLoad / totalLoad * 100;

    final heelPercent = totalLoad <= 0
        ? 0.0
        : stats.heelLoad / totalLoad * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seçili Kare Özeti',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pressureMetricTile(
                'Maksimum Ham Değer',
                stats.maxValue.toStringAsFixed(1),
                Icons.trending_up,
              ),
              _pressureMetricTile(
                'Ortalama Temas',
                stats.averageContactValue
                    .toStringAsFixed(1),
                Icons.analytics_outlined,
              ),
              _pressureMetricTile(
                'Temas Hücresi',
                '${stats.contactCellCount}',
                Icons.grid_view_outlined,
              ),
              _pressureMetricTile(
                'Toplam Ham Yük',
                stats.totalLoad.toStringAsFixed(0),
                Icons.scale_outlined,
              ),
            ],
          ),
          const SizedBox(height: 17),
          _percentageDistribution(
            title: 'Sol / Sağ Yük Dağılımı',
            firstLabel: 'Sol',
            firstValue: leftPercent,
            secondLabel: 'Sağ',
            secondValue: rightPercent,
          ),
          const SizedBox(height: 15),
          _percentageDistribution(
            title: 'Ön Ayak / Topuk Dağılımı',
            firstLabel: 'Ön Ayak',
            firstValue: forefootPercent,
            secondLabel: 'Topuk',
            secondValue: heelPercent,
          ),
          const SizedBox(height: 15),
          _buildPressureCenterInformation(stats),
          if (data.weightKg != null &&
              data.cellAreaCm2 != null) ...[
            const SizedBox(height: 15),
            _buildApproximatePressureValues(
              data: data,
              stats: stats,
            ),
          ],
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.07),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: Colors.orange.withOpacity(0.18),
              ),
            ),
            child: Text(
              'Ham sensör değerleri doğrudan kPa değildir. '
              'Kilo ve sensör alanı kullanılarak gösterilen '
              'fiziksel değerler yaklaşık değerlerdir.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kayıt özeti: maksimum '
            '${recording.maxPressure?.toStringAsFixed(1) ?? '—'}, '
            'ortalama '
            '${recording.avgPressure?.toStringAsFixed(2) ?? '—'}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pressureMetricTile(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.055),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.indigo,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 10,
            ),
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
    final normalizedFirst = (firstValue / 100)
        .clamp(0.0, 1.0)
        .toDouble();

    final firstFlex = math.max(
      1,
      (normalizedFirst * 1000).round(),
    );

    final secondFlex = math.max(
      1,
      ((1 - normalizedFirst) * 1000).round(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: firstFlex,
                  child: Container(
                    color: Colors.teal,
                  ),
                ),
                Expanded(
                  flex: secondFlex,
                  child: Container(
                    color: Colors.indigo,
                  ),
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

  Widget _buildPressureCenterInformation(
    _PressureFrameStats stats,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.my_location_outlined,
            color: Colors.teal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stats.centerOfPressureX == null ||
                      stats.centerOfPressureY == null
                  ? 'Basınç merkezi hesaplanamadı.'
                  : 'Basınç merkezi: '
                      'X ${stats.centerOfPressureX!.toStringAsFixed(1)}, '
                      'Y ${stats.centerOfPressureY!.toStringAsFixed(1)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApproximatePressureValues({
    required _PressureRecordingData data,
    required _PressureFrameStats stats,
  }) {
    final weightKg = data.weightKg;
    final cellAreaCm2 = data.cellAreaCm2;

    if (weightKg == null ||
        weightKg <= 0 ||
        cellAreaCm2 == null ||
        cellAreaCm2 <= 0 ||
        stats.totalLoad <= 0 ||
        stats.contactCellCount <= 0) {
      return const SizedBox.shrink();
    }

    final bodyForceNewton = weightKg * 9.80665;

    final maxCellForce = bodyForceNewton *
        (stats.maxValue / stats.totalLoad);

    final cellAreaM2 = cellAreaCm2 / 10000;

    final maxPressureKpa =
        maxCellForce / cellAreaM2 / 1000;

    final contactAreaM2 =
        stats.contactCellCount * cellAreaM2;

    final averagePressureKpa =
        bodyForceNewton / contactAreaM2 / 1000;

    final contactAreaCm2 =
        stats.contactCellCount * cellAreaCm2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _pressureMetricTile(
          'Yaklaşık Maksimum Basınç',
          '${maxPressureKpa.toStringAsFixed(1)} kPa',
          Icons.speed_outlined,
        ),
        _pressureMetricTile(
          'Ortalama Temas Basıncı',
          '${averagePressureKpa.toStringAsFixed(1)} kPa',
          Icons.compress,
        ),
        _pressureMetricTile(
          'Yaklaşık Temas Alanı',
          '${contactAreaCm2.toStringAsFixed(1)} cm²',
          Icons.crop_free_outlined,
        ),
      ],
    );
  }

  Widget _buildPressureSummaryWithoutFrames(
    SessionPressureRecordingModel recording,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recording.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pressureMetricTile(
                'Kare Sayısı',
                '${recording.frameCount}',
                Icons.filter_frames,
              ),
              _pressureMetricTile(
                'Süre',
                _formatDuration(recording.durationMs),
                Icons.timer_outlined,
              ),
              _pressureMetricTile(
                'Maksimum Ham Değer',
                recording.maxPressure
                        ?.toStringAsFixed(1) ??
                    '—',
                Icons.trending_up,
              ),
              _pressureMetricTile(
                'Ortalama Ham Değer',
                recording.avgPressure
                        ?.toStringAsFixed(2) ??
                    '—',
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
        .fold<int>(
          0,
          (current, value) => math.max(
            current,
            value,
          ),
        );

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
      centerOfPressureX: totalLoad <= 0
          ? null
          : weightedX / totalLoad,
      centerOfPressureY: totalLoad <= 0
          ? null
          : weightedY / totalLoad,
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
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null &&
              subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.35,
              ),
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
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: Colors.teal,
              size: 21,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: subtitle == null ||
                  subtitle.trim().isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.35,
                    ),
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
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.teal,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.red.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.red,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
        ),
      ],
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

  const _PressureHeatmapPainter({
    required this.matrix,
    required this.configuredMaxValue,
    required this.threshold,
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
        .fold<int>(
          0,
          (current, value) => math.max(
            current,
            value,
          ),
        );

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
      ..style = PaintingStyle.fill;

    for (int row = 0; row < rows; row++) {
      final rowData = matrix[row];

      for (int col = 0; col < cols; col++) {
        final value = col < rowData.length
            ? rowData[col]
            : 0.0;

        if (value <= threshold) {
          paint.color = const Color(0xFF0A1728);
        } else {
          final normalized = (value / effectiveMax)
              .clamp(0.0, 1.0)
              .toDouble();

          paint.color = _heatmapColor(normalized);
        }

        canvas.drawRect(
          Rect.fromLTWH(
            col * cellWidth,
            row * cellHeight,
            cellWidth + 0.5,
            cellHeight + 0.5,
          ),
          paint,
        );
      }
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
  bool shouldRepaint(
    covariant _PressureHeatmapPainter oldDelegate,
  ) {
    return oldDelegate.matrix != matrix ||
        oldDelegate.configuredMaxValue !=
            configuredMaxValue ||
        oldDelegate.threshold != threshold;
  }
}

// -----------------------------------------------------------------------------
// View data classes
// -----------------------------------------------------------------------------

class _AnatomicalMeasurement {
  final String title;
  final String value;
  final IconData icon;
  final String description;

  const _AnatomicalMeasurement({
    required this.title,
    required this.value,
    required this.icon,
    required this.description,
  });
}

class _EvaluationFindingPanelData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String description;
  final List<_FindingMetric> metrics;

  final String? imageSource;
  final String? secondaryImageSource;
  final String? imageTitle;
  final String? secondaryImageTitle;

  const _EvaluationFindingPanelData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
    required this.metrics,
    this.imageSource,
    this.secondaryImageSource,
    this.imageTitle,
    this.secondaryImageTitle,
  });
}

class _FindingMetric {
  final String label;
  final String value;

  const _FindingMetric({
    required this.label,
    required this.value,
  });
}

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

  factory _PressureRecordingData.fromJson(
    Map<String, dynamic> map,
  ) {
    final visualSettings =
        _asMap(map['visual_settings']);

    final anthropometric =
        _asMap(map['anthropometric']);

    final rawFrames = _asList(map['frames']);

    final frames = rawFrames
        .map(
          (item) => _PressureFrameData.fromJson(
            _asMap(item),
          ),
        )
        .where(
          (frame) => frame.matrix.isNotEmpty,
        )
        .toList();

    final detectedRows = frames.isEmpty
        ? 0
        : frames.first.matrix.length;

    final detectedCols = frames.isEmpty ||
            frames.first.matrix.isEmpty
        ? 0
        : frames.first.matrix.first.length;

    final rows = _toInt(map['rows']) ?? detectedRows;
    final cols = _toInt(map['cols']) ?? detectedCols;

    final storedCellAreaCm2 = _toDouble(
      anthropometric['cell_area_cm2'] ??
          map['cell_area_cm2'],
    );

    double? calculatedCellAreaCm2 =
        storedCellAreaCm2;

    // PressureMeasurementDialog içindeki sensör ölçüsü:
    // 452 × 344 mm, 64 × 32 hücre.
    if (calculatedCellAreaCm2 == null &&
        rows > 0 &&
        cols > 0) {
      final cellWidthMm = 452.0 / cols;
      final cellHeightMm = 344.0 / rows;

      calculatedCellAreaCm2 =
          (cellWidthMm * cellHeightMm) / 100;
    }

    return _PressureRecordingData(
      rows: rows,
      cols: cols,
      durationMs:
          _toInt(map['duration_ms']) ?? 0,
      maxVisualValue: _toDouble(
            visualSettings['max_value'] ??
                map['max_value'],
          ) ??
          0,
      threshold: _toDouble(
            visualSettings['threshold'] ??
                map['threshold'],
          ) ??
          0,
      weightKg: _toDouble(
        anthropometric['weight_kg'] ??
            map['weight_kg'],
      ),
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

    return double.tryParse(
      value.toString().replaceAll(',', '.'),
    );
  }
}

class _PressureFrameData {
  final DateTime? timestamp;
  final List<List<double>> matrix;

  const _PressureFrameData({
    required this.timestamp,
    required this.matrix,
  });

  factory _PressureFrameData.fromJson(
    Map<String, dynamic> map,
  ) {
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

            return double.tryParse(
                  value.toString(),
                ) ??
                0.0;
          }).toList(),
        );
      }
    }

    return _PressureFrameData(
      timestamp: DateTime.tryParse(
        (map['timestamp'] ?? '').toString(),
      ),
      matrix: matrix,
    );
  }
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