import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/new_request_fab.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/status_chip.dart';
import '../home/root_shell.dart';
import 'request_detail_screen.dart';
import 'service_catalog_screen.dart';

/// Shared list+tracker screen used by both Dokyu (Document Requests) and
/// Tulong (Assistance Requests) — same shape as the Web Admin's
/// document-requests.blade.php / assistance-requests.blade.php (All /
/// Active / Done tabs, reference number, type, status). One implementation
/// parameterized by [category]/[catalog] rather than two near-identical
/// screens, per the "reuse before duplicating" rule this project follows
/// throughout its own component library.
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

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestsService>();
    final categoryRequests = requests.byCategory(widget.category);
    final active = categoryRequests.where((r) => !AppStatusX.fromLabel(r.status).isDone).toList();
    final done = categoryRequests.where((r) => AppStatusX.fromLabel(r.status).isDone).toList();
    final visible = _tab == 0 ? active : done;

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
      floatingActionButton: NewRequestFab(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedTabs(
              labels: ['Active (${active.length})', 'Done (${done.length})'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
              accent: widget.accent,
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      child: EmptyState(
                        icon: widget.icon,
                        title: _tab == 0 ? 'No active requests' : 'No completed requests yet',
                        description: _tab == 0 ? 'Tap "New Request" to get started.' : null,
                      ),
                    ),
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
            Text(request.office, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
