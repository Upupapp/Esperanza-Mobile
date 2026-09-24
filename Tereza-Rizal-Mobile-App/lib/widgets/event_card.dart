import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../screens/shared/event_poster_viewer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// One event as its own independent card — used on both Home's "Upcoming
/// Events" preview ([compact]) and the dedicated Events list. Never
/// stacks multiple events into one shared container: each [EventCard]
/// renders exactly one [EventItem].
///
/// The poster (when present) is shown with `BoxFit.contain` inside a
/// full-width box — never `BoxFit.cover` — so dates/times/team names
/// printed on the poster are never cropped off; any letterboxing just
/// shows a neutral background rather than losing content. Tapping opens
/// the full poster in [EventPosterViewer] for a pinch-to-zoom close look.
class EventCard extends StatelessWidget {
  final EventItem event;
  final bool compact;

  const EventCard({super.key, required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: event.imagePath != null ? () => EventPosterViewer.open(context, event) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imagePath != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  color: AppColors.slate100,
                  constraints: BoxConstraints(maxHeight: compact ? 220 : 420),
                  width: double.infinity,
                  // Decode at the card's actual bounded width rather than
                  // the source poster's full resolution — BoxFit.contain
                  // never crops, so scaling decode to width alone (letting
                  // height follow proportionally) can't distort or crop it.
                  child: LayoutBuilder(
                    builder: (context, constraints) => Image.asset(
                      event.imagePath!,
                      fit: BoxFit.contain,
                      cacheWidth: constraints.hasBoundedWidth
                          ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()
                          : null,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (event.category != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            event.category!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _MetaRow(icon: Icons.calendar_today_rounded, text: event.date),
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(icon: Icons.schedule_rounded, text: event.time),
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(icon: Icons.place_outlined, text: event.venue),
                  if (event.imagePath != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        // Flexible: a Row with no flex child sizes to its
                        // content's unconstrained width — the same
                        // overflow pattern fixed repeatedly elsewhere in
                        // this app (StatusChip, post_card's action row,
                        // etc.) at narrow widths / large text scales.
                        Flexible(
                          child: Text(
                            'View full poster',
                            textWidthBasis: TextWidthBasis.longestLine,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brand600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(Icons.open_in_full_rounded, size: 12, color: AppColors.brand600),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.slate400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.3)),
        ),
      ],
    );
  }
}
