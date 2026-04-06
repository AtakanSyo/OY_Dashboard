import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:oy_site/services/serial/serial_port_factory.dart';
import 'dart:math';

class PressureScreen extends StatefulWidget {
  final dynamic pressureRepository;

  const PressureScreen({
    super.key,
    required this.pressureRepository,
  });

  @override
  State<PressureScreen> createState() => _PressureScreenState();
}

class _PressureScreenState extends State<PressureScreen> {
  late final SerialPortService _serialService;
  List<String> _ports = [];
  String? _connectedPort;

  String _status = "Disconnected";
  int _frameCount = 0;

  static const int ROWS = 32;
  static const int COLS = 64;
  static const int FRAME_LEN = 2056;

  double _maxValue = 96;
  int _threshold = 9;
  int _smoothSize = 0;

  List<List<int>> _pressureData =
      List.generate(ROWS, (_) => List.filled(COLS, 0));

  List<int> _buffer = [];

  ui.Image? _heatmapImage;

  DateTime _lastSendTime = DateTime.now();

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

  void _processBuffer() {
    while (true) {
      final start = _findHeader();

      if (start == -1) {
        _buffer.clear();
        return;
      }

      if (_buffer.length < start + FRAME_LEN) return;

      final frame = _buffer.sublist(start, start + FRAME_LEN);
      _buffer = _buffer.sublist(start + FRAME_LEN);

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
    final payload = frame.sublist(4);

    // 🔌 Gelecekte repository / Supabase için hazır hook
    _sendToRepository(payload);

    if (payload.length < ROWS * COLS) return;

    List<List<int>> newData =
        List.generate(ROWS, (_) => List.filled(COLS, 0));

    for (int i = 0; i < ROWS * COLS; i++) {
      final row = (ROWS - 1) - (i ~/ COLS);
      final col = i % COLS;

      int value = payload[i];
      if (value < _threshold) value = 0;

      newData[row][col] = value;
    }

    newData = _applySmoothing(newData);

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
      // Şimdilik sadece hazırlık noktası.
      // İleride örnek:
      // widget.pressureRepository.sendPressureFrame(payload);

      debugPrint("Frame ready for repository: ${payload.length} bytes");
    } catch (e) {
      debugPrint("Repository error: $e");
    }
  }

  List<List<int>> _applySmoothing(List<List<int>> data) {
    int k = _smoothSize;
    if (k <= 0) return data;
    if (k % 2 == 0) k += 1;

    final half = k ~/ 2;

    List<List<int>> result =
        List.generate(ROWS, (_) => List.filled(COLS, 0));

    for (int r = 0; r < ROWS; r++) {
      for (int c = 0; c < COLS; c++) {
        int sum = 0;
        int count = 0;

        for (int dr = -half; dr <= half; dr++) {
          for (int dc = -half; dc <= half; dc++) {
            final nr = r + dr;
            final nc = c + dc;

            if (nr >= 0 && nr < ROWS && nc >= 0 && nc < COLS) {
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
    final pixels = Uint8List(ROWS * COLS * 4);

    for (int r = 0; r < ROWS; r++) {
      for (int c = 0; c < COLS; c++) {
        final color = _colorToInt(data[r][c]);
        final idx = (r * COLS + c) * 4;

        pixels[idx] = (color >> 16) & 0xFF;
        pixels[idx + 1] = (color >> 8) & 0xFF;
        pixels[idx + 2] = color & 0xFF;
        pixels[idx + 3] = 0xFF;
      }
    }

    final completer = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels,
      COLS,
      ROWS,
      ui.PixelFormat.rgba8888,
      (img) => completer.complete(img),
    );

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Basınç Ölçüm",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("Port: "),
                  DropdownButton<String>(
                    value: _connectedPort,
                    hint: const Text("Select"),
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
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 60, child: Text("Max")),
                        Expanded(
                          child: Slider(
                            min: 10,
                            max: 255,
                            value: _maxValue,
                            onChanged: (v) => setState(() => _maxValue = v),
                          ),
                        ),
                        Text(_maxValue.toInt().toString()),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 60, child: Text("Thresh")),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 20,
                            divisions: 20,
                            value: _threshold.toDouble(),
                            onChanged: (v) =>
                                setState(() => _threshold = v.toInt()),
                          ),
                        ),
                        Text(_threshold.toString()),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 60, child: Text("Smooth")),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 15,
                            divisions: 7,
                            value: _smoothSize.toDouble(),
                            onChanged: (v) =>
                                setState(() => _smoothSize = v.toInt()),
                          ),
                        ),
                        Text(_smoothSize.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Text("Status: $_status"),
          Text("Frames: $_frameCount"),
          const SizedBox(height: 10),

          Expanded(
            child: CustomPaint(
              painter: _heatmapImage != null
                  ? HeatmapPainter(_heatmapImage!)
                  : null,
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class HeatmapPainter extends CustomPainter {
  final ui.Image image;

  HeatmapPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;

    final sensorRatio = 452 / 344;
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