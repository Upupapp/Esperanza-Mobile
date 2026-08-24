import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/access_level.dart';
import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../utils/demo_resident_photo.dart';
import '../../utils/esperanza_seal.dart';
import '../../widgets/app_card.dart';

/// Esperanza Digital ID — conceptually a resident's own wallet/viewer for
/// *official, already-issued* digital government credentials (National ID,
/// PhilHealth ID, Barangay ID, Senior Citizen ID, PWD ID, and future LGU
/// credentials), the way eGovPH presents a citizen's own government IDs.
/// This is a frontend/demo concept only — this project has no real
/// integration with eGovPH, PhilSys, PhilHealth, or any other government
/// database.
///
/// The physical ID a resident uploads during registration is a *different*
/// concept — that's evidence submitted for LGU verification, shown at
/// Profile > Personal Information > Submitted Government ID (see
/// resident_profile/personal_information_screen.dart), not here. Only a
/// verified account gets the Esperanza Digital ID card; an unverified
/// account (including a duplicate registration still Pending Review) sees
/// an explanatory state instead, never a second verified Digital ID for the
/// same resident.
class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account!;
    final isVerified = session.accessLevel == AccessLevel.verified;

    return Scaffold(
      appBar: AppBar(title: const Text('Digital ID')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (isVerified) ...[
            _EsperanzaIdCard(account: account),
            const SizedBox(height: AppSpacing.xl),
            const _FutureCredentialsSection(),
          ] else ...[
            _NotYetVerifiedCard(account: account),
          ],
        ],
      ),
    );
  }
}

class _EsperanzaIdCard extends StatelessWidget {
  final CitizenAccount account;
  const _EsperanzaIdCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final personal = context.watch<ResidentProfileService>().profileFor(account).personal;
    final photo = profileImageFor(account, personal);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy900, AppColors.brand700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.navy900.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(esperanzaSealAsset, width: 32, height: 32, fit: BoxFit.cover),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Esperanza Digital ID',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.emerald500, borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 3),
                    Text('Verified', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                backgroundImage: photo,
                child: photo != null
                    ? null
                    : Text(
                        account.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Brgy. ${account.barangay}, Esperanza, Masbate',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resident ID',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        account.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 34),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This is a frontend simulation. No real government ID system issued this card.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// A preview of *other* official digital government credentials this
/// resident may eventually be able to view here (National ID, PhilHealth,
/// etc.) — inspired by eGovPH's own credential-wallet UX only. Every row is
/// a locked placeholder: this project has no real integration with eGovPH,
/// PhilSys, PhilHealth, or any other government database, and the document
/// uploaded during registration never appears in this list (see this file's
/// own class-level doc comment for why those are two different concepts).
class _FutureCredentialsSection extends StatelessWidget {
  const _FutureCredentialsSection();

  static const _credentials = [
    (icon: Icons.badge_outlined, label: 'National ID (PhilSys)'),
    (icon: Icons.health_and_safety_outlined, label: 'PhilHealth ID'),
    (icon: Icons.location_city_outlined, label: 'Barangay ID'),
    (icon: Icons.groups_outlined, label: 'Senior Citizen ID'),
    (icon: Icons.accessible_outlined, label: 'PWD ID'),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Other Government Credentials',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Other official government IDs will appear here once available. This is a frontend preview only.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final c in _credentials) ...[
            _LockedCredentialRow(icon: c.icon, label: c.label),
            if (c != _credentials.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _LockedCredentialRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LockedCredentialRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.6,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: AppColors.slate500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(999)),
            child: const Text(
              'Coming soon',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate500),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotYetVerifiedCard extends StatelessWidget {
  final CitizenAccount account;
  const _NotYetVerifiedCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.hourglass_top_rounded, size: 26, color: AppColors.amber700),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Digital ID not yet available',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Your Esperanza Digital ID is issued once Esperanza LGU verifies your account. '
            'Current status: ${AppStatusX.fromLabel(account.status).label}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
