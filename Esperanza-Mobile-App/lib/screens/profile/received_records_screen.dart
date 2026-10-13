import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/peso_text.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/resident_record_tile.dart';

/// "Dokyu & Tulong Received" (2026-10-13): every document and assistance on
/// the resident's record - what the offices recorded for them and what they
/// filed - with the assistance received in all. The resident's side of the
/// staff profile's card, as the web portal's My Profile has it.
class ReceivedRecordsScreen extends StatelessWidget {
  const ReceivedRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.read<RequestsService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Dokyu & Tulong Received')),
      body: AsyncStateView<void>(
        // Their own requests too, so one they filed opens straight away.
        loader: () => Future.wait([service.loadRecords(), service.loadRequests()]),
        builder: (context, _, reload) {
          final requests = context.watch<RequestsService>();
          final records = requests.records;
          final total = requests.assistanceReceived;
          return RefreshIndicator(
            onRefresh: () => Future.wait([requests.loadRecords(), requests.loadRequests()]),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
              children: [
                const Text(
                  'The documents and assistance on your record: what the offices recorded for you, and what you filed.',
                  style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (requests.recordsPending)
                  const EmptyState(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Waiting for your barangay',
                    description: 'They appear here once your barangay confirms the record is yours.',
                  )
                else if (requests.recordsFailed)
                  EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load them',
                    description: 'Check your connection, then pull down to try again.',
                    action: OutlinedButton(onPressed: reload, child: const Text('Try Again')),
                  )
                else if (records.isEmpty)
                  const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nothing on your record yet',
                    description: 'Documents and assistance you receive will be listed here.',
                  )
                else ...[
                  for (final r in records) ResidentRecordTile(record: r),
                  if (total > 0) ...[
                    const Divider(height: AppSpacing.xl),
                    Text(
                      'Assistance received in all: ${pesoText(total)}',
                      style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.navy900),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
