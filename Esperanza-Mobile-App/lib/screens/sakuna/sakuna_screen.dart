import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/access_level.dart';
import '../../models/evacuation_center.dart';
import '../../models/geo_point.dart';
import '../../services/device_location.dart';
import '../../widgets/sakuna_map.dart';
import 'location_picker_screen.dart';
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
import 'my_shelter_screen.dart';
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
/// exists; `lat`/`lng` (2026-10-26) where staff pinned the centre, or none.
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
      location: GeoPoint.fromJson(m),
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
            const SizedBox(height: AppSpacing.itemGap),
            // The family's own stays and relief, confirming an item came, and
            // a household list kept ready (2026-10-27, Phase 3).
            AppButton(
              label: tr('My Shelter and Relief'),
              icon: Icons.family_restroom_rounded,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => requireAccountForBalita(
                context,
                'Your shelter and relief records',
                minLevel: AccessLevel.unverified,
                () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyShelterScreen())),
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

/// The evacuation centres, as on the website (2026-10-26): a list or a map,
/// by barangay, and the nearest open centre. A distance is a straight line
/// from a point the resident chose -- the phone's GPS or a tap on the map --
/// to a centre staff pinned; never from an address or a barangay name. A
/// centre without a pin stays in the list and is never measured. "Nearest"
/// is said in words (a badge), not colour alone, and only among open
/// centres; it is not offered as the safest or quickest way to go.
class _EvacuationCentersSection extends StatefulWidget {
  const _EvacuationCentersSection({required this.centers, this.mine});

  final List<EvacuationCenter> centers;

  /// The resident's barangay: its centres lead, as on the website.
  final String? mine;

  @override
  State<_EvacuationCentersSection> createState() => _EvacuationCentersSectionState();
}

class _EvacuationCentersSectionState extends State<_EvacuationCentersSection> {
  bool _showMap = false;
  String? _barangay;
  GeoPoint? _here;
  bool _hereFromGps = false;
  double? _accuracy;
  bool _locating = false;
  LocationProblem? _problem;

  bool _isMine(EvacuationCenter c) => widget.mine != null && widget.mine!.isNotEmpty && c.barangay == widget.mine;

  double? _distance(EvacuationCenter c) {
    final here = _here;
    final at = c.location;
    return here == null || at == null ? null : here.distanceKmTo(at);
  }

  List<EvacuationCenter> get _placed => widget.centers.where((c) => c.location != null).toList();

  List<String> get _barangays => {for (final c in widget.centers) if (c.barangay.isNotEmpty) c.barangay}.toList()..sort();

  /// The website's order: the resident's barangay first, open ones first,
  /// then by barangay and name. With a point to measure from, the open
  /// centres on the map come first, nearest first.
  List<EvacuationCenter> get _shown {
    int flag(bool v) => v ? 0 : 1;
    final rows = widget.centers.where((c) => _barangay == null || c.barangay == _barangay).toList()
      ..sort((a, b) {
        final byMine = flag(_isMine(a)).compareTo(flag(_isMine(b)));
        if (byMine != 0) return byMine;
        final byOpen = flag(a.isOpen).compareTo(flag(b.isOpen));
        if (byOpen != 0) return byOpen;
        final byBarangay = a.barangay.compareTo(b.barangay);
        return byBarangay != 0 ? byBarangay : a.name.compareTo(b.name);
      });
    if (_here == null) return rows;
    final order = {for (var i = 0; i < rows.length; i++) rows[i]: i};
    return rows
      ..sort((a, b) {
        final da = a.isOpen ? _distance(a) : null;
        final db = b.isOpen ? _distance(b) : null;
        final measured = flag(da != null).compareTo(flag(db != null));
        if (measured != 0) return measured;
        if (da != null && db != null) return da.compareTo(db);
        return order[a]!.compareTo(order[b]!);
      });
  }

  /// The nearest OPEN centre with a pin, across every barangay.
  ({EvacuationCenter centre, double km})? get _nearest {
    ({EvacuationCenter centre, double km})? best;
    for (final c in widget.centers) {
      if (!c.isOpen) continue;
      final d = _distance(c);
      if (d != null && (best == null || d < best.km)) best = (centre: c, km: d);
    }
    return best;
  }

  String _distanceLabel(EvacuationCenter c) {
    final d = _distance(c);
    return d == null ? '' : '${distanceText(d)} ${tr('away, in a straight line')}';
  }

  Future<void> _findNearest() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await DeviceLocation.ask(context);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (result.point case final p?) {
        _here = p;
        _hereFromGps = true;
        _accuracy = result.accuracyM;
        _problem = null;
      } else if (result.problem case final problem?) {
        _problem = problem;
      }
    });
  }

  Future<void> _pickHere() async {
    final picked = await Navigator.of(context).push<GeoPoint>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(initial: _here, purpose: PickPurpose.here)),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _here = picked;
      _hereFromGps = false;
      _accuracy = null;
      _problem = null;
    });
  }

  void _open(EvacuationCenter c) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EvacuationCenterDetailScreen(
        center: c,
        isNearest: _nearest?.centre == c,
        distanceKm: _distance(c),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final placed = _placed;
    final nearest = _nearest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Evacuation Centres'), style: AppTypography.subsectionLabel),
        const SizedBox(height: AppSpacing.md),
        if (widget.centers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(tr('No evacuation centres listed yet.'), style: const TextStyle(color: AppColors.textMuted)),
          )
        else ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: false, icon: const Icon(Icons.list_rounded, size: 18), label: Text(tr('List'))),
                  ButtonSegment(value: true, icon: const Icon(Icons.map_outlined, size: 18), label: Text(tr('Map'))),
                ],
                selected: {_showMap},
                onSelectionChanged: (v) => setState(() => _showMap = v.first),
              ),
              DropdownButton<String?>(
                value: _barangay,
                hint: Text(tr('All barangays')),
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(AppRadius.md),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(tr('All barangays'))),
                  for (final b in _barangays) DropdownMenuItem<String?>(value: b, child: Text('Brgy. $b')),
                ],
                onChanged: (v) => setState(() => _barangay = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (placed.isEmpty)
            _Note(tr('No centre is on the map yet, so distances cannot be measured. Use the list and the barangay filter.'))
          else
            _NearestPanel(
              locating: _locating,
              here: _here,
              hereFromGps: _hereFromGps,
              accuracy: _accuracy,
              problem: _problem,
              nearest: nearest,
              distanceLabel: _distanceLabel,
              onFind: _findNearest,
              onPick: _pickHere,
              onClear: () => setState(() {
                _here = null;
                _problem = null;
              }),
              onOpen: _open,
            ),
          const SizedBox(height: AppSpacing.md),
          if (_showMap)
            _CentresMap(
              centres: shown.where((c) => c.location != null).toList(),
              unplaced: widget.centers.length - placed.length,
              here: _here,
              onOpen: _open,
              onShowList: () => setState(() => _showMap = false),
            )
          else if (shown.isEmpty)
            _Note(tr('No centre in this barangay.'))
          else
            for (final c in shown)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                child: _CentreCard(
                  centre: c,
                  mine: _isMine(c),
                  nearest: nearest?.centre == c,
                  distanceLabel: _distanceLabel(c),
                  onTap: () => _open(c),
                ),
              ),
        ],
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Text(text, style: AppTypography.helper),
  );
}

/// "Find the nearest open centre": the phone's GPS, or a point chosen on
/// the map when the phone cannot or may not say. The answer, and what a
/// straight line does and does not mean.
class _NearestPanel extends StatelessWidget {
  const _NearestPanel({
    required this.locating,
    required this.here,
    required this.hereFromGps,
    required this.accuracy,
    required this.problem,
    required this.nearest,
    required this.distanceLabel,
    required this.onFind,
    required this.onPick,
    required this.onClear,
    required this.onOpen,
  });

  final bool locating;
  final GeoPoint? here;
  final bool hereFromGps;
  final double? accuracy;
  final LocationProblem? problem;
  final ({EvacuationCenter centre, double km})? nearest;
  final String Function(EvacuationCenter) distanceLabel;
  final VoidCallback onFind;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final void Function(EvacuationCenter) onOpen;

  @override
  Widget build(BuildContext context) {
    final best = nearest;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppButton(
            // The website's shorter phrase: the long one is cut off in Filipino.
            label: locating ? tr('Finding you…') : tr('Nearest open centre'),
            icon: Icons.my_location_rounded,
            fullWidth: true,
            loading: locating,
            onPressed: locating ? null : onFind,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.map_outlined, size: 17),
                  label: Text(tr('Choose my place on the map')),
                ),
              ),
              if (here != null) TextButton(onPressed: onClear, child: Text(tr('Clear'))),
            ],
          ),
          if (here == null && problem == null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              tr('Your device asks before sharing your location; it is used only to measure distances.'),
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
            ),
          ],
          if (problem != null && here == null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              locationProblemText(problem!, incident: false),
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.amber700, fontWeight: FontWeight.w600),
            ),
          ],
          if (here != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hereFromGps
                  ? locationFoundText(incident: false, accuracyM: accuracy)
                  : tr('Measured from the point you chose on the map.'),
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (best != null)
              Material(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () => onOpen(best.centre),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Nearest open centre').toUpperCase(),
                          style: const TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w700, color: AppColors.emerald700),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(best.centre.name, style: AppTypography.cardTitle),
                        Text(
                          '${distanceLabel(best.centre)} · Brgy. ${best.centre.barangay}',
                          style: AppTypography.helper.copyWith(color: AppColors.emerald700),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Text(tr('No open centre is on the map right now.'), style: AppTypography.helper),
            const SizedBox(height: AppSpacing.sm),
            Text(
              tr('Distances are straight lines, not by road. The nearest is not always the safest or quickest to reach — follow the MDRRMO and your barangay officials.'),
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The centres on a map: teal while open, slate when not; the resident's
/// point in blue. A centre without a pin is not drawn and is counted below.
class _CentresMap extends StatelessWidget {
  const _CentresMap({required this.centres, required this.unplaced, required this.here, required this.onOpen, required this.onShowList});

  final List<EvacuationCenter> centres;
  final int unplaced;
  final GeoPoint? here;
  final void Function(EvacuationCenter) onOpen;
  final VoidCallback onShowList;

  @override
  Widget build(BuildContext context) {
    if (centres.isEmpty) {
      return Row(
        children: [
          Expanded(child: _Note(tr('No centre is on the map yet. They are all in the list.'))),
          TextButton(onPressed: onShowList, child: Text(tr('Show the list'))),
        ],
      );
    }
    final points = [for (final c in centres) c.location!, ?here];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: 340,
            child: SakunaMap(
              key: ValueKey(Object.hashAll(points)),
              center: points.first,
              fit: points,
              semanticLabel: tr('Map of evacuation centres'),
              pins: [
                for (final c in centres)
                  MapPin(
                    point: c.location!,
                    size: 30,
                    label: '${c.name}, ${c.isOpen ? tr('Open now') : tr('Not open')}',
                    onTap: () => onOpen(c),
                    child: CentreMarker(open: c.isOpen),
                  ),
                if (here != null) MapPin(point: here!, size: 18, label: tr('You'), child: const HereMarker()),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          tr('Select a centre for its details. Green: open now. Grey: not open.'),
          style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
        ),
        if (unplaced > 0)
          Text(
            '$unplaced ${tr('listed centre(s) are not on the map yet; they are in the list.')}',
            style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}

class _CentreCard extends StatelessWidget {
  const _CentreCard({required this.centre, required this.mine, required this.nearest, required this.distanceLabel, required this.onTap});

  final EvacuationCenter centre;
  final bool mine;
  final bool nearest;
  final String distanceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = centre;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Icon(Icons.home_work_outlined, size: 17, color: AppColors.brand600),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _OpenChip(isOpen: c.isOpen),
                    if (nearest) _Tag(tr('Nearest open'), AppColors.emerald50, AppColors.emerald700),
                    if (mine) _Tag(tr('In your barangay'), AppColors.brand50, AppColors.brand700),
                    if (c.occupancyWarning case final w?) _Tag(w, AppColors.amber50, AppColors.amber700),
                  ],
                ),
                if (distanceLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(distanceLabel, style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  [
                    if (c.address != null) c.address!,
                    'Brgy. ${c.barangay}',
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
