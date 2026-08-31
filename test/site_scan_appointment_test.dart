import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/site/data/scan_appointment_service.dart';
import 'package:oy_site/site/pages/scan_appointment_page.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  bool corporate = false,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: ScanAppointmentPage(initialCorporate: corporate)),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Tarama Yap — slot üretimi', () {
    test('11:00–16:45 arası 15 dakikalık 24 slot', () {
      final slots = buildDailyScanSlots();
      expect(slots.first, '11:00');
      expect(slots.last, '16:45');
      expect(slots.length, 24);
      expect(slots.contains('13:30'), isTrue);
    });
  });

  group('Tarama Yap sayfası', () {
    testWidgets('bireysel form alanları görünür (Supabase gerektirmez)', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1440, 1000));

      expect(tester.takeException(), isNull);
      expect(find.text('Bireysel'), findsOneWidget);
      expect(find.text('Kurumsal'), findsOneWidget);
      expect(find.text('Ad Soyad'), findsOneWidget);
      expect(find.text('Telefon'), findsOneWidget);
      expect(find.text('E-posta'), findsOneWidget);
      expect(find.text('Lokasyon'), findsOneWidget);
      expect(find.text('Tarih'), findsOneWidget);
      expect(find.text('Saat'), findsOneWidget);
      expect(find.text('Randevu Oluştur'), findsOneWidget);
    });

    testWidgets('dar ekranda taşma vermez', (tester) async {
      await _pump(tester, size: const Size(390, 900));
      expect(tester.takeException(), isNull);
    });

    testWidgets('boş formda gönderince zorunlu alan uyarısı çıkar', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1440, 1400));

      await tester.tap(find.text('Randevu Oluştur'));
      await tester.pump();

      expect(find.text('Bu alan zorunludur.'), findsWidgets);
      expect(find.text('Devam etmek için onaylayın.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kurumsal sekmesi form alanlarını gösterir', (tester) async {
      // 700 px: üst bar hamburger'e düşer, "Kurumsal" yalnızca sekme metni
      // olarak bulunur (menü öğesi değil).
      await _pump(tester, size: const Size(700, 1400));

      await tester.tap(find.text('Kurumsal'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Şirket ismi'), findsOneWidget);
      expect(find.text('Yetkili kişi'), findsOneWidget);
      expect(find.text('Kaç kişi tarama yapılacak'), findsOneWidget);
      expect(find.text('Tarayıcı sistem satın alma'), findsOneWidget);
      expect(find.text('B2B tarama hizmeti'), findsOneWidget);
      expect(find.text('Talep Gönder'), findsOneWidget);
    });

    testWidgets('initialCorporate doğrudan kurumsal formu açar', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1440, 1200), corporate: true);

      expect(find.text('Şirket ismi'), findsOneWidget);
      expect(find.text('Ad Soyad'), findsNothing);
    });
  });
}
