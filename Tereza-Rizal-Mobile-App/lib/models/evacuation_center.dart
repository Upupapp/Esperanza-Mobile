/// A citizen-facing evacuation center entry — the mobile-side detail view
/// backing Sakuna's "Evacuation Centers" list. `distanceKm` is a
/// simulated value (this app has no real device geolocation wired up —
/// see MockCatalog's doc comment) used only to demonstrate "nearest
/// center" ordering/highlighting; it is never presented as a live GPS
/// reading. `currentOccupancy`/`currentCapacityStatus` are left null by
/// default and only rendered when actually set — per the emergency spec,
/// this app must never invent a fake "X of Y occupied" number, so the
/// detail screen shows "Capacity information unavailable" whenever these
/// are null instead of fabricating a status.
class EvacuationCenter {
  final String name;
  final String barangay;
  final int totalCapacity;
  final List<String> services;
  final List<String> amenities;
  final String? contactNumber;
  final double? distanceKm;
  final int? currentOccupancy;

  const EvacuationCenter({
    required this.name,
    required this.barangay,
    required this.totalCapacity,
    this.services = const [],
    this.amenities = const [],
    this.contactNumber,
    this.distanceKm,
    this.currentOccupancy,
  });

  bool get hasLiveCapacityData => currentOccupancy != null;
}
