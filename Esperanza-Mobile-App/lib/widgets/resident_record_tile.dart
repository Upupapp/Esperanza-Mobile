import 'package:flutter/material.dart';

import '../models/resident_record.dart';
import '../models/service_request.dart';
import '../screens/shared/request_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_text.dart';
import '../utils/peso_text.dart';
import 'app_card.dart';
import 'esperanza_art.dart';
import 'status_chip.dart';

/// One Dokyu or Tulong on the resident's record (GET /citizen/records,
/// 2026-10-13): what an office recorded for them, or what they filed. A
/// filed one opens as any of their requests does; an office's record opens a
/// read-only sheet - it has no detail endpoint and nothing to act on.
class ResidentRecordTile extends StatelessWidget {
  const ResidentRecordTile({super.key, required this.record});

  final ResidentRecord record;

  /// Tulong · Aug 14, 2025 · ₱3,000.00 · TUL-2025-00071
  /// A zero amount (a free document) is left out, as on the web portal.
  static String line(ResidentRecord r) => [
    r.category == ServiceCategory.tulong ? 'Tulong' : 'Dokyu',
    if (r.date != null) shortDate(r.date!),
    if ((r.amountValue ?? 0) > 0) ?pesoText(r.amount),
    r.ref,
  ].join(' · ');

  void _open(BuildContext context) {
    if (!record.fromOffice) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: record.ref)));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // As tall as it needs, scrolling on a short screen: the default sheet
      // cut off the last rows on a small phone.
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RecordSheet(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = record;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        onTap: () => _open(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RequestClayIcon(r.category),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.service,
                    style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.navy900),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(line(r), style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
                  if (r.purpose != null)
                    Text('For: ${r.purpose}', style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    r.source,
                    style: TextStyle(
                      fontSize: AppTextSize.fine,
                      fontWeight: FontWeight.w600,
                      color: r.fromOffice ? AppColors.brand700 : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.32),
              child: StatusChip.request(r.status, small: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// An office's record, all of it: nothing here to change or send.
class _RecordSheet extends StatelessWidget {
  const _RecordSheet({required this.record});

  final ResidentRecord record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final rows = <(String, String)>[
      ('Status', r.status),
      if (r.date != null) ('Date', shortDate(r.date!)),
      if ((r.amountValue ?? 0) > 0)
        (r.category == ServiceCategory.tulong ? 'Amount' : 'Fee paid', pesoText(r.amount)!)
      // The office's logbook said the document was free (live test 2026-10-13: "₱0.00").
      else if (r.category == ServiceCategory.dokyu && r.amountValue == 0)
        ('Fee paid', 'Free'),
      if (r.purpose != null) ('For', r.purpose!),
      ('Reference', r.ref),
      if (r.reference != null) ("Office's number", r.reference!),
      ('Recorded by', r.office ?? 'The office'),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.service,
              style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.navy900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              r.category == ServiceCategory.tulong ? 'Tulong, from the office\'s records' : 'Dokyu, from the office\'s records',
              style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 116,
                      child: Text(label, style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: AppColors.textBody),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'The office recorded this for you before you had an account, or at its counter. It is here for you to see.',
              style: TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
