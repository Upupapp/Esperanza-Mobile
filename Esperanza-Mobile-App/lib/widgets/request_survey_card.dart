import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_dialogs.dart';

/// "How was the service?" once a request is released or completed (parity
/// with the website's Track Request, 2026-10-15): a 1-5 rating and an
/// optional comment, asked once. Hidden when this phone already answered or
/// skipped it.
class RequestSurveyCard extends StatefulWidget {
  const RequestSurveyCard({super.key, required this.reference, required this.status});

  final String reference;
  final String status;

  /// The statuses the website asks at.
  static bool dueAt(String status) => status == 'Released' || status == 'Completed';

  @override
  State<RequestSurveyCard> createState() => _RequestSurveyCardState();
}

class _RequestSurveyCardState extends State<RequestSurveyCard> {
  final _comment = TextEditingController();
  bool? _settled;
  int _rating = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    FeedbackService.surveySettled(widget.reference).then((v) {
      if (mounted) setState(() => _settled = v);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating == 0 || _sending) return;
    setState(() => _sending = true);
    try {
      await FeedbackService.rate(widget.reference, _rating, _comment.text);
      if (!mounted) return;
      setState(() => _settled = true);
      AppDialogs.toast(context, 'Thank you for rating the service!');
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _skip() async {
    await FeedbackService.skipSurvey(widget.reference);
    if (mounted) setState(() => _settled = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!RequestSurveyCard.dueAt(widget.status) || _settled != false) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How was the service?', style: AppTypography.cardHeading),
            const SizedBox(height: AppSpacing.xs),
            Text('Rate your experience with this request. We ask only once.', style: AppTypography.helper),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Rating, 1 to 5',
              container: true,
              child: Row(
                children: [
                  for (var n = 1; n <= 5; n++)
                    IconButton(
                      tooltip: '$n – ${FeedbackService.ratingLabels[n]}',
                      isSelected: n <= _rating,
                      onPressed: () => setState(() => _rating = n),
                      style: IconButton.styleFrom(minimumSize: const Size.square(AppSizes.minTouchTarget)),
                      icon: Icon(
                        n <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 30,
                        color: n <= _rating ? AppColors.gold500 : AppColors.slate400,
                      ),
                    ),
                ],
              ),
            ),
            if (_rating > 0)
              Text(FeedbackService.ratingLabels[_rating]!, style: AppTypography.labelText),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _comment,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Comment (optional)', counterText: ''),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Skip',
                    variant: AppButtonVariant.secondary,
                    onPressed: _sending ? null : _skip,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Send rating',
                    loading: _sending,
                    onPressed: _rating == 0 || _sending ? null : _send,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
