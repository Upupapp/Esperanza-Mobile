import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_client.dart';
import '../../services/support_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/status_chip.dart';
import 'report_problem_screen.dart';

import '../../l10n/tr.dart';
/// What the office is doing with a ticket, in a line (the website's
/// statusNote).
String ticketStatusNote(String status) => switch (status) {
  'Completed' => 'Resolved by the office',
  'Cancelled' => 'Closed',
  'Under Review' => 'The office is looking into it',
  _ => 'Waiting for the office',
};

/// One support ticket as a conversation with the office (parity with the
/// website's Help > Support, 2026-10-15): the resident's report first, the
/// office's replies, and the resident's answers. A ticket the office closed
/// takes no more replies; a new one can start from it.
class TicketThreadScreen extends StatefulWidget {
  const TicketThreadScreen({super.key, required this.ticket});

  /// The list row; the screen reads the whole conversation itself.
  final SupportTicket ticket;

  @override
  State<TicketThreadScreen> createState() => _TicketThreadScreenState();
}

class _TicketThreadScreenState extends State<TicketThreadScreen> {
  late SupportTicket _ticket = widget.ticket;
  final _reply = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await SupportService.ticket(widget.ticket.ref);
      if (mounted) setState(() => _ticket = t);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending || _ticket.closed) return;
    setState(() => _sending = true);
    try {
      final t = await SupportService.reply(_ticket.ref, text);
      if (!mounted) return;
      _reply.clear();
      setState(() => _ticket = t);
      AppDialogs.toast(context, tr('Reply sent.'));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'TICKET_CLOSED' || e.status == 409) {
        // Closed meanwhile: say so where the reply box was.
        await _load();
      } else {
        AppDialogs.toast(context, e.message(), success: false);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _startNew() {
    final t = _ticket;
    final subject = 'Re: ${t.subject}';
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReportProblemScreen(
          initialSubject: subject.length > 160 ? subject.substring(0, 160) : subject,
          initialCategory: t.category,
          initialRequestRef: t.requestRef,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _ticket;
    final when = DateFormat('MMM d, y · h:mm a');
    return Scaffold(
      appBar: AppBar(title: Text(t.ref)),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(t.subject, style: AppTypography.cardHeading)),
                      const SizedBox(width: AppSpacing.sm),
                      StatusChip(status: AppStatusX.fromLabel(t.status), small: true),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    [t.category, ?t.office, ticketStatusNote(t.status)].join(' · '),
                    style: AppTypography.helper,
                  ),
                  if (t.requestRef != null) Text('Request: ${t.requestRef}', style: AppTypography.fine),
                  if (t.attachmentName != null) Text('Attached: ${t.attachmentName}', style: AppTypography.fine),
                  const SizedBox(height: AppSpacing.lg),
                  if (_error != null && !_loading) ...[
                    Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(label: tr('Try again'), variant: AppButtonVariant.secondary, onPressed: _load),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  for (final m in t.conversation)
                    _Bubble(message: m, when: m.at == null ? null : when.format(m.at!.toLocal())),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.slate200)),
              ),
              child: t.closed
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'The office closed this ticket, so it takes no more replies. '
                          'Open a new one if you still need help.',
                          style: AppTypography.helper,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton(
                          label: tr('Open a new ticket'),
                          variant: AppButtonVariant.secondary,
                          fullWidth: true,
                          onPressed: _startNew,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _reply,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 4000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Write a reply to the office',
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filled(
                          tooltip: tr('Send reply'),
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.brand600,
                            minimumSize: const Size.square(AppSizes.minTouchTarget),
                          ),
                          icon: _sending
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface),
                                )
                              : const Icon(Icons.send_rounded, color: AppColors.surface),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.when});

  final TicketMessage message;
  final String? when;

  @override
  Widget build(BuildContext context) {
    final mine = !message.fromStaff;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: mine ? AppColors.brand50 : AppColors.surface,
            border: Border.all(color: mine ? AppColors.brand100 : AppColors.slate200),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [message.name, ?when].join(' · '),
                style: AppTypography.fine.copyWith(fontWeight: FontWeight.w600, color: AppColors.slate600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(message.body, style: AppTypography.bodyText.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
