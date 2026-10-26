import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evacuation_center.dart';
import '../../models/geo_point.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../utils/phone_dial.dart';
import '../../widgets/sakuna_map.dart';

import '../../l10n/tr.dart';
/// Full detail view for one evacuation center — services, amenities,
/// where it is, contact, directions, and capacity/status. [distanceKm] is
/// the straight line from the point the resident chose on the centres list
/// (their phone's GPS or a tap on the map) to where staff pinned the centre;
/// without both there is no distance and no "nearest" badge (2026-10-26).
/// [EvacuationCenter.currentOccupancy] is only ever rendered when actually
/// set, never a fabricated number.
class EvacuationCenterDetailScreen extends StatelessWidget {
  final EvacuationCenter center;
  final bool isNearest;
  final double? distanceKm;

  const EvacuationCenterDetailScreen({super.key, required this.center, this.isNearest = false, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(center.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            if (isNearest) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_rounded, size: 14, color: AppColors.emerald700),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      tr('Nearest open centre'),
                      style: TextStyle(
                        fontSize: AppTextSize.label,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald700,
                      ),
                    ),
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
                  decoration: BoxDecoration(
                    color: AppColors.brand50,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.home_work_outlined, size: 22, color: AppColors.brand600),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center.name,
                        style: const TextStyle(
                          fontSize: AppTextSize.card,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [if (center.address != null) center.address!, 'Brgy. ${center.barangay}'].join(' · '),
                        style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Open or not is the first thing an evacuating family
                      // needs; said in words, not colour alone.
                      Text(
                        center.isOpen ? 'Open now, taking evacuees' : 'Not open right now',
                        style: TextStyle(
                          fontSize: AppTextSize.helper,
                          fontWeight: FontWeight.w600,
                          color: center.isOpen ? AppColors.emerald700 : AppColors.slate600,
                        ),
                      ),
                      if (distanceKm != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${distanceText(distanceKm!)} ${tr('away, in a straight line')}',
                          style: const TextStyle(
                            fontSize: AppTextSize.helper,
                            color: AppColors.brand600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Where it is, as staff pinned it; a centre registered before the
            // map says so, and directions search for its name instead.
            const SizedBox(height: AppSpacing.lg),
            if (center.location case final at?) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  height: 190,
                  child: SakunaMap(
                    center: at,
                    zoom: 16,
                    semanticLabel: tr('Map showing where the centre is'),
                    pins: [MapPin(point: at, size: 30, label: center.name, child: CentreMarker(open: center.isOpen))],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(at.text, style: AppTypography.helper),
            ] else
              Text(
                tr('This centre is not on the map yet; directions search for its name and address.'),
                style: AppTypography.helper,
              ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Directions',
                    icon: Icons.directions_rounded,
                    onPressed: () => _openDirections(context),
                  ),
                ),
                if (dialUri(center.contactNumber) != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: tr('Call'),
                      icon: Icons.call_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => launchUrl(dialUri(center.contactNumber)!),
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
                  const Text(
                    'Capacity / Status',
                    style: TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // As the website: capacity only when listed, the people
                  // (and families) here now when counted, "unavailable" only
                  // when neither is known (parity check, 2026-10-26).
                  if (center.totalCapacity > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(icon: Icons.groups_outlined, text: 'Capacity: ${center.totalCapacity} people'),
                  ],
                  if (center.hasLiveCapacityData) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(
                      icon: Icons.people_alt_outlined,
                      text: [
                        'Now here: ${center.currentOccupancy} people',
                        if (center.families != null) '${center.families} families',
                      ].join(', '),
                    ),
                  ],
                  if (center.occupancyWarning != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(icon: Icons.warning_amber_rounded, text: center.occupancyWarning!, warning: true),
                  ],
                  if (center.totalCapacity <= 0 && !center.hasLiveCapacityData) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(icon: Icons.info_outline_rounded, text: tr('Capacity information unavailable'), muted: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ListCard(title: tr('Available Services'), icon: Icons.medical_services_outlined, items: center.services),
            // The server keeps no amenities: the card only ever said "No
            // information available yet."
            if (center.amenities.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _ListCard(title: 'Amenities', icon: Icons.checklist_rounded, items: center.amenities),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (center.contactNumber != null)
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.call_outlined, size: 18, color: AppColors.brand600),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Contact', style: AppTypography.cardTitle),
                    const Spacer(),
                    Text(
                      center.contactNumber!,
                      style: const TextStyle(
                        fontSize: AppTextSize.helper,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    // To the point staff pinned (2026-10-26), as the website does; a centre
    // registered before the map gets a Google Maps text search for its
    // name, recorded address and barangay rather than invented coordinates.
    final at = center.location;
    final uri = at != null
        ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('${at.lat},${at.lng}')}')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent([center.name, ?center.address, 'Brgy. ${center.barangay}', 'Esperanza, Masbate'].join(', '))}',
          );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warning;
  final bool muted;
  const _InfoRow({required this.icon, required this.text, this.warning = false, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final colour = warning ? AppColors.rose700 : (muted ? AppColors.textMuted : AppColors.slate700);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: warning ? AppColors.rose600 : AppColors.slate500),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppTextSize.helper,
              color: colour,
              fontWeight: warning ? FontWeight.w600 : FontWeight.w400,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
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
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTextSize.body,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            Text(
              tr('No information available yet.'),
              style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.emerald500),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
