// Verifies the Emergency evacuation-center list and detail flow now that
// both are real data (GET /sakuna/centers, production-readiness programme,
// 2026-09-25): tapping a center opens full details, and capacity honestly
// reflects what the endpoint actually returns -- live occupancy when
// present, "unavailable" when it isn't, never a fabricated number either
// way.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/models/evacuation_center.dart';
import 'package:esperanza_mobile/screens/sakuna/evacuation_center_detail_screen.dart';
import 'package:esperanza_mobile/screens/sakuna/sakuna_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';

import 'support/fake_api.dart';

void main() {
  setUp(() {
    FakeApi.install((path, query) {
      if (path == '/hotlines') return <Map<String, dynamic>>[];
      if (path == '/sakuna/centers') {
        return [
          {
            'ref': 'EC-001',
            'name': 'Poblacion Covered Court',
            'barangay': 'Poblacion',
            'address': 'Poblacion',
            'status': 'Processing',
            'services': ['Emergency Shelter', 'Medical Station'],
            'families': 10,
            'individuals': 40,
            'capacity': 200,
            'pct': 20,
          },
        ];
      }
      throw FakeApiError(status: 404, code: 'NOT_FOUND', messageEn: 'no fake route for $path');
    });
  });

  tearDown(() => FakeApi.restore());

  Future<void> pumpSakuna(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
          ChangeNotifierProvider(create: (_) => RequestsService()),
        ],
        child: const MaterialApp(home: SakunaScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('evacuation centers load from the real endpoint and never show a fabricated "Nearest" badge', (tester) async {
    await pumpSakuna(tester);

    expect(find.text('Poblacion Covered Court'), findsOneWidget);
    // This app has no geolocation wired up and SakunaCenter carries no
    // lat/lng at all, so distanceKm is always null on real data -- "Nearest"
    // must never render, not even for whichever center happens to sort
    // first. (A prior version of this list badged the first sorted center
    // as "Nearest" unconditionally when nothing had a real distance --
    // fixed alongside this conversion.)
    expect(find.text('Nearest'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a center opens its detail screen with real services and live occupancy', (tester) async {
    await pumpSakuna(tester);

    await tester.tap(find.text('Poblacion Covered Court'));
    await tester.pumpAndSettle();

    expect(find.byType(EvacuationCenterDetailScreen), findsOneWidget);
    expect(find.text('Nearest Evacuation Center'), findsNothing); // no real distance signal exists
    expect(find.text('Available Services'), findsOneWidget);
    expect(find.text('Emergency Shelter'), findsOneWidget);
    // Real occupancy now exists (individuals: 40 from the fake /sakuna/centers
    // response above) -- the honest-capacity design still applies, but the
    // live number is what it must show, not the "unavailable" fallback.
    expect(find.textContaining('Currently occupied'), findsOneWidget);
    expect(find.text('Capacity information unavailable'), findsNothing);
    expect(find.text('Directions'), findsOneWidget);
    // SakunaCenter has no contact-number column at all -- unlike the old
    // MockCatalog fixture, which always had one, "Call" is correctly absent
    // rather than fabricated.
    expect(find.text('Call'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a center with no distanceKm or occupancy renders without a distance line, nearest badge, or fabricated capacity', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: EvacuationCenterDetailScreen(
          center: EvacuationCenter(name: 'Fallback Center', barangay: 'Test', totalCapacity: 50),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('km away'), findsNothing);
    expect(find.text('Nearest Evacuation Center'), findsNothing);
    expect(find.text('Capacity information unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
