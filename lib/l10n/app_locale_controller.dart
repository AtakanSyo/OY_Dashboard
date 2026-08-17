import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ChangeNotifier {
  static const _preferenceKey = 'app_locale';

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_preferenceKey);
    if (code == 'tr' || code == 'en') {
      _locale = Locale(code!);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'tr' && locale.languageCode != 'en') return;
    if (_locale?.languageCode == locale.languageCode) return;

    _locale = Locale(locale.languageCode);
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, locale.languageCode);
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope bulunamadı.');
    return scope!.notifier!;
  }
}
