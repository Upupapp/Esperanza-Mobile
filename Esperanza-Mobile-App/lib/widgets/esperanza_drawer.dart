import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/balita_service.dart';
import '../services/master_file_service.dart';
import '../services/notifications_service.dart';
import '../services/requests_service.dart';
import '../services/resident_profile_service.dart';
import '../services/sign_out.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/directory/directory_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_screen.dart';
import '../screens/profile/digital_id_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/shared/documents_uploaded_screen.dart';
import '../screens/shared/my_requests_screen.dart';
import '../screens/support/help_support_screen.dart';
import '../screens/verify/verify_document_screen.dart';
import '../services/citizen_session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/demo_resident_photo.dart';
import 'app_dialogs.dart';
import '../theme/app_typography.dart';
import 'esperanza_art.dart';

import '../l10n/tr.dart';
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
    // 2026-10 design: a soft white body under a navy header that runs up under
    // the status bar; each entry an icon in a soft neumorphic chip.
    return Drawer(
      // Opaque: page text showing through a menu is hard to read.
      backgroundColor: AppColors.slate50,
      surfaceTintColor: AppColors.clear,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(session: session),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  if (session.isSignedIn) ...[
                    _DrawerTile(
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                      onTap: () => _push(context, const ProfileScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.settings_outlined,
                      label: tr('Settings'),
                      onTap: () => _push(context, const SettingsScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.assignment_outlined,
                      label: tr('My Requests'),
                      onTap: () => _push(context, const MyRequestsScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.event_available_outlined,
                      label: tr('Appointments'),
                      onTap: () => _push(context, const AppointmentsScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.badge_outlined,
                      label: 'Digital ID',
                      onTap: () => _push(context, const DigitalIdScreen()),
                    ),
                    _DrawerTile(
                      icon: Icons.folder_open_outlined,
                      label: tr('Documents Uploaded'),
                      onTap: () => _push(context, const DocumentsUploadedScreen()),
                    ),
                  ] else ...[
                    _DrawerTile(
                      icon: Icons.login_rounded,
                      label: tr('Sign In'),
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
                  // Public, as on the website: anyone can check a document.
                  _DrawerTile(
                    icon: Icons.qr_code_scanner_rounded,
                    label: tr('Verify a Document'),
                    onTap: () => _push(context, const VerifyDocumentScreen()),
                  ),
                  _DrawerTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Suporta',
                    onTap: () => _push(context, const HelpSupportScreen()),
                  ),
                  _DrawerTile(
                    icon: Icons.privacy_tip_outlined,
                    label: tr('Privacy Policy'),
                    onTap: () => _push(context, const PrivacyPolicyScreen()),
                  ),
                  _DrawerTile(
                    icon: Icons.gavel_outlined,
                    label: 'Terms and Conditions',
                    onTap: () => _push(context, const TermsScreen()),
                  ),
                  if (session.isSignedIn) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Divider(height: 1),
                    ),
                    _DrawerTile(
                      icon: Icons.logout_rounded,
                      label: tr('Sign Out'),
                      danger: true,
                      onTap: () async {
                        Navigator.of(context).pop();
                        // Read the services BEFORE the await - `context` may be gone by the
                        // time the dialog resolves.
                        final requests = context.read<RequestsService>();
                        final profiles = context.read<ResidentProfileService>();
                        final masterFile = context.read<MasterFileService>();
                        final notifications = context.read<NotificationsService>();
                        final balita = context.read<BalitaService>();
                        final ok = await AppDialogs.confirm(
                          context,
                          title: 'Sign out?',
                          // Says what actually happens. Signing out now erases this
                          // account's profile, photo, requests and documents from the
                          // device, and there is no backend holding a copy - so the old
                          // "sign back in anytime" was a promise the app cannot keep.
                          message: 'Your profile, photo, requests and uploaded documents will be removed '
                              'from this device. You can register or sign in again anytime.',
                          confirmLabel: tr('Sign Out'),
                          danger: true,
                        );
                        if (ok) {
                          await SignOut.signOut(
                            session,
                            requests: requests,
                            profiles: profiles,
                            masterFile: masterFile,
                            notifications: notifications,
                            balita: balita,
                          );
                        }
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
    // showing (this was the root cause behind "Nicanor/Perlita no longer
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
    final personal = account != null ? context.watch<ResidentProfileService>().profileFor(account).personal : null;
    final photo = profileImageFor(account, personal, approvedUrl: context.watch<CitizenSessionService>().photo?.approvedUrl);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, MediaQuery.paddingOf(context).top + AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy950, AppColors.navy800, AppColors.brand800],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold400),
            child: CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surface.withValues(alpha: 0.15),
            backgroundImage: photo,
            onBackgroundImageError: photo != null ? (error, stackTrace) {} : null,
            child: photo != null
                ? null
                : (account != null
                    ? Text(
                        account.initials,
                        style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700, fontSize: AppTextSize.card),
                      )
                    : const Icon(Icons.person_outline_rounded, color: AppColors.surface, size: 26)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            account?.fullName ?? 'Guest',
            style: const TextStyle(color: AppColors.surface, fontSize: AppTextSize.card, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            account != null ? 'Citizen Account · Brgy. ${account.barangay}' : 'Sign in to access more features',
            style: TextStyle(color: AppColors.surface.withValues(alpha: 0.7), fontSize: AppTextSize.label),
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
    final color = danger ? AppColors.rose600 : AppColors.navy900;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: NeuWell(
        radius: AppRadius.md,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, color: danger ? AppColors.rose600 : AppColors.navy700, size: 21),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: color),
      ),
      trailing: danger ? null : const Icon(Icons.chevron_right_rounded, color: AppColors.slate400),
      onTap: onTap,
    );
  }
}
