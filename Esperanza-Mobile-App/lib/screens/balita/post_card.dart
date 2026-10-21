import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/balita_post_actions.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_card.dart';
import '../../widgets/balita_media_gallery.dart';
import '../../widgets/balita_share_sheet.dart';
import 'comments_sheet.dart';
import 'post_image_viewer.dart';
import '../../theme/app_typography.dart';

/// A single Balita feed post — header (avatar/author/verified badge/
/// barangay/timestamp), body text, optional image, an engagement summary
/// row, and a Like / Comment / Share action row. Real data and real
/// interactions now (production-readiness programme, 2026-09-25) -- see
/// [BalitaService]'s own doc comment. Every post is the LGU's own (owner,
/// 2026-10-20), so there is nothing to report or delete here.
///
/// Tapping the image opens [PostImageViewer] by `post.id` only (not a
/// snapshot of this [post]) so the viewer always reads the *live* post
/// straight from BalitaService — the same single source of truth this
/// card itself is built from — which is what keeps like/comment state
/// trivially synchronized between the feed and the viewer without any
/// manual prop-passing back and forth.
class PostCard extends StatelessWidget {
  final Announcement post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final balita = context.read<BalitaService>();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      // Frosted white: a post is read at length, and the standard glass let
      // the coloured backdrop wash through the text.
      child: AppCard(
        frosted: true,
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.gold50,
                  child: Text(
                    'LGU',
                    style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: AppColors.gold700),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.author,
                              style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.brand500),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          post.barangay != null ? 'Brgy. ${post.barangay}' : 'Official account',
                          post.timeLabel,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_headline(post) case final headline?) ...[
              Text(headline, style: AppTypography.cardHeading),
              if (_bodyAfterHeadline(post).isNotEmpty) const SizedBox(height: AppSpacing.xs),
            ],
            if (_bodyAfterHeadline(post).isNotEmpty)
              Text(
                _bodyAfterHeadline(post),
                style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate700, height: 1.45),
              ),
            if (post.media.isNotEmpty) ...[
              if (post.body.trim().isNotEmpty) const SizedBox(height: AppSpacing.md),
              BalitaMediaGallery(
                media: post.media,
                onOpen: (i) => PostImageViewer.open(context, post.id, initialIndex: i),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            BalitaEngagementRow(post: post),
            Row(
              children: [
                Expanded(
                  child: PostActionButton(
                    icon: post.likedByMe == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: 'Like',
                    color: post.likedByMe == true ? AppColors.rose500 : AppColors.slate500,
                    onTap: () =>
                        requireAccountForBalita(context, 'Reacting to Balita posts', () => _like(context, balita)),
                  ),
                ),
                Expanded(
                  child: PostActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: 'Comment',
                    color: AppColors.slate500,
                    onTap: () => requireAccountForBalita(
                      context,
                      'Commenting on Balita posts',
                      () => openBalitaComments(context, post),
                    ),
                  ),
                ),
                Expanded(
                  child: PostActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: AppColors.slate500,
                    onTap: () => requireAccountForBalita(
                      context,
                      'Sharing Balita posts',
                      () => BalitaShareSheet.show(context, post),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _like(BuildContext context, BalitaService balita) async {
    try {
      await balita.toggleLike(post);
    } on ApiException catch (e) {
      if (context.mounted) AppDialogs.toast(context, e.message(), success: false);
    }
  }
}

/// Opens the shared [CommentsSheet] bottom sheet — reused as-is by both
/// [PostCard] and [PostImageViewer] rather than either owning its own
/// comment UI, per the "do not create a separate comment system for the
/// viewer" requirement.
void openBalitaComments(BuildContext context, Announcement post) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(post: post),
  );
}

/// Renders one remote photo of a post, with its loading and error states.
/// Public so [PostImageViewer] renders the exact same image at a different
/// [fit] rather than duplicating that logic. (A post's photos and videos are
/// laid out by [BalitaMediaGallery], 2026-10-18.)
class PostMediaView extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  const PostMediaView({super.key, required this.imageUrl, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.slate100,
          alignment: Alignment.center,
          child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.slate100,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.slate400, size: 28),
      ),
    );
  }
}

/// The engagement summary line under a Balita post — reaction count on the
/// left, comment count and share count together on the right (Facebook-
/// style), rather than fixed equal-width columns or a single flowing list.
/// Public — and the single implementation — so [PostCard] and
/// [PostImageViewer] can never visually drift apart, per the "same
/// engagement summary everywhere" requirement.
class BalitaEngagementRow extends StatelessWidget {
  final Announcement post;
  const BalitaEngagementRow({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final hasEngagement = post.likes > 0 || post.commentsCount > 0 || post.shares > 0;
    if (!hasEngagement) return const SizedBox.shrink();

    const style = TextStyle(fontSize: AppTextSize.label, color: AppColors.slate500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: post.likes > 0
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.rose500, shape: BoxShape.circle),
                          child: const Icon(Icons.favorite_rounded, size: 11, color: Colors.white),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${post.likes}', style: style.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            if (post.commentsCount > 0 || post.shares > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.commentsCount > 0)
                    Text('${post.commentsCount} comment${post.commentsCount == 1 ? '' : 's'}', style: style),
                  if (post.commentsCount > 0 && post.shares > 0) const SizedBox(width: AppSpacing.md),
                  if (post.shares > 0) Text('${post.shares} share${post.shares == 1 ? '' : 's'}', style: style),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
      ],
    );
  }
}

/// One Like/Comment/Share action — public so [PostImageViewer] renders
/// the identical row instead of a second, visually-different engagement
/// design.
class PostActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const PostActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.xs),
              // Flexible: a Row with no flex child sizes to the natural
              // (unconstrained) width of its content — Like/Comment/Share
              // sit in three equal Expanded thirds of the card width, and
              // at some combinations of card width + text-scale the label
              // alone needs more than its third. Same fix as
              // SectionStatusChip/StatusChip elsewhere in this app.
              Flexible(
                child: Text(
                  label,
                  textWidthBasis: TextWidthBasis.longestLine,
                  style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An announcement's headline, when it has one and the body leads with it.
String? _headline(Announcement post) {
  final title = post.title;
  return title != null && post.body.startsWith(title) ? title : null;
}

/// The body without the headline [_headline] already drew.
String _bodyAfterHeadline(Announcement post) {
  final headline = _headline(post);
  final body = headline == null ? post.body : post.body.substring(headline.length);
  return body.trim();
}
