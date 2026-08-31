import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oy_site/data/repositories/supabase_customer_home_repository.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:oy_site/models/customer_home_model.dart';
import 'package:oy_site/models/order_model.dart';
import 'package:oy_site/screens/dashboard/customer/customer_home_screen.dart';

void main() {
  const user = AppUser(
    firstName: 'Ada',
    lastName: 'Test',
    email: 'ada@example.com',
    roleCode: RoleCodes.customer,
    roleName: 'Customer',
  );

  testWidgets('shows assessment and active order when both exist', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      user: user,
      data: CustomerHomeData(
        patientName: user.fullName,
        latestAssessment: _assessment(),
        activeOrder: _activeOrder(),
      ),
    );

    expect(find.text('Assessment summary from Supabase'), findsOneWidget);
    expect(find.text('OY-ACTIVE'), findsWidgets);
    expect(find.text('Üretimde'), findsWidgets);
  });

  testWidgets('keeps the assessment visible without an active order', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      user: user,
      data: CustomerHomeData(
        patientName: user.fullName,
        latestAssessment: _assessment(),
      ),
    );

    expect(find.text('Assessment summary from Supabase'), findsOneWidget);
    expect(find.text('Aktif sipariş yok'), findsWidgets);
  });

  testWidgets('shows honest empty states when no records exist', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      user: user,
      data: CustomerHomeData(patientName: user.fullName),
    );

    expect(find.text('Henüz değerlendirme yok'), findsWidgets);
    expect(find.text('Aktif sipariş yok'), findsWidgets);
    expect(find.text('Ürün belirlenmedi.'), findsWidgets);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required AppUser user,
  required CustomerHomeData data,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: CustomerHomeScreen(
        currentUser: user,
        onNavigate: (_) {},
        repository: _FakeHomeRepository(data),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CustomerHomeAssessmentData _assessment() {
  return CustomerHomeAssessmentData(
    sessionCode: 'SESSION-1',
    analysisDate: DateTime(2026, 8, 10),
    summary: 'Assessment summary from Supabase',
    highlights: const ['Finding'],
    recommendationTitle: 'Recommendation',
    recommendationNote: 'Recommendation note',
  );
}

CustomerHomeOrderData _activeOrder() {
  return CustomerHomeOrderData(
    orderNo: 'OY-ACTIVE',
    orderStatus: OrderStatuses.production,
    productType: 'insole',
    orderedAt: DateTime(2026, 8, 10),
    progressStep: 2,
  );
}

class _FakeHomeRepository implements CustomerHomeRepository {
  final CustomerHomeData data;

  const _FakeHomeRepository(this.data);

  @override
  Future<CustomerHomeData> getHomeData({required String patientName}) async {
    return data;
  }
}
