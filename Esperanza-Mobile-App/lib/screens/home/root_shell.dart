import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/access_level.dart';
import '../../services/citizen_session_service.dart';
import '../../services/notification_feed.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/access_guard.dart';
import '../../widgets/magnetic_navbar_core.dart';
import '../../widgets/nav_item_data.dart';
import '../../widgets/promotional_banner_dialog.dart';
import '../balita/balita_screen.dart';
import '../dokyu/dokyu_screen.dart';
import '../notifications/notifications_screen.dart';
import '../sakuna/sakuna_screen.dart';
import '../tulong/tulong_screen.dart';
import 'home_screen.dart';

/// Mobile bottom-nav IA: Home / Dokyu / Tulong / Balita / Emergency.
/// Profile moved into the hamburger drawer (see widgets/esperanza_drawer.dart)
/// and Alerts moved to a top-right icon on each tab's AppBar — freeing the
/// two bottom-tab slots Balita and Emergency (Sakuna) now occupy. Dokyu and
/// Tulong require a Verified account (AccessLevel.verified); Emergency only
/// requires being signed in — withholding emergency/incident reporting
/// behind LGU verification would be poor public-safety practice, so an
/// Unverified citizen can still use it. Home and Balita stay open to
/// Guests. See widgets/access_guard.dart for the enforcement.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  static final GlobalKey<_RootShellState> _key = GlobalKey<_RootShellState>();

  static void jumpTo(BuildContext context, int index) {
    _key.currentState?.setTab(index);
  }

  @override
  State<RootShell> createState() => _RootShellState();

  static RootShell withKey() => RootShell(key: _key);
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    AccessGuard(required: AccessLevel.verified, featureName: 'Dokyu (Document Requests)', child: DokyuScreen()),
    AccessGuard(required: AccessLevel.verified, featureName: 'Tulong (Assistance Requests)', child: TulongScreen()),
    BalitaScreen(),
    AccessGuard(required: AccessLevel.unverified, featureName: 'Risk Reduction & Emergency', child: SakunaScreen()),
  ];

  // Each non-Home tab's promotional popup (Home's own is offered by
  // HomeScreen itself, on its own initState) — centralized here rather
  // than in each tab's own initState because RootShell's IndexedStack
  // builds every tab's State immediately at launch to keep them alive
  // across switches, so a plain initState in e.g. DokyuScreen would fire
  // long before the citizen ever actually opens Dokyu. RootShell is the
  // one place that genuinely knows when a tab becomes the active one
  // (setTab), which is what "first time this tab is opened" actually
  // means. Kept separate per tab (a Set, not one flag) so closing one
  // tab's popup never dismisses another's — session-only, resets on a
  // full relaunch same as every other promotional popup in this app.
  final _tabBannerOffered = <int>{};

  static const _tabBannerAssets = {
    1: ('assets/images/Dokyu Tab.png', 'Dokyu', AccessLevel.verified),
    2: ('assets/images/Tulong Tab.png', 'Tulong', AccessLevel.verified),
    3: ('assets/images/Balita Tab.png', 'Balita', AccessLevel.guest),
    4: ('assets/images/Emergency.png', 'Emergency', AccessLevel.unverified),
  };

  void _maybeShowTabBanner(int index) {
    final entry = _tabBannerAssets[index];
    if (entry == null || _tabBannerOffered.contains(index)) return;
    final (asset, label, required) = entry;
    // Never pop a promotional banner over a RestrictedFeatureNotice — the
    // citizen isn't looking at "the normal screen" in that case, so the
    // popup would be floating over the wrong content entirely. It'll be
    // offered the first time they actually reach the real screen instead.
    if (context.read<CitizenSessionService>().accessLevel.index < required.index) return;
    _tabBannerOffered.add(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) PromotionalBannerDialog.show(context, assetPath: asset, label: label);
    });
  }

  static const _items = [
    NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
    NavItemData(outlineIcon: Icons.description_outlined, filledIcon: Icons.description_rounded, label: 'Dokyu'),
    NavItemData(outlineIcon: Icons.volunteer_activism_outlined, filledIcon: Icons.volunteer_activism_rounded, label: 'Tulong'),
    NavItemData(outlineIcon: Icons.campaign_outlined, filledIcon: Icons.campaign_rounded, label: 'Balita'),
    NavItemData(outlineIcon: Icons.shield_outlined, filledIcon: Icons.shield_rounded, label: 'Emergency'),
  ];

  // Even fifths — same equal-division calibration method as the reference
  // implementation's 5-destination preset, proportional to the bar's own
  // width (not fixed pixels), so all five slots stay correctly positioned
  // at any screen size.
  static const _tabCenterRatios = [0.1, 0.3, 0.5, 0.7, 0.9];

  void setTab(int i) {
    setState(() => _index = i);
    _maybeShowTabBanner(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // MagneticNavbarCore reports a tall bounding box (barHeight +
      // protrusion, for the floating circle's headroom above the pill),
      // but only paints the small pill/circle within it — everywhere else
      // in that box is transparent. Without extendBody, Scaffold reserves
      // that *entire* box as "nav bar territory" and stops body there,
      // which read as an oversized solid block sitting behind/above the
      // actual floating pill. extendBody lets body run underneath the full
      // box instead — exactly Flutter's documented mechanism for a
      // non-rectangular bottomNavigationBar shape — so real page content
      // shows through the transparent headroom and only the painted pill
      // itself is visible, while still auto-adding a matching bottom
      // MediaQuery inset so body content doesn't sit underneath it.
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: MagneticNavbarCore(
        items: _items,
        tabCenterRatios: _tabCenterRatios,
        currentIndex: _index,
        onTap: setTab,
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
