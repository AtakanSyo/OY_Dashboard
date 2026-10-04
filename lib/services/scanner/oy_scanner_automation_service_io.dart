import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

import 'oy_scanner_automation_service_base.dart';

OYScannerAutomationService createOYScannerAutomationService({
  String? executablePath,
}) {
  return DesktopOYScannerAutomationService(eFootExecutablePath: executablePath);
}

class DesktopOYScannerAutomationService implements OYScannerAutomationService {
  final String? eFootExecutablePath;

  const DesktopOYScannerAutomationService({this.eFootExecutablePath});

  static const _defaultEFootPaths = <String>[
    r'D:\eFoot V3.2.112\eFoot-touch.exe',
    r'D:\eFoot V3.2.112\eFoot.exe',
  ];

  @override
  Future<bool> isSupported() async => Platform.isWindows;

  @override
  Future<OYScannerAutomationResult> runCommand(
    String label,
    List<String> arguments,
  ) async {
    final startedAt = DateTime.now();
    if (!Platform.isWindows) {
      return _result(
        label,
        arguments,
        startedAt,
        success: false,
        errorMessage:
            'OY Scanner otomasyonu yalnızca Windows üzerinde çalışır.',
      );
    }

    try {
      final output = StringBuffer();
      final command = _ScannerCommand.parse(arguments);
      if (command.silent) {
        _WindowsAutomation.enableDashboardShield();
      }
      var window = _WindowsAutomation.findEFootWindow();

      if (command.shouldLaunchWhenMissing && window == null) {
        final launched = await _launchEFoot();
        output.writeln(
          launched ? 'eFoot başlatıldı.' : 'eFoot çalıştırılamadı.',
        );
        window = await _waitForEFootWindow();
      }

      if (window == null) {
        return _result(
          label,
          arguments,
          startedAt,
          success: false,
          stdoutText: output.toString(),
          errorMessage:
              'eFoot penceresi bulunamadı. eFoot açık değilse önce Ekranı Aç komutunu deneyin.',
        );
      }

      output.writeln('eFoot bulundu: ${window.title}');
      output.writeln('Pencere: ${window.rect}');
      output.writeln(
        command.silent
            ? 'Gizli mod: Dashboard en üstte tutulacak, eFoot öne alınmayacak.'
            : 'Görünür mod: eFoot öne alınacak.',
      );

      if (command.silent) {
        final shielded = _WindowsAutomation.enableDashboardShield();
        output.writeln(
          shielded
              ? 'Dashboard kiosk kalkanı etkin.'
              : 'Dashboard penceresi kalkan için bulunamadı.',
        );
      } else {
        _WindowsAutomation.restoreAndFocus(window.handle);
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }

      switch (command.action) {
        case _ScannerAction.status:
          output.writeln('Durum: pencere erişilebilir.');
        case _ScannerAction.wake:
          _click(window, 0.50, 0.50, command.silent);
          output.writeln('Tanıtım ekranı için merkez tıklaması gönderildi.');
        case _ScannerAction.startScan:
          final x = command.gender == 'female' ? 0.559 : 0.441;
          _click(window, x, 0.929, command.silent);
          output.writeln(
            'Tarama başlatma tıklaması gönderildi: ${command.gender}.',
          );
        case _ScannerAction.fillForm:
          await _fillForm(window, command, output);
          if (command.next) {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            _click(window, 0.50, 0.929, command.silent);
            output.writeln('Next tıklaması gönderildi.');
          }
        case _ScannerAction.export:
          _click(window, 0.50, 0.929, command.silent);
          output.writeln('Export adayı tıklaması gönderildi.');
        case _ScannerAction.home:
          _click(window, 0.067, 0.057, command.silent);
          output.writeln('Home tıklaması gönderildi.');
      }
      return _result(
        label,
        arguments,
        startedAt,
        success: true,
        stdoutText: output.toString(),
      );
    } catch (error) {
      return _result(
        label,
        arguments,
        startedAt,
        success: false,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<List<OYScannerGeneratedFile>> listGeneratedFiles({
    DateTime? since,
  }) async {
    final root = Directory(r'D:\LSF350\2026');
    if (!root.existsSync()) return const [];

    final files = <File>[];
    final allowed = <String>{'.pdf', '.zip', '.stl', '.asc', '.bmp', '.doc'};
    try {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final stat = await entity.stat();
        if (since != null && stat.modified.isBefore(since)) continue;
        final extension = _extensionOf(entity.path).toLowerCase();
        if (!allowed.contains(extension)) continue;
        files.add(entity);
      }
    } catch (_) {
      return const [];
    }

    if (files.isEmpty) return const [];

    final newestDirectory = files.map((file) => file.parent.path).fold<String?>(
      null,
      (current, path) {
        if (current == null) return path;
        final currentNewest = files
            .where((file) => file.parent.path == current)
            .map((file) => file.statSync().modified)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        final candidateNewest = files
            .where((file) => file.parent.path == path)
            .map((file) => file.statSync().modified)
            .reduce((a, b) => a.isAfter(b) ? a : b);
        return candidateNewest.isAfter(currentNewest) ? path : current;
      },
    );

    final visibleFiles =
        files.where((file) => file.parent.path == newestDirectory).map((file) {
          final stat = file.statSync();
          final name = file.uri.pathSegments.isEmpty
              ? file.path
              : Uri.decodeComponent(file.uri.pathSegments.last);
          return OYScannerGeneratedFile(
            path: file.path,
            name: name,
            extension: _extensionOf(file.path),
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
          );
        }).toList()..sort((a, b) => a.name.compareTo(b.name));

    return visibleFiles;
  }

  @override
  Future<void> openGeneratedFile(String path) async {
    await Process.start('explorer.exe', [path]);
  }

  static String _extensionOf(String path) {
    final index = path.lastIndexOf('.');
    if (index < 0 || index == path.length - 1) return '';
    return path.substring(index);
  }

  Future<bool> _launchEFoot() async {
    final candidates = <String>[
      if (eFootExecutablePath != null && eFootExecutablePath!.trim().isNotEmpty)
        eFootExecutablePath!,
      ..._defaultEFootPaths,
    ];

    for (final candidate in candidates) {
      final file = File(candidate);
      if (!file.existsSync()) continue;
      await Process.start(file.absolute.path, const []);
      return true;
    }

    return false;
  }

  Future<_WindowInfo?> _waitForEFootWindow() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final window = _WindowsAutomation.findEFootWindow();
      if (window != null) return window;
    }

    return null;
  }

  void _click(_WindowInfo window, double x, double y, bool silent) {
    if (silent) {
      _WindowsAutomation.backgroundClickRelative(window, x, y);
      return;
    }
    _WindowsAutomation.clickRelative(window, x, y);
  }

  Future<void> _fillForm(
    _WindowInfo window,
    _ScannerCommand command,
    StringBuffer output,
  ) async {
    final fields = <({String label, String value})>[
      (label: 'Name', value: command.name),
      (label: 'Tel', value: command.tel),
      (label: 'Age', value: command.age),
      (label: 'Height', value: command.height),
      (label: 'Weight', value: command.weight),
      (label: 'ShoeSize', value: command.shoeSize),
    ];

    _click(window, 0.406, 0.402, command.silent);
    await Future<void>.delayed(const Duration(milliseconds: 180));

    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      await Clipboard.setData(ClipboardData(text: field.value));
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (command.silent) {
        _WindowsAutomation.backgroundReplaceText(window.handle, field.value);
      } else {
        _WindowsAutomation.replaceFocusedTextFromClipboard();
      }
      output.writeln('${field.label} yazıldı.');
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (i < fields.length - 1) {
        if (command.silent) {
          _WindowsAutomation.backgroundPressTab(window.handle);
        } else {
          _WindowsAutomation.pressTab();
        }
        await Future<void>.delayed(const Duration(milliseconds: 160));
      }
    }
  }

  OYScannerAutomationResult _result(
    String label,
    List<String> arguments,
    DateTime startedAt, {
    required bool success,
    String stdoutText = '',
    String stderrText = '',
    String? errorMessage,
  }) {
    return OYScannerAutomationResult(
      success: success,
      commandLabel: label,
      executablePath: 'OY Dashboard Windows otomasyonu',
      arguments: arguments,
      exitCode: success ? 0 : 1,
      stdoutText: stdoutText,
      stderrText: stderrText,
      errorMessage: errorMessage,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );
  }
}

enum _ScannerAction { status, wake, startScan, fillForm, export, home }

class _ScannerCommand {
  final _ScannerAction action;
  final String gender;
  final bool next;
  final String name;
  final String tel;
  final String age;
  final String height;
  final String weight;
  final String shoeSize;
  final bool silent;

  const _ScannerCommand({
    required this.action,
    this.gender = 'male',
    this.next = false,
    this.name = 'OY Test',
    this.tel = '5550000000',
    this.age = '30',
    this.height = '175',
    this.weight = '70',
    this.shoeSize = '42',
    this.silent = false,
  });

  bool get shouldLaunchWhenMissing =>
      action == _ScannerAction.wake || action == _ScannerAction.status;

  static _ScannerCommand parse(List<String> arguments) {
    _ScannerAction action = _ScannerAction.status;
    var gender = 'male';
    var next = false;
    var name = 'OY Test';
    var tel = '5550000000';
    var age = '30';
    var height = '175';
    var weight = '70';
    var shoeSize = '42';
    var silent = false;

    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      String nextValue() {
        if (i + 1 >= arguments.length) return '';
        return arguments[++i];
      }

      switch (arg) {
        case '--silent':
          silent = true;
        case '--status':
          action = _ScannerAction.status;
        case '--wake':
          action = _ScannerAction.wake;
        case '--start-scan':
          action = _ScannerAction.startScan;
        case '--fill-form':
          action = _ScannerAction.fillForm;
        case '--export':
          action = _ScannerAction.export;
        case '--home':
          action = _ScannerAction.home;
        case '--next':
          next = true;
        case '--gender':
          final value = nextValue().toLowerCase();
          gender = value == 'female' ? 'female' : 'male';
        case '--name':
          name = nextValue();
        case '--tel':
          tel = nextValue();
        case '--age':
          age = nextValue();
        case '--height':
          height = nextValue();
        case '--weight':
          weight = nextValue();
        case '--shoe-size':
          shoeSize = nextValue();
      }
    }

    return _ScannerCommand(
      action: action,
      gender: gender,
      next: next,
      name: name,
      tel: tel,
      age: age,
      height: height,
      weight: weight,
      shoeSize: shoeSize,
      silent: silent,
    );
  }
}

class _WindowsAutomation {
  static final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');

  static final _enumWindows = _user32
      .lookupFunction<
        Int32 Function(
          Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>,
          IntPtr,
        ),
        int Function(
          Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>>,
          int,
        )
      >('EnumWindows');

  static final _isWindowVisible = _user32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'IsWindowVisible',
      );

  static final _getWindowText = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<Utf16>, Int32),
        int Function(int, Pointer<Utf16>, int)
      >('GetWindowTextW');

  static final _getClassName = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<Utf16>, Int32),
        int Function(int, Pointer<Utf16>, int)
      >('GetClassNameW');

  static final _getWindowRect = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<_NativeRect>),
        int Function(int, Pointer<_NativeRect>)
      >('GetWindowRect');
  static final _getWindowThreadProcessId = _user32
      .lookupFunction<
        Uint32 Function(IntPtr, Pointer<Uint32>),
        int Function(int, Pointer<Uint32>)
      >('GetWindowThreadProcessId');

  static final _setWindowPos = _user32
      .lookupFunction<
        Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
        int Function(int, int, int, int, int, int, int)
      >('SetWindowPos');

  static final _showWindow = _user32
      .lookupFunction<Int32 Function(IntPtr, Int32), int Function(int, int)>(
        'ShowWindow',
      );

  static final _setForegroundWindow = _user32
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'SetForegroundWindow',
      );

  static final _setCursorPos = _user32
      .lookupFunction<Int32 Function(Int32, Int32), int Function(int, int)>(
        'SetCursorPos',
      );

  static final _mouseEvent = _user32
      .lookupFunction<
        Void Function(Uint32, Uint32, Uint32, Uint32, IntPtr),
        void Function(int, int, int, int, int)
      >('mouse_event');

  static final _keybdEvent = _user32
      .lookupFunction<
        Void Function(Uint8, Uint8, Uint32, IntPtr),
        void Function(int, int, int, int)
      >('keybd_event');
  static final _postMessage = _user32
      .lookupFunction<
        Int32 Function(IntPtr, Uint32, IntPtr, IntPtr),
        int Function(int, int, int, int)
      >('PostMessageW');

  static List<_WindowInfo>? _enumWindowsBuffer;
  static List<int>? _currentProcessWindowsBuffer;

  static bool enableDashboardShield() {
    final hwnd = _findCurrentProcessWindow();
    if (hwnd == null) return false;
    const swMaximize = 3;
    const hwndTopmost = -1;
    const swpNoMove = 0x0002;
    const swpNoSize = 0x0001;
    const swpShowWindow = 0x0040;
    _showWindow(hwnd, swMaximize);
    _setWindowPos(
      hwnd,
      hwndTopmost,
      0,
      0,
      0,
      0,
      swpNoMove | swpNoSize | swpShowWindow,
    );
    return true;
  }

  static int? _findCurrentProcessWindow() {
    final handles = <int>[];
    _currentProcessWindowsBuffer = handles;
    try {
      _enumWindows(_currentProcessCallback, 0);
    } finally {
      _currentProcessWindowsBuffer = null;
    }
    if (handles.isEmpty) return null;
    return handles.first;
  }

  static final _currentProcessCallback =
      Pointer.fromFunction<Int32 Function(IntPtr, IntPtr)>(
        _currentProcessEnumProc,
        1,
      );

  static int _currentProcessEnumProc(int hwnd, int lParam) {
    final handles = _currentProcessWindowsBuffer;
    if (handles == null) return 1;
    if (_isWindowVisible(hwnd) == 0) return 1;
    final processId = calloc<Uint32>();
    try {
      _getWindowThreadProcessId(hwnd, processId);
      if (processId.value == pid) {
        handles.add(hwnd);
        return 0;
      }
    } finally {
      calloc.free(processId);
    }
    return 1;
  }

  static _WindowInfo? findEFootWindow() {
    final windows = <_WindowInfo>[];
    _enumWindowsBuffer = windows;
    try {
      _enumWindows(_enumWindowsCallback, 0);
    } finally {
      _enumWindowsBuffer = null;
    }

    if (windows.isEmpty) return null;
    windows.sort((a, b) => b.rect.area.compareTo(a.rect.area));
    return windows.first;
  }

  static final _enumWindowsCallback =
      Pointer.fromFunction<Int32 Function(IntPtr, IntPtr)>(_enumWindowsProc, 1);

  static int _enumWindowsProc(int hwnd, int lParam) {
    final windows = _enumWindowsBuffer;
    if (windows == null) return 1;
    if (_isWindowVisible(hwnd) == 0) return 1;
    final title = _windowText(hwnd);
    final className = _className(hwnd);
    if (_looksLikeEFoot(title, className)) {
      final rect = _windowRect(hwnd);
      if (rect != null) {
        windows.add(
          _WindowInfo(
            handle: hwnd,
            title: title,
            className: className,
            rect: rect,
          ),
        );
      }
    }
    return 1;
  }

  static void restoreAndFocus(int hwnd) {
    const swRestore = 9;
    _showWindow(hwnd, swRestore);
    _setForegroundWindow(hwnd);
  }

  static void clickRelative(_WindowInfo window, double x, double y) {
    final point = window.rect.relativePoint(x, y);
    _setCursorPos(point.x, point.y);
    sleep(const Duration(milliseconds: 70));
    const leftDown = 0x0002;
    const leftUp = 0x0004;
    _mouseEvent(leftDown, 0, 0, 0, 0);
    sleep(const Duration(milliseconds: 60));
    _mouseEvent(leftUp, 0, 0, 0, 0);
  }

  static void backgroundClickRelative(_WindowInfo window, double x, double y) {
    final point = window.rect.clientPoint(x, y);
    final lParam = _makeLParam(point.x, point.y);
    const wmMouseMove = 0x0200;
    const wmLButtonDown = 0x0201;
    const wmLButtonUp = 0x0202;
    const mkLButton = 0x0001;
    _postMessage(window.handle, wmMouseMove, 0, lParam);
    sleep(const Duration(milliseconds: 55));
    _postMessage(window.handle, wmLButtonDown, mkLButton, lParam);
    sleep(const Duration(milliseconds: 60));
    _postMessage(window.handle, wmLButtonUp, 0, lParam);
  }

  static void replaceFocusedTextFromClipboard() {
    const vkControl = 0x11;
    const vkA = 0x41;
    const vkV = 0x56;
    _keyDown(vkControl);
    _tapKey(vkA);
    sleep(const Duration(milliseconds: 45));
    _tapKey(vkV);
    _keyUp(vkControl);
  }

  static void pressTab() {
    const vkTab = 0x09;
    _tapKey(vkTab);
  }

  static void backgroundReplaceText(int hwnd, String value) {
    const vkControl = 0x11;
    const vkA = 0x41;
    _postKeyDown(hwnd, vkControl);
    _postKeyTap(hwnd, vkA);
    _postKeyUp(hwnd, vkControl);
    sleep(const Duration(milliseconds: 50));
    for (final unit in value.codeUnits) {
      _postChar(hwnd, unit);
      sleep(const Duration(milliseconds: 8));
    }
  }

  static void backgroundPressTab(int hwnd) {
    const vkTab = 0x09;
    _postKeyTap(hwnd, vkTab);
  }

  static void _tapKey(int keyCode) {
    _keyDown(keyCode);
    sleep(const Duration(milliseconds: 35));
    _keyUp(keyCode);
  }

  static void _keyDown(int keyCode) {
    _keybdEvent(keyCode, 0, 0, 0);
  }

  static void _keyUp(int keyCode) {
    const keyUp = 0x0002;
    _keybdEvent(keyCode, 0, keyUp, 0);
  }

  static void _postKeyTap(int hwnd, int keyCode) {
    _postKeyDown(hwnd, keyCode);
    sleep(const Duration(milliseconds: 20));
    _postKeyUp(hwnd, keyCode);
  }

  static void _postKeyDown(int hwnd, int keyCode) {
    const wmKeyDown = 0x0100;
    _postMessage(hwnd, wmKeyDown, keyCode, 0);
  }

  static void _postKeyUp(int hwnd, int keyCode) {
    const wmKeyUp = 0x0101;
    _postMessage(hwnd, wmKeyUp, keyCode, 0);
  }

  static void _postChar(int hwnd, int codeUnit) {
    const wmChar = 0x0102;
    _postMessage(hwnd, wmChar, codeUnit, 0);
  }

  static int _makeLParam(int low, int high) {
    return (low & 0xFFFF) | ((high & 0xFFFF) << 16);
  }

  static bool _looksLikeEFoot(String title, String className) {
    final titleLower = title.toLowerCase();
    final classLower = className.toLowerCase();
    return titleLower.contains('efoot') ||
        titleLower.contains('efoot-touch') ||
        classLower.contains('qt5qwindowowndcicon');
  }

  static String _windowText(int hwnd) {
    final rawBuffer = calloc<Uint16>(512);
    final buffer = rawBuffer.cast<Utf16>();
    try {
      final length = _getWindowText(hwnd, buffer, 512);
      return buffer.toDartString(length: math.max(0, length));
    } finally {
      calloc.free(rawBuffer);
    }
  }

  static String _className(int hwnd) {
    final rawBuffer = calloc<Uint16>(256);
    final buffer = rawBuffer.cast<Utf16>();
    try {
      final length = _getClassName(hwnd, buffer, 256);
      return buffer.toDartString(length: math.max(0, length));
    } finally {
      calloc.free(rawBuffer);
    }
  }

  static _WindowRect? _windowRect(int hwnd) {
    final rect = calloc<_NativeRect>();
    try {
      if (_getWindowRect(hwnd, rect) == 0) return null;
      return _WindowRect(
        left: rect.ref.left,
        top: rect.ref.top,
        right: rect.ref.right,
        bottom: rect.ref.bottom,
      );
    } finally {
      calloc.free(rect);
    }
  }
}

final class _NativeRect extends Struct {
  @Int32()
  external int left;

  @Int32()
  external int top;

  @Int32()
  external int right;

  @Int32()
  external int bottom;
}

class _WindowInfo {
  final int handle;
  final String title;
  final String className;
  final _WindowRect rect;

  const _WindowInfo({
    required this.handle,
    required this.title,
    required this.className,
    required this.rect,
  });
}

class _WindowRect {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const _WindowRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  int get width => math.max(1, right - left);
  int get height => math.max(1, bottom - top);
  int get area => width * height;

  ({int x, int y}) relativePoint(double x, double y) {
    return (x: left + (width * x).round(), y: top + (height * y).round());
  }

  ({int x, int y}) clientPoint(double x, double y) {
    return (x: (width * x).round(), y: (height * y).round());
  }

  @override
  String toString() => '$left,$top ${width}x$height';
}
