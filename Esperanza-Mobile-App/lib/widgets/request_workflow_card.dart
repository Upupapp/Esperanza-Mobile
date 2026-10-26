import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/request_workflow.dart';
import '../services/api_client.dart';
import '../services/json_read.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_text.dart';
import '../utils/phone_dial.dart';
import 'app_card.dart';

import '../l10n/tr.dart';
/// "Steps of your request", as the website shows it: each step of the
/// service's process with who is responsible and the working days, done
/// ones ticked, the current one highlighted.
class RequestWorkflowCard extends StatelessWidget {
  const RequestWorkflowCard({super.key, required this.workflow, required this.accent});

  final RequestWorkflow workflow;
  final Color accent;

  String get _summary {
    if (workflow.stopped) return 'This request was stopped; the steps after it will not happen.';
    final current = workflow.steps.where((s) => s.index == workflow.current).firstOrNull;
    return '${workflow.doneCount} of ${workflow.steps.length} done${current == null ? '' : '. Now: ${current.name}'}';
  }

  String _meta(WorkflowStep s) => [
    ?s.responsible,
    if (s.days != null) '${s.days} ${s.days == '1' ? 'working day' : 'working days'}',
    if (s.done && s.doneAt != null) 'done ${shortDate(s.doneAt!)}',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_outlined, size: AppSizes.iconBase, color: accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(tr('Steps of your request'), style: AppTypography.cardHeading)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(_summary, style: AppTypography.helper),
          const SizedBox(height: AppSpacing.md),
          for (final s in workflow.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Semantics(
                label: '${s.name}, ${s.done ? 'done' : (workflow.current == s.index ? 'current step' : 'not yet')}',
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.done
                            ? AppColors.emerald500
                            : (workflow.current == s.index ? accent : AppColors.slate100),
                      ),
                      child: s.done
                          ? const Icon(Icons.check_rounded, size: 14, color: AppColors.surface)
                          : Text(
                              '${s.index + 1}',
                              style: AppTypography.fine.copyWith(
                                fontWeight: FontWeight.w700,
                                color: workflow.current == s.index ? AppColors.surface : AppColors.slate500,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: AppTypography.bodySmallMedium.copyWith(
                              color: workflow.current == s.index ? accent : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_meta(s).isNotEmpty) Text(_meta(s), style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Where to Claim / Who to Contact", the website's fallback while the
/// server sends no pickup details: a barangay document is claimed at the
/// barangay hall; anything else at the office, with its number from the
/// government directory, or the Municipal Hall trunkline.
class WhereToClaimCard extends StatelessWidget {
  const WhereToClaimCard({super.key, required this.office, required this.barangay});

  final String office;
  final String barangay;

  static const _municipalHall = 'Municipal Hall, Poblacion, Esperanza, Masbate';
  static const _trunkline = 'Municipal Hall Trunkline (056) 333-1000';

  static Future<String?> _officeContact(String office) async {
    final short = office.split('/').first.trim().toLowerCase();
    if (short.isEmpty) return null;
    try {
      final res = await api.get('/directory');
      for (final m in res.list.map(JsonRead.map).whereType<Map<String, dynamic>>()) {
        final name = (JsonRead.nonEmpty(m['office']) ?? JsonRead.nonEmpty(m['name']) ?? '').toLowerCase();
        if (name.isNotEmpty && (name.contains(short) || short.contains(name))) return JsonRead.nonEmpty(m['contact']);
      }
    } on ApiException {
      // The trunkline stands in.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final barangayOffice = RegExp(r'^Barangay (Hall|Office)').hasMatch(office);
    final hall = office.startsWith('Barangay Hall') ? office : 'Barangay Hall (Brgy. $barangay)';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('WHERE TO CLAIM / WHO TO CONTACT'), style: AppTypography.eyebrow.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(office, style: AppTypography.bodySmallMedium.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          _line(Icons.place_outlined, barangayOffice ? '$hall, Esperanza, Masbate' : _municipalHall),
          if (barangayOffice)
            _line(Icons.call_outlined, 'Visit your Barangay Hall')
          else
            FutureBuilder<String?>(
              future: _officeContact(office),
              builder: (context, snap) {
                final contact = snap.data;
                final uri = contact == null ? dialUri('(056) 333-1000') : dialUri(contact);
                return _line(
                  Icons.call_outlined,
                  contact ?? _trunkline,
                  onTap: uri == null ? null : () => launchUrl(uri),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, {VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTypography.helper.copyWith(color: onTap == null ? AppColors.textBody : AppColors.brand600),
            ),
          ),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
