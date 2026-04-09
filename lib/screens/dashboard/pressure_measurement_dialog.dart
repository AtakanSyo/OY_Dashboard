import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:oy_site/services/serial/serial_port_factory.dart';

class PressureMeasurementDialog extends StatefulWidget {
  final dynamic pressureRepository;
  final String sessionCode;

  const PressureMeasurementDialog({
    super.key,
    required this.pressureRepository,
    required this.sessionCode,
  });

  @override
  State<PressureMeasurementDialog> createState() =>
      _PressureMeasurementDialogState();
}

class _PressureMeasurementDialogState extends State<PressureMeasurementDialog> {
  late final SerialPortService _serialService;

  List<String> _ports = [];
  String? _connectedPort;

  String _status = "Disconnected";
  int _frameCount = 0;

  static const int rows = 32;
  static const int cols = 64;
  static const int frameLen = 2056;

  double _maxValue = 96;
  int _threshold = 9;
  int _smoothSize = 0;

  List<List<int>> _pressureData =
      List.generate(rows, (_) => List.filled(cols, 0));

  List<int> _buffer = [];
  ui.Image? _heatmapImage;

  DateTime _lastSendTime = DateTime.now();

  bool _isRecording = false;
  bool _isPlaybackMode = false;

  List<PressureRecording> _recordings = [];
  List<PressureFrameSnapshot> _currentRecordingFrames = [];

  PressureRecording? _selectedRecording;
  int _playbackFrameIndex = 0;
  ui.Image? _playbackHeatmapImage;

  @override
  void initState() {
    super.initState();
    _serialService = createSerialPortService();
    _ports = _serialService.availablePorts;
  }

  @override
  void dispose() {
    _serialService.disconnect();
    super.dispose();
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
        _status = 'Connected to $portName';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _disconnect() {
    _serialService.disconnect();
    setState(() {
      _connectedPort = null;
      _status = 'Disconnected';
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

    List<List<int>> newData =
        List.generate(rows, (_) => List.filled(cols, 0));

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

    List<List<int>> result =
        List.generate(rows, (_) => List.filled(cols, 0));

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

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
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
          ? 'Recording started (no active port)'
          : 'Recording started on $_connectedPort';
    });
  }

  void _stopRecording() {
    final frames = List<PressureFrameSnapshot>.from(_currentRecordingFrames);

    PressureRecording? newRecording;
    if (frames.isNotEmpty) {
      newRecording = PressureRecording(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Kayıt ${_recordings.length + 1}',
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
            '${newRecording.title} kaydedildi (${newRecording.frames.length} frame)';
      } else {
        _status = 'Kayıt durduruldu (frame yok)';
      }
    });
  }

  Future<void> _openRecording(PressureRecording recording) async {
    if (recording.frames.isEmpty) return;

    final firstFrame = recording.frames.first;
    final playbackImage = await _generateHeatmapImage(firstFrame.matrix);

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
    final playbackImage = await _generateHeatmapImage(frame.matrix);

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

  String _formatDateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:'
        '${value.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final activePreviewImage =
        _isPlaybackMode ? _playbackHeatmapImage : _heatmapImage;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1250,
        height: 780,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Basınç Ölçüm Önizleme',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Session: ${widget.sessionCode}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Canlı ölçüm bağlantısı kurabilir, kayıt alabilir ve alınan kayıtları frame bazında inceleyebilirsin.',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _connectedPort,
                                  decoration: const InputDecoration(
                                    labelText: 'Port',
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('Select'),
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
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _connectedPort == null ? null : _disconnect,
                                  child: const Text('Bağlantıyı Kes'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _connectedPort == null ? null : _toggleRecording,
                                  icon: Icon(
                                    _isRecording
                                        ? Icons.stop_circle_outlined
                                        : Icons.fiber_manual_record,
                                  ),
                                  label: Text(
                                    _isRecording
                                        ? 'Kaydı Durdur'
                                        : 'Kaydı Başlat',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isRecording
                                        ? Colors.red
                                        : Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSliderRow(
                            label: 'Max',
                            valueText: _maxValue.toInt().toString(),
                            slider: Slider(
                              min: 10,
                              max: 255,
                              value: _maxValue,
                              onChanged: (v) => setState(() => _maxValue = v),
                            ),
                          ),
                          _buildSliderRow(
                            label: 'Thresh',
                            valueText: _threshold.toString(),
                            slider: Slider(
                              min: 0,
                              max: 20,
                              divisions: 20,
                              value: _threshold.toDouble(),
                              onChanged: (v) =>
                                  setState(() => _threshold = v.toInt()),
                            ),
                          ),
                          _buildSliderRow(
                            label: 'Smooth',
                            valueText: _smoothSize.toString(),
                            slider: Slider(
                              min: 0,
                              max: 15,
                              divisions: 15,
                              value: _smoothSize.toDouble(),
                              onChanged: (v) =>
                                  setState(() => _smoothSize = v.toInt()),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard('Status', _status),
                          const SizedBox(height: 10),
                          _buildInfoCard('Frames', _frameCount.toString()),
                          if (_isRecording) ...[
                            const SizedBox(height: 10),
                            _buildInfoCard(
                              'Current Recording Frames',
                              _currentRecordingFrames.length.toString(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                            'Kayıtlar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _recordings.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      'Henüz kayıt yok',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: _recordings.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final recording = _recordings[index];
                                      final isSelected = _selectedRecording?.id ==
                                          recording.id;

                                      return InkWell(
                                        onTap: () => _openRecording(recording),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.teal.withOpacity(0.08)
                                                : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.teal
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recording.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDateTime(
                                                  recording.createdAt,
                                                ),
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${recording.frames.length} frame',
                                                style: TextStyle(
                                                  color: Colors.grey[800],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _isPlaybackMode
                                      ? 'Playback Modu'
                                      : 'Canlı Görünüm',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_isPlaybackMode)
                                OutlinedButton.icon(
                                  onPressed: _exitPlaybackMode,
                                  icon: const Icon(Icons.wifi_tethering),
                                  label: const Text('Canlı Görünüme Dön'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: RepaintBoundary(
                                        child: CustomPaint(
                                          painter: activePreviewImage != null
                                              ? HeatmapPainter(activePreviewImage)
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (activePreviewImage == null)
                                      Center(
                                        child: Text(
                                          _isPlaybackMode
                                              ? 'Playback frame yok'
                                              : 'Canlı veri bekleniyor',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_isPlaybackMode &&
                              _selectedRecording != null &&
                              _selectedRecording!.frames.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Container(
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Frame ${_playbackFrameIndex + 1} / ${_selectedRecording!.frames.length}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    min: 0,
                                    max: (_selectedRecording!.frames.length - 1)
                                        .toDouble(),
                                    divisions:
                                        _selectedRecording!.frames.length > 1
                                            ? _selectedRecording!.frames.length - 1
                                            : 1,
                                    value: _playbackFrameIndex.toDouble().clamp(
                                          0,
                                          (_selectedRecording!.frames.length - 1)
                                              .toDouble(),
                                        ),
                                    onChanged: (value) {
                                      _updatePlaybackFrame(value.round());
                                    },
                                  ),
                                  Text(
                                    'Zaman: ${_formatDateTime(_selectedRecording!.frames[_playbackFrameIndex].timestamp)}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required Widget slider,
  }) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Expanded(child: slider),
        SizedBox(
          width: 36,
          child: Text(
            valueText,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class PressureFrameSnapshot {
  final DateTime timestamp;
  final List<List<int>> matrix;

  const PressureFrameSnapshot({
    required this.timestamp,
    required this.matrix,
  });
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

  HeatmapPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;

    const sensorRatio = 452 / 344;
    final canvasRatio = size.width / size.height;

    double drawWidth, drawHeight;
    double offsetX = 0, offsetY = 0;

    if (canvasRatio > sensorRatio) {
      drawHeight = size.height;
      drawWidth = drawHeight * sensorRatio;
      offsetX = (size.width - drawWidth) / 2;
    } else {
      drawWidth = size.width;
      drawHeight = drawWidth / sensorRatio;
      offsetY = (size.height - drawHeight) / 2;
    }

    final dstRect = Rect.fromLTWH(offsetX, offsetY, drawWidth, drawHeight);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dstRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) => true;
}