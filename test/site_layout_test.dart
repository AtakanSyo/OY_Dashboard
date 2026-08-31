import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/site/content/site_page_content.dart';
import 'package:oy_site/site/pages/site_content_page.dart';
import 'package:oy_site/site/pages/site_home_page.dart';
import 'package:oy_site/site/site_routes.dart';

/// Superspec §14 kırılım noktaları.
const Map<String, Size> _breakpoints = {
  'mobil 390': Size(390, 900),
  'tablet 1024': Size(1024, 1000),
  'desktop 1440': Size(1440, 1000),
};

/// Superspec §2.1: public dilde kullanılmaması gereken kelimeler.
const List<String> _forbiddenWords = ['kişiselleştir', 'ortez', 'analiz'];

Future<void> _pumpSite(WidgetTester tester, Widget page, Size size) async {
  // `setSurfaceSize` MediaQuery'yi güncellemez; ölçüyü doğrudan view'a vermek
  // gerekir, aksi hâlde sayfa 800x600 varsayıp yanlış kırılımda çizilir.
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: page, onGenerateRoute: generateSiteRoute),
  );

  // Hero'daki ölçüm animasyonunun tamamlanması için.
  await tester.pump(const Duration(milliseconds: 1200));
}

List<String> _visibleTexts(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? '')
      .where((text) => text.isNotEmpty)
      .toList();
}

void main() {
  setUpAll(() {
    // Testlerde font indirmeye çalışılmasın; paketlenmiş fontlar kullanılır.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Ana sayfa', () {
    for (final entry in _breakpoints.entries) {
      testWidgets('${entry.key} genişliğinde taşma vermeden çizilir', (
        tester,
      ) async {
        await _pumpSite(tester, const SiteHomePage(), entry.value);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('spesifikasyondaki zorunlu bölümleri içerir', (tester) async {
      await _pumpSite(tester, const SiteHomePage(), const Size(1440, 1000));

      final texts = _visibleTexts(tester).join(' | ');

      // Hero
      expect(
        texts,
        contains('Ayağınız tek bir kategoriye sığmayacak kadar eşsiz.'),
      );
      expect(
        texts,
        contains(
          'Yapay Zeka Destekli Anatomik Kategorilemeyle doğru '
          'tabanlıkla konforu hissedin.',
        ),
      );
      expect(texts, contains('Sürecimiz'));
      expect(texts, contains('3D Tarama İçin Randevu Al'));

      // Ürün bölümü — dört kart (V3: OY Sports Carbon eklendi)
      expect(texts, contains('Veri Güdümlü Ayak Giyim Teknolojileri'));
      expect(texts, contains('OY Orthopedic'));
      expect(texts, contains('OY Sports'));
      expect(texts, contains('OY Recovery'));
      expect(texts, contains('OY Sports Carbon'));

      // B2B — V3 "Kurumlara Özel Çözümler"
      expect(texts, contains('KURUMLARA ÖZEL ÇÖZÜMLER'));
      expect(texts, contains('KLİNİKLER'));
      expect(texts, contains('SPOR KULÜPLERİ'));
      expect(texts, contains('İŞ YERLERİ'));

      expect(texts, contains('Giriş Yap'));
    });

    testWidgets('public dilde yasak kelimeleri kullanmaz', (tester) async {
      await _pumpSite(tester, const SiteHomePage(), const Size(1440, 1000));

      for (final text in _visibleTexts(tester)) {
        final lower = text.toLowerCase();
        for (final word in _forbiddenWords) {
          expect(
            lower.contains(word),
            isFalse,
            reason: 'Yasak kelime "$word" şu metinde geçiyor: "$text"',
          );
        }
      }
    });
  });

  group('Menü sayfaları', () {
    // Her menü sayfası hem dar hem geniş ekranda taşmadan çizilmeli.
    for (final route in sitePageContent.keys) {
      testWidgets('$route mobil ve masaüstünde çizilir', (tester) async {
        final content = sitePageContent[route]!;

        await _pumpSite(
          tester,
          SiteContentPage(content: content),
          const Size(390, 900),
        );
        expect(tester.takeException(), isNull, reason: '$route (390 px)');

        await _pumpSite(
          tester,
          SiteContentPage(content: content),
          const Size(1440, 1000),
        );
        expect(tester.takeException(), isNull, reason: '$route (1440 px)');
      });
    }

    testWidgets('yasal sayfalar kayıtlı belge metnini basar', (tester) async {
      await _pumpSite(
        tester,
        SiteContentPage(content: sitePageContent[SiteRoutes.kvkk]!),
        const Size(1440, 1000),
      );

      final texts = _visibleTexts(tester).join(' | ');
      expect(texts, contains('AYDINLATMA METNİ'));
    });
  });

  group('Navigasyon', () {
    test('her menü bağlantısı tanımlı bir route’a gider', () {
      // generateSiteRoute içinde ele alınan, sitePageContent'te olması
      // gerekmeyen interaktif route'lar.
      final knownRoutes = {
        ...sitePageContent.keys,
        SiteRoutes.home,
        SiteRoutes.login,
        SiteRoutes.taramaRandevusu,
        SiteRoutes.taramaStandiBasvuru,
        SiteRoutes.olcumMerkezleri,
        SiteRoutes.iletisim,
        SiteRoutes.haberler,
      };

      // Sayfa içi çapa (#id) linklerinde yol kısmı karşılaştırılır.
      String pathOf(String route) => Uri.parse(route).path;

      for (final item in siteNavigation) {
        if (item.route != null) {
          expect(
            knownRoutes,
            contains(pathOf(item.route!)),
            reason: '${item.label} tanımsız route’a gidiyor: ${item.route}',
          );
        }

        for (final link in item.children) {
          expect(
            knownRoutes,
            contains(pathOf(link.route)),
            reason: '${link.label} tanımsız route’a gidiyor: ${link.route}',
          );
        }
      }
    });
  });
}
