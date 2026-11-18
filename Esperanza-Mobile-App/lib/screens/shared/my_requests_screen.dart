import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/live_refresh.dart';
import '../../widgets/segmented_tabs.dart';
import '../../widgets/status_chip.dart';
import 'request_detail_screen.dart';
import '../../theme/app_typography.dart';
import '../../utils/date_text.dart';
import '../../widgets/esperanza_art.dart';

import '../../l10n/tr.dart';
/// The signed-in resident's full Dokyu + Tulong request history in one
/// place — derived straight from [RequestsService], never a separate
/// hardcoded list. Tapping a card opens the same [RequestDetailScreen]
/// every other "Track"/"View" entry point already uses — there is no
/// second detail/tracking implementation.
///
/// No client-side account filter anymore -- GET /citizen/requests is
/// already scoped to the signed-in citizen by the bearer token
/// (production-readiness programme, 2026-09-25), and RequestsService never
/// populates applicantId from the real API at all. Filtering by it here (as
/// this screen used to) was load-bearing under the old local simulation,
/// which held every demo account's requests in one shared pool; against the
/// real API it always compared against an empty string and would have
/// always shown "No requests yet", even for a citizen with real ones.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  int _tab = 0; // 0 = All, 1 = Dokyu, 2 = Tulong

  // It showed whatever was loaded when the app started: a request filed on
  // the website meanwhile was missing, and pulling down did nothing
  // (Esperanza bugs QA item 10, seen on the emulator). Opening the screen
  // re-reads the list, and pulling down reads it again.
  @override
  void initState() {
    super.initState();
    _reload(quiet: true);
  }

  /// Why the list could not be read, while nothing was ever read: the page
  /// said "No requests yet" to a resident who has some (QA 2026-11-18).
  String? _loadError;

  Future<void> _reload({bool quiet = false}) async {
    try {
      await context.read<RequestsService>().loadRequests();
      if (mounted && _loadError != null) setState(() => _loadError = null);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message());
      if (!quiet) AppDialogs.toast(context, e.message(), success: false);
    }
  }

  /// Live updates (2026-11-15): read again quietly when requests change on
  /// the server while this page is on top.
  @override
  Widget build(BuildContext context) => LiveRefresh(
    topics: const {'requests'},
    onChange: (_) async {
      await context.read<RequestsService>().refreshRequests();
      if (mounted && _loadError != null) setState(() => _loadError = null);
    },
    child: _buildPage(context),
  );

  Widget _buildPage(BuildContext context) {
    final requests = context.watch<RequestsService>();

    // "All" here means "all Dokyu + Tulong" — Sakuna incident reports are a
    // separate concern (see ServiceCategory.sakunaIncident) not covered by
    // this Dokyu/Tulong service-history screen.
    var mine = requests.all.where((r) => r.category != ServiceCategory.sakunaIncident).toList();
    // With nothing to show yet, "No requests yet" only once the list has
    // been read: a loader while it is being read, and why when it could not.
    final loading = mine.isEmpty && !requests.loaded;
    final failed = mine.isEmpty && _loadError != null;
    if (_tab == 1) mine = mine.where((r) => r.category == ServiceCategory.dokyu).toList();
    if (_tab == 2) mine = mine.where((r) => r.category == ServiceCategory.tulong).toList();
    mine.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return Scaffold(
      appBar: AppBar(title: Text(tr('My Requests'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
            child: SegmentedTabs(
              labels: [tr('All'), 'Dokyu', 'Tulong'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: mine.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.xxxl),
                            child: Center(child: EsperanzaLoader()),
                          )
                        else if (failed)
                          EmptyState(
                            glyph: ClayGlyph.error,
                            title: 'Your requests could not be loaded',
                            description: _loadError,
                            action: AppButton(
                              label: tr('Try Again'),
                              icon: Icons.refresh_rounded,
                              variant: AppButtonVariant.secondary,
                              // The reason shows here, not in a toast too.
                              onPressed: () => _reload(quiet: true),
                            ),
                          )
                        else
                          EmptyState(
                            icon: Icons.folder_open_outlined,
                            title: _tab == 0 ? 'No requests yet' : 'No ${_tab == 1 ? 'Dokyu' : 'Tulong'} requests yet',
                            description: 'Your submitted Dokyu and Tulong requests will appear here.',
                          ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                      itemCount: mine.length,
                      itemBuilder: (context, i) => _MyRequestCard(request: mine[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyRequestCard extends StatelessWidget {
  final ServiceRequest request;
  const _MyRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final categoryColor = switch (request.category) {
      ServiceCategory.dokyu => AppColors.brand600,
      ServiceCategory.tulong => AppColors.purple700,
      ServiceCategory.sakunaIncident => AppColors.rose600,
      ServiceCategory.unknown => AppColors.slate600,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The service name has this row to itself beside a capped status,
            // as on the Dokyu and Tulong lists. With the category pill in it
            // too, a long status ("Under Verification") left a long service
            // name so little room on a phone that it broke mid-word
            // ("Certificatio" / "n"; live-updates video, 2026-11-15).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RequestClayIcon(request.category),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    request.typeName,
                    style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.4),
                  child: StatusChip.request(request.status, small: true, label: request.statusLabel),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Which kind of request it is, beside its reference number.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    request.category.label,
                    style: TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w700, color: categoryColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    request.referenceNumber,
                    style: const TextStyle(
                      fontSize: AppTextSize.label,
                      color: AppColors.textMuted,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            // The purpose filed, as the website's list shows it.
            if (request.purpose.isNotEmpty)
              Text(
                request.purpose,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Submitted ${shortDate(request.submittedAt)}',
              style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(tr('Track'), style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w600, color: categoryColor)),
                Icon(Icons.chevron_right_rounded, size: 15, color: categoryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
