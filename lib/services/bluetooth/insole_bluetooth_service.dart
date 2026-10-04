import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oy_site/services/bluetooth/insole_protocol.dart';
import 'package:universal_ble/universal_ble.dart';

enum InsoleBluetoothConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}

enum InsoleBluetoothDebugLevel { info, success, warning, error, data }

class InsoleBluetoothDebugMessage {
  final DateTime timestamp;
  final InsoleBluetoothDebugLevel level;
  final String message;

  const InsoleBluetoothDebugMessage({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}

class InsoleBluetoothDevice {
  final String id;
  final String name;
  final int rssi;

  const InsoleBluetoothDevice({
    required this.id,
    required this.name,
    required this.rssi,
  });
}

class InsoleBluetoothChannel {
  final String serviceUuid;
  final String characteristicUuid;
  final bool usesIndications;
  final bool isPreferred;

  const InsoleBluetoothChannel({
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.usesIndications,
    required this.isPreferred,
  });

  @override
  bool operator ==(Object other) =>
      other is InsoleBluetoothChannel &&
      serviceUuid.toLowerCase() == other.serviceUuid.toLowerCase() &&
      characteristicUuid.toLowerCase() ==
          other.characteristicUuid.toLowerCase();

  @override
  int get hashCode =>
      Object.hash(serviceUuid.toLowerCase(), characteristicUuid.toLowerCase());
}

abstract class InsoleBluetoothService {
  Stream<List<InsoleBluetoothDevice>> get scanResults;
  Stream<InsoleBluetoothConnectionState> get connectionState;
  Stream<List<InsoleBluetoothChannel>> get channels;
  Stream<Uint8List> get data;
  Stream<InsoleBluetoothDebugMessage> get debugMessages;

  Future<bool> isSupported();
  Future<void> startScan();
  Future<void> stopScan();
  Future<void> connect(String deviceId);
  Future<void> selectChannel(InsoleBluetoothChannel channel);
  Future<void> disconnect();
  Future<void> dispose();
}

class UniversalInsoleBluetoothService implements InsoleBluetoothService {
  final StreamController<List<InsoleBluetoothDevice>> _scanController =
      StreamController<List<InsoleBluetoothDevice>>.broadcast();
  final StreamController<InsoleBluetoothConnectionState> _stateController =
      StreamController<InsoleBluetoothConnectionState>.broadcast();
  final StreamController<List<InsoleBluetoothChannel>> _channelController =
      StreamController<List<InsoleBluetoothChannel>>.broadcast();
  final StreamController<Uint8List> _dataController =
      StreamController<Uint8List>.broadcast();
  final StreamController<InsoleBluetoothDebugMessage> _debugController =
      StreamController<InsoleBluetoothDebugMessage>.broadcast();

  final Map<String, BleDevice> _scanResultsById = <String, BleDevice>{};

  StreamSubscription<BleDevice>? _scanSubscription;
  StreamSubscription<bool>? _deviceConnectionSubscription;
  StreamSubscription<Uint8List>? _valueSubscription;
  Timer? _scanTimer;
  Timer? _notificationWatchdog;

  String? _connectedDeviceId;
  List<InsoleBluetoothChannel> _availableChannels = const [];
  InsoleBluetoothChannel? _activeChannel;
  InsoleBluetoothConnectionState _currentState =
      InsoleBluetoothConnectionState.disconnected;
  bool _disposed = false;
  int _receivedValueEventCount = 0;

  UniversalInsoleBluetoothService() {
    _scanSubscription = UniversalBle.scanStream.listen(
      _handleScanResult,
      onError: (Object error, StackTrace stackTrace) {
        _log(
          'Tarama akışı hatası: $error',
          level: InsoleBluetoothDebugLevel.error,
        );
        if (!_scanController.isClosed) {
          _scanController.addError(error, stackTrace);
        }
      },
    );
  }

  @override
  Stream<List<InsoleBluetoothDevice>> get scanResults => _scanController.stream;

  @override
  Stream<InsoleBluetoothConnectionState> get connectionState =>
      _stateController.stream;

  @override
  Stream<List<InsoleBluetoothChannel>> get channels =>
      _channelController.stream;

  @override
  Stream<Uint8List> get data => _dataController.stream;

  @override
  Stream<InsoleBluetoothDebugMessage> get debugMessages =>
      _debugController.stream;

  @override
  Future<bool> isSupported() async {
    try {
      final state = await UniversalBle.getBluetoothAvailabilityState();
      _log('Bluetooth kullanılabilirlik durumu: ${state.name}');
      return state != AvailabilityState.unsupported;
    } catch (error) {
      _log(
        'Bluetooth durumu okunamadı: $error',
        level: InsoleBluetoothDebugLevel.error,
      );
      return false;
    }
  }

  @override
  Future<void> startScan() async {
    _ensureActive();
    _log('Cihaz taraması istendi.');
    if (!await isSupported()) {
      throw StateError('Bu cihazda Bluetooth Low Energy desteklenmiyor.');
    }

    if (await UniversalBle.isScanning()) {
      _log('Önceki tarama durduruluyor.');
      await UniversalBle.stopScan();
    }

    await UniversalBle.requestPermissions();
    _log('Bluetooth izinleri doğrulandı.');
    _scanResultsById.clear();
    _scanController.add(const <InsoleBluetoothDevice>[]);
    _emitState(InsoleBluetoothConnectionState.scanning);

    try {
      // Windows'ta bazı JYS cihazları yerel adı ve servis listesini farklı
      // reklam parçalarında gönderiyor. Platform filtresi bu parçalardan birini
      // kaçırmasın diye yerel uygulamada geniş tarama yapıp aşağıda birleştiririz.
      // Web Bluetooth ise erişilecek servisleri seçim anında bildirmeyi zorunlu
      // tuttuğu için orada filtreli tarama korunur.
      if (kIsWeb) {
        await UniversalBle.startScan(
          scanFilter: ScanFilter(
            withServices: InsoleProtocolConstants.supportedServiceUuids,
            withNamePrefix: const [InsoleProtocolConstants.deviceNamePrefix],
          ),
        );
      } else {
        await UniversalBle.startScan();
      }
      _log(
        kIsWeb
            ? 'Tarama başladı: '
                  'ad=${InsoleProtocolConstants.deviceNamePrefix}*, '
                  'servis=${InsoleProtocolConstants.supportedServiceUuids.join(', ')}'
            : 'Geniş tarama başladı: tüm BLE reklamları dinleniyor; '
                  'JYS_B_ adı veya bilinen servis UUID’si uygulamada süzülecek.',
      );
      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 20), () {
        unawaited(stopScan());
      });
    } catch (error) {
      _log(
        'Tarama başlatılamadı: $error',
        level: InsoleBluetoothDebugLevel.error,
      );
      _emitState(InsoleBluetoothConnectionState.disconnected);
      rethrow;
    }
  }

  @override
  Future<void> stopScan() async {
    final wasScanning =
        _currentState == InsoleBluetoothConnectionState.scanning;
    _scanTimer?.cancel();
    _scanTimer = null;
    try {
      if (await UniversalBle.isScanning()) {
        await UniversalBle.stopScan();
      }
    } catch (_) {}

    if (_currentState == InsoleBluetoothConnectionState.scanning) {
      _emitState(InsoleBluetoothConnectionState.disconnected);
    }
    if (wasScanning) _log('Cihaz taraması durduruldu.');
  }

  @override
  Future<void> connect(String deviceId) async {
    _ensureActive();
    _log('Bağlantı istendi: cihaz=$deviceId');
    await stopScan();
    await _releaseDeviceConnection(disconnectDevice: true);

    _connectedDeviceId = deviceId;
    _emitState(InsoleBluetoothConnectionState.connecting);
    _deviceConnectionSubscription = UniversalBle.connectionStream(deviceId)
        .listen((isConnected) {
          _log(
            'Bağlantı olayı: ${isConnected ? 'bağlı' : 'bağlantı kesildi'} '
            '(cihaz=$deviceId)',
            level: isConnected
                ? InsoleBluetoothDebugLevel.success
                : InsoleBluetoothDebugLevel.warning,
          );
          if (!isConnected &&
              _currentState != InsoleBluetoothConnectionState.connecting) {
            unawaited(_handleUnexpectedDisconnect());
          }
        });

    try {
      await _pairIfRequired(deviceId);
      _log('BLE bağlantısı kuruluyor...');
      await UniversalBle.connect(
        deviceId,
        timeout: const Duration(seconds: 20),
      );
      _log('BLE bağlantısı kuruldu.', level: InsoleBluetoothDebugLevel.success);
      final services = await UniversalBle.discoverServices(deviceId);
      _log('GATT keşfi tamamlandı: ${services.length} servis bulundu.');
      for (final service in services) {
        _log('SERVİS ${service.uuid}');
        for (final characteristic in service.characteristics) {
          final properties = characteristic.properties.isEmpty
              ? 'özellik yok'
              : characteristic.properties
                    .map((property) => property.name)
                    .join(', ');
          _log('  KARAKTERİSTİK ${characteristic.uuid} [$properties]');
        }
      }
      final inputChannels = _buildInputChannels(services);
      if (inputChannels.isEmpty) {
        throw StateError(
          'İç tabanda Notify veya Indicate özelliği olan bir üretici kanalı '
          'bulunamadı.',
        );
      }

      _receivedValueEventCount = 0;
      _availableChannels = List<InsoleBluetoothChannel>.unmodifiable(
        inputChannels,
      );
      if (!_channelController.isClosed) {
        _channelController.add(_availableChannels);
      }
      _log(
        '${inputChannels.length} veri kanalı test için hazır. '
        'Bir seferde yalnızca seçilen kanal dinlenecek.',
        level: InsoleBluetoothDebugLevel.success,
      );
      for (final channel in inputChannels) {
        _log(
          'TEST KANALI${channel.isPreferred ? ' (protokoldeki)' : ''}: '
          'servis=${channel.serviceUuid}, '
          'karakteristik=${channel.characteristicUuid}, '
          'tür=${channel.usesIndications ? 'Indicate' : 'Notify'}',
        );
      }
      _emitState(InsoleBluetoothConnectionState.connected);
      _log('BLE bağlı; veri almak için test edilecek kanalı seçin.');
      unawaited(_logDeviceInformation(deviceId, services));
    } catch (error) {
      _log(
        'Bağlantı işlemi başarısız: $error',
        level: InsoleBluetoothDebugLevel.error,
      );
      await _releaseDeviceConnection(disconnectDevice: true);
      _emitState(InsoleBluetoothConnectionState.disconnected);
      rethrow;
    }
  }

  List<InsoleBluetoothChannel> _buildInputChannels(List<BleService> services) {
    final channels = <InsoleBluetoothChannel>[];
    final preferredUuid = BleUuidParser.string(
      InsoleProtocolConstants.notifyCharacteristicUuid,
    );
    for (final service in services) {
      if (!_isVendorSpecificService(service.uuid)) continue;
      for (final characteristic in service.characteristics) {
        final supportsNotify = characteristic.properties.contains(
          CharacteristicProperty.notify,
        );
        final supportsIndicate = characteristic.properties.contains(
          CharacteristicProperty.indicate,
        );
        if (!supportsNotify && !supportsIndicate) continue;
        channels.add(
          InsoleBluetoothChannel(
            serviceUuid: service.uuid,
            characteristicUuid: characteristic.uuid,
            usesIndications: !supportsNotify && supportsIndicate,
            isPreferred:
                BleUuidParser.string(characteristic.uuid) == preferredUuid,
          ),
        );
      }
    }
    channels.sort((a, b) {
      if (a.isPreferred != b.isPreferred) return a.isPreferred ? -1 : 1;
      final serviceCompare = a.serviceUuid.compareTo(b.serviceUuid);
      return serviceCompare != 0
          ? serviceCompare
          : a.characteristicUuid.compareTo(b.characteristicUuid);
    });
    return channels;
  }

  bool _isVendorSpecificService(String uuid) {
    final normalized = BleUuidParser.string(uuid);
    return !normalized.endsWith('-0000-1000-8000-00805f9b34fb');
  }

  @override
  Future<void> selectChannel(InsoleBluetoothChannel channel) async {
    _ensureActive();
    final deviceId = _connectedDeviceId;
    if (deviceId == null ||
        _currentState != InsoleBluetoothConnectionState.connected) {
      throw StateError('Önce iç taban cihazına bağlanın.');
    }
    if (!_availableChannels.contains(channel)) {
      throw StateError('Seçilen kanal bu cihazın kanal listesinde yok.');
    }

    await _releaseInputChannel(unsubscribe: true);
    _receivedValueEventCount = 0;
    _activeChannel = channel;
    _log(
      'Kanal testi başlatılıyor: servis=${channel.serviceUuid}, '
      'karakteristik=${channel.characteristicUuid}, '
      'tür=${channel.usesIndications ? 'Indicate' : 'Notify'}',
    );

    try {
      _valueSubscription =
          UniversalBle.characteristicValueStream(
            deviceId,
            channel.characteristicUuid,
          ).listen(
            (value) => _handleStreamCharacteristicValue(
              deviceId,
              channel.characteristicUuid,
              value,
            ),
            onError: (Object error, StackTrace stackTrace) {
              _log(
                'Karakteristik değer akışı hatası '
                '(${channel.characteristicUuid}): $error',
                level: InsoleBluetoothDebugLevel.error,
              );
            },
          );

      if (!channel.usesIndications) {
        await UniversalBle.subscribeNotifications(
          deviceId,
          channel.serviceUuid,
          channel.characteristicUuid,
        );
      } else {
        await UniversalBle.subscribeIndications(
          deviceId,
          channel.serviceUuid,
          channel.characteristicUuid,
        );
      }

      final subscriptionType = !channel.usesIndications ? 'Notify' : 'Indicate';
      _log(
        '$subscriptionType aboneliği etkinleştirildi: '
        '${channel.characteristicUuid}',
        level: InsoleBluetoothDebugLevel.success,
      );
      _startNotificationWatchdog();
    } catch (error) {
      await _releaseInputChannel(unsubscribe: false);
      _log(
        'Kanal etkinleştirilemedi: $error',
        level: InsoleBluetoothDebugLevel.error,
      );
      rethrow;
    }
  }

  Future<void> _logDeviceInformation(
    String deviceId,
    List<BleService> services,
  ) async {
    const serviceUuid = '0000180a-0000-1000-8000-00805f9b34fb';
    const fields = <({String uuid, String label})>[
      (uuid: '00002a24-0000-1000-8000-00805f9b34fb', label: 'Model'),
      (uuid: '00002a26-0000-1000-8000-00805f9b34fb', label: 'Firmware'),
      (uuid: '00002a29-0000-1000-8000-00805f9b34fb', label: 'Üretici'),
    ];

    BleService? deviceInformationService;
    for (final service in services) {
      if (BleUuidParser.string(service.uuid) == serviceUuid) {
        deviceInformationService = service;
        break;
      }
    }
    if (deviceInformationService == null) return;

    for (final field in fields) {
      final isReadable = deviceInformationService.characteristics.any(
        (characteristic) =>
            BleUuidParser.string(characteristic.uuid) == field.uuid &&
            characteristic.properties.contains(CharacteristicProperty.read),
      );
      if (!isReadable || _connectedDeviceId != deviceId) continue;

      try {
        final value = await UniversalBle.read(
          deviceId,
          deviceInformationService.uuid,
          field.uuid,
          timeout: const Duration(seconds: 3),
        );
        final text = String.fromCharCodes(
          value,
        ).replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
        _log(
          'CİHAZ BİLGİSİ ${field.label}: '
          '${text.isEmpty ? '(boş)' : text}',
        );
      } catch (error) {
        _log(
          'Cihaz bilgisi okunamadı (${field.label}): $error',
          level: InsoleBluetoothDebugLevel.warning,
        );
      }
    }
  }

  Future<void> _pairIfRequired(String deviceId) async {
    if (!BleCapabilities.hasSystemPairingApi) {
      _log('Sistem eşleştirme API’si yok; işletim sistemi otomatik yönetecek.');
      return;
    }

    final isPaired = await UniversalBle.isPaired(
      deviceId,
      timeout: const Duration(seconds: 10),
    );
    _log(
      'Eşleştirme durumu: ${isPaired == true ? 'eşleştirilmiş' : 'eşleştirilmemiş'}',
    );
    if (isPaired == true) return;

    _log(
      'Sistem eşleştirmesi başlatılıyor; PIN sorulursa '
      '${InsoleProtocolConstants.pairingCode} girin.',
    );
    await UniversalBle.pair(deviceId, timeout: const Duration(seconds: 45));
    _log(
      'Sistem eşleştirmesi tamamlandı.',
      level: InsoleBluetoothDebugLevel.success,
    );
  }

  void _handleStreamCharacteristicValue(
    String deviceId,
    String characteristicId,
    Uint8List value,
  ) {
    _acceptCharacteristicValue(deviceId, characteristicId, value);
  }

  void _acceptCharacteristicValue(
    String deviceId,
    String characteristicId,
    Uint8List value,
  ) {
    final connectedDeviceId = _connectedDeviceId;
    if (connectedDeviceId == null || value.isEmpty) return;

    final isCurrentDevice =
        connectedDeviceId.toLowerCase() == deviceId.toLowerCase();
    final normalizedCharacteristic = BleUuidParser.string(characteristicId);
    final isActiveInputChannel =
        _activeChannel != null &&
        BleUuidParser.string(_activeChannel!.characteristicUuid) ==
            normalizedCharacteristic;
    if (!isCurrentDevice || !isActiveInputChannel) return;

    _recordIncomingValueEvent(deviceId, characteristicId, value);
    _stopNotificationWatchdog();
    _emitCharacteristicValue(value);
  }

  void _startNotificationWatchdog() {
    _notificationWatchdog?.cancel();
    if (_receivedValueEventCount > 0) return;
    final activeChannel = _activeChannel;
    if (activeChannel == null) return;
    _log(
      'Seçilen kanal dinleniyor; ilk sensör paketi bekleniyor: '
      '${activeChannel.characteristicUuid}',
    );
    _notificationWatchdog = Timer(const Duration(seconds: 5), () {
      _notificationWatchdog = null;
      if (_receivedValueEventCount != 0 || _connectedDeviceId == null) return;
      _log(
        '5 saniye içinde seçilen kanaldan bildirim gelmedi. '
        'Başka bir test kanalı seçebilirsiniz.',
        level: InsoleBluetoothDebugLevel.warning,
      );
    });
  }

  void _stopNotificationWatchdog() {
    _notificationWatchdog?.cancel();
    _notificationWatchdog = null;
  }

  void _recordIncomingValueEvent(
    String deviceId,
    String characteristicId,
    Uint8List value,
  ) {
    _receivedValueEventCount++;
    if (_receivedValueEventCount > 10 && _receivedValueEventCount % 20 != 0) {
      return;
    }

    final preview = value
        .take(24)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
    _log(
      'RX #$_receivedValueEventCount | cihaz=$deviceId | '
      'karakteristik=$characteristicId | ${value.length} bayt | $preview',
      level: InsoleBluetoothDebugLevel.data,
    );
  }

  void _emitCharacteristicValue(Uint8List value) {
    if (!_dataController.isClosed && value.isNotEmpty) {
      _dataController.add(Uint8List.fromList(value));
    }
  }

  @override
  Future<void> disconnect() async {
    _log('Bağlantıyı kesme istendi.');
    await _releaseDeviceConnection(disconnectDevice: true);
    _emitState(InsoleBluetoothConnectionState.disconnected);
    _log('Bağlantı kapatıldı.');
  }

  void _handleScanResult(BleDevice result) {
    // Aynı ekranda tarama, sol bağlantı ve sağ bağlantı için ayrı servis
    // örnekleri bulunur. Sonuçları yalnızca taramayı başlatan örnek toplar.
    if (_currentState != InsoleBluetoothConnectionState.scanning) return;
    final name = (result.name ?? '').trim();
    final compactName = name.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final matchesName = compactName.startsWith('JYSB');
    final supportedServices = InsoleProtocolConstants.supportedServiceUuids
        .map(BleUuidParser.string)
        .toSet();
    final matchesService = result.services
        .map(BleUuidParser.string)
        .any(supportedServices.contains);
    if (!matchesName && !matchesService) {
      return;
    }

    final isNewDevice = !_scanResultsById.containsKey(result.deviceId);
    final previous = _scanResultsById[result.deviceId];
    if (name.isEmpty && (previous?.name ?? '').trim().isNotEmpty) {
      result.name = previous!.name;
    }
    if (previous != null) {
      result.services = {
        ...previous.services.map(BleUuidParser.string),
        ...result.services.map(BleUuidParser.string),
      }.toList(growable: false);
    }
    _scanResultsById[result.deviceId] = result;
    if (isNewDevice) {
      final displayName = (result.name ?? '').trim();
      _log(
        'Cihaz bulundu: '
        'ad=${displayName.isEmpty ? '(reklamda ad yok)' : displayName}, '
        'kimlik=${result.deviceId}, RSSI=${result.rssi ?? -127} dBm, '
        'eşleşme=${matchesName ? 'ad' : 'servis UUID’si'}',
        level: InsoleBluetoothDebugLevel.success,
      );
    }
    final devices =
        _scanResultsById.values
            .map(
              (device) => InsoleBluetoothDevice(
                id: device.deviceId,
                name: (device.name ?? '').trim().isEmpty
                    ? 'JYS_B_ servis cihazı'
                    : device.name!.trim(),
                rssi: device.rssi ?? -127,
              ),
            )
            .toList()
          ..sort((a, b) => b.rssi.compareTo(a.rssi));

    if (!_scanController.isClosed) {
      _scanController.add(List<InsoleBluetoothDevice>.unmodifiable(devices));
    }
  }

  Future<void> _releaseDeviceConnection({
    required bool disconnectDevice,
  }) async {
    _stopNotificationWatchdog();
    final deviceId = _connectedDeviceId;
    await _releaseInputChannel(unsubscribe: true);
    await _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = null;

    _connectedDeviceId = null;
    _availableChannels = const [];
    if (!_channelController.isClosed) {
      _channelController.add(const <InsoleBluetoothChannel>[]);
    }
    if (disconnectDevice && deviceId != null) {
      try {
        await UniversalBle.disconnect(
          deviceId,
          timeout: const Duration(seconds: 8),
        );
      } catch (error) {
        _log(
          'Fiziksel bağlantı kapatılırken hata: $error',
          level: InsoleBluetoothDebugLevel.warning,
        );
      }
    }
  }

  Future<void> _releaseInputChannel({required bool unsubscribe}) async {
    _stopNotificationWatchdog();
    final deviceId = _connectedDeviceId;
    final channel = _activeChannel;
    _activeChannel = null;

    if (unsubscribe && deviceId != null && channel != null) {
      try {
        await UniversalBle.unsubscribe(
          deviceId,
          channel.serviceUuid,
          channel.characteristicUuid,
        );
        _log('Kanal dinlemesi kapatıldı: ${channel.characteristicUuid}');
      } catch (error) {
        _log(
          'Kanal dinlemesi kapatılırken hata '
          '(${channel.characteristicUuid}): $error',
          level: InsoleBluetoothDebugLevel.warning,
        );
      }
    }

    await _valueSubscription?.cancel();
    _valueSubscription = null;
  }

  Future<void> _handleUnexpectedDisconnect() async {
    _stopNotificationWatchdog();
    _activeChannel = null;
    _availableChannels = const [];
    await _valueSubscription?.cancel();
    _valueSubscription = null;
    if (!_channelController.isClosed) {
      _channelController.add(const <InsoleBluetoothChannel>[]);
    }
    _connectedDeviceId = null;
    _emitState(InsoleBluetoothConnectionState.disconnected);
  }

  void _log(
    String message, {
    InsoleBluetoothDebugLevel level = InsoleBluetoothDebugLevel.info,
  }) {
    if (_debugController.isClosed) return;
    _debugController.add(
      InsoleBluetoothDebugMessage(
        timestamp: DateTime.now(),
        level: level,
        message: message,
      ),
    );
  }

  void _emitState(InsoleBluetoothConnectionState state) {
    _currentState = state;
    if (!_stateController.isClosed) _stateController.add(state);
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('Bluetooth servisi kapatılmış.');
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopScan();
    await _releaseDeviceConnection(disconnectDevice: true);
    await _scanSubscription?.cancel();
    await _scanController.close();
    await _stateController.close();
    await _channelController.close();
    await _dataController.close();
    await _debugController.close();
  }
}
