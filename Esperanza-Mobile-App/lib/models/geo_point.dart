import 'dart:math' as math;

import '../services/json_read.dart';

/// A place on the map, kept the way the backend keeps it (Sakuna on a real
/// map, 2026-10-26): `lat` and `lng`, WGS 84 decimal degrees, both or
/// neither. An incident and an evacuation centre carry the same pair, on the
/// website and here. Never made up: a record without one has none, rather
/// than one at the middle of its barangay.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  /// Esperanza, Masbate: the town (OpenStreetMap node 198506055). Where a map
  /// opens when there is nothing on it yet; never a record's location.
  static const home = GeoPoint(11.7369622, 124.041699);

  /// Both numbers, in range, and not 0, 0 -- the test the API applies.
  static bool valid(double? lat, double? lng) =>
      lat != null &&
      lng != null &&
      lat.isFinite &&
      lng.isFinite &&
      lat.abs() <= 90 &&
      lng.abs() <= 180 &&
      !(lat == 0 && lng == 0);

  /// The pair from an API row (`lat`, `lng`), or null when either is missing
  /// or malformed: half a pin is no pin.
  static GeoPoint? fromJson(Map<String, dynamic> m) {
    final lat = JsonRead.number(m['lat']);
    final lng = JsonRead.number(m['lng']);
    return valid(lat, lng) ? GeoPoint(lat!, lng!) : null;
  }

  /// Rounded to the backend column's seven decimals (about a centimetre).
  GeoPoint rounded() => GeoPoint(_round7(lat), _round7(lng));

  /// What the API is sent: strings, so the same map goes as JSON or as a
  /// multipart form field.
  Map<String, String> toFields() => {'lat': _round7(lat).toStringAsFixed(7), 'lng': _round7(lng).toStringAsFixed(7)};

  /// Straight-line (great-circle) distance in kilometres. Not a road route.
  double distanceKmTo(GeoPoint other) {
    const r = 6371.0088;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(other.lat - lat);
    final dLng = rad(other.lng - lng);
    final h = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat)) * math.cos(rad(other.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(h)));
  }

  /// "11.73696, 124.04170": five decimals, about a metre.
  String get text => '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($text)';
}

double _round7(double v) => (v * 1e7).roundToDouble() / 1e7;

/// "450 m" or "2.3 km", as the website writes a distance.
String distanceText(double km) {
  if (km < 1) return '${math.max(10, ((km * 1000) / 10).round() * 10)} m';
  return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
}
