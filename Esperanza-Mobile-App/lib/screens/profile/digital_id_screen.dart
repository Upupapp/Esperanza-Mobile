import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/access_level.dart';
import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../utils/demo_resident_photo.dart';
import '../../utils/esperanza_seal.dart';
import '../../utils/government_id.dart';
import '../../widgets/app_card.dart';
import 'government_id_viewer.dart';

/// Esperanza Digital ID — a verified resident's own digital ID card, plus
/// My Government IDs (the seeded document(s) backing that verification).
/// Both sections read the same single GovernmentIdRecord (see
/// utils/government_id.dart) — there is no separate copy for either. Only
/// a verified account gets the actual Digital ID card here; an unverified
/// account (including a duplicate registration still Pending Review) sees
/// an explanatory state instead, never a second verified Esperanza Digital
/// ID for the same resident — but if that unverified account already has a
/// submitted ID on file, it's still shown as a "Submitted ID Document"
/// (pending verification), since submitting an ID and being verified are
/// two different facts.
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
            const Text(
              'My Government IDs',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'The document Esperanza LGU verified to issue your Digital ID.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            _GovernmentIdCard(account: account),
          ] else ...[
            _NotYetVerifiedCard(account: account),
            // Submitting an ID during sign-up and being verified are two
            // different facts (see utils/government_id.dart) — any
            // unverified account (Ronaldo, or either Teodoro duplicate
            // registration) can already have submitted an ID without that
            // ever implying verification on its own.
            if (governmentIdFor(account) != null) ...[
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Submitted ID Document',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'The identification you submitted during registration. Esperanza LGU has not verified it yet — '
                'your Esperanza Digital ID is issued once verification is complete.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              _GovernmentIdCard(account: account),
            ],
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
    final photo = demoProfileImageFor(account);
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

class _GovernmentIdCard extends StatelessWidget {
  final CitizenAccount account;
  const _GovernmentIdCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final record = governmentIdFor(account);
    if (record == null) {
      return AppCard(
        child: Column(
          children: [
            const Icon(Icons.badge_outlined, size: 28, color: AppColors.slate400),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No government ID on file yet.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate600),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => GovernmentIdViewer.open(context, record),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(record.assetPath, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.idType,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Issued by ${record.issuingOffice}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'View',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand600),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.brand600),
              ],
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
