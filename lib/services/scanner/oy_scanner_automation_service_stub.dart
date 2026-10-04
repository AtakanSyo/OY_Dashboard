import 'oy_scanner_automation_service_base.dart';

OYScannerAutomationService createOYScannerAutomationService() {
  return const _UnsupportedOYScannerAutomationService();
}

class _UnsupportedOYScannerAutomationService
    implements OYScannerAutomationService {
  const _UnsupportedOYScannerAutomationService();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<OYScannerAutomationResult> runCommand(
    String label,
    List<String> arguments,
  ) async {
    final now = DateTime.now();
    return OYScannerAutomationResult(
      success: false,
      commandLabel: label,
      executablePath: '',
      arguments: arguments,
      exitCode: null,
      stdoutText: '',
      stderrText: '',
      errorMessage:
          'OY Scanner otomasyonu yalnızca Windows masaüstü uygulamasında kullanılabilir.',
      startedAt: now,
      finishedAt: now,
    );
  }

  @override
  Future<List<OYScannerGeneratedFile>> listGeneratedFiles({
    DateTime? since,
  }) async {
    return const [];
  }

  @override
  Future<void> openGeneratedFile(String path) async {}
}
