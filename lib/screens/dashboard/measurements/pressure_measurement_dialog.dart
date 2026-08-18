import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:oy_site/data/repositories/supabase_session_pressure_repository.dart';
import 'package:oy_site/models/session_pressure_recording_model.dart';
import 'package:oy_site/services/serial/serial_port_factory.dart';
import 'package:oy_site/services/storage/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const int _pressureRows = 32;
const int _pressureCols = 64;
const double _sensorRatio = 452 / 344;
const double _gravityMps2 = 9.80665;

// Sensörün aktif alan ölçüsü. Gerçek sensör aktif alanı farklıysa güncelle.
const double _sensorPhysicalWidthMm = 452;
const double _sensorPhysicalHeightMm = 344;

class PressureMeasurementDialog extends StatefulWidget {
  final dynamic pressureRepository;
  final String sessionCode;

  final int? sessionId;
  final int? patientId;
  final int? expertUserId;

  const PressureMeasurementDialog({
    super.key,
    required this.pressureRepository,
    required this.sessionCode,
    this.sessionId,
    this.patientId,
    this.expertUserId,
  });

  @override
  State<PressureMeasurementDialog> createState() =>
      _PressureMeasurementDialogState();
}

class _PressureMeasurementDialogState extends State<PressureMeasurementDialog> {
  late final SerialPortService _serialService;

  final SupabaseSessionPressureRepository _pressureRepository =
      SupabaseSessionPressureRepository();

  final SupabaseStorageService _storageService = SupabaseStorageService();

  SupabaseClient get _client => Supabase.instance.client;

  List<String> _ports = [];
  String? _connectedPort;

  String _status = 'Bağlantı yok';
  int _frameCount = 0;

  static const int rows = _pressureRows;
  static const int cols = _pressureCols;
  static const int frameLen = 2056;
  static const int packageSize = rows * cols;

  double _maxValue = 96;
  int _threshold = 9;
  int _smoothSize = 0;

  // 1.0 = toplam ham yük, danışanın tüm vücut ağırlığına normalize edilir.
  // Tek ayak/yarım yük protokolü kullanılacaksa 0.5 gibi güncellenebilir.
  double _measurementLoadRatio = 1.0;

  List<List<int>> _pressureData = List.generate(
    rows,
    (_) => List.filled(cols, 0),
  );

  List<int> _buffer = [];
  ui.Image? _heatmapImage;

  DateTime _lastSendTime = DateTime.now();

  bool _isRecording = false;
  bool _isPlaybackMode = false;
  bool _isExporting = false;
  bool _isImportingPressureFile = false;

  List<PressureRecording> _recordings = [];
  List<PressureFrameSnapshot> _currentRecordingFrames = [];

  PressureRecording? _selectedRecording;
  int _playbackFrameIndex = 0;
  ui.Image? _playbackHeatmapImage;

  double? _bodyWeightKg;
  double? _heightCm;
  double? _bmi;
  double? _shoeSizeEu;
  String _anthropometricInfoStatus = 'Danışan bilgisi yükleniyor...';

  bool _showCenterOfPressure = true;
  bool _showPeakPressure = true;
  bool _enablePointProbe = true;
  bool _showCircularRegion = true;
  int _roiRadius = 5;
  _GridPoint? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _serialService = createSerialPortService();
    _ports = _serialService.availablePorts;
    _loadAnthropometricInfo();
  }

  @override
  void dispose() {
    _serialService.disconnect();
    super.dispose();
  }

  Future<void> _loadAnthropometricInfo() async {
    final sessionId = widget.sessionId;

    if (sessionId == null) {
      if (!mounted) return;

      setState(() {
        _anthropometricInfoStatus =
            'Oturum ID olmadığı için danışan bilgisi okunamadı.';
      });
      return;
    }

    try {
      final response = await _client
          .from('anthropometric_clinical_infos')
          .select('''
            weight_kg,
            height_cm,
            bmi,
            shoe_size_eu,
            updated_at,
            created_at
          ''')
          .eq('session_id', sessionId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _anthropometricInfoStatus =
              'Bu ölçüm için danışan bilgisi bulunamadı.';
        });
        return;
      }

      final row = Map<String, dynamic>.from(response as Map);

      setState(() {
        _bodyWeightKg = _toDoubleOrNull(row['weight_kg']);
        _heightCm = _toDoubleOrNull(row['height_cm']);
        _bmi = _toDoubleOrNull(row['bmi']);
        _shoeSizeEu = _toDoubleOrNull(row['shoe_size_eu']);

        _anthropometricInfoStatus = _bodyWeightKg == null
            ? 'Danışan bilgisi okundu fakat kilo bilgisi boş.'
            : 'Danışan bilgisi okundu.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _anthropometricInfoStatus =
            'Danışan bilgisi okunamadı. RLS veya kolon kontrolü gerekebilir: $e';
      });
    }
  }

  void _refreshPorts() {
    setState(() {
      _ports = _serialService.availablePorts;
    });
  }

  void _connect(String portName) {
    try {
      _serialService.connect(portName, (Uint8List data) {
        _buffer.addAll(data);
        _processBuffer();
      });

      setState(() {
        _connectedPort = portName;
        _status = 'Cihaz bağlı: $portName';
      });
    } catch (e) {
      setState(() {
        _status = 'Bağlantı hatası: $e';
      });
    }
  }

  void _disconnect() {
    _serialService.disconnect();
    setState(() {
      _connectedPort = null;
      _status = 'Bağlantı yok';
    });
  }

  void _processBuffer() {
    while (true) {
      final start = _findHeader();

      if (start == -1) {
        _buffer.clear();
        return;
      }

      if (_buffer.length < start + frameLen) return;

      final frame = _buffer.sublist(start, start + frameLen);
      _buffer = _buffer.sublist(start + frameLen);

      _parseFrame(frame);
    }
  }

  int _findHeader() {
    for (int i = 0; i < _buffer.length - 1; i++) {
      if (_buffer[i] == 0xA5 && _buffer[i + 1] == 0x5A) return i;
    }
    return -1;
  }

  Future<void> _parseFrame(List<int> frame) async {
    if (frame.length < 4) return;

    final payload = frame.sublist(4);

    _sendToRepository(payload);

    if (payload.length < rows * cols) return;

    List<List<int>> newData = List.generate(rows, (_) => List.filled(cols, 0));

    for (int i = 0; i < rows * cols; i++) {
      final row = (rows - 1) - (i ~/ cols);
      final col = i % cols;

      int value = payload[i];
      if (value < _threshold) value = 0;

      newData[row][col] = value;
    }

    newData = _applySmoothing(newData);

    if (_isRecording) {
      _currentRecordingFrames.add(
        PressureFrameSnapshot(
          timestamp: DateTime.now(),
          matrix: _deepCopyMatrix(newData),
        ),
      );
    }

    final heatmapImage = await _generateHeatmapImage(newData);

    if (!mounted) return;

    setState(() {
      _pressureData = newData;
      _heatmapImage = heatmapImage;
      _frameCount++;
    });
  }

  void _sendToRepository(List<int> payload) {
    final now = DateTime.now();

    if (now.difference(_lastSendTime).inMilliseconds < 200) {
      return;
    }

    _lastSendTime = now;

    try {
      // Gelecek aşama:
      // widget.pressureRepository.sendPressureFrame(
      //   sessionCode: widget.sessionCode,
      //   payload: payload,
      // );
    } catch (_) {}
  }

  List<List<int>> _applySmoothing(List<List<int>> data) {
    int k = _smoothSize;
    if (k <= 0) return data;
    if (k % 2 == 0) k += 1;

    final half = k ~/ 2;

    List<List<int>> result = List.generate(rows, (_) => List.filled(cols, 0));

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        int sum = 0;
        int count = 0;

        for (int dr = -half; dr <= half; dr++) {
          for (int dc = -half; dc <= half; dc++) {
            final nr = r + dr;
            final nc = c + dc;

            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
              sum += data[nr][nc];
              count++;
            }
          }
        }

        result[r][c] = (sum / count).round();
      }
    }

    return result;
  }

  List<List<int>> _deepCopyMatrix(List<List<int>> source) {
    return source.map((row) => List<int>.from(row)).toList();
  }

  int _colorToInt(int value) {
    if (value <= 0) return 0xFFFFFFFF;

    final norm = pow((value / _maxValue).clamp(0.0, 1.0), 0.7).toDouble();

    int r, g;

    if (norm < 0.5) {
      final t = norm * 2;
      r = (255 * t).toInt();
      g = 255;
    } else {
      final t = (norm - 0.5) * 2;
      r = 255;
      g = (255 * (1 - t)).toInt();
    }

    return (0xFF << 24) | (r << 16) | (g << 8);
  }

  Future<ui.Image> _generateHeatmapImage(List<List<int>> data) async {
    final pixels = Uint8List(rows * cols * 4);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final color = _colorToInt(data[r][c]);
        final idx = (r * cols + c) * 4;

        pixels[idx] = (color >> 16) & 0xFF;
        pixels[idx + 1] = (color >> 8) & 0xFF;
        pixels[idx + 2] = color & 0xFF;
        pixels[idx + 3] = 0xFF;
      }
    }

    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels,
      cols,
      rows,
      ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );

    return completer.future;
  }

  List<List<int>> _applyVisualSettingsToPlaybackMatrix(List<List<int>> source) {
    final thresholded = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        if (r >= source.length || c >= source[r].length) return 0;

        final value = source[r][c];

        if (value < _threshold) return 0;

        return value;
      });
    });

    return _applySmoothing(thresholded);
  }

  Future<ui.Image> _generatePlaybackHeatmapImage(PressureFrameSnapshot frame) {
    final displayMatrix = _applyVisualSettingsToPlaybackMatrix(frame.matrix);

    return _generateHeatmapImage(displayMatrix);
  }

  Future<void> _refreshPlaybackHeatmapWithCurrentSettings() async {
    final recording = _selectedRecording;

    if (!_isPlaybackMode || recording == null || recording.frames.isEmpty) {
      return;
    }

    final safeIndex = _playbackFrameIndex.clamp(0, recording.frames.length - 1);

    final playbackImage = await _generatePlaybackHeatmapImage(
      recording.frames[safeIndex],
    );

    if (!mounted) return;

    setState(() {
      _playbackHeatmapImage = playbackImage;
    });
  }

  void _onVisualSettingChanged(VoidCallback update) {
    setState(update);
    _refreshPlaybackHeatmapWithCurrentSettings();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isPlaybackMode = false;
      _selectedRecording = null;
      _playbackHeatmapImage = null;
      _playbackFrameIndex = 0;
      _currentRecordingFrames = [];
      _isRecording = true;
      _status = _connectedPort == null
          ? 'Ölçüm kaydı başlatıldı. Cihaz bağlantısı yok.'
          : 'Ölçüm kaydı başlatıldı: $_connectedPort';
    });
  }

  Future<void> _stopRecording() async {
    final frames = List<PressureFrameSnapshot>.from(_currentRecordingFrames);

    PressureRecording? newRecording;

    if (frames.isNotEmpty) {
      newRecording = PressureRecording(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Ölçüm Kaydı ${_recordings.length + 1}',
        createdAt: DateTime.now(),
        frames: frames,
      );
    }

    setState(() {
      _isRecording = false;
      _currentRecordingFrames = [];

      if (newRecording != null) {
        _recordings = [newRecording, ..._recordings];
        _status =
            '${newRecording.title} kaydedildi (${newRecording.frames.length} kare)';
      } else {
        _status = 'Kayıt durduruldu. Ölçüm karesi yok.';
      }
    });

    if (newRecording == null) return;

    await _saveRecordingToSupabase(newRecording);
  }

  Future<void> _saveRecordingToSupabase(PressureRecording recording) async {
    final sessionId = widget.sessionId;
    final patientId = widget.patientId;
    final expertUserId = widget.expertUserId;

    if (sessionId == null || patientId == null || expertUserId == null) {
      setState(() {
        _status =
            '${recording.title} cihazda/local kaydedildi. Supabase için oturum/danışan/uzman ID eksik.';
      });
      return;
    }

    try {
      final stats = _calculatePressureStats(recording.frames);

      final rawJson = _recordingToJson(recording);
      final rawJsonBytes = utf8.encode(jsonEncode(rawJson));

      final storagePath = _storageService.buildPressureRecordingPath(
        sessionId: sessionId,
        recordingId: recording.id,
      );

      final uploadResult = await _storageService.uploadBytes(
        bytes: rawJsonBytes,
        storagePath: storagePath,
      );

      final model = SessionPressureRecordingModel(
        sessionId: sessionId,
        patientId: patientId,
        expertUserId: expertUserId,
        title: recording.title,
        frameCount: recording.frames.length,
        durationMs: _calculateDurationMs(recording.frames),
        maxPressure: stats.maxPressure,
        avgPressure: stats.avgPressure,
        rawFramesJson: null,
        storageBucket: uploadResult.bucket,
        storagePath: uploadResult.storagePath,
        uploadStatus: PressureUploadStatuses.uploaded,
        recordedAt: recording.createdAt,
      );

      await _pressureRepository.createRecording(recording: model);

      if (!mounted) return;

      setState(() {
        _status =
            '${recording.title} Supabase ve Storage kayıtları tamamlandı (${recording.frames.length} kare)';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _status =
            '${recording.title} local kaydedildi. Supabase/Storage hatası: $e';
      });
    }
  }

  int _calculateDurationMs(List<PressureFrameSnapshot> frames) {
    if (frames.length < 2) return 0;

    return frames.last.timestamp
        .difference(frames.first.timestamp)
        .inMilliseconds;
  }

  _PressureStats _calculatePressureStats(List<PressureFrameSnapshot> frames) {
    int maxValue = 0;
    int sum = 0;
    int count = 0;

    for (final frame in frames) {
      for (final row in frame.matrix) {
        for (final value in row) {
          if (value > maxValue) maxValue = value;
          sum += value;
          count++;
        }
      }
    }

    return _PressureStats(
      maxPressure: maxValue.toDouble(),
      avgPressure: count == 0 ? 0 : sum / count,
    );
  }

  Map<String, dynamic> _recordingToJson(PressureRecording recording) {
    final stats = _calculatePressureStats(recording.frames);

    return {
      'id': recording.id,
      'title': recording.title,
      'created_at': recording.createdAt.toIso8601String(),
      'session_code': widget.sessionCode,
      'session_id': widget.sessionId,
      'patient_id': widget.patientId,
      'expert_user_id': widget.expertUserId,
      'rows': rows,
      'cols': cols,
      'package_size': packageSize,
      'frame_count': recording.frames.length,
      'duration_ms': _calculateDurationMs(recording.frames),
      'visual_settings': {
        'max_value': _maxValue,
        'threshold': _threshold,
        'smooth_size': _smoothSize,
      },
      'anthropometric': {
        'weight_kg': _bodyWeightKg,
        'height_cm': _heightCm,
        'bmi': _bmi,
        'shoe_size_eu': _shoeSizeEu,
      },
      'analysis_summary': {
        'max_pressure': stats.maxPressure,
        'avg_pressure': stats.avgPressure,
      },
      'frames': recording.frames.map((frame) {
        return {
          'timestamp': frame.timestamp.toIso8601String(),
          'matrix': frame.matrix,
        };
      }).toList(),
    };
  }

  Future<void> _openRecording(PressureRecording recording) async {
    if (recording.frames.isEmpty) return;

    final firstFrame = recording.frames.first;
    final playbackImage = await _generatePlaybackHeatmapImage(firstFrame);

    if (!mounted) return;

    setState(() {
      _isPlaybackMode = true;
      _selectedRecording = recording;
      _playbackFrameIndex = 0;
      _playbackHeatmapImage = playbackImage;
    });
  }

  Future<void> _updatePlaybackFrame(int index) async {
    final recording = _selectedRecording;
    if (recording == null) return;
    if (index < 0 || index >= recording.frames.length) return;

    final frame = recording.frames[index];
    final playbackImage = await _generatePlaybackHeatmapImage(frame);

    if (!mounted) return;

    setState(() {
      _playbackFrameIndex = index;
      _playbackHeatmapImage = playbackImage;
    });
  }

  void _exitPlaybackMode() {
    setState(() {
      _isPlaybackMode = false;
      _selectedRecording = null;
      _playbackFrameIndex = 0;
      _playbackHeatmapImage = null;
    });
  }

  Future<void> _exportRecordingsZip() async {
    if (_recordings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dışa aktarılacak ölçüm kaydı bulunamadı.'),
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _status = 'Ölçüm kayıtları ZIP olarak hazırlanıyor...';
    });

    try {
      final archive = Archive();

      for (int i = 0; i < _recordings.length; i++) {
        final recording = _recordings[i];

        final folderName =
            '${(i + 1).toString().padLeft(2, '0')}_${_safeFileName(recording.title)}';

        _addTextFileToArchive(
          archive: archive,
          path: '$folderName/recording.json',
          content: const JsonEncoder.withIndent(
            '  ',
          ).convert(_recordingToJson(recording)),
        );

        _addTextFileToArchive(
          archive: archive,
          path: '$folderName/recording.csv',
          content: _buildRecordingCsv(recording),
        );
      }

      final encodedZip = ZipEncoder().encode(archive);

      if (encodedZip == null) {
        throw Exception('ZIP dosyası oluşturulamadı.');
      }

      final exportDirectory = Directory(
        '${Directory.current.path}${Platform.pathSeparator}exports'
        '${Platform.pathSeparator}pressure_recordings',
      );

      if (!await exportDirectory.exists()) {
        await exportDirectory.create(recursive: true);
      }

      final fileName =
          'pressure_recordings_${_safeFileName(widget.sessionCode)}_${_exportTimestamp()}.zip';

      final outputFile = File(
        '${exportDirectory.path}${Platform.pathSeparator}$fileName',
      );

      await outputFile.writeAsBytes(encodedZip, flush: true);

      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _status = 'Ölçüm kayıtları dışa aktarıldı: ${outputFile.path}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ölçüm kayıtları kaydedildi: ${outputFile.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _status = 'ZIP dışa aktarma hatası: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ZIP dışa aktarma hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndImportPressureRecording() async {
    setState(() {
      _isImportingPressureFile = true;
      _status = 'Ölçüm kayıt dosyası seçiliyor...';
    });

    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Basınç kayıt dosyası seç',
        type: FileType.custom,
        allowedExtensions: const ['json', 'csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isImportingPressureFile = false;
          _status = 'Dosya seçimi iptal edildi.';
        });
        return;
      }

      final file = result.files.single;
      final fileName = file.name;
      final extension = _fileExtension(fileName);

      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Dosya içeriği okunamadı.');
      }

      final importedRecording = _parseImportedPressureRecording(
        fileName: fileName,
        extension: extension,
        bytes: bytes,
      );

      if (importedRecording.frames.isEmpty) {
        throw Exception('Dosyada okunabilir ölçüm karesi bulunamadı.');
      }

      final firstImage = await _generatePlaybackHeatmapImage(
        importedRecording.frames.first,
      );

      if (!mounted) return;

      setState(() {
        _recordings = [importedRecording, ..._recordings];

        _isPlaybackMode = true;
        _selectedRecording = importedRecording;
        _playbackFrameIndex = 0;
        _playbackHeatmapImage = firstImage;

        _isImportingPressureFile = false;
        _status =
            '${importedRecording.title} içe aktarıldı (${importedRecording.frames.length} kare).';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${importedRecording.title} içe aktarıldı.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isImportingPressureFile = false;
        _status = 'Dosya içe aktarma hatası: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya içe aktarma hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  PressureRecording _parseImportedPressureRecording({
    required String fileName,
    required String extension,
    required Uint8List bytes,
  }) {
    final content = utf8.decode(bytes, allowMalformed: true);

    if (extension == 'json') {
      return _parseImportedPressureJson(
        content: content,
        fallbackTitle: _fileNameWithoutExtension(fileName),
      );
    }

    if (extension == 'csv') {
      return _parseImportedPressureCsv(
        content: content,
        fallbackTitle: _fileNameWithoutExtension(fileName),
      );
    }

    throw Exception('Desteklenmeyen dosya formatı: .$extension');
  }

  PressureRecording _parseImportedPressureJson({
    required String content,
    required String fallbackTitle,
  }) {
    final decoded = jsonDecode(content);

    Map<String, dynamic> root;

    if (decoded is Map<String, dynamic>) {
      root = decoded;
    } else if (decoded is Map) {
      root = Map<String, dynamic>.from(decoded);
    } else if (decoded is List) {
      root = {
        'title': fallbackTitle,
        'created_at': DateTime.now().toIso8601String(),
        'frames': decoded,
      };
    } else {
      throw Exception('JSON formatı okunamadı.');
    }

    final rawFrames = root['frames'];

    if (rawFrames is! List || rawFrames.isEmpty) {
      throw Exception('JSON içinde frames listesi bulunamadı.');
    }

    final createdAt = _parseImportedDate(root['created_at']) ?? DateTime.now();

    final frames = <PressureFrameSnapshot>[];

    for (int i = 0; i < rawFrames.length; i++) {
      final frame = _parseJsonFrame(
        rawFrames[i],
        fallbackTimestamp: createdAt.add(Duration(milliseconds: i * 100)),
      );

      frames.add(frame);
    }

    return PressureRecording(
      id: (root['id'] ?? 'import_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      title: (root['title'] ?? fallbackTitle).toString(),
      createdAt: createdAt,
      frames: frames,
    );
  }

  PressureFrameSnapshot _parseJsonFrame(
    dynamic rawFrame, {
    required DateTime fallbackTimestamp,
  }) {
    if (rawFrame is List) {
      return PressureFrameSnapshot(
        timestamp: fallbackTimestamp,
        matrix: _matrixFromDynamic(rawFrame),
      );
    }

    final frameMap = _mapFromDynamic(rawFrame);

    if (frameMap.isEmpty) {
      throw Exception('JSON frame formatı hatalı.');
    }

    final matrixSource =
        frameMap['matrix'] ?? frameMap['data'] ?? frameMap['values'];

    if (matrixSource == null) {
      throw Exception('JSON frame içinde matrix alanı bulunamadı.');
    }

    return PressureFrameSnapshot(
      timestamp: _parseImportedDate(frameMap['timestamp']) ?? fallbackTimestamp,
      matrix: _matrixFromDynamic(matrixSource),
    );
  }

  PressureRecording _parseImportedPressureCsv({
    required String content,
    required String fallbackTitle,
  }) {
    final lines = const LineSplitter()
        .convert(content)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      throw Exception('CSV içinde yeterli satır bulunamadı.');
    }

    final header = _splitCsvLine(
      lines.first,
    ).map((item) => item.trim().toUpperCase()).toList();

    final timestampIndex = header.indexOf('TIMESTAMP');

    int firstMatrixIndex = header.indexWhere((item) => item == 'MAT_0');

    if (firstMatrixIndex == -1) {
      firstMatrixIndex = header.indexWhere((item) => item.startsWith('MAT_'));
    }

    if (firstMatrixIndex == -1) {
      throw Exception('CSV içinde MAT_0/MAT_ alanları bulunamadı.');
    }

    final importedAt = DateTime.now();
    final frames = <PressureFrameSnapshot>[];

    for (int i = 1; i < lines.length; i++) {
      final cells = _splitCsvLine(lines[i]);

      if (cells.length <= firstMatrixIndex) continue;

      final timestamp = timestampIndex >= 0 && timestampIndex < cells.length
          ? _parseImportedDate(cells[timestampIndex])
          : null;

      final rawValues = cells
          .skip(firstMatrixIndex)
          .take(packageSize)
          .map((value) => int.tryParse(value.trim()) ?? 0)
          .toList();

      final paddedValues = _normalizeFlatValues(rawValues);

      frames.add(
        PressureFrameSnapshot(
          timestamp:
              timestamp ?? importedAt.add(Duration(milliseconds: i * 100)),
          matrix: _matrixFromFlatValues(paddedValues),
        ),
      );
    }

    if (frames.isEmpty) {
      throw Exception('CSV içinde okunabilir ölçüm karesi bulunamadı.');
    }

    return PressureRecording(
      id: 'import_${DateTime.now().microsecondsSinceEpoch}',
      title: fallbackTitle,
      createdAt: frames.first.timestamp,
      frames: frames,
    );
  }

  void _addTextFileToArchive({
    required Archive archive,
    required String path,
    required String content,
  }) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  String _buildRecordingCsv(PressureRecording recording) {
    final buffer = StringBuffer();

    final headers = <String>[
      'SN',
      'TIMESTAMP',
      'PACKAGE_SIZE',
      'MAX_VALUE',
      'MIN_VALUE',
      ...List.generate(packageSize, (index) => 'MAT_$index'),
    ];

    buffer.writeln(headers.join(','));

    for (
      int frameIndex = 0;
      frameIndex < recording.frames.length;
      frameIndex++
    ) {
      final frame = recording.frames[frameIndex];
      final flatValues = _flattenMatrix(frame.matrix);

      final maxValue = flatValues.isEmpty ? 0 : flatValues.reduce(max);
      final minValue = flatValues.isEmpty ? 0 : flatValues.reduce(min);

      final row = <String>[
        frameIndex.toString(),
        _formatCsvTimestamp(frame.timestamp),
        packageSize.toString(),
        maxValue.toString(),
        minValue.toString(),
        ...flatValues.map((value) => value.toString()),
      ];

      buffer.writeln(row.map(_csvEscape).join(','));
    }

    return buffer.toString();
  }

  List<int> _flattenMatrix(List<List<int>> matrix) {
    final values = <int>[];

    for (final row in matrix) {
      values.addAll(row);
    }

    if (values.length == packageSize) {
      return values;
    }

    if (values.length > packageSize) {
      return values.sublist(0, packageSize);
    }

    return [...values, ...List<int>.filled(packageSize - values.length, 0)];
  }

  List<List<int>> get _activePressureMatrix {
    if (_isPlaybackMode &&
        _selectedRecording != null &&
        _selectedRecording!.frames.isNotEmpty) {
      final safeIndex = _playbackFrameIndex.clamp(
        0,
        _selectedRecording!.frames.length - 1,
      );

      return _applyVisualSettingsToPlaybackMatrix(
        _selectedRecording!.frames[safeIndex].matrix,
      );
    }

    return _pressureData;
  }

  _PressureAnalysis _analyzeMatrix(List<List<int>> matrix) {
    int totalLoad = 0;
    int contactCells = 0;

    int maxValue = 0;
    int peakRow = 0;
    int peakCol = 0;

    int leftLoad = 0;
    int rightLoad = 0;
    int topLoad = 0;
    int bottomLoad = 0;

    double weightedRowSum = 0;
    double weightedColSum = 0;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final value = matrix[r][c];

        totalLoad += value;

        if (value > 0) {
          contactCells++;
        }

        if (value > maxValue) {
          maxValue = value;
          peakRow = r;
          peakCol = c;
        }

        weightedRowSum += r * value;
        weightedColSum += c * value;

        if (c < cols / 2) {
          leftLoad += value;
        } else {
          rightLoad += value;
        }

        if (r < rows / 2) {
          topLoad += value;
        } else {
          bottomLoad += value;
        }
      }
    }

    final totalCells = rows * cols;
    final avgAll = totalCells == 0 ? 0.0 : totalLoad / totalCells;
    final avgContact = contactCells == 0 ? 0.0 : totalLoad / contactCells;

    final centerRow = totalLoad == 0 ? null : weightedRowSum / totalLoad;
    final centerCol = totalLoad == 0 ? null : weightedColSum / totalLoad;

    _RegionStats? selectedRegion;

    final selectedPoint = _selectedPoint;
    if (selectedPoint != null) {
      selectedRegion = _calculateCircularRegion(
        matrix: matrix,
        center: selectedPoint,
        radius: _roiRadius,
        totalLoad: totalLoad,
      );
    }

    return _PressureAnalysis(
      totalLoad: totalLoad,
      maxValue: maxValue,
      peakPoint: _GridPoint(row: peakRow, col: peakCol),
      contactCells: contactCells,
      contactRatio: totalCells == 0 ? 0 : contactCells / totalCells,
      avgAll: avgAll,
      avgContact: avgContact,
      centerRow: centerRow,
      centerCol: centerCol,
      leftLoad: leftLoad,
      rightLoad: rightLoad,
      topLoad: topLoad,
      bottomLoad: bottomLoad,
      selectedRegion: selectedRegion,
    );
  }

  _RegionStats _calculateCircularRegion({
    required List<List<int>> matrix,
    required _GridPoint center,
    required int radius,
    required int totalLoad,
  }) {
    int regionLoad = 0;
    int regionCells = 0;
    int regionContactCells = 0;
    int regionMaxValue = 0;

    final radiusSquared = radius * radius;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final dr = r - center.row;
        final dc = c - center.col;

        if ((dr * dr + dc * dc) <= radiusSquared) {
          final value = matrix[r][c];

          regionCells++;
          regionLoad += value;

          if (value > 0) {
            regionContactCells++;
          }

          if (value > regionMaxValue) {
            regionMaxValue = value;
          }
        }
      }
    }

    return _RegionStats(
      radius: radius,
      totalLoad: regionLoad,
      cellCount: regionCells,
      contactCellCount: regionContactCells,
      maxValue: regionMaxValue,
      avgValue: regionCells == 0 ? 0 : regionLoad / regionCells,
      loadRatio: totalLoad == 0 ? 0 : regionLoad / totalLoad,
    );
  }

  void _handleHeatmapTap(Offset localPosition, Size canvasSize) {
    if (!_enablePointProbe && !_showCircularRegion) return;

    final sensorRect = _sensorDrawRect(canvasSize);

    if (!sensorRect.contains(localPosition)) return;

    final normalizedX =
        ((localPosition.dx - sensorRect.left) / sensorRect.width).clamp(
          0.0,
          1.0,
        );

    final normalizedY =
        ((localPosition.dy - sensorRect.top) / sensorRect.height).clamp(
          0.0,
          1.0,
        );

    final col = (normalizedX * cols).floor().clamp(0, cols - 1);
    final displayRow = (normalizedY * rows).floor().clamp(0, rows - 1);
    final row = (rows - 1) - displayRow;

    setState(() {
      _selectedPoint = _GridPoint(row: row, col: col);
    });
  }

  int? _selectedPointValue(List<List<int>> matrix) {
    final point = _selectedPoint;
    if (point == null) return null;

    if (point.row < 0 ||
        point.row >= rows ||
        point.col < 0 ||
        point.col >= cols) {
      return null;
    }

    return matrix[point.row][point.col];
  }

  double? _selectedPointNeighborhoodAverage(List<List<int>> matrix) {
    final point = _selectedPoint;
    if (point == null) return null;

    int sum = 0;
    int count = 0;

    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        final row = point.row + dr;
        final col = point.col + dc;

        if (row >= 0 && row < rows && col >= 0 && col < cols) {
          sum += matrix[row][col];
          count++;
        }
      }
    }

    return count == 0 ? null : sum / count;
  }

  String _csvEscape(String value) {
    if (!value.contains(',') &&
        !value.contains('"') &&
        !value.contains('\n') &&
        !value.contains('\r')) {
      return value;
    }

    return '"${value.replaceAll('"', '""')}"';
  }

  String _safeFileName(String value) {
    final normalized = value.trim().isEmpty ? 'recording' : value.trim();

    return normalized
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _exportTimestamp() {
    final now = DateTime.now();

    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  String _formatCsvTimestamp(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}.'
        '${value.millisecond.toString().padLeft(3, '0')}';
  }

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }

  String _formatDouble(double? value, {int digits = 1, String fallback = '—'}) {
    if (value == null) return fallback;
    return value.toStringAsFixed(digits);
  }

  String _formatRatio(double ratio, {int digits = 1}) {
    return '${(ratio * 100).toStringAsFixed(digits)}%';
  }

  double get _sensorCellAreaM2 {
    final cellWidthM = (_sensorPhysicalWidthMm / cols) / 1000.0;
    final cellHeightM = (_sensorPhysicalHeightMm / rows) / 1000.0;

    return cellWidthM * cellHeightM;
  }

  double get _sensorCellAreaCm2 {
    return _sensorCellAreaM2 * 10000.0;
  }

  double _contactAreaCm2(int contactCells) {
    return contactCells * _sensorCellAreaCm2;
  }

  double? _totalMeasuredForceN(_PressureAnalysis analysis) {
    final weightKg = _bodyWeightKg;

    if (weightKg == null || weightKg <= 0) return null;
    if (analysis.totalLoad <= 0) return null;

    return weightKg * _gravityMps2 * _measurementLoadRatio;
  }

  double? _newtonPerRawUnit(_PressureAnalysis analysis) {
    final totalForceN = _totalMeasuredForceN(analysis);

    if (totalForceN == null) return null;
    if (analysis.totalLoad <= 0) return null;

    return totalForceN / analysis.totalLoad;
  }

  double? _rawToForceN(num rawValue, _PressureAnalysis analysis) {
    final newtonPerRawUnit = _newtonPerRawUnit(analysis);

    if (newtonPerRawUnit == null) return null;

    return rawValue.toDouble() * newtonPerRawUnit;
  }

  double? _rawToPressureKpa(num rawValue, _PressureAnalysis analysis) {
    final forceN = _rawToForceN(rawValue, analysis);

    if (forceN == null) return null;
    if (_sensorCellAreaM2 <= 0) return null;

    return (forceN / _sensorCellAreaM2) / 1000.0;
  }

  double? _ratioToForceN(double ratio, _PressureAnalysis analysis) {
    final totalForceN = _totalMeasuredForceN(analysis);

    if (totalForceN == null) return null;

    return totalForceN * ratio;
  }

  double? _regionForceN(_RegionStats? region, _PressureAnalysis analysis) {
    if (region == null) return null;

    return _rawToForceN(region.totalLoad, analysis);
  }

  double? _regionAveragePressureKpa(
    _RegionStats? region,
    _PressureAnalysis analysis,
  ) {
    if (region == null) return null;

    final regionForceN = _regionForceN(region, analysis);

    if (regionForceN == null) return null;

    final effectiveCellCount = region.contactCellCount > 0
        ? region.contactCellCount
        : region.cellCount;

    if (effectiveCellCount <= 0) return null;

    final areaM2 = effectiveCellCount * _sensorCellAreaM2;

    if (areaM2 <= 0) return null;

    return (regionForceN / areaM2) / 1000.0;
  }

  String _formatNewton(double? value, {int digits = 1}) {
    if (value == null || value.isNaN || value.isInfinite) return '—';

    return '${value.toStringAsFixed(digits)} N';
  }

  String _formatKpa(double? value, {int digits = 1}) {
    if (value == null || value.isNaN || value.isInfinite) return '—';

    return '${value.toStringAsFixed(digits)} kPa';
  }

  String _formatCm2(double? value, {int digits = 1}) {
    if (value == null || value.isNaN || value.isInfinite) return '—';

    return '${value.toStringAsFixed(digits)} cm²';
  }

  String _pointZoneLabel(_GridPoint? point) {
    if (point == null) return 'Seçilmedi';

    return _pressureZoneLabel(
      row: point.row.toDouble(),
      col: point.col.toDouble(),
    );
  }

  String _pressureZoneLabel({required double? row, required double? col}) {
    if (row == null || col == null) return '—';

    final verticalZone = _displayVerticalZone(row);
    final horizontalZone = _displayHorizontalZone(col);

    if (verticalZone == 'Orta' && horizontalZone == 'Orta') {
      return 'Orta bölge';
    }

    if (horizontalZone == 'Orta') {
      return '$verticalZone bölge';
    }

    if (verticalZone == 'Orta') {
      return '$horizontalZone orta';
    }

    return '$verticalZone / $horizontalZone';
  }

  String _displayVerticalZone(double matrixRow) {
    final displayRow = (_pressureRows - 1) - matrixRow;

    if (displayRow < _pressureRows * 0.33) return 'Ön';
    if (displayRow > _pressureRows * 0.66) return 'Topuk';

    return 'Orta';
  }

  String _displayHorizontalZone(double col) {
    if (col < _pressureCols * 0.33) return 'Sol';
    if (col > _pressureCols * 0.66) return 'Sağ';

    return 'Orta';
  }

  String _fileExtension(String fileName) {
    final parts = fileName.toLowerCase().split('.');

    if (parts.length < 2) return '';

    return parts.last.trim();
  }

  String _fileNameWithoutExtension(String fileName) {
    final normalized = fileName.trim();

    if (normalized.isEmpty) return 'İçe Aktarılan Ölçüm';

    final dotIndex = normalized.lastIndexOf('.');

    if (dotIndex <= 0) return normalized;

    return normalized.substring(0, dotIndex);
  }

  Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    return <String, dynamic>{};
  }

  DateTime? _parseImportedDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return DateTime.tryParse(text) ??
        DateTime.tryParse(text.replaceFirst(' ', 'T'));
  }

  List<List<int>> _matrixFromDynamic(dynamic value) {
    if (value is! List) {
      throw Exception('Matrix alanı liste formatında değil.');
    }

    if (value.isEmpty) {
      throw Exception('Matrix alanı boş.');
    }

    final looksLikeMatrix = value.first is List;

    if (looksLikeMatrix) {
      final matrix = value.map((row) {
        if (row is! List) {
          return List<int>.filled(cols, 0);
        }

        final parsedRow = row.map((cell) {
          if (cell is int) return cell;
          if (cell is num) return cell.round();

          return int.tryParse(cell.toString()) ?? 0;
        }).toList();

        if (parsedRow.length == cols) return parsedRow;

        if (parsedRow.length > cols) {
          return parsedRow.sublist(0, cols);
        }

        return [...parsedRow, ...List<int>.filled(cols - parsedRow.length, 0)];
      }).toList();

      if (matrix.length == rows) return matrix;

      if (matrix.length > rows) {
        return matrix.sublist(0, rows);
      }

      return [
        ...matrix,
        ...List.generate(
          rows - matrix.length,
          (_) => List<int>.filled(cols, 0),
        ),
      ];
    }

    final flatValues = value.map((cell) {
      if (cell is int) return cell;
      if (cell is num) return cell.round();

      return int.tryParse(cell.toString()) ?? 0;
    }).toList();

    return _matrixFromFlatValues(_normalizeFlatValues(flatValues));
  }

  List<int> _normalizeFlatValues(List<int> values) {
    if (values.length == packageSize) return values;

    if (values.length > packageSize) {
      return values.sublist(0, packageSize);
    }

    return [...values, ...List<int>.filled(packageSize - values.length, 0)];
  }

  List<List<int>> _matrixFromFlatValues(List<int> values) {
    final normalized = _normalizeFlatValues(values);

    return List.generate(rows, (row) {
      final start = row * cols;
      final end = start + cols;

      return normalized.sublist(start, end);
    });
  }

  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();

    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        final isEscapedQuote =
            insideQuotes && i + 1 < line.length && line[i + 1] == '"';

        if (isEscapedQuote) {
          buffer.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }

        continue;
      }

      if (char == ',' && !insideQuotes) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    result.add(buffer.toString());

    return result;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    final activePreviewImage = _isPlaybackMode
        ? _playbackHeatmapImage
        : _heatmapImage;

    final activeMatrix = _activePressureMatrix;
    final analysis = _analyzeMatrix(activeMatrix);

    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: min(screenSize.width * 0.97, 1720.0),
        height: min(screenSize.height * 0.94, 1020.0),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDialogHeader(),
              const SizedBox(height: 14),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftControlPanel(),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _buildPreviewPanel(
                        activePreviewImage: activePreviewImage,
                        analysis: analysis,
                      ),
                    ),
                    const SizedBox(width: 18),
                    _buildAnalysisPanel(
                      analysis: analysis,
                      activeMatrix: activeMatrix,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Plantar Basınç Ölçümü',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          'Oturum: ${widget.sessionCode}',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildLeftControlPanel() {
    return SizedBox(
      width: 350,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildExpandablePanel(
              title: 'Cihaz Bağlantısı',
              icon: Icons.usb_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Basınç ölçüm cihazının bağlı olduğu seri portu seçmek ve bağlantıyı yönetmek için kullanılır.',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _connectedPort,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text('Seç'),
                          items: _ports.map((port) {
                            return DropdownMenuItem(
                              value: port,
                              child: Text(port),
                            );
                          }).toList(),
                          onChanged: (port) {
                            if (port != null) _connect(port);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _refreshPorts,
                        tooltip: 'Portları yenile',
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _connectedPort == null ? null : _disconnect,
                      child: const Text('Bağlantıyı Kes'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard('Durum', _status),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Görüntü Ayarları',
              icon: Icons.tune_outlined,
              initiallyExpanded: false,
              tooltip:
                  'Basınç haritasının ekrandaki görünümünü ayarlar. Kayıt dosyasındaki veriyi değiştirmez.',
              child: Column(
                children: [
                  _buildSliderRow(
                    label: 'Renk',
                    valueText: _maxValue.toInt().toString(),
                    tooltip:
                        'Renk skalasının üst sınırıdır. Düşürülürse düşük basınçlar daha belirgin görünür.',
                    slider: Slider(
                      min: 10,
                      max: 255,
                      value: _maxValue,
                      onChanged: (v) => _onVisualSettingChanged(() {
                        _maxValue = v;
                      }),
                    ),
                  ),
                  _buildSliderRow(
                    label: 'Eşik',
                    valueText: _threshold.toString(),
                    tooltip:
                        'Bu değerin altındaki okumalar görsel değerlendirmede sıfırlanır. Gürültüyü temizlemek için kullanılır.',
                    slider: Slider(
                      min: 0,
                      max: 20,
                      divisions: 20,
                      value: _threshold.toDouble(),
                      onChanged: (v) => _onVisualSettingChanged(() {
                        _threshold = v.toInt();
                      }),
                    ),
                  ),
                  _buildSliderRow(
                    label: 'Yumuş.',
                    valueText: _smoothSize.toString(),
                    tooltip:
                        'Komşu hücre ortalamasıyla görüntüyü yumuşatır. Yüksek değer detay kaybına neden olabilir.',
                    slider: Slider(
                      min: 0,
                      max: 15,
                      divisions: 15,
                      value: _smoothSize.toDouble(),
                      onChanged: (v) => _onVisualSettingChanged(() {
                        _smoothSize = v.toInt();
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Ölçüm Kontrolü',
              icon: Icons.fiber_manual_record_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Canlı gelen basınç verisini ölçüm kaydı olarak alır. Kayıt durunca sistem kaydı yapılır.',
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _connectedPort == null
                          ? null
                          : _toggleRecording,
                      icon: Icon(
                        _isRecording
                            ? Icons.stop_circle_outlined
                            : Icons.fiber_manual_record,
                      ),
                      label: Text(
                        _isRecording ? 'Ölçümü Durdur' : 'Ölçümü Başlat',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red
                            : Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard('Canlı Kare', _frameCount.toString()),
                  if (_isRecording) ...[
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      'Kayıttaki Kare',
                      _currentRecordingFrames.length.toString(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Ölçüm Kayıtları',
              icon: Icons.folder_copy_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Bu oturumda alınan veya dosyadan içe aktarılan basınç ölçümleri burada listelenir.',
              titleAction: IconButton(
                tooltip: _recordings.isEmpty
                    ? 'Dışa aktarılacak kayıt yok'
                    : 'Ölçüm kayıtlarını ZIP olarak dışa aktar',
                onPressed: _recordings.isEmpty || _isExporting
                    ? null
                    : _exportRecordingsZip,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
              ),
              child: _buildRecordingsList(),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Kayıt Dosyası Aç',
              icon: Icons.upload_file_outlined,
              initiallyExpanded: false,
              tooltip:
                  'Bilgisayara kaydedilmiş JSON veya CSV basınç ölçümlerini açar. Açılan kayıt, normal ölçüm kaydı gibi incelenebilir.',
              child: _buildImportPressureRecordingSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportPressureRecordingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bilgisayara kaydedilmiş basınç ölçüm dosyasını açabilirsin. Dosya içe aktarıldığında ölçüm kayıtlarına eklenir ve otomatik inceleme modunda açılır.',
          style: TextStyle(color: Colors.grey[700], height: 1.35),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isImportingPressureFile
                ? null
                : _pickAndImportPressureRecording,
            icon: _isImportingPressureFile
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.folder_open_outlined),
            label: Text(
              _isImportingPressureFile
                  ? 'Dosya açılıyor...'
                  : 'CSV / JSON Dosyası Aç',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Desteklenen formatlar: .json, .csv. ZIP dosyası içindeki kayıtları açmak için önce ZIP’i çıkartıp içindeki recording.json veya recording.csv dosyasını seç.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.35),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel({
    required ui.Image? activePreviewImage,
    required _PressureAnalysis analysis,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _isPlaybackMode ? 'Kayıt İnceleme' : 'Canlı Ölçüm',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_selectedPoint != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedPoint = null;
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Seçimi Temizle'),
              ),
            if (_isPlaybackMode)
              OutlinedButton.icon(
                onPressed: _exitPlaybackMode,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Canlı Ölçüme Dön'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return GestureDetector(
                    onTapDown: (details) {
                      _handleHeatmapTap(details.localPosition, canvasSize);
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: activePreviewImage != null
                                  ? HeatmapPainter(
                                      image: activePreviewImage,
                                      analysis: analysis,
                                      selectedPoint: _selectedPoint,
                                      showCenterOfPressure:
                                          _showCenterOfPressure,
                                      showPeakPressure: _showPeakPressure,
                                      showSelectedPoint: _enablePointProbe,
                                      showCircularRegion: _showCircularRegion,
                                      roiRadius: _roiRadius,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        if (activePreviewImage == null)
                          Center(
                            child: Text(
                              _isPlaybackMode
                                  ? 'İncelenecek kare yok'
                                  : 'Canlı veri bekleniyor',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        if (_enablePointProbe || _showCircularRegion)
                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.58),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _selectedPoint == null
                                    ? 'Bölge seçmek için haritaya tıkla'
                                    : 'Seçili bölge: ${_pointZoneLabel(_selectedPoint)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_isPlaybackMode &&
            _selectedRecording != null &&
            _selectedRecording!.frames.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildPlaybackControls(),
        ],
      ],
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRecording!.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Kare ${_playbackFrameIndex + 1} / ${_selectedRecording!.frames.length}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Slider(
            min: 0,
            max: (_selectedRecording!.frames.length - 1).toDouble(),
            divisions: _selectedRecording!.frames.length > 1
                ? _selectedRecording!.frames.length - 1
                : 1,
            value: _playbackFrameIndex.toDouble().clamp(
              0,
              (_selectedRecording!.frames.length - 1).toDouble(),
            ),
            onChanged: (value) {
              _updatePlaybackFrame(value.round());
            },
          ),
          Text(
            'Ölçüm zamanı: ${_formatDateTime(_selectedRecording!.frames[_playbackFrameIndex].timestamp)}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisPanel({
    required _PressureAnalysis analysis,
    required List<List<int>> activeMatrix,
  }) {
    final selectedValue = _selectedPointValue(activeMatrix);
    final selectedNeighborhoodAvg = _selectedPointNeighborhoodAverage(
      activeMatrix,
    );

    final leftRatio = analysis.totalLoad == 0
        ? 0.0
        : analysis.leftLoad / analysis.totalLoad;
    final rightRatio = analysis.totalLoad == 0
        ? 0.0
        : analysis.rightLoad / analysis.totalLoad;

    final forefootRatio = analysis.totalLoad == 0
        ? 0.0
        : analysis.bottomLoad / analysis.totalLoad;
    final heelRatio = analysis.totalLoad == 0
        ? 0.0
        : analysis.topLoad / analysis.totalLoad;

    final totalMeasuredForceN = _totalMeasuredForceN(analysis);

    final peakForceN = _rawToForceN(analysis.maxValue, analysis);
    final peakPressureKpa = _rawToPressureKpa(analysis.maxValue, analysis);

    final avgContactPressureKpa = analysis.contactCells == 0
        ? null
        : _rawToPressureKpa(analysis.avgContact, analysis);

    final contactAreaCm2 = _contactAreaCm2(analysis.contactCells);

    final selectedPointForceN = selectedValue == null
        ? null
        : _rawToForceN(selectedValue, analysis);

    final selectedPointPressureKpa = selectedValue == null
        ? null
        : _rawToPressureKpa(selectedValue, analysis);

    final selectedNeighborhoodPressureKpa = selectedNeighborhoodAvg == null
        ? null
        : _rawToPressureKpa(selectedNeighborhoodAvg, analysis);

    final selectedRegionForceN = _regionForceN(
      analysis.selectedRegion,
      analysis,
    );

    final selectedRegionPressureKpa = _regionAveragePressureKpa(
      analysis.selectedRegion,
      analysis,
    );

    final showAnthropometricWarning =
        _bodyWeightKg == null ||
        _anthropometricInfoStatus.contains('okunamadı') ||
        _anthropometricInfoStatus.contains('bulunamadı') ||
        _anthropometricInfoStatus.contains('boş');

    final showScientificMetricWarning =
        totalMeasuredForceN == null || analysis.totalLoad == 0;

    return SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildExpandablePanel(
              title: 'Görsel İnceleme Araçları',
              icon: Icons.visibility_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Basınç haritası üzerinde uzman incelemesi için kullanılan görsel katmanları açıp kapatır.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactTileGrid(
                    children: [
                      _buildAnalysisSwitchCard(
                        icon: Icons.adjust_outlined,
                        title: 'Basınç merkezi',
                        subtitle: 'Denge noktası',
                        value: _showCenterOfPressure,
                        onChanged: (value) {
                          setState(() {
                            _showCenterOfPressure = value;
                          });
                        },
                        tooltip:
                            'Basınç merkezi, aktif ölçüm karesindeki basınçların ağırlıklı merkezidir.',
                      ),
                      _buildAnalysisSwitchCard(
                        icon: Icons.local_fire_department_outlined,
                        title: 'En yoğun nokta',
                        subtitle: 'Peak bölge',
                        value: _showPeakPressure,
                        onChanged: (value) {
                          setState(() {
                            _showPeakPressure = value;
                          });
                        },
                        tooltip:
                            'Aktif ölçüm karesinde en yüksek basınç okunan bölgeyi işaretler.',
                      ),
                      _buildAnalysisSwitchCard(
                        icon: Icons.touch_app_outlined,
                        title: 'Nokta ölçümü',
                        subtitle: 'Tek bölge seç',
                        value: _enablePointProbe,
                        onChanged: (value) {
                          setState(() {
                            _enablePointProbe = value;
                          });
                        },
                        tooltip:
                            'Basınç haritasına tıklayarak seçilen bölgedeki kuvvet ve basınç değerlerini gösterir.',
                      ),
                      _buildAnalysisSwitchCard(
                        icon: Icons.radio_button_checked,
                        title: 'Bölge incelemesi',
                        subtitle: 'Dairesel alan',
                        value: _showCircularRegion,
                        onChanged: (value) {
                          setState(() {
                            _showCircularRegion = value;
                          });
                        },
                        tooltip:
                            'Seçili nokta etrafında dairesel bir alan oluşturur ve bu alanın kuvvet/basınç dağılımını hesaplar.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSliderRow(
                    label: 'Alan',
                    valueText: _roiRadius.toString(),
                    tooltip:
                        'Bölge incelemesinde seçilen noktanın etrafındaki inceleme yarıçapını belirler.',
                    slider: Slider(
                      min: 1,
                      max: 12,
                      divisions: 11,
                      value: _roiRadius.toDouble(),
                      onChanged: _showCircularRegion
                          ? (value) {
                              setState(() {
                                _roiRadius = value.round();
                              });
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Ölçüm Referansı',
              icon: Icons.science_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Newton ve kPa hesapları için kullanılan danışan ve sensör referans bilgileri.',
              child: Column(
                children: [
                  _buildCompactTileGrid(
                    children: [
                      _buildClinicalMetricCard(
                        icon: Icons.monitor_weight_outlined,
                        title: 'Kilo',
                        value: _bodyWeightKg == null
                            ? '—'
                            : '${_formatDouble(_bodyWeightKg)} kg',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.scale_outlined,
                        title: 'Referans kuvvet',
                        value: _formatNewton(totalMeasuredForceN),
                        subtitle: 'Kilo × 9.81 m/s²',
                        tooltip:
                            'Ham sensör toplamı bu kuvvete normalize edilir. Sensör kalibrasyonu yerine yaklaşık referans olarak kullanılır.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.straighten_outlined,
                        title: 'Ayakkabı',
                        value: _formatDouble(_shoeSizeEu),
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.grid_view_outlined,
                        title: 'Hücre alanı',
                        value: _formatCm2(_sensorCellAreaCm2),
                        subtitle: 'Tek sensör hücresi',
                        tooltip:
                            'kPa hesabında kullanılan yaklaşık tek hücre alanıdır. Sensör aktif alanı değişirse güncellenmelidir.',
                      ),
                    ],
                  ),
                  if (showAnthropometricWarning ||
                      showScientificMetricWarning) ...[
                    const SizedBox(height: 10),
                    _buildClinicalNotice(
                      icon: Icons.info_outline,
                      text:
                          'Newton ve kPa değerleri için kilo bilgisi ve aktif temas verisi gerekir. Sensör kalibrasyonu yapılana kadar değerler vücut ağırlığına göre normalize edilmiş yaklaşık değerlerdir.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Basınç Özeti',
              icon: Icons.insights_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Aktif ölçüm karesindeki temel basınç ve temas bulgularını bilimsel birimlerle özetler.',
              child: Column(
                children: [
                  _buildCompactTileGrid(
                    children: [
                      _buildClinicalMetricCard(
                        icon: Icons.warning_amber_outlined,
                        title: 'En yüksek basınç',
                        value: _formatKpa(peakPressureKpa),
                        subtitle: analysis.maxValue == 0
                            ? 'Veri bekleniyor'
                            : '${_formatNewton(peakForceN)} • ${_pointZoneLabel(analysis.peakPoint)}',
                        tooltip:
                            'Aktif karedeki en yoğun tek hücre basıncıdır. kPa değeri normalize edilmiş kuvvet ve hücre alanı ile hesaplanır.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.center_focus_strong_outlined,
                        title: 'Basınç merkezi',
                        value: _pressureZoneLabel(
                          row: analysis.centerRow,
                          col: analysis.centerCol,
                        ),
                        subtitle: 'Denge eğilimi',
                        tooltip:
                            'Basınçların ağırlıklı merkezinin ayak tabanındaki yaklaşık bölgesidir.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.grid_on_outlined,
                        title: 'Temas alanı',
                        value: _formatCm2(contactAreaCm2),
                        subtitle: _formatRatio(analysis.contactRatio),
                        tooltip:
                            'Eşik değerinden sonra temas algılanan hücrelerin yaklaşık toplam alanıdır.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.speed_outlined,
                        title: 'Ortalama basınç',
                        value: _formatKpa(avgContactPressureKpa),
                        subtitle: 'Temas eden alan',
                        tooltip:
                            'Sadece temas algılanan hücreler üzerinden hesaplanan yaklaşık ortalama basınçtır.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildClinicalNotice(
                    icon: Icons.science_outlined,
                    text:
                        'N ve kPa değerleri vücut ağırlığına göre normalize edilmiş yaklaşık değerlerdir. Mutlak klinik ölçüm için sensörün kuvvet-kalibrasyon eğrisi ve aktif alan ölçüsü doğrulanmalıdır.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Ayak İçi Yük Dağılımı',
              icon: Icons.balance_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Ölçüm karesindeki yükün ön/arka ve sol/sağ dağılımını N ve yüzde olarak gösterir.',
              child: Column(
                children: [
                  _buildCompactTileGrid(
                    children: [
                      _buildClinicalMetricCard(
                        icon: Icons.arrow_upward_outlined,
                        title: 'Ön ayak yükü',
                        value: _formatNewton(
                          _ratioToForceN(forefootRatio, analysis),
                        ),
                        subtitle: _formatRatio(forefootRatio),
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.arrow_downward_outlined,
                        title: 'Topuk yükü',
                        value: _formatNewton(
                          _ratioToForceN(heelRatio, analysis),
                        ),
                        subtitle: _formatRatio(heelRatio),
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.keyboard_arrow_left_outlined,
                        title: 'Sol taraf yükü',
                        value: _formatNewton(
                          _ratioToForceN(leftRatio, analysis),
                        ),
                        subtitle: _formatRatio(leftRatio),
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.keyboard_arrow_right_outlined,
                        title: 'Sağ taraf yükü',
                        value: _formatNewton(
                          _ratioToForceN(rightRatio, analysis),
                        ),
                        subtitle: _formatRatio(rightRatio),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildClinicalNotice(
                    icon: Icons.info_outline,
                    text:
                        'Ön ayak / topuk ayrımı, parmakların ekranda yukarı baktığı görüntü yerleşimine göre etiketlenmiştir.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildExpandablePanel(
              title: 'Seçili Bölge İncelemesi',
              icon: Icons.my_location_outlined,
              initiallyExpanded: true,
              tooltip:
                  'Harita üzerinde seçilen nokta ve çevresindeki bölgeye ait lokal kuvvet ve basınç sonuçları.',
              child: Column(
                children: [
                  _buildCompactTileGrid(
                    children: [
                      _buildClinicalMetricCard(
                        icon: Icons.place_outlined,
                        title: 'Seçili bölge',
                        value: _pointZoneLabel(_selectedPoint),
                        subtitle: _selectedPoint == null
                            ? 'Haritaya tıkla'
                            : 'Bölge seçildi',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.touch_app_outlined,
                        title: 'Noktasal kuvvet',
                        value: _formatNewton(selectedPointForceN),
                        subtitle: 'Seçili hücre',
                        tooltip:
                            'Seçilen hücredeki ham değer, toplam vücut kuvvetine normalize edilerek Newton cinsinden gösterilir.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.speed_outlined,
                        title: 'Noktasal basınç',
                        value: _formatKpa(selectedPointPressureKpa),
                        subtitle: 'Seçili hücre',
                        tooltip:
                            'Seçilen hücredeki kuvvetin tek hücre alanına bölünmesiyle yaklaşık kPa değeri hesaplanır.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.blur_circular_outlined,
                        title: 'Çevre basıncı',
                        value: _formatKpa(selectedNeighborhoodPressureKpa),
                        subtitle: '3x3 komşuluk',
                        tooltip:
                            'Tek hücre gürültüsünü azaltmak için seçili nokta ve çevresindeki hücrelerden hesaplanan yaklaşık basınçtır.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.donut_large_outlined,
                        title: 'Bölge kuvveti',
                        value: _formatNewton(selectedRegionForceN),
                        subtitle: analysis.selectedRegion == null
                            ? 'Dairesel alan yok'
                            : _formatRatio(analysis.selectedRegion!.loadRatio),
                        tooltip:
                            'Seçili dairesel alan içindeki toplam normalize kuvvettir.',
                      ),
                      _buildClinicalMetricCard(
                        icon: Icons.compress_outlined,
                        title: 'Bölge basıncı',
                        value: _formatKpa(selectedRegionPressureKpa),
                        subtitle: 'Ortalama kPa',
                        tooltip:
                            'Seçili dairesel alandaki toplam kuvvetin temas eden bölge alanına bölünmesiyle hesaplanır.',
                      ),
                    ],
                  ),
                  if (_selectedPoint == null) ...[
                    const SizedBox(height: 10),
                    _buildClinicalNotice(
                      icon: Icons.touch_app_outlined,
                      text:
                          'Lokal inceleme için basınç haritasında bir noktaya tıklayın.',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTileGrid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children.map((child) {
            return SizedBox(width: itemWidth, child: child);
          }).toList(),
        );
      },
    );
  }

  Widget _buildClinicalMetricCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    String? tooltip,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: Colors.teal.shade700),
              ),
              const Spacer(),
              if (tooltip != null && tooltip.trim().isNotEmpty)
                _buildHelpTooltip(tooltip),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.trim().isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? tooltip,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: value ? Colors.teal.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: value ? Colors.teal : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: value
                        ? Colors.teal.withOpacity(0.14)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: value ? Colors.teal.shade700 : Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 0.72,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                ),
                if (tooltip != null && tooltip.trim().isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildHelpTooltip(tooltip),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalNotice({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.blueGrey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandablePanel({
    required String title,
    required IconData icon,
    required Widget child,
    bool initiallyExpanded = false,
    Widget? titleAction,
    String? tooltip,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(icon, color: Colors.teal),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (tooltip != null && tooltip.trim().isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildHelpTooltip(tooltip),
              ],
              if (titleAction != null) ...[
                const SizedBox(width: 4),
                titleAction,
              ],
            ],
          ),
          children: [Align(alignment: Alignment.centerLeft, child: child)],
        ),
      ),
    );
  }

  Widget _buildRecordingsList() {
    if (_recordings.isEmpty) {
      return Container(
        width: double.infinity,
        height: 130,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'Henüz ölçüm kaydı yok',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.separated(
        itemCount: _recordings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final recording = _recordings[index];
          final isSelected = _selectedRecording?.id == recording.id;

          return InkWell(
            onTap: () => _openRecording(recording),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.teal.withOpacity(0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.teal : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(recording.createdAt),
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recording.frames.length} kare',
                    style: TextStyle(color: Colors.grey[800], fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required Widget slider,
    String? tooltip,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Row(
            children: [
              Flexible(child: Text(label)),
              if (tooltip != null && tooltip.trim().isNotEmpty) ...[
                const SizedBox(width: 4),
                _buildHelpTooltip(tooltip),
              ],
            ],
          ),
        ),
        Expanded(child: slider),
        SizedBox(width: 42, child: Text(valueText, textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildHelpTooltip(String message) {
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 350),
      child: Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
    );
  }
}

class PressureFrameSnapshot {
  final DateTime timestamp;
  final List<List<int>> matrix;

  const PressureFrameSnapshot({required this.timestamp, required this.matrix});
}

class PressureRecording {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<PressureFrameSnapshot> frames;

  const PressureRecording({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.frames,
  });
}

class HeatmapPainter extends CustomPainter {
  final ui.Image image;
  final _PressureAnalysis analysis;
  final _GridPoint? selectedPoint;

  final bool showCenterOfPressure;
  final bool showPeakPressure;
  final bool showSelectedPoint;
  final bool showCircularRegion;
  final int roiRadius;

  HeatmapPainter({
    required this.image,
    required this.analysis,
    required this.selectedPoint,
    required this.showCenterOfPressure,
    required this.showPeakPressure,
    required this.showSelectedPoint,
    required this.showCircularRegion,
    required this.roiRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;
    final dstRect = _sensorDrawRect(size);

    canvas.save();
    canvas.translate(0, dstRect.top + dstRect.bottom);
    canvas.scale(1, -1);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(dstRect.left, dstRect.top, dstRect.width, dstRect.height),
      paint,
    );

    canvas.restore();

    if (showPeakPressure && analysis.maxValue > 0) {
      final peakCenter = _cellCenter(
        dstRect,
        analysis.peakPoint.row.toDouble(),
        analysis.peakPoint.col.toDouble(),
      );

      final peakPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;

      canvas.drawCircle(peakCenter, 9, peakPaint);
      canvas.drawLine(
        Offset(peakCenter.dx - 12, peakCenter.dy),
        Offset(peakCenter.dx + 12, peakCenter.dy),
        peakPaint,
      );
      canvas.drawLine(
        Offset(peakCenter.dx, peakCenter.dy - 12),
        Offset(peakCenter.dx, peakCenter.dy + 12),
        peakPaint,
      );
    }

    if (showCenterOfPressure &&
        analysis.centerRow != null &&
        analysis.centerCol != null) {
      final center = _cellCenter(
        dstRect,
        analysis.centerRow!,
        analysis.centerCol!,
      );

      final copPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6;

      canvas.drawCircle(center, 12, copPaint);
      canvas.drawLine(
        Offset(center.dx - 16, center.dy),
        Offset(center.dx + 16, center.dy),
        copPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 16),
        Offset(center.dx, center.dy + 16),
        copPaint,
      );
    }

    final point = selectedPoint;

    if (point != null && showCircularRegion) {
      final center = _cellCenter(
        dstRect,
        point.row.toDouble(),
        point.col.toDouble(),
      );

      final cellWidth = dstRect.width / _pressureCols;
      final cellHeight = dstRect.height / _pressureRows;
      final radiusPx = roiRadius * ((cellWidth + cellHeight) / 2);

      final roiPaint = Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

      canvas.drawCircle(center, radiusPx, roiPaint);
    }

    if (point != null && showSelectedPoint) {
      final center = _cellCenter(
        dstRect,
        point.row.toDouble(),
        point.col.toDouble(),
      );

      final selectedPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;

      canvas.drawCircle(center, 6, selectedPaint);
    }
  }

  Offset _cellCenter(Rect rect, double row, double col) {
    final flippedRow = (_pressureRows - 1) - row;

    return Offset(
      rect.left + ((col + 0.5) / _pressureCols) * rect.width,
      rect.top + ((flippedRow + 0.5) / _pressureRows) * rect.height,
    );
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) => true;
}

Rect _sensorDrawRect(Size size) {
  final canvasRatio = size.width / size.height;

  double drawWidth;
  double drawHeight;
  double offsetX = 0;
  double offsetY = 0;

  if (canvasRatio > _sensorRatio) {
    drawHeight = size.height;
    drawWidth = drawHeight * _sensorRatio;
    offsetX = (size.width - drawWidth) / 2;
  } else {
    drawWidth = size.width;
    drawHeight = drawWidth / _sensorRatio;
    offsetY = (size.height - drawHeight) / 2;
  }

  return Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);
}

class _GridPoint {
  final int row;
  final int col;

  const _GridPoint({required this.row, required this.col});
}

class _PressureAnalysis {
  final int totalLoad;
  final int maxValue;
  final _GridPoint peakPoint;
  final int contactCells;
  final double contactRatio;
  final double avgAll;
  final double avgContact;
  final double? centerRow;
  final double? centerCol;
  final int leftLoad;
  final int rightLoad;
  final int topLoad;
  final int bottomLoad;
  final _RegionStats? selectedRegion;

  const _PressureAnalysis({
    required this.totalLoad,
    required this.maxValue,
    required this.peakPoint,
    required this.contactCells,
    required this.contactRatio,
    required this.avgAll,
    required this.avgContact,
    required this.centerRow,
    required this.centerCol,
    required this.leftLoad,
    required this.rightLoad,
    required this.topLoad,
    required this.bottomLoad,
    required this.selectedRegion,
  });
}

class _RegionStats {
  final int radius;
  final int totalLoad;
  final int cellCount;
  final int contactCellCount;
  final int maxValue;
  final double avgValue;
  final double loadRatio;

  const _RegionStats({
    required this.radius,
    required this.totalLoad,
    required this.cellCount,
    required this.contactCellCount,
    required this.maxValue,
    required this.avgValue,
    required this.loadRatio,
  });
}

class _PressureStats {
  final double maxPressure;
  final double avgPressure;

  const _PressureStats({required this.maxPressure, required this.avgPressure});
}
