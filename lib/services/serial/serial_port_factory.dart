export 'serial_port_service.dart';

// Dart conditional imports: the compiler picks exactly one of these files.
// On web builds, flutter_libserialport is never imported.
// Both files export createSerialPortService() which pressure_screen calls.
export 'web_serial_port_service.dart'
    if (dart.library.io) 'desktop_serial_port_service.dart';
