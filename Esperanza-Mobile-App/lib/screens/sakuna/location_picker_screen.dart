import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/tr.dart';
import '../../models/geo_point.dart';
import '../../services/device_location.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/sakuna_map.dart';

/// What a place is being chosen for.
enum PickPurpose {
  /// Where an emergency is, for a report.
  incident,

  /// Where the resident is, to measure the evacuation centres from.
  here,
}

/// A map to choose one place on (Sakuna, 2026-10-26): tap to place the pin,
/// tap elsewhere to move it, or start from the phone's location. Returns the
/// point, or null when the resident goes back. The written place on the
/// report form is kept either way; a pin is never required to report.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initial, this.purpose = PickPurpose.incident, this.startWithGps = false});

  final GeoPoint? initial;
  final PickPurpose purpose;

  /// Ask the phone first (the form's "Use my location" brings the resident
  /// here to check the pin).
  final bool startWithGps;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  GeoPoint? _point;
  bool _locating = false;
  String? _note;
  bool _noteIsTrouble = false;

  bool get _incident => widget.purpose == PickPurpose.incident;

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
    if (widget.startWithGps) WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
  }

  void _place(GeoPoint p) => setState(() {
    _point = p.rounded();
    if (!_locating && !_noteIsTrouble) _note = null;
  });

  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await DeviceLocation.ask(context);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (result.point case final p?) {
        _point = p;
        _noteIsTrouble = false;
        _note = locationFoundText(incident: _incident, accuracyM: result.accuracyM);
        _map.move(LatLng(p.lat, p.lng), 17);
      } else if (result.problem case final problem?) {
        _noteIsTrouble = true;
        _note = locationProblemText(problem, incident: _incident);
      }
    });
  }

  void _zoom(double by) {
    final camera = _map.camera;
    _map.move(camera.center, (camera.zoom + by).clamp(3, 19));
  }

  @override
  Widget build(BuildContext context) {
    final point = _point;
    return Scaffold(
      appBar: AppBar(title: Text(_incident ? tr('Pin on map') : tr('Choose my place on the map'))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Text(
                _incident ? tr('Tap the map to place the pin. Tap another spot to move it.') : tr('Tap the map where you are.'),
                style: AppTypography.helper,
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SakunaMap(
                      controller: _map,
                      center: point ?? GeoPoint.home,
                      zoom: point == null ? 13 : 17,
                      onTap: _place,
                      semanticLabel: tr('Map. Tap or click to place the pin.'),
                      pins: [
                        if (point != null)
                          MapPin(
                            point: point,
                            size: 44,
                            tipAtPoint: _incident,
                            label: _incident ? tr('Pinned location') : tr('You'),
                            child: _incident ? const PlacePin(size: 44) : const SizedBox(width: 18, height: 18, child: HereMarker()),
                          ),
                      ],
                    ),
                  ),
                  // Zoom without a pinch, for one hand or a shaking one.
                  Positioned(
                    right: AppSpacing.sm,
                    top: AppSpacing.sm,
                    child: Column(
                      children: [
                        _MapButton(icon: Icons.add_rounded, tooltip: 'Zoom in', onPressed: () => _zoom(1)),
                        const SizedBox(height: AppSpacing.xs),
                        _MapButton(icon: Icons.remove_rounded, tooltip: 'Zoom out', onPressed: () => _zoom(-1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    point == null ? tr('Nothing pinned yet.') : '${tr('Pinned at')} ${point.text}',
                    style: AppTypography.helper.copyWith(
                      fontWeight: FontWeight.w600,
                      color: point == null ? AppColors.textMuted : AppColors.emerald700,
                    ),
                  ),
                  if (_note != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _note!,
                      style: AppTypography.helper.copyWith(
                        color: _noteIsTrouble ? AppColors.amber700 : AppColors.textMuted,
                        fontWeight: _noteIsTrouble ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: _locating ? tr('Finding you…') : tr('Use my location'),
                          icon: Icons.my_location_rounded,
                          variant: AppButtonVariant.secondary,
                          loading: _locating,
                          onPressed: _locating ? null : _useMyLocation,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          label: _incident ? tr('Use this location') : tr('Measure from here'),
                          icon: Icons.check_rounded,
                          onPressed: point == null ? null : () => Navigator.of(context).pop(point),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      side: BorderSide(color: AppColors.border),
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.slate700),
      constraints: const BoxConstraints(minWidth: AppSizes.minTouchTarget, minHeight: AppSizes.minTouchTarget),
    ),
  );
}

/// The website's words for a position found (its sakuna-map.js), so the
/// Filipino matches; the accuracy follows in metres.
String locationFoundText({required bool incident, double? accuracyM}) {
  final within = accuracyM == null ? '' : ' (±${accuracyM.round()} m)';
  if (!incident) return '${tr('Measured from where your device is.')}$within';
  return '${tr('Pinned where your device is. If the emergency is somewhere else, tap that spot on the map.')}$within';
}

/// Why no position, and what to do instead: the website's sentences.
String locationProblemText(LocationProblem problem, {required bool incident}) {
  final denied = problem == LocationProblem.denied || problem == LocationProblem.deniedForever;
  if (incident) {
    return denied
        ? tr('Location access was not allowed, so nothing was pinned. Tap the map where the emergency is instead.')
        : tr('Your device could not find its location. Tap the map where the emergency is instead.');
  }
  return denied
      ? tr('Location access was not allowed. Choose your place on the map, or pick your barangay below.')
      : tr('Your device could not find its location. Choose your place on the map, or pick your barangay below.');
}
