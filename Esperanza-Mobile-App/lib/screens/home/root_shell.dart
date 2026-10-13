import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/access_level.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/notification_feed.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../widgets/access_guard.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/esperanza_curved_navbar.dart';
import '../../widgets/nav_item_data.dart';
import '../../utils/banner_memory.dart';
import '../../widgets/promotional_banner_dialog.dart';
import '../../widgets/sakuna_alerts_ui.dart';
import '../../widgets/service_launcher_menu.dart';
import '../balita/balita_screen.dart';
import '../dokyu/dokyu_screen.dart';
import '../events/events_screen.dart';
import '../notifications/notifications_screen.dart';
import '../sakuna/sakuna_screen.dart';
import '../tulong/tulong_screen.dart';
import 'home_screen.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_client.dart';
import '../../widgets/esperanza_drawer.dart';

/// Mobile bottom-nav IA: Home / Balita / + / Events / Emergency, laid out
/// and animated as a direct port of the Servana Client App's curved main
/// navigation (see widgets/esperanza_curved_navbar.dart's doc comment for
/// the exact source). Dokyu and Tulong no longer occupy their own permanent
/// nav slots — the center "+" is a service launcher: tapping it opens
/// [ServiceLauncherMenu], two floating circular bubbles (Dokyu and Tulong)
/// attached directly to the navbar, styled like the navbar's own active
/// bubble rather than a separate panel or sheet.
/// Profile lives in the hamburger drawer (see widgets/esperanza_drawer.dart)
/// and Alerts is a top-right icon on each tab's AppBar. Dokyu and Tulong
/// still require a Verified account (AccessLevel.verified); Emergency only
/// requires being signed in — withholding emergency/incident reporting
/// behind LGU verification would be poor public-safety practice, so an
/// Unverified citizen can still use it. Home and Balita/Events stay open to
/// Guests. See widgets/access_guard.dart for the enforcement.
///
/// Two independent index spaces drive this screen: [_navIndex] (0-3, one
/// per real tab — Home, Balita, Events, Emergency, in that order, matching
/// [_items] and what [EsperanzaCurvedNavBar] shows as its active slot) and
/// [_bodyIndex] (0-5, one per actual screen kept alive in the body's
/// [IndexedStack], since Dokyu and Tulong are still real destinations, just
/// reached through the launcher rather than a direct tab). Whenever Dokyu
/// or Tulong is showing, [_navIndex] is null and [_activeLauncherTarget]
/// holds which one instead — that's the mechanism behind "the center +
/// area stays visually selected while inside Dokyu/Tulong": the navbar's
/// cradle tracks the center slot and the "+" circle itself swaps to that
/// destination's own icon/color, exactly like a tab's active bubble does.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  static final GlobalKey<_RootShellState> _key = GlobalKey<_RootShellState>();

  /// Switches to one of the four real tabs — Home=0, Balita=1, Events=2,
  /// Emergency=3, matching [EsperanzaCurvedNavBar]'s slot order.
  static void jumpTo(BuildContext context, int index) {
    _key.currentState?.setTab(index);
  }

  /// Jumps straight into Dokyu or Tulong without going through the "+"
  /// menu — for call sites where the citizen already expressed a specific
  /// choice (e.g. Home's "Dokyu Requests" stat tile), so re-showing the
  /// picker would just be an extra tap.
  static void openService(BuildContext context, ServiceLauncherTarget target) {
    _key.currentState?.openService(target);
  }

  /// Opens the side menu. It belongs to the shell, not to the tab: a drawer
  /// in a tab's own Scaffold could only cover that tab, so the floating nav
  /// bar (the shell's) stayed on top of it. Outside a shell - a screen shown
  /// on its own - it falls back to that screen's Scaffold.
  static void openDrawer(BuildContext context) {
    final shell = context.findAncestorStateOfType<_RootShellState>();
    if (shell != null) {
      shell._scaffoldKey.currentState?.openDrawer();
    } else {
      Scaffold.maybeOf(context)?.openDrawer();
    }
  }

  @override
  State<RootShell> createState() => _RootShellState();

  static RootShell withKey() => RootShell(key: _key);
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _drawerOpen = false;
  int? _navIndex = 0;
  ServiceLauncherTarget? _activeLauncherTarget;
  int _bodyIndex = 0;
  Timer? _poll;
  NotificationsService? _notifications;
  bool _alertOpen = false;

  @override
  void initState() {
    super.initState();
    // The bell's unread dot needs the server feed as soon as the shell
    // appears, not only once the Notifications screen is opened. After that
    // it refreshes every minute while the app is open and on every return to
    // it: notifications used to arrive only when the app was started.
    WidgetsBinding.instance.addObserver(this);
    _loadNotifications();
    _startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _notifications = context.read<NotificationsService>()..addListener(_maybeShowAlert);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _notifications?.removeListener(_maybeShowAlert);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
      _startPolling();
      // An LGU decision made while the app was in the background shows on
      // return, not only after signing in again (2026-10-13).
      final session = context.read<CitizenSessionService>();
      if (session.account != null && !session.isGuest) {
        session.refresh().catchError((Object _) {});
      }
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _startPolling() {
    _poll ??= Timer.periodic(const Duration(seconds: 60), (_) => _loadNotifications());
  }

  /// A new Sakuna alert opens as a dialog once, on whatever tab is showing.
  Future<void> _maybeShowAlert() async {
    final service = _notifications;
    if (_alertOpen || !mounted || service == null) return;
    final alert = service.pendingAlert;
    if (alert == null) return;
    _alertOpen = true;
    final openEmergency = await SakunaAlertDialog.show(context, alert);
    await service.alertShown(alert);
    _alertOpen = false;
    if (openEmergency && mounted) setTab(3);
    if (mounted) unawaited(_maybeShowAlert());
  }

  Future<void> _loadNotifications() async {
    if (context.read<CitizenSessionService>().account == null) return;
    try {
      await context.read<NotificationsService>().loadServer();
    } on ApiException {
      // The bell keeps what it had; the Notifications screen can retry.
    }
  }

  // Home=0, Balita=1, Events=2, Emergency=3, Dokyu=4, Tulong=5 — see class
  // doc comment for why this is a separate space from the nav's own index.
  final _screens = const [
    HomeScreen(),
    BalitaScreen(),
    EventsScreen(),
    AccessGuard(required: AccessLevel.unverified, featureName: 'Risk Reduction & Emergency', child: SakunaScreen()),
    AccessGuard(required: AccessLevel.verified, featureName: 'Dokyu (Document Requests)', child: DokyuScreen()),
    AccessGuard(required: AccessLevel.verified, featureName: 'Tulong (Assistance Requests)', child: TulongScreen()),
  ];

  // Maps a real nav tab (0-3) to its body page.
  static const _navToBody = {0: 0, 1: 1, 2: 2, 3: 3};

  // Each body page's promotional popup (Home's own is offered by
  // HomeScreen itself, on its own initState) — centralized here rather
  // than in each screen's own initState because RootShell's IndexedStack
  // builds every page's State immediately at launch to keep them alive
  // across switches, so a plain initState in e.g. DokyuScreen would fire
  // long before the citizen ever actually opens Dokyu. RootShell is the
  // one place that genuinely knows when a page becomes the active one,
  // which is what "first time this page is opened" actually means. Kept
  // separate per page (a Set, not one flag) so closing one page's popup
  // never dismisses another's — session-only, resets on a full relaunch
  // same as every other promotional popup in this app.
  final _bannerOffered = <int>{};

  static const _bannerAssets = {
    1: ('assets/images/Balita Tab.png', 'Balita', AccessLevel.guest),
    2: ('assets/images/Balita tab_Events.png', 'Events', AccessLevel.guest),
    // 3 (Emergency) is DELIBERATELY ABSENT. Every other tab's promotional
    // banner costs the citizen one tap. On Risk Reduction & Emergency it costs
    // time during an emergency: observed on a device 2026-08-30, the
    // full-screen popup covered the red "In a life-threatening emergency, call
    // 911 or MDRRMO directly" banner and the evacuation-centre list, and had to
    // be dismissed before either could be read or used.
    //
    // assets/images/Emergency.png is still declared and still shipped — it is
    // used elsewhere on that screen. Only the interstitial is suppressed, so
    // restoring it is re-adding this one line if the LGU decides otherwise.
    4: ('assets/images/Dokyu Tab.png', 'Dokyu', AccessLevel.verified),
    5: ('assets/images/Tulong Tab.png', 'Tulong', AccessLevel.verified),
  };

  void _maybeShowBanner(int bodyIndex) {
    final entry = _bannerAssets[bodyIndex];
    if (entry == null || _bannerOffered.contains(bodyIndex)) return;
    final (asset, label, required) = entry;
    // Never pop a promotional banner over a RestrictedFeatureNotice — the
    // citizen isn't looking at "the normal screen" in that case, so the
    // popup would be floating over the wrong content entirely. It'll be
    // offered the first time they actually reach the real screen instead.
    if (context.read<CitizenSessionService>().accessLevel.index < required.index) return;
    _bannerOffered.add(bodyIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BannerMemory.showOnce(asset, () {
        if (mounted) PromotionalBannerDialog.show(context, assetPath: asset, label: label);
      });
    });
  }

  static const _items = [
    NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
    NavItemData(outlineIcon: Icons.campaign_outlined, filledIcon: Icons.campaign_rounded, label: 'Balita'),
    NavItemData(outlineIcon: Icons.event_outlined, filledIcon: Icons.event_rounded, label: 'Events'),
    NavItemData(outlineIcon: Icons.shield_outlined, filledIcon: Icons.shield_rounded, label: 'Emergency'),
  ];

  /// The nav's own index space (0-3: Home, Balita, Events, Emergency).
  void setTab(int i) {
    AppHaptics.selection();
    final body = _navToBody[i]!;
    setState(() {
      _navIndex = i;
      _activeLauncherTarget = null;
      _bodyIndex = body;
    });
    _maybeShowBanner(body);
  }

  /// Opens (or, if already open, closes) the center "+" launcher's floating
  /// Dokyu/Tulong bubbles — mirrors how Servana's own Book action never
  /// selects a tab itself, only opens something; the expansion's own
  /// choice is what advances state, via [openService]. Tapping the button
  /// again while it's already expanded toggles it closed instead of
  /// silently doing nothing.
  void _openLauncher() {
    if (ServiceLauncherMenu.isOpen) {
      ServiceLauncherMenu.dismiss();
    } else {
      ServiceLauncherMenu.show(context, onSelect: openService);
    }
  }

  /// Both the launcher's bubbles and Home's own "jump straight to
  /// Dokyu/Tulong" tiles funnel through this one gateway, so the confirmed
  /// duplicate account (Phase 6 — see MockCatalog.duplicateVerifiedDemoAccount)
  /// is intercepted here regardless of entry point, rather than only when
  /// reached through the "+" — it never becomes Verified in this
  /// simulation, so it can never legitimately land on Dokyu/Tulong's own
  /// AccessGuard-gated screen; showing that screen's generic restricted
  /// notice here would just be confusing given the citizen already knows
  /// exactly why (a duplicate of their own verified account exists).
  void openService(ServiceLauncherTarget target) {
    final session = context.read<CitizenSessionService>();
    if (session.account?.id == MockCatalog.duplicateVerifiedDemoAccount.id) {
      _promptSwitchToVerifiedAccount();
      return;
    }
    AppHaptics.selection();
    final body = target == ServiceLauncherTarget.dokyu ? 4 : 5;
    setState(() {
      _navIndex = null;
      _activeLauncherTarget = target;
      _bodyIndex = body;
    });
    _maybeShowBanner(body);
  }

  /// "Go to My Verified Account" switches the frontend session straight to
  /// the real, verified Perlita and lands on Home — deliberately not
  /// straight into Dokyu/Tulong, so the account switch itself stays
  /// legible before the citizen deliberately re-opens the launcher (this
  /// screen's own class doc explains why that separation matters here).
  Future<void> _promptSwitchToVerifiedAccount() async {
    final switchAccount = await AppDialogs.confirm(
      context,
      title: 'Use Your Verified Account',
      message:
          'This account is a duplicate of an existing verified Esperanza account. You can continue using this '
          'account for available public features, but Dokyu and Tulong are only available through your verified '
          'account.',
      confirmLabel: 'Go to My Verified Account',
      cancelLabel: 'Not Now',
    );
    if (!switchAccount || !mounted) return;

    await context.read<CitizenSessionService>().login(MockCatalog.demoAccounts.last);
    if (!mounted) return;
    setState(() {
      _navIndex = 0;
      _activeLauncherTarget = null;
      _bodyIndex = 0;
    });
    if (mounted) AppDialogs.toast(context, 'Switched to your verified Esperanza account.');
  }

  @override
  Widget build(BuildContext context) {
    // Back closes an open side menu. Android 16 handles Back predictively,
    // and an open drawer on the app's first route did not claim it: Back
    // closed the whole app instead of the menu (seen on the emulator,
    // 2026-10-09). While the menu is open the shell says it cannot pop, and
    // closes the menu itself.
    return PopScope(
      canPop: !_drawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _drawerOpen) _scaffoldKey.currentState?.closeDrawer();
      },
      child: _scaffold(),
    );
  }

  Widget _scaffold() {
    return Scaffold(
      key: _scaffoldKey,
      // The side menu, above everything in the shell - the nav bar included.
      drawer: const EsperanzaDrawer(),
      onDrawerChanged: (open) => setState(() => _drawerOpen = open),
      // EsperanzaCurvedNavBar reports a bounding box that is its own bar
      // height only (matching Servana's own SizedBox — see
      // widgets/esperanza_curved_navbar.dart); the raised bubble and "+"
      // overflow above it via the internal Stack's Clip.none. Without
      // extendBody, Scaffold would still reserve that box as solid "nav bar
      // territory" and stop body there, which reads as a block behind the
      // curved surface's transparent corners. extendBody lets body run
      // underneath instead — Flutter's documented mechanism for a
      // non-rectangular bottomNavigationBar — while still publishing a
      // matching bottom MediaQuery inset so body content (e.g. the FAB
      // clearance math in screens/shared/request_list_screen.dart) doesn't
      // sit underneath it.
      extendBody: true,
      // The tabs are clear; this page's route paints the soft backdrop
      // beneath them (BackdropPageTransitionsBuilder), so their glass cards
      // show colour through them.
      body: IndexedStack(index: _bodyIndex, children: _screens),
      bottomNavigationBar: EsperanzaCurvedNavBar(
        items: _items,
        activeIndex: _navIndex,
        activeLauncherTarget: _activeLauncherTarget,
        onTabSelected: setTab,
        onCenterPressed: _openLauncher,
      ),
    );
  }
}

/// The menu button at the leading edge of every tab's AppBar: opens the
/// shell's side menu (see [RootShell.openDrawer]).
class ShellMenuButton extends StatelessWidget {
  const ShellMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: () => RootShell.openDrawer(context),
    );
  }
}

/// Shared top-right "Alerts" icon button — every root tab's AppBar uses
/// this instead of duplicating the same IconButton/navigation each time.
class AlertsAction extends StatelessWidget {
  // Left null everywhere except Home's hero, which sits directly on a
  // dark navy/brand gradient rather than inside an AppBar — the AppBar
  // theme's foregroundColor (dark, correct for every other screen's
  // white AppBar) would be invisible there, so only that one call site
  // passes an explicit white override.
  final Color? color;

  /// False where the bell sits in its own circle (Home's hero) rather than
  /// at the trailing edge of an AppBar.
  final bool edgePadding;
  const AlertsAction({super.key, this.color, this.edgePadding = true});

  @override
  Widget build(BuildContext context) {
    final ids = buildNotificationFeed(context).map((n) => n.id);
    final unread = context.watch<NotificationsService>().unreadCount(ids);

    return Padding(
      // AppBar's auto-generated leading hamburger sits inside a 56-wide
      // box (centering its icon ~16px in from the true screen edge), but
      // `actions` are packed flush against the trailing edge with no
      // equivalent margin — this pulls the bell in by roughly the same
      // amount so the header reads as symmetrical left-to-right, without
      // touching icon size or notification behavior.
      padding: EdgeInsets.only(right: edgePadding ? AppSpacing.sm : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: color),
            tooltip: unread == 0 ? 'Alerts' : 'Alerts, $unread unread',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          // How many are unread (Esperanza QA, 2026-10-07: a dot did not say
          // how many); nothing at all when everything is read.
          if (unread > 0)
            Positioned(
              top: 4,
              right: 2,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.rose500,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: AppTextSize.fine,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small helper so cards can render a "brand" colored icon container
/// without repeating the same BoxDecoration everywhere.
class BrandIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  const BrandIconBox({super.key, required this.icon, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(icon, size: size * 0.45, color: AppColors.brand600),
    );
  }
}
