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
import '../../widgets/balita_share_sheet.dart';
import 'comments_sheet.dart';
import 'post_image_viewer.dart';

/// A single Balita feed post — header (avatar/author/verified badge/
/// barangay/timestamp/overflow menu), body text, optional image, an
/// engagement summary row, and a Like / Comment / Share action row. Real
/// data and real interactions now (production-readiness programme,
/// 2026-09-25) -- see [BalitaService]'s own doc comment.
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
    final isOfficial = post.isOfficial;
    final balita = context.read<BalitaService>();
    final pendingReview = post.mine && post.status == 'Pending Review';

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
                        [
                          if (post.barangay != null) 'Brgy. ${post.barangay}' else if (isOfficial) 'Official account',
                          post.timeLabel,
                          if (pendingReview) 'Pending review — only visible to you',
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: pendingReview ? AppColors.amber700 : AppColors.textMuted,
                          fontWeight: pendingReview ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Report is a real, per-post citizen action now, but only
                // for someone else's community post -- there's no report
                // endpoint for official announcements (nothing to flag
                // about the LGU's own content), and reporting your own
                // post makes no sense either.
                if (post.kind == PostKind.community && !post.mine)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showPostMenu(context, balita),
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
            if (post.imageUrl != null) ...[
              if (post.body.trim().isNotEmpty) const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: InkWell(
                    onTap: () => PostImageViewer.open(context, post.id),
                    child: PostMediaView(imageUrl: post.imageUrl!),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            BalitaEngagementRow(post: post),
            Row(
              children: [
                Expanded(
                  child: PostActionButton(
                    icon: post.likedByMe == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: 'Like',
                    color: post.likedByMe == true ? AppColors.rose500 : AppColors.slate500,
                    onTap: () => requireAccountForBalita(context, 'Reacting to Balita posts', () => _like(context, balita)),
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

  void _showPostMenu(BuildContext context, BalitaService balita) {
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
                leading: const Icon(Icons.flag_outlined, color: AppColors.slate600),
                title: const Text('Report post', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  requireAccountForBalita(context, 'Reporting Balita posts', () => _report(context, balita));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _report(BuildContext context, BalitaService balita) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReportDialog(),
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    try {
      await balita.reportPost(post, reason.trim());
      if (context.mounted) AppDialogs.toast(context, 'Thanks — this has been flagged for review.');
    } on ApiException catch (e) {
      if (context.mounted) AppDialogs.toast(context, e.message(), success: false);
    }
  }
}

class _ReportDialog extends StatefulWidget {
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report this post'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        decoration: const InputDecoration(hintText: 'Why are you reporting this post?'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Submit'),
        ),
      ],
    );
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

/// Renders a post's real, single remote image (GET .../image_url) — never
/// a local asset or video: the real schema attaches at most one image per
/// post (confirmed against the backend directly), unlike MockCatalog's own
/// seed posts, which included bundled local assets and a video-attachment
/// card for a feature the backend never had. Public (not `PostCard`-
/// private) so [PostImageViewer] renders the exact same image — including
/// the same loading/error handling — at a different [fit] rather than
/// duplicating that logic.
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
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
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
            if (post.commentsCount > 0 || post.shares > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.commentsCount > 0)
                    Text('${post.commentsCount} comment${post.commentsCount == 1 ? '' : 's'}', style: style),
                  if (post.commentsCount > 0 && post.shares > 0) const SizedBox(width: 14),
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
