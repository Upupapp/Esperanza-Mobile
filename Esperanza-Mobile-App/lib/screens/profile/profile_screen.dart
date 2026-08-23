import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/citizen_session_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../utils/demo_resident_photo.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/menu_tile.dart';
import '../../widgets/resident_profile_status_card.dart';
import '../../widgets/verification_status_panel.dart';
import '../auth/register_screen.dart';
import '../directory/directory_screen.dart';
import '../support/help_support_screen.dart';
import 'digital_id_screen.dart';
import 'edit_profile_screen.dart';
import 'resident_profile/resident_profile_overview_screen.dart';
import 'settings_screen.dart';

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
    final photo = demoProfileImageFor(account);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.brand50,
                  backgroundImage: photo,
                  child: photo == null
                      ? Text(
                          account.initials,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.brand600),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  account.fullName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${account.id} · Brgy. ${account.barangay}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: account.profileCompleteness / 100,
                    minHeight: 7,
                    backgroundColor: AppColors.slate100,
                    valueColor: const AlwaysStoppedAnimation(AppColors.emerald500),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Profile ${account.profileCompleteness}% complete',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Profile'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          VerificationStatusPanel(
            status: AppStatusX.fromLabel(account.status),
            onAction: account.status == 'Rejected'
                ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()))
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          MenuListTile(
            icon: Icons.badge_outlined,
            label: 'Digital ID',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DigitalIdScreen())),
          ),
          ResidentProfileStatusCard(
            profile: residentProfile,
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResidentProfileOverviewScreen())),
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
            label: 'Help & Support',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
          ),
          const SizedBox(height: AppSpacing.md),
          MenuListTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            danger: true,
            onTap: () async {
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
      ),
    );
  }
}
