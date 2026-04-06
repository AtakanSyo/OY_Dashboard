import 'dart:typed_data';

/// Abstract interface for serial port communication.
/// Desktop uses flutter_libserialport; web uses a no-op stub.
abstract class SerialPortService {
  /// Returns available port names (e.g. COM3, /dev/ttyUSB0).
  List<String> get availablePorts;

  /// Opens the port and starts streaming raw bytes.
  void connect(String portName, void Function(Uint8List) onData);

  /// Closes the port and cleans up resources.
  void disconnect();

  /// Whether a port is currently open.
  bool get isConnected;
}
