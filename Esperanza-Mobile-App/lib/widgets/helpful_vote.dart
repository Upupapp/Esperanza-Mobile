import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_dialogs.dart';

/// "Was this helpful?" under a help article (parity with the website's Help,
/// 2026-10-15; POST /citizen/help/feedback). The answer can be changed; the
/// server keeps the latest one.
class HelpfulVote extends StatefulWidget {
  const HelpfulVote({super.key, required this.docKey, required this.item});

  final String docKey;
  final String item;

  @override
  State<HelpfulVote> createState() => _HelpfulVoteState();
}

class _HelpfulVoteState extends State<HelpfulVote> {
  bool? _vote;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    FeedbackService.helpVote(widget.docKey, widget.item).then((v) {
      if (mounted && v != null) setState(() => _vote = v);
    });
  }

  Future<void> _send(bool helpful) async {
    if (_sending || _vote == helpful) return;
    final before = _vote;
    setState(() {
      _vote = helpful;
      _sending = true;
    });
    try {
      await FeedbackService.voteHelp(widget.docKey, widget.item, helpful);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _vote = before);
      AppDialogs.toast(context, e.message(), success: false);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _choice(String label, IconData icon, bool value) {
    final picked = _vote == value;
    return TextButton.icon(
      onPressed: _sending ? null : () => _send(value),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, AppSizes.minTouchTarget),
        foregroundColor: picked ? AppColors.brand700 : AppColors.slate600,
        backgroundColor: picked ? AppColors.brand50 : null,
      ),
      icon: Icon(icon, size: AppSizes.iconSm),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.xs,
        children: [
          Text(
            _vote == null ? 'Was this helpful?' : 'Thanks for your feedback.',
            style: AppTypography.helper,
          ),
          Semantics(selected: _vote == true, child: _choice('Yes', Icons.thumb_up_alt_outlined, true)),
          Semantics(selected: _vote == false, child: _choice('No', Icons.thumb_down_alt_outlined, false)),
        ],
      ),
    );
  }
}
