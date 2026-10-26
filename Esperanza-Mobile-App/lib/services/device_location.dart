import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';
import '../utils/protected_action.dart';

/// Why the phone gave no position. Each has an alternative on screen: tap
/// the map, or choose the barangay. A report is never held up by one.
enum LocationProblem { denied, deniedForever, serviceOff, unavailable }

/// What asking the phone where it is came to: a [point] (with its accuracy
/// in metres), a [problem], or neither when the resident chose Not Now.
class LocationResult {
  const LocationResult.found(GeoPoint this.point, {this.accuracyM}) : problem = null;
  const LocationResult.failed(LocationProblem this.problem) : point = null, accuracyM = null;
  const LocationResult.cancelled() : point = null, problem = null, accuracyM = null;

  final GeoPoint? point;
  final double? accuracyM;
  final LocationProblem? problem;

  bool get cancelled => point == null && problem == null;
}

/// The phone's position, for Sakuna's map (2026-10-26): "Use my location"
/// on an incident report and the nearest open evacuation centre. Asked only
/// when the resident taps one of those, after the explanation in
/// [confirmLocationUse]; once, in the foreground, never tracked.
class DeviceLocation {
  DeviceLocation._();

  /// The operating system's answer. Swapped in tests: there is no GPS in a
  /// widget test, and tests never touch a device service.
  static Future<LocationResult> Function() locate = fromPlatform;

  /// The operating system's own answer, through geolocator.
  static Future<LocationResult> fromPlatform() => _locate();

  /// The explanation first (once per phone), then [locate]. A position that
  /// the settings block outright offers the Settings dialog.
  static Future<LocationResult> ask(BuildContext context) async {
    if (!await confirmLocationUse(context)) return const LocationResult.cancelled();
    final result = await locate();
    if (result.problem == LocationProblem.deniedForever && context.mounted) {
      await showPermissionSettingsDialog(context);
    }
    return result;
  }
}

Future<LocationResult> _locate() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.failed(LocationProblem.serviceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failed(LocationProblem.deniedForever);
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
      return const LocationResult.failed(LocationProblem.denied);
    }
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(locationSettings: _settings());
    } on LocationServiceDisabledException {
      // Android: Google's "Location Accuracy" prompt answered No thanks
      // fails the request although the phone's own GPS is on (seen on the
      // emulator, 2026-10-26). Ask the platform's location manager instead.
      if (!await Geolocator.isLocationServiceEnabled()) rethrow;
      position = await Geolocator.getCurrentPosition(locationSettings: _settings(plainAndroid: true));
    }
    if (!GeoPoint.valid(position.latitude, position.longitude)) {
      return const LocationResult.failed(LocationProblem.unavailable);
    }
    return LocationResult.found(
      GeoPoint(position.latitude, position.longitude).rounded(),
      accuracyM: position.accuracy > 0 ? position.accuracy : null,
    );
  } on LocationServiceDisabledException {
    return const LocationResult.failed(LocationProblem.serviceOff);
  } on PermissionDeniedException {
    return const LocationResult.failed(LocationProblem.denied);
  } on TimeoutException {
    return const LocationResult.failed(LocationProblem.unavailable);
  } catch (_) {
    return const LocationResult.failed(LocationProblem.unavailable);
  }
}

/// High accuracy, twenty seconds at most. On Android, [plainAndroid] skips
/// Google Play services and reads the platform's own location manager.
LocationSettings _settings({bool plainAndroid = false}) {
  const limit = Duration(seconds: 20);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(accuracy: LocationAccuracy.high, timeLimit: limit, forceLocationManager: plainAndroid);
  }
  return const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: limit);
}
