import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/catalog_item.dart';
import '../../models/request_filters.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../widgets/active_filter_chip.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/nav_style.dart';
import '../../widgets/new_request_fab.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/status_chip.dart';
import '../home/root_shell.dart';
import 'request_detail_screen.dart';
import 'service_catalog_screen.dart';

/// Shared list+tracker screen used by both Dokyu (Document Requests) and
/// Tulong (Assistance Requests) — same shape as the Web Admin's
/// document-requests.blade.php / assistance-requests.blade.php (All /
/// Active / Done tabs, reference number, type, status), plus search,
/// filtering (Barangay/LGU, Type, Status, Date, Sort — behind a "Filter"
/// button so the main screen stays clean, per the filtering spec), active
/// filter chips, and sharing the currently filtered results via the
/// device's native share sheet. One implementation parameterized by
/// [category]/[catalog] rather than two near-identical screens, per the
/// "reuse before duplicating" rule this project follows throughout its
/// own component library.
class RequestListScreen extends StatefulWidget {
  final ServiceCategory category;
  final String title;
  final String subtitle;
  final List<CatalogItem> catalog;
  final Color accent;
  final IconData icon;

  const RequestListScreen({
    super.key,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.catalog,
    required this.accent,
    required this.icon,
  });

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  int _tab = 0; // 0 = active, 1 = done
  RequestFilters _filters = const RequestFilters();

  Future<void> _openFilters(List<ServiceRequest> categoryRequests) async {
    final typeOptions = categoryRequests.map((r) => r.typeName).toSet().toList()..sort();
    final statusOptions = categoryRequests.map((r) => r.status).toSet().toList()..sort();
    final result = await showModalBottomSheet<RequestFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        initial: _filters,
        typeOptions: typeOptions,
        statusOptions: statusOptions,
        accent: widget.accent,
      ),
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  Future<void> _shareFilteredResults(List<ServiceRequest> visible) async {
    if (visible.isEmpty) return;
    final lines = <String>[
      '${widget.title} — ${_filters.isActive ? "Filtered Results" : "My Requests"} (${visible.length})',
      '',
      for (final r in visible.take(20)) '• ${r.typeName} — ${r.status} (${r.referenceNumber})',
      if (visible.length > 20) '…and ${visible.length - 20} more',
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n'), subject: '${widget.title} — Esperanza'));
  }

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestsService>();
    final categoryRequests = requests.byCategory(widget.category);
    final activeAll = categoryRequests.where((r) => !AppStatusX.fromLabel(r.status).isDone).toList();
    final doneAll = categoryRequests.where((r) => AppStatusX.fromLabel(r.status).isDone).toList();
    final tabSource = _tab == 0 ? activeAll : doneAll;
    final visible = _filters.apply(tabSource);

    return Scaffold(
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [AlertsAction()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(widget.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ),
      ),
      // This Scaffold is nested inside RootShell's own (which owns the
      // floating navbar via `bottomNavigationBar` + `extendBody: true`) —
      // it has no bottomNavigationBar of its own, so a plain
      // `floatingActionButton` would use Scaffold's default endFloat
      // margin measured from the *true* screen edge, landing it behind
      // the navbar. Padding it by the inherited navbar-height MediaQuery
      // inset (see NavStyle.floatingElementGap's doc comment) plus a
      // visual gap keeps it clearly above the bar, staying correct across
      // screen sizes/safe-area insets since neither value is hardcoded.
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + NavStyle.floatingElementGap),
        child: NewRequestFab(
          accent: widget.accent,
          // Dokyu and Tulong's RequestListScreen instances are both mounted
          // at once (RootShell's IndexedStack), so the FAB's default hero tag
          // — shared by every FloatingActionButton unless overridden — would
          // collide the moment both are reachable in the same route subtree.
          heroTag: widget.category,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ServiceCatalogScreen(
                category: widget.category,
                title: widget.title,
                catalog: widget.catalog,
                accent: widget.accent,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedTabs(
              labels: ['Active (${activeAll.length})', 'Done (${doneAll.length})'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              accent: widget.accent,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openFilters(categoryRequests),
                    icon: Icon(Icons.tune_rounded, size: 16, color: _filters.isActive ? widget.accent : AppColors.slate600),
                    label: Text(
                      _filters.isActive ? 'Filter (${_filters.activeCount})' : 'Filter',
                      style: TextStyle(color: _filters.isActive ? widget.accent : AppColors.slate700, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _filters.isActive ? widget.accent : AppColors.slate200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: visible.isEmpty ? null : () => _shareFilteredResults(visible),
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Share results',
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: AppColors.slate200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          if (_filters.isActive) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_filters.search.trim().isNotEmpty)
                            ActiveFilterChip(
                              label: '"${_filters.search.trim()}"',
                              accent: widget.accent,
                              onRemove: () => setState(() => _filters = _filters.copyWith(search: '')),
                            ),
                          if (_filters.scope != null)
                            ActiveFilterChip(
                              label: _filters.scope!.label,
                              accent: widget.accent,
                              onRemove: () => setState(() => _filters = _filters.copyWith(clearScope: true)),
                            ),
                          if (_filters.typeName != null)
                            ActiveFilterChip(
                              label: _filters.typeName!,
                              accent: widget.accent,
                              onRemove: () => setState(() => _filters = _filters.copyWith(clearTypeName: true)),
                            ),
                          if (_filters.status != null)
                            ActiveFilterChip(
                              label: _filters.status!,
                              accent: widget.accent,
                              onRemove: () => setState(() => _filters = _filters.copyWith(clearStatus: true)),
                            ),
                          if (_filters.dateRange != null)
                            ActiveFilterChip(
                              label: 'Date range',
                              accent: widget.accent,
                              onRemove: () => setState(() => _filters = _filters.copyWith(clearDateRange: true)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _filters = const RequestFilters()),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${visible.length} result${visible.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? _EmptyStateArea(
                    icon: widget.icon,
                    title: _filters.isActive ? 'No requests match your current filters.' : (_tab == 0 ? 'No active requests' : 'No completed requests yet'),
                    description: _filters.isActive ? null : (_tab == 0 ? 'Tap "New Request" to get started.' : null),
                    action: _filters.isActive
                        ? OutlinedButton(
                            onPressed: () => setState(() => _filters = const RequestFilters()),
                            child: const Text('Clear Filters'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => _RequestTile(request: visible[i], accent: widget.accent),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The "no requests yet" / "no results match your filters" state, biased
/// upward so it clears the floating New Request button and the navbar
/// beneath it — shared by Dokyu and Tulong through RequestListScreen, so
/// fixing the positioning here keeps both consistent automatically.
///
/// Reserves `MediaQuery.paddingOf(context).bottom` (RootShell's
/// `extendBody: true` publishes this as exactly the navbar's rendered
/// height) plus the FAB's own footprint and a couple of visual gaps below
/// the centered content — the same clearance math the FAB's own position
/// already uses (see RequestListScreen's `floatingActionButton`), so both
/// stay in sync if that ever changes.
///
/// Uses `ConstrainedBox(minHeight: ...)` + `SingleChildScrollView` (not a
/// plain `Padding` + `Center`) specifically so short screens degrade by
/// becoming scrollable instead of the reserved bottom padding silently
/// eating all the available room and pushing the content past the FAB
/// anyway — every part of the empty state stays reachable regardless of
/// screen height.
class _EmptyStateArea extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const _EmptyStateArea({required this.icon, required this.title, this.description, this.action});

  @override
  Widget build(BuildContext context) {
    final bottomReserve = MediaQuery.paddingOf(context).bottom +
        NavStyle.floatingElementGap +
        NavStyle.floatingActionButtonHeight +
        NavStyle.floatingElementGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyState(icon: icon, title: title, description: description, action: action),
                SizedBox(height: bottomReserve),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  final ServiceRequest request;
  final Color accent;
  const _RequestTile({required this.request, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(request.typeName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
                StatusChip(status: AppStatusX.fromLabel(request.status), small: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(request.referenceNumber, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: Text(request.office, style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
                _ScopeTag(office: request.office),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Submitted ${_fmt(request.submittedAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                Row(
                  children: [
                    Text('Track', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent)),
                    Icon(Icons.chevron_right_rounded, size: 15, color: accent),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.month}/${d.day}/${d.year}';
}

/// Small "Barangay" / "LGU" badge next to the office line — makes the
/// Barangay-vs-Municipality distinction visually understandable on every
/// tile, not just inside the filter sheet.
class _ScopeTag extends StatelessWidget {
  final String office;
  const _ScopeTag({required this.office});

  @override
  Widget build(BuildContext context) {
    final scope = scopeOfOffice(office);
    final isBarangay = scope == RequestScope.barangay;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isBarangay ? AppColors.emerald50 : AppColors.indigo50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isBarangay ? 'Barangay' : 'LGU',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isBarangay ? AppColors.emerald700 : AppColors.indigo700),
      ),
    );
  }
}
