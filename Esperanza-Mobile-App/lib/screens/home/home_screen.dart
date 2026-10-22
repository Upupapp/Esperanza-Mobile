import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../models/citizen_account.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../services/json_read.dart';
import '../../services/notifications_service.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/tulong_status.dart';
import '../../theme/app_typography.dart';
import '../../utils/demo_resident_photo.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_art.dart';
import '../../widgets/event_card.dart';
import '../../utils/banner_memory.dart';
import '../../widgets/occasion_greeting_popup.dart';
import '../../widgets/home_welcome_banner.dart';
import '../../widgets/live_banners.dart';
import '../../widgets/sakuna_alerts_ui.dart';
import '../../widgets/resident_profile_status_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/service_launcher_menu.dart';
import '../../widgets/status_chip.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../balita/balita_post_screen.dart';
import '../directory/directory_screen.dart';
import '../shared/documents_uploaded_screen.dart';
import '../shared/my_requests_screen.dart';
import '../profile/resident_profile/resident_profile_overview_screen.dart';
import 'root_shell.dart';
import '../../models/access_level.dart';
import '../../services/mock_catalog.dart';
import '../../widgets/access_guard.dart';
import '../shared/service_search_screen.dart';

import '../../l10n/tr.dart';
/// Mirrors citizen/dashboard.blade.php in what it shows: navy hero with
/// greeting + barangay identity, quick actions, stat tiles, active-requests
/// preview, the latest LGU announcements, upcoming events preview. Laid out
/// to the 2026-10 design refresh. Renders a reduced Guest variant
/// (Section 6) when no account is signed in — Balita/Events previews stay
/// visible (public content), account-specific sections (stat tiles,
/// Resident Profile status, Active Requests) don't.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  // Fetched once per session-entry (RootShell keeps this screen alive via
  // IndexedStack) -- a plain Future, not AsyncStateView, since this is a
  // small teaser tucked inside a much larger dashboard: a fetch failure
  // here should just show nothing,
  // never a full-screen error/retry state that blocks everything else on
  // Home (see sakuna_screen.dart's own doc comment on this exact class of
  // mistake).
  late final Future<List<EventItem>> _eventsFuture = _loadEvents();

  /// The banners staff publish to the dashboard; nothing shows when none
  /// are live or the list cannot be read.
  late final Future<List<LiveBanner>> _bannersFuture = LiveBanner.load();

  Future<List<EventItem>> _loadEvents() async {
    try {
      // From today, as the website asks (parity check, 2026-10-22): the
      // server lists events oldest first, so without it 20 past events
      // filled the page and nothing upcoming was left. More than the two it
      // shows, since the server's order is not calendar order.
      final now = DateTime.now();
      final from =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final res = await api.get('/events', query: {'from': from, 'per_page': 20});
      final events = EventItem.inCalendarOrder(JsonRead.rows(res.list, EventItem.fromApi).where((e) => e.title.isNotEmpty));
      // Upcoming only: under an "Upcoming Events" heading, a past event
      // (which calendar order puts after the upcoming ones) must not fill a
      // slot when fewer than two are coming up.
      final today = DateTime.now();
      return events.where((e) => !e.isPast(today)).take(2).toList();
    } on ApiException {
      // Caught, not rethrown: this teaser has no retry affordance of its
      // own (see the class-level doc comment), so a failure here should
      // read as "nothing to preview right now," not an error the rest of
      // Home has to account for.
      return const [];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The Resident Profile card shows what the barangay decided, not what
    // this phone last knew (live test 2026-10-07, BUG-9).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncResidentProfile());
    // The opening pop-ups, after the first real frame (the standard safe
    // point to open a dialog from initState): this is the first frame after
    // signing in, or after the opening animation for someone already signed
    // in. Offered once per launch or sign-in - the session keeps that, not
    // this State, so Home being built again (a sign-in from guest mode, the
    // shell rebuilt) never asks the server twice (2026-10-21).
    //
    // First the server's occasion pop-up, when one is due - a fiesta, a
    // holiday, the resident's birthday (the server's since 2026-10-21; the
    // phone no longer works the birthday out for a pop-up). Then the welcome
    // poster, so the two never stack. A resident who followed the pop-up to
    // its post is on that page now: the poster waits for next time instead
    // of opening over it.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !context.read<CitizenSessionService>().takeLaunchPopups()) return;
      final account = context.read<CitizenSessionService>().account;
      final wentOn = await OccasionGreetingPopup.showIfAny(context, account);
      if (!mounted || wentOn) return;
      BannerMemory.showOnce(HomeWelcomeBanner.assetPath, () {
        if (mounted) HomeWelcomeBanner.show(context);
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncResidentProfile();
  }

  /// GET /citizen/resident-profile. Offline, the card keeps what it shows.
  Future<void> _syncResidentProfile() async {
    if (!mounted) return;
    final account = context.read<CitizenSessionService>().account;
    if (account == null) return;
    try {
      await context.read<ResidentProfileService>().sync(account);
    } on ApiException {
      // The status on file stands until the next try.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account;
    final requests = context.watch<RequestsService>();
    final activeRequests = requests.all.where((r) => !RequestStatusView(r.status).isDone).toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    final residentProfile = account != null ? context.watch<ResidentProfileService>().profileFor(account) : null;
    final updates = _latestUpdates(context);

    // 2026-10 refresh: a full-bleed navy hero under the status bar (light
    // icons over it), a quick-actions card riding its lower edge, then the
    // dashboard on the light page. No SafeArea: the hero pads itself below
    // the status bar, and RootShell's floating navbar is cleared by the
    // list's own bottom padding (see the note on it below).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // The soft colour wash the frosted panels blur (2026-10 design).
            const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: SoftBackdropPainter()))),
            RefreshIndicator(
          // It only waited half a second: the counts and Active Requests
          // stayed as loaded at start-up (Esperanza bugs QA item 10, seen on
          // the emulator). Pulling down now re-reads requests and the bell.
          onRefresh: () async {
            try {
              await Future.wait([
                context.read<RequestsService>().loadRequests(),
                context.read<NotificationsService>().loadServer(),
              ]);
            } on ApiException catch (e) {
              if (context.mounted) AppDialogs.toast(context, e.message(), success: false);
            }
          },
          child: ListView(
            controller: _scrollController,
            // Bottom clearance for the floating navbar, transparent rather
            // than SafeArea's opaque inset (see RequestListScreen).
            padding: const EdgeInsets.only(bottom: AppSpacing.page),
            children: [
              _Hero(account: account, scrollController: _scrollController),
              // Rides up over the hero's lower edge, as in the design.
              Transform.translate(
                offset: const Offset(0, -_Hero.overlap),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: _QuickActions(signedIn: account != null),
                ),
              ),
              // Shifted up by the same amount, so the overlap leaves no gap.
              Transform.translate(
                offset: const Offset(0, -_Hero.overlap + AppSpacing.sectionGap),
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Alerts in force for the resident's barangay, like the
                    // website's dashboard; they were only on the Emergency tab.
                    ActiveAlertsCard(onOpen: () => RootShell.jumpTo(context, 3)),
                    // The banners staff publish; the municipal card when none
                    // are live, so the slot is never empty.
                    FutureBuilder<List<LiveBanner>>(
                      future: _bannersFuture,
                      builder: (context, snapshot) {
                        final banners = snapshot.data ?? const <LiveBanner>[];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                          child: banners.isEmpty ? const _PromoCard() : LiveBannersStrip(banners: banners),
                        );
                      },
                    ),
                    if (account != null) ...[
                      ResidentProfileStatusCard(
                        profile: residentProfile!,
                        onTap: () => Navigator.of(
                          context,
                        ).push(MaterialPageRoute(builder: (_) => const ResidentProfileOverviewScreen())),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      const SectionHeader(title: 'Overview'),
                      // Content-sized rows, not GridView.count's fixed aspect
                      // ratio, which overflowed at large text sizes ("BOTTOM
                      // OVERFLOWED BY 19 PIXELS"); IntrinsicHeight keeps both
                      // tiles in a row the same height.
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StatTile(
                                label: 'Dokyu Requests',
                                value: '${requests.byCategory(ServiceCategory.dokyu).length}',
                                icon: Icons.description_outlined,
                                color: StatTileColor.azure,
                                onTap: () => RootShell.openService(context, ServiceLauncherTarget.dokyu),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: StatTile(
                                label: 'Tulong Requests',
                                value: '${requests.byCategory(ServiceCategory.tulong).length}',
                                icon: Icons.volunteer_activism_outlined,
                                color: StatTileColor.indigo,
                                onTap: () => RootShell.openService(context, ServiceLauncherTarget.tulong),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: StatTile(
                                label: 'Active Requests',
                                value: '${activeRequests.length}',
                                icon: Icons.hourglass_top_outlined,
                                color: StatTileColor.amber,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: StatTile(
                                // "Account Details", not "Profile Complete": the
                                // four contact fields on Edit Profile, which
                                // legitimately differs from the Resident Profile
                                // card's own percentage above.
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
                        // The same 12 below it as below a request tile.
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                          child: AppCard(
                            child: EmptyState(
                              icon: Icons.inbox_outlined,
                              title: 'No active requests',
                              description: 'Start a Dokyu or Tulong request and track it here.',
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
                            ),
                          ),
                        )
                      else
                        ...activeRequests.take(3).map((r) => _RequestPreviewTile(request: r)),
                      // The last card's own 12, plus 12: a section's 24.
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // The two newest LGU announcements, as the design's "Latest
                    // Updates"; the whole feed stays on the Balita tab.
                    if (updates.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Latest Updates',
                        actionLabel: tr('View all'),
                        onAction: () => RootShell.jumpTo(context, 1),
                      ),
                      for (final post in updates) _UpdateTile(post: post),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    SectionHeader(
                      title: tr('Upcoming Events'),
                      actionLabel: tr('View all'),
                      onAction: () => RootShell.jumpTo(context, 2), // Events — see RootShell's 4-tab index space
                    ),
                    FutureBuilder<List<EventItem>>(
                      future: _eventsFuture,
                      builder: (context, snapshot) {
                        final events = snapshot.data ?? const <EventItem>[];
                        return Column(
                          children: [for (final e in events) EventCard(event: e, compact: true)],
                        );
                      },
                    ),
                  ],
                ),
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
}

/// The two newest LGU announcements from the Balita feed RootShell loads.
/// Empty where no feed is provided (a Home shown on its own).
List<Announcement> _latestUpdates(BuildContext context) {
  try {
    return context.watch<BalitaService>().posts.take(2).toList();
  } on ProviderNotFoundException {
    return const [];
  }
}

/// The navy hero (2026-10 design): a deep gradient with a wave-shaped lower
/// edge trimmed in gold, frosted buttons, the resident's photo in a gold ring
/// and the greeting. The shortcuts panel rides over the wave.
class _Hero extends StatelessWidget {
  final CitizenAccount? account;
  final ScrollController scrollController;
  const _Hero({required this.account, required this.scrollController});

  /// How far the shortcuts panel rides up over the hero.
  static const double overlap = 64;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _HeroWavePainter())),
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, top + AppSpacing.sm, AppSpacing.lg, overlap + AppSpacing.xxxl),
          child: account != null ? _signedInContent(context, account!) : _guestContent(context),
        ),
      ],
    );
  }

  Widget _frosted({required Widget child}) => ClipOval(
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surface.withValues(alpha: 0.24), AppColors.surface.withValues(alpha: 0.08)],
          ),
          border: Border.all(color: AppColors.surface.withValues(alpha: 0.30)),
        ),
        child: child,
      ),
    ),
  );

  Widget _menuButton() => Builder(
    builder: (context) => _frosted(
      child: IconButton(
        tooltip: 'Menu',
        onPressed: () => RootShell.openDrawer(context),
        icon: const Icon(Icons.menu_rounded, color: AppColors.surface, size: 22),
      ),
    ),
  );

  // The circle frames the button only; the unread count sits on its rim,
  // outside the clip (see AlertsAction.frame).
  Widget _bell() => AlertsAction(
    color: AppColors.surface,
    edgePadding: false,
    frame: (button) => _frosted(child: button),
  );

  Widget _signedInContent(BuildContext context, CitizenAccount account) {
    final personal = context.watch<ResidentProfileService>().profileFor(account).personal;
    final photo = profileImageFor(
      account,
      personal,
      approvedUrl: context.watch<CitizenSessionService>().photo?.approvedUrl,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [_menuButton(), const Spacer(), _bell()]),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.gold300, AppColors.gold500]),
                boxShadow: [BoxShadow(color: AppColors.gold400.withValues(alpha: 0.45), blurRadius: 16)],
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.navy700,
                backgroundImage: photo,
                onBackgroundImageError: photo != null ? (error, stackTrace) {} : null,
                child: photo == null
                    ? Text(
                        account.initials,
                        style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700, fontSize: AppTextSize.card),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Magandang araw, ${account.firstName} 👋',
                    // Wraps, never truncates: on a 390pt phone one line cut
                    // the greeting at "Magandang araw,…" and the name, the
                    // whole point of it, never showed.
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: AppTextSize.section,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'How can we help you today?',
                    style: TextStyle(color: AppColors.surface.withValues(alpha: 0.80), fontSize: AppTextSize.helper, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Pill(icon: Icons.place_rounded, label: 'Brgy. ${account.barangay}'),
        const SizedBox(height: AppSpacing.lg),
        const _SearchBar(),
      ],
    );
  }

  Widget _guestContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _menuButton(),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Esperanza',
                style: TextStyle(fontFamily: 'Lora', color: AppColors.surface, fontSize: AppTextSize.section, fontWeight: FontWeight.w600),
              ),
            ),
            _bell(),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Welcome, Guest 👋',
          style: TextStyle(color: AppColors.surface, fontSize: AppTextSize.section, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "You're browsing public content. Sign in or create an account for full access.",
          style: TextStyle(color: AppColors.surface.withValues(alpha: 0.80), fontSize: AppTextSize.helper, height: 1.35),
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: tr('Sign In'),
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

/// The hero's ground: navy gradient with a wave for its lower edge, a
/// lighter swell inside it, a gold trim along the wave and a warm glow.
class _HeroWavePainter extends CustomPainter {
  const _HeroWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    Path wave(double lift) => Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - 70 - lift)
      ..cubicTo(w * 0.72, h - 10 - lift, w * 0.35, h - 110 - lift, 0, h - 30 - lift)
      ..close();

    final body = wave(0);
    canvas.drawPath(
      body.shift(const Offset(0, 8)),
      Paint()
        ..color = AppColors.navy900.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy950, AppColors.navy800, AppColors.brand800],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipPath(body);
    // A lighter swell, the second wave in the design.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.55)
        ..cubicTo(w * 0.35, h * 0.35, w * 0.65, h * 0.85, w, h * 0.50)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = AppColors.brand600.withValues(alpha: 0.22),
    );
    // A cool highlight in the corner (gold over navy reads olive).
    final g = Rect.fromCircle(center: Offset(w * 0.95, h * 0.02), radius: w * 0.55);
    canvas.drawCircle(
      g.center,
      g.width / 2,
      Paint()..shader = RadialGradient(colors: [AppColors.brand400.withValues(alpha: 0.38), AppColors.brand400.withValues(alpha: 0)]).createShader(g),
    );
    canvas.restore();

    // Gold trim riding the wave.
    final trim = Path()
      ..moveTo(0, h - 30)
      ..cubicTo(w * 0.35, h - 110, w * 0.72, h - 10, w, h - 70);
    canvas.drawPath(
      trim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = AppColors.gold400.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      trim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(colors: [AppColors.gold300, AppColors.gold500]).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_HeroWavePainter old) => false;
}

/// The frosted search bar in the hero (2026-10 design). Opens Service
/// Search behind the same access guard as the Dokyu and Tulong tabs; the
/// duplicate demo account is sent to RootShell's own prompt instead.
class _SearchBar extends StatelessWidget {
  const _SearchBar();

  void _open(BuildContext context) {
    final session = context.read<CitizenSessionService>();
    if (session.account?.id == MockCatalog.duplicateVerifiedDemoAccount.id) {
      RootShell.openService(context, ServiceLauncherTarget.dokyu);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AccessGuard(
          required: AccessLevel.verified,
          featureName: 'Service search',
          child: ServiceSearchScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search services, permits, or documents',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _open(context),
        child: GlassPanel(
          dark: true,
          blur: 12,
          borderRadius: BorderRadius.circular(AppRadius.full),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.surface.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Search services, permits, or documents',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.surface.withValues(alpha: 0.85), fontSize: AppTextSize.helper),
                ),
              ),
              Icon(Icons.tune_rounded, color: AppColors.gold300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      dark: true,
      blur: 10,
      borderRadius: BorderRadius.circular(AppRadius.full),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.gold300),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.surface, fontSize: AppTextSize.label, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four shortcuts under the hero, as clay icons on a frosted panel.
/// Every request shortcut goes through RootShell.openService, the one
/// gateway that applies access and duplicate-account rules (a Home shortcut
/// once pushed TulongScreen raw and let an unverified citizen past the
/// tab's gate).
class _QuickActions extends StatelessWidget {
  final bool signedIn;
  const _QuickActions({required this.signedIn});

  @override
  Widget build(BuildContext context) {
    void push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // The English in both languages (owner, 2026-10-23): "Bagong
    // Kahilingan sa Dokyu" was too long for a tile.
    final actions = [
      _QuickAction(
        label: 'New Dokyu Request',
        glyph: ClayGlyph.document,
        onTap: () => RootShell.openService(context, ServiceLauncherTarget.dokyu),
      ),
      _QuickAction(
        label: 'New Tulong Request',
        glyph: ClayGlyph.heart,
        onTap: () => RootShell.openService(context, ServiceLauncherTarget.tulong),
      ),
      if (signedIn) ...[
        _QuickAction(label: tr('My Documents'), glyph: ClayGlyph.folder, onTap: () => push(const DocumentsUploadedScreen())),
        _QuickAction(label: 'Track Requests', glyph: ClayGlyph.pin, onTap: () => push(const MyRequestsScreen())),
      ] else ...[
        _QuickAction(label: tr('Directory'), glyph: ClayGlyph.building, onTap: () => push(const DirectoryScreen())),
        _QuickAction(label: tr('Emergency'), glyph: ClayGlyph.shield, onTap: () => RootShell.jumpTo(context, 3)),
      ],
    ];
    // Glass card + clay icons, the app's signature pairing. Subtle glass
    // with a light blur: it rides over the hero's wave, which softens
    // through it (at the old 62% the navy muddied the labels).
    return GlassSurface.glass(
      blur: true,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, AppSpacing.xs, AppSpacing.md),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final a in actions) Expanded(child: a)],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final ClayGlyph glyph;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.glyph, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
          child: Column(
            children: [
              ClayTile(size: 64, warm: true, child: ClayIcon(glyph, size: 42)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w600, color: AppColors.navy800, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The municipal card shown when staff have no banner live, with a gold
/// arrow into the government directory. The painted navy scene holds the
/// headline on the left and blends, through a gradient, into a photo of the
/// Esperanza Town Hall on the right; the gold ribbon sweeps across both.
class _PromoCard extends StatelessWidget {
  const _PromoCard();

  /// The Esperanza, Masbate town hall, from the photo the LGU team supplied:
  /// two parked motorcycles and a passer-by removed (no real person in a
  /// public repo), then upscaled 2x and sharpened.
  static const _townHallPhoto = 'assets/images/esperanza_town_hall.jpg';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'A more accessible government for you. Open the Government Directory.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DirectoryScreen())),
        child: Container(
          // A floor, not a fixed height: at a large text size the headline
          // takes more lines and the card grows with it.
          constraints: const BoxConstraints(minHeight: 176),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.float),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(
                  painter: EsperanzaScenePainter(focusX: 0.70, sunX: 0.90, sun: 0.24, ground: 0.80, showHall: false),
                ),
              ),
              // The town hall photo on the right 70%, fading in from its
              // left edge so the painted scene flows into it.
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.70,
                    heightFactor: 1,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.clear, AppColors.navy950],
                        stops: [0, 0.45],
                      ).createShader(bounds),
                      child: Image.asset(
                        _townHallPhoto,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.1, 0),
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),
              // A navy scrim from the left, so the white headline never sits
              // on the pale facade.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.navy950.withValues(alpha: 0.55),
                        AppColors.navy950.withValues(alpha: 0.35),
                        AppColors.navy950.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.48, 0.72],
                    ),
                  ),
                ),
              ),
              // The gold ribbon and ground over everything: the card's sweep
              // runs unbroken from the scene across the photo.
              const Positioned.fill(
                child: CustomPaint(painter: EsperanzaScenePainter(ground: 0.80, foregroundOnly: true)),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FractionallySizedBox(
                      widthFactor: 0.56,
                      child: Text(
                        'A more accessible government for you.',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontSize: AppTextSize.card,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          shadows: [Shadow(color: AppColors.navy950, blurRadius: 8)],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [AppColors.gold300, AppColors.gold500]),
                        boxShadow: [BoxShadow(color: AppColors.gold400.withValues(alpha: 0.5), blurRadius: 14, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: AppColors.navy950, size: 22),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One LGU announcement under "Latest Updates": a clay megaphone on a
/// frosted card, the headline, two lines of it and the date. Opens the post.
class _UpdateTile extends StatelessWidget {
  final Announcement post;
  const _UpdateTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final lines = post.body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final title = post.title ?? (lines.isNotEmpty ? lines.first : 'Announcement');
    final rest = post.title != null ? lines.where((l) => l.trim() != post.title!.trim()).join(' ') : lines.skip(1).join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BalitaPostScreen(announcementId: post.remoteId)),
        ),
        child: GlassSurface(
          radius: 24,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClayTile(size: 54, radius: 18, child: ClayIcon(ClayGlyph.megaphone, size: 36)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        rest,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate600, height: 1.35),
                      ),
                    ],
                    if (post.at != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        DateFormat('MMM d, y').format(post.at!.toLocal()),
                        style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestPreviewTile extends StatelessWidget {
  final ServiceRequest request;
  const _RequestPreviewTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                    style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(request.referenceNumber, style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted)),
                ],
              ),
            ),
            StatusChip.request(request.status, small: true, label: request.statusLabel),
          ],
        ),
      ),
    );
  }
}
