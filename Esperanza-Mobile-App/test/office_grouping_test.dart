// The catalogue spells the Civil Registrar three ways; the Dokyu office step
// must show it once and list every one of its services under it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/service_catalog_screen.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/utils/office_name.dart';

CatalogItem _item(String key, String name, String office) =>
    CatalogItem.fromApi({'key': key, 'name': name, 'office': office, 'type': 'dokyu', 'fee': {'display': '₱50.00'}});

void main() {
  test('the three Civil Registrar spellings are one office', () {
    expect(canonicalOffice('Civil Registrar'), 'Office of the Municipal Civil Registrar');
    expect(canonicalOffice('Civil Registrar / appropriate local office'), 'Office of the Municipal Civil Registrar');
    expect(canonicalOffice("Treasurer's Office"), "Treasurer's Office");
  });

  testWidgets('the office step lists the Civil Registrar once, with all its services', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog = [
      _item('a', 'Barangay Clearance', 'Office of the Punong Barangay'),
      _item('b', 'Birth Certificate (CTC)', 'Office of the Municipal Civil Registrar'),
      _item('c', 'Delayed Registration of Birth', 'Civil Registrar'),
      _item('d', 'Certificate of Fetal Death', 'Civil Registrar / appropriate local office'),
      _item('e', 'Cedula', "Treasurer's Office"),
    ];
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => RequestsService()),
        ],
        child: MaterialApp(
          home: ServiceCatalogScreen(category: ServiceCategory.dokyu, title: 'Dokyu', catalog: catalog, accent: AppColors.brand600),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('LGU / Municipality'));
    await tester.pumpAndSettle();

    expect(find.text('Office of the Municipal Civil Registrar'), findsOneWidget);
    expect(find.text('Civil Registrar'), findsNothing);

    await tester.tap(find.text('Office of the Municipal Civil Registrar'));
    await tester.pumpAndSettle();
    expect(find.text('Birth Certificate (CTC)'), findsOneWidget);
    expect(find.text('Delayed Registration of Birth'), findsOneWidget);
    expect(find.text('Certificate of Fetal Death'), findsOneWidget);
    expect(find.text('Cedula'), findsNothing);
  });
}
