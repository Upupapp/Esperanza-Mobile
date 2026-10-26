import 'geo_point.dart';

/// A citizen-facing evacuation center entry — the mobile-side detail view
/// backing Sakuna's "Evacuation Centers" list. [location] is where staff
/// pinned it (2026-10-26), or null for a centre registered before the map:
/// such a centre is listed, but never placed on the map or measured. A
/// distance is worked out from it and a point the resident chose (the
/// phone's GPS or a tap on the map), never from an address or a barangay.
/// `currentOccupancy` is left null unless the server counts it — per the
/// emergency spec, this app must never invent a fake "X of Y occupied"
/// number.
class EvacuationCenter {
  final String name;
  final String barangay;
  final int totalCapacity;
  final List<String> services;
  final List<String> amenities;
  final String? contactNumber;
  final int? currentOccupancy;

  /// Where it is, as staff pinned it; null when it is not on the map yet.
  final GeoPoint? location;

  /// The street address the Web Admin recorded, when it has one.
  final String? address;

  /// Whether the centre is open to evacuees right now. The backend marks an
  /// opened centre `Processing` and a closed or never-opened one `Archived`
  /// (EvacuationService::openCenter/closeCenter); residents need the plain
  /// answer, not those words.
  final bool isOpen;

  /// Families staying there now, when the office counts them.
  final int? families;

  const EvacuationCenter({
    required this.name,
    required this.barangay,
    required this.totalCapacity,
    this.services = const [],
    this.amenities = const [],
    this.contactNumber,
    this.currentOccupancy,
    this.location,
    this.families,
    this.address,
    this.isOpen = false,
  });

  bool get hasLiveCapacityData => currentOccupancy != null;

  /// The staff Centres tab's thresholds, as the website warns: almost full
  /// from 75%, full at 100% - only for an open centre with a live count.
  String? get occupancyWarning {
    final n = currentOccupancy;
    if (!isOpen || n == null || totalCapacity <= 0) return null;
    final pct = n * 100 / totalCapacity;
    if (pct >= 100) return 'Full: ask the MDRRMO for another centre';
    if (pct >= 75) return 'Almost full';
    return null;
  }
}
