import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/citizen_session_service.dart';
import '../../services/site_content_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/expandable_panel.dart';
import '../profile/data_requests_screen.dart';

/// Privacy Policy — the one the Municipality publishes for the whole
/// platform (web and mobile) from the Web Admin's Settings > Site Content,
/// read from `GET /site-content/privacy`.
///
/// Until 2026-09-28 this screen carried its own text, written when the app
/// had no backend: it said the app connected to no server and left the
/// effective date and the privacy contact as placeholders for the
/// Municipality to fill in. The
/// Municipality had already published all three. Now the text, the date and
/// the contact details are theirs, and change when they publish.
///
/// It never waits on the network: the bundled version 1 shows at once and is
/// replaced by the saved or live copy as soon as one arrives.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  PublishedDocument _policy = SiteContentService.bundledPrivacyPolicyDocument;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final policy = await SiteContentService.privacyPolicy();
    if (!mounted) return;
    setState(() {
      _policy = policy;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final policy = _policy;
    final signedIn = context.watch<CitizenSessionService>().isSignedIn;
    final meta = [
      if (policy.effectiveDate != null) 'Effective ${DateFormat('MMM d, yyyy').format(policy.effectiveDate!)}',
      if (policy.version != null) 'Version ${policy.version}',
    ].join(' · ');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Text(
              'Learn how Esperanza Mobile handles and protects your information.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            if (meta.isNotEmpty)
              Text(
                meta,
                style: const TextStyle(
                  fontSize: AppTextSize.label,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            if (_loaded && policy.source != ContentSource.live) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                policy.source == ContentSource.saved
                    ? 'Could not reach the server, so this is the copy saved on this phone. Pull down to try again.'
                    : 'Could not reach the server, so this is the version included with the app. Pull down to try again.',
                style: AppTypography.helper,
              ),
            ],
            if (policy.intro != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(policy.intro!, style: AppTypography.body),
            ],
            const SizedBox(height: AppSpacing.xl),
            for (final section in policy.sections)
              ExpandablePanel(
                title: section.heading,
                child: Text(section.body, style: AppTypography.body),
              ),
            if (signedIn) ...[
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Your privacy rights', style: AppTypography.cardHeading),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Ask the Municipality to show, correct, delete or give you a copy of the information it holds about you.',
                      style: AppTypography.helper,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Make a Data Request',
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DataRequestsScreen())),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
