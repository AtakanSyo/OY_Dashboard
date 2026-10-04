import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/widgets/sidebar.dart';

void main() {
  testWidgets(
    'Cihazlar menüsü yalnızca uzman rolünde ve doğru indekste görünür',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var selectedIndex = -1;
      await tester.pumpWidget(
        _testApp(
          Sidebar(
            onItemSelected: (index) => selectedIndex = index,
            selectedIndex: 0,
            currentUser: _user(RoleCodes.expert),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cihazlar'), findsOneWidget);
      await tester.tap(find.text('Cihazlar'));
      expect(selectedIndex, 3);

      await tester.pumpWidget(
        _testApp(
          Sidebar(
            onItemSelected: (_) {},
            selectedIndex: 0,
            currentUser: _user(RoleCodes.customer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cihazlar'), findsNothing);
    },
  );
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

AppUser _user(String roleCode) {
  return AppUser(
    userId: 1,
    firstName: 'Test',
    lastName: 'Kullanıcı',
    email: 'test@example.com',
    roleCode: roleCode,
    roleName: roleCode,
  );
}
