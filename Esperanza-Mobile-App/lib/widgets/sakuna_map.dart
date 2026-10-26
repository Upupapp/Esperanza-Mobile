import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/tr.dart';
import '../models/geo_point.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Where the map tiles come from (Sakuna on a real map, 2026-10-26).
/// OpenStreetMap's own servers by default: free, no key, and fine for the
/// light use a municipality's app makes under their tile policy, which asks
/// for the attribution below and an app that names itself. A build points
/// elsewhere with `--dart-define=MAP_TILE_URL=...` (and
/// `MAP_TILE_ATTRIBUTION`) without a code change; see docs/SAKUNA_MAPS.md.
class MapTiles {
  MapTiles._();

  static const url = String.fromEnvironment('MAP_TILE_URL', defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
  static const attribution = String.fromEnvironment('MAP_TILE_ATTRIBUTION', defaultValue: 'OpenStreetMap contributors');
  static const attributionUrl = 'https://www.openstreetmap.org/copyright';
  static const userAgentPackageName = 'ph.gov.esperanza.esperanza_mobile';

  /// Off in widget tests (test/flutter_test_config.dart): tests never touch
  /// the network, so the map draws its markers on a plain ground.
  static bool enabled = true;
}

/// One point on a [SakunaMap].
class MapPin {
  const MapPin({required this.point, required this.child, this.size = 30, this.tipAtPoint = false, this.onTap, this.label});

  final GeoPoint point;
  final Widget child;
  final double size;

  /// A teardrop pin stands on the point; a dot is centred on it.
  final bool tipAtPoint;
  final VoidCallback? onTap;
  final String? label;
}

/// The app's map: OpenStreetMap tiles, the attribution they require, and the
/// pins it is given. Saved coordinates only; nothing is placed at a guessed
/// point. When the tiles cannot load (no signal, the service refusing) it
/// says so over the map and keeps working: the pins and taps still do.
class SakunaMap extends StatefulWidget {
  const SakunaMap({
    super.key,
    this.center = GeoPoint.home,
    this.zoom = 13,
    this.fit = const [],
    this.pins = const [],
    this.onTap,
    this.interactive = true,
    this.controller,
    this.semanticLabel,
  });

  final GeoPoint center;
  final double zoom;

  /// Points to frame when the map opens (two or more); otherwise [center].
  final List<GeoPoint> fit;
  final List<MapPin> pins;
  final void Function(GeoPoint point)? onTap;
  final bool interactive;
  final MapController? controller;
  final String? semanticLabel;

  @override
  State<SakunaMap> createState() => _SakunaMapState();
}

class _SakunaMapState extends State<SakunaMap> {
  int _failed = 0;
  int _attempt = 0;
  Timer? _window;

  bool get _tilesFailed => _failed >= 6;

  @override
  void dispose() {
    _window?.cancel();
    super.dispose();
  }

  void _tileError() {
    if (!mounted || _tilesFailed) return;
    _window ??= Timer(const Duration(seconds: 20), () => _window = null);
    setState(() => _failed++);
  }

  void _retry() => setState(() {
    _failed = 0;
    _attempt++;
  });

  LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

  @override
  Widget build(BuildContext context) {
    final fit = widget.fit.length > 1
        ? CameraFit.coordinates(coordinates: widget.fit.map(_ll).toList(), padding: const EdgeInsets.all(AppSpacing.huge), maxZoom: 15)
        : null;
    final map = FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: _ll(widget.fit.length == 1 ? widget.fit.first : widget.center),
        initialZoom: widget.fit.length == 1 ? 15 : widget.zoom,
        initialCameraFit: fit,
        backgroundColor: AppColors.slate100,
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
        onTap: widget.onTap == null ? null : (_, ll) => widget.onTap!(GeoPoint(ll.latitude, ll.longitude).rounded()),
      ),
      children: [
        if (MapTiles.enabled)
          TileLayer(
            key: ValueKey('tiles-$_attempt'),
            urlTemplate: MapTiles.url,
            userAgentPackageName: MapTiles.userAgentPackageName,
            maxZoom: 19,
            errorTileCallback: (_, _, _) => _tileError(),
          ),
        MarkerLayer(
          markers: [
            for (final pin in widget.pins)
              Marker(
                point: _ll(pin.point),
                width: pin.size,
                height: pin.size,
                alignment: pin.tipAtPoint ? Alignment.topCenter : Alignment.center,
                child: Semantics(
                  label: pin.label,
                  button: pin.onTap != null,
                  child: GestureDetector(onTap: pin.onTap, behavior: HitTestBehavior.opaque, child: pin.child),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution(MapTiles.attribution, onTap: () => launchUrl(Uri.parse(MapTiles.attributionUrl))),
          ],
        ),
      ],
    );
    return Semantics(
      label: widget.semanticLabel,
      child: Stack(
        children: [
          Positioned.fill(child: map),
          if (_tilesFailed)
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Material(
                color: AppColors.amber50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: AppSizes.iconSm, color: AppColors.amber700),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          tr('The map could not load (no connection, or the map service is busy).'),
                          style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.amber700, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(onPressed: _retry, child: Text(tr('Try again'))),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Severity colours, the website's: Critical rose, High orange, Medium amber.
Color severityColor(String? severity) => switch (severity) {
  'Critical' => AppColors.rose600,
  'High' => AppColors.orange500,
  'Medium' || 'Moderate' => AppColors.amber500,
  _ => AppColors.slate500,
};

/// The teardrop pin that marks where an emergency is.
class PlacePin extends StatelessWidget {
  const PlacePin({super.key, this.color = AppColors.rose600, this.size = 40});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    Icons.location_on_rounded,
    size: size,
    color: color,
    shadows: const [Shadow(color: AppColors.mediaScrim, blurRadius: 4)],
  );
}

/// An evacuation centre: teal while open, slate when not.
class CentreMarker extends StatelessWidget {
  const CentreMarker({super.key, required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: open ? AppColors.teal500 : AppColors.slate500,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: AppColors.surface, width: 2),
      boxShadow: const [BoxShadow(color: AppColors.mediaScrim, blurRadius: 4)],
    ),
    child: const Center(child: Icon(Icons.home_work_rounded, size: AppSizes.iconSm, color: AppColors.surface)),
  );
}

/// Where the resident is: a blue dot.
class HereMarker extends StatelessWidget {
  const HereMarker({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.blue500,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.surface, width: 3),
      boxShadow: const [BoxShadow(color: AppColors.mediaScrim, blurRadius: 4)],
    ),
  );
}
