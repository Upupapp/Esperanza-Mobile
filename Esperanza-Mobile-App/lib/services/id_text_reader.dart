import 'package:flutter/foundation.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'id_text_parser.dart';

/// Reads the text on the resident's photos of an ID, on the phone (Google
/// ML Kit; owner, 2026-10-13): the photos are not sent anywhere for this, and
/// it works offline. What it finds is only filled into the Add ID form for
/// the resident to check and correct; nothing is saved from it directly.
///
/// Each line goes to the parser with where it sits on the photo, so a label
/// is paired with the value printed by it rather than whatever the reader
/// listed next; and the National ID's QR code is read too (2026-10-14).
class IdTextReader {
  IdTextReader._();

  /// Swapped out by widget tests, where no phone plugin exists.
  @visibleForTesting
  static Future<IdReading?> Function(String kind, {String? frontPath, String? backPath})? debugOverride;

  /// Null when nothing could be read (no photo path, a web build, or the
  /// reader failed): the form simply stays as typed.
  static Future<IdReading?> read(String kind, {String? frontPath, String? backPath}) async {
    final override = debugOverride;
    if (override != null) return override(kind, frontPath: frontPath, backPath: backPath);
    if (kIsWeb || (frontPath == null && backPath == null)) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      Future<List<IdTextLine>> linesOf(String? path) async {
        if (path == null) return const [];
        final text = await recognizer.processImage(InputImage.fromFilePath(path));
        return [
          for (final block in text.blocks)
            for (final line in block.lines)
              IdTextLine(
                line.text,
                left: line.boundingBox.left,
                top: line.boundingBox.top,
                right: line.boundingBox.right,
                bottom: line.boundingBox.bottom,
              ),
        ];
      }

      final reading = IdTextParser.parseLines(
        kind,
        front: await linesOf(frontPath),
        back: await linesOf(backPath),
        codes: kind == 'philippine_national_id' ? await _qrCodes([?backPath, ?frontPath]) : const [],
      );
      return reading.isEmpty ? null : reading;
    } catch (_) {
      // Unreadable photo, missing model: the resident types it instead.
      return null;
    } finally {
      await recognizer.close();
    }
  }

  /// The QR codes on [paths]; none when the scanner fails, so the printed
  /// text is still read.
  static Future<List<String>> _qrCodes(List<String> paths) async {
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      return [
        for (final path in paths)
          for (final code in await scanner.processImage(InputImage.fromFilePath(path)))
            if (code.rawValue case final value? when value.isNotEmpty) value,
      ];
    } catch (_) {
      return const [];
    } finally {
      await scanner.close();
    }
  }
}
