import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/evacuation_center.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/esperanza_drawer.dart';
import '../home/root_shell.dart';
import '../shared/request_list_screen.dart';
import 'evacuation_center_detail_screen.dart';

/// GET /hotlines (public, PublicContentController::hotlines).
Future<List<(String, String)>> _loadHotlines() async {
  final res = await api.get('/hotlines');
  return res.list.map((raw) {
    final m = raw as Map<String, dynamic>;
    return (m['office'] as String? ?? '', m['contact'] as String? ?? '');
  }).toList();
}

/// GET /sakuna/centers (public, PublicContentController::centers) --
/// SakunaCenter has no `amenities`/`contactNumber` column, so those stay
/// empty/null rather than fabricated (matching EvacuationCenter's own
/// existing "never invent a fake occupancy number" design). `currentOccupancy`
/// is finally live data instead of always null, now that a real endpoint
/// exists.
Future<List<EvacuationCenter>> _loadEvacuationCenters() async {
  final res = await api.get('/sakuna/centers', query: {'per_page': 100});
  return res.list.map((raw) {
    final m = raw as Map<String, dynamic>;
    return EvacuationCenter(
      name: m['name'] as String? ?? '',
      barangay: m['barangay'] as String? ?? '',
      totalCapacity: (m['capacity'] as num?)?.toInt() ?? 0,
      services: (m['services'] as List?)?.cast<String>() ?? const [],
      currentOccupancy: (m['individuals'] as num?)?.toInt(),
    );
  }).toList();
}

/// Sakuna (Disaster Risk Reduction & Emergency Ops) — citizen-appropriate
/// slice of the Web Admin's much larger Sakuna module (Command Center,
/// Vulnerability Assessment, Resources, Damage Assessment, etc. are
/// staff-only and never belong on mobile — see Section 6/11 of the
/// alignment doc). Citizens get: read-only hotlines/evacuation-center
/// info, and the ability to report an incident + track its status, reusing
/// the same request pipeline as Dokyu/Tulong.
typedef _SakunaData = ({List<(String, String)> hotlines, List<EvacuationCenter> centers});

class SakunaScreen extends StatelessWidget {
  const SakunaScreen({super.key});

  Future<_SakunaData> _load() async {
    final results = await Future.wait([_loadHotlines(), _loadEvacuationCenters()]);
    return (hotlines: results[0] as List<(String, String)>, centers: results[1] as List<EvacuationCenter>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(title: const Text('Risk Reduction & Emergency'), actions: const [AlertsAction()]),
      // Bottom padding must include the inherited navbar MediaQuery inset
      // (RootShell's extendBody: true publishes it — see
      // widgets/esperanza_curved_navbar.dart) on top of the visual
      // breathing room, or the last evacuation-center card ends up laid
      // out underneath the floating navbar's bounding box and can't be
      // scrolled fully into view — same pattern as balita_screen.dart.
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + MediaQuery.paddingOf(context).bottom),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.rose600, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'In a life-threatening emergency, call 911 or MDRRMO directly.',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Reporting an incident has no dependency on the hotlines/centers
          // fetch below -- it must stay reachable even if that fetch fails,
          // so it renders unconditionally rather than living inside the
          // AsyncStateView gate.
          AppButton(
            label: 'Report an Incident',
            icon: Icons.report_outlined,
            variant: AppButtonVariant.danger,
            fullWidth: true,
            size: AppButtonSize.lg,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RequestListScreen(
                  category: ServiceCategory.sakunaIncident,
                  title: 'Incident Reports',
                  subtitle: 'Report and track disaster/emergency incidents.',
                  // Stays local: POST /citizen/incidents takes a free-text
                  // type/severity, not a value validated against any
                  // server-side catalog, so there's nothing to fetch here.
                  catalog: MockCatalog.incidentTypes,
                  accent: AppColors.rose600,
                  icon: Icons.report_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          AsyncStateView<_SakunaData>(
            loader: _load,
            builder: (context, data, reload) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Emergency Hotlines', style: AppTypography.subsectionLabel),
                const SizedBox(height: AppSpacing.md),
                if (data.hotlines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text('No hotlines listed yet.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ...data.hotlines.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(h.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                          InkWell(
                            onTap: () => launchUrl(Uri.parse('tel:${h.$2}')),
                            child: Row(
                              children: [
                                Text(
                                  h.$2,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.rose600,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(Icons.call_rounded, size: 14, color: AppColors.rose600),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _EvacuationCentersSection(centers: data.centers),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sorted by [EvacuationCenter.distanceKm] (a simulated stand-in for real
/// device geolocation — see EvacuationCenterDetailScreen's doc comment)
/// so the nearest center leads the list and is clearly labeled — not
/// merely color-coded — with a badge, per the emergency spec's "do not
/// rely only on color" requirement. Centers without a distance value
/// (the state a real "location permission denied" fallback would produce)
/// still render normally, just without a distance line or nearest badge —
/// manual browsing always works regardless of location availability.
class _EvacuationCentersSection extends StatelessWidget {
  const _EvacuationCentersSection({required this.centers});

  final List<EvacuationCenter> centers;

  @override
  Widget build(BuildContext context) {
    final sorted = [...centers]
      ..sort((a, b) {
        if (a.distanceKm == null && b.distanceKm == null) return 0;
        if (a.distanceKm == null) return 1;
        if (b.distanceKm == null) return -1;
        return a.distanceKm!.compareTo(b.distanceKm!);
      });
    // No center ever carries a real distanceKm today (this app has no
    // geolocation wired up, and SakunaCenter has no lat/lng at all) -- the
    // old orElse fallback used to badge whichever center happened to sort
    // first as "Nearest" regardless, which is exactly the fabricated-signal
    // mistake this app's own design principle exists to prevent. `nearest`
    // must stay null, and no badge shows, unless a real distance exists.
    final withDistance = sorted.where((c) => c.distanceKm != null);
    final nearest = withDistance.isEmpty ? null : withDistance.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evacuation Centers', style: AppTypography.subsectionLabel),
        const SizedBox(height: AppSpacing.md),
        if (sorted.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('No evacuation centers listed yet.', style: TextStyle(color: AppColors.textMuted)),
          ),
        for (final c in sorted) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EvacuationCenterDetailScreen(center: c, isNearest: c == nearest),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.home_work_outlined, size: 17, color: AppColors.brand600),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                c.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c == nearest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald50,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.near_me_rounded, size: 10, color: AppColors.emerald700),
                                    SizedBox(width: 3),
                                    Text(
                                      'Nearest',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.emerald700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          c.distanceKm != null
                              ? 'Brgy. ${c.barangay} · ${c.distanceKm!.toStringAsFixed(1)} km · Capacity: ${c.totalCapacity}'
                              : 'Brgy. ${c.barangay} · Capacity: ${c.totalCapacity}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
