// The citizen side made to match the website (2026-10-22): a support ticket
// can name the request it is about; the name is typed before verification
// and asked for after it (reason and proof); the Resident Profile asks only
// what the server keeps; and Balita has the All / Barangay tabs, a category
// and Load more. Synthetic identities only.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/citizen_account.dart';
import 'package:esperanza_mobile/screens/balita/balita_screen.dart';
import 'package:esperanza_mobile/screens/directory/barangay_profile_screen.dart';
import 'package:esperanza_mobile/screens/profile/edit_profile_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/family_information_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/household_information_screen.dart';
import 'package:esperanza_mobile/screens/profile/resident_profile/personal_information_screen.dart';
import 'package:esperanza_mobile/screens/support/report_problem_screen.dart';
import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/barangay_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';
import 'package:esperanza_mobile/services/support_service.dart';

import 'support/fake_api.dart';

CitizenAccount _citizen({String status = 'Pending Review'}) => CitizenAccount(
      id: 'ESP-RES-2026-000901',
      firstName: 'Testa',
      lastName: 'Sintetiko',
      email: 'testa@esperanza-test.invalid',
      mobile: '09170000000',
      barangay: 'Poblacion',
      purok: 'Purok 1',
      address: 'Purok 1, Barangay Poblacion, Esperanza, Masbate',
      birthdate: '1995-03-02',
      sex: 'Female',
      civilStatus: 'Single',
      occupation: 'Teacher',
      profileCompleteness: 100,
      status: status,
    );

/// What a request sent: method, path and body (JSON decoded, or the raw
/// multipart text).
typedef _Sent = ({String method, String path, Object? body});

/// Serves [handler]'s data with the envelope's `meta` (which FakeApi omits).
void _serve(List<_Sent> sent, ({Object? data, Map<String, dynamic>? meta, int status}) Function(http.Request r) handler) {
  api = ApiClient(
    baseUrl: 'https://test.invalid',
    httpClient: MockClient((r) async {
      Object? body = r.body;
      try {
        body = jsonDecode(r.body);
      } catch (_) {}
      sent.add((method: r.method, path: r.url.path, body: body));
      final res = handler(r);
      final envelope = res.status >= 400
          ? res.data
          : {'data': res.data, if (res.meta != null) 'meta': res.meta};
      return http.Response(jsonEncode(envelope), res.status, headers: {'content-type': 'application/json'});
    }),
  );
}

({Object? data, Map<String, dynamic>? meta, int status}) _ok(Object? data, [Map<String, dynamic>? meta]) =>
    (data: data, meta: meta, status: 200);

Future<CitizenSessionService> _pump(WidgetTester tester, Widget home, {CitizenAccount? account}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final session = CitizenSessionService();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(home: account == null ? home : const SizedBox()),
    ),
  );
  if (account != null) {
    await tester.runAsync(() => session.login(account));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CitizenSessionService>.value(value: session),
          ChangeNotifierProvider(create: (_) => RequestsService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => BalitaService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(home: home),
      ),
    );
  }
  await tester.pumpAndSettle();
  return session;
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(FakeApi.restore);

  group('Report a Problem', () {
    test('a ticket reads the request it is about', () {
      final t = SupportTicket.fromJson({'ref': 'TKT-2026-0001', 'request_ref': 'DOK-2026-00036', 'office': 'Barangay'});
      expect(t!.requestRef, 'DOK-2026-00036');
    });

    testWidgets('"Related request (optional)" lists the Dokyu and Tulong and sends request_ref', (tester) async {
      final sent = <_Sent>[];
      _serve(sent, (r) {
        if (r.url.path == '/citizen/requests') {
          return _ok([
            {'ref': 'DOK-2026-00036', 'type': 'dokyu', 'service': 'Business Clearance', 'status': 'Released', 'submitted': '2026-10-01'},
            {'ref': 'TUL-2026-00007', 'type': 'tulong', 'service': 'Medical Assistance', 'status': 'Under Review', 'submitted': '2026-10-02'},
          ], {'current_page': 1, 'last_page': 1});
        }
        if (r.url.path == '/citizen/support/tickets') return _ok({'ref': 'TKT-2026-0042'});
        return _ok(<dynamic>[]);
      });
      await _pump(tester, const ReportProblemScreen(), account: _citizen());

      expect(find.text('Related request (optional)'), findsOneWidget);
      expect(find.text('The ticket goes to the office handling that request.'), findsOneWidget);
      await tester.ensureVisible(find.text('None'));
      await tester.tap(find.text('None'));
      await tester.pumpAndSettle();
      expect(find.text('TUL-2026-00007 · Medical Assistance · Under Review'), findsWidgets);
      await tester.tap(find.text('DOK-2026-00036 · Business Clearance · Released').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Briefly describe the problem'), 'Wrong date');
      await tester.enterText(find.widgetWithText(TextField, 'What happened? What were you trying to do?'), 'The date is wrong.');
      await _tapText(tester, 'Submit Report');

      final post = sent.singleWhere((s) => s.method == 'POST');
      expect(post.path, '/citizen/support/tickets');
      expect((post.body! as Map)['request_ref'], 'DOK-2026-00036');
      expect(find.textContaining('TKT-2026-0042'), findsOneWidget);
    });
  });

  group('Edit Profile: the name', () {
    testWidgets('before verification the first and last name are typed here, and only a change is sent', (tester) async {
      final sent = <_Sent>[];
      _serve(sent, (r) => _ok({'account_no': 'ESP-RES-2026-000901', 'first_name': 'Testina', 'last_name': 'Sintetiko', 'status': 'Pending Review'}));
      await _pump(tester, const EditProfileScreen(), account: _citizen());

      expect(find.text('Request a name change'), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, 'Testa'), 'Testina');
      await _tapText(tester, 'Save Changes');

      final put = sent.singleWhere((s) => s.method == 'PUT');
      expect(put.path, '/citizen/profile');
      expect(put.body, {'first_name': 'Testina'});
    });

    testWidgets('verified: the name is locked, and a change is asked for with the reason and proof', (tester) async {
      final sent = <_Sent>[];
      _serve(sent, (r) => _ok(<dynamic>[]));
      await _pump(tester, const EditProfileScreen(), account: _citizen(status: 'Approved'));

      expect(find.widgetWithText(TextField, 'Testa'), findsNothing);
      expect(find.textContaining("Your account is verified, so your name can't be changed here."), findsOneWidget);
      await _tapText(tester, 'Request a name change');

      await _tapText(tester, 'Send request');
      expect(find.text('Choose why your name is changing.'), findsOneWidget);

      await _tapText(tester, 'Choose…');
      await tester.tap(find.text('Marriage (taking my spouse’s surname)').last);
      await tester.pumpAndSettle();
      await _tapText(tester, 'Send request');
      expect(find.text('That is the name already on record.'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Sintetiko'), 'Halimbawa');
      await _tapText(tester, 'Send request');
      expect(find.text('Attach your proof: PSA marriage certificate'), findsOneWidget);
      expect(sent.where((s) => s.method == 'POST'), isEmpty);
    });

    testWidgets('a request still waiting is shown, and no second can be started', (tester) async {
      final sent = <_Sent>[];
      _serve(sent, (r) => _ok([
            {
              'ref': 'DSR-2026-0003',
              'kind': 'name_change',
              'detail': 'Name change (marriage)',
              'status': 'Submitted',
              'requested': {'first_name': 'Testa', 'last_name': 'Halimbawa'},
              'submitted_at': '2026-10-20T02:00:00Z',
            },
          ]));
      await _pump(tester, const EditProfileScreen(), account: _citizen(status: 'Approved'));

      expect(find.text('Waiting for your barangay: DSR-2026-0003 → Testa Halimbawa'), findsOneWidget);
      expect(find.textContaining('You can send another once it is answered.'), findsOneWidget);
      expect(find.text('Request a name change'), findsNothing);
    });
  });

  group('Resident Profile asks only what the server keeps', () {
    setUp(() => FakeApi.install((path, query) => <dynamic>[]));

    testWidgets('Personal Information: the name from the account, no email, barangay or attachments', (tester) async {
      await _pump(tester, const PersonalInformationScreen(), account: _citizen());
      expect(find.text('Testa Sintetiko'), findsOneWidget);
      expect(find.text('Email address'), findsNothing);
      expect(find.text('Barangay'), findsNothing);
      expect(find.text('Complete address'), findsNothing);
      expect(find.text('Attach ID / Document'), findsNothing);
      expect(find.text('Submitted Government ID'), findsNothing);
      expect(find.text('Household monthly income'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Household: no rooms, internet or other families', (tester) async {
      await _pump(tester, const HouseholdInformationScreen(), account: _citizen());
      expect(find.text('Number of rooms'), findsNothing);
      expect(find.text('Internet Access'), findsNothing);
      expect(find.text('Add Another Family'), findsNothing);
      expect(find.text('Barangay'), findsNothing);
    });

    testWidgets('Family: no "join family", emergency contact or made-up ids', (tester) async {
      await _pump(tester, const FamilyInformationScreen(), account: _citizen());
      expect(find.text('Request to Join Family'), findsNothing);
      expect(find.textContaining('Emergency Contact'), findsNothing);
      expect(find.text('Family ID'), findsNothing);
      expect(find.text('Household ID'), findsNothing);
      expect(find.text('Add the people in your family (not yourself).'), findsOneWidget);
    });
  });

  group('Balita', () {
    Map<String, dynamic> post(int id, {String? barangay, String category = 'Community'}) => {
          'id': id,
          'title': 'Synthetic post $id',
          'body': 'Body $id',
          'category': category,
          'barangay': ?barangay,
          'published_at': '2026-10-${(20 - id).toString().padLeft(2, '0')}T00:00:00Z',
        };

    testWidgets('All / Barangay, a category, and Load more for the next page', (tester) async {
      final sent = <_Sent>[];
      _serve(sent, (r) {
        if (r.url.path == '/announcements') {
          final page = r.url.queryParameters['page'] ?? '1';
          return page == '1'
              ? _ok([post(1, barangay: 'Poblacion'), post(2, category: 'Health')], {'current_page': 1, 'last_page': 2})
              : _ok([post(3, barangay: 'Baras')], {'current_page': 2, 'last_page': 2});
        }
        return _ok(<dynamic>[]);
      });
      await _pump(tester, const BalitaScreen(), account: _citizen());

      // The redesign (2026-10-22): underlined tabs and a Filter, no count.
      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Synthetic post 3'), findsNothing);
      await _tapText(tester, 'Load more posts');
      expect(sent.any((s) => s.path == '/announcements' && s.method == 'GET'), isTrue);
      await tester.scrollUntilVisible(find.text('Synthetic post 3'), 300);
      expect(find.text('Synthetic post 3'), findsOneWidget);
      expect(find.text('Load more posts'), findsNothing);

      await tester.scrollUntilVisible(find.text('Barangay'), -300);
      await _tapText(tester, 'Barangay');
      expect(find.text('Synthetic post 1'), findsOneWidget);
      expect(find.text('Synthetic post 2'), findsNothing);

      await _tapText(tester, 'All');
      await _tapText(tester, 'Filter');
      expect(find.text('All categories'), findsOneWidget);
      await _tapText(tester, 'Health');
      expect(find.text('Synthetic post 2'), findsOneWidget);
      expect(find.text('Synthetic post 1'), findsNothing);
      // The Filter now names the category, and the list has closed.
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('All categories'), findsNothing);
    });
  });

  group('Barangay profile (the redesign)', () {
    final labangtaytay = {
      'name': 'Labangtaytay',
      'contact': '(056) 000-0000',
      'history': {
        'summary': 'Puroks 9–12 · Formerly Barrio Tabunok',
        'facts': [
          {'value': '4', 'label': 'Puroks (9–12)'},
          {'value': '1961', 'label': 'Became a barrio'},
        ],
        'name_origin': {'title': 'labang + taytayan', 'text': 'The bamboo bridge.'},
        'livelihood': {'items': ['Fishing'], 'note': 'Synthetic gear'},
        'founding': 'Founded by synthetic settlers.',
        'leadership': [
          {'name': 'Ana Una', 'title': 'Kapitan del Barrio', 'term': '1970 – 1982'},
          {'name': 'Ben Dalawa', 'title': 'Punong Barangay', 'term': '1982 – 2001'},
          {'name': 'Cora Tatlo', 'title': 'Punong Barangay', 'term': '2001 – 2010'},
          {'name': 'Dan Apat', 'title': 'Punong Barangay', 'term': '2010 – Present'},
        ],
        'landmarks': [
          {'name': 'Synthetic Chapel', 'location': 'Purok 9', 'note': 'Fiesta in May'},
        ],
      },
      'officials_roster': [
        {'name': 'Hon. Dan Apat', 'position': 'Punong Barangay', 'committee': 'Chairperson, BDRRMC'},
        {'name': 'Eva Lima', 'position': 'Barangay Secretary', 'committee': 'Records'},
        {'name': 'Cora Tatlo', 'position': 'Barangay Kagawad', 'committee': 'Environment'},
      ],
    };

    testWidgets('History: facts, the name, livelihood, leaders newest first, places, and the full text', (tester) async {
      await _pump(tester, BarangayProfileScreen(barangay: BarangayInfo.fromApi(labangtaytay)!));

      expect(find.text('Puroks 9–12 · Formerly Barrio Tabunok'), findsOneWidget);
      expect(find.text('1961'), findsOneWidget);
      expect(find.text('labang + taytayan'), findsOneWidget);
      expect(find.text('Fishing'), findsOneWidget);
      // Newest first, three at a time, the current one marked.
      await tester.scrollUntilVisible(find.text('Show all 4'), 300);
      expect(find.text('Dan Apat'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Ana Una'), findsNothing);
      await _tapText(tester, 'Show all 4');
      expect(find.text('Ana Una'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Read full history'), 300);
      await tester.pumpAndSettle();
      expect(find.text('Synthetic Chapel'), findsOneWidget);
      expect(find.text('Founded by synthetic settlers.'), findsNothing);
      await _tapText(tester, 'Read full history');
      await tester.scrollUntilVisible(find.text('Founded by synthetic settlers.'), 200);
      expect(find.text('Founded by synthetic settlers.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Officials: the Punong Barangay, officers, kagawad by committee, and a profile', (tester) async {
      await _pump(tester, BarangayProfileScreen(barangay: BarangayInfo.fromApi(labangtaytay)!));
      await _tapText(tester, 'Officials & Staff');

      expect(find.text('PUNONG BARANGAY'), findsOneWidget);
      expect(find.text('Officers'), findsOneWidget);
      expect(find.text('1 · by committee'), findsOneWidget);
      await _tapText(tester, 'Cora Tatlo');
      // A kagawad who once led the barangay says so.
      expect(find.text('Also served'), findsOneWidget);
      expect(find.text('Punong Barangay, 2001 – 2010'), findsOneWidget);
      expect(find.text('Committee'), findsOneWidget);
      await tester.tap(find.byTooltip('Close profile'));
      await tester.pumpAndSettle();
      expect(find.text('Also served'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a barangay without the highlights shows what it has', (tester) async {
      await _pump(
        tester,
        BarangayProfileScreen(
          barangay: BarangayInfo.fromApi({
            'name': 'Agoho',
            'punong_barangay': 'Hon. Synthetic Captain',
            'history': {'founding': 'Founded by synthetic settlers.'},
          })!,
        ),
      );
      expect(find.text('Punong Barangay: Hon. Synthetic Captain'), findsOneWidget);
      expect(find.text('Read full history'), findsOneWidget);
      expect(find.text('Leadership'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
