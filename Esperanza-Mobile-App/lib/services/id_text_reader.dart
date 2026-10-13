import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'id_text_parser.dart';

/// Reads the text on the resident's photos of an ID, on the phone (Google
/// ML Kit; owner, 2026-10-13): the photos are not sent anywhere for this, and
/// it works offline. What it finds is only filled into the Add ID form for
/// the resident to check and correct; nothing is saved from it directly.
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
      Future<String> textOf(String? path) async =>
          path == null ? '' : (await recognizer.processImage(InputImage.fromFilePath(path))).text;
      final reading = IdTextParser.parse(kind, await textOf(frontPath), await textOf(backPath));
      return reading.isEmpty ? null : reading;
    } catch (_) {
      // Unreadable photo, missing model: the resident types it instead.
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
