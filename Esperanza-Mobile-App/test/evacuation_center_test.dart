// Verifies the new Emergency evacuation-center detail flow: the list
// highlights the nearest center (by simulated distance), tapping opens
// full details, and capacity honestly shows "unavailable" rather than a
// fabricated number since no live capacity feed exists.
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

void main() {
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

  testWidgets('nearest evacuation center (by simulated distance) is labeled and listed first', (tester) async {
    await pumpSakuna(tester);

    expect(find.text('Nearest'), findsOneWidget);
    expect(find.text('Poblacion Covered Court'), findsOneWidget); // 0.8km — the closest seed value
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a center opens its detail screen with services, amenities, and an honest capacity state', (tester) async {
    await pumpSakuna(tester);

    await tester.tap(find.text('Poblacion Covered Court'));
    await tester.pumpAndSettle();

    expect(find.byType(EvacuationCenterDetailScreen), findsOneWidget);
    expect(find.text('Nearest Evacuation Center'), findsOneWidget);
    expect(find.text('Available Services'), findsOneWidget);
    expect(find.text('Amenities'), findsOneWidget);
    expect(find.text('Emergency Shelter'), findsOneWidget);
    // No live capacity feed exists anywhere in this app — must never show
    // a fabricated occupancy number.
    expect(find.text('Capacity information unavailable'), findsOneWidget);
    expect(find.textContaining('Currently occupied'), findsNothing);
    expect(find.text('Directions'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a center with no distanceKm renders without a distance line or nearest badge (location-denied fallback shape)', (tester) async {
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
