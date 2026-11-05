import 'package:flutter/material.dart';

import '../../models/resident_certificate.dart';
import '../../services/certificates_service.dart';
import '../../services/message_language.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/date_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state.dart';
import '../shared/certificate_view_screen.dart';

/// The website's own Filipino (welfare-citizen.js and
/// components/citizen/welfare-received.blade.php), written there as
/// Filipino / English; shown in the language chosen in Settings. A phrase
/// the website has no Filipino for is plain English.
String _t(String fil, String en) => MessageLanguage.filipino.value ? fil : en;

/// "Aking mga sertipiko" (owner, 2026-11-05, sheet item 9): every
/// certificate the resident holds - from a group session (theirs, or a
/// partner's copy naming them) and from an event they attended - as on the
/// website's Tulong page, opened from the Tulong screen.
///
/// [openControlNumber] comes from a notification's `?certificate=` link
/// (the partner's copy): that certificate is shown once the list is read,
/// and marked in it; one not in the list is said so plainly.
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key, this.openControlNumber});

  final String? openControlNumber;

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  int _generation = 0;

  /// The linked certificate is opened once, not on every rebuild.
  bool _opened = false;

  void _open(ResidentCertificate c) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateViewScreen(certificate: c)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('certificates_screen'),
      appBar: AppBar(title: Text(_t('Aking mga sertipiko', 'My certificates'))),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _generation++),
        child: AsyncStateView<List<ResidentCertificate>>(
          key: ValueKey('certificates-$_generation'),
          loader: CertificatesService.mine,
          builder: (context, list, reload) {
            final wanted = widget.openControlNumber;
            final target = wanted == null ? null : list.where((c) => c.controlNumber == wanted).firstOrNull;
            if (target != null && !_opened) {
              _opened = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _open(target);
              });
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                AppSpacing.scrollEnd + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                const Text(
                  "Certificates from the group sessions and events you attended, including a partner's copy that names you.",
                  style: AppTypography.helper,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                if (wanted != null && target == null)
                  Container(
                    key: const Key('certificate_not_found'),
                    margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.amber50,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.gold200),
                    ),
                    child: Text(
                      'Certificate $wanted is not in your list yet. Pull down to refresh, or ask the office that issued it.',
                      style: AppTypography.bodyText.copyWith(color: AppColors.amber700),
                    ),
                  ),
                if (list.isEmpty)
                  const EmptyState(
                    icon: Icons.workspace_premium_outlined,
                    title: 'No certificates yet',
                    description: 'Certificates from the sessions and events you attend are listed here once they are issued.',
                  )
                else
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                      child: _CertificateCard(
                        certificate: c,
                        highlighted: identical(c, target),
                        onOpen: () => _open(c),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.certificate, required this.highlighted, required this.onOpen});

  final ResidentCertificate certificate;
  final bool highlighted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = certificate;
    final (fg, bg) = c.isEvent ? (AppColors.indigo700, AppColors.indigo50) : (AppColors.amber700, AppColors.amber50);
    final where = [
      if (c.isEvent && c.eventTitle != null) c.eventTitle!,
      if (c.date != null) shortDate(c.date!),
      if (c.venue != null) c.venue!,
      c.controlNumber,
    ].join(' · ');
    final card = AppCard(
      key: Key('certificate_${c.controlNumber}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(c.title ?? _t('Sertipiko', 'Certificate'), style: AppTypography.cardHeading)),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(
                  c.isEvent ? _t('Kaganapan', 'Event') : _t('Sesyon', 'Session'),
                  style: AppTypography.labelText.copyWith(color: fg),
                ),
              ),
            ],
          ),
          if (c.holderNames.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(c.holderNames.join(_t(' at ', ' and ')), style: AppTypography.helper),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(where, style: AppTypography.helper),
          if (c.issuedOn != null) Text('${_t('Inilabas noong', 'Issued on')} ${shortDate(c.issuedOn!)}', style: AppTypography.helper),
          const SizedBox(height: AppSpacing.md),
          // Withdrawn: still opens, with REVOKED across it, as on the website.
          if (c.revoked) ...[
            Text(revokedNote(c), style: AppTypography.bodyText.copyWith(color: AppColors.rose700)),
            const SizedBox(height: AppSpacing.sm),
          ],
          AppButton(
            label: _t('Tingnan ang sertipiko', 'View certificate'),
            icon: Icons.workspace_premium_outlined,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
    if (!highlighted) return card;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brand500, width: 2),
      ),
      child: card,
    );
  }
}
