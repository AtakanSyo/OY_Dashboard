import 'dart:typed_data';
import 'serial_port_service.dart';

/// No-op stub used on web builds where serial ports are not available.
class WebSerialPortService implements SerialPortService {
  @override
  List<String> get availablePorts => [];

  @override
  bool get isConnected => false;

  @override
  void connect(String portName, void Function(Uint8List) onData) {
    // Serial ports are not supported on web.
  }

  @override
  void disconnect() {
    // No-op on web.
  }
}

SerialPortService createSerialPortService() => WebSerialPortService();
