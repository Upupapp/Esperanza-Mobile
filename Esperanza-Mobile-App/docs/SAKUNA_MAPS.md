# Sakuna maps in the app

*2026-10-26. The full setup and the provider limits are in the website's
`docs/SAKUNA_MAPS.md`; the API side is in `esperanza-backend/docs/SAKUNA_MAPS.md`.*

## What the app does

- **Report an Incident:** the "Map location (optional)" section offers "Pin on map",
  which opens a full-screen map, and "Use my location". The pin can be moved or
  removed. It is sent as `lat`/`lng` together with the report, or not at all.
- **Evacuation centres:** a list or a map, a barangay filter, and "Nearest open
  centre".
  - Distances are straight lines from the phone's GPS or from a point the resident
    taps.
  - Centres without a pin stay in the list and are never measured.
- **Centre detail:** a small map, the coordinates, and directions to the real point.
- **Incident detail:** where the resident pinned the report.

## Packages and permissions

- **`flutter_map` + `latlong2`:** pure Dart, with OpenStreetMap tiles. There is no
  native map SDK and no API key.
- **`geolocator`:** a native plugin.
  - **Android:** `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` are declared.
  - **iOS:** `NSLocationWhenInUseUsageDescription` is in `ios/Runner/Info.plist`.
- **When location is asked for:** only when the resident taps "Use my location" or
  "Nearest open centre". The app's own explanation comes first (once per phone),
  then the system prompt. Location is never tracked in the background.
- **Android "Location Accuracy" prompt:** Google Play services asks for it. If the
  resident answers No thanks, the app asks Android's own location manager instead
  of failing (`lib/services/device_location.dart`).

**macOS lane:** `geolocator` adds native iOS code. Build and check iOS (permission
text, first prompt, `Package.resolved`) before the next iOS release.

## Build settings (`--dart-define`)

| Name | Default |
|---|---|
| `MAP_TILE_URL` | `https://tile.openstreetmap.org/{z}/{x}/{y}.png` |
| `MAP_TILE_ATTRIBUTION` | `OpenStreetMap contributors` |

The app identifies itself to the tile servers as
`ph.gov.esperanza.esperanza_mobile`, as OpenStreetMap's tile policy requires.

## Tests

- `test/flutter_test_config.dart` turns tiles off and replaces GPS with a stub, so
  no test touches the network or a device.
- `test/sakuna_map_test.dart` covers:
  - the pair rules and distances;
  - a report with a pin, without one, and with location refused;
  - the map picker;
  - nearest open centre;
  - the barangay filter and the map;
  - centre and incident details;
  - the "No thanks" fallback.
