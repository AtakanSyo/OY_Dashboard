import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/site/pages/site_home_page.dart';
import 'package:oy_site/site/site_routes.dart';

/// V3 "Kurumlara Özel Çözümler" — üç görselli tam kaplama kart.

Future<void> _pumpHome(WidgetTester tester, {required Size size}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: const SiteHomePage(), onGenerateRoute: generateSiteRoute),
  );
  await tester.pump(const Duration(milliseconds: 1200));
}

Future<void> _center(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('B2B bölümü — V3', () {
    testWidgets('yeni başlık ve üç segment kartı çizilir', (tester) async {
      await _pumpHome(tester, size: const Size(1440, 1200));

      expect(find.text('KURUMLARA ÖZEL ÇÖZÜMLER'), findsOneWidget);
      expect(
        find.textContaining('ölçülebilir bir hizmete dönüştürün'),
        findsOneWidget,
      );
      expect(find.text('KLİNİKLER'), findsOneWidget);
      expect(find.text('SPOR KULÜPLERİ'), findsOneWidget);
      expect(find.text('İŞ YERLERİ'), findsOneWidget);
      expect(find.text('Klinik çözümünü incele'), findsOneWidget);
      expect(find.text('Kurumsal programı incele'), findsOneWidget);
      // Eski başlık gitti.
      expect(find.text('Kurumdan Kuruma (B2B) Hizmetlerimiz'), findsNothing);

      await _disposeTree(tester);
    });

    testWidgets('Klinikler kartı /cozumler/klinikler sayfasına gider', (
      tester,
    ) async {
      await _pumpHome(tester, size: const Size(1440, 1200));

      final card = find.text('Klinik çözümünü incele');
      await _center(tester, card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text('Klinikler'), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('Spor Kulüpleri kartı /iletisim sayfasına gider', (
      tester,
    ) async {
      await _pumpHome(tester, size: const Size(1440, 1200));

      final card = find.text('Spor kulübü çözümünü incele');
      await _center(tester, card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text('Bize ulaşın'), findsOneWidget);

      await _disposeTree(tester);
    });

    testWidgets('klavye ile odak + Enter kartı etkinleştirir', (tester) async {
      await _pumpHome(tester, size: const Size(1440, 1200));

      final label = find.text('Kurumsal programı incele');
      await _center(tester, label);
      Focus.of(tester.element(label)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('İş Yerleri'), findsOneWidget);

      await _disposeTree(tester);
    });
  });

  group('B2B bölümü — kırılım noktaları', () {
    for (final width in <double>[1440, 1024, 768, 390, 360]) {
      testWidgets('${width.toInt()} px genişlikte taşma yok', (tester) async {
        await _pumpHome(tester, size: Size(width, 1400));
        expect(tester.takeException(), isNull);
        await _disposeTree(tester);
      });
    }
  });
}
