class OYScannerAutomationResult {
  final bool success;
  final String commandLabel;
  final String executablePath;
  final List<String> arguments;
  final int? exitCode;
  final String stdoutText;
  final String stderrText;
  final String? errorMessage;
  final DateTime startedAt;
  final DateTime finishedAt;

  const OYScannerAutomationResult({
    required this.success,
    required this.commandLabel,
    required this.executablePath,
    required this.arguments,
    required this.exitCode,
    required this.stdoutText,
    required this.stderrText,
    required this.errorMessage,
    required this.startedAt,
    required this.finishedAt,
  });

  String get summary {
    if (success) return '$commandLabel tamamlandı';
    final message = errorMessage ?? stderrText.trim();
    if (message.isEmpty) return '$commandLabel tamamlanamadı';
    return message;
  }
}

class OYScannerGeneratedFile {
  final String path;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime modifiedAt;

  const OYScannerGeneratedFile({
    required this.path,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.modifiedAt,
  });
}

abstract class OYScannerAutomationService {
  Future<bool> isSupported();
  Future<OYScannerAutomationResult> runCommand(
    String label,
    List<String> arguments,
  );
  Future<List<OYScannerGeneratedFile>> listGeneratedFiles({DateTime? since});
  Future<void> openGeneratedFile(String path);
}
