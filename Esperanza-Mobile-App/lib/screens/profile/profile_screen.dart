import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/balita_service.dart';
import '../../services/sign_out.dart';
import '../../services/requests_service.dart';
import '../../services/notifications_service.dart';
import '../../services/master_file_service.dart';
import '../../services/citizen_session_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../utils/demo_resident_photo.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/menu_tile.dart';
import '../../widgets/resident_profile_status_card.dart';
import '../../widgets/verification_status_panel.dart';
import '../directory/directory_screen.dart';
import '../support/help_support_screen.dart';
import 'digital_id_screen.dart';
import 'edit_profile_screen.dart';
import 'id_verification_screen.dart';
import 'received_records_screen.dart';
import 'resident_profile/resident_profile_overview_screen.dart';
import 'settings_screen.dart';
import '../../theme/app_typography.dart';
import '../../models/identity_status.dart';
import '../../widgets/identity_status_panel.dart';

/// Profile hub — account summary + links to everything that doesn't get
/// its own bottom-nav tab (Balita/Events, Directory, Risk Reduction,
/// Settings), matching the Web Admin topbar's avatar-dropdown pattern
/// (My Profile / Settings / Sign Out) plus the sidebar items that didn't
/// make the mobile tab bar.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account!;
    final residentProfile = context.watch<ResidentProfileService>().profileFor(account);
    final photo = profileImageFor(account, residentProfile.personal, approvedUrl: session.photo?.approvedUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          // The account card (2026-10 refresh): navy, the photo in a gold
          // ring, the completeness bar in gold.
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl + AppSpacing.xs),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy900, AppColors.navy700, AppColors.brand800],
              ),
              boxShadow: AppShadows.float,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.gold400, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.navy700,
                        backgroundImage: photo,
                        onBackgroundImageError: photo != null ? (error, stackTrace) {} : null,
                        child: photo == null
                            ? Text(
                                account.initials,
                                style: const TextStyle(fontSize: AppTextSize.section, fontWeight: FontWeight.w700, color: AppColors.surface),
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
                            account.fullName,
                            style: const TextStyle(fontSize: AppTextSize.section, fontWeight: FontWeight.w700, color: AppColors.surface),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Citizen Account · Brgy. ${account.barangay}',
                            style: TextStyle(fontSize: AppTextSize.label, color: AppColors.surface.withValues(alpha: 0.78)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            account.id,
                            style: TextStyle(fontSize: AppTextSize.label, color: AppColors.surface.withValues(alpha: 0.78)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: LinearProgressIndicator(
                    value: account.profileCompleteness / 100,
                    minHeight: 7,
                    backgroundColor: AppColors.surface.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold400),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  // Names the form it measures — see home_screen.dart's
                  // Account Details tile.
                  'Account details ${account.profileCompleteness}% complete',
                  style: TextStyle(fontSize: AppTextSize.label, color: AppColors.surface.withValues(alpha: 0.78)),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Edit Profile',
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.gold,
                  fullWidth: true,
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VerificationStatusPanel(
            status: AppStatusX.fromLabel(account.status),
            waitingOnIdentity: account.identityStatus != 'Verified' && account.status != 'Approved',
            // A rejected account sends a new valid ID from here, as on the web
            // portal's Profile; it used to open registration, which makes a
            // second account instead of fixing this one.
            onAction: account.status == 'Rejected'
                ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IdVerificationScreen()))
                : null,
          ),
          // Identity, apart from residency (2026-10-09): a verified identity
          // does not approve residency, and a revoked one pauses requests
          // without changing it.
          if (IdentityStatusX.fromLabel(account.identityStatus) case final identity?) ...[
            const SizedBox(height: AppSpacing.md),
            IdentityStatusPanel(
              status: identity,
              onResend: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IdVerificationScreen())),
            ),
          ] else if (account.status == 'Pending Review' || account.status == 'Rejected') ...[
            // Registered without verifying (2026-10-09, "do it later"): the
            // LGU cannot approve residency until the identity is verified.
            const SizedBox(height: AppSpacing.md),
            IdentityStatusPanel.notStarted(
              onStart: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IdVerificationScreen())),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          MenuListTile(
            icon: Icons.badge_outlined,
            label: 'Digital ID',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DigitalIdScreen())),
          ),
          MenuListTile(
            icon: Icons.verified_user_outlined,
            label: 'Valid ID Verification',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IdVerificationScreen())),
          ),
          ResidentProfileStatusCard(
            profile: residentProfile,
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResidentProfileOverviewScreen())),
          ),
          // What the offices recorded for them, and what they filed (2026-10-13).
          MenuListTile(
            icon: Icons.volunteer_activism_outlined,
            label: 'Dokyu & Tulong Received',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReceivedRecordsScreen())),
          ),
          const SizedBox(height: AppSpacing.xl),
          MenuListTile(
            icon: Icons.home_work_outlined,
            label: 'Household & Family',
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResidentProfileOverviewScreen())),
          ),
          MenuListTile(
            icon: Icons.apartment_outlined,
            label: 'Government Directory',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DirectoryScreen())),
          ),
          MenuListTile(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          MenuListTile(
            icon: Icons.help_outline_rounded,
            label: 'Suporta',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
          MenuListTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            danger: true,
            onTap: () async {
              // Read the services BEFORE the await — `context` may be gone
              // by the time the dialog resolves.
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
                // device, and there is no backend holding a copy — so the old
                // "you can sign back in anytime" would have been a promise the
                // app cannot keep.
                message: 'Your profile, photo, requests and uploaded documents will be removed '
                    'from this device. You can register or sign in again anytime.',
                confirmLabel: 'Sign Out',
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
      ),
    );
  }
}
