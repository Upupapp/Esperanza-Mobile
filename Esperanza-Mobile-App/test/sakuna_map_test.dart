// Sakuna on a real map (2026-10-26): a report carries where the emergency
// is, the centres are on a map and measured from a point the resident chose,
// and nothing is ever placed or measured from a guess. The same `lat`/`lng`
// pair the website and the backend keep. No tiles, no GPS: the test config
// turns both off, and each test that needs a position fakes one.
import 'package:esperanza_mobile/models/evacuation_center.dart';
import 'package:esperanza_mobile/models/geo_point.dart';
import 'package:esperanza_mobile/screens/sakuna/evacuation_center_detail_screen.dart';
import 'package:esperanza_mobile/screens/sakuna/location_picker_screen.dart';
import 'package:esperanza_mobile/screens/sakuna/report_incident_screen.dart';
import 'package:esperanza_mobile/screens/sakuna/sakuna_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/device_location.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_api.dart';

/// Answers the phone's position as [point], as GPS would.
void _gpsAt(GeoPoint point, {double accuracy = 12}) =>
    DeviceLocation.locate = () async => LocationResult.found(point, accuracyM: accuracy);

void _gpsRefused() => DeviceLocation.locate = () async => const LocationResult.failed(LocationProblem.denied);

/// The explanation before the first location request is acknowledged once
/// per phone; the tests start as a phone that already saw it.
void _locationExplained() => SharedPreferences.setMockInitialValues({'protected_action_ack.location': true});

Map<String, dynamic> _centre(String ref, String name, String barangay, {String status = 'Processing', Object? lat, Object? lng}) => {
  'ref': ref,
  'name': name,
  'barangay': barangay,
  'address': '$barangay Road',
  'status': status,
  'services': const ['Emergency Shelter'],
  'families': 2,
  'individuals': 9,
  'capacity': 100,
  'pct': 9,
  'lat': lat,
  'lng': lng,
};

/// The operating system's side of geolocator, faked: location on and allowed,
/// and the first (Play services) request refused as a declined "Location
/// Accuracy" prompt refuses it.
class _DeclinedAccuracy extends GeolocatorPlatform {
  final asked = <bool>[];

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    final plain = locationSettings is AndroidSettings && locationSettings.forceLocationManager;
    asked.add(plain);
    if (!plain) throw const LocationServiceDisabledException();
    return Position(
      latitude: 11.7390,
      longitude: 124.0412,
      timestamp: DateTime(2026, 10, 26),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  tearDown(FakeApi.restore);
  tearDown(() => DeviceLocation.locate = () async => const LocationResult.failed(LocationProblem.unavailable));

  test("declining Google's Location Accuracy prompt still finds the phone (Android)", () async {
    final previous = GeolocatorPlatform.instance;
    final fake = _DeclinedAccuracy();
    GeolocatorPlatform.instance = fake;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() {
      GeolocatorPlatform.instance = previous;
      debugDefaultTargetPlatformOverride = null;
    });
    final result = await DeviceLocation.fromPlatform();
    expect(fake.asked, [false, true], reason: 'Play services first, then the platform location manager');
    expect(result.point, const GeoPoint(11.739, 124.0412));
    expect(result.accuracyM, 5);
  });

  group('the coordinate pair', () {
    test('read as the API sends it, both or neither, never 0, 0', () {
      expect(GeoPoint.fromJson({'lat': '11.7370000', 'lng': '124.0417000'}), const GeoPoint(11.737, 124.0417));
      expect(GeoPoint.fromJson({'lat': 11.737, 'lng': 124.0417}), const GeoPoint(11.737, 124.0417));
      expect(GeoPoint.fromJson({'lat': 11.737}), isNull, reason: 'half a pin is no pin');
      expect(GeoPoint.fromJson({'lat': null, 'lng': null}), isNull);
      expect(GeoPoint.fromJson({'lat': 0, 'lng': 0}), isNull);
      expect(GeoPoint.fromJson({'lat': 91, 'lng': 124}), isNull);
      expect(GeoPoint.fromJson({'lat': 'eleven', 'lng': 124}), isNull);
    });

    test('sent at the column\'s seven decimals, as strings for JSON or a form', () {
      expect(const GeoPoint(11.73701234, 124.04169987).toFields(), {'lat': '11.7370123', 'lng': '124.0416999'});
    });

    test('a straight-line distance from real coordinates', () {
      // One minute of latitude is one nautical mile: 1.853 km.
      const a = GeoPoint(11.0, 124.0);
      const b = GeoPoint(11.0 + 1 / 60, 124.0);
      expect(a.distanceKmTo(b), closeTo(1.853, 0.01));
      expect(distanceText(0.4567), '460 m');
      expect(distanceText(2.345), '2.3 km');
      expect(distanceText(12.6), '13 km');
    });
  });

  group('reporting where the emergency is', () {
    Future<List<Map<String, dynamic>>> pumpReport(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final sent = <Map<String, dynamic>>[];
      FakeApi.installFull((r) {
        if (r.path == '/citizen/incidents' && r.method == 'POST') {
          sent.add(r.body!);
          return {'ref': 'INC-2026-00100', 'title': 'Flood', 'type': 'Flood', 'severity': 'High', 'barangay': 'Poblacion', 'status': 'Submitted', 'reported': '2026-10-26T00:00:00Z'};
        }
        return <dynamic>[];
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CitizenSessionService()),
            ChangeNotifierProvider(create: (_) => RequestsService()),
          ],
          child: const MaterialApp(home: ReportIncidentScreen(accent: AppColors.rose600)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flood'));
      await tester.tap(find.text('High'));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(MockCatalog.barangays.first).last);
      await tester.pumpAndSettle();
      return sent;
    }

    Future<void> submit(WidgetTester tester) async {
      final button = find.text('Submit Report');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    testWidgets('no pin: it says so, and the report goes without one', (tester) async {
      _locationExplained();
      final sent = await pumpReport(tester);
      expect(find.text('No map location selected. The barangay and the place you typed are still sent.'), findsOneWidget);
      await submit(tester);
      expect(sent, hasLength(1));
      expect(sent.single.containsKey('lat'), isFalse);
      expect(sent.single.containsKey('lng'), isFalse);
    });

    testWidgets('"Use my location" pins the phone\'s position and sends the pair', (tester) async {
      _locationExplained();
      _gpsAt(const GeoPoint(11.7381234, 124.0398765), accuracy: 15);
      final sent = await pumpReport(tester);
      final use = find.text('Use my location');
      await tester.ensureVisible(use);
      await tester.tap(use);
      await tester.pumpAndSettle();
      expect(find.text('Pinned at 11.73812, 124.03988'), findsOneWidget);
      expect(find.textContaining('If the emergency is somewhere else, tap that spot on the map.'), findsOneWidget);
      expect(find.textContaining('(±15 m)'), findsOneWidget);
      await submit(tester);
      expect(sent.single['lat'], '11.7381234');
      expect(sent.single['lng'], '124.0398765');
    });

    testWidgets('location refused: an alternative, and the report still goes', (tester) async {
      _locationExplained();
      _gpsRefused();
      final sent = await pumpReport(tester);
      final use = find.text('Use my location');
      await tester.ensureVisible(use);
      await tester.tap(use);
      await tester.pumpAndSettle();
      expect(find.text('Location access was not allowed, so nothing was pinned. Tap the map where the emergency is instead.'), findsOneWidget);
      await submit(tester);
      expect(sent, hasLength(1));
      expect(sent.single.containsKey('lat'), isFalse);
    });

    testWidgets('a pin chosen on the map comes back to the form, and can be removed', (tester) async {
      _locationExplained();
      final sent = await pumpReport(tester);
      final pin = find.text('Pin on map');
      await tester.ensureVisible(pin);
      await tester.tap(pin);
      await tester.pumpAndSettle();
      expect(find.byType(LocationPickerScreen), findsOneWidget);
      expect(find.text('Nothing pinned yet.'), findsOneWidget);
      // A tap on the map places the pin where it lands.
      await tester.tapAt(tester.getCenter(find.byType(LocationPickerScreen)));
      // The map waits out a double tap before it calls a tap a tap.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pinned at 11.7'), findsOneWidget);
      await tester.tap(find.text('Use this location'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportIncidentScreen), findsOneWidget);
      expect(find.textContaining('Pinned at 11.7'), findsOneWidget);

      final remove = find.text('Remove pin');
      await tester.ensureVisible(remove);
      await tester.tap(remove);
      await tester.pumpAndSettle();
      expect(find.text('No map location selected. The barangay and the place you typed are still sent.'), findsOneWidget);
      await submit(tester);
      expect(sent.single.containsKey('lat'), isFalse);
    });
  });

  group('evacuation centres', () {
    Future<void> pumpSakuna(WidgetTester tester, List<Map<String, dynamic>> centres) async {
      tester.view.physicalSize = const Size(390, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FakeApi.install((path, query) {
        if (path == '/sakuna/centers') return centres;
        if (path == '/hotlines' || path == '/alerts') return <dynamic>[];
        throw FakeApiError(status: 404, code: 'NOT_FOUND', messageEn: 'no fake route for $path');
      });
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

    // The resident is at the town; the closed hall is nearer than either
    // open centre, and one open centre was never pinned.
    final centres = [
      _centre('EC-1', 'Town Gym', 'Poblacion', lat: 11.7450, lng: 124.0417), // ~0.9 km
      _centre('EC-2', 'Hill School', 'Santiago', lat: '11.7700000', lng: '124.0417000'), // ~3.7 km
      _centre('EC-3', 'Old Hall', 'Poblacion', status: 'Archived', lat: 11.7375, lng: 124.0417), // ~0.06 km, not open
      _centre('EC-4', 'Unpinned Chapel', 'Agoho'),
    ];

    testWidgets('nearest is the nearest OPEN centre with a pin, from the phone, with the straight-line caveat', (tester) async {
      _locationExplained();
      _gpsAt(GeoPoint.home);
      await pumpSakuna(tester, centres);
      expect(find.text('Nearest open'), findsNothing, reason: 'no point to measure from yet');

      await tester.tap(find.widgetWithText(AppButton, 'Nearest open centre'));
      await tester.pumpAndSettle();

      expect(find.text('NEAREST OPEN CENTRE'), findsOneWidget);
      expect(find.textContaining('890 m away, in a straight line'), findsWidgets);
      expect(find.text('Nearest open'), findsOneWidget, reason: 'one badge, on Town Gym');
      expect(find.textContaining('not always the safest or quickest'), findsOneWidget);
      // The unpinned centre is listed, unmeasured.
      expect(find.text('Unpinned Chapel'), findsOneWidget);
      // Open centres come first by distance.
      final gym = tester.getTopLeft(find.text('Town Gym').last).dy;
      final school = tester.getTopLeft(find.text('Hill School')).dy;
      expect(gym, lessThan(school));
    });

    testWidgets('location refused: no nearest, an alternative, and the list still works', (tester) async {
      _locationExplained();
      _gpsRefused();
      await pumpSakuna(tester, centres);
      await tester.tap(find.widgetWithText(AppButton, 'Nearest open centre'));
      await tester.pumpAndSettle();
      expect(find.text('Location access was not allowed. Choose your place on the map, or pick your barangay below.'), findsOneWidget);
      expect(find.text('NEAREST OPEN CENTRE'), findsNothing);
      expect(find.text('Town Gym'), findsOneWidget);
      expect(find.text('Unpinned Chapel'), findsOneWidget);
    });

    testWidgets('the map shows the pinned centres and counts the rest; the barangay filter narrows the list', (tester) async {
      await pumpSakuna(tester, centres);
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.text('1 listed centre(s) are not on the map yet; they are in the list.'), findsOneWidget);
      Finder pin(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label);
      expect(pin('Town Gym, Open now'), findsOneWidget);
      expect(pin('Old Hall, Not open'), findsOneWidget);
      expect(pin('Unpinned Chapel, Open now'), findsNothing, reason: 'never placed at a guessed point');
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('All barangays'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brgy. Santiago').last);
      await tester.pumpAndSettle();
      expect(find.text('Hill School'), findsOneWidget);
      expect(find.text('Town Gym'), findsNothing);
    });

    testWidgets('no centre pinned: no measuring, no broken map', (tester) async {
      await pumpSakuna(tester, [_centre('EC-9', 'Unpinned Chapel', 'Agoho')]);
      expect(find.text('No centre is on the map yet, so distances cannot be measured. Use the list and the barangay filter.'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Nearest open centre'), findsNothing);
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.text('No centre is on the map yet. They are all in the list.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("a centre's page shows where it is, or says it is not on the map", (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EvacuationCenterDetailScreen(
            center: EvacuationCenter(name: 'Town Gym', barangay: 'Poblacion', totalCapacity: 100, isOpen: true, location: GeoPoint(11.745, 124.0417)),
            distanceKm: 0.9,
            isNearest: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('11.74500, 124.04170'), findsOneWidget);
      expect(find.text('900 m away, in a straight line'), findsOneWidget);
      expect(find.text('Nearest open centre'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: EvacuationCenterDetailScreen(center: EvacuationCenter(name: 'Chapel', barangay: 'Agoho', totalCapacity: 50))),
      );
      await tester.pumpAndSettle();
      expect(find.text('This centre is not on the map yet; directions search for its name and address.'), findsOneWidget);
      expect(find.textContaining('away, in a straight line'), findsNothing);
      expect(find.text('Nearest open centre'), findsNothing);
    });
  });

  test("a report's detail reads where it was pinned", () async {
    FakeApi.install(
      (path, query) => {
        'ref': 'INC-2026-00101',
        'title': 'Fire',
        'type': 'Fire',
        'severity': 'High',
        'barangay': 'Poblacion',
        'status': 'Submitted',
        'reported': '2026-10-26T00:00:00Z',
        'lat': 11.7381234,
        'lng': 124.0398765,
        'timeline': const [],
      },
    );
    final service = RequestsService();
    addTearDown(service.dispose);
    final incident = await service.loadDetail('INC-2026-00101');
    expect(incident.incidentLocation, const GeoPoint(11.7381234, 124.0398765));
  });
}
