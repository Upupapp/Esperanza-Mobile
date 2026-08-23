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
import '../../widgets/promotional_banner_dialog.dart';
import '../../widgets/service_launcher_menu.dart';
import '../balita/balita_screen.dart';
import '../dokyu/dokyu_screen.dart';
import '../events/events_screen.dart';
import '../notifications/notifications_screen.dart';
import '../sakuna/sakuna_screen.dart';
import '../tulong/tulong_screen.dart';
import 'home_screen.dart';

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

  @override
  State<RootShell> createState() => _RootShellState();

  static RootShell withKey() => RootShell(key: _key);
}

class _RootShellState extends State<RootShell> {
  int? _navIndex = 0;
  ServiceLauncherTarget? _activeLauncherTarget;
  int _bodyIndex = 0;

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
    3: ('assets/images/Emergency.png', 'Emergency', AccessLevel.unverified),
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
      if (mounted) PromotionalBannerDialog.show(context, assetPath: asset, label: label);
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
  /// duplicate account (Phase 6 — see MockCatalog.duplicateCristyAccount)
  /// is intercepted here regardless of entry point, rather than only when
  /// reached through the "+" — it never becomes Verified in this
  /// simulation, so it can never legitimately land on Dokyu/Tulong's own
  /// AccessGuard-gated screen; showing that screen's generic restricted
  /// notice here would just be confusing given the citizen already knows
  /// exactly why (a duplicate of their own verified account exists).
  void openService(ServiceLauncherTarget target) {
    final session = context.read<CitizenSessionService>();
    if (session.account?.id == MockCatalog.duplicateCristyAccount.id) {
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
  /// the real, verified Cristy and lands on Home — deliberately not
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
    return Scaffold(
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

/// Shared top-right "Alerts" icon button — every root tab's AppBar uses
/// this instead of duplicating the same IconButton/navigation each time.
class AlertsAction extends StatelessWidget {
  // Left null everywhere except Home's hero, which sits directly on a
  // dark navy/brand gradient rather than inside an AppBar — the AppBar
  // theme's foregroundColor (dark, correct for every other screen's
  // white AppBar) would be invisible there, so only that one call site
  // passes an explicit white override.
  final Color? color;
  const AlertsAction({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final ids = buildNotificationFeed(context).map((n) => n.id);
    final hasUnread = context.watch<NotificationsService>().hasUnread(ids);

    return Padding(
      // AppBar's auto-generated leading hamburger sits inside a 56-wide
      // box (centering its icon ~16px in from the true screen edge), but
      // `actions` are packed flush against the trailing edge with no
      // equivalent margin — this pulls the bell in by roughly the same
      // amount so the header reads as symmetrical left-to-right, without
      // touching icon size or notification behavior.
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: color),
            tooltip: 'Alerts',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          // Small, subtle unread marker — never a numeric badge, this app
          // has no unread-count system beyond "read or not".
          if (hasUnread)
            Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.rose500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
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
