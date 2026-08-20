import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';

import 'l10n/app_locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'site/pages/site_home_page.dart';
import 'site/site_routes.dart';

/// OPTIYOU public sitesi — karşılama sayfası, menüler ve içerik sayfaları.
///
/// Bu dal (`public-site-only`) yalnızca herkese açık siteyi içerir. Giriş
/// (`/giris`, `/login`), kayıt, şifre sıfırlama, ödeme ve giriş sonrası
/// dashboard ekranları bu dalda bulunmaz; o route'lar ana sayfaya düşer.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hero videosu media_kit ile oynatılıyor (video_player Windows'ta doku
  // sunmuyor); yerel kütüphaneler burada hazırlanır.
  MediaKit.ensureInitialized();

  // Site tipografisi assets/fonts/ altında paketlenmiştir; çalışma anında
  // Google'dan font indirilmez (yükleme gecikmesi ve dış bağımlılık olmasın).
  GoogleFonts.config.allowRuntimeFetching = false;

  final localeController = AppLocaleController();
  await localeController.load();

  runApp(OptiyouSiteApp(localeController: localeController));
}

class OptiyouSiteApp extends StatelessWidget {
  final AppLocaleController localeController;

  const OptiyouSiteApp({super.key, required this.localeController});

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: localeController,
      child: AnimatedBuilder(
        animation: localeController,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => 'OPTIYOU',
          debugShowCheckedModeBanner: false,
          locale: localeController.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (locale, supportedLocales) {
            if (localeController.locale != null) {
              return localeController.locale;
            }
            if (locale?.languageCode == 'en') return const Locale('en');
            return const Locale('tr');
          },
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const SiteHomePage(),
          onGenerateRoute: (settings) {
            // Public site route'ları (ana sayfa ve menü sayfaları).
            final siteRoute = generateSiteRoute(settings);
            if (siteRoute != null) return siteRoute;

            // Giriş ve dashboard route'ları bu dalın kapsamı dışında;
            // tanımsız adresler ana sayfaya döner.
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const SiteHomePage(),
            );
          },
        ),
      ),
    );
  }
}
