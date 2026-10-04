import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/screens/dashboard/devices/devices_screen.dart';
import 'package:oy_site/services/bluetooth/insole_bluetooth_service.dart';
import 'package:oy_site/services/bluetooth/insole_protocol.dart';
import 'package:oy_site/services/scanner/oy_scanner_automation_service.dart';

void main() {
  testWidgets('iki iç taban ayrı bağlanır ve kanalları ayrı seçilir', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scanner = _FakeInsoleBluetoothService();
    final leftService = _FakeInsoleBluetoothService();
    final rightService = _FakeInsoleBluetoothService();
    addTearDown(() async {
      await scanner.close();
      await leftService.close();
      await rightService.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DevicesScreen(
            pressureRepository: Object(),
            insoleScannerBluetoothService: scanner,
            insoleBluetoothService: leftService,
            rightInsoleBluetoothService: rightService,
          ),
        ),
      ),
    );

    expect(find.text('Cihazlar'), findsOneWidget);
    expect(find.text('Basınç Sensör Pedi'), findsOneWidget);
    expect(find.text('Basınç Sensörlü İç Taban'), findsOneWidget);

    await tester.tap(find.text('Basınç Sensörlü İç Taban'));
    await tester.pumpAndSettle();

    expect(find.text('Çift iç taban ve kanal testi'), findsOneWidget);
    expect(find.text('Bluetooth debug günlüğü'), findsOneWidget);
    expect(find.text('İki Tabanı Ara'), findsOneWidget);

    scanner.emitDebug('Çift cihaz testi başladı');
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Bluetooth debug günlüğü'), 300);
    await tester.pump();
    expect(find.textContaining('Çift cihaz testi başladı'), findsOneWidget);

    tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, 'İki Tabanı Ara'),
        )
        .onPressed!();
    await tester.pump();
    scanner.emitDevices(const [
      InsoleBluetoothDevice(id: 'insole-1', name: 'JYS_B_001', rssi: -39),
      InsoleBluetoothDevice(id: 'insole-2', name: 'JYS_B_002', rssi: -42),
    ]);
    await tester.pump();

    expect(find.text('JYS_B_001'), findsOneWidget);
    expect(find.text('JYS_B_002'), findsOneWidget);

    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('assign-left-insole-1')),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    tester
        .widget<OutlinedButton>(
          find.byKey(const ValueKey('assign-right-insole-2')),
        )
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(leftService.connectedDeviceId, 'insole-1');
    expect(rightService.connectedDeviceId, 'insole-2');
    expect(find.text('Protokoldeki basınç kanalı'), findsNWidgets(2));

    tester
        .widget<FilledButton>(find.byKey(const ValueKey('left-channel-0')))
        .onPressed!();
    await tester.pump();
    tester
        .widget<FilledButton>(find.byKey(const ValueKey('right-channel-0')))
        .onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    expect(leftService.selectedChannel, _FakeInsoleBluetoothService.primary);
    expect(rightService.selectedChannel, _FakeInsoleBluetoothService.primary);
    expect(find.text('Dinleniyor'), findsNWidgets(2));

    leftService.emitData(
      _buildFrame(List<int>.generate(108, (index) => index)),
    );
    rightService.emitData(_buildFrame(List<int>.filled(108, 12)));
    await tester.pump();

    expect(find.text('9×12'), findsNWidgets(2));
    expect(find.text('Ham Paket'), findsNWidgets(2));
    expect(find.text('Ham Bayt'), findsNWidgets(2));

    final startButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ölçümü Başlat'),
    );
    expect(startButton.onPressed, isNotNull);
    startButton.onPressed!();
    await tester.pump();
    expect(find.text('Ölçümü Durdur'), findsOneWidget);

    leftService.emitData(_buildFrame(List<int>.filled(108, 21)));
    rightService.emitData(_buildFrame(List<int>.filled(108, 22)));
    await tester.pump();
    tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Ölçümü Durdur'),
        )
        .onPressed!();
    await tester.pump();

    expect(find.textContaining('Sol 1 • Sağ 1 kare'), findsOneWidget);
  });

  testWidgets('OY Scanner kartı otomasyon panelini açar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1300, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final scannerAutomationService = _FakeOYScannerAutomationService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DevicesScreen(
            pressureRepository: Object(),
            scannerAutomationService: scannerAutomationService,
          ),
        ),
      ),
    );

    expect(find.text('OY Scanner'), findsOneWidget);

    await tester.tap(find.text('OY Scanner'));
    await tester.pumpAndSettle();

    expect(find.text('Otomatik tarama'), findsOneWidget);
    expect(find.text('Hastalar'), findsOneWidget);

    await tester.tap(find.text('Durum'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(scannerAutomationService.lastArguments, const [
      '--silent',
      '--status',
    ]);
    expect(find.textContaining('Durum kontrolü tamamlandı'), findsWidgets);
  });
}

class _FakeInsoleBluetoothService implements InsoleBluetoothService {
  static const primary = InsoleBluetoothChannel(
    serviceUuid: InsoleProtocolConstants.serviceUuid,
    characteristicUuid: InsoleProtocolConstants.notifyCharacteristicUuid,
    usesIndications: false,
    isPreferred: true,
  );
  static const alternative = InsoleBluetoothChannel(
    serviceUuid: InsoleProtocolConstants.diagnosticServiceUuid,
    characteristicUuid: '5833ff03-9b8b-5191-6142-22a4536ef123',
    usesIndications: false,
    isPreferred: false,
  );

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

  String? connectedDeviceId;
  InsoleBluetoothChannel? selectedChannel;

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
  Future<bool> isSupported() async => true;

  @override
  Future<void> startScan() async {
    _stateController.add(InsoleBluetoothConnectionState.scanning);
  }

  @override
  Future<void> stopScan() async {
    _stateController.add(InsoleBluetoothConnectionState.disconnected);
  }

  @override
  Future<void> connect(String deviceId) async {
    connectedDeviceId = deviceId;
    _stateController.add(InsoleBluetoothConnectionState.connecting);
    _channelController.add(const [primary, alternative]);
    _stateController.add(InsoleBluetoothConnectionState.connected);
  }

  @override
  Future<void> selectChannel(InsoleBluetoothChannel channel) async {
    selectedChannel = channel;
  }

  @override
  Future<void> disconnect() async {
    connectedDeviceId = null;
    selectedChannel = null;
    _channelController.add(const []);
    _stateController.add(InsoleBluetoothConnectionState.disconnected);
  }

  void emitDevices(List<InsoleBluetoothDevice> devices) {
    _scanController.add(devices);
  }

  void emitData(Uint8List data) {
    _dataController.add(data);
  }

  void emitDebug(String message) {
    _debugController.add(
      InsoleBluetoothDebugMessage(
        timestamp: DateTime(2026, 9, 7, 12, 34, 56),
        level: InsoleBluetoothDebugLevel.info,
        message: message,
      ),
    );
  }

  @override
  Future<void> dispose() async {}

  Future<void> close() async {
    await _scanController.close();
    await _stateController.close();
    await _channelController.close();
    await _dataController.close();
    await _debugController.close();
  }
}

Uint8List _buildFrame(List<int> content) {
  final length = content.length + 1;
  final prefix = <int>[
    0x55,
    0xAA,
    length & 0xFF,
    (length >> 8) & 0xFF,
    InsoleProtocolConstants.pressureFunctionCode,
    ...content,
  ];
  return Uint8List.fromList([
    ...prefix,
    InsoleProtocolParser.checksumFor(prefix),
    InsoleProtocolConstants.frameTail,
  ]);
}

class _FakeOYScannerAutomationService implements OYScannerAutomationService {
  List<String> lastArguments = const [];

  @override
  Future<List<OYScannerGeneratedFile>> listGeneratedFiles({
    DateTime? since,
  }) async {
    return const [];
  }

  @override
  Future<void> openGeneratedFile(String path) async {}

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<OYScannerAutomationResult> runCommand(
    String label,
    List<String> arguments,
  ) async {
    lastArguments = List<String>.from(arguments);
    final now = DateTime(2026, 9, 25, 17, 20);
    return OYScannerAutomationResult(
      success: true,
      commandLabel: label,
      executablePath: r'C:\OYScanner\OYAutomationPilot.exe',
      arguments: arguments,
      exitCode: 0,
      stdoutText: 'stage=SelectGender',
      stderrText: '',
      errorMessage: null,
      startedAt: now,
      finishedAt: now,
    );
  }
}
