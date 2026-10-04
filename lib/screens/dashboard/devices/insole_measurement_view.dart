import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oy_site/services/bluetooth/insole_bluetooth_service.dart';
import 'package:oy_site/services/bluetooth/insole_protocol.dart';

class InsoleMeasurementView extends StatefulWidget {
  /// Eski test ve kullanım noktalarıyla uyumluluk için sol taban servisi.
  final InsoleBluetoothService? bluetoothService;
  final InsoleBluetoothService? scannerBluetoothService;
  final InsoleBluetoothService? rightBluetoothService;

  const InsoleMeasurementView({
    super.key,
    this.bluetoothService,
    this.scannerBluetoothService,
    this.rightBluetoothService,
  });

  @override
  State<InsoleMeasurementView> createState() => _InsoleMeasurementViewState();
}

class _InsoleMeasurementViewState extends State<InsoleMeasurementView> {
  late final InsoleBluetoothService _scannerService;
  late final _InsoleSideSession _leftSession;
  late final _InsoleSideSession _rightSession;
  late final bool _ownsScannerService;
  late final bool _ownsLeftService;
  late final bool _ownsRightService;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final ScrollController _debugScrollController = ScrollController();
  final List<_SideDebugMessage> _debugMessages = [];

  List<InsoleBluetoothDevice> _devices = const [];
  bool _isSupported = true;
  bool _isCheckingSupport = true;
  bool _isScanning = false;
  bool _isRecording = false;
  DateTime? _recordingStartedAt;
  Duration? _lastRecordingDuration;
  int _lastLeftRecordingFrameCount = 0;
  int _lastRightRecordingFrameCount = 0;
  String _scanStatus = 'Önce JYS_B_001 ve JYS_B_002 cihazlarını arayın.';

  Iterable<_InsoleSideSession> get _sideSessions => [
    _leftSession,
    _rightSession,
  ];

  bool get _bothSidesReady => _sideSessions.every(
    (session) =>
        session.connectionState == InsoleBluetoothConnectionState.connected &&
        session.activeChannel != null,
  );

  bool get _hasBusySide => _sideSessions.any(
    (session) =>
        session.connectionState == InsoleBluetoothConnectionState.connecting ||
        session.isChangingChannel,
  );

  @override
  void initState() {
    super.initState();
    _ownsScannerService = widget.scannerBluetoothService == null;
    _ownsLeftService = widget.bluetoothService == null;
    _ownsRightService = widget.rightBluetoothService == null;

    _scannerService =
        widget.scannerBluetoothService ?? UniversalInsoleBluetoothService();
    _leftSession = _InsoleSideSession(
      side: _InsoleSide.left,
      service: widget.bluetoothService ?? UniversalInsoleBluetoothService(),
    );
    _rightSession = _InsoleSideSession(
      side: _InsoleSide.right,
      service:
          widget.rightBluetoothService ?? UniversalInsoleBluetoothService(),
    );

    _listenToScanner();
    _listenToSide(_leftSession);
    _listenToSide(_rightSession);
    unawaited(_checkBluetoothSupport());
  }

  void _listenToScanner() {
    _subscriptions.add(
      _scannerService.debugMessages.listen(
        (message) => _appendDebugMessage('GENEL', message),
        onError: (Object error) => _appendLocalDebug(
          'GENEL',
          'Debug akışı hatası: $error',
          InsoleBluetoothDebugLevel.error,
        ),
      ),
    );
    _subscriptions.add(
      _scannerService.scanResults.listen(
        (devices) {
          if (!mounted) return;
          setState(() => _devices = devices);
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() {
            _isScanning = false;
            _scanStatus = 'Cihaz arama hatası: $error';
          });
        },
      ),
    );
    _subscriptions.add(
      _scannerService.connectionState.listen((state) {
        if (!mounted) return;
        if (state == InsoleBluetoothConnectionState.scanning) {
          setState(() => _isScanning = true);
        } else if (_isScanning) {
          setState(() {
            _isScanning = false;
            _scanStatus = _devices.isEmpty
                ? 'Tarama tamamlandı. JYS_B_ cihazı bulunamadı.'
                : 'Tarama tamamlandı. Her cihazı doğru tarafa atayın.';
          });
        }
      }),
    );
  }

  void _listenToSide(_InsoleSideSession session) {
    _subscriptions.add(
      session.service.debugMessages.listen(
        (message) => _appendDebugMessage(session.side.logLabel, message),
        onError: (Object error) => _appendLocalDebug(
          session.side.logLabel,
          'Debug akışı hatası: $error',
          InsoleBluetoothDebugLevel.error,
        ),
      ),
    );
    _subscriptions.add(
      session.service.connectionState.listen((state) {
        if (!mounted || state == InsoleBluetoothConnectionState.scanning) {
          return;
        }
        setState(() {
          final previous = session.connectionState;
          session.connectionState = state;
          if (state == InsoleBluetoothConnectionState.connected) {
            session.status = 'Bağlandı. Şimdi test edilecek kanalı seçin.';
          } else if (state == InsoleBluetoothConnectionState.connecting) {
            session.status = '${session.device?.name ?? 'Cihaz'} bağlanıyor...';
          } else if (previous == InsoleBluetoothConnectionState.connected ||
              previous == InsoleBluetoothConnectionState.connecting) {
            session.activeChannel = null;
            session.channels = const [];
            session.status = 'Bağlantı kesildi.';
            _stopRecordingBecauseSideChanged();
          }
        });
      }),
    );
    _subscriptions.add(
      session.service.channels.listen((channels) {
        if (!mounted) return;
        setState(() {
          session.channels = channels;
          if (!channels.contains(session.activeChannel)) {
            session.activeChannel = null;
          }
        });
      }),
    );
    _subscriptions.add(
      session.service.data.listen(
        (data) => _handleIncomingData(session, data),
        onError: (Object error) => _appendLocalDebug(
          session.side.logLabel,
          'Veri akışı hatası: $error',
          InsoleBluetoothDebugLevel.error,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _debugScrollController.dispose();
    if (_ownsScannerService) unawaited(_scannerService.dispose());
    if (_ownsLeftService) unawaited(_leftSession.service.dispose());
    if (_ownsRightService) unawaited(_rightSession.service.dispose());
    super.dispose();
  }

  Future<void> _checkBluetoothSupport() async {
    final supported = await _scannerService.isSupported();
    if (!mounted) return;
    setState(() {
      _isSupported = supported;
      _isCheckingSupport = false;
      if (!supported) {
        _scanStatus =
            'Bu bilgisayar veya tarayıcı Bluetooth Low Energy desteklemiyor.';
      }
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'JYS_B_001 ve JYS_B_002 cihazları aranıyor...';
    });
    try {
      await _scannerService.startScan();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _scanStatus = 'Bluetooth taraması başlatılamadı: $error';
      });
    }
  }

  Future<void> _connectSide(
    _InsoleSideSession session,
    InsoleBluetoothDevice device,
  ) async {
    final otherSession = session == _leftSession ? _rightSession : _leftSession;
    if (otherSession.device?.id == device.id &&
        otherSession.connectionState !=
            InsoleBluetoothConnectionState.disconnected) {
      _showMessage(
        '${device.name} zaten ${otherSession.side.label} olarak bağlı.',
      );
      return;
    }

    try {
      await _scannerService.stopScan();
      if (session.device != null && session.device!.id != device.id) {
        await session.service.disconnect();
      }
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        session.device = device;
        session.connectionState = InsoleBluetoothConnectionState.connecting;
        session.channels = const [];
        session.activeChannel = null;
        session.resetMeasurements();
        session.status = '${device.name} cihazına bağlanılıyor...';
      });
      await session.service.connect(device.id);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        session.connectionState = InsoleBluetoothConnectionState.disconnected;
        session.activeChannel = null;
        session.channels = const [];
        session.status = 'Bağlantı kurulamadı: $error';
      });
    }
  }

  Future<void> _disconnectSide(_InsoleSideSession session) async {
    setState(() {
      session.status = 'Bağlantı kapatılıyor...';
      session.isChangingChannel = true;
    });
    Object? disconnectError;
    try {
      await session.service.disconnect();
    } catch (error) {
      disconnectError = error;
    }
    if (!mounted) return;
    setState(() {
      session.isChangingChannel = false;
      session.connectionState = InsoleBluetoothConnectionState.disconnected;
      session.device = null;
      session.channels = const [];
      session.activeChannel = null;
      session.status = disconnectError == null
          ? 'Bu taraf için cihaz seçilmedi.'
          : 'Bağlantı kapatılırken hata oluştu: $disconnectError';
      _stopRecordingBecauseSideChanged();
    });
  }

  Future<void> _selectChannel(
    _InsoleSideSession session,
    InsoleBluetoothChannel channel,
  ) async {
    setState(() {
      session.isChangingChannel = true;
      session.activeChannel = null;
      session.resetMeasurements();
      session.status = 'Seçilen kanal açılıyor...';
    });
    try {
      await session.service.selectChannel(channel);
      if (!mounted) return;
      setState(() {
        session.isChangingChannel = false;
        session.activeChannel = channel;
        if (session.rawPacketCount == 0) {
          session.status = 'Kanal dinleniyor. İlk sensör paketi bekleniyor.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        session.isChangingChannel = false;
        session.activeChannel = null;
        session.status = 'Kanal açılamadı: $error';
      });
    }
  }

  void _handleIncomingData(_InsoleSideSession session, Uint8List data) {
    final frames = session.parser.addBytes(data);
    if (!mounted) return;
    setState(() {
      session.rawPacketCount++;
      session.rawByteCount += data.length;
      session.lastRawPreview = data
          .take(16)
          .map((value) => value.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      if (frames.isEmpty) {
        session.status =
            'Ham veri geliyor; geçerli basınç çerçevesi bekleniyor.';
        return;
      }

      session.latestFrame = frames.last;
      session.frameCount += frames.length;
      if (_isRecording) session.recordedFrameCount += frames.length;
      session.status =
          'Canlı veri alınıyor • ${frames.last.matrixLabel} • '
          '${frames.last.bytesPerSample} bayt/örnek';
    });
  }

  void _toggleRecording() {
    if (_isRecording) {
      final startedAt = _recordingStartedAt;
      setState(() {
        _isRecording = false;
        _lastLeftRecordingFrameCount = _leftSession.recordedFrameCount;
        _lastRightRecordingFrameCount = _rightSession.recordedFrameCount;
        _lastRecordingDuration = startedAt == null
            ? Duration.zero
            : DateTime.now().difference(startedAt);
      });
      return;
    }

    setState(() {
      _leftSession.recordedFrameCount = 0;
      _rightSession.recordedFrameCount = 0;
      _recordingStartedAt = DateTime.now();
      _lastRecordingDuration = null;
      _lastLeftRecordingFrameCount = 0;
      _lastRightRecordingFrameCount = 0;
      _isRecording = true;
    });
  }

  void _stopRecordingBecauseSideChanged() {
    if (!_isRecording) return;
    _isRecording = false;
    _lastLeftRecordingFrameCount = _leftSession.recordedFrameCount;
    _lastRightRecordingFrameCount = _rightSession.recordedFrameCount;
    final startedAt = _recordingStartedAt;
    _lastRecordingDuration = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
  }

  void _appendDebugMessage(String source, InsoleBluetoothDebugMessage message) {
    if (!mounted) return;
    setState(() {
      _debugMessages.add(_SideDebugMessage(source: source, message: message));
      if (_debugMessages.length > 500) _debugMessages.removeAt(0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_debugScrollController.hasClients) return;
      _debugScrollController.jumpTo(
        _debugScrollController.position.maxScrollExtent,
      );
    });
  }

  void _appendLocalDebug(
    String source,
    String text,
    InsoleBluetoothDebugLevel level,
  ) {
    _appendDebugMessage(
      source,
      InsoleBluetoothDebugMessage(
        timestamp: DateTime.now(),
        level: level,
        message: text,
      ),
    );
  }

  Future<void> _copyDebugMessages() async {
    final text = _debugMessages.map(_formatDebugMessage).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _showMessage('Bluetooth debug günlüğü kopyalandı.');
  }

  void _clearDebugMessages() => setState(_debugMessages.clear);

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSupport) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProtocolNotice(),
              const SizedBox(height: 16),
              _buildConnectionPanel(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final leftCard = _buildSideConnectionCard(_leftSession);
                  final rightCard = _buildSideConnectionCard(_rightSession);
                  if (constraints.maxWidth < 850) {
                    return Column(
                      children: [
                        leftCard,
                        const SizedBox(height: 16),
                        rightCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: leftCard),
                      const SizedBox(width: 16),
                      Expanded(child: rightCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildDebugPanel(),
              const SizedBox(height: 16),
              _buildLivePanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9E5DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bluetooth_connected, color: Color(0xFF087F73)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çift iç taban ve kanal testi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'JYS_B_001 ve JYS_B_002 ayrı ayrı bağlanır. Sağ/sol atamasını '
                  'siz yaparsınız ve her cihazda yalnızca seçtiğiniz kanal '
                  'dinlenir. Tarama sırasında telefonunuzdaki debug uygulamasının '
                  'cihaz bağlantısını kapalı tutun. Eşleştirme kodu: '
                  '${InsoleProtocolConstants.pairingCode}',
                  style: TextStyle(color: Colors.grey[700], height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bluetooth cihazları',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              _buildScanChip(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _bothSidesReady
                ? 'İki iç taban da bağlı ve seçilen kanallar dinleniyor.'
                : _scanStatus,
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: !_isSupported || _isScanning || _hasBusySide
                  ? null
                  : _startScan,
              icon: _isScanning
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bluetooth_searching),
              label: Text(_isScanning ? 'Aranıyor...' : 'İki Tabanı Ara'),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Bulunan cihazlar',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_devices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isScanning
                    ? 'Yakındaki JYS_B_ cihazları taranıyor...'
                    : 'Henüz JYS_B_ cihazı bulunmadı.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < 720
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: _devices
                      .map(
                        (device) => SizedBox(
                          width: width,
                          child: _buildDeviceTile(device),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(InsoleBluetoothDevice device) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDDF4F0),
                child: Icon(Icons.bluetooth, color: Color(0xFF087F73)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Sinyal: ${device.rssi} dBm\nKimlik: ${device.id}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildAssignButton(_leftSession, device)),
              const SizedBox(width: 8),
              Expanded(child: _buildAssignButton(_rightSession, device)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignButton(
    _InsoleSideSession session,
    InsoleBluetoothDevice device,
  ) {
    final isAssigned =
        session.device?.id == device.id &&
        session.connectionState != InsoleBluetoothConnectionState.disconnected;
    final otherSession = session == _leftSession ? _rightSession : _leftSession;
    final isUsedByOther =
        otherSession.device?.id == device.id &&
        otherSession.connectionState !=
            InsoleBluetoothConnectionState.disconnected;
    return OutlinedButton.icon(
      key: ValueKey('assign-${session.side.name}-${device.id}'),
      onPressed: isAssigned || isUsedByOther || _hasBusySide
          ? null
          : () => _connectSide(session, device),
      icon: Icon(isAssigned ? Icons.check : session.side.icon, size: 17),
      label: Text(
        isAssigned
            ? '${session.side.shortLabel} bağlı'
            : session.side.actionLabel,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
    );
  }

  Widget _buildSideConnectionCard(_InsoleSideSession session) {
    final isConnected =
        session.connectionState == InsoleBluetoothConnectionState.connected;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(session.side.icon, color: const Color(0xFF087F73)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  session.side.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildSideStateChip(session),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.device?.name ?? 'Henüz bir cihaz atanmadı.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            session.status,
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
          if (isConnected) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text(
              'Tek tek denenecek kanallar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Yeni bir kanal seçildiğinde önceki kanal otomatik kapanır.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (session.channels.isEmpty)
              const LinearProgressIndicator()
            else
              ...session.channels.indexed.map(
                (entry) => _buildChannelTile(session, entry.$1, entry.$2),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: session.isChangingChannel
                    ? null
                    : () => _disconnectSide(session),
                icon: const Icon(Icons.link_off, size: 18),
                label: const Text('Bağlantıyı Kes'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelTile(
    _InsoleSideSession session,
    int index,
    InsoleBluetoothChannel channel,
  ) {
    final active = session.activeChannel == channel;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F7F4) : Colors.grey[50],
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: active ? const Color(0xFF11998E) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channel.isPreferred
                      ? 'Protokoldeki basınç kanalı'
                      : 'Alternatif kanal ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${channel.usesIndications ? 'Indicate' : 'Notify'} • '
                  '${channel.characteristicUuid}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'Servis: ${channel.serviceUuid}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            key: ValueKey('${session.side.name}-channel-$index'),
            onPressed: session.isChangingChannel
                ? null
                : () => _selectChannel(session, channel),
            child: Text(active ? 'Yeniden dene' : 'Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bluetooth debug günlüğü',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Günlüğü kopyala',
                onPressed: _debugMessages.isEmpty ? null : _copyDebugMessages,
                icon: const Icon(Icons.copy_all_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Günlüğü temizle',
                onPressed: _debugMessages.isEmpty ? null : _clearDebugMessages,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: _debugMessages.isEmpty
                ? const Center(
                    child: Text(
                      'Tarama başlatıldığında mesajlar burada görünecek.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  )
                : SelectionArea(
                    child: ListView.builder(
                      controller: _debugScrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: _debugMessages.length,
                      itemBuilder: (context, index) {
                        final entry = _debugMessages[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            _formatDebugMessage(entry),
                            style: TextStyle(
                              color: _debugMessageColor(entry.message.level),
                              height: 1.35,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            'GENEL, SOL ve SAĞ mesajları birlikte gösterilir; son 500 kayıt tutulur.',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Çift iç taban ölçümü',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton.icon(
                onPressed: _bothSidesReady ? _toggleRecording : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _isRecording
                      ? Colors.red[700]
                      : const Color(0xFF087F73),
                ),
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.fiber_manual_record,
                ),
                label: Text(_isRecording ? 'Ölçümü Durdur' : 'Ölçümü Başlat'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _bothSidesReady
                ? 'Her iki tabanın akışı birlikte kaydedilecektir.'
                : 'Ölçüm için iki tabanı da bağlayın ve her biri için bir kanal seçin.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final leftPanel = _buildSideLivePanel(_leftSession);
              final rightPanel = _buildSideLivePanel(_rightSession);
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [leftPanel, const SizedBox(height: 14), rightPanel],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftPanel),
                  const SizedBox(width: 14),
                  Expanded(child: rightPanel),
                ],
              );
            },
          ),
          if (_isRecording || _lastRecordingDuration != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isRecording
                    ? Colors.red.withValues(alpha: 0.08)
                    : const Color(0xFFEFFAF8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isRecording ? Icons.radio_button_checked : Icons.check,
                    color: _isRecording
                        ? Colors.red[700]
                        : const Color(0xFF087F73),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isRecording
                          ? 'Kayıt sürüyor • Sol ${_leftSession.recordedFrameCount} • '
                                'Sağ ${_rightSession.recordedFrameCount} kare'
                          : 'Son ölçüm • Sol $_lastLeftRecordingFrameCount • '
                                'Sağ $_lastRightRecordingFrameCount kare • '
                                '${_formatDuration(_lastRecordingDuration!)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSideLivePanel(_InsoleSideSession session) {
    final frame = session.latestFrame;
    final ready =
        session.connectionState == InsoleBluetoothConnectionState.connected &&
        session.activeChannel != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.side.label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            session.device?.name ?? 'Cihaz seçilmedi',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricCard(label: 'Toplam Kare', value: '${session.frameCount}'),
              _MetricCard(
                label: 'Ham Paket',
                value: '${session.rawPacketCount}',
              ),
              _MetricCard(label: 'Ham Bayt', value: '${session.rawByteCount}'),
              _MetricCard(label: 'Matris', value: frame?.matrixLabel ?? '—'),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1.15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: frame == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.airline_seat_legroom_normal_outlined,
                              size: 44,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ready
                                  ? 'İlk basınç karesi bekleniyor...'
                                  : 'Bağlantı ve kanal seçimi bekleniyor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomPaint(
                        painter: _InsoleHeatmapPainter(frame.matrix),
                        child: const SizedBox.expand(),
                      ),
                    ),
            ),
          ),
          if (session.rawPacketCount > 0 && session.frameCount == 0) ...[
            const SizedBox(height: 9),
            Text(
              'Son ham veri: ${session.lastRawPreview ?? '—'}',
              style: TextStyle(
                color: Colors.blueGrey[700],
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (session.parser.invalidFrameCount > 0) ...[
            const SizedBox(height: 7),
            Text(
              '${session.parser.invalidFrameCount} doğrulanamayan paket atlandı.',
              style: TextStyle(color: Colors.orange[800], fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanChip() {
    final color = _isScanning ? Colors.blue : Colors.grey;
    return _StatusChip(
      label: _isScanning ? 'Aranıyor' : 'Tarama hazır',
      color: color,
    );
  }

  Widget _buildSideStateChip(_InsoleSideSession session) {
    if (session.activeChannel != null &&
        session.connectionState == InsoleBluetoothConnectionState.connected) {
      return const _StatusChip(label: 'Dinleniyor', color: Color(0xFF11998E));
    }
    final (label, color) = switch (session.connectionState) {
      InsoleBluetoothConnectionState.disconnected => (
        'Bağlı değil',
        Colors.grey,
      ),
      InsoleBluetoothConnectionState.scanning => ('Aranıyor', Colors.blue),
      InsoleBluetoothConnectionState.connecting => (
        'Bağlanıyor',
        Colors.orange,
      ),
      InsoleBluetoothConnectionState.connected => ('Kanal seçin', Colors.blue),
    };
    return _StatusChip(label: label, color: color);
  }

  String _formatDebugMessage(_SideDebugMessage entry) {
    final message = entry.message;
    final time = message.timestamp;
    final timestamp =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
    final level = switch (message.level) {
      InsoleBluetoothDebugLevel.info => 'BİLGİ',
      InsoleBluetoothDebugLevel.success => 'BAŞARILI',
      InsoleBluetoothDebugLevel.warning => 'UYARI',
      InsoleBluetoothDebugLevel.error => 'HATA',
      InsoleBluetoothDebugLevel.data => 'VERİ',
    };
    return '[$timestamp] [${entry.source}] [$level] ${message.message}';
  }

  Color _debugMessageColor(InsoleBluetoothDebugLevel level) {
    return switch (level) {
      InsoleBluetoothDebugLevel.info => const Color(0xFFE2E8F0),
      InsoleBluetoothDebugLevel.success => const Color(0xFF6EE7B7),
      InsoleBluetoothDebugLevel.warning => const Color(0xFFFCD34D),
      InsoleBluetoothDebugLevel.error => const Color(0xFFFCA5A5),
      InsoleBluetoothDebugLevel.data => const Color(0xFF93C5FD),
    };
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

enum _InsoleSide { left, right }

extension on _InsoleSide {
  String get label =>
      this == _InsoleSide.left ? 'Sol iç taban' : 'Sağ iç taban';
  String get shortLabel => this == _InsoleSide.left ? 'Sol' : 'Sağ';
  String get actionLabel =>
      this == _InsoleSide.left ? 'Sola bağla' : 'Sağa bağla';
  String get logLabel => this == _InsoleSide.left ? 'SOL' : 'SAĞ';
  IconData get icon => this == _InsoleSide.left
      ? Icons.arrow_back_rounded
      : Icons.arrow_forward_rounded;
}

class _InsoleSideSession {
  final _InsoleSide side;
  final InsoleBluetoothService service;
  final InsoleProtocolParser parser = InsoleProtocolParser();

  InsoleBluetoothDevice? device;
  InsoleBluetoothConnectionState connectionState =
      InsoleBluetoothConnectionState.disconnected;
  List<InsoleBluetoothChannel> channels = const [];
  InsoleBluetoothChannel? activeChannel;
  InsolePressureFrame? latestFrame;
  String status = 'Bu taraf için cihaz seçilmedi.';
  String? lastRawPreview;
  bool isChangingChannel = false;
  int rawPacketCount = 0;
  int rawByteCount = 0;
  int frameCount = 0;
  int recordedFrameCount = 0;

  _InsoleSideSession({required this.side, required this.service});

  void resetMeasurements() {
    parser.reset();
    latestFrame = null;
    lastRawPreview = null;
    rawPacketCount = 0;
    rawByteCount = 0;
    frameCount = 0;
    recordedFrameCount = 0;
  }
}

class _SideDebugMessage {
  final String source;
  final InsoleBluetoothDebugMessage message;

  const _SideDebugMessage({required this.source, required this.message});
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InsoleHeatmapPainter extends CustomPainter {
  final List<List<int>> matrix;

  const _InsoleHeatmapPainter(this.matrix);

  @override
  void paint(Canvas canvas, Size size) {
    if (matrix.isEmpty || matrix.first.isEmpty) return;

    final rows = matrix.length;
    final columns = matrix.first.length;
    final maximum = math.max(1, matrix.expand((row) => row).reduce(math.max));
    final heatmapRatio = columns / rows;
    final availableRatio = size.width / size.height;

    final drawWidth = availableRatio > heatmapRatio
        ? size.height * heatmapRatio
        : size.width;
    final drawHeight = availableRatio > heatmapRatio
        ? size.height
        : size.width / heatmapRatio;
    final origin = Offset(
      (size.width - drawWidth) / 2,
      (size.height - drawHeight) / 2,
    );
    final cellWidth = drawWidth / columns;
    final cellHeight = drawHeight / rows;

    final clipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(origin.dx, origin.dy, drawWidth, drawHeight),
      Radius.circular(math.min(drawWidth, drawHeight) * 0.12),
    );

    canvas.save();
    canvas.clipRRect(clipRect);
    canvas.drawRect(clipRect.outerRect, Paint()..color = Colors.white);

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final normalized = (matrix[row][column] / maximum).clamp(0.0, 1.0);
        canvas.drawRect(
          Rect.fromLTWH(
            origin.dx + (column * cellWidth),
            origin.dy + (row * cellHeight),
            cellWidth + 0.5,
            cellHeight + 0.5,
          ),
          Paint()..color = _heatColor(normalized),
        );
      }
    }
    canvas.restore();

    canvas.drawRRect(
      clipRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFB9D8D4),
    );
  }

  Color _heatColor(double value) {
    if (value <= 0.02) return const Color(0xFFF2F7F7);
    if (value < 0.25) {
      return Color.lerp(
        const Color(0xFF2563EB),
        const Color(0xFF22D3EE),
        value / 0.25,
      )!;
    }
    if (value < 0.55) {
      return Color.lerp(
        const Color(0xFF22D3EE),
        const Color(0xFFFACC15),
        (value - 0.25) / 0.30,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFACC15),
      const Color(0xFFDC2626),
      (value - 0.55) / 0.45,
    )!;
  }

  @override
  bool shouldRepaint(covariant _InsoleHeatmapPainter oldDelegate) {
    return oldDelegate.matrix != matrix;
  }
}
