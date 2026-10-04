import 'kiosk_window_controller_base.dart';

KioskWindowController createKioskWindowController() {
  return const StubKioskWindowController();
}

class StubKioskWindowController implements KioskWindowController {
  const StubKioskWindowController();

  @override
  Future<void> enterFullscreen() async {}

  @override
  Future<void> exitFullscreen() async {}
}
