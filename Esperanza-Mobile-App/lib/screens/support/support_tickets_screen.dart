import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_client.dart';
import '../../services/support_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_chip.dart';
import 'report_problem_screen.dart';
import 'ticket_thread_screen.dart';

/// The resident's support tickets: what they reported, where it stands and
/// the office's reply. The web portal's Help > Support lists the same
/// tickets; on the phone a ticket could be filed but never seen again.
/// Each opens as a conversation the resident can answer (parity, 2026-10-15).
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  List<SupportTicket>? _tickets;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tickets = await SupportService.myTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.explain());
    }
  }

  Future<void> _report() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportProblemScreen()));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _tickets;
    return Scaffold(
      appBar: AppBar(title: const Text('My Support Tickets')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            if (tickets == null && _error == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (tickets == null) ...[
              Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'Try again', variant: AppButtonVariant.secondary, onPressed: _load),
            ] else if (tickets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text('You have not reported a problem yet.', style: AppTypography.helper),
              )
            else
              for (final t in tickets)
                _TicketCard(
                  ticket: t,
                  onOpen: () async {
                    await Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => TicketThreadScreen(ticket: t)));
                    if (mounted) await _load();
                  },
                ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Report a Problem', icon: Icons.flag_outlined, variant: AppButtonVariant.secondary, fullWidth: true, onPressed: _report),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onOpen;
  const _TicketCard({required this.ticket, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, y');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(ticket.subject, style: AppTypography.cardHeading)),
                const SizedBox(width: AppSpacing.sm),
                StatusChip(status: AppStatusX.fromLabel(ticket.status), small: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [ticket.ref, ticket.category, ?ticket.requestRef, if (ticket.createdAt != null) date.format(ticket.createdAt!.toLocal())].join(' · '),
              style: AppTypography.fine,
            ),
            if (ticket.body.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(ticket.body, style: AppTypography.helper),
            ],
            if (ticket.attachmentName != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Attached: ${ticket.attachmentName}', style: AppTypography.fine),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticketStatusNote(ticket.status),
                    style: AppTypography.labelText.copyWith(color: AppColors.slate600),
                  ),
                ),
                Text(
                  ticket.closed ? 'View conversation' : 'Open conversation',
                  style: AppTypography.labelText.copyWith(color: AppColors.brand600),
                ),
                const Icon(Icons.chevron_right_rounded, size: AppSizes.iconBase, color: AppColors.brand600),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
