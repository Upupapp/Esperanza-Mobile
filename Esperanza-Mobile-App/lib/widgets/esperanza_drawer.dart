import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth/register_screen.dart';
import '../screens/directory/directory_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../services/citizen_session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_dialogs.dart';

/// The app's hamburger-menu drawer (Section 2) — hosts Profile and the
/// screens that no longer have a dedicated bottom tab now that Balita and
/// Emergency have taken two of the five slots. Content adapts to the
/// current [CitizenSessionService] state: Guests see Sign In / Create
/// Account front and center (Section 11 — registration must be easy to
/// find, not buried), signed-in citizens see their usual account menu.
class EsperanzaDrawer extends StatelessWidget {
  const EsperanzaDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(session: session),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  if (session.isSignedIn) ...[
                    _DrawerTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () => _push(context, const ProfileScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => _push(context, const SettingsScreen()),
                    ),
                  ] else ...[
                    _DrawerTile(
                      icon: Icons.login_rounded,
                      label: 'Sign In',
                      onTap: () => _goToAuth(context, register: false),
                    ),
                    _DrawerTile(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Create Account',
                      onTap: () => _goToAuth(context, register: true),
                    ),
                  ],
                  _DrawerTile(
                    icon: Icons.apartment_outlined,
                    label: 'Government Directory',
                    onTap: () => _push(context, const DirectoryScreen()),
                  ),
                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () {
                      Navigator.of(context).pop();
                      AppDialogs.toast(context, 'Help & Support content coming soon.');
                    },
                  ),
                  if (session.isSignedIn) ...[
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                    _DrawerTile(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      danger: true,
                      onTap: () async {
                        Navigator.of(context).pop();
                        final ok = await AppDialogs.confirm(
                          context,
                          title: 'Sign out?',
                          message: 'You can sign back in anytime with your registered email.',
                          confirmLabel: 'Sign Out',
                          danger: true,
                        );
                        if (ok) await session.logout();
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _goToAuth(BuildContext context, {required bool register}) async {
    Navigator.of(context).pop(); // close the drawer
    await context.read<CitizenSessionService>().endGuestSession();
    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    // Pop back to the root route rather than pushing a fresh LoginScreen/
    // RegisterScreen on top of an otherwise-emptied stack. The root route
    // is _AuthGate (main.dart), which just reacted to endGuestSession()
    // above and is already showing LoginScreen on its own — the previous
    // `pushAndRemoveUntil(..., (route) => false)` removed _AuthGate from
    // the stack entirely, so any *later* login()/logout() had nothing
    // left to react to, leaving the user stuck on whatever screen was
    // showing (this was the root cause behind "Ronaldo/Marites no longer
    // opening" when reached via this Sign In / Create Account path).
    nav.popUntil((route) => route.isFirst);
    if (register) {
      nav.push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    }
  }
}

class _Header extends StatelessWidget {
  final CitizenSessionService session;
  const _Header({required this.session});

  @override
  Widget build(BuildContext context) {
    final account = session.account;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.navy900, AppColors.brand700]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            child: account != null
                ? Text(account.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))
                : const Icon(Icons.person_outline_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            account?.fullName ?? 'Guest',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            account != null ? 'Brgy. ${account.barangay}' : 'Sign in to access more features',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _DrawerTile({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.rose600 : AppColors.slate700;
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.rose500 : AppColors.slate500, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }
}
