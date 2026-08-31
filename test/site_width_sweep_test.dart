import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oy_site/site/pages/site_home_page.dart';
import 'package:oy_site/site/site_routes.dart';

/// Kart ızgarası ve hero, kırılım noktaları arasındaki ara genişliklerde de
/// taşmamalı. Daha önce iki kez, yalnızca belirli genişliklerde ortaya çıkan
/// yerleşim hataları yaşandı; bu tarama onları erken yakalar.
String? _lastErrorDump;

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('ana sayfa 360–1600 px aralığında taşma vermez', (tester) async {
    final failures = <String>[];

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _lastErrorDump = details.toString();
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    for (var width = 320.0; width <= 1920; width += 20) {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(width, 1000);

      await tester.pumpWidget(
        MaterialApp(
          home: const SiteHomePage(),
          onGenerateRoute: generateSiteRoute,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1200));

      final exception = tester.takeException();
      if (exception != null) {
        failures.add('${width.toInt()} px: $exception');
        // ignore: avoid_print
        print('--- $width px ---\n${_lastErrorDump ?? "(detay yok)"}');
      }
    }

    addTearDown(tester.view.reset);

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
