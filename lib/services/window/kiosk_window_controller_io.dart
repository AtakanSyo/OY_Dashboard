import 'dart:io';

import 'package:flutter/services.dart';

import 'kiosk_window_controller_base.dart';

KioskWindowController createKioskWindowController() {
  return const DesktopKioskWindowController();
}

class DesktopKioskWindowController implements KioskWindowController {
  static const MethodChannel _channel = MethodChannel('oy_site/kiosk_window');

  const DesktopKioskWindowController();

  @override
  Future<void> enterFullscreen() async {
    if (!Platform.isWindows) return;
    await _invokeSafely('enterFullscreen');
  }

  @override
  Future<void> exitFullscreen() async {
    if (!Platform.isWindows) return;
    await _invokeSafely('exitFullscreen');
  }

  Future<void> _invokeSafely(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Eski build çalışıyorsa kanal yoktur; kiosk ekranı yine normal çalışsın.
    } on PlatformException {
      // Fullscreen kiosk konfor özelliği; başarısız olursa ana akışı bozmasın.
    }
  }
}
