import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/site_content_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/expandable_panel.dart';

import '../../l10n/tr.dart';
/// Terms and Conditions: the ones the Municipality publishes for web and
/// mobile alike (`GET /site-content/terms`, the web portal's
/// /citizen/legal/terms). Registration asks the resident to accept them, and
/// until now the app showed only a short summary of its own instead.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  PublishedDocument? _terms;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final terms = await SiteContentService.terms();
    if (!mounted) return;
    setState(() {
      _terms = terms;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final terms = _terms;
    return Scaffold(
      appBar: AppBar(title: const Text('Terms and Conditions')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            if (!_loaded)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (terms == null) ...[
              const Text(
                'The Terms and Conditions could not be loaded. Check your connection and try again.',
                style: AppTypography.helper,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: tr('Try again'), variant: AppButtonVariant.secondary, onPressed: _load),
            ] else ...[
              Text(terms.title, style: AppTypography.sectionTitle),
              if (terms.effectiveDate != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Effective ${DateFormat('MMM d, yyyy').format(terms.effectiveDate!)}',
                  style: const TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
              if (terms.source == ContentSource.saved) ...[
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Could not reach the server, so this is the copy saved on this phone. Pull down to try again.',
                  style: AppTypography.helper,
                ),
              ],
              if (terms.intro != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(terms.intro!, style: AppTypography.body),
              ],
              const SizedBox(height: AppSpacing.xl),
              for (final section in terms.sections)
                ExpandablePanel(title: section.heading, child: Text(section.body, style: AppTypography.body)),
            ],
          ],
        ),
      ),
    );
  }
}
