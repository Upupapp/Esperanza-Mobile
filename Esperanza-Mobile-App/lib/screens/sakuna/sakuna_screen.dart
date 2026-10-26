import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/access_level.dart';
import '../../models/evacuation_center.dart';
import '../../utils/balita_post_actions.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_state_view.dart';
import '../home/root_shell.dart';
import '../shared/request_list_screen.dart';
import 'evacuation_center_detail_screen.dart';
import '../../services/json_read.dart';
import '../../utils/phone_dial.dart';
import '../../services/requests_service.dart';
import '../../services/citizen_session_service.dart';
import '../../services/sakuna_alerts.dart';
import '../../utils/date_text.dart';
import '../../widgets/esperanza_art.dart';

import '../../l10n/tr.dart';
/// GET /hotlines (public, PublicContentController::hotlines).
Future<List<(String, String, String?)>> _loadHotlines() async {
  final res = await api.get('/hotlines');
  return JsonRead.rows(res.list, (m) {
    final office = JsonRead.nonEmpty(m['office']) ?? JsonRead.nonEmpty(m['name']);
    final contact = JsonRead.nonEmpty(m['contact']) ?? JsonRead.nonEmpty(m['number']);
    // A hotline with no number is not a hotline.
    if (contact == null) return null;
    // Who answers it, as the website shows under the office.
    return (office ?? 'Hotline', contact, JsonRead.nonEmpty(m['position']));
  });
}

/// GET /sakuna/centers (public, PublicContentController::centers) --
/// SakunaCenter has no `amenities`/`contactNumber` column, so those stay
/// empty/null rather than fabricated (matching EvacuationCenter's own
/// existing "never invent a fake occupancy number" design). `currentOccupancy`
/// is finally live data instead of always null, now that a real endpoint
/// exists.
Future<List<EvacuationCenter>> _loadEvacuationCenters() async {
  final rows = await api.getAllPages('/sakuna/centers', query: {'per_page': 100});
  return JsonRead.rows(rows, (m) {
    final name = JsonRead.nonEmpty(m['name']);
    if (name == null) return null;
    return EvacuationCenter(
      name: name,
      barangay: JsonRead.string(m['barangay']) ?? '',
      totalCapacity: JsonRead.integer(m['capacity']) ?? 0,
      // Was `.cast<String>()`, which throws lazily -- at render time, inside
      // the list's build -- the first time a service arrives as anything
      // but a string.
      services: JsonRead.strings(m['services']),
      currentOccupancy: JsonRead.integer(m['individuals']),
      families: JsonRead.integer(m['families']),
      address: JsonRead.nonEmpty(m['address']),
      isOpen: JsonRead.nonEmpty(m['status']) == 'Processing',
    );
  });
}

/// Sakuna (Disaster Risk Reduction & Emergency Ops) — citizen-appropriate
/// slice of the Web Admin's much larger Sakuna module (Command Center,
/// Vulnerability Assessment, Resources, Damage Assessment, etc. are
/// staff-only and never belong on mobile — see Section 6/11 of the
/// alignment doc). Citizens get: read-only hotlines/evacuation-center
/// info, and the ability to report an incident + track its status, reusing
/// the same request pipeline as Dokyu/Tulong.
typedef _SakunaData = ({List<(String, String, String?)> hotlines, List<EvacuationCenter> centers});

class SakunaScreen extends StatefulWidget {
  const SakunaScreen({super.key});

  @override
  State<SakunaScreen> createState() => _SakunaScreenState();
}

class _SakunaScreenState extends State<SakunaScreen> {
  /// Bumped by pull-to-refresh: alerts, hotlines and centres are rebuilt
  /// under a new key, so each loads again. During a typhoon the tab stays
  /// open for hours, and the only way to see a new alert used to be
  /// restarting the app.
  int _generation = 0;

  Future<_SakunaData> _load() async {
    final results = await Future.wait([_loadHotlines(), _loadEvacuationCenters()]);
    return (hotlines: results[0] as List<(String, String, String?)>, centers: results[1] as List<EvacuationCenter>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Clear, over RootShell's GlassBackdrop: the glass cards show its colour.
      backgroundColor: AppColors.clear,
      appBar: AppBar(
        leading: const ShellMenuButton(),title: const Text('Risk Reduction & Emergency'), actions: const [AlertsAction()]),
      // Bottom padding must include the inherited navbar MediaQuery inset
      // (RootShell's extendBody: true publishes it — see
      // widgets/esperanza_curved_navbar.dart) on top of the visual
      // breathing room, or the last evacuation-center card ends up laid
      // out underneath the floating navbar's bounding box and can't be
      // scrolled fully into view — same pattern as balita_screen.dart.
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _generation++),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            // Dials 911 on tap: in a life-threatening emergency, the banner that
            // says "call 911" should be the fastest way to do it.
            Semantics(
              button: true,
              label: 'Call 911. In a life-threatening emergency, call 911 or MDRRMO directly.',
              excludeSemantics: true,
              child: Material(
                color: AppColors.rose600,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => launchUrl(Uri.parse('tel:911')),
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          // The website's two lines, in the chosen language.
                          child: Text(
                            '${tr('In a life-threatening emergency, call 911.')} '
                            '${tr('Or call the MDRRMO directly, or one of the hotlines below.')}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: AppTextSize.helper,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Icon(Icons.call_rounded, color: Colors.white, size: AppSizes.iconBase),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _AlertsSection(key: ValueKey('alerts-$_generation')),
            const SizedBox(height: AppSpacing.sectionGap),
            // Reporting an incident has no dependency on the hotlines/centers
            // fetch below -- it must stay reachable even if that fetch fails,
            // so it renders unconditionally rather than living inside the
            // AsyncStateView gate.
            AppButton(
              label: tr('Report an Incident'),
              icon: Icons.report_outlined,
              variant: AppButtonVariant.danger,
              fullWidth: true,
              size: AppButtonSize.lg,
              onPressed: () => requireAccountForBalita(
                context,
                'Reporting an incident',
                // Open to unverified citizens (the backend's own rule); a guest
                // is asked to sign in instead of meeting a refused request.
                minLevel: AccessLevel.unverified,
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    // Loads the citizen's own reports from GET /citizen/incidents
                    // before the list renders; it read /citizen/requests, which
                    // never holds an incident, so the list was always empty.
                    builder: (context) => AsyncStateView<void>(
                      loader: () => context.read<RequestsService>().loadIncidents(),
                      builder: (context, _, reload) => const RequestListScreen(
                        category: ServiceCategory.sakunaIncident,
                        title: 'Incident Reports',
                        subtitle: 'Report and track disaster/emergency incidents.',
                        // The report form asks what is happening itself
                        // (lib/models/incident_types.dart).
                        catalog: [],
                        accent: AppColors.rose600,
                        icon: Icons.report_outlined,
                        pushed: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AsyncStateView<_SakunaData>(
              key: ValueKey('directory-$_generation'),
              loader: _load,
              builder: (context, data, reload) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Emergency Hotlines'), style: AppTypography.subsectionLabel),
                  const SizedBox(height: AppSpacing.md),
                  if (data.hotlines.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(tr('No hotlines listed yet.'), style: TextStyle(color: AppColors.textMuted)),
                    ),
                  ...data.hotlines.map(
                    (h) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                      child: _HotlineTile(office: h.$1, contact: h.$2, position: h.$3),
                    ),
                  ),
                  // The last tile's own 12, plus 12: a section's 24.
                  const SizedBox(height: AppSpacing.md),
                  _EvacuationCentersSection(
                    centers: data.centers,
                    mine: context.watch<CitizenSessionService>().account?.barangay,
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

/// Sorted by [EvacuationCenter.distanceKm] (a simulated stand-in for real
/// device geolocation — see EvacuationCenterDetailScreen's doc comment)
/// so the nearest center leads the list and is clearly labeled — not
/// merely color-coded — with a badge, per the emergency spec's "do not
/// rely only on color" requirement. Centers without a distance value
/// (the state a real "location permission denied" fallback would produce)
/// still render normally, just without a distance line or nearest badge —
/// manual browsing always works regardless of location availability.
class _EvacuationCentersSection extends StatelessWidget {
  const _EvacuationCentersSection({required this.centers, this.mine});

  final List<EvacuationCenter> centers;

  /// The resident's barangay: its centres lead, as on the website.
  final String? mine;

  bool _isMine(EvacuationCenter c) => mine != null && mine!.isNotEmpty && c.barangay == mine;

  @override
  Widget build(BuildContext context) {
    // The website's order: the resident's barangay first, open ones first,
    // then by barangay and name (a distance, if one ever exists, after that).
    int flag(bool v) => v ? 0 : 1;
    final sorted = [...centers]
      ..sort((a, b) {
        final byMine = flag(_isMine(a)).compareTo(flag(_isMine(b)));
        if (byMine != 0) return byMine;
        final byOpen = flag(a.isOpen).compareTo(flag(b.isOpen));
        if (byOpen != 0) return byOpen;
        final byBarangay = a.barangay.compareTo(b.barangay);
        return byBarangay != 0 ? byBarangay : a.name.compareTo(b.name);
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
            padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
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
                    decoration: BoxDecoration(
                      color: AppColors.brand50,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
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
                                style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c == nearest) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald50,
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.near_me_rounded, size: 10, color: AppColors.emerald700),
                                    SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Nearest',
                                      style: TextStyle(
                                        fontSize: AppTextSize.fine,
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
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _OpenChip(isOpen: c.isOpen),
                            if (_isMine(c)) _Tag(tr('In your barangay'), AppColors.brand50, AppColors.brand700),
                            if (c.occupancyWarning case final w?) _Tag(w, AppColors.amber50, AppColors.amber700),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          [
                            if (c.address != null) c.address!,
                            'Brgy. ${c.barangay}',
                            if (c.distanceKm != null) '${c.distanceKm!.toStringAsFixed(1)} km',
                            // "Is there room?" is the question during an
                            // evacuation: the live headcount when the backend
                            // has one, capacity alone when it does not.
                            c.hasLiveCapacityData && c.totalCapacity > 0
                                ? '${c.currentOccupancy} of ${c.totalCapacity} people'
                                : c.totalCapacity > 0
                                ? 'Capacity: ${c.totalCapacity} people'
                                : 'Capacity not listed',
                            if (c.families != null) '${c.families} ${c.families == 1 ? 'family' : 'families'}',
                          ].join(' · '),
                          style: AppTypography.helper,
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

/// One emergency hotline. Name above, number below, and the whole card is
/// the call target with a 44pt call button -- the number used to sit beside
/// the name, squeezed until "0917 123 4567 / 0998 765 4321" wrapped across
/// lines, and the only tappable part was the small red text and a 14pt icon.
/// Only the first number is dialled (see [dialUri]); the full text stays
/// visible so a second line can still be read and dialled by hand.
class _HotlineTile extends StatelessWidget {
  const _HotlineTile({required this.office, required this.contact, this.position});

  final String office;
  final String contact;
  final String? position;

  @override
  Widget build(BuildContext context) {
    final uri = dialUri(contact);
    // container: its own node. Without it these flags merge into the
    // nearest ancestor and the whole section reads as one button.
    return Semantics(
      container: true,
      button: uri != null,
      label: [uri == null ? office : 'Call $office', ?position, contact].join(', '),
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        onTap: uri == null ? null : () => launchUrl(uri),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    office,
                    style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  if (position != null) Text(position!, style: AppTypography.helper),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    contact,
                    style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600, color: AppColors.rose700),
                  ),
                ],
              ),
            ),
            if (uri != null) ...[
              const SizedBox(width: AppSpacing.md),
              Container(
                width: AppSizes.minTouchTarget,
                height: AppSizes.minTouchTarget,
                decoration: const BoxDecoration(color: AppColors.rose50, shape: BoxShape.circle),
                child: const Icon(Icons.call_rounded, size: AppSizes.iconBase, color: AppColors.rose600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Emergency alerts the Municipality has published (public GET /alerts):
/// typhoon signals, evacuation orders, advisories. The tab used to show
/// hotlines and centres only, so an alert the MDRRMO published never
/// reached a resident through the app. Loaded on its own, so a failure here
/// never hides the hotlines, and scoped to the citizen's barangay
/// (municipality-wide alerts included).
class _AlertsSection extends StatefulWidget {
  const _AlertsSection({super.key});

  @override
  State<_AlertsSection> createState() => _AlertsSectionState();
}

class _AlertsSectionState extends State<_AlertsSection> {
  late Future<List<PublicAlert>> _alerts = _load();

  Future<List<PublicAlert>> _load() =>
      SakunaAlerts.load(barangay: context.read<CitizenSessionService>().account?.barangay);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PublicAlert>>(
      future: _alerts,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Text(tr('Checking for emergency alerts…'), style: AppTypography.helper);
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(child: Text(tr('Emergency alerts could not be checked.'), style: AppTypography.helper)),
              TextButton(onPressed: () => setState(() => _alerts = _load()), child: Text(tr('Try Again'))),
            ],
          );
        }
        final alerts = snapshot.data!;
        if (alerts.isEmpty) {
          return Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: AppSizes.iconSm, color: AppColors.emerald700),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(tr('No emergency alerts in force right now.'), style: AppTypography.helper)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr('Active Alerts'), style: AppTypography.subsectionLabel),
            const SizedBox(height: AppSpacing.md),
            // 12 between alerts and none after the last: the section gap
            // below is the same with alerts or without.
            for (var i = 0; i < alerts.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.itemGap),
              _AlertCard(alert: alerts[i]),
            ],
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final PublicAlert alert;

  @override
  Widget build(BuildContext context) {
    final kind = [?alert.type, ?alert.levelLabel].join(' · ');
    final where = alert.barangays.isEmpty ? tr('All barangays') : alert.barangays.map((b) => 'Brgy. $b').join(', ');
    return Semantics(
      container: true,
      label: tr('Emergency alert'),
      child: GlassSurface(
        radius: AppRadius.xl,
        padding: const EdgeInsets.all(AppSpacing.lg),
        tint: AppColors.rose50,
        tintEnd: AppColors.rose50,
        rim: AppColors.rose600,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.campaign_rounded, color: AppColors.rose600, size: AppSizes.iconBase),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kind.isNotEmpty) ...[
                    Text(kind, style: AppTypography.labelText.copyWith(color: AppColors.rose700)),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(alert.title, style: AppTypography.cardHeading),
                  if (alert.body.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(alert.body, style: AppTypography.bodyText),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    [
                      where,
                      if (alert.publishedAt != null) timeAgo(alert.publishedAt!),
                      // When the office set it to end, as the website says it.
                      if (alert.expiresAt != null) 'Until ${dateAndTime(alert.expiresAt!)}',
                    ].join(' · '),
                    style: AppTypography.helper,
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

/// Whether a centre is taking evacuees now: said in words and colour, never
/// colour alone.
class _OpenChip extends StatelessWidget {
  const _OpenChip({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? AppColors.emerald50 : AppColors.slate100,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        isOpen ? 'Open now' : 'Not open',
        style: TextStyle(
          fontSize: AppTextSize.fine,
          fontWeight: FontWeight.w700,
          color: isOpen ? AppColors.emerald700 : AppColors.slate600,
        ),
      ),
    );
  }
}

/// A small label beside a centre's open/closed chip.
class _Tag extends StatelessWidget {
  const _Tag(this.text, this.background, this.foreground);

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.full)),
    child: Text(text, style: AppTypography.fine.copyWith(color: foreground, fontWeight: FontWeight.w700)),
  );
}
