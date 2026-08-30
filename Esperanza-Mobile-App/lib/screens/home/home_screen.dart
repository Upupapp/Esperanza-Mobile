import 'package:flutter/material.dart';
import '../../models/access_level.dart';
import '../../widgets/access_guard.dart';
import 'package:provider/provider.dart';
import '../../models/citizen_account.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/requests_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../utils/demo_resident_photo.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_drawer.dart';
import '../../widgets/event_card.dart';
import '../../widgets/home_welcome_banner.dart';
import '../../widgets/parallax_header.dart';
import '../../widgets/resident_profile_status_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/service_launcher_menu.dart';
import '../../widgets/status_chip.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../dokyu/dokyu_screen.dart';
import '../profile/resident_profile/resident_profile_overview_screen.dart';
import '../tulong/tulong_screen.dart';
import 'root_shell.dart';

/// Mirrors citizen/dashboard.blade.php: navy hero with greeting + barangay
/// identity, quick-action stat tiles, active-requests preview, Balita
/// preview, upcoming events preview. Renders a reduced Guest variant
/// (Section 6) when no account is signed in — Balita/Events previews stay
/// visible (public content), account-specific sections (stat tiles,
/// Resident Profile status, Active Requests) don't.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  bool _bannerOffered = false;

  @override
  void initState() {
    super.initState();
    // RootShell mounts HomeScreen once via IndexedStack and keeps it alive
    // across tab switches, so `initState` running exactly once per
    // session-entry is what makes "show once, then stay closed for the
    // rest of this session" work without any extra persisted flag — no
    // over-engineered banner-impression backend needed for this demo.
    // addPostFrameCallback defers to after the first real frame, which is
    // the standard safe point to open a dialog from initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_bannerOffered && mounted) {
        _bannerOffered = true;
        HomeWelcomeBanner.show(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account;
    final requests = context.watch<RequestsService>();
    final activeRequests = requests.all.where((r) => !AppStatusX.fromLabel(r.status).isDone).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    final residentProfile = account != null ? context.watch<ResidentProfileService>().profileFor(account) : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const EsperanzaDrawer(),
      // bottom: false — RootShell's extendBody:true publishes a bottom
      // MediaQuery padding matching the floating navbar's *full* reported
      // height (barHeight + protrusion, ~150px — headroom for the circle,
      // not just the visible ~72px pill). A bottom-insetting SafeArea
      // would reserve all of that as extra space *inside* this Scaffold's
      // own opaque backgroundColor, which is exactly what read as a large
      // light rectangle sitting behind/above the navbar — Home is the only
      // tab that wraps its body in SafeArea at all, which is why this
      // didn't show up on Dokyu/Tulong/Balita/Emergency. Top/left/right
      // protection is still needed here since, unlike those tabs, Home has
      // no AppBar of its own to already clear the status bar/notch.
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => Future.delayed(const Duration(milliseconds: 500)),
          child: ListView(
            controller: _scrollController,
            // 100 (rather than a plain 32) leaves real, transparent
            // clearance for the floating navbar — matching the same value
            // RequestListScreen's own list already uses for this — so the
            // last card can scroll clear of it without needing SafeArea's
            // much larger, opaquely-backed inset to do that job.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _Hero(account: account, scrollController: _scrollController),
              const SizedBox(height: AppSpacing.lg),
              if (account != null) ...[
                ResidentProfileStatusCard(
                  profile: residentProfile!,
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const ResidentProfileOverviewScreen())),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Two content-sized rows instead of GridView.count's fixed
                // childAspectRatio: a fixed aspect ratio forces an exact
                // cell height regardless of how much vertical space the
                // icon + value + label actually need, which is exactly
                // what caused "BOTTOM OVERFLOWED BY 19 PIXELS" — at larger
                // text-scale settings or on narrower phones it will always
                // overflow *some* aspect ratio no matter what number is
                // chosen. Sizing each row to its own content (via
                // IntrinsicHeight + stretch) makes overflow structurally
                // impossible while still keeping both tiles in a row
                // equal height.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Dokyu Requests',
                          value: '${requests.byCategory(ServiceCategory.dokyu).length}',
                          icon: Icons.description_outlined,
                          color: StatTileColor.brand,
                          onTap: () => RootShell.openService(context, ServiceLauncherTarget.dokyu),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          label: 'Tulong Requests',
                          value: '${requests.byCategory(ServiceCategory.tulong).length}',
                          icon: Icons.volunteer_activism_outlined,
                          color: StatTileColor.purple,
                          onTap: () => RootShell.openService(context, ServiceLauncherTarget.tulong),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Active Requests',
                          value: '${activeRequests.length}',
                          icon: Icons.hourglass_top_outlined,
                          color: StatTileColor.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatTile(
                          // "Account Details", not "Profile Complete": this is
                          // account.profileCompleteness — the four contact
                          // fields on Edit Profile (mobile, occupation, purok,
                          // barangay). The Resident Profile card directly above
                          // shows overallCompletionPercent, which weighs the
                          // Personal/Family/Household sections. Both are
                          // correct and they legitimately differ, but until
                          // 2026-08-30 they sat on one screen as "Profile
                          // Complete" and "Resident Profile" with no way for a
                          // citizen to tell they measure different forms.
                          label: 'Account Details',
                          value: '${account.profileCompleteness}%',
                          icon: Icons.badge_outlined,
                          color: StatTileColor.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(
                  title: 'Active Requests',
                  actionLabel: activeRequests.isNotEmpty ? 'View all' : null,
                  onAction: () => RootShell.openService(context, ServiceLauncherTarget.dokyu),
                ),
                if (activeRequests.isEmpty)
                  AppCard(
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No active requests',
                      description: 'Start a Dokyu or Tulong request and track it here.',
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: AppSpacing.xl),
                    ),
                  )
                else
                  ...activeRequests.take(3).map((r) => _RequestPreviewTile(request: r)),
                const SizedBox(height: AppSpacing.xxl),
              ],
              // No Balita/News section here — Balita already has its own
              // dedicated bottom tab; duplicating the feed on Home only
              // adds noise. Events stays, since Home has always carried a
              // short upcoming-events teaser distinct from the full
              // Events list.
              SectionHeader(
                title: 'Upcoming Events',
                actionLabel: 'View all',
                onAction: () => RootShell.jumpTo(context, 2), // Events — see RootShell's 4-tab index space
              ),
              for (final e in MockCatalog.events.take(2)) EventCard(event: e, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final CitizenAccount? account;
  final ScrollController scrollController;
  const _Hero({required this.account, required this.scrollController});

  static const _labelStyle = TextStyle(fontFamily: AppTypography.sans, fontSize: 12.5, fontWeight: FontWeight.w500);
  static const _buttonGap = 10.0;
  // Matches AppButtonSize.sm's own geometry (padding/icon/icon-gap) — used
  // only to measure whether the full label fits, never to render.
  static const _nonTextWidth = (14 * 2) + 16 + AppSpacing.sm;

  bool _fitsOneLine(String text, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _labelStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return painter.width <= maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    return ParallaxHeader(
      scrollController: scrollController,
      borderRadius: BorderRadius.circular(20),
      background: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy900, AppColors.brand700],
          ),
        ),
      ),
      foreground: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: account != null ? _signedInContent(context, account!) : _guestContent(context),
      ),
    );
  }

  Widget _topBar(BuildContext context, {required Widget middle}) {
    return Row(
      children: [
        Builder(
          builder: (context) => InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Scaffold.of(context).openDrawer(),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Icon(Icons.menu_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: middle),
        const SizedBox(width: AppSpacing.sm),
        const AlertsAction(color: Colors.white),
      ],
    );
  }

  Widget _signedInContent(BuildContext context, CitizenAccount account) {
    final personal = context.watch<ResidentProfileService>().profileFor(account).personal;
    final photo = profileImageFor(account, personal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(
          context,
          middle: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        account.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Magandang araw, ${account.firstName} 👋',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Brgy. ${account.barangay}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            const tulongLabel = 'New Tulong Request';
            const dokyuLabel = 'New Dokyu Request';

            final tulongButton = AppButton(
              label: tulongLabel,
              icon: Icons.volunteer_activism_outlined,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.sm,
              fullWidth: true,
              // Guarded with the SAME level and featureName RootShell uses for
              // the Tulong tab. Until 2026-08-30 this pushed TulongScreen raw:
              // the tab route was gated at AccessLevel.verified while this
              // shortcut to the identical screen was not, so an Unverified
              // citizen tapping the Home CTA walked straight into the request
              // flow the tab refuses them. One rule, two call sites, enforced
              // at one of them.
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccessGuard(
                    required: AccessLevel.verified,
                    featureName: 'Tulong (Assistance Requests)',
                    child: TulongScreen(),
                  ),
                ),
              ),
            );
            final dokyuButton = AppButton(
              label: dokyuLabel,
              icon: Icons.note_add_outlined,
              variant: AppButtonVariant.gold,
              size: AppButtonSize.sm,
              fullWidth: true,
              // Same guard as the Dokyu tab — see the Tulong button above.
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccessGuard(
                    required: AccessLevel.verified,
                    featureName: 'Dokyu (Document Requests)',
                    child: DokyuScreen(),
                  ),
                ),
              ),
            );

            // Side by side only if BOTH full labels genuinely fit on one
            // line at this width — real font-metric measurement, not a
            // guessed breakpoint, so it can't silently start truncating
            // again on a device slightly narrower than whatever number
            // was hard-coded. Otherwise stack full-width so the primary
            // action labels are never cut off.
            final perButtonWidth = (constraints.maxWidth - _buttonGap) / 2;
            final availableTextWidth = perButtonWidth - _nonTextWidth;
            final sideBySideFits =
                _fitsOneLine(tulongLabel, availableTextWidth) && _fitsOneLine(dokyuLabel, availableTextWidth);

            if (sideBySideFits) {
              return Row(
                children: [
                  Expanded(child: tulongButton),
                  const SizedBox(width: _buttonGap),
                  Expanded(child: dokyuButton),
                ],
              );
            }
            return Column(
              children: [
                tulongButton,
                const SizedBox(height: _buttonGap),
                dokyuButton,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _guestContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(
          context,
          middle: const Text(
            'Esperanza',
            style: TextStyle(fontFamily: 'Lora', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Welcome, Guest 👋',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "You're browsing public content. Sign in or create an account for full access.",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Create Account',
                variant: AppButtonVariant.gold,
                size: AppButtonSize.sm,
                fullWidth: true,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              ),
            ),
            const SizedBox(width: _buttonGap),
            Expanded(
              child: AppButton(
                label: 'Sign In',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                fullWidth: true,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequestPreviewTile extends StatelessWidget {
  final ServiceRequest request;
  const _RequestPreviewTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () {
          final target = request.category == ServiceCategory.dokyu
              ? ServiceLauncherTarget.dokyu
              : ServiceLauncherTarget.tulong;
          RootShell.openService(context, target);
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.typeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(request.referenceNumber, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            StatusChip(status: AppStatusX.fromLabel(request.status), small: true),
          ],
        ),
      ),
    );
  }
}
