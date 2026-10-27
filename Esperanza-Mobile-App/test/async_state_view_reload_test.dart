// AsyncStateView's reload: an arrow `setState(() => _future = ...)` returned
// the Future, which setState refuses in debug builds, so every Retry, and a
// screen reloading itself after a change, threw (found recording the Sakuna
// demo, 2026-10-27).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/widgets/async_state_view.dart';

void main() {
  testWidgets('reload loads again without throwing', (tester) async {
    var loads = 0;
    VoidCallback? reload;
    await tester.pumpWidget(
      MaterialApp(
        home: AsyncStateView<int>(
          loader: () async => ++loads,
          builder: (context, n, r) {
            reload = r;
            return Text('loaded $n');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('loaded 1'), findsOneWidget);

    reload!();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('loaded 2'), findsOneWidget);
  });
}
