// Verifies the new progressive filtering on ServiceCatalogScreen: a step
// is only shown when it would actually narrow something. Dokyu's catalog
// spans both Barangay and LGU offices, so it shows a scope step first;
// Tulong's catalog is entirely LGU/Municipal-level, so that step is
// skipped and it starts directly at Department.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/service_catalog_screen.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/theme/app_colors.dart';

void main() {
  testWidgets('Dokyu catalog shows the Barangay/LGU step first, then Department, then items', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ServiceCatalogScreen(
        category: ServiceCategory.dokyu,
        title: 'Dokyu',
        catalog: MockCatalog.documentTypes,
        accent: AppColors.brand600,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Where is this service administered?'), findsOneWidget);
    expect(find.text('Barangay'), findsOneWidget);
    expect(find.text('LGU / Municipality'), findsOneWidget);

    await tester.tap(find.text('Barangay'));
    await tester.pumpAndSettle();

    // Barangay-scoped Dokyu items only come from "Barangay Hall" — a
    // single department, so the department step is itself skipped and it
    // should land directly on the item list.
    expect(find.text('Barangay Clearance'), findsOneWidget);
    expect(find.text('Cedula (Community Tax Certificate)'), findsNothing); // Treasurer's Office = LGU-scoped
    expect(tester.takeException(), isNull);

    // Back button un-does the last selection rather than leaving the screen.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Where is this service administered?'), findsOneWidget);
  });

  testWidgets('Tulong catalog is entirely LGU-scoped, so the Barangay/LGU step is skipped', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ServiceCatalogScreen(
        category: ServiceCategory.tulong,
        title: 'Tulong',
        catalog: MockCatalog.assistanceTypes,
        accent: AppColors.purple700,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Where is this service administered?'), findsNothing);
    expect(find.text('Which office handles this?'), findsOneWidget);
    expect(find.text('OSCA'), findsOneWidget);

    await tester.tap(find.text('OSCA'));
    await tester.pumpAndSettle();

    expect(find.text('Social Pension (Indigent Senior Citizen)'), findsOneWidget);
    expect(find.text('Medical Assistance (AICS)'), findsNothing); // MSWDO department
    expect(tester.takeException(), isNull);
  });
}
