import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Where the holder's face is on the front photo of a kept ID (owner,
/// 2026-10-13): the wallet card shows that crop as its picture. Found on the
/// phone; only the box (fractions of the photo) is saved, never a second image.
@immutable
class PortraitBox {
  const PortraitBox(this.x, this.y, this.w, this.h);

  /// Fractions of the photo's width and height, 0..1.
  final double x;
  final double y;
  final double w;
  final double h;

  /// The card's picture slot, width : height.
  static const slotAspect = 72 / 92;

  /// "x,y,w,h" as the API keeps it.
  String encode() => [x, y, w, h].map((v) => v.clamp(0.0, 1.0).toStringAsFixed(4)).join(',');

  static PortraitBox? decode(String? s) {
    if (s == null) return null;
    final parts = s.split(',').map(double.tryParse).toList();
    if (parts.length != 4 || parts.any((v) => v == null || v < 0 || v > 1)) return null;
    final b = PortraitBox(parts[0]!, parts[1]!, parts[2]!, parts[3]!);
    return (b.w <= 0 || b.h <= 0) ? null : b;
  }

  /// A head-and-shoulders crop around a face found at [face] (pixels) on a
  /// photo [imageW] x [imageH]: a little room around the face, the hair above,
  /// in the card slot's proportions, kept inside the photo.
  static PortraitBox? around(ui.Rect face, double imageW, double imageH) {
    if (imageW <= 0 || imageH <= 0 || face.isEmpty) return null;
    var h = face.height * 1.9;
    var w = h * slotAspect;
    if (w < face.width * 1.3) {
      w = face.width * 1.3;
      h = w / slotAspect;
    }
    // Never larger than the photo, still in proportion.
    final fit = math.min(1.0, math.min(imageW / w, imageH / h));
    w *= fit;
    h *= fit;
    var left = face.center.dx - w / 2;
    var top = face.top - face.height * 0.45;
    // max(0, ...): a crop exactly the photo's size can come out a hair
    // larger in floating point, and clamp refuses an upper bound below 0.
    left = left.clamp(0.0, math.max(0.0, imageW - w));
    top = top.clamp(0.0, math.max(0.0, imageH - h));
    return PortraitBox(left / imageW, top / imageH, w / imageW, h / imageH);
  }
}

class IdPortraitFinder {
  IdPortraitFinder._();

  /// Swapped out by widget tests, where no phone plugin exists.
  @visibleForTesting
  static Future<PortraitBox?> Function(String path, Uint8List bytes)? debugOverride;

  /// The largest face on the photo at [path], or null when none is found (a
  /// web build, an ID without a photo, an unreadable picture): the card then
  /// shows the whole photo.
  static Future<PortraitBox?> find(String? path, Uint8List bytes) async {
    final override = debugOverride;
    if (override != null && path != null) return override(path, bytes);
    if (kIsWeb || path == null) return null;
    final detector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate, minFaceSize: 0.05),
    );
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      if (faces.isEmpty) return null;
      final face = faces.reduce(
        (a, b) => a.boundingBox.width * a.boundingBox.height >= b.boundingBox.width * b.boundingBox.height ? a : b,
      );
      final image = await decodeImageFromList(bytes);
      final box = PortraitBox.around(face.boundingBox, image.width.toDouble(), image.height.toDouble());
      image.dispose();
      return box;
    } catch (_) {
      return null;
    } finally {
      await detector.close();
    }
  }
}

/// Decodes the picture only to learn its size.
Future<ui.Image> decodeImageFromList(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}
