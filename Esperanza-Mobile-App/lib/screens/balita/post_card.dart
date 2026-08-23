import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/balita_post_actions.dart';
import '../../utils/cross_platform_image.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_card.dart';
import '../../widgets/balita_share_sheet.dart';
import 'comments_sheet.dart';
import 'post_image_viewer.dart';

/// A single Balita feed post — header (avatar/author/verified badge/
/// barangay/timestamp/overflow menu), body text, optional image, an
/// engagement summary row, and a Like / Comment / Share action row. All
/// interactions are local-state simulations driven by the callbacks passed
/// in from BalitaScreen — there is no backend for the social feed.
///
/// Tapping the image opens [PostImageViewer] by `post.id` only (not a
/// snapshot of this [post]) so the viewer always reads the *live* post
/// straight from BalitaService — the same single source of truth this
/// card itself is built from — which is what keeps like/comment/share
/// state trivially synchronized between the feed and the viewer without
/// any manual prop-passing back and forth.
class PostCard extends StatelessWidget {
  final Announcement post;
  final VoidCallback onLike;
  final ValueChanged<PostComment> onComment;
  final VoidCallback onShare;

  const PostCard({super.key, required this.post, required this.onLike, required this.onComment, required this.onShare});

  @override
  Widget build(BuildContext context) {
    final isOfficial = post.isOfficial;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: isOfficial ? AppColors.gold50 : AppColors.brand50,
                  child: Text(
                    isOfficial ? 'LGU' : (post.author.isNotEmpty ? post.author.substring(0, 1).toUpperCase() : '?'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isOfficial ? AppColors.gold700 : AppColors.brand600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.author,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOfficial) ...[
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.verified_rounded, size: 14, color: AppColors.brand500),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        post.barangay != null
                            ? 'Brgy. ${post.barangay} · ${post.time}'
                            : (isOfficial ? 'Official account · ${post.time}' : post.time),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showPostMenu(context),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(Icons.more_horiz_rounded, size: 19, color: AppColors.slate400),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (post.body.trim().isNotEmpty)
              Text(post.body, style: const TextStyle(fontSize: 13.5, color: AppColors.slate700, height: 1.45)),
            if (post.media != null) ...[
              if (post.body.trim().isNotEmpty) const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  // Only images open the larger viewer — a video card
                  // (no video_player dependency in this project, per its
                  // own doc comment below) has nothing bigger to show.
                  child: post.media!.type == PostMediaType.image
                      ? InkWell(
                          onTap: () => PostImageViewer.open(context, post.id),
                          child: PostMediaView(media: post.media!),
                        )
                      : PostMediaView(media: post.media!),
                ),
              ),
            ],
            const SizedBox(height: 12),
            BalitaEngagementRow(post: post),
            Row(
              children: [
                Expanded(
                  child: PostActionButton(
                    icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: 'Like',
                    color: post.liked ? AppColors.rose500 : AppColors.slate500,
                    onTap: () => requireAccountForBalita(context, 'Reacting to Balita posts', onLike),
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
                      () => openBalitaComments(context, post, onComment),
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
                      () => BalitaShareSheet.show(context, post, onShare),
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

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bookmark_outline_rounded, color: AppColors.slate600),
                title: const Text('Save post', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  AppDialogs.toast(context, 'Saved (demo).');
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.slate600),
                title: const Text('Report post', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  AppDialogs.toast(context, 'Thanks — this has been flagged for review (demo).', success: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the shared [CommentsSheet] bottom sheet — reused as-is by both
/// [PostCard] and [PostImageViewer] rather than either owning its own
/// comment UI, per the "do not create a separate comment system for the
/// viewer" requirement.
void openBalitaComments(BuildContext context, Announcement post, ValueChanged<PostComment> onSubmit) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(post: post, onSubmit: onSubmit),
  );
}

/// Renders a post's attached [PostMedia] — a seed/bundled asset or a real
/// file the citizen picked, or a video attachment card (no video_player
/// dependency in this project, so a clear "this is a video" preview
/// stands in for actual playback, per the simulation scope for Balita).
/// Public (not `PostCard`-private) so [PostImageViewer] renders the exact
/// same image — including the same cross-platform-safe loading/error
/// handling — at a different [fit] rather than duplicating that logic.
class PostMediaView extends StatelessWidget {
  final PostMedia media;
  final BoxFit fit;
  const PostMediaView({super.key, required this.media, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (media.type == PostMediaType.image) {
      // Some bundled seed images (e.g. the aerial/city-hall shots) are
      // several megapixels — far more than a feed card or the viewer ever
      // displays. LayoutBuilder reads the actual bounded width this
      // instance is being laid out at (feed card vs. the taller viewer
      // each pass a different constraint) so the decoder only produces a
      // bitmap sized for what's really on screen, in either context,
      // without hardcoding either one's size here.
      if (media.isAsset) {
        return LayoutBuilder(
          builder: (context, constraints) => Image.asset(
            media.path,
            fit: fit,
            width: double.infinity,
            cacheWidth: constraints.hasBoundedWidth
                ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()
                : null,
          ),
        );
      }
      // A citizen-picked photo's `path` is only ever safe to read via
      // dart:io on native platforms — see cross_platform_image.dart. No
      // current flow constructs a non-asset PostMedia, but this guards the
      // same crash the attachment picker had if/when post composing ships.
      final provider = pickedFileImageProvider(path: media.path);
      if (provider == null) {
        return Container(
          color: AppColors.slate100,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.slate400, size: 28),
        );
      }
      return Image(
        image: provider,
        fit: fit,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.slate100,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.slate400, size: 28),
        ),
      );
    }
    return Container(
      color: AppColors.navy900,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(
              media.fileName ?? 'Video attached',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// The engagement summary line under a Balita post — reaction count on the
/// left, comment count and share count together on the right (Facebook-
/// style), rather than fixed equal-width columns or a single flowing list.
/// View count is tracked internally (see [BalitaService.recordView]) but is
/// intentionally not rendered here. Public — and the single implementation
/// — so [PostCard] and [PostImageViewer] can never visually drift apart,
/// per the "same engagement summary everywhere" requirement.
class BalitaEngagementRow extends StatelessWidget {
  final Announcement post;
  const BalitaEngagementRow({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final hasEngagement = post.likes > 0 || post.commentCount > 0 || post.shares > 0;
    if (!hasEngagement) return const SizedBox.shrink();

    const style = TextStyle(fontSize: 12, color: AppColors.slate500);

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
                        const SizedBox(width: 6),
                        Text('${post.likes}', style: style.copyWith(fontWeight: FontWeight.w500)),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            if (post.commentCount > 0 || post.shares > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.commentCount > 0)
                    Text('${post.commentCount} comment${post.commentCount == 1 ? '' : 's'}', style: style),
                  if (post.commentCount > 0 && post.shares > 0) const SizedBox(width: 14),
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
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
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
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
