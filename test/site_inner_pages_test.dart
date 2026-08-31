import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/site/content/site_page_content.dart';
import 'package:oy_site/site/pages/site_content_page.dart';
import 'package:oy_site/site/pages/site_utility_pages.dart';
import 'package:oy_site/site/site_routes.dart';

Future<void> _pump(WidgetTester tester, Widget page, Size size) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: page, onGenerateRoute: generateSiteRoute),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('İç sayfa içerikleri', () {
    for (final size in const [Size(390, 900), Size(1280, 900)]) {
      testWidgets('tüm menü sayfaları ${size.width.toInt()} px taşmaz', (
        tester,
      ) async {
        for (final entry in sitePageContent.entries) {
          await _pump(tester, SiteContentPage(content: entry.value), size);
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key} @ ${size.width.toInt()}px',
          );
        }
      });
    }

    testWidgets('teknolojilerimiz çapa navigasyonu çalışır', (tester) async {
      await _pump(
        tester,
        SiteContentPage(content: sitePageContent[SiteRoutes.teknolojiler]!),
        const Size(1280, 900),
      );

      expect(find.text('Basınç ölçümü'), findsWidgets);
      // Çapa çipine dokunmak istisna üretmemeli (kaydırma yapılır).
      await tester.tap(find.text('Veri güvenliği').first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    test('public dilde yasak terimler kullanılmaz', () {
      const forbidden = ['kişiselleştir', 'ısmarlama', 'ortez', 'ortotik'];
      final buffer = StringBuffer();

      void scan(String? s) {
        if (s == null) return;
        final lower = s.toLowerCase();
        for (final word in forbidden) {
          if (lower.contains(word)) buffer.writeln('"$word" → "$s"');
        }
      }

      for (final page in sitePageContent.values) {
        scan(page.eyebrow);
        scan(page.title);
        scan(page.description);
        for (final block in page.blocks) {
          switch (block) {
            case SiteHeadingBlock():
              scan(block.title);
              scan(block.description);
            case SiteImageTextBlock():
              scan(block.title);
              scan(block.body);
              block.bullets.forEach(scan);
            case SiteFeaturesBlock():
              for (final it in block.items) {
                scan(it.title);
                scan(it.body);
              }
            case SiteFaqBlock():
              for (final it in block.items) {
                scan(it.question);
                scan(it.answer);
              }
            case SiteBulletsBlock():
              scan(block.title);
              block.bullets.forEach(scan);
              scan(block.note);
            case SiteCtaBlock():
              scan(block.title);
              scan(block.description);
            default:
              break;
          }
        }
      }

      expect(buffer.isEmpty, isTrue, reason: buffer.toString());
    });
  });

  group('Yardımcı sayfalar', () {
    testWidgets('Ölçüm Merkezleri — arama ve boş durum', (tester) async {
      await _pump(
        tester,
        const MeasurementCentersPage(),
        const Size(1280, 1000),
      );

      expect(find.text('LiveLifeTaller — Kartal'), findsOneWidget);
      expect(find.text('İZTÜ DML — Buca İzmir'), findsOneWidget);
      expect(find.text('Alsancak İzmir'), findsOneWidget);
      expect(find.textContaining('Buca / İzmir'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'ankara');
      await tester.pump();

      expect(find.text('Bu aramaya uygun merkez bulunamadı'), findsOneWidget);
    });

    testWidgets('Haberler — boş durum gösterilir', (tester) async {
      await _pump(tester, const NewsPage(), const Size(390, 900));
      expect(find.text('Henüz yayımlanmış içerik yok'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('İletişim — kanallar ve form alanları', (tester) async {
      await _pump(tester, const ContactPage(), const Size(1280, 1400));
      expect(find.text('info@optiyou.com.tr'), findsWidgets);
      expect(find.textContaining('0534 884 23 19'), findsWidgets);
      expect(find.textContaining('+90 507 290 37 13'), findsWidgets);
      expect(find.text('Mesajınız'), findsOneWidget);
      expect(find.text('E-posta ile Gönder'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('İletişim — boş form doğrulaması', (tester) async {
      await _pump(tester, const ContactPage(), const Size(1280, 1400));
      await tester.tap(find.text('E-posta ile Gönder'));
      await tester.pump();
      expect(find.text('Bu alan zorunludur.'), findsWidgets);
    });
  });
}
