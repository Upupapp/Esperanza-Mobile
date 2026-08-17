import 'package:flutter/material.dart';
import '../../models/access_level.dart';
import '../../theme/app_colors.dart';
import '../../widgets/access_guard.dart';
import '../../widgets/magnetic_navbar_core.dart';
import '../../widgets/nav_item_data.dart';
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

  void setTab(int i) => setState(() => _index = i);

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
    return IconButton(
      icon: Icon(Icons.notifications_outlined, color: color),
      tooltip: 'Alerts',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
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
