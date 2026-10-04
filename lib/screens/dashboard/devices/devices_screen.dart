import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/screens/dashboard/devices/insole_measurement_view.dart';
import 'package:oy_site/screens/dashboard/devices/scanner/oy_scanner_control_view.dart';
import 'package:oy_site/screens/dashboard/measurements/pressure_screen.dart';
import 'package:oy_site/services/bluetooth/insole_bluetooth_service.dart';
import 'package:oy_site/services/scanner/oy_scanner_automation_service.dart';

enum MeasurementDeviceType { pressurePad, bluetoothInsole, oyScanner }

class DevicesScreen extends StatefulWidget {
  final AppUser? currentUser;
  final dynamic pressureRepository;
  final InsoleBluetoothService? insoleBluetoothService;
  final InsoleBluetoothService? insoleScannerBluetoothService;
  final InsoleBluetoothService? rightInsoleBluetoothService;
  final OYScannerAutomationService? scannerAutomationService;

  const DevicesScreen({
    super.key,
    this.currentUser,
    required this.pressureRepository,
    this.insoleBluetoothService,
    this.insoleScannerBluetoothService,
    this.rightInsoleBluetoothService,
    this.scannerAutomationService,
  });

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  MeasurementDeviceType? _selectedDevice;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F8F8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cihazlar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Ölçümde kullanacağınız cihazı seçin.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 1040
                            ? 3
                            : constraints.maxWidth >= 720
                            ? 2
                            : 1;
                        final cardWidth = columns == 1
                            ? constraints.maxWidth
                            : (constraints.maxWidth - (14 * (columns - 1))) /
                                  columns;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _DeviceChoiceCard(
                                icon: Icons.grid_view_rounded,
                                title: 'Basınç Sensör Pedi',
                                description:
                                    'Mevcut 32×64 sensör pedine USB/seri port ile bağlanın.',
                                badge: 'USB',
                                isSelected:
                                    _selectedDevice ==
                                    MeasurementDeviceType.pressurePad,
                                onTap: () => _selectDevice(
                                  MeasurementDeviceType.pressurePad,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _DeviceChoiceCard(
                                icon: Icons.bluetooth_connected,
                                title: 'Basınç Sensörlü İç Taban',
                                description:
                                    'JYS_B_ serisi iç tabana Bluetooth ile bağlanın.',
                                badge: 'Bluetooth',
                                isSelected:
                                    _selectedDevice ==
                                    MeasurementDeviceType.bluetoothInsole,
                                onTap: () => _selectDevice(
                                  MeasurementDeviceType.bluetoothInsole,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _DeviceChoiceCard(
                                icon: Icons.document_scanner_outlined,
                                title: 'OY Scanner',
                                description:
                                    'Ayak tarayıcı akışını OY Dashboard üzerinden yönetin.',
                                badge: '3D Tarama',
                                isSelected:
                                    _selectedDevice ==
                                    MeasurementDeviceType.oyScanner,
                                onTap: () => _selectDevice(
                                  MeasurementDeviceType.oyScanner,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: switch (_selectedDevice) {
                MeasurementDeviceType.pressurePad => PressureScreen(
                  key: const ValueKey('pressure-pad'),
                  pressureRepository: widget.pressureRepository,
                ),
                MeasurementDeviceType.bluetoothInsole => InsoleMeasurementView(
                  key: const ValueKey('bluetooth-insole'),
                  bluetoothService: widget.insoleBluetoothService,
                  scannerBluetoothService: widget.insoleScannerBluetoothService,
                  rightBluetoothService: widget.rightInsoleBluetoothService,
                ),
                MeasurementDeviceType.oyScanner => OYScannerControlView(
                  key: const ValueKey('oy-scanner'),
                  currentUser: widget.currentUser,
                  automationService: widget.scannerAutomationService,
                ),
                null => const _DeviceSelectionPrompt(
                  key: ValueKey('device-selection-prompt'),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectDevice(MeasurementDeviceType device) {
    if (_selectedDevice == device) return;
    setState(() => _selectedDevice = device);
  }
}

class _DeviceSelectionPrompt extends StatelessWidget {
  const _DeviceSelectionPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F7F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sensors_outlined,
                size: 36,
                color: Color(0xFF087F73),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Ölçüme başlamak için bir cihaz seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Bağlantı ve kontrol seçenekleri seçtiğiniz cihaza göre açılacaktır.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeviceChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF087F73) : Colors.grey[700]!;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF11998E) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x2211998E),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.chevron_right,
                color: isSelected ? const Color(0xFF11998E) : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
