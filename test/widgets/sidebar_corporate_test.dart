import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/widgets/sidebar.dart';

void main() {
  testWidgets('corporate sidebar shows kiosk entry', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Sidebar(
          selectedIndex: 0,
          onItemSelected: (_) {},
          currentUser: const AppUser(
            userId: 11,
            clinicId: 22,
            firstName: 'Corporate',
            lastName: 'User',
            email: 'corporate@example.com',
            roleCode: RoleCodes.corporate,
            roleName: 'Corporate',
          ),
        ),
      ),
    );

    expect(find.text('Tarama Kiosku'), findsOneWidget);
    expect(find.byIcon(Icons.document_scanner_outlined), findsOneWidget);
  });
}
