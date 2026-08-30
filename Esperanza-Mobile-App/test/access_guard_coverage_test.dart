// Every route to a gated screen must carry its guard — not just the tab.
//
// `root_shell.dart` wraps DokyuScreen and TulongScreen in
// `AccessGuard(required: AccessLevel.verified)`. Until 2026-08-30 the Home
// screen's "New Dokyu Request" / "New Tulong Request" buttons pushed the very
// same screens **raw**, so an Unverified citizen who used the CTA walked
// straight into the request flow the tab refuses them. One rule, two call
// sites, enforced at one.
//
// Found by signing in as the unverified demo account and tapping the button —
// not by a test. `nav_access_overflow_test.dart` renders the guarded tab and
// passes; nothing exercised the shortcut.
//
// So this asserts the property that actually matters — no unguarded
// construction *anywhere* — rather than testing the two call sites that happen
// to exist today. A third route added next month is covered by construction.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens that must never be constructed without an enclosing AccessGuard.
const _gated = ['DokyuScreen', 'TulongScreen', 'SakunaScreen'];

/// Is this construction lexically inside an `AccessGuard(... child: ...)`?
///
/// A lookback rather than a balanced-paren regex: Dart's formatter splits these
/// calls across many lines, and a regex trying to match the whole thing is the
/// kind of clever that quietly stops matching and turns the test green. The
/// window is generous; requiring `child:` after the `AccessGuard(` is what makes
/// it specific.
bool _insideAccessGuard(String source, int constructionStart) {
  const window = 400;
  final from = constructionStart - window < 0 ? 0 : constructionStart - window;
  final before = source.substring(from, constructionStart);
  final guardAt = before.lastIndexOf('AccessGuard(');
  if (guardAt < 0) return false;
  return before.substring(guardAt).contains('child:');
}

void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('the scan reaches the screens', () {
    expect(sources.length, greaterThan(100), reason: 'only ${sources.length} lib files — the walk is broken');
  });

  for (final screen in _gated) {
    test('$screen is never constructed outside an AccessGuard', () {
      final pattern = RegExp('\\b$screen\\s*\\(\\s*\\)');
      final offenders = <String>[];
      var constructions = 0;

      for (final file in sources) {
        final source = file.readAsStringSync();
        // The screen's own definition file legitimately names it.
        if (source.contains('class $screen ')) continue;
        final path = file.path.replaceAll(r'\', '/');

        for (final match in pattern.allMatches(source)) {
          constructions++;
          if (_insideAccessGuard(source, match.start)) continue;
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          offenders.add('$path:$line');
        }
      }

      // A scanner that finds no constructions passes for ever.
      expect(
        constructions,
        greaterThan(0),
        reason: 'found no $screen construction at all — the pattern is broken, not the code',
      );

      expect(
        offenders,
        isEmpty,
        reason:
            '$screen is reachable without its AccessGuard from:\n  ${offenders.join('\n  ')}\n\n'
            'Wrap it exactly as root_shell.dart does, with the same required level '
            'and featureName. A screen gated on one route and open on another is '
            'not gated.',
      );
    });
  }
}
