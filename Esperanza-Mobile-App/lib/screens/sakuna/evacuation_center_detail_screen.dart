import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evacuation_center.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// Full detail view for one evacuation center — services, amenities,
/// distance, contact, directions, and capacity/status. This app has no
/// real geolocation package wired up (no `geolocator` dependency, no
/// location-permission flow), so [EvacuationCenter.distanceKm] is a
/// simulated stand-in used only to demonstrate the "nearest center"
/// interaction; a real integration would replace it with a live distance
/// computed from the device's actual position, and would need to handle
/// the permission-denied fallback this screen already models by simply
/// omitting distance/nearest-badge when [EvacuationCenter.distanceKm] is
/// null. Likewise, [EvacuationCenter.currentOccupancy] is only ever
/// rendered when actually set — there is no live capacity feed behind
/// this app, so the honest state is "Capacity information unavailable,"
/// never a fabricated number.
class EvacuationCenterDetailScreen extends StatelessWidget {
  final EvacuationCenter center;
  final bool isNearest;

  const EvacuationCenterDetailScreen({super.key, required this.center, this.isNearest = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(center.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            if (isNearest) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, size: 14, color: AppColors.emerald700),
                    const SizedBox(width: 6),
                    const Text('Nearest Evacuation Center', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.emerald700)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.home_work_outlined, size: 22, color: AppColors.brand600),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(center.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Brgy. ${center.barangay}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      if (center.distanceKm != null) ...[
                        const SizedBox(height: 4),
                        Text('${center.distanceKm!.toStringAsFixed(1)} km away (estimated)', style: const TextStyle(fontSize: 12.5, color: AppColors.brand600, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Directions',
                    icon: Icons.directions_rounded,
                    onPressed: () => _openDirections(context),
                  ),
                ),
                if (center.contactNumber != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: 'Call',
                      icon: Icons.call_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => launchUrl(Uri.parse('tel:${center.contactNumber}')),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Capacity / Status', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.groups_outlined, size: 16, color: AppColors.slate500),
                      const SizedBox(width: 8),
                      Text('Total design capacity: ${center.totalCapacity} people', style: const TextStyle(fontSize: 12.5, color: AppColors.slate700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (center.hasLiveCapacityData)
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.slate500),
                        const SizedBox(width: 8),
                        Text('Currently occupied: ${center.currentOccupancy}', style: const TextStyle(fontSize: 12.5, color: AppColors.slate700)),
                      ],
                    )
                  else
                    Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.slate400),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Capacity information unavailable', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ListCard(title: 'Available Services', icon: Icons.medical_services_outlined, items: center.services),
            const SizedBox(height: AppSpacing.lg),
            _ListCard(title: 'Amenities', icon: Icons.checklist_rounded, items: center.amenities),
            const SizedBox(height: AppSpacing.lg),
            if (center.contactNumber != null)
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.call_outlined, size: 18, color: AppColors.brand600),
                    const SizedBox(width: 10),
                    const Text('Contact', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text(center.contactNumber!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brand600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    // No stored lat/lng coordinates exist for these centers (this is a
    // frontend-only build with no real geocoding), so directions use a
    // Google Maps *text search* for the center's name + barangay rather
    // than fabricating coordinates — the maps app resolves the actual
    // location from that query.
    final query = Uri.encodeComponent('${center.name}, Brgy. ${center.barangay}, Esperanza, Masbate');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  const _ListCard({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.brand600),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text('No information available yet.', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontStyle: FontStyle.italic))
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.emerald500),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: const TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.3))),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
