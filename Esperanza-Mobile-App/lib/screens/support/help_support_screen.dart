import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/citizen_session_service.dart';
import '../../services/site_content_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/phone_dial.dart';
import '../../utils/app_version.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expandable_panel.dart';
import '../../widgets/helpful_vote.dart';
import '../../widgets/segmented_tabs.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_screen.dart';
import '../sakuna/report_incident_screen.dart';
import 'report_problem_screen.dart';
import 'support_tickets_screen.dart';

import '../../l10n/tr.dart';
/// Suporta, as the website's Help & Support page (citizen/help): FAQs,
/// Tutorials and Support. Every answer is the LGU's own, published in
/// Settings > Site Content, so the website and the app say the same thing
/// and the office corrects it in one place. The app used to carry its own
/// answers as well, and they drifted (a "simulated" face check long after it
/// was real; files the server does not accept); its phone troubleshooting now
/// lives in the FAQ under "Mobile app" (2026-10-22).
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

enum _HelpTab { faqs, tutorials, support }

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  HelpContent? _content;
  _HelpTab _tab = _HelpTab.faqs;
  String _faqSearch = '';
  String? _faqCategory;
  String _tutorialSearch = '';
  String? _tutorialCategory;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    if (_content != null) setState(() => _content = null);
    final content = await SiteContentService.help();
    if (mounted) setState(() => _content = content);
  }

  bool _matches(String search, Iterable<String?> texts) {
    final q = search.trim().toLowerCase();
    return q.isEmpty || texts.whereType<String>().join(' ').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    // The Tutorials tab shows only while a tutorial has something behind it.
    final tabs = [_HelpTab.faqs, if (content?.tutorials.isNotEmpty ?? false) _HelpTab.tutorials, _HelpTab.support];
    final tab = tabs.contains(_tab) ? _tab : _HelpTab.faqs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporta'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'FAQs, tutorials, and support from the ICT Office.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.helper.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          SegmentedTabs(
            labels: [
              for (final t in tabs)
                switch (t) {
                  _HelpTab.faqs => tr('FAQs'),
                  _HelpTab.tutorials => tr('Tutorials'),
                  _HelpTab.support => tr('Support'),
                },
            ],
            selectedIndex: tabs.indexOf(tab),
            onChanged: (i) => setState(() => _tab = tabs[i]),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...switch (tab) {
            _HelpTab.faqs => _faqs(context, content),
            _HelpTab.tutorials => _tutorials(content!),
            _HelpTab.support => _support(context, content),
          },
        ],
      ),
    );
  }

  /// A search box, the categories the LGU used, the count, and the answers.
  List<Widget> _faqs(BuildContext context, HelpContent? content) {
    if (content == null) {
      return const [
        Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: Center(child: CircularProgressIndicator())),
      ];
    }
    if (content.faqsFailed) {
      return [
        EmptyState(
          icon: Icons.cloud_off_rounded,
          title: tr('Could not load'),
          description: tr('Could not load the FAQs.'),
          action: AppButton(label: tr('Try again'), variant: AppButtonVariant.secondary, onPressed: _loadContent),
        ),
      ];
    }
    final categories = {for (final f in content.faqs) ?f.category}.toList();
    final shown = [
      for (final f in content.faqs)
        if ((_faqCategory == null || f.category == _faqCategory) && _matches(_faqSearch, [f.question, f.answer])) f,
    ];
    final signedIn = context.watch<CitizenSessionService>().account != null;
    return [
      AppTextField(hintText: tr('Search FAQs...'), icon: Icons.search_rounded, onChanged: (v) => setState(() => _faqSearch = v)),
      const SizedBox(height: AppSpacing.md),
      _CategoryChips(
        categories: categories,
        selected: _faqCategory,
        onSelected: (c) => setState(() => _faqCategory = c),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text('${shown.length} ${shown.length == 1 ? 'result' : 'results'}', style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
      const SizedBox(height: AppSpacing.sm),
      if (shown.isEmpty)
        EmptyState(
          icon: Icons.help_outline_rounded,
          title: content.faqs.isEmpty
              ? 'No FAQs are published yet. Submit a support ticket if you need help.'
              : 'No FAQs match your search.',
        )
      else
        for (final faq in shown)
          ExpandablePanel(
            title: faq.question,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(faq.answer, style: AppTypography.body),
                // Signed in only: the server counts one answer per resident.
                if (signedIn) HelpfulVote(docKey: 'faqs', item: faq.key),
              ],
            ),
          ),
    ];
  }

  List<Widget> _tutorials(HelpContent content) {
    final categories = {for (final t in content.tutorials) ?t.category}.toList();
    final shown = [
      for (final t in content.tutorials)
        if ((_tutorialCategory == null || t.category == _tutorialCategory) &&
            _matches(_tutorialSearch, [t.title, t.description, t.category]))
          t,
    ];
    return [
      AppTextField(
        hintText: tr('Search tutorials...'),
        icon: Icons.search_rounded,
        onChanged: (v) => setState(() => _tutorialSearch = v),
      ),
      const SizedBox(height: AppSpacing.md),
      _CategoryChips(
        categories: categories,
        selected: _tutorialCategory,
        onSelected: (c) => setState(() => _tutorialCategory = c),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text('${shown.length} ${shown.length == 1 ? 'result' : 'results'}', style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
      const SizedBox(height: AppSpacing.sm),
      if (shown.isEmpty)
        EmptyState(icon: Icons.school_outlined, title: tr('No tutorials match your search.'))
      else
        for (final t in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
            child: AppCard(
              onTap: t.link == null
                  ? null
                  : () {
                      final uri = Uri.tryParse(t.link!);
                      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    t.link == null ? Icons.article_outlined : Icons.play_circle_outline_rounded,
                    color: AppColors.brand600,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.category != null)
                          Text(t.category!, style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
                        Text(t.title, style: AppTypography.bodyMedium),
                        if (t.description != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(t.description!, style: AppTypography.helper),
                        ],
                      ],
                    ),
                  ),
                  if (t.duration != null) Text(t.duration!, style: AppTypography.fine),
                ],
              ),
            ),
          ),
    ];
  }

  /// The website's Support tab: an incident is not a ticket; a new ticket;
  /// the tickets so far; then how to reach the office.
  List<Widget> _support(BuildContext context, HelpContent? content) {
    final signedIn = context.watch<CitizenSessionService>().isSignedIn;
    return [
      if (signedIn) ...[
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.rose600),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('Flooding, fire, a landslide or an accident?'), style: AppTypography.cardHeading),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          "Don't file it as a ticket: report an incident so the MDRRMO sees it at once.",
                          style: AppTypography.helper.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: tr('Report an incident'),
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportIncidentScreen(accent: AppColors.rose600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      _LinkCard(
        icon: Icons.flag_outlined,
        tint: AppColors.rose50,
        color: AppColors.rose600,
        label: tr('Submit a Support Ticket'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportProblemScreen())),
      ),
      if (signedIn) ...[
        const SizedBox(height: AppSpacing.md),
        _LinkCard(
          icon: Icons.confirmation_number_outlined,
          tint: AppColors.brand50,
          color: AppColors.brand600,
          label: tr('My Support Tickets'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportTicketsScreen())),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Municipality of Esperanza Support', style: AppTypography.subsectionLabel),
            const SizedBox(height: AppSpacing.md),
            if (content == null)
              const Text('Loading contact details…', style: AppTypography.helper)
            else if (content.channels.isEmpty && content.officeHours == null)
              Row(
                children: [
                  const Expanded(child: Text('Contact details could not be loaded.', style: AppTypography.helper)),
                  TextButton(onPressed: _loadContent, child: Text(tr('Try again'))),
                ],
              )
            else ...[
              for (final c in content.channels)
                _ContactRow(icon: _channelIcon(c.key), label: c.label, value: c.value, onTap: _channelAction(c)),
              if (content.officeHours != null)
                _ContactRow(icon: Icons.schedule_outlined, label: tr('Office Hours'), value: content.officeHours!),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xxl),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            child: Text(tr('Privacy Policy'), style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600, color: AppColors.brand600)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
            child: Text(
              'Terms and Conditions',
              style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600, color: AppColors.brand600),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Center(
        child: Text('Esperanza Mobile — Version $appVersion', style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
      ),
    ];
  }
}

/// "All" and each category, as the website's filter row.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.categories, required this.selected, required this.onSelected});

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final c in [null, ...categories]) ...[
            ChoiceChip(
              label: Text(c ?? 'All'),
              selected: selected == c,
              onSelected: (_) => onSelected(c),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.tint, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color tint;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(icon, size: AppSizes.iconSm, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.slate700))),
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
        ],
      ),
    );
  }
}

IconData _channelIcon(String key) => switch (key) {
  'phone' => Icons.call_outlined,
  'email' => Icons.mail_outline_rounded,
  'visit' => Icons.apartment_outlined,
  _ => Icons.info_outline_rounded,
};

/// A phone channel dials, an email channel opens the mail app; a place to
/// visit is only read.
VoidCallback? _channelAction(SupportChannel c) {
  final Uri? uri = switch (c.key) {
    'phone' => dialUri(c.value),
    'email' => Uri(scheme: 'mailto', path: c.value),
    _ => null,
  };
  return uri == null ? null : () => launchUrl(uri);
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _ContactRow({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.slate400),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppTextSize.helper,
                fontWeight: FontWeight.w600,
                color: onTap != null ? AppColors.brand600 : AppColors.slate700,
              ),
            ),
          ),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

