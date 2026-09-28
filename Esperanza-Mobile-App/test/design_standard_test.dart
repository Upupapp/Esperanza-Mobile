// Holds the design standard (docs/DESIGN_GUIDELINES.md) to its own numbers:
// the spacing and type scales match the web platform's roles, and every
// text colour the standard names is readable (WCAG AA 4.5:1).
import 'dart:math' as math;

import 'package:esperanza_mobile/theme/app_colors.dart';
import 'package:esperanza_mobile/theme/app_spacing.dart';
import 'package:esperanza_mobile/theme/app_status.dart';
import 'package:esperanza_mobile/theme/app_typography.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _luminance(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('colour contrast (WCAG AA, 4.5:1 for text)', () {
    const surfaces = {'surface': AppColors.surface, 'background': AppColors.background};
    const text = {
      'textPrimary': AppColors.textPrimary,
      'textBody': AppColors.textBody,
      'textMuted': AppColors.textMuted,
    };

    for (final t in text.entries) {
      for (final s in surfaces.entries) {
        test('${t.key} on ${s.key}', () {
          expect(contrast(t.value, s.value), greaterThanOrEqualTo(4.5));
        });
      }
    }

    test('textDisabled is below AA, so it is never for content', () {
      expect(contrast(AppColors.textDisabled, AppColors.surface), lessThan(4.5));
    });

    test('button foreground/background pairs (AppButton variants)', () {
      final pairs = {
        'primary': (Colors.white, AppColors.brand500),
        'secondary': (AppColors.slate700, Colors.white),
        'ghost': (AppColors.slate500, Colors.white),
        'danger': (Colors.white, AppColors.rose600),
        'gold': (AppColors.navy950, AppColors.gold400),
      };
      for (final p in pairs.entries) {
        expect(contrast(p.value.$1, p.value.$2), greaterThanOrEqualTo(4.5), reason: p.key);
      }
    });

    test('status badges are readable, with two known web-owned exceptions', () {
      // Cancelled (slate-500 on slate-100, 4.34) and Archived (slate-400 on
      // slate-100, 2.34) fail AA on both platforms. Their colours are the
      // web's badge.blade.php and must stay identical, so the fix belongs
      // to both lanes together (PENDING.md). Pinned here so no other status
      // joins them, and so this fails -- and gets updated -- once fixed.
      const knownFailing = {AppStatus.cancelled, AppStatus.archived};
      final failing = <AppStatus>{};
      for (final s in AppStatus.values) {
        final style = s.style;
        if (contrast(style.foreground, style.background) < 4.5) failing.add(s);
      }
      expect(failing, knownFailing);
    });
  });

  group('spacing matches the web rhythm', () {
    test('the scale is 4/8/12/16/20/24/32/48', () {
      expect(
        [AppSpacing.xs, AppSpacing.sm, AppSpacing.md, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xxxl, AppSpacing.page],
        [4, 8, 12, 16, 20, 24, 32, 48],
      );
    });

    test('every role resolves to a stop on the scale', () {
      final stops = {4.0, 8.0, 12.0, 16.0, 20.0, 24.0, 32.0, 48.0};
      for (final v in [
        AppSpacing.screenGutter,
        AppSpacing.cardPadding,
        AppSpacing.sheetPadding,
        AppSpacing.itemGap,
        AppSpacing.fieldGap,
        AppSpacing.sectionGap,
        AppSpacing.headingGap,
        AppSpacing.inlineGap,
        AppSpacing.scrollEnd,
      ]) {
        expect(stops, contains(v));
      }
    });

    test('interactive sizes meet the 44pt touch target', () {
      expect(AppSizes.minTouchTarget, 44);
      expect(AppSizes.buttonHeight, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      expect(AppSizes.buttonHeightLg, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      expect(AppSizes.inputHeight, greaterThanOrEqualTo(AppSizes.minTouchTarget));
    });
  });

  group('type scale', () {
    // (size, line height, weight) — card title down to label are the web's
    // own `.type-*` values exactly; display/page are one notch smaller for a
    // phone.
    final roles = <String, (TextStyle, double, double, FontWeight)>{
      'displayTitle': (AppTypography.displayTitle, 32, 40, FontWeight.w700),
      'pageTitle': (AppTypography.pageTitle, 24, 32, FontWeight.w700),
      'sectionTitle': (AppTypography.sectionTitle, 20, 28, FontWeight.w700),
      'cardHeading': (AppTypography.cardHeading, 16, 24, FontWeight.w600),
      'bodyText': (AppTypography.bodyText, 14, 22, FontWeight.w400),
      'helper': (AppTypography.helper, 13, 20, FontWeight.w400),
      'labelText': (AppTypography.labelText, 12, 16, FontWeight.w600),
      'eyebrow': (AppTypography.eyebrow, 11, 16, FontWeight.w600),
      'fine': (AppTypography.fine, 11, 14, FontWeight.w400),
    };

    for (final r in roles.entries) {
      test(r.key, () {
        final (style, size, lineHeight, weight) = r.value;
        expect(style.fontSize, size);
        expect(style.fontSize! * style.height!, closeTo(lineHeight, 0.001));
        expect(style.fontWeight, weight);
        expect(style.fontSize! % 1, 0, reason: 'the standard uses whole points only');
        expect(style.fontSize, greaterThanOrEqualTo(11), reason: '11 is the floor for readable text');
      });
    }
  });

  group('AppButton meets its size floor', () {
    for (final (size, floor) in [
      (AppButtonSize.sm, AppSizes.buttonHeightCompact),
      (AppButtonSize.md, AppSizes.buttonHeight),
      (AppButtonSize.lg, AppSizes.buttonHeightLg),
    ]) {
      testWidgets('$size is at least $floor tall', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: AppButton(label: 'Submit', size: size, onPressed: () {})),
            ),
          ),
        );
        expect(tester.getSize(find.byType(AppButton)).height, greaterThanOrEqualTo(floor));
      });
    }
  });

  test('every AppTypography style is a whole point, 11 or larger', () {
    final all = <String, TextStyle>{
      'displayTitle': AppTypography.displayTitle,
      'pageTitle': AppTypography.pageTitle,
      'sectionTitle': AppTypography.sectionTitle,
      'cardHeading': AppTypography.cardHeading,
      'bodyText': AppTypography.bodyText,
      'helper': AppTypography.helper,
      'labelText': AppTypography.labelText,
      'eyebrow': AppTypography.eyebrow,
      'fine': AppTypography.fine,
      'documentHeading': AppTypography.documentHeading,
      'h1': AppTypography.h1,
      'h2': AppTypography.h2,
      'h3': AppTypography.h3,
      'body': AppTypography.body,
      'bodyMedium': AppTypography.bodyMedium,
      'caption': AppTypography.caption,
      'bodySmallRegular': AppTypography.bodySmallRegular,
      'bodySmall': AppTypography.bodySmall,
      'bodySmallMedium': AppTypography.bodySmallMedium,
      'label': AppTypography.label,
      'labelStrong': AppTypography.labelStrong,
      'captionSmallRegular': AppTypography.captionSmallRegular,
      'captionSmall': AppTypography.captionSmall,
      'micro': AppTypography.micro,
      'cardTitle': AppTypography.cardTitle,
      'subsectionLabel': AppTypography.subsectionLabel,
      'hero': AppTypography.hero,
      'wordmark': AppTypography.wordmark,
      'overline': AppTypography.overline,
      'button': AppTypography.button,
      'documentTitle': AppTypography.documentTitle,
    };
    for (final e in all.entries) {
      final size = e.value.fontSize!;
      expect(size % 1, 0, reason: '${e.key} is $size');
      expect(size, greaterThanOrEqualTo(11), reason: '${e.key} is $size');
    }
  });
}
