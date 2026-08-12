import 'package:flutter/material.dart';
import '../../models/access_level.dart';
import '../../theme/app_colors.dart';
import '../../widgets/access_guard.dart';
import '../../widgets/animated_bottom_navigation.dart';
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
    AnimatedBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    AnimatedBottomNavItem(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Dokyu'),
    AnimatedBottomNavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism_rounded, label: 'Tulong'),
    AnimatedBottomNavItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, label: 'Balita'),
    AnimatedBottomNavItem(icon: Icons.shield_outlined, activeIcon: Icons.shield_rounded, label: 'Emergency'),
  ];

  void setTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AnimatedBottomNavigation(
        items: _items,
        currentIndex: _index,
        onTap: setTab,
      ),
    );
  }
}

/// Shared top-right "Alerts" icon button — every root tab's AppBar uses
/// this instead of duplicating the same IconButton/navigation each time.
class AlertsAction extends StatelessWidget {
  const AlertsAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined),
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
