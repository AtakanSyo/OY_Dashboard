import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/site/pages/site_home_page.dart';
import 'package:oy_site/site/site_routes.dart';

/// V3 ürün bölümü: dört iki yüzlü kart (OY Sports Carbon dahil), tıklama /
/// klavye ile çevirme, `Escape` sıfırlama ve asset bütünlüğü.

const List<String> _names = [
  'OY Orthopedic',
  'OY Sports',
  'OY Recovery',
  'OY Sports Carbon',
];

const String _orthopedicLayer = 'Antibakteriyel üst yüzey';
const String _carbonLayer = 'Karbon fiber plaka';

const List<String> _assets = [
  'assets/site/v3/generated/product-daily-assembled.webp',
  'assets/site/v3/generated/product-daily-exploded.webp',
  'assets/site/v3/source/product-sports-assembled.webp',
  'assets/site/v3/generated/product-sports-exploded.webp',
  'assets/site/v3/source/product-recovery-assembled.webp',
  'assets/site/v3/generated/product-recovery-exploded.webp',
  'assets/site/v3/generated/product-carbon-assembled.webp',
  'assets/site/v3/generated/product-carbon-exploded.webp',
];

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(1440, 2600),
  bool reduceMotion = false,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: const SiteHomePage(),
        ),
      ),
      onGenerateRoute: generateSiteRoute,
    ),
  );
  await tester.pump(const Duration(milliseconds: 1200));
}

Future<void> _tapCard(WidgetTester tester, String name) async {
  final target = find.text(name).first;
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump();
  await tester.tap(target, warnIfMissed: false);
  await tester.pump();
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Ürün bölümü — V3', () {
    testWidgets('bölüm başlığı ve dört ürün (Carbon dahil) çizilir', (
      tester,
    ) async {
      await _pumpHome(tester);

      expect(find.text('OPTIYOU TEKNOLOJİ GİYİM ÜRÜNLERİ'), findsOneWidget);
      expect(
        find.text('Veri Güdümlü Ayak Giyim Teknolojileri'),
        findsOneWidget,
      );
      for (final name in _names) {
        expect(find.text(name), findsWidgets, reason: name);
      }
      expect(find.text('Gün boyu dengeli destek.'), findsOneWidget);
      // Randevu CTA'sı ürün bölümünde yok; yerine ürün bağlantısı var.
      expect(find.text('Tüm ürünleri incele'), findsOneWidget);
      expect(find.text('Tarama Yap'), findsNothing);

      await _disposeTree(tester);
    });

    testWidgets('kapalıyken katman adları ağaçta değil (lazy back)', (
      tester,
    ) async {
      await _pumpHome(tester);
      expect(find.text(_orthopedicLayer), findsNothing);
      expect(find.text(_carbonLayer), findsNothing);
      await _disposeTree(tester);
    });

    testWidgets('karta tıklamak çevirir, tekrar tıklamak geri alır', (
      tester,
    ) async {
      await _pumpHome(tester);

      await _tapCard(tester, 'OY Orthopedic');
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(_orthopedicLayer), findsOneWidget);

      await _tapCard(tester, 'OY Orthopedic');
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(_orthopedicLayer), findsNothing);

      await _disposeTree(tester);
    });

    testWidgets('Escape tüm kartları ön yüze döndürür', (tester) async {
      await _pumpHome(tester);

      await _tapCard(tester, 'OY Sports Carbon');
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(_carbonLayer), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text(_carbonLayer), findsNothing);

      await _disposeTree(tester);
    });

    testWidgets('azaltılmış hareket tercihinde de çevrilebilir', (
      tester,
    ) async {
      await _pumpHome(tester, reduceMotion: true);

      await _tapCard(tester, 'OY Recovery');
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Konturlu ayak yatağı'), findsWidgets);

      await _disposeTree(tester);
    });
  });

  group('Ürün bölümü — kırılım noktaları', () {
    for (final width in <double>[1440, 1280, 1024, 768, 390, 360]) {
      testWidgets('${width.toInt()} px genişlikte taşma yok', (tester) async {
        await _pumpHome(tester, size: Size(width, 3200));
        expect(tester.takeException(), isNull);

        await _tapCard(tester, 'OY Sports');
        await tester.pump(const Duration(milliseconds: 800));
        expect(tester.takeException(), isNull);

        await _disposeTree(tester);
      });
    }
  });

  group('Ürün asset bütünlüğü', () {
    test('görsel dosyaları diskte var', () {
      for (final path in _assets) {
        expect(File(path).existsSync(), isTrue, reason: '$path bulunamadı');
      }
    });

    test('asset klasörleri pubspec.yaml içinde tanımlı', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final path in _assets) {
        final dir = '${path.substring(0, path.lastIndexOf('/'))}/';
        expect(
          pubspec.contains(path) || pubspec.contains(dir),
          isTrue,
          reason: '$path pubspec.yaml içinde yok',
        );
      }
    });
  });
}
