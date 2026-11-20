import 'dart:math';

/// A random (v4) id for one filing, made once per form and sent with every
/// try: the server answers a repeated `client_uuid` with the request it
/// already filed (CitizenRequestController::store), so Submit tapped again
/// after a slow answer never files a second case (flows review, 2026-11-20).
String newClientUuid() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
