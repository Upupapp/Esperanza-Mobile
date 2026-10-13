// The card's picture is the face on the ID (owner, 2026-10-13): a crop box
// around the face found on the front photo, and the widget that shows it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/services/id_portrait.dart';
import 'package:esperanza_mobile/widgets/wallet_id_card.dart';

void main() {
  test('a head-and-shoulders crop around the face, in the slot\'s proportions, inside the photo', () {
    // A 1000 x 630 ID photo with a 120 x 150 face at the left.
    final box = PortraitBox.around(const Rect.fromLTWH(80, 160, 120, 150), 1000, 630)!;
    expect(box.w * 1000 / (box.h * 630), closeTo(PortraitBox.slotAspect, 0.01));
    // The face is inside, with room above it for the hair.
    expect(box.x * 1000, lessThanOrEqualTo(80));
    expect((box.x + box.w) * 1000, greaterThanOrEqualTo(200));
    expect(box.y * 630, lessThan(160));
    expect(box.y + box.h, lessThanOrEqualTo(1.0001));
    expect(box.x, greaterThanOrEqualTo(0));
  });

  test('a face at the edge is kept inside the photo, and a huge one is shrunk to fit', () {
    final edge = PortraitBox.around(const Rect.fromLTWH(0, 0, 100, 120), 1000, 630)!;
    expect(edge.x, 0);
    expect(edge.y, 0);
    final huge = PortraitBox.around(const Rect.fromLTWH(100, 50, 600, 600), 800, 630)!;
    expect(huge.w, lessThanOrEqualTo(1.0001));
    expect(huge.h, lessThanOrEqualTo(1.0001));
  });

  test('the box travels as four fractions, and anything else is refused', () {
    const b = PortraitBox(0.05, 0.2, 0.25, 0.45);
    expect(b.encode(), '0.0500,0.2000,0.2500,0.4500');
    final back = PortraitBox.decode(b.encode())!;
    expect([back.x, back.y, back.w, back.h], [0.05, 0.2, 0.25, 0.45]);
    expect(PortraitBox.decode('1.5,0,0.2,0.2'), isNull);
    expect(PortraitBox.decode('0,0,0,0'), isNull);
    expect(PortraitBox.decode('url(x)'), isNull);
    expect(PortraitBox.decode(null), isNull);
  });

  testWidgets('the slot shows only the box of the photo, scaled to fill', (tester) async {
    const box = PortraitBox(0.1, 0.2, 0.25, 0.5);
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 72,
          height: 92,
          child: CroppedPortrait(
            box: box,
            child: ColoredBox(key: ValueKey('photo'), color: Colors.black),
          ),
        ),
      ),
    );
    // The whole photo is drawn at 72/0.25 x 92/0.5, so the box fills the slot.
    final photo = tester.getRect(find.byKey(const ValueKey('photo')));
    expect(photo.width, closeTo(288, 0.01));
    expect(photo.height, closeTo(184, 0.01));
    final slot = tester.getRect(find.byType(CroppedPortrait));
    // The box's top-left corner sits at the slot's.
    expect(photo.left + 0.1 * photo.width, closeTo(slot.left, 0.01));
    expect(photo.top + 0.2 * photo.height, closeTo(slot.top, 0.01));
  });
}
