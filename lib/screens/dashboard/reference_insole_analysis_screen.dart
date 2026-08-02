import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/optiyou_order_operation_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _AnalysisToolMode {
  calibration,
  measurement,
}

enum _CalibrationMode {
  simpleTwoPoint,
  perspectiveA4,
  perspectiveSquareMarker,
  multiReference,
}

class ReferenceInsoleAnalysisScreen extends StatefulWidget {
  final AppUser currentUser;
  final OptiYouOrderOperationItem operationItem;

  const ReferenceInsoleAnalysisScreen({
    super.key,
    required this.currentUser,
    required this.operationItem,
  });

  @override
  State<ReferenceInsoleAnalysisScreen> createState() =>
      _ReferenceInsoleAnalysisScreenState();
}

class _ReferenceInsoleAnalysisScreenState
    extends State<ReferenceInsoleAnalysisScreen> {
  static const String _tableName = 'order_reference_insole_analyses';

  static const double _a4WidthMm = 210;
  static const double _a4HeightMm = 297;
  static const double _defaultMarkerSizeMm = 25;
  static const double _defaultOneTlDiameterMm = 26.15;
  static const double _minCanvasScale = 0.5;
  static const double _maxCanvasScale = 12;
  static const double _mouseWheelZoomFactor = 1.12;

  SupabaseClient get _client => Supabase.instance.client;

  final TextEditingController _referenceLengthController =
      TextEditingController(text: '25');
  final TextEditingController _noteController = TextEditingController();
  final TransformationController _canvasTransformationController =
      TransformationController();

  bool _isLoading = true;
  bool _isLoadingImage = false;
  bool _isSaving = false;
  bool _isExporting = false;

  String? _errorMessage;
  String? _statusMessage;

  int? _savedAnalysisId;

  List<_ReferencePhotoRecord> _photoRecords = [];
  int? _selectedPhotoIndex;

  Uint8List? _sourceImageBytes;
  ui.Image? _sourceImage;

  _AnalysisToolMode _toolMode = _AnalysisToolMode.calibration;
  _CalibrationMode _calibrationMode = _CalibrationMode.perspectiveA4;

  double _referenceLengthMm = _defaultMarkerSizeMm;
  double? _calibrationPixelDistance;
  double? _pixelsPerMm;

  List<_ImagePoint> _simpleCalibrationPoints = [];
  List<_ImagePoint> _perspectiveCalibrationPoints = [];
  List<_ImagePoint> _pendingMultiReferencePoints = [];
  List<_ImagePoint> _pendingMeasurementPoints = [];

  List<double>? _homographyImageToMm;
  List<_LocalReferenceScale> _multiReferences = [];
  List<_InsoleMeasurement> _measurements = [];
  _InsoleBoundary? _insoleBoundary;
  bool _showInsoleBoundary = true;
  bool _showCalibrationOverlay = true;
  bool _showRoiOverlay = true;
  bool _showInternalPointOverlay = true;
  bool _showMeasurementOverlay = true;
  bool _isDetectingBoundary = false;

  Rect? _boundaryRoiImageRect;
  _ImagePoint? _boundarySeedPoint;
  _ImagePoint? _boundaryBackgroundPoint;

  bool _isSelectingBoundaryRoi = false;
  bool _isSelectingBoundarySeed = false;
  bool _isSelectingBoundaryBackground = false;

  _ImagePoint? _boundaryRoiDragStartPoint;
  _ImagePoint? _boundaryRoiDragCurrentPoint;
  bool _isDraggingBoundaryRoi = false;
  bool _suppressNextCanvasTap = false;

  Timer? _boundaryDetectionDebounce;

  double _boundarySensitivity = 0.52;
  double _boundaryShadowTolerance = 0.62;
  double _boundaryBackgroundSeparation = 0.42;
  int _boundaryClosingStrength = 2;
  int _boundarySmoothingStrength = 2;

  int? get _orderId => widget.operationItem.order.orderId;
  int get _sessionId => widget.operationItem.order.sessionId;
  int get _patientId => widget.operationItem.order.patientId;

  _ReferencePhotoRecord? get _selectedPhoto {
    final index = _selectedPhotoIndex;

    if (index == null) return null;
    if (index < 0 || index >= _photoRecords.length) return null;

    return _photoRecords[index];
  }

  bool get _hasCalibration {
    switch (_calibrationMode) {
      case _CalibrationMode.simpleTwoPoint:
        return _pixelsPerMm != null &&
            _pixelsPerMm! > 0 &&
            _simpleCalibrationPoints.length == 2;
      case _CalibrationMode.perspectiveA4:
      case _CalibrationMode.perspectiveSquareMarker:
        return _homographyImageToMm != null &&
            _perspectiveCalibrationPoints.length == 4;
      case _CalibrationMode.multiReference:
        return _multiReferences.isNotEmpty;
    }
  }

  int get _requiredCalibrationPointCount {
    switch (_calibrationMode) {
      case _CalibrationMode.simpleTwoPoint:
      case _CalibrationMode.multiReference:
        return 2;
      case _CalibrationMode.perspectiveA4:
      case _CalibrationMode.perspectiveSquareMarker:
        return 4;
    }
  }

  int get _currentCalibrationPointCount {
    switch (_calibrationMode) {
      case _CalibrationMode.simpleTwoPoint:
        return _simpleCalibrationPoints.length;
      case _CalibrationMode.perspectiveA4:
      case _CalibrationMode.perspectiveSquareMarker:
        return _perspectiveCalibrationPoints.length;
      case _CalibrationMode.multiReference:
        return _pendingMultiReferencePoints.length;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _boundaryDetectionDebounce?.cancel();
    _referenceLengthController.dispose();
    _noteController.dispose();
    _canvasTransformationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final orderId = _orderId;

    if (orderId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sipariş ID bulunamadı.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    try {
      final photos = await _fetchReferencePhotos();
      final latestAnalysis = await _fetchLatestAnalysis(orderId: orderId);

      int? selectedIndex;

      if (latestAnalysis != null) {
        _applySavedAnalysis(latestAnalysis);

        final savedPhotoId = _asInt(latestAnalysis['source_photo_id']);

        if (savedPhotoId != null) {
          final index = photos.indexWhere((photo) => photo.id == savedPhotoId);
          if (index >= 0) selectedIndex = index;
        }
      }

      selectedIndex ??= photos.isEmpty ? null : 0;

      if (!mounted) return;

      setState(() {
        _photoRecords = photos;
        _selectedPhotoIndex = selectedIndex;
        _isLoading = false;

        if (photos.isEmpty) {
          _errorMessage =
              'Bu siparişe bağlı ölçüm oturumunda referans iç taban fotoğrafı bulunamadı.';
        }
      });

      if (selectedIndex != null) {
        await _loadSelectedPhotoImage(photos[selectedIndex]);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Referans iç taban analizi yüklenemedi: $e';
      });
    }
  }

  Future<List<_ReferencePhotoRecord>> _fetchReferencePhotos() async {
    final response = await _client
        .from('session_reference_photos')
        .select()
        .eq('session_id', _sessionId)
        .order('created_at', ascending: false);

    final rows = (response as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    final records = rows.map((row) {
      final id = _asInt(row['id']);

      final fileType = (row['file_type'] ??
              row['photo_type'] ??
              row['reference_type'] ??
              'reference_photo')
          .toString();

      final fileName = (row['file_name'] ??
              row['title'] ??
              row['photo_title'] ??
              'Referans fotoğraf #${id ?? '—'}')
          .toString();

      final bucket = (row['storage_bucket'] ?? '').toString();
      final path = (row['storage_path'] ?? '').toString();
      final publicUrl = (row['public_url'] ?? '').toString();
      final mimeType = (row['mime_type'] ?? '').toString();

      return _ReferencePhotoRecord(
        id: id,
        fileType: fileType,
        fileName: fileName,
        mimeType: mimeType.trim().isEmpty ? null : mimeType,
        storageBucket: bucket.trim().isEmpty ? null : bucket,
        storagePath: path.trim().isEmpty ? null : path,
        publicUrl: publicUrl.trim().isEmpty ? null : publicUrl,
        createdAt: _asDateTime(row['created_at']),
      );
    }).toList();

    records.sort((a, b) {
      final aScore = _referencePhotoPreferenceScore(a);
      final bScore = _referencePhotoPreferenceScore(b);
      return bScore.compareTo(aScore);
    });

    return records;
  }

  int _referencePhotoPreferenceScore(_ReferencePhotoRecord record) {
    final text = [
      record.fileType,
      record.fileName,
      record.storagePath ?? '',
      record.publicUrl ?? '',
    ].join(' ').toLowerCase();

    int score = 0;

    if (text.contains('insole')) score += 4;
    if (text.contains('ic_taban')) score += 4;
    if (text.contains('iç_taban')) score += 4;
    if (text.contains('taban')) score += 3;
    if (text.contains('reference')) score += 2;
    if (text.contains('referans')) score += 2;
    if (text.contains('photo')) score += 1;
    if (text.contains('foto')) score += 1;

    return score;
  }

  Future<Map<String, dynamic>?> _fetchLatestAnalysis({
    required int orderId,
  }) async {
    final response = await _client
        .from(_tableName)
        .select()
        .eq('order_id', orderId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return Map<String, dynamic>.from(response as Map);
  }

  void _applySavedAnalysis(Map<String, dynamic> row) {
    _savedAnalysisId = _asInt(row['id']);

    final calibrationJson = _asMap(row['calibration_points_json']);

    final dbCalibrationType =
        (calibrationJson['mode'] ?? row['calibration_type'] ?? '').toString();
    _calibrationMode = _calibrationModeFromDbCode(dbCalibrationType);

    final referenceMm = _asDouble(row['calibration_reference_mm']) ??
        _asDouble(calibrationJson['referenceLengthMm']);

    if (referenceMm != null && referenceMm > 0) {
      _referenceLengthMm = referenceMm;
      _referenceLengthController.text = _trimDoubleText(referenceMm);
    }

    _calibrationPixelDistance = _asDouble(row['calibration_pixel_distance']);
    _pixelsPerMm = _asDouble(row['pixels_per_mm']);

    final note = (calibrationJson['note'] ?? '').toString();
    if (note.trim().isNotEmpty) {
      _noteController.text = note;
    }

    _simpleCalibrationPoints = _asList(
      calibrationJson['simplePoints'] ?? calibrationJson['points'],
    ).map(_pointFromDynamic).whereType<_ImagePoint>().take(2).toList();

    _perspectiveCalibrationPoints = _asList(
      calibrationJson['perspectivePoints'] ?? calibrationJson['imagePoints'],
    ).map(_pointFromDynamic).whereType<_ImagePoint>().take(4).toList();

    _homographyImageToMm = _asDoubleList(calibrationJson['homographyImageToMm']);

    _multiReferences = _asList(calibrationJson['multiReferences'])
        .map(_localReferenceFromDynamic)
        .whereType<_LocalReferenceScale>()
        .toList();

    final measurementsJson = _asList(row['measurements_json']);

    _measurements = measurementsJson
        .map(_measurementFromDynamic)
        .whereType<_InsoleMeasurement>()
        .toList();

    final boundaryFromColumn = _boundaryFromDynamic(row['insole_boundary_json']);
    final boundaryFromCalibration =
        _boundaryFromDynamic(calibrationJson['insoleBoundary']);

    _insoleBoundary = boundaryFromColumn ?? boundaryFromCalibration;
    _boundaryRoiImageRect = _insoleBoundary?.roiImageRect;
    _boundarySeedPoint = _insoleBoundary?.seedPoint;

    final boundarySettings = _asMap(calibrationJson['boundarySettings']);

    _boundarySensitivity =
        ((_asDouble(boundarySettings['sensitivity']) ??
                    _insoleBoundary?.sensitivity ??
                    0.52)
                .clamp(0.0, 1.0))
            .toDouble();

    _boundaryShadowTolerance =
        ((_asDouble(boundarySettings['shadowTolerance']) ??
                    _insoleBoundary?.shadowTolerance ??
                    0.62)
                .clamp(0.0, 1.0))
            .toDouble();

    _boundaryBackgroundSeparation =
        ((_asDouble(boundarySettings['backgroundSeparation']) ??
                    _insoleBoundary?.backgroundSeparation ??
                    0.42)
                .clamp(0.0, 1.0))
            .toDouble();

    _boundaryClosingStrength =
        ((_asInt(boundarySettings['closingStrength']) ??
                    _insoleBoundary?.closingStrength ??
                    2)
                .clamp(0, 6))
            .toInt();

    _boundarySmoothingStrength =
        ((_asInt(boundarySettings['smoothingStrength']) ??
                    _insoleBoundary?.smoothingStrength ??
                    2)
                .clamp(0, 6))
            .toInt();

    _recomputeCalibrationAndMeasurements();
  }

  Future<void> _loadSelectedPhotoImage(_ReferencePhotoRecord photo) async {
    _resetCanvasView();

    setState(() {
      _isLoadingImage = true;
      _sourceImage = null;
      _sourceImageBytes = null;
      _statusMessage = 'Referans görsel yükleniyor...';
    });

    try {
      final bytes = await _loadPhotoBytes(photo);
      final image = await _decodeImage(bytes);

      if (!mounted) return;

      setState(() {
        _sourceImageBytes = bytes;
        _sourceImage = image;
        _isLoadingImage = false;
        _statusMessage = 'Referans görsel yüklendi.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingImage = false;
        _errorMessage = 'Referans görsel açılamadı: $e';
      });
    }
  }

  Future<Uint8List> _loadPhotoBytes(_ReferencePhotoRecord photo) async {
    final bucket = photo.storageBucket;
    final path = photo.storagePath;

    if (bucket != null &&
        bucket.trim().isNotEmpty &&
        path != null &&
        path.trim().isNotEmpty) {
      return _client.storage.from(bucket).download(path);
    }

    final publicUrl = photo.publicUrl;

    if (publicUrl != null && publicUrl.trim().isNotEmpty) {
      final byteData = await NetworkAssetBundle(Uri.parse(publicUrl)).load(
        publicUrl,
      );

      return byteData.buffer.asUint8List();
    }

    throw Exception('Fotoğraf için storage yolu veya public URL bulunamadı.');
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final completer = Completer<ui.Image>();

    ui.decodeImageFromList(
      bytes,
      (image) => completer.complete(image),
    );

    return completer.future;
  }

  void _changeCalibrationMode(_CalibrationMode mode) {
    setState(() {
      _calibrationMode = mode;
      _toolMode = _AnalysisToolMode.calibration;
      _simpleCalibrationPoints = [];
      _perspectiveCalibrationPoints = [];
      _pendingMultiReferencePoints = [];
      _pendingMeasurementPoints = [];
      _homographyImageToMm = null;
      _multiReferences = [];
      _measurements = [];
      _calibrationPixelDistance = null;
      _pixelsPerMm = null;

      if (mode == _CalibrationMode.perspectiveA4) {
        _referenceLengthMm = _a4WidthMm;
        _referenceLengthController.text = _trimDoubleText(_a4WidthMm);
      } else if (mode == _CalibrationMode.perspectiveSquareMarker ||
          mode == _CalibrationMode.simpleTwoPoint) {
        _referenceLengthMm = _defaultMarkerSizeMm;
        _referenceLengthController.text = _trimDoubleText(_defaultMarkerSizeMm);
      } else if (mode == _CalibrationMode.multiReference) {
        _referenceLengthMm = _defaultOneTlDiameterMm;
        _referenceLengthController.text = _trimDoubleText(
          _defaultOneTlDiameterMm,
        );
      }

      _statusMessage = _calibrationInstruction;
    });
  }

  void _onReferenceLengthChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));

    setState(() {
      if (parsed != null && parsed > 0) {
        _referenceLengthMm = parsed;
      }

      _recomputeCalibrationAndMeasurements();
    });
  }

  void _recomputeCalibrationAndMeasurements() {
    _calibrationPixelDistance = null;
    _pixelsPerMm = null;
    _homographyImageToMm = _homographyImageToMm;

    switch (_calibrationMode) {
      case _CalibrationMode.simpleTwoPoint:
        if (_simpleCalibrationPoints.length == 2 && _referenceLengthMm > 0) {
          final pixelDistance = _distancePx(
            _simpleCalibrationPoints[0],
            _simpleCalibrationPoints[1],
          );

          if (pixelDistance > 0) {
            _calibrationPixelDistance = pixelDistance;
            _pixelsPerMm = pixelDistance / _referenceLengthMm;
          }
        }
        break;
      case _CalibrationMode.perspectiveA4:
      case _CalibrationMode.perspectiveSquareMarker:
        if (_perspectiveCalibrationPoints.length == 4) {
          _homographyImageToMm = _computeHomographyImageToWorld(
            imagePoints: _perspectiveCalibrationPoints,
            worldPoints: _worldPointsForCurrentPerspectiveMode(),
          );
        } else {
          _homographyImageToMm = null;
        }
        break;
      case _CalibrationMode.multiReference:
        if (_multiReferences.isNotEmpty) {
          _calibrationPixelDistance = _multiReferences
                  .map((reference) => reference.pixelDistance)
                  .reduce((a, b) => a + b) /
              _multiReferences.length;

          _pixelsPerMm = _multiReferences
                  .map((reference) => reference.pixelsPerMm)
                  .reduce((a, b) => a + b) /
              _multiReferences.length;
        }
        break;
    }

    if (_hasCalibration) {
      _measurements = _measurements.map((measurement) {
        final recalculated = _buildMeasurement(
          start: measurement.startImage,
          end: measurement.endImage,
          label: measurement.label,
          id: measurement.id,
          createdAt: measurement.createdAt,
        );

        return recalculated ?? measurement;
      }).toList();
    }
  }

  List<_ImagePoint> _worldPointsForCurrentPerspectiveMode() {
    switch (_calibrationMode) {
      case _CalibrationMode.perspectiveA4:
        return const [
          _ImagePoint(x: 0, y: 0),
          _ImagePoint(x: _a4WidthMm, y: 0),
          _ImagePoint(x: _a4WidthMm, y: _a4HeightMm),
          _ImagePoint(x: 0, y: _a4HeightMm),
        ];
      case _CalibrationMode.perspectiveSquareMarker:
        final size = _referenceLengthMm > 0
            ? _referenceLengthMm
            : _defaultMarkerSizeMm;

        return [
          const _ImagePoint(x: 0, y: 0),
          _ImagePoint(x: size, y: 0),
          _ImagePoint(x: size, y: size),
          _ImagePoint(x: 0, y: size),
        ];
      case _CalibrationMode.simpleTwoPoint:
      case _CalibrationMode.multiReference:
        return const [];
    }
  }


  double _currentCanvasScale() {
    return _canvasTransformationController.value.getMaxScaleOnAxis();
  }

  void _resetCanvasView() {
    _canvasTransformationController.value = Matrix4.identity();
  }

  void _handleCanvasPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final currentScale = _currentCanvasScale();
    final zoomFactor = event.scrollDelta.dy < 0
        ? _mouseWheelZoomFactor
        : 1 / _mouseWheelZoomFactor;

    final nextScale = (currentScale * zoomFactor)
        .clamp(_minCanvasScale, _maxCanvasScale)
        .toDouble();

    if ((nextScale - currentScale).abs() < 0.001) return;

    final focalPoint = event.localPosition;
    final scenePoint = _canvasTransformationController.toScene(focalPoint);

    _canvasTransformationController.value = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(nextScale)
      ..translate(-scenePoint.dx, -scenePoint.dy);
  }

  Widget _buildZoomIndicator() {
    return AnimatedBuilder(
      animation: _canvasTransformationController,
      builder: (context, _) {
        final zoomPercent = (_currentCanvasScale() * 100).round();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.zoom_in_outlined,
                    size: 17,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$zoomPercent%',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Görünümü sıfırla',
              onPressed: _resetCanvasView,
              icon: const Icon(Icons.center_focus_strong_outlined),
            ),
          ],
        );
      },
    );
  }


  Widget _buildOverlayVisibilityControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOverlayIconToggle(
            tooltip: 'Kalibrasyon çizgilerini göster/gizle',
            icon: Icons.straighten_outlined,
            value: _showCalibrationOverlay,
            onChanged: (value) {
              setState(() => _showCalibrationOverlay = value);
            },
          ),
          _buildOverlayIconToggle(
            tooltip: 'ROI alanını göster/gizle',
            icon: Icons.crop_free_outlined,
            value: _showRoiOverlay,
            onChanged: (value) {
              setState(() => _showRoiOverlay = value);
            },
          ),
          _buildOverlayIconToggle(
            tooltip: 'İç taban içi noktayı göster/gizle',
            icon: Icons.my_location_outlined,
            value: _showInternalPointOverlay,
            onChanged: (value) {
              setState(() => _showInternalPointOverlay = value);
            },
          ),
          _buildOverlayIconToggle(
            tooltip: 'Ölçüm çizgilerini göster/gizle',
            icon: Icons.linear_scale_outlined,
            value: _showMeasurementOverlay,
            onChanged: (value) {
              setState(() => _showMeasurementOverlay = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayIconToggle({
    required String tooltip,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!value),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: value ? Colors.teal.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            icon,
            size: 18,
            color: value ? Colors.teal.shade700 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  void _handleImageTap(Offset localPosition, Size canvasSize) async {
    final image = _sourceImage;
    if (image == null) return;

    final imageRect = _imageDrawRect(
      canvasSize,
      image.width / image.height,
    );

    if (!imageRect.contains(localPosition)) return;

    final point = _canvasPointToImagePoint(
      localPosition,
      imageRect,
      image,
    );

    if (_isSelectingBoundarySeed) {
      _setBoundarySeedPoint(point);
      return;
    }

    if (_isSelectingBoundaryRoi) {
      return;
    }

    if (_toolMode == _AnalysisToolMode.calibration) {
      await _handleCalibrationTap(point);
      return;
    }

    await _handleMeasurementTap(point);
  }

  Future<void> _handleCalibrationTap(_ImagePoint point) async {
    switch (_calibrationMode) {
      case _CalibrationMode.simpleTwoPoint:
        setState(() {
          if (_simpleCalibrationPoints.length >= 2) {
            _simpleCalibrationPoints = [point];
          } else {
            _simpleCalibrationPoints = [..._simpleCalibrationPoints, point];
          }

          _recomputeCalibrationAndMeasurements();
          _statusMessage = _simpleCalibrationPoints.length == 2
              ? 'Basit kalibrasyon tamamlandı. Ölçüm moduna geçebilirsin.'
              : 'Referans uzunluğu için ikinci noktayı seç.';
        });
        break;
      case _CalibrationMode.perspectiveA4:
      case _CalibrationMode.perspectiveSquareMarker:
        setState(() {
          if (_perspectiveCalibrationPoints.length >= 4) {
            _perspectiveCalibrationPoints = [point];
          } else {
            _perspectiveCalibrationPoints = [
              ..._perspectiveCalibrationPoints,
              point,
            ];
          }

          _recomputeCalibrationAndMeasurements();
          _statusMessage = _perspectiveCalibrationPoints.length == 4
              ? 'Perspektif kalibrasyon tamamlandı. Ölçüm moduna geçebilirsin.'
              : _calibrationInstruction;
        });
        break;
      case _CalibrationMode.multiReference:
        await _handleMultiReferenceTap(point);
        break;
    }
  }

  Future<void> _handleMultiReferenceTap(_ImagePoint point) async {
    if (_pendingMultiReferencePoints.isEmpty) {
      setState(() {
        _pendingMultiReferencePoints = [point];
        _statusMessage =
            'Çoklu referans için ikinci noktayı seç. Örn. 1 TL çapının karşı ucu.';
      });
      return;
    }

    final start = _pendingMultiReferencePoints.first;
    final end = point;
    final pixelDistance = _distancePx(start, end);

    if (pixelDistance <= 0) return;

    final result = await _showReferenceScaleDialog(
      defaultLabel: 'Referans ${_multiReferences.length + 1}',
      defaultLengthMm: _referenceLengthMm,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _pendingMultiReferencePoints = [];
        _statusMessage = 'Çoklu referans ekleme iptal edildi.';
      });
      return;
    }

    final pixelsPerMm = pixelDistance / result.lengthMm;

    setState(() {
      _multiReferences = [
        ..._multiReferences,
        _LocalReferenceScale(
          id: 'r_${DateTime.now().microsecondsSinceEpoch}',
          label: result.label,
          start: start,
          end: end,
          referenceLengthMm: result.lengthMm,
          pixelDistance: pixelDistance,
          pixelsPerMm: pixelsPerMm,
          createdAt: DateTime.now(),
        ),
      ];
      _pendingMultiReferencePoints = [];
      _recomputeCalibrationAndMeasurements();
      _statusMessage =
          'Referans eklendi. Farklı bölgelere yeni referans ekleyebilir veya ölçüm moduna geçebilirsin.';
    });
  }

  Future<_ReferenceScaleDialogResult?> _showReferenceScaleDialog({
    required String defaultLabel,
    required double defaultLengthMm,
  }) async {
    final labelController = TextEditingController(text: defaultLabel);
    final lengthController = TextEditingController(
      text: _trimDoubleText(defaultLengthMm),
    );

    final result = await showDialog<_ReferenceScaleDialogResult>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Referans Ölçüsü'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Referans adı',
                  hintText: 'Örn. Sol üst 1 TL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gerçek uzunluk (mm)',
                  hintText: 'Örn. 26.15 veya 25',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              final label = labelController.text.trim().isEmpty
                  ? defaultLabel
                  : labelController.text.trim();
              final length = double.tryParse(
                lengthController.text.trim().replaceAll(',', '.'),
              );

              if (length == null || length <= 0) {
                return;
              }

              Navigator.pop(
                context,
                _ReferenceScaleDialogResult(
                  label: label,
                  lengthMm: length,
                ),
              );
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    labelController.dispose();
    lengthController.dispose();

    return result;
  }

  Future<void> _handleMeasurementTap(_ImagePoint point) async {
    if (!_hasCalibration) {
      _showMessage('Önce kalibrasyon yapmalısın.');
      return;
    }

    if (_pendingMeasurementPoints.length >= 2) {
      setState(() {
        _pendingMeasurementPoints = [point];
      });
      return;
    }

    if (_pendingMeasurementPoints.isEmpty) {
      setState(() {
        _pendingMeasurementPoints = [point];
        _statusMessage = 'Ölçüm için ikinci noktayı seç.';
      });
      return;
    }

    final start = _pendingMeasurementPoints.first;
    final end = point;

    final defaultLabel = 'Ölçüm ${_measurements.length + 1}';
    final label = await _showMeasurementLabelDialog(defaultLabel);

    if (!mounted) return;

    final measurement = _buildMeasurement(
      start: start,
      end: end,
      label: label ?? defaultLabel,
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );

    if (measurement == null) {
      _showMessage('Ölçüm hesaplanamadı. Kalibrasyon noktalarını kontrol et.');
      return;
    }

    setState(() {
      _measurements = [..._measurements, measurement];
      _pendingMeasurementPoints = [];
      _statusMessage = 'Ölçüm eklendi: ${_formatMm(measurement.lengthMm)}';
    });
  }

  _InsoleMeasurement? _buildMeasurement({
    required _ImagePoint start,
    required _ImagePoint end,
    required String label,
    required String id,
    required DateTime createdAt,
  }) {
    final pixelDistance = _distancePx(start, end);

    if (pixelDistance <= 0) return null;

    switch (_calibrationMode) {
      case _CalibrationMode.perspectiveA4:
      case _CalibrationMode.perspectiveSquareMarker:
        final homography = _homographyImageToMm;
        if (homography == null) return null;

        final startMm = _applyHomography(start, homography);
        final endMm = _applyHomography(end, homography);

        if (startMm == null || endMm == null) return null;

        final lengthMm = _distancePx(startMm, endMm);

        return _InsoleMeasurement(
          id: id,
          label: label,
          startImage: start,
          endImage: end,
          startMm: startMm,
          endMm: endMm,
          pixelDistance: pixelDistance,
          lengthMm: lengthMm,
          localPixelsPerMm: null,
          calibrationMethod: _calibrationDbCode(_calibrationMode),
          createdAt: createdAt,
        );
      case _CalibrationMode.simpleTwoPoint:
        final ppm = _pixelsPerMm;
        if (ppm == null || ppm <= 0) return null;

        return _InsoleMeasurement(
          id: id,
          label: label,
          startImage: start,
          endImage: end,
          startMm: null,
          endMm: null,
          pixelDistance: pixelDistance,
          lengthMm: pixelDistance / ppm,
          localPixelsPerMm: ppm,
          calibrationMethod: _calibrationDbCode(_calibrationMode),
          createdAt: createdAt,
        );
      case _CalibrationMode.multiReference:
        final midpoint = _ImagePoint(
          x: (start.x + end.x) / 2,
          y: (start.y + end.y) / 2,
        );

        final ppm = _localPixelsPerMmAt(midpoint);
        if (ppm == null || ppm <= 0) return null;

        return _InsoleMeasurement(
          id: id,
          label: label,
          startImage: start,
          endImage: end,
          startMm: null,
          endMm: null,
          pixelDistance: pixelDistance,
          lengthMm: pixelDistance / ppm,
          localPixelsPerMm: ppm,
          calibrationMethod: _calibrationDbCode(_calibrationMode),
          createdAt: createdAt,
        );
    }
  }

  double? _localPixelsPerMmAt(_ImagePoint imagePoint) {
    if (_multiReferences.isEmpty) return null;

    double weightedSum = 0;
    double weightTotal = 0;

    for (final reference in _multiReferences) {
      final distance = _distancePx(imagePoint, reference.center);
      final weight = 1 / math.pow(distance + 1, 2);

      weightedSum += reference.pixelsPerMm * weight;
      weightTotal += weight;
    }

    if (weightTotal <= 0) return null;

    return weightedSum / weightTotal;
  }

  Future<String?> _showMeasurementLabelDialog(String defaultLabel) async {
    final controller = TextEditingController(text: defaultLabel);

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ölçüm Adı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Ölçüm adı',
            hintText: 'Örn. Topuk - Ön uç uzunluğu',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            Navigator.pop(context, trimmed.isEmpty ? defaultLabel : trimmed);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              Navigator.pop(context, trimmed.isEmpty ? defaultLabel : trimmed);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    controller.dispose();

    return result;
  }

  Future<void> _saveAnalysis() async {
    final orderId = _orderId;

    if (orderId == null) {
      _showMessage('Sipariş ID bulunamadı.');
      return;
    }

    if (!_hasCalibration) {
      _showMessage('Kaydetmeden önce kalibrasyon yapmalısın.');
      return;
    }

    final selectedPhoto = _selectedPhoto;

    setState(() {
      _isSaving = true;
      _statusMessage = 'Referans iç taban analizi kaydediliyor...';
    });

    try {
      final payload = <String, dynamic>{
        'order_id': orderId,
        'session_id': _sessionId,
        'patient_id': _patientId,
        'source_photo_id': selectedPhoto?.id,
        'source_photo_bucket': selectedPhoto?.storageBucket,
        'source_photo_path': selectedPhoto?.storagePath,
        'source_photo_public_url': selectedPhoto?.publicUrl,
        'calibration_type': _calibrationDbCode(_calibrationMode),
        'calibration_reference_label': _calibrationModeLabel(_calibrationMode),
        'calibration_reference_mm': _referenceLengthMm,
        'calibration_pixel_distance': _calibrationPixelDistance,
        'pixels_per_mm': _pixelsPerMm,
        'calibration_points_json': _calibrationJson(),
        'measurements_json':
            _measurements.map((measurement) => measurement.toJson()).toList(),
        'insole_boundary_json':
            _insoleBoundary?.toJson() ?? <String, dynamic>{},
        'created_by_user_id': widget.currentUser.userId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_savedAnalysisId == null) {
        final saved = await _client
            .from(_tableName)
            .insert(payload)
            .select('id')
            .single();

        _savedAnalysisId = _asInt((saved as Map)['id']);
      } else {
        await _client
            .from(_tableName)
            .update(payload)
            .eq('id', _savedAnalysisId!);
      }

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _statusMessage = 'Analiz order ile ilişkilendirilerek kaydedildi.';
      });

      _showMessage('Referans iç taban analizi kaydedildi.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _statusMessage = null;
      });

      _showMessage('Analiz kaydedilemedi: $e');
    }
  }

  Map<String, dynamic> _calibrationJson() {
    return {
      'mode': _calibrationDbCode(_calibrationMode),
      'label': _calibrationModeLabel(_calibrationMode),
      'referenceLengthMm': _referenceLengthMm,
      'a4WidthMm': _a4WidthMm,
      'a4HeightMm': _a4HeightMm,
      'simplePoints':
          _simpleCalibrationPoints.map((point) => point.toJson()).toList(),
      'perspectivePoints': _perspectiveCalibrationPoints
          .map((point) => point.toJson())
          .toList(),
      'worldPoints': _worldPointsForCurrentPerspectiveMode()
          .map((point) => point.toJson())
          .toList(),
      'homographyImageToMm': _homographyImageToMm,
      'multiReferences':
          _multiReferences.map((reference) => reference.toJson()).toList(),
      'insoleBoundary': _insoleBoundary?.toJson(),
      'boundarySettings': {
        'sensitivity': _boundarySensitivity,
        'shadowTolerance': _boundaryShadowTolerance,
        'backgroundSeparation': _boundaryBackgroundSeparation,
        'closingStrength': _boundaryClosingStrength,
        'smoothingStrength': _boundarySmoothingStrength,
      },
      'calibrationPixelDistance': _calibrationPixelDistance,
      'pixelsPerMm': _pixelsPerMm,
      'note': _noteController.text.trim(),
    };
  }


  Future<void> _exportFullAnnotatedPng() async {
    await _exportPngVariant(
      transparentOverlay: false,
      fileSuffix: 'full_annotated',
      preparingMessage: 'Tam PNG hazırlanıyor...',
      successMessage: 'Tam PNG dışa aktarıldı.',
    );
  }

  Future<void> _exportTransparentOverlayPng() async {
    await _exportPngVariant(
      transparentOverlay: true,
      fileSuffix: 'transparent_overlay',
      preparingMessage: 'Şeffaf PNG overlay hazırlanıyor...',
      successMessage: 'Şeffaf PNG overlay dışa aktarıldı.',
    );
  }

  Future<void> _exportFullSvg() async {
    await _exportSvgVariant(
      transparentOverlay: false,
      fileSuffix: 'full_annotated',
      preparingMessage: 'Tam SVG hazırlanıyor...',
      successMessage: 'Tam SVG dışa aktarıldı.',
    );
  }

  Future<void> _exportTransparentOverlaySvg() async {
    await _exportSvgVariant(
      transparentOverlay: true,
      fileSuffix: 'transparent_overlay',
      preparingMessage: 'Şeffaf SVG overlay hazırlanıyor...',
      successMessage: 'Şeffaf SVG overlay dışa aktarıldı.',
    );
  }

  Future<void> _exportPngVariant({
    required bool transparentOverlay,
    required String fileSuffix,
    required String preparingMessage,
    required String successMessage,
  }) async {
    if (_sourceImage == null) {
      _showMessage('Dışa aktarılacak görsel yok.');
      return;
    }

    if (_measurements.isEmpty && _insoleBoundary == null) {
      _showMessage(
        'PNG için en az bir ölçüm veya iç taban sınırı eklemelisin.',
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _statusMessage = preparingMessage;
    });

    try {
      final bytes = await _buildAnnotatedPngBytes(
        transparentOverlay: transparentOverlay,
      );
      final fileName =
          '${_safeFileName(widget.operationItem.order.orderNo)}_reference_insole_$fileSuffix.png';

      await _saveBytesToComputer(
        fileName: fileName,
        bytes: bytes,
        extensions: const ['png'],
      );

      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _statusMessage = '$successMessage tamamlandı.';
      });

      _showMessage(successMessage);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _statusMessage = null;
      });

      _showMessage('PNG dışa aktarılamadı: $e');
    }
  }

  Future<void> _exportSvgVariant({
    required bool transparentOverlay,
    required String fileSuffix,
    required String preparingMessage,
    required String successMessage,
  }) async {
    if (_sourceImage == null || (!transparentOverlay && _sourceImageBytes == null)) {
      _showMessage('Dışa aktarılacak görsel yok.');
      return;
    }

    if (_measurements.isEmpty && _insoleBoundary == null) {
      _showMessage(
        'SVG için en az bir ölçüm veya iç taban sınırı eklemelisin.',
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _statusMessage = preparingMessage;
    });

    try {
      final svg = _buildSvgString(
        transparentOverlay: transparentOverlay,
      );
      final fileName =
          '${_safeFileName(widget.operationItem.order.orderNo)}_reference_insole_$fileSuffix.svg';

      await _saveBytesToComputer(
        fileName: fileName,
        bytes: Uint8List.fromList(utf8.encode(svg)),
        extensions: const ['svg'],
      );

      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _statusMessage = '$successMessage tamamlandı.';
      });

      _showMessage(successMessage);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isExporting = false;
        _statusMessage = null;
      });

      _showMessage('SVG dışa aktarılamadı: $e');
    }
  }

  Future<void> _saveBytesToComputer({
    required String fileName,
    required Uint8List bytes,
    required List<String> extensions,
  }) async {
    await FilePicker.saveFile(
      dialogTitle: 'Dosyayı kaydet',
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: extensions,
    );
  }

  Future<Uint8List> _buildAnnotatedPngBytes({
    bool transparentOverlay = false,
  }) async {
    final image = _sourceImage!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    if (!transparentOverlay) {
      final backgroundPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);

      canvas.drawImage(image, Offset.zero, Paint());
    }

    _drawAnnotationsOnCanvas(
      canvas: canvas,
      imageWidth: width,
      imageHeight: height,
      exportScale: 1,
      includeCalibration: !transparentOverlay,
      includeRoi: !transparentOverlay,
      includeInternalPoint: !transparentOverlay,
      includeBoundary: true,
      includeMeasurements: true,
      includeReferenceObjects: !transparentOverlay,
    );

    final picture = recorder.endRecording();
    final exportedImage = await picture.toImage(
      image.width,
      image.height,
    );

    final byteData = await exportedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData == null) {
      throw Exception('PNG byte verisi oluşturulamadı.');
    }

    return byteData.buffer.asUint8List();
  }

  void _drawAnnotationsOnCanvas({
    required Canvas canvas,
    required double imageWidth,
    required double imageHeight,
    required double exportScale,
    required bool includeCalibration,
    required bool includeRoi,
    required bool includeInternalPoint,
    required bool includeBoundary,
    required bool includeMeasurements,
    required bool includeReferenceObjects,
  }) {
    final lineStroke = math.max(2, imageWidth * 0.004) * exportScale;

    final measurementPaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = lineStroke
      ..strokeCap = StrokeCap.round;

    final referencePaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = lineStroke
      ..strokeCap = StrokeCap.round;

    final calibrationPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = lineStroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.fill;

    if (includeBoundary) {
      final boundary = _insoleBoundary;
      if (boundary != null && boundary.points.length >= 3) {
        final boundaryPath = Path()
          ..moveTo(boundary.points.first.x, boundary.points.first.y);

        for (final point in boundary.points.skip(1)) {
          boundaryPath.lineTo(point.x, point.y);
        }

        boundaryPath.close();

        canvas.drawPath(
          boundaryPath,
          Paint()
            ..color = Colors.cyan.withOpacity(0.10)
            ..style = PaintingStyle.fill,
        );

        canvas.drawPath(
          boundaryPath,
          Paint()
            ..color = Colors.cyan.shade700
            ..style = PaintingStyle.stroke
            ..strokeWidth = lineStroke
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    if (includeRoi) {
      final roi = _boundaryRoiImageRect;
      if (roi != null && roi.width > 0 && roi.height > 0) {
        final roiPaint = Paint()
          ..color = Colors.orange.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = lineStroke * 0.85;

        final roiFillPaint = Paint()
          ..color = Colors.orange.withOpacity(0.08)
          ..style = PaintingStyle.fill;

        canvas.drawRect(roi, roiFillPaint);
        canvas.drawRect(roi, roiPaint);

        _drawCanvasLabel(
          canvas: canvas,
          text: 'ROI',
          position: roi.topLeft + Offset(8 * exportScale, 28 * exportScale),
          color: Colors.orange.shade800,
          exportScale: exportScale,
        );
      }
    }

    if (includeInternalPoint) {
      final point = _boundarySeedPoint;
      if (point != null) {
        final center = point.toOffset();
        final crossPaint = Paint()
          ..color = Colors.pink.shade700
          ..strokeWidth = lineStroke * 0.85
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawCircle(center, 10 * exportScale, crossPaint);
        canvas.drawLine(
          Offset(center.dx - 16 * exportScale, center.dy),
          Offset(center.dx + 16 * exportScale, center.dy),
          crossPaint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - 16 * exportScale),
          Offset(center.dx, center.dy + 16 * exportScale),
          crossPaint,
        );

        _drawCanvasLabel(
          canvas: canvas,
          text: 'İç nokta',
          position: center + Offset(10 * exportScale, -8 * exportScale),
          color: Colors.pink.shade700,
          exportScale: exportScale,
        );
      }
    }

    if (includeCalibration) {
      if (_simpleCalibrationPoints.length == 2) {
        final a = _simpleCalibrationPoints[0].toOffset();
        final b = _simpleCalibrationPoints[1].toOffset();

        canvas.drawLine(a, b, calibrationPaint);
        canvas.drawCircle(a, 7 * exportScale, pointPaint);
        canvas.drawCircle(b, 7 * exportScale, pointPaint);

        _drawCanvasLabel(
          canvas: canvas,
          text: 'Kalibrasyon: ${_referenceLengthMm.toStringAsFixed(2)} mm',
          position: Offset(
            (a.dx + b.dx) / 2,
            (a.dy + b.dy) / 2,
          ),
          color: Colors.blue,
          exportScale: exportScale,
        );
      }

      if (_perspectiveCalibrationPoints.length == 4) {
        for (int i = 0; i < 4; i++) {
          final a = _perspectiveCalibrationPoints[i].toOffset();
          final b = _perspectiveCalibrationPoints[(i + 1) % 4].toOffset();
          canvas.drawLine(a, b, calibrationPaint);
          canvas.drawCircle(a, 7 * exportScale, pointPaint);
        }

        final center = _averageOffset(
          _perspectiveCalibrationPoints
              .map((point) => point.toOffset())
              .toList(),
        );

        _drawCanvasLabel(
          canvas: canvas,
          text: 'Perspektif: ${_calibrationModeLabel(_calibrationMode)}',
          position: center,
          color: Colors.blue,
          exportScale: exportScale,
        );
      }
    }

    if (includeReferenceObjects) {
      for (final reference in _multiReferences) {
        final a = reference.start.toOffset();
        final b = reference.end.toOffset();
        canvas.drawLine(a, b, referencePaint);
        canvas.drawCircle(a, 7 * exportScale, pointPaint);
        canvas.drawCircle(b, 7 * exportScale, pointPaint);

        _drawCanvasLabel(
          canvas: canvas,
          text: '${reference.label}: ${_formatMm(reference.referenceLengthMm)}',
          position: Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
          color: Colors.deepPurple,
          exportScale: exportScale,
        );
      }
    }

    if (includeMeasurements) {
      for (final measurement in _measurements) {
        final a = measurement.startImage.toOffset();
        final b = measurement.endImage.toOffset();

        canvas.drawLine(a, b, measurementPaint);
        canvas.drawCircle(a, 7 * exportScale, pointPaint);
        canvas.drawCircle(b, 7 * exportScale, pointPaint);

        final midpoint = Offset(
          (a.dx + b.dx) / 2,
          (a.dy + b.dy) / 2,
        );

        _drawCanvasLabel(
          canvas: canvas,
          text: '${measurement.label}: ${_formatMm(measurement.lengthMm)}',
          position: midpoint,
          color: Colors.teal,
          exportScale: exportScale,
        );
      }
    }
  }

  Offset _averageOffset(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;

    double x = 0;
    double y = 0;

    for (final point in points) {
      x += point.dx;
      y += point.dy;
    }

    return Offset(x / points.length, y / points.length);
  }

  void _drawCanvasLabel({
    required Canvas canvas,
    required String text,
    required Offset position,
    required Color color,
    required double exportScale,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 * exportScale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final padding = EdgeInsets.symmetric(
      horizontal: 10 * exportScale,
      vertical: 7 * exportScale,
    );

    final rect = Rect.fromLTWH(
      position.dx + 8 * exportScale,
      position.dy - textPainter.height - 8 * exportScale,
      textPainter.width + padding.horizontal,
      textPainter.height + padding.vertical,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(10 * exportScale),
    );

    final backgroundPaint = Paint()..color = color.withOpacity(0.88);
    canvas.drawRRect(rrect, backgroundPaint);

    textPainter.paint(
      canvas,
      Offset(
        rect.left + padding.left,
        rect.top + padding.top,
      ),
    );
  }

  String _buildSvgString({
    bool transparentOverlay = false,
  }) {
    final image = _sourceImage!;
    final buffer = StringBuffer();

    buffer.writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${image.width}" height="${image.height}" '
      'viewBox="0 0 ${image.width} ${image.height}">',
    );

    if (!transparentOverlay) {
      final imageBytes = _sourceImageBytes!;
      final imageBase64 = base64Encode(imageBytes);
      final mimeType = _selectedPhoto?.resolvedMimeType ?? 'image/png';

      buffer.writeln(
        '<image x="0" y="0" width="${image.width}" height="${image.height}" '
        'href="data:$mimeType;base64,$imageBase64" />',
      );
    }

    final boundary = _insoleBoundary;
    if (boundary != null && boundary.points.length >= 3) {
      final polygonPoints = boundary.points
          .map((point) => '${point.x.toStringAsFixed(2)},${point.y.toStringAsFixed(2)}')
          .join(' ');

      buffer.writeln(
        '<polygon points="$polygonPoints" '
        'fill="rgba(0,188,212,0.10)" stroke="#0097A7" '
        'stroke-width="4" stroke-linejoin="round" />',
      );
    }

    if (!transparentOverlay) {
      final roi = _boundaryRoiImageRect;
      if (roi != null && roi.width > 0 && roi.height > 0) {
        buffer.writeln(
          '<rect x="${roi.left.toStringAsFixed(2)}" '
          'y="${roi.top.toStringAsFixed(2)}" '
          'width="${roi.width.toStringAsFixed(2)}" '
          'height="${roi.height.toStringAsFixed(2)}" '
          'fill="rgba(245,124,0,0.08)" stroke="#EF6C00" '
          'stroke-width="4" />',
        );
      }

      final internalPoint = _boundarySeedPoint;
      if (internalPoint != null) {
        buffer.writeln(
          '<circle cx="${internalPoint.x}" cy="${internalPoint.y}" '
          'r="12" fill="none" stroke="#AD1457" stroke-width="4" />',
        );
        buffer.writeln(
          '<line x1="${internalPoint.x - 18}" y1="${internalPoint.y}" '
          'x2="${internalPoint.x + 18}" y2="${internalPoint.y}" '
          'stroke="#AD1457" stroke-width="4" stroke-linecap="round" />',
        );
        buffer.writeln(
          '<line x1="${internalPoint.x}" y1="${internalPoint.y - 18}" '
          'x2="${internalPoint.x}" y2="${internalPoint.y + 18}" '
          'stroke="#AD1457" stroke-width="4" stroke-linecap="round" />',
        );
      }

      if (_simpleCalibrationPoints.length == 2) {
        final a = _simpleCalibrationPoints[0];
        final b = _simpleCalibrationPoints[1];

        buffer.writeln(
          '<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" '
          'stroke="#1565C0" stroke-width="4" stroke-linecap="round" />',
        );

        buffer.writeln(
          '<text x="${(a.x + b.x) / 2 + 8}" y="${(a.y + b.y) / 2 - 8}" '
          'font-size="16" font-weight="700" fill="#1565C0">'
          'Kalibrasyon: ${_referenceLengthMm.toStringAsFixed(2)} mm'
          '</text>',
        );
      }

      if (_perspectiveCalibrationPoints.length == 4) {
        for (int i = 0; i < 4; i++) {
          final a = _perspectiveCalibrationPoints[i];
          final b = _perspectiveCalibrationPoints[(i + 1) % 4];

          buffer.writeln(
            '<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" '
            'stroke="#1565C0" stroke-width="4" stroke-linecap="round" />',
          );

          buffer.writeln(
            '<circle cx="${a.x}" cy="${a.y}" r="7" fill="#1565C0" />',
          );
        }
      }

      for (final reference in _multiReferences) {
        final a = reference.start;
        final b = reference.end;
        final midX = (a.x + b.x) / 2;
        final midY = (a.y + b.y) / 2;

        buffer.writeln(
          '<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" '
          'stroke="#5E35B1" stroke-width="4" stroke-linecap="round" />',
        );

        buffer.writeln('<circle cx="${a.x}" cy="${a.y}" r="7" fill="#5E35B1" />');
        buffer.writeln('<circle cx="${b.x}" cy="${b.y}" r="7" fill="#5E35B1" />');

        buffer.writeln(
          '<text x="${midX + 8}" y="${midY - 8}" '
          'font-size="16" font-weight="700" fill="#5E35B1">'
          '${_escapeXml(reference.label)}: ${_formatMm(reference.referenceLengthMm)}'
          '</text>',
        );
      }
    }

    for (final measurement in _measurements) {
      final a = measurement.startImage;
      final b = measurement.endImage;
      final midX = (a.x + b.x) / 2;
      final midY = (a.y + b.y) / 2;

      buffer.writeln(
        '<line x1="${a.x}" y1="${a.y}" x2="${b.x}" y2="${b.y}" '
        'stroke="#00897B" stroke-width="4" stroke-linecap="round" />',
      );

      buffer.writeln('<circle cx="${a.x}" cy="${a.y}" r="7" fill="#00897B" />');
      buffer.writeln('<circle cx="${b.x}" cy="${b.y}" r="7" fill="#00897B" />');

      buffer.writeln(
        '<text x="${midX + 8}" y="${midY - 8}" '
        'font-size="16" font-weight="700" fill="#00897B">'
        '${_escapeXml(measurement.label)}: ${_formatMm(measurement.lengthMm)}'
        '</text>',
      );
    }

    buffer.writeln('</svg>');

    return buffer.toString();
  }

  Future<void> _detectInsoleBoundary({bool showMessages = true}) async {
    final image = _sourceImage;

    if (image == null) {
      if (showMessages) {
        _showMessage('Sınır tespiti için önce referans görsel yüklenmeli.');
      }
      return;
    }

    final roi = _boundaryRoiImageRect;
    if (roi == null || roi.width < 20 || roi.height < 20) {
      if (showMessages) {
        _showMessage(
          'Önce iç tabanı kapsayan, markerları dışarıda bırakan bir ROI alanı seç.',
        );
      }
      return;
    }

    if (_boundarySeedPoint == null) {
      if (showMessages) {
        _showMessage(
          'Önce ROI içindeki iç taban gövdesine bir iç taban içi nokta seç.',
        );
      }
      return;
    }

    if (!roi.contains(_boundarySeedPoint!.toOffset())) {
      if (showMessages) {
        _showMessage(
          'İç taban içi nokta ROI alanının dışında. İç taban üzerinde ve ROI içinde yeni bir nokta seç.',
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isDetectingBoundary = true;
      _statusMessage = showMessages
          ? 'ROI + iç taban içi nokta + slider ayarları ile sınır tespit ediliyor...'
          : 'Slider ayarlarına göre sınır güncelleniyor...';
    });

    try {
      final boundary = await _autoDetectInsoleBoundary(
        image,
        roiImageRect: roi,
        seedPoint: _boundarySeedPoint!,
        sensitivity: _boundarySensitivity,
        shadowTolerance: _boundaryShadowTolerance,
        backgroundSeparation: _boundaryBackgroundSeparation,
        closingStrength: _boundaryClosingStrength,
        smoothingStrength: _boundarySmoothingStrength,
      );

      if (!mounted) return;

      if (boundary == null || boundary.points.length < 8) {
        setState(() {
          _isDetectingBoundary = false;
          _statusMessage = showMessages
              ? null
              : 'Bu slider ayarlarıyla sınır net bulunamadı.';
        });

        if (showMessages) {
          _showMessage(
            'İç taban sınırı net tespit edilemedi. ROI alanını daraltıp iç taban içi noktayı gövdeye yakın seçerek tekrar dene. Gerekirse hassasiyet, zemin ayrımı ve boşluk doldurma sliderlarını değiştir.',
          );
        }
        return;
      }

      setState(() {
        _insoleBoundary = boundary;
        _showInsoleBoundary = true;
        _isDetectingBoundary = false;
        _isSelectingBoundaryRoi = false;
        _isSelectingBoundarySeed = false;
        _boundaryRoiDragStartPoint = null;
        _boundaryRoiDragCurrentPoint = null;
        _statusMessage =
            'İç taban sınırı güncellendi: ${boundary.points.length} nokta.';
      });

      if (showMessages) {
        _showMessage('İç taban sınırı bulundu.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDetectingBoundary = false;
        _statusMessage = showMessages ? null : 'Sınır güncellenemedi.';
      });

      if (showMessages) {
        _showMessage('İç taban sınırı tespit edilemedi: $e');
      }
    }
  }

  void _scheduleBoundaryDetectionPreview() {
    _boundaryDetectionDebounce?.cancel();

    if (_sourceImage == null ||
        _boundaryRoiImageRect == null ||
        _boundarySeedPoint == null) {
      return;
    }

    _boundaryDetectionDebounce = Timer(
      const Duration(milliseconds: 260),
      () {
        if (!mounted) return;
        _detectInsoleBoundary(showMessages: false);
      },
    );
  }

  Future<_InsoleBoundary?> _autoDetectInsoleBoundary(
    ui.Image image, {
    required Rect roiImageRect,
    required _ImagePoint seedPoint,
    required double sensitivity,
    required double shadowTolerance,
    required double backgroundSeparation,
    required int closingStrength,
    required int smoothingStrength,
  }) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) {
      throw Exception('Görsel piksel verisi okunamadı.');
    }

    final data = byteData.buffer.asUint8List();
    final imageWidth = image.width;
    final imageHeight = image.height;

    final maxAnalysisSize = 900;
    final sampleStep =
        math.max(1, (math.max(imageWidth, imageHeight) / maxAnalysisSize).ceil());

    final gridWidth = (imageWidth / sampleStep).floor();
    final gridHeight = (imageHeight / sampleStep).floor();

    if (gridWidth < 20 || gridHeight < 20) {
      throw Exception('Görsel sınır analizi için çok küçük.');
    }

    final normalizedRoi = _normalizeImageRect(roiImageRect, image);
    if (normalizedRoi.width < 20 || normalizedRoi.height < 20) {
      throw Exception('Seçilen ROI alanı sınır analizi için çok küçük.');
    }

    final a4RestrictPolygon =
        _calibrationMode == _CalibrationMode.perspectiveA4 &&
                _perspectiveCalibrationPoints.length == 4
            ? _perspectiveCalibrationPoints
            : null;

    final seedFeature = _sampleAverageFeature(
      data: data,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      center: seedPoint,
      radiusPx: math.max(2, sampleStep * 2),
    );

    final backgroundFeature = _estimateBackgroundFeatureFromRoiBorder(
      data: data,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      roi: normalizedRoi,
      radiusPx: math.max(2, sampleStep),
    );

    final seedThreshold = ui.lerpDouble(0.08, 0.38, sensitivity)!;
    final separationMargin = ui.lerpDouble(0.01, 0.18, backgroundSeparation)!;

    final mask = List<bool>.filled(gridWidth * gridHeight, false);

    for (int gy = 0; gy < gridHeight; gy++) {
      for (int gx = 0; gx < gridWidth; gx++) {
        final px = math.min(imageWidth - 1, gx * sampleStep + sampleStep ~/ 2);
        final py =
            math.min(imageHeight - 1, gy * sampleStep + sampleStep ~/ 2);

        final imagePoint = _ImagePoint(x: px.toDouble(), y: py.toDouble());

        if (!normalizedRoi.contains(imagePoint.toOffset())) {
          continue;
        }

        if (a4RestrictPolygon != null &&
            !_isPointInsidePolygon(imagePoint, a4RestrictPolygon)) {
          continue;
        }

        final feature = _pixelFeaturesAt(
          data: data,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
          x: px,
          y: py,
        );

        final seedDistance = _boundaryFeatureDistance(
          feature,
          seedFeature,
          shadowTolerance: shadowTolerance,
        );

        final backgroundDistance = _boundaryFeatureDistance(
          feature,
          backgroundFeature,
          shadowTolerance: 0.20,
        );

        final isCandidate = seedDistance <= seedThreshold &&
            (backgroundDistance - seedDistance) >= separationMargin;

        if (isCandidate) {
          mask[gy * gridWidth + gx] = true;
        }
      }
    }

    final closedMask = _closeMask(
      mask,
      gridWidth,
      gridHeight,
      iterations: closingStrength.clamp(0, 6).toInt(),
    );

    final component = _componentFromSeedOrLargest(
      mask: closedMask,
      width: gridWidth,
      height: gridHeight,
      sampleStep: sampleStep,
      roiImageRect: normalizedRoi,
      seedPoint: seedPoint,
    );

    if (component.length < 80) return null;

    final boundaryCells = _extractBoundaryCells(
      component,
      gridWidth,
      gridHeight,
    );

    if (boundaryCells.length < 20) return null;

    final points = _boundaryCellsToImagePolygon(
      boundaryCells,
      sampleStep,
      imageWidth,
      imageHeight,
      smoothingStrength: smoothingStrength.clamp(0, 6).toInt(),
    );

    if (points.length < 8) return null;

    final boundary = _InsoleBoundary(
      method: 'roi_internal_point_slider_similarity',
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      roiImageRect: normalizedRoi,
      seedPoint: seedPoint,
      sensitivity: sensitivity,
      shadowTolerance: shadowTolerance,
      backgroundSeparation: backgroundSeparation,
      closingStrength: closingStrength,
      smoothingStrength: smoothingStrength,
      points: points,
      pointsMm: _boundaryPointsInMm(points),
      createdAt: DateTime.now(),
    );

    return boundary;
  }

  Rect _normalizeImageRect(Rect rect, ui.Image image) {
    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    final left = math.min(rect.left, rect.right).clamp(0.0, imageWidth).toDouble();
    final right = math.max(rect.left, rect.right).clamp(0.0, imageWidth).toDouble();
    final top = math.min(rect.top, rect.bottom).clamp(0.0, imageHeight).toDouble();
    final bottom = math.max(rect.top, rect.bottom).clamp(0.0, imageHeight).toDouble();

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Set<int> _componentFromSeedOrLargest({
    required List<bool> mask,
    required int width,
    required int height,
    required int sampleStep,
    required Rect roiImageRect,
    required _ImagePoint? seedPoint,
  }) {
    if (seedPoint != null) {
      final seedIndex = _findNearestCandidateCell(
        mask: mask,
        width: width,
        height: height,
        sampleStep: sampleStep,
        roiImageRect: roiImageRect,
        seedPoint: seedPoint,
      );

      if (seedIndex != null) {
        final seedComponent = _growComponentFromIndex(
          mask: mask,
          width: width,
          height: height,
          startIndex: seedIndex,
        );

        if (seedComponent.isNotEmpty) return seedComponent;
      }
    }

    return _largestRoiComponent(
      mask: mask,
      width: width,
      height: height,
      sampleStep: sampleStep,
      roiImageRect: roiImageRect,
    );
  }

  int? _findNearestCandidateCell({
    required List<bool> mask,
    required int width,
    required int height,
    required int sampleStep,
    required Rect roiImageRect,
    required _ImagePoint seedPoint,
  }) {
    final seedX = (seedPoint.x / sampleStep).round().clamp(0, width - 1).toInt();
    final seedY = (seedPoint.y / sampleStep).round().clamp(0, height - 1).toInt();
    final seedIndex = seedY * width + seedX;

    if (mask[seedIndex]) return seedIndex;

    int? bestIndex;
    double bestDistance = double.infinity;
    final maxRadius = math.max(8, (40 / sampleStep).ceil());

    for (int radius = 1; radius <= maxRadius; radius++) {
      for (int y = seedY - radius; y <= seedY + radius; y++) {
        if (y < 0 || y >= height) continue;

        for (int x = seedX - radius; x <= seedX + radius; x++) {
          if (x < 0 || x >= width) continue;
          if (x != seedX - radius &&
              x != seedX + radius &&
              y != seedY - radius &&
              y != seedY + radius) {
            continue;
          }

          final index = y * width + x;
          if (!mask[index]) continue;

          final imagePoint = _ImagePoint(
            x: math.min((width * sampleStep) - 1, x * sampleStep + sampleStep / 2).toDouble(),
            y: math.min((height * sampleStep) - 1, y * sampleStep + sampleStep / 2).toDouble(),
          );

          if (!roiImageRect.contains(imagePoint.toOffset())) continue;

          final distance = _distancePx(seedPoint, imagePoint);
          if (distance < bestDistance) {
            bestDistance = distance;
            bestIndex = index;
          }
        }
      }

      if (bestIndex != null) return bestIndex;
    }

    return null;
  }

  Set<int> _growComponentFromIndex({
    required List<bool> mask,
    required int width,
    required int height,
    required int startIndex,
  }) {
    if (startIndex < 0 || startIndex >= mask.length) return <int>{};
    if (!mask[startIndex]) return <int>{};

    final visited = <int>{startIndex};
    final queue = <int>[startIndex];

    const neighborOffsets = <List<int>>[
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final cx = current % width;
      final cy = current ~/ width;

      for (final offset in neighborOffsets) {
        final nx = cx + offset[0];
        final ny = cy + offset[1];

        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;

        final nextIndex = ny * width + nx;
        if (!mask[nextIndex] || visited.contains(nextIndex)) continue;

        visited.add(nextIndex);
        queue.add(nextIndex);
      }
    }

    return visited;
  }

  Set<int> _largestRoiComponent({
    required List<bool> mask,
    required int width,
    required int height,
    required int sampleStep,
    required Rect roiImageRect,
  }) {
    final visited = List<bool>.filled(mask.length, false);
    Set<int> best = <int>{};

    const neighborOffsets = <List<int>>[
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final index = y * width + x;
        if (!mask[index] || visited[index]) continue;

        final queue = <int>[index];
        final component = <int>{};
        visited[index] = true;

        while (queue.isNotEmpty) {
          final current = queue.removeLast();
          component.add(current);

          final cx = current % width;
          final cy = current ~/ width;

          for (final offset in neighborOffsets) {
            final nx = cx + offset[0];
            final ny = cy + offset[1];

            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;

            final nextIndex = ny * width + nx;
            if (!mask[nextIndex] || visited[nextIndex]) continue;

            final imagePoint = _ImagePoint(
              x: math.min((width * sampleStep) - 1, nx * sampleStep + sampleStep / 2).toDouble(),
              y: math.min((height * sampleStep) - 1, ny * sampleStep + sampleStep / 2).toDouble(),
            );

            if (!roiImageRect.contains(imagePoint.toOffset())) continue;

            visited[nextIndex] = true;
            queue.add(nextIndex);
          }
        }

        if (component.length > best.length) best = component;
      }
    }

    return best;
  }

  List<bool> _closeMask(
    List<bool> mask,
    int width,
    int height, {
    int iterations = 1,
  }) {
    List<bool> current = List<bool>.from(mask);

    for (int i = 0; i < iterations; i++) {
      final dilated = List<bool>.filled(current.length, false);

      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          bool any = false;

          for (int dy = -1; dy <= 1 && !any; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (current[(y + dy) * width + x + dx]) {
                any = true;
                break;
              }
            }
          }

          dilated[y * width + x] = any;
        }
      }

      current = dilated;
    }

    for (int i = 0; i < iterations; i++) {
      final eroded = List<bool>.filled(current.length, false);

      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          bool all = true;

          for (int dy = -1; dy <= 1 && all; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (!current[(y + dy) * width + x + dx]) {
                all = false;
                break;
              }
            }
          }

          eroded[y * width + x] = all;
        }
      }

      current = eroded;
    }

    return current;
  }

  _BoundaryPixelFeatures _pixelFeaturesAt({
    required Uint8List data,
    required int imageWidth,
    required int imageHeight,
    required int x,
    required int y,
  }) {
    final clampedX = x.clamp(0, imageWidth - 1).toInt();
    final clampedY = y.clamp(0, imageHeight - 1).toInt();

    final offset = (clampedY * imageWidth + clampedX) * 4;
    final r = data[offset].toDouble();
    final g = data[offset + 1].toDouble();
    final b = data[offset + 2].toDouble();

    final sum = math.max(1.0, r + g + b);
    final maxChannel = math.max(r, math.max(g, b));
    final minChannel = math.min(r, math.min(g, b));

    return _BoundaryPixelFeatures(
      nr: r / sum,
      ng: g / sum,
      nb: b / sum,
      luminance: (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0,
      saturation: maxChannel <= 0
          ? 0
          : ((maxChannel - minChannel) / maxChannel).clamp(0.0, 1.0).toDouble(),
    );
  }

  _BoundaryPixelFeatures _sampleAverageFeature({
    required Uint8List data,
    required int imageWidth,
    required int imageHeight,
    required _ImagePoint center,
    required int radiusPx,
  }) {
    final samples = <_BoundaryPixelFeatures>[];

    final cx = center.x.round();
    final cy = center.y.round();

    for (int y = cy - radiusPx; y <= cy + radiusPx; y++) {
      for (int x = cx - radiusPx; x <= cx + radiusPx; x++) {
        if (x < 0 || y < 0 || x >= imageWidth || y >= imageHeight) continue;
        samples.add(
          _pixelFeaturesAt(
            data: data,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            x: x,
            y: y,
          ),
        );
      }
    }

    return _BoundaryPixelFeatures.average(samples);
  }

  _BoundaryPixelFeatures _estimateBackgroundFeatureFromRoiBorder({
    required Uint8List data,
    required int imageWidth,
    required int imageHeight,
    required Rect roi,
    required int radiusPx,
  }) {
    final samplePoints = <_ImagePoint>[];

    final left = roi.left + roi.width * 0.06;
    final right = roi.right - roi.width * 0.06;
    final top = roi.top + roi.height * 0.06;
    final bottom = roi.bottom - roi.height * 0.06;

    for (int i = 0; i < 6; i++) {
      final t = i / 5.0;

      samplePoints.add(_ImagePoint(
        x: ui.lerpDouble(left, right, t)!,
        y: top,
      ));
      samplePoints.add(_ImagePoint(
        x: ui.lerpDouble(left, right, t)!,
        y: bottom,
      ));
      samplePoints.add(_ImagePoint(
        x: left,
        y: ui.lerpDouble(top, bottom, t)!,
      ));
      samplePoints.add(_ImagePoint(
        x: right,
        y: ui.lerpDouble(top, bottom, t)!,
      ));
    }

    final features = samplePoints
        .map(
          (point) => _sampleAverageFeature(
            data: data,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            center: point,
            radiusPx: radiusPx,
          ),
        )
        .toList();

    return _BoundaryPixelFeatures.average(features);
  }

  double _boundaryFeatureDistance(
    _BoundaryPixelFeatures a,
    _BoundaryPixelFeatures b, {
    required double shadowTolerance,
  }) {
    final chromaDistance = math.sqrt(
      math.pow(a.nr - b.nr, 2) +
          math.pow(a.ng - b.ng, 2) +
          math.pow(a.nb - b.nb, 2),
    ) / 1.7320508075688772;

    final saturationDistance = (a.saturation - b.saturation).abs();
    final luminanceDistance = (a.luminance - b.luminance).abs();

    final luminanceWeight =
        ui.lerpDouble(0.20, 0.06, shadowTolerance.clamp(0.0, 1.0).toDouble())!;

    return (chromaDistance * 0.72) +
        (saturationDistance * 0.18) +
        (luminanceDistance * luminanceWeight);
  }

  Set<int> _largestInteriorComponent(
    List<bool> mask,
    int width,
    int height,
    int sampleStep,
    int imageWidth,
    int imageHeight,
  ) {
    final visited = List<bool>.filled(mask.length, false);
    Set<int> best = <int>{};

    const neighborOffsets = <List<int>>[
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        final index = y * width + x;

        if (!mask[index] || visited[index]) continue;

        final queue = <int>[index];
        final component = <int>{};
        visited[index] = true;

        bool touchesGridEdge = false;

        while (queue.isNotEmpty) {
          final current = queue.removeLast();
          component.add(current);

          final cx = current % width;
          final cy = current ~/ width;

          if (cx <= 1 ||
              cy <= 1 ||
              cx >= width - 2 ||
              cy >= height - 2) {
            touchesGridEdge = true;
          }

          for (final offset in neighborOffsets) {
            final nx = cx + offset[0];
            final ny = cy + offset[1];

            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;

            final nextIndex = ny * width + nx;
            if (!mask[nextIndex] || visited[nextIndex]) continue;

            visited[nextIndex] = true;
            queue.add(nextIndex);
          }
        }

        if (touchesGridEdge) continue;
        if (component.length > best.length) best = component;
      }
    }

    return best;
  }

  List<int> _extractBoundaryCells(
    Set<int> component,
    int width,
    int height,
  ) {
    final boundary = <int>[];

    for (final index in component) {
      final x = index % width;
      final y = index ~/ width;

      final isBoundary =
          x == 0 ||
          y == 0 ||
          x == width - 1 ||
          y == height - 1 ||
          !component.contains(index - 1) ||
          !component.contains(index + 1) ||
          !component.contains(index - width) ||
          !component.contains(index + width);

      if (isBoundary) boundary.add(index);
    }

    return boundary;
  }

  List<_ImagePoint> _boundaryCellsToImagePolygon(
    List<int> boundaryCells,
    int sampleStep,
    int imageWidth,
    int imageHeight, {
    int smoothingStrength = 1,
  }) {
    double centerX = 0;
    double centerY = 0;

    final rawPoints = boundaryCells.map((index) {
      final gx = index % (imageWidth / sampleStep).floor();
      final gy = index ~/ (imageWidth / sampleStep).floor();

      final point = _ImagePoint(
        x: math
            .min(imageWidth - 1, gx * sampleStep + sampleStep / 2)
            .toDouble(),
        y: math
            .min(imageHeight - 1, gy * sampleStep + sampleStep / 2)
            .toDouble(),
      );

      centerX += point.x;
      centerY += point.y;

      return point;
    }).toList();

    centerX /= rawPoints.length;
    centerY /= rawPoints.length;

    const binCount = 180;
    final radialPoints = List<_ImagePoint?>.filled(binCount, null);
    final radialDistances = List<double>.filled(binCount, -1);

    for (final point in rawPoints) {
      final angle = math.atan2(point.y - centerY, point.x - centerX);
      final normalizedAngle = angle < 0 ? angle + math.pi * 2 : angle;
      final bin = ((normalizedAngle / (math.pi * 2)) * binCount)
          .floor()
          .clamp(0, binCount - 1)
          .toInt();

      final distance = math.sqrt(
        math.pow(point.x - centerX, 2) + math.pow(point.y - centerY, 2),
      );

      if (distance > radialDistances[bin]) {
        radialDistances[bin] = distance;
        radialPoints[bin] = point;
      }
    }

    final polygon = radialPoints.whereType<_ImagePoint>().toList();

    if (polygon.length <= 40) return polygon;

    final targetCount = 90;
    final step = math.max(1, (polygon.length / targetCount).floor());

    final simplified = <_ImagePoint>[];

    for (int i = 0; i < polygon.length; i += step) {
      simplified.add(polygon[i]);
    }

    return _smoothBoundaryPoints(
      simplified,
      iterations: smoothingStrength.clamp(0, 6).toInt(),
    );
  }

  List<_ImagePoint> _smoothBoundaryPoints(
    List<_ImagePoint> points, {
    int iterations = 1,
  }) {
    if (points.length < 8 || iterations <= 0) return points;

    List<_ImagePoint> currentPoints = List<_ImagePoint>.from(points);

    for (int iteration = 0; iteration < iterations; iteration++) {
      final smoothed = <_ImagePoint>[];

      for (int i = 0; i < currentPoints.length; i++) {
        final prev = currentPoints[(i - 1 + currentPoints.length) % currentPoints.length];
        final current = currentPoints[i];
        final next = currentPoints[(i + 1) % currentPoints.length];

        smoothed.add(
          _ImagePoint(
            x: (prev.x + current.x * 2 + next.x) / 4,
            y: (prev.y + current.y * 2 + next.y) / 4,
          ),
        );
      }

      currentPoints = smoothed;
    }

    return currentPoints;
  }

  List<_ImagePoint>? _boundaryPointsInMm(List<_ImagePoint> points) {
    final homography = _homographyImageToMm;
    if (homography == null) return null;

    final mmPoints = <_ImagePoint>[];

    for (final point in points) {
      final transformed = _applyHomography(point, homography);
      if (transformed == null) return null;
      mmPoints.add(transformed);
    }

    return mmPoints;
  }

  bool _isPointInsidePolygon(
    _ImagePoint point,
    List<_ImagePoint> polygon,
  ) {
    if (polygon.length < 3) return false;

    bool inside = false;

    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].x;
      final yi = polygon[i].y;
      final xj = polygon[j].x;
      final yj = polygon[j].y;

      final intersects = ((yi > point.y) != (yj > point.y)) &&
          (point.x <
              (xj - xi) * (point.y - yi) / ((yj - yi).abs() < 1e-9 ? 1e-9 : yj - yi) +
                  xi);

      if (intersects) inside = !inside;
    }

    return inside;
  }

  _ImagePoint? _scenePointToImagePoint(Offset scenePoint, Size canvasSize) {
    final image = _sourceImage;
    if (image == null) return null;

    final imageRect = _imageDrawRect(
      canvasSize,
      image.width / image.height,
    );

    if (!imageRect.contains(scenePoint)) return null;

    return _canvasPointToImagePoint(scenePoint, imageRect, image);
  }

  void _startBoundaryRoiSelection() {
    if (_sourceImage == null) {
      _showMessage('ROI seçmek için önce referans görsel yüklenmeli.');
      return;
    }

    setState(() {
      _isSelectingBoundaryRoi = true;
      _isSelectingBoundarySeed = false;
      _isSelectingBoundaryBackground = false;
      _boundaryRoiDragStartPoint = null;
      _boundaryRoiDragCurrentPoint = null;
      _isDraggingBoundaryRoi = false;
      _suppressNextCanvasTap = false;
      _statusMessage =
          'ROI seçimi aktif: iç tabanı kapsayan ve markerları dışarıda bırakan dikdörtgeni sürükleyerek çiz.';
    });
  }

  void _startBoundarySeedSelection() {
    if (_boundaryRoiImageRect == null) {
      _showMessage('İç taban içi nokta seçmeden önce ROI alanı seç.');
      return;
    }

    setState(() {
      _isSelectingBoundarySeed = true;
      _isSelectingBoundaryRoi = false;
      _isSelectingBoundaryBackground = false;
      _boundaryRoiDragStartPoint = null;
      _boundaryRoiDragCurrentPoint = null;
      _isDraggingBoundaryRoi = false;
      _suppressNextCanvasTap = false;
      _statusMessage =
          'İç taban içi nokta seçimi aktif: ROI içinde iç tabanın gövdesine bir kez tıkla.';
    });
  }

  void _handleBoundaryRoiPointerDown(PointerDownEvent event, Size canvasSize) {
    if (!_isSelectingBoundaryRoi) return;

    final scenePoint = _canvasTransformationController.toScene(
      event.localPosition,
    );
    final imagePoint = _scenePointToImagePoint(scenePoint, canvasSize);

    if (imagePoint == null) return;

    setState(() {
      _isDraggingBoundaryRoi = true;
      _suppressNextCanvasTap = true;
      _boundaryRoiDragStartPoint = imagePoint;
      _boundaryRoiDragCurrentPoint = imagePoint;
      _boundaryRoiImageRect = Rect.fromPoints(
        imagePoint.toOffset(),
        imagePoint.toOffset(),
      );
      _insoleBoundary = null;
    });
  }

  void _handleBoundaryRoiPointerMove(PointerMoveEvent event, Size canvasSize) {
    if (!_isSelectingBoundaryRoi || !_isDraggingBoundaryRoi) return;

    final start = _boundaryRoiDragStartPoint;
    if (start == null) return;

    final scenePoint = _canvasTransformationController.toScene(
      event.localPosition,
    );
    final imagePoint = _scenePointToImagePoint(scenePoint, canvasSize);

    if (imagePoint == null) return;

    final image = _sourceImage;
    if (image == null) return;

    final nextRect = _normalizeImageRect(
      Rect.fromPoints(start.toOffset(), imagePoint.toOffset()),
      image,
    );

    setState(() {
      _suppressNextCanvasTap = true;
      _boundaryRoiDragCurrentPoint = imagePoint;
      _boundaryRoiImageRect = nextRect;
    });
  }

  void _handleBoundaryRoiPointerUp(PointerUpEvent event) {
    if (!_isSelectingBoundaryRoi || !_isDraggingBoundaryRoi) return;

    setState(() {
      _isDraggingBoundaryRoi = false;
      _suppressNextCanvasTap = true;
    });

    _finishBoundaryRoiSelection();
  }

  void _handleBoundaryRoiPointerCancel(PointerCancelEvent event) {
    if (!_isSelectingBoundaryRoi) return;

    setState(() {
      _isDraggingBoundaryRoi = false;
      _suppressNextCanvasTap = true;
    });

    _finishBoundaryRoiSelection();
  }

  void _handleBoundaryRoiPanStart(DragStartDetails details, Size canvasSize) {
    if (!_isSelectingBoundaryRoi) return;

    final scenePoint = _canvasTransformationController.toScene(
      details.localPosition,
    );
    final imagePoint = _scenePointToImagePoint(scenePoint, canvasSize);

    if (imagePoint == null) return;

    setState(() {
      _boundaryRoiDragStartPoint = imagePoint;
      _boundaryRoiDragCurrentPoint = imagePoint;
      _boundaryRoiImageRect = Rect.fromPoints(
        imagePoint.toOffset(),
        imagePoint.toOffset(),
      );
      _insoleBoundary = null;
    });
  }

  void _handleBoundaryRoiPanUpdate(DragUpdateDetails details, Size canvasSize) {
    if (!_isSelectingBoundaryRoi) return;

    final start = _boundaryRoiDragStartPoint;
    if (start == null) return;

    final scenePoint = _canvasTransformationController.toScene(
      details.localPosition,
    );
    final imagePoint = _scenePointToImagePoint(scenePoint, canvasSize);

    if (imagePoint == null) return;

    final image = _sourceImage;
    if (image == null) return;

    final nextRect = _normalizeImageRect(
      Rect.fromPoints(start.toOffset(), imagePoint.toOffset()),
      image,
    );

    setState(() {
      _boundaryRoiDragCurrentPoint = imagePoint;
      _boundaryRoiImageRect = nextRect;
    });
  }

  void _handleBoundaryRoiPanEnd(DragEndDetails details) {
    if (!_isSelectingBoundaryRoi) return;
    _finishBoundaryRoiSelection();
  }

  void _finishBoundaryRoiSelection() {
    if (!_isSelectingBoundaryRoi) return;

    final roi = _boundaryRoiImageRect;

    setState(() {
      _isSelectingBoundaryRoi = false;
      _isDraggingBoundaryRoi = false;
      _boundaryRoiDragStartPoint = null;
      _boundaryRoiDragCurrentPoint = null;

      if (roi == null || roi.width < 20 || roi.height < 20) {
        _boundaryRoiImageRect = null;
        _statusMessage = 'ROI alanı çok küçük olduğu için iptal edildi.';
      } else {
        _boundarySeedPoint = null;
        _boundaryBackgroundPoint = null;
        _insoleBoundary = null;
        _statusMessage =
            'ROI seçildi. Şimdi ROI içinde iç tabanın gövdesine iç taban içi nokta seç.';
      }
    });
  }

  void _setBoundarySeedPoint(_ImagePoint point) {
    final roi = _boundaryRoiImageRect;

    if (roi == null) {
      _showMessage('İç taban içi nokta seçmeden önce ROI alanı seç.');
      return;
    }

    if (!roi.contains(point.toOffset())) {
      _showMessage('İç taban içi nokta ROI alanının içinde olmalı.');
      return;
    }

    setState(() {
      _boundarySeedPoint = point;
      _isSelectingBoundarySeed = false;
      _insoleBoundary = null;
      _statusMessage =
          'İç taban içi nokta seçildi. İlk sınır tahmini hazırlanıyor; sliderları değiştirince çizgi otomatik güncellenir.';
    });

    _scheduleBoundaryDetectionPreview();
  }

  void _clearBoundaryRoiAndSeed() {
    setState(() {
      _boundaryRoiImageRect = null;
      _boundarySeedPoint = null;
      _boundaryBackgroundPoint = null;
      _boundaryRoiDragStartPoint = null;
      _boundaryRoiDragCurrentPoint = null;
      _isDraggingBoundaryRoi = false;
      _suppressNextCanvasTap = false;
      _isSelectingBoundaryRoi = false;
      _isSelectingBoundarySeed = false;
      _isSelectingBoundaryBackground = false;
      _insoleBoundary = null;
      _statusMessage = 'ROI, iç taban içi nokta ve sınır temizlendi.';
    });
  }

  void _clearInsoleBoundary() {
    setState(() {
      _insoleBoundary = null;
      _statusMessage = 'İç taban sınırı temizlendi. ROI ve iç taban içi nokta korunuyor.';
    });
  }


  void _clearCalibration() {
    setState(() {
      _simpleCalibrationPoints = [];
      _perspectiveCalibrationPoints = [];
      _pendingMultiReferencePoints = [];
      _pendingMeasurementPoints = [];
      _homographyImageToMm = null;
      _multiReferences = [];
      _calibrationPixelDistance = null;
      _pixelsPerMm = null;
      _measurements = [];
      _insoleBoundary = null;
      _showInsoleBoundary = true;
      _boundaryRoiImageRect = null;
      _boundarySeedPoint = null;
      _boundaryBackgroundPoint = null;
      _isSelectingBoundaryRoi = false;
      _isSelectingBoundarySeed = false;
      _isSelectingBoundaryBackground = false;
      _boundaryRoiDragStartPoint = null;
      _boundaryRoiDragCurrentPoint = null;
      _toolMode = _AnalysisToolMode.calibration;
      _statusMessage = 'Kalibrasyon, sınır ve ölçümler temizlendi.';
    });
  }

  void _clearMeasurements() {
    setState(() {
      _measurements = [];
      _pendingMeasurementPoints = [];
      _statusMessage = 'Ölçümler temizlendi.';
    });
  }

  void _deleteMeasurement(String id) {
    setState(() {
      _measurements =
          _measurements.where((measurement) => measurement.id != id).toList();
    });
  }

  void _deleteMultiReference(String id) {
    setState(() {
      _multiReferences =
          _multiReferences.where((reference) => reference.id != id).toList();
      _recomputeCalibrationAndMeasurements();
    });
  }

  double _distancePx(_ImagePoint a, _ImagePoint b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;

    return math.sqrt(dx * dx + dy * dy);
  }

  Rect _imageDrawRect(Size canvasSize, double imageRatio) {
    final canvasRatio = canvasSize.width / canvasSize.height;

    double width;
    double height;

    if (canvasRatio > imageRatio) {
      height = canvasSize.height;
      width = height * imageRatio;
    } else {
      width = canvasSize.width;
      height = width / imageRatio;
    }

    return Rect.fromLTWH(
      (canvasSize.width - width) / 2,
      (canvasSize.height - height) / 2,
      width,
      height,
    );
  }

  _ImagePoint _canvasPointToImagePoint(
    Offset canvasPoint,
    Rect imageRect,
    ui.Image image,
  ) {
    final normalizedX =
        ((canvasPoint.dx - imageRect.left) / imageRect.width)
            .clamp(0.0, 1.0)
            .toDouble();

    final normalizedY =
        ((canvasPoint.dy - imageRect.top) / imageRect.height)
            .clamp(0.0, 1.0)
            .toDouble();

    return _ImagePoint(
      x: normalizedX * image.width,
      y: normalizedY * image.height,
    );
  }

  List<double>? _computeHomographyImageToWorld({
    required List<_ImagePoint> imagePoints,
    required List<_ImagePoint> worldPoints,
  }) {
    if (imagePoints.length != 4 || worldPoints.length != 4) return null;

    final matrix = List.generate(8, (_) => List<double>.filled(9, 0));

    for (int i = 0; i < 4; i++) {
      final x = imagePoints[i].x;
      final y = imagePoints[i].y;
      final X = worldPoints[i].x;
      final Y = worldPoints[i].y;

      matrix[2 * i][0] = x;
      matrix[2 * i][1] = y;
      matrix[2 * i][2] = 1;
      matrix[2 * i][3] = 0;
      matrix[2 * i][4] = 0;
      matrix[2 * i][5] = 0;
      matrix[2 * i][6] = -X * x;
      matrix[2 * i][7] = -X * y;
      matrix[2 * i][8] = X;

      matrix[2 * i + 1][0] = 0;
      matrix[2 * i + 1][1] = 0;
      matrix[2 * i + 1][2] = 0;
      matrix[2 * i + 1][3] = x;
      matrix[2 * i + 1][4] = y;
      matrix[2 * i + 1][5] = 1;
      matrix[2 * i + 1][6] = -Y * x;
      matrix[2 * i + 1][7] = -Y * y;
      matrix[2 * i + 1][8] = Y;
    }

    final solution = _solveLinearSystem(matrix);

    if (solution == null || solution.length != 8) return null;

    return [
      solution[0],
      solution[1],
      solution[2],
      solution[3],
      solution[4],
      solution[5],
      solution[6],
      solution[7],
      1,
    ];
  }

  List<double>? _solveLinearSystem(List<List<double>> augmentedMatrix) {
    final n = augmentedMatrix.length;
    final matrix = augmentedMatrix.map((row) => [...row]).toList();

    for (int col = 0; col < n; col++) {
      int pivotRow = col;
      double pivotValue = matrix[col][col].abs();

      for (int row = col + 1; row < n; row++) {
        final value = matrix[row][col].abs();
        if (value > pivotValue) {
          pivotValue = value;
          pivotRow = row;
        }
      }

      if (pivotValue < 1e-12) return null;

      if (pivotRow != col) {
        final temp = matrix[col];
        matrix[col] = matrix[pivotRow];
        matrix[pivotRow] = temp;
      }

      final pivot = matrix[col][col];
      for (int j = col; j <= n; j++) {
        matrix[col][j] /= pivot;
      }

      for (int row = 0; row < n; row++) {
        if (row == col) continue;

        final factor = matrix[row][col];
        if (factor.abs() < 1e-12) continue;

        for (int j = col; j <= n; j++) {
          matrix[row][j] -= factor * matrix[col][j];
        }
      }
    }

    return List<double>.generate(n, (index) => matrix[index][n]);
  }

  _ImagePoint? _applyHomography(_ImagePoint point, List<double> h) {
    if (h.length != 9) return null;

    final x = point.x;
    final y = point.y;
    final denominator = h[6] * x + h[7] * y + h[8];

    if (denominator.abs() < 1e-12) return null;

    final worldX = (h[0] * x + h[1] * y + h[2]) / denominator;
    final worldY = (h[3] * x + h[4] * y + h[5]) / denominator;

    return _ImagePoint(x: worldX, y: worldY);
  }

  String get _calibrationInstruction {
    switch (_calibrationMode) {
      case _CalibrationMode.simpleTwoPoint:
        return 'Bilinen referans uzunluğunun iki ucunu seç. Örn. 25 mm marker kenarı veya 1 TL çapı.';
      case _CalibrationMode.perspectiveA4:
        return 'A4 kâğıdın 4 köşesini sırayla seç: sol üst → sağ üst → sağ alt → sol alt.';
      case _CalibrationMode.perspectiveSquareMarker:
        return '25 mm kare markerın 4 köşesini sırayla seç: sol üst → sağ üst → sağ alt → sol alt.';
      case _CalibrationMode.multiReference:
        return 'Farklı bölgelerde 1 TL veya marker gibi referansların iki ucunu seçerek birden fazla lokal ölçek ekle.';
    }
  }

  String _calibrationModeLabel(_CalibrationMode mode) {
    switch (mode) {
      case _CalibrationMode.simpleTwoPoint:
        return 'Basit 2 Nokta';
      case _CalibrationMode.perspectiveA4:
        return 'A4 Perspektif';
      case _CalibrationMode.perspectiveSquareMarker:
        return 'Kare Marker Perspektif';
      case _CalibrationMode.multiReference:
        return 'Çoklu Manuel Referans';
    }
  }

  String _calibrationDbCode(_CalibrationMode mode) {
    switch (mode) {
      case _CalibrationMode.simpleTwoPoint:
        return 'simple_two_point';
      case _CalibrationMode.perspectiveA4:
        return 'homography_a4';
      case _CalibrationMode.perspectiveSquareMarker:
        return 'homography_square_marker';
      case _CalibrationMode.multiReference:
        return 'multi_reference';
    }
  }

  _CalibrationMode _calibrationModeFromDbCode(String value) {
    switch (value) {
      case 'simple_two_point':
      case 'manual':
        return _CalibrationMode.simpleTwoPoint;
      case 'homography_a4':
      case 'perspective_a4':
        return _CalibrationMode.perspectiveA4;
      case 'homography_square_marker':
      case 'perspective_square_marker':
      case 'aruco_25mm':
        return _CalibrationMode.perspectiveSquareMarker;
      case 'multi_reference':
      case 'coin_1tl':
        return _CalibrationMode.multiReference;
      default:
        return _CalibrationMode.perspectiveA4;
    }
  }

  String _toolModeLabel(_AnalysisToolMode mode) {
    switch (mode) {
      case _AnalysisToolMode.calibration:
        return 'Kalibrasyon';
      case _AnalysisToolMode.measurement:
        return 'Ölçüm';
    }
  }

  String _formatMm(double value) {
    return '${value.toStringAsFixed(2)} mm';
  }

  String _formatPx(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(1)} px';
  }

  String _formatRatio(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(4)} px/mm';
  }

  String _trimDoubleText(double value) {
    final fixed = value.toStringAsFixed(4);
    return fixed
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  String _safeFileName(String value) {
    final normalized = value.trim().isEmpty ? 'order' : value.trim();

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

  String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.operationItem.order;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referans İç Taban Analizi'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          if (_isSaving || _isExporting || _isLoadingImage)
            const LinearProgressIndicator(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1050;

                if (isNarrow) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildLeftPanel(order.orderNo),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 620,
                          child: _buildCanvasPanel(),
                        ),
                        const SizedBox(height: 16),
                        _buildRightPanel(),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLeftPanel(order.orderNo),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _buildCanvasPanel(),
                      ),
                      const SizedBox(width: 18),
                      _buildRightPanel(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(String orderNo) {
    return SizedBox(
      width: 350,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Sipariş Bilgisi',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  _buildKeyValueRow('Sipariş No', orderNo),
                  _buildKeyValueRow(
                    'Kullanıcı',
                    widget.operationItem.patientName,
                  ),
                  _buildKeyValueRow(
                    'Klinik',
                    widget.operationItem.clinicName,
                  ),
                  _buildKeyValueRow(
                    'Uzman',
                    widget.operationItem.expertName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Referans Görsel',
              icon: Icons.image_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_photoRecords.isEmpty)
                    _buildNotice(
                      icon: Icons.warning_amber_outlined,
                      text:
                          'Bu oturum için referans iç taban fotoğrafı bulunamadı.',
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _selectedPhotoIndex,
                      decoration: const InputDecoration(
                        labelText: 'Fotoğraf',
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(_photoRecords.length, (index) {
                        final photo = _photoRecords[index];

                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            photo.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      onChanged: _isLoadingImage
                          ? null
                          : (index) async {
                              if (index == null) return;

                              setState(() {
                                _selectedPhotoIndex = index;
                              });

                              await _loadSelectedPhotoImage(
                                _photoRecords[index],
                              );
                            },
                    ),
                  const SizedBox(height: 10),
                  _buildNotice(
                    icon: Icons.info_outline,
                    text:
                        'En doğru sonuç için A4 veya marker ile perspektif kalibrasyonu kullan. 1 TL / çoklu referans yöntemi lokal ölçek düzeltmesi yapar.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Kalibrasyon',
              icon: Icons.straighten_outlined,
              child: Column(
                children: [
                  DropdownButtonFormField<_CalibrationMode>(
                    value: _calibrationMode,
                    decoration: const InputDecoration(
                      labelText: 'Kalibrasyon yöntemi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _CalibrationMode.perspectiveA4,
                        child: Text('A4 perspektif düzeltme'),
                      ),
                      DropdownMenuItem(
                        value: _CalibrationMode.perspectiveSquareMarker,
                        child: Text('25 mm kare marker perspektif'),
                      ),
                      DropdownMenuItem(
                        value: _CalibrationMode.multiReference,
                        child: Text('Çoklu 1 TL / manuel referans'),
                      ),
                      DropdownMenuItem(
                        value: _CalibrationMode.simpleTwoPoint,
                        child: Text('Basit 2 nokta ölçek'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _changeCalibrationMode(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _referenceLengthController,
                    keyboardType: TextInputType.number,
                    enabled: _calibrationMode != _CalibrationMode.perspectiveA4,
                    decoration: InputDecoration(
                      labelText: _calibrationMode == _CalibrationMode.multiReference
                          ? 'Yeni referans varsayılan uzunluğu (mm)'
                          : 'Referans uzunluğu (mm)',
                      helperText: _calibrationMode == _CalibrationMode.perspectiveA4
                          ? 'A4 ölçüsü 210 × 297 mm olarak kullanılır.'
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: _onReferenceLengthChanged,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          selected:
                              _toolMode == _AnalysisToolMode.calibration,
                          label: const Text('Kalibrasyon'),
                          avatar: const Icon(Icons.tune, size: 18),
                          onSelected: (_) {
                            setState(() {
                              _toolMode = _AnalysisToolMode.calibration;
                              _statusMessage = _calibrationInstruction;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          selected:
                              _toolMode == _AnalysisToolMode.measurement,
                          label: const Text('Ölçüm'),
                          avatar: const Icon(Icons.linear_scale, size: 18),
                          onSelected: _hasCalibration
                              ? (_) {
                                  setState(() {
                                    _toolMode = _AnalysisToolMode.measurement;
                                    _statusMessage =
                                        'Ölçüm için iki nokta seç.';
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildKeyValueRow('Mod', _toolModeLabel(_toolMode)),
                  _buildKeyValueRow(
                    'Kalibrasyon noktası',
                    '$_currentCalibrationPointCount / $_requiredCalibrationPointCount',
                  ),
                  _buildKeyValueRow(
                    'Referans piksel',
                    _formatPx(_calibrationPixelDistance),
                  ),
                  _buildKeyValueRow('Ortalama ölçek', _formatRatio(_pixelsPerMm)),
                  _buildKeyValueRow(
                    'Perspektif matrisi',
                    _homographyImageToMm == null ? '—' : 'Hazır',
                  ),
                  const SizedBox(height: 10),
                  _buildNotice(
                    icon: Icons.touch_app_outlined,
                    text: _calibrationInstruction,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearCalibration,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Kalibrasyonu Temizle'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'İç Taban Sınırı',
              icon: Icons.gesture_outlined,
              child: Column(
                children: [
                  _buildNotice(
                    icon: Icons.select_all_outlined,
                    text:
                        'Önce markerları dışarıda bırakan bir ROI seç. Ardından ROI içinde iç tabanın gövdesine bir iç taban içi nokta koy. Sliderları değiştirdikçe sınır otomatik güncellenir.',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDetectingBoundary
                              ? null
                              : _startBoundaryRoiSelection,
                          icon: const Icon(Icons.crop_free_outlined),
                          label: Text(
                            _boundaryRoiImageRect == null
                                ? 'ROI Seç'
                                : 'ROI Yenile',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDetectingBoundary ||
                                  _boundaryRoiImageRect == null
                              ? null
                              : _startBoundarySeedSelection,
                          icon: const Icon(Icons.my_location_outlined),
                          label: Text(
                            _boundarySeedPoint == null
                                ? 'İç Nokta Seç'
                                : 'İç Nokta Yenile',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildKeyValueRow(
                    'ROI',
                    _boundaryRoiImageRect == null
                        ? '—'
                        : '${_boundaryRoiImageRect!.width.toStringAsFixed(0)} × ${_boundaryRoiImageRect!.height.toStringAsFixed(0)} px',
                  ),
                  _buildKeyValueRow(
                    'İç taban içi nokta',
                    _boundarySeedPoint == null
                        ? '—'
                        : 'x:${_boundarySeedPoint!.x.toStringAsFixed(0)}, y:${_boundarySeedPoint!.y.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  _buildBoundarySlider(
                    title: 'Sınır hassasiyeti',
                    subtitle:
                        'Yüksek değer iç tabana benzer daha fazla pikseli dahil eder. Çok yüksek değer gölgeyi de içeri alabilir.',
                    value: _boundarySensitivity,
                    valueText: _levelText(_boundarySensitivity),
                    onChanged: (value) {
                      setState(() {
                        _boundarySensitivity = value;
                      });
                      _scheduleBoundaryDetectionPreview();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildBoundarySlider(
                    title: 'Gölge toleransı',
                    subtitle:
                        'Yüksek değer parlaklık farklarını daha fazla yok sayar. Gölgeli fotoğraflarda yükseltmek işe yarar.',
                    value: _boundaryShadowTolerance,
                    valueText: _levelText(_boundaryShadowTolerance),
                    onChanged: (value) {
                      setState(() {
                        _boundaryShadowTolerance = value;
                      });
                      _scheduleBoundaryDetectionPreview();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildBoundarySlider(
                    title: 'Zemin ayrımı',
                    subtitle:
                        'Yüksek değer A4/arka planı daha agresif dışarıda bırakır. Gölge sınıra dahil oluyorsa yükselt.',
                    value: _boundaryBackgroundSeparation,
                    valueText: _levelText(_boundaryBackgroundSeparation),
                    onChanged: (value) {
                      setState(() {
                        _boundaryBackgroundSeparation = value;
                      });
                      _scheduleBoundaryDetectionPreview();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildBoundarySlider(
                    title: 'Boşluk doldurma',
                    subtitle:
                        'Kopuk sınırları birleştirir. Çok yüksek değer yakın gölgeleri veya lekeleri de birleştirebilir.',
                    value: _boundaryClosingStrength.toDouble(),
                    min: 0,
                    max: 6,
                    divisions: 6,
                    valueText: _strengthText(_boundaryClosingStrength),
                    onChanged: (value) {
                      setState(() {
                        _boundaryClosingStrength = value.round();
                      });
                      _scheduleBoundaryDetectionPreview();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildBoundarySlider(
                    title: 'Kontur yumuşatma',
                    subtitle:
                        'Çizgiyi daha akıcı yapar. Çok yüksek değer küçük gerçek detayları sadeleştirebilir.',
                    value: _boundarySmoothingStrength.toDouble(),
                    min: 0,
                    max: 6,
                    divisions: 6,
                    valueText: _strengthText(_boundarySmoothingStrength),
                    onChanged: (value) {
                      setState(() {
                        _boundarySmoothingStrength = value.round();
                      });
                      _scheduleBoundaryDetectionPreview();
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isDetectingBoundary
                          ? null
                          : () => _detectInsoleBoundary(),
                      icon: _isDetectingBoundary
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_fix_high_outlined),
                      label: const Text('Sınırı Bul / Güncelle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade700,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    value: _showInsoleBoundary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sınırı göster'),
                    subtitle: Text(
                      _insoleBoundary == null
                          ? 'Henüz sınır bulunmadı.'
                          : '${_insoleBoundary!.points.length} nokta ile çiziliyor.',
                    ),
                    onChanged: _insoleBoundary == null
                        ? null
                        : (value) {
                            setState(() => _showInsoleBoundary = value);
                          },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _insoleBoundary == null
                              ? null
                              : _clearInsoleBoundary,
                          icon: const Icon(Icons.layers_clear_outlined),
                          label: const Text('Sınırı Temizle'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _boundaryRoiImageRect == null &&
                                  _boundarySeedPoint == null
                              ? null
                              : _clearBoundaryRoiAndSeed,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: const Text('ROI/Nokta Temizle'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Kaydet / Dışa Aktar',
              icon: Icons.save_alt_outlined,
              child: Column(
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Analiz notu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveAnalysis,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_done_outlined),
                      label: const Text('Order’a Kaydet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Tam görsel',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isExporting ? null : _exportFullAnnotatedPng,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('PNG'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting ? null : _exportFullSvg,
                          icon: const Icon(Icons.code_outlined),
                          label: const Text('SVG'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Şeffaf overlay',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting
                              ? null
                              : _exportTransparentOverlayPng,
                          icon: const Icon(Icons.layers_outlined),
                          label: const Text('PNG'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting
                              ? null
                              : _exportTransparentOverlaySvg,
                          icon: const Icon(Icons.polyline_outlined),
                          label: const Text('SVG'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Görsel Üzerinde Ölçüm',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_statusMessage != null)
              Flexible(
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
              ),
            const SizedBox(width: 10),
            _buildOverlayVisibilityControls(),
            const SizedBox(width: 8),
            _buildZoomIndicator(),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  )
                : _sourceImage == null
                    ? Center(
                        child: Text(
                          _isLoadingImage
                              ? 'Görsel yükleniyor...'
                              : 'Referans görsel bekleniyor',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final canvasSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );

                            return Listener(
                              onPointerSignal: _handleCanvasPointerSignal,
                              onPointerDown: _isSelectingBoundaryRoi
                                  ? (event) => _handleBoundaryRoiPointerDown(
                                        event,
                                        canvasSize,
                                      )
                                  : null,
                              onPointerMove: _isSelectingBoundaryRoi
                                  ? (event) => _handleBoundaryRoiPointerMove(
                                        event,
                                        canvasSize,
                                      )
                                  : null,
                              onPointerUp: _isSelectingBoundaryRoi
                                  ? _handleBoundaryRoiPointerUp
                                  : null,
                              onPointerCancel: _isSelectingBoundaryRoi
                                  ? _handleBoundaryRoiPointerCancel
                                  : null,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: (details) {
                                  if (_suppressNextCanvasTap) {
                                    _suppressNextCanvasTap = false;
                                    return;
                                  }

                                  if (_isSelectingBoundaryRoi) return;

                                  final scenePoint =
                                      _canvasTransformationController.toScene(
                                    details.localPosition,
                                  );

                                  _handleImageTap(
                                    scenePoint,
                                    canvasSize,
                                  );
                                },
                                child: ClipRect(
                                  child: InteractiveViewer(
                                    transformationController:
                                        _canvasTransformationController,
                                    minScale: _minCanvasScale,
                                    maxScale: _maxCanvasScale,
                                    boundaryMargin: const EdgeInsets.all(5000),
                                    panEnabled: !_isSelectingBoundaryRoi,
                                    scaleEnabled: !_isSelectingBoundaryRoi,
                                    child: SizedBox(
                                      width: canvasSize.width,
                                      height: canvasSize.height,
                                      child: CustomPaint(
                                        painter: _ReferenceInsolePainter(
                                          image: _sourceImage!,
                                          calibrationMode: _calibrationMode,
                                          toolMode: _toolMode,
                                          simpleCalibrationPoints:
                                              _simpleCalibrationPoints,
                                          perspectiveCalibrationPoints:
                                              _perspectiveCalibrationPoints,
                                          multiReferences: _multiReferences,
                                          pendingMultiReferencePoints:
                                              _pendingMultiReferencePoints,
                                          measurements: _measurements,
                                          pendingMeasurementPoints:
                                              _pendingMeasurementPoints,
                                          insoleBoundary: _showInsoleBoundary
                                              ? _insoleBoundary
                                              : null,
                                          boundaryRoiImageRect:
                                              _boundaryRoiImageRect,
                                          boundarySeedPoint:
                                              _boundarySeedPoint,
                                          boundaryBackgroundPoint: null,
                                          isSelectingBoundaryRoi:
                                              _isSelectingBoundaryRoi,
                                          isSelectingBoundarySeed:
                                              _isSelectingBoundarySeed,
                                          isSelectingBoundaryBackground: false,
                                          boundaryRoiDragStartPoint:
                                              _boundaryRoiDragStartPoint,
                                          boundaryRoiDragCurrentPoint:
                                              _boundaryRoiDragCurrentPoint,
                                          referenceLengthMm: _referenceLengthMm,
                                          showCalibrationOverlay:
                                              _showCalibrationOverlay,
                                          showBoundaryRoiOverlay:
                                              _showRoiOverlay,
                                          showInternalPointOverlay:
                                              _showInternalPointOverlay,
                                          showMeasurementOverlay:
                                              _showMeasurementOverlay,
                                        ),
                                        size: canvasSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return SizedBox(
      width: 370,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Ölçüm Listesi',
              icon: Icons.format_list_numbered_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_measurements.isEmpty)
                    _buildNotice(
                      icon: Icons.touch_app_outlined,
                      text:
                          'Ölçüm moduna geçip görsel üzerinde iki nokta seçerek ölçüm ekleyebilirsin.',
                    )
                  else
                    ..._measurements.map(_buildMeasurementTile),
                  if (_measurements.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _clearMeasurements,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Tüm Ölçümleri Temizle'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_calibrationMode == _CalibrationMode.multiReference) ...[
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Lokal Referanslar',
                icon: Icons.adjust_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_multiReferences.isEmpty)
                      _buildNotice(
                        icon: Icons.add_location_alt_outlined,
                        text:
                            'Farklı bölgelerdeki 1 TL veya marker referanslarını ekle. Ölçüm, seçilen noktaya yakın referanslara göre ağırlıklandırılır.',
                      )
                    else
                      ..._multiReferences.map(_buildMultiReferenceTile),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'İç Taban Sınırı',
              icon: Icons.polyline_outlined,
              child: _insoleBoundary == null
                  ? _buildNotice(
                      icon: Icons.gesture_outlined,
                      text:
                          'Sol panelden otomatik sınır tespiti yapıldığında sınır bilgisi burada özetlenir.',
                    )
                  : Column(
                      children: [
                        _buildKeyValueRow(
                          'Yöntem',
                          _insoleBoundary!.method,
                        ),
                        _buildKeyValueRow(
                          'Nokta sayısı',
                          _insoleBoundary!.points.length.toString(),
                        ),
                        _buildKeyValueRow(
                          'MM koordinat',
                          _insoleBoundary!.pointsMm == null
                              ? 'Yok'
                              : 'Hazır',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Perspektif / Ölçüm Mantığı',
              icon: Icons.science_outlined,
              child: _buildNotice(
                icon: Icons.functions_outlined,
                text:
                    'A4 veya kare marker modunda 4 köşeden homografi matrisi hesaplanır. Tıklanan noktalar gerçek mm düzlemine dönüştürülür ve mesafe bu düzlemde hesaplanır. Çoklu referansta ise ölçümün orta noktasına en yakın referansların px/mm oranı ağırlıklı kullanılır.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementTile(_InsoleMeasurement measurement) {
    final methodLabel = _calibrationModeLabel(
      _calibrationModeFromDbCode(measurement.calibrationMethod),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.linear_scale, color: Colors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  measurement.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMm(measurement.lengthMm),
                  style: TextStyle(
                    color: Colors.teal.shade800,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Piksel: ${measurement.pixelDistance.toStringAsFixed(1)} px • $methodLabel',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
                if (measurement.startMm != null &&
                    measurement.endMm != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Başlangıç: ${measurement.startMm!.x.toStringAsFixed(1)}, ${measurement.startMm!.y.toStringAsFixed(1)} mm',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Bitiş: ${measurement.endMm!.x.toStringAsFixed(1)}, ${measurement.endMm!.y.toStringAsFixed(1)} mm',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
                if (measurement.localPixelsPerMm != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Lokal ölçek: ${measurement.localPixelsPerMm!.toStringAsFixed(4)} px/mm',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sil',
            onPressed: () => _deleteMeasurement(measurement.id),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiReferenceTile(_LocalReferenceScale reference) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.adjust_outlined, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatMm(reference.referenceLengthMm)} • ${reference.pixelsPerMm.toStringAsFixed(4)} px/mm',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sil',
            onPressed: () => _deleteMultiReference(reference.id),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 7,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.orange.shade800,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.orange.shade900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundarySlider({
    required String title,
    required String subtitle,
    required double value,
    required String valueText,
    required ValueChanged<double> onChanged,
    double min = 0,
    double max = 1,
    int? divisions = 100,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                valueText,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  String _levelText(double value) {
    if (value < 0.17) return 'Çok düşük';
    if (value < 0.34) return 'Düşük';
    if (value < 0.50) return 'Orta düşük';
    if (value < 0.67) return 'Orta';
    if (value < 0.84) return 'Yüksek';
    return 'Çok yüksek';
  }

  String _strengthText(int value) {
    switch (value) {
      case 0:
        return 'Kapalı';
      case 1:
        return 'Çok düşük';
      case 2:
        return 'Düşük';
      case 3:
        return 'Orta';
      case 4:
        return 'Yüksek';
      case 5:
        return 'Çok yüksek';
      case 6:
        return 'Maksimum';
      default:
        return value.toString();
    }
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return DateTime.tryParse(text);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);

    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) return value;

    if (value is String && value.trim().isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded;
    }

    return <dynamic>[];
  }

  static List<double>? _asDoubleList(dynamic value) {
    final list = _asList(value);
    if (list.isEmpty) return null;

    final result = list.map(_asDouble).whereType<double>().toList();

    return result.isEmpty ? null : result;
  }

  static _ImagePoint? _pointFromDynamic(dynamic value) {
    final map = _asMap(value);
    final x = _asDouble(map['x']);
    final y = _asDouble(map['y']);

    if (x == null || y == null) return null;

    return _ImagePoint(x: x, y: y);
  }

  static _LocalReferenceScale? _localReferenceFromDynamic(dynamic value) {
    final map = _asMap(value);

    final start = _pointFromDynamic(map['start']);
    final end = _pointFromDynamic(map['end']);
    final referenceLengthMm = _asDouble(map['referenceLengthMm']);
    final pixelDistance = _asDouble(map['pixelDistance']);
    final pixelsPerMm = _asDouble(map['pixelsPerMm']);

    if (start == null ||
        end == null ||
        referenceLengthMm == null ||
        pixelDistance == null ||
        pixelsPerMm == null) {
      return null;
    }

    return _LocalReferenceScale(
      id: (map['id'] ?? 'r_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      label: (map['label'] ?? 'Referans').toString(),
      start: start,
      end: end,
      referenceLengthMm: referenceLengthMm,
      pixelDistance: pixelDistance,
      pixelsPerMm: pixelsPerMm,
      createdAt: _asDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }


  static Rect? _rectFromDynamic(dynamic value) {
    final map = _asMap(value);
    if (map.isEmpty) return null;

    final x = _asDouble(map['x'] ?? map['left']);
    final y = _asDouble(map['y'] ?? map['top']);
    final width = _asDouble(map['width']);
    final height = _asDouble(map['height']);

    if (x != null && y != null && width != null && height != null) {
      return Rect.fromLTWH(x, y, width, height);
    }

    final left = _asDouble(map['left']);
    final top = _asDouble(map['top']);
    final right = _asDouble(map['right']);
    final bottom = _asDouble(map['bottom']);

    if (left != null && top != null && right != null && bottom != null) {
      return Rect.fromLTRB(left, top, right, bottom);
    }

    return null;
  }

  static _InsoleBoundary? _boundaryFromDynamic(dynamic value) {
    final map = _asMap(value);

    if (map.isEmpty) return null;

    final points = _asList(map['points'] ?? map['pointsImage'])
        .map(_pointFromDynamic)
        .whereType<_ImagePoint>()
        .toList();

    if (points.length < 3) return null;

    final pointsMm = _asList(map['pointsMm'])
        .map(_pointFromDynamic)
        .whereType<_ImagePoint>()
        .toList();

    final roiMap = _asMap(map['roi'] ?? map['roiImageRect']);
    final roi = _rectFromDynamic(roiMap);
    final seed = _pointFromDynamic(map['seedPoint']);

    return _InsoleBoundary(
      method: (map['method'] ?? 'saved_boundary').toString(),
      imageWidth: _asInt(map['imageWidth']) ?? 0,
      imageHeight: _asInt(map['imageHeight']) ?? 0,
      roiImageRect: roi,
      seedPoint: seed,
      sensitivity: _asDouble(map['sensitivity']),
      shadowTolerance: _asDouble(map['shadowTolerance']),
      backgroundSeparation: _asDouble(map['backgroundSeparation']),
      closingStrength: _asInt(map['closingStrength']),
      smoothingStrength: _asInt(map['smoothingStrength']),
      points: points,
      pointsMm: pointsMm.isEmpty ? null : pointsMm,
      createdAt: _asDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }


  static _InsoleMeasurement? _measurementFromDynamic(dynamic value) {
    final map = _asMap(value);

    final startImage =
        _pointFromDynamic(map['startImage'] ?? map['start'] ?? map['startPoint']);
    final endImage =
        _pointFromDynamic(map['endImage'] ?? map['end'] ?? map['endPoint']);

    final startMm = _pointFromDynamic(map['startMm']);
    final endMm = _pointFromDynamic(map['endMm']);

    final pixelDistance = _asDouble(map['pixelDistance']);
    final lengthMm = _asDouble(map['lengthMm']);
    final localPixelsPerMm = _asDouble(map['localPixelsPerMm']);

    if (startImage == null ||
        endImage == null ||
        pixelDistance == null ||
        lengthMm == null) {
      return null;
    }

    return _InsoleMeasurement(
      id: (map['id'] ?? 'm_${DateTime.now().microsecondsSinceEpoch}')
          .toString(),
      label: (map['label'] ?? 'Ölçüm').toString(),
      startImage: startImage,
      endImage: endImage,
      startMm: startMm,
      endMm: endMm,
      pixelDistance: pixelDistance,
      lengthMm: lengthMm,
      localPixelsPerMm: localPixelsPerMm,
      calibrationMethod: (map['calibrationMethod'] ?? 'simple_two_point')
          .toString(),
      createdAt: _asDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }
}

class _ReferenceInsolePainter extends CustomPainter {
  final ui.Image image;
  final _CalibrationMode calibrationMode;
  final _AnalysisToolMode toolMode;
  final List<_ImagePoint> simpleCalibrationPoints;
  final List<_ImagePoint> perspectiveCalibrationPoints;
  final List<_LocalReferenceScale> multiReferences;
  final List<_ImagePoint> pendingMultiReferencePoints;
  final List<_InsoleMeasurement> measurements;
  final List<_ImagePoint> pendingMeasurementPoints;
  final _InsoleBoundary? insoleBoundary;
  final Rect? boundaryRoiImageRect;
  final _ImagePoint? boundarySeedPoint;
  final _ImagePoint? boundaryBackgroundPoint;
  final bool isSelectingBoundaryRoi;
  final bool isSelectingBoundarySeed;
  final bool isSelectingBoundaryBackground;
  final _ImagePoint? boundaryRoiDragStartPoint;
  final _ImagePoint? boundaryRoiDragCurrentPoint;
  final double referenceLengthMm;
  final bool showCalibrationOverlay;
  final bool showBoundaryRoiOverlay;
  final bool showInternalPointOverlay;
  final bool showMeasurementOverlay;

  const _ReferenceInsolePainter({
    required this.image,
    required this.calibrationMode,
    required this.toolMode,
    required this.simpleCalibrationPoints,
    required this.perspectiveCalibrationPoints,
    required this.multiReferences,
    required this.pendingMultiReferencePoints,
    required this.measurements,
    required this.pendingMeasurementPoints,
    required this.insoleBoundary,
    required this.boundaryRoiImageRect,
    required this.boundarySeedPoint,
    required this.boundaryBackgroundPoint,
    required this.isSelectingBoundaryRoi,
    required this.isSelectingBoundarySeed,
    required this.isSelectingBoundaryBackground,
    required this.boundaryRoiDragStartPoint,
    required this.boundaryRoiDragCurrentPoint,
    required this.referenceLengthMm,
    required this.showCalibrationOverlay,
    required this.showBoundaryRoiOverlay,
    required this.showInternalPointOverlay,
    required this.showMeasurementOverlay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageRatio = image.width / image.height;
    final imageRect = _imageDrawRect(size, imageRatio);

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      imageRect,
      Paint(),
    );

    final calibrationPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final measurementPaint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final pendingPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final referencePaint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    _drawInsoleBoundary(canvas, imageRect);

    if (showBoundaryRoiOverlay || showInternalPointOverlay) {
      _drawBoundaryRoiAndSeed(canvas, imageRect);
    }

    if (showCalibrationOverlay) {
      _drawSimpleCalibration(canvas, imageRect, calibrationPaint);
      _drawPerspectiveCalibration(canvas, imageRect, calibrationPaint);
      _drawMultiReferences(canvas, imageRect, referencePaint);
      _drawPendingReferences(canvas, imageRect, pendingPaint);
    }

    if (showMeasurementOverlay) {
      _drawMeasurements(canvas, imageRect, measurementPaint);
      _drawPendingMeasurements(canvas, imageRect, pendingPaint);
    }

    _drawTopBadge(
      canvas: canvas,
      text: _modeInstructionText,
      rect: imageRect,
    );
  }

  void _drawBoundaryRoiAndSeed(Canvas canvas, Rect imageRect) {
    final activeRoi = _activeBoundaryRoiRect();

    if (showBoundaryRoiOverlay &&
        activeRoi != null &&
        activeRoi.width > 0 &&
        activeRoi.height > 0) {
      final rect = _imageRectToCanvasRect(activeRoi, imageRect);
      final fillPaint = Paint()
        ..color = Colors.orange.withOpacity(isSelectingBoundaryRoi ? 0.14 : 0.08)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = Colors.orange.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelectingBoundaryRoi ? 3 : 2;

      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);

      _drawLabel(
        canvas: canvas,
        text: isSelectingBoundaryRoi ? 'ROI seçiliyor' : 'ROI',
        position: rect.topLeft + const Offset(8, 24),
        color: Colors.orange.shade800,
      );
    }

    final seed = boundarySeedPoint;
    if (showInternalPointOverlay && seed != null) {
      final point = _imagePointToCanvasPoint(seed, imageRect);
      _drawCrosshair(canvas, point, Colors.pink.shade700);
      _drawLabel(
        canvas: canvas,
        text: isSelectingBoundarySeed ? 'İç nokta seçiliyor' : 'İç nokta',
        position: point + const Offset(10, -10),
        color: Colors.pink.shade700,
      );
    }

    final background = boundaryBackgroundPoint;
    if (background != null) {
      final point = _imagePointToCanvasPoint(background, imageRect);
      _drawCrosshair(canvas, point, Colors.amber.shade800);
      _drawLabel(
        canvas: canvas,
        text: isSelectingBoundaryBackground
            ? 'Zemin seçiliyor'
            : 'Zemin/Gölge',
        position: point + const Offset(10, 18),
        color: Colors.amber.shade800,
      );
    }
  }


  Rect? _activeBoundaryRoiRect() {
    if (isSelectingBoundaryRoi &&
        boundaryRoiDragStartPoint != null &&
        boundaryRoiDragCurrentPoint != null) {
      return Rect.fromPoints(
        boundaryRoiDragStartPoint!.toOffset(),
        boundaryRoiDragCurrentPoint!.toOffset(),
      );
    }

    return boundaryRoiImageRect;
  }

  Rect _imageRectToCanvasRect(Rect rect, Rect imageRect) {
    final topLeft = _imagePointToCanvasPoint(
      _ImagePoint(x: rect.left, y: rect.top),
      imageRect,
    );
    final bottomRight = _imagePointToCanvasPoint(
      _ImagePoint(x: rect.right, y: rect.bottom),
      imageRect,
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  void _drawCrosshair(Canvas canvas, Offset point, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(point, 8, paint..style = PaintingStyle.stroke);
    canvas.drawLine(
      Offset(point.dx - 13, point.dy),
      Offset(point.dx + 13, point.dy),
      paint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(point.dx, point.dy - 13),
      Offset(point.dx, point.dy + 13),
      paint..style = PaintingStyle.stroke,
    );
  }

  void _drawInsoleBoundary(Canvas canvas, Rect imageRect) {
    final boundary = insoleBoundary;

    if (boundary == null || boundary.points.length < 3) return;

    final points = boundary.points
        .map((point) => _imagePointToCanvasPoint(point, imageRect))
        .toList();

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.cyan.withOpacity(0.10)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.cyan.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawSimpleCalibration(
    Canvas canvas,
    Rect imageRect,
    Paint paint,
  ) {
    if (simpleCalibrationPoints.isEmpty) return;

    for (final point in simpleCalibrationPoints) {
      _drawPoint(
        canvas,
        _imagePointToCanvasPoint(point, imageRect),
        Colors.blue,
      );
    }

    if (simpleCalibrationPoints.length == 2) {
      final a = _imagePointToCanvasPoint(simpleCalibrationPoints[0], imageRect);
      final b = _imagePointToCanvasPoint(simpleCalibrationPoints[1], imageRect);

      canvas.drawLine(a, b, paint);

      _drawLabel(
        canvas: canvas,
        text: 'Kalibrasyon: ${referenceLengthMm.toStringAsFixed(2)} mm',
        position: Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
        color: Colors.blue,
      );
    }
  }

  void _drawPerspectiveCalibration(
    Canvas canvas,
    Rect imageRect,
    Paint paint,
  ) {
    if (perspectiveCalibrationPoints.isEmpty) return;

    final points = perspectiveCalibrationPoints
        .map((point) => _imagePointToCanvasPoint(point, imageRect))
        .toList();

    for (int i = 0; i < points.length; i++) {
      _drawPoint(canvas, points[i], Colors.blue);
      _drawSmallIndex(canvas, points[i], '${i + 1}', Colors.blue);

      if (i > 0) {
        canvas.drawLine(points[i - 1], points[i], paint);
      }
    }

    if (points.length == 4) {
      canvas.drawLine(points.last, points.first, paint);
      final center = _averageOffset(points);

      _drawLabel(
        canvas: canvas,
        text: calibrationMode == _CalibrationMode.perspectiveA4
            ? 'A4 perspektif'
            : 'Marker perspektif',
        position: center,
        color: Colors.blue,
      );
    }
  }

  void _drawMultiReferences(
    Canvas canvas,
    Rect imageRect,
    Paint paint,
  ) {
    for (final reference in multiReferences) {
      final a = _imagePointToCanvasPoint(reference.start, imageRect);
      final b = _imagePointToCanvasPoint(reference.end, imageRect);

      canvas.drawLine(a, b, paint);
      _drawPoint(canvas, a, Colors.deepPurple);
      _drawPoint(canvas, b, Colors.deepPurple);

      _drawLabel(
        canvas: canvas,
        text:
            '${reference.label}: ${reference.referenceLengthMm.toStringAsFixed(2)} mm',
        position: Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
        color: Colors.deepPurple,
      );
    }
  }

  void _drawPendingReferences(
    Canvas canvas,
    Rect imageRect,
    Paint paint,
  ) {
    if (pendingMultiReferencePoints.isEmpty) return;

    final points = pendingMultiReferencePoints
        .map((point) => _imagePointToCanvasPoint(point, imageRect))
        .toList();

    for (final point in points) {
      _drawPoint(canvas, point, Colors.orange);
    }

    if (points.length == 2) {
      canvas.drawLine(points[0], points[1], paint);
    }
  }

  void _drawMeasurements(
    Canvas canvas,
    Rect imageRect,
    Paint paint,
  ) {
    for (final measurement in measurements) {
      final a = _imagePointToCanvasPoint(measurement.startImage, imageRect);
      final b = _imagePointToCanvasPoint(measurement.endImage, imageRect);

      canvas.drawLine(a, b, paint);
      _drawPoint(canvas, a, Colors.teal);
      _drawPoint(canvas, b, Colors.teal);

      _drawLabel(
        canvas: canvas,
        text:
            '${measurement.label}: ${measurement.lengthMm.toStringAsFixed(2)} mm',
        position: Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2),
        color: Colors.teal,
      );
    }
  }

  void _drawPendingMeasurements(
    Canvas canvas,
    Rect imageRect,
    Paint paint,
  ) {
    if (pendingMeasurementPoints.isEmpty) return;

    final points = pendingMeasurementPoints
        .map((point) => _imagePointToCanvasPoint(point, imageRect))
        .toList();

    for (final point in points) {
      _drawPoint(canvas, point, Colors.orange);
    }

    if (points.length == 2) {
      canvas.drawLine(points[0], points[1], paint);
    }
  }

  String get _modeInstructionText {
    if (isSelectingBoundaryRoi) {
      return 'ROI seçimi: iç tabanı kapsayan alanı sürükle';
    }

    if (isSelectingBoundarySeed) {
      return 'İç taban içi nokta seçimi: gövdeye tıkla';
    }

    if (toolMode == _AnalysisToolMode.measurement) {
      return 'Ölçüm modu: ölçülecek iki noktayı seç';
    }

    switch (calibrationMode) {
      case _CalibrationMode.simpleTwoPoint:
        return 'Basit kalibrasyon: bilinen ölçünün iki ucunu seç';
      case _CalibrationMode.perspectiveA4:
        return 'A4: sol üst → sağ üst → sağ alt → sol alt';
      case _CalibrationMode.perspectiveSquareMarker:
        return 'Kare marker: sol üst → sağ üst → sağ alt → sol alt';
      case _CalibrationMode.multiReference:
        return 'Çoklu referans: her referans için iki uç seç';
    }
  }

  Rect _imageDrawRect(Size canvasSize, double imageRatio) {
    final canvasRatio = canvasSize.width / canvasSize.height;

    double width;
    double height;

    if (canvasRatio > imageRatio) {
      height = canvasSize.height;
      width = height * imageRatio;
    } else {
      width = canvasSize.width;
      height = width / imageRatio;
    }

    return Rect.fromLTWH(
      (canvasSize.width - width) / 2,
      (canvasSize.height - height) / 2,
      width,
      height,
    );
  }

  Offset _imagePointToCanvasPoint(_ImagePoint point, Rect imageRect) {
    return Offset(
      imageRect.left + (point.x / image.width) * imageRect.width,
      imageRect.top + (point.y / image.height) * imageRect.height,
    );
  }

  Offset _averageOffset(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;

    double x = 0;
    double y = 0;

    for (final point in points) {
      x += point.dx;
      y += point.dy;
    }

    return Offset(x / points.length, y / points.length);
  }

  void _drawPoint(Canvas canvas, Offset point, Color color) {
    final outerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final innerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(point, 7, outerPaint);
    canvas.drawCircle(point, 5, innerPaint);
  }

  void _drawSmallIndex(
    Canvas canvas,
    Offset point,
    String text,
    Color color,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromCircle(
      center: point + const Offset(12, -12),
      radius: 10,
    );

    canvas.drawOval(rect, Paint()..color = color);
    textPainter.paint(
      canvas,
      Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawLabel({
    required Canvas canvas,
    required String text,
    required Offset position,
    required Color color,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 260);

    final rect = Rect.fromLTWH(
      position.dx + 8,
      position.dy - textPainter.height - 8,
      textPainter.width + 16,
      textPainter.height + 10,
    );

    final backgroundPaint = Paint()..color = color.withOpacity(0.88);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      backgroundPaint,
    );

    textPainter.paint(
      canvas,
      Offset(rect.left + 8, rect.top + 5),
    );
  }

  void _drawTopBadge({
    required Canvas canvas,
    required String text,
    required Rect rect,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 24);

    final badgeRect = Rect.fromLTWH(
      rect.left + 12,
      rect.top + 12,
      textPainter.width + 18,
      textPainter.height + 12,
    );

    final paint = Paint()..color = Colors.black.withOpacity(0.62);

    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(999)),
      paint,
    );

    textPainter.paint(
      canvas,
      Offset(badgeRect.left + 9, badgeRect.top + 6),
    );
  }

  @override
  bool shouldRepaint(covariant _ReferenceInsolePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.calibrationMode != calibrationMode ||
        oldDelegate.toolMode != toolMode ||
        !listEquals(
          oldDelegate.simpleCalibrationPoints,
          simpleCalibrationPoints,
        ) ||
        !listEquals(
          oldDelegate.perspectiveCalibrationPoints,
          perspectiveCalibrationPoints,
        ) ||
        !listEquals(oldDelegate.multiReferences, multiReferences) ||
        !listEquals(
          oldDelegate.pendingMultiReferencePoints,
          pendingMultiReferencePoints,
        ) ||
        !listEquals(oldDelegate.measurements, measurements) ||
        !listEquals(
          oldDelegate.pendingMeasurementPoints,
          pendingMeasurementPoints,
        ) ||
        oldDelegate.insoleBoundary != insoleBoundary ||
        oldDelegate.boundaryRoiImageRect != boundaryRoiImageRect ||
        oldDelegate.boundarySeedPoint != boundarySeedPoint ||
        oldDelegate.boundaryBackgroundPoint != boundaryBackgroundPoint ||
        oldDelegate.isSelectingBoundaryRoi != isSelectingBoundaryRoi ||
        oldDelegate.isSelectingBoundarySeed != isSelectingBoundarySeed ||
        oldDelegate.isSelectingBoundaryBackground !=
            isSelectingBoundaryBackground ||
        oldDelegate.boundaryRoiDragStartPoint != boundaryRoiDragStartPoint ||
        oldDelegate.boundaryRoiDragCurrentPoint != boundaryRoiDragCurrentPoint ||
        oldDelegate.referenceLengthMm != referenceLengthMm ||
        oldDelegate.showCalibrationOverlay != showCalibrationOverlay ||
        oldDelegate.showBoundaryRoiOverlay != showBoundaryRoiOverlay ||
        oldDelegate.showInternalPointOverlay != showInternalPointOverlay ||
        oldDelegate.showMeasurementOverlay != showMeasurementOverlay;
  }
}

class _ReferencePhotoRecord {
  final int? id;
  final String fileType;
  final String fileName;
  final String? mimeType;
  final String? storageBucket;
  final String? storagePath;
  final String? publicUrl;
  final DateTime? createdAt;

  const _ReferencePhotoRecord({
    required this.id,
    required this.fileType,
    required this.fileName,
    required this.mimeType,
    required this.storageBucket,
    required this.storagePath,
    required this.publicUrl,
    required this.createdAt,
  });

  String get displayName {
    if (fileName.trim().isNotEmpty) return fileName;
    if (fileType.trim().isNotEmpty) return fileType;
    return 'Referans fotoğraf #${id ?? '—'}';
  }

  String get resolvedMimeType {
    if (mimeType != null && mimeType!.trim().isNotEmpty) {
      return mimeType!;
    }

    final lower = [fileName, storagePath ?? '', publicUrl ?? '']
        .join(' ')
        .toLowerCase();

    if (lower.contains('.jpg') || lower.contains('.jpeg')) {
      return 'image/jpeg';
    }

    if (lower.contains('.webp')) return 'image/webp';

    return 'image/png';
  }
}

class _ImagePoint {
  final double x;
  final double y;

  const _ImagePoint({
    required this.x,
    required this.y,
  });

  Offset toOffset() => Offset(x, y);

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _ImagePoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

class _LocalReferenceScale {
  final String id;
  final String label;
  final _ImagePoint start;
  final _ImagePoint end;
  final double referenceLengthMm;
  final double pixelDistance;
  final double pixelsPerMm;
  final DateTime createdAt;

  const _LocalReferenceScale({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    required this.referenceLengthMm,
    required this.pixelDistance,
    required this.pixelsPerMm,
    required this.createdAt,
  });

  _ImagePoint get center {
    return _ImagePoint(
      x: (start.x + end.x) / 2,
      y: (start.y + end.y) / 2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'start': start.toJson(),
      'end': end.toJson(),
      'referenceLengthMm': referenceLengthMm,
      'pixelDistance': pixelDistance,
      'pixelsPerMm': pixelsPerMm,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _LocalReferenceScale &&
        other.id == id &&
        other.label == label &&
        other.start == start &&
        other.end == end &&
        other.referenceLengthMm == referenceLengthMm &&
        other.pixelDistance == pixelDistance &&
        other.pixelsPerMm == pixelsPerMm;
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        start,
        end,
        referenceLengthMm,
        pixelDistance,
        pixelsPerMm,
      );
}


class _InsoleBoundary {
  final String method;
  final int imageWidth;
  final int imageHeight;
  final Rect? roiImageRect;
  final _ImagePoint? seedPoint;
  final double? sensitivity;
  final double? shadowTolerance;
  final double? backgroundSeparation;
  final int? closingStrength;
  final int? smoothingStrength;
  final List<_ImagePoint> points;
  final List<_ImagePoint>? pointsMm;
  final DateTime createdAt;

  const _InsoleBoundary({
    required this.method,
    required this.imageWidth,
    required this.imageHeight,
    required this.roiImageRect,
    required this.seedPoint,
    required this.sensitivity,
    required this.shadowTolerance,
    required this.backgroundSeparation,
    required this.closingStrength,
    required this.smoothingStrength,
    required this.points,
    required this.pointsMm,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'roi': roiImageRect == null
          ? null
          : {
              'x': roiImageRect!.left,
              'y': roiImageRect!.top,
              'width': roiImageRect!.width,
              'height': roiImageRect!.height,
              'left': roiImageRect!.left,
              'top': roiImageRect!.top,
              'right': roiImageRect!.right,
              'bottom': roiImageRect!.bottom,
            },
      'seedPoint': seedPoint?.toJson(),
      'sensitivity': sensitivity,
      'shadowTolerance': shadowTolerance,
      'backgroundSeparation': backgroundSeparation,
      'closingStrength': closingStrength,
      'smoothingStrength': smoothingStrength,
      'points': points.map((point) => point.toJson()).toList(),
      'pointsMm': pointsMm?.map((point) => point.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _InsoleBoundary &&
        other.method == method &&
        other.imageWidth == imageWidth &&
        other.imageHeight == imageHeight &&
        other.roiImageRect == roiImageRect &&
        other.seedPoint == seedPoint &&
        other.sensitivity == sensitivity &&
        other.shadowTolerance == shadowTolerance &&
        other.backgroundSeparation == backgroundSeparation &&
        other.closingStrength == closingStrength &&
        other.smoothingStrength == smoothingStrength &&
        listEquals(other.points, points) &&
        listEquals(other.pointsMm, pointsMm);
  }

  @override
  int get hashCode => Object.hash(
        method,
        imageWidth,
        imageHeight,
        roiImageRect,
        seedPoint,
        sensitivity,
        shadowTolerance,
        backgroundSeparation,
        closingStrength,
        smoothingStrength,
        Object.hashAll(points),
        pointsMm == null ? null : Object.hashAll(pointsMm!),
      );
}


class _InsoleMeasurement {
  final String id;
  final String label;
  final _ImagePoint startImage;
  final _ImagePoint endImage;
  final _ImagePoint? startMm;
  final _ImagePoint? endMm;
  final double pixelDistance;
  final double lengthMm;
  final double? localPixelsPerMm;
  final String calibrationMethod;
  final DateTime createdAt;

  const _InsoleMeasurement({
    required this.id,
    required this.label,
    required this.startImage,
    required this.endImage,
    required this.startMm,
    required this.endMm,
    required this.pixelDistance,
    required this.lengthMm,
    required this.localPixelsPerMm,
    required this.calibrationMethod,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'startImage': startImage.toJson(),
      'endImage': endImage.toJson(),
      'startMm': startMm?.toJson(),
      'endMm': endMm?.toJson(),
      'pixelDistance': pixelDistance,
      'lengthMm': lengthMm,
      'localPixelsPerMm': localPixelsPerMm,
      'calibrationMethod': calibrationMethod,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _InsoleMeasurement &&
        other.id == id &&
        other.label == label &&
        other.startImage == startImage &&
        other.endImage == endImage &&
        other.startMm == startMm &&
        other.endMm == endMm &&
        other.pixelDistance == pixelDistance &&
        other.lengthMm == lengthMm &&
        other.localPixelsPerMm == localPixelsPerMm &&
        other.calibrationMethod == calibrationMethod;
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        startImage,
        endImage,
        startMm,
        endMm,
        pixelDistance,
        lengthMm,
        localPixelsPerMm,
        calibrationMethod,
      );
}

class _ReferenceScaleDialogResult {
  final String label;
  final double lengthMm;

  const _ReferenceScaleDialogResult({
    required this.label,
    required this.lengthMm,
  });
}


class _BoundaryPixelFeatures {
  final double nr;
  final double ng;
  final double nb;
  final double luminance;
  final double saturation;

  const _BoundaryPixelFeatures({
    required this.nr,
    required this.ng,
    required this.nb,
    required this.luminance,
    required this.saturation,
  });

  factory _BoundaryPixelFeatures.average(
    List<_BoundaryPixelFeatures> items,
  ) {
    if (items.isEmpty) {
      return const _BoundaryPixelFeatures(
        nr: 0,
        ng: 0,
        nb: 0,
        luminance: 0,
        saturation: 0,
      );
    }

    double nr = 0;
    double ng = 0;
    double nb = 0;
    double luminance = 0;
    double saturation = 0;

    for (final item in items) {
      nr += item.nr;
      ng += item.ng;
      nb += item.nb;
      luminance += item.luminance;
      saturation += item.saturation;
    }

    final count = items.length.toDouble();

    return _BoundaryPixelFeatures(
      nr: nr / count,
      ng: ng / count,
      nb: nb / count,
      luminance: luminance / count,
      saturation: saturation / count,
    );
  }
}
