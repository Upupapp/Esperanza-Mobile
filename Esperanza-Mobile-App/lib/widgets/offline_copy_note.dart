import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/date_text.dart';

/// Says that what is on screen is the phone's saved copy, from when, because
/// the server cannot be reached - no signal, or the server is down (scope
/// round 2026-10-15, "offline copy").
class OfflineCopyNote extends StatelessWidget {
  const OfflineCopyNote({super.key, required this.savedAt});

  final DateTime savedAt;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.amber700),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Esperanza cannot be reached right now, so this is your list as saved on ${dateAndTime(savedAt)}. '
                'Pull down to try again.',
                style: AppTypography.captionSmallRegular.copyWith(color: AppColors.amber700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
