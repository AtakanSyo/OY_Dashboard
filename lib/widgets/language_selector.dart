import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_locale_controller.dart';
import 'package:oy_site/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  final bool compact;
  final Color? foregroundColor;

  const LanguageSelector({
    super.key,
    this.compact = false,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final color = foregroundColor ?? Theme.of(context).colorScheme.onSurface;
    final languageCode = locale.languageCode.toUpperCase();

    return PopupMenuButton<String>(
      tooltip: localizations.selectLanguage,
      onSelected: (code) {
        AppLocaleScope.of(context).setLocale(Locale(code));
      },
      itemBuilder: (context) => [
        _item('tr', localizations.turkish, locale.languageCode == 'tr'),
        _item('en', localizations.english, locale.languageCode == 'en'),
      ],
      child: Semantics(
        button: true,
        label: localizations.selectLanguage,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language, color: color, size: 22),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  languageCode,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                Icon(Icons.arrow_drop_down, color: color, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(String code, String label, bool selected) {
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: selected
                ? const Icon(Icons.check, size: 18)
                : const SizedBox.shrink(),
          ),
          Text(label),
        ],
      ),
    );
  }
}
