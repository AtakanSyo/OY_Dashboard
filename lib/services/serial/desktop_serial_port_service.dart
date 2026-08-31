import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'serial_port_service.dart';

class DesktopSerialPortService implements SerialPortService {
  SerialPort? _port;
  SerialPortReader? _reader;

  @override
  List<String> get availablePorts => SerialPort.availablePorts;

  @override
  bool get isConnected => _port?.isOpen ?? false;

  @override
  void connect(String portName, void Function(Uint8List) onData) {
    disconnect();

    _port = SerialPort(portName);
    _port!.openReadWrite();

    _port!.config = SerialPortConfig()
      ..baudRate = 460800
      ..bits = 8
      ..stopBits = 1
      ..parity = 0;

    _reader = SerialPortReader(_port!);
    _reader!.stream.listen(onData);
  }

  @override
  void disconnect() {
    _reader?.close();
    _port?.close();
    _reader = null;
    _port = null;
  }
}

SerialPortService createSerialPortService() => DesktopSerialPortService();
