import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/site/pages/site_home_page.dart';
import 'package:oy_site/site/site_routes.dart';

/// "Sürecimiz" bölümünün V3 davranış testleri: sahne rayı, kilit/Escape ve
/// asset bütünlüğü.

const List<String> _cardTitles = [
  '3D Biyomekanik Tarama',
  'Yapay Zekâ Destekli Anatomik Kategorileme',
  'Veri Güdümlü Dijital Üretim',
  'Teslimat ve Dijital Takip',
];

const String _body1 =
    'Ayak geometrisi ve yük altındaki plantar basınç dağılımı aynı '
    'ölçüm oturumunda dijitalleştirilir.';

const List<String> _assets = [
  'assets/site/v3/source/process-real-scan-session.webp',
  'assets/site/v3/generated/process-ai-categorization.webp',
  'assets/site/v3/generated/process-digital-production.webp',
  'assets/site/v3/generated/process-delivery-tracking.webp',
];

Future<void> _pumpHome(
  WidgetTester tester, {
  Size size = const Size(1440, 3200),
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

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Sürecimiz bölümü — V3', () {
    testWidgets('yeni başlık, Sole Doctor satırı ve özet çizilir', (
      tester,
    ) async {
      await _pumpHome(tester);

      expect(find.text('SÜRECİMİZ'), findsOneWidget);
      expect(
        find.text('Eşsiz ayak yapınıza en uygun ortopedik tabanlığı bulun.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains(
                'Sole Doctor - Ayak Sağlığı için Dijital Takip Üretim Hizmeti',
              ),
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('tek bir dijital profilde bir araya getirilir'),
        findsOneWidget,
      );
      // Eski başlık kalmadı.
      expect(
        find.text('Ölçümden teslimata, veriye dayalı dört adım'),
        findsNothing,
      );

      for (final title in _cardTitles) {
        expect(find.text(title), findsWidgets, reason: title);
      }

      await _disposeTree(tester);
    });

    testWidgets('karta tıklamak açıklamayı sabitler, Escape sıfırlar', (
      tester,
    ) async {
      await _pumpHome(tester);

      // Kapalıyken açıklama ağaçta değil.
      expect(find.text(_body1), findsNothing);

      await tester.tap(find.text(_cardTitles[0]).first);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(_body1), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(_body1), findsNothing);

      await _disposeTree(tester);
    });

    testWidgets('patent bandı 29.08.2026 metniyle görünür', (tester) async {
      await _pumpHome(tester);

      expect(
        find.text(
          'Anatomik kategorileme sistemimiz için patent başvurusu yapıldı',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('29.08.2026 tarihinde patent başvurusu'),
        findsOneWidget,
      );

      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .join(' ');
      expect(texts.toLowerCase().contains('patentli'), isFalse);

      await _disposeTree(tester);
    });

    testWidgets('bölüm sonu CTA metinleri yerinde', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Ölçüm Noktalarını Gör'), findsOneWidget);
      expect(find.text('Süreci İncele'), findsOneWidget);

      await _disposeTree(tester);
    });
  });

  group('Sürecimiz kırılım noktaları — V3', () {
    for (final width in <double>[1440, 1100, 1024, 768, 390, 360]) {
      testWidgets('${width.toInt()} px genişlikte taşma yok', (tester) async {
        await _pumpHome(tester, size: Size(width, 3600));
        expect(tester.takeException(), isNull);

        await tester.tap(find.text(_cardTitles[0]).first);
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);

        await _disposeTree(tester);
      });
    }
  });

  group('Sürecimiz asset bütünlüğü', () {
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
