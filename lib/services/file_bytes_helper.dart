// ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import: dart:io is only available on non-web platforms.
import 'file_bytes_helper_stub.dart'
    if (dart.library.io) 'file_bytes_helper_io.dart';

/// Reads raw bytes from a local file path.
/// Returns null on web (paths are not available on web).
Future<Uint8List?> readBytesFromPath(String path) async {
  if (kIsWeb) return null;
  return readBytesFromPathImpl(path);
}
