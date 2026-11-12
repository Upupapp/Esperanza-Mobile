import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/widgets/payment_guidance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CatalogItem _item({required String fee, bool blocked = false}) => CatalogItem(
  key: 'tulong_medical',
  name: 'Medical Assistance (AICS)',
  office: 'MSWDO',
  fee: fee,
  days: '3-5 working days',
  requirements: const [],
  process: const [],
  policyBlocked: blocked,
);

Future<void> _pump(WidgetTester tester, Widget card) => tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));

void main() {
  group('Payment guidance', () {
    testWidgets('a free Tulong program awaiting an LGU ruling says nothing about paying', (tester) async {
      await _pump(tester, PaymentGuidanceCard(item: _item(fee: 'Free', blocked: true), sayWhenFree: false));
      expect(find.textContaining('pay the fee'), findsNothing);
      expect(find.textContaining('not yet ruled'), findsNothing);
    });

    testWidgets('a free Dokyu service awaiting an LGU ruling is still free', (tester) async {
      await _pump(tester, PaymentGuidanceCard(item: _item(fee: 'Free', blocked: true)));
      expect(find.textContaining('free of charge'), findsOneWidget);
      expect(find.textContaining('not yet ruled'), findsNothing);
    });

    testWidgets('a service with a fee awaiting an LGU ruling says the office will confirm it', (tester) async {
      await _pump(tester, PaymentGuidanceCard(item: _item(fee: '₱50.00', blocked: true)));
      expect(find.textContaining('pay the fee in person'), findsOneWidget);
      expect(find.textContaining('not yet ruled'), findsOneWidget);
    });
  });
}
