import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/announcement.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_card.dart';
import '../../widgets/restricted_feature_notice.dart';
import 'comments_sheet.dart';

/// A single Balita feed post — header (avatar/author/verified badge/
/// barangay/timestamp/overflow menu), body text, optional image, an
/// engagement summary row, and a Like / Comment / Share action row. All
/// interactions are local-state simulations driven by the callbacks passed
/// in from BalitaScreen — there is no backend for the social feed.
class PostCard extends StatelessWidget {
  final Announcement post;
  final VoidCallback onLike;
  final ValueChanged<PostComment> onComment;
  final VoidCallback onShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isOfficial = post.isOfficial;
    final hasEngagement = post.likes > 0 || post.commentCount > 0 || post.shares > 0;

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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOfficial ? AppColors.gold700 : AppColors.brand600),
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
                            const SizedBox(width: 4),
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
                    padding: EdgeInsets.all(8),
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
                  child: _PostMediaView(media: post.media!),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (hasEngagement) ...[
              Row(
                children: [
                  if (post.likes > 0) ...[
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.rose500, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_rounded, size: 11, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('${post.likes}', style: const TextStyle(fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500)),
                  ],
                  const Spacer(),
                  // Flexible: a Spacer only shrinks itself to make room, it
                  // doesn't shrink its fixed siblings — a like count on the
                  // left plus "N comments · N shares" on the right can still
                  // together exceed the card width at some text scales.
                  // Combining into one Text + Flexible + ellipsis lets it
                  // wrap/truncate instead of overflowing.
                  if (post.commentCount > 0 || post.shares > 0)
                    Flexible(
                      child: Text(
                        [
                          if (post.commentCount > 0) '${post.commentCount} comment${post.commentCount == 1 ? '' : 's'}',
                          if (post.shares > 0) '${post.shares} share${post.shares == 1 ? '' : 's'}',
                        ].join('  ·  '),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
            ],
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: 'Like',
                    color: post.liked ? AppColors.rose500 : AppColors.slate500,
                    onTap: () => _requireAccount(context, 'Reacting to Balita posts', onLike),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: 'Comment',
                    color: AppColors.slate500,
                    onTap: () => _requireAccount(context, 'Commenting on Balita posts', () => _openComments(context)),
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    color: AppColors.slate500,
                    // Sharing stays open to everyone, including Guests —
                    // it's re-distributing public content, not a personal
                    // interaction. Uses the OS's native share sheet
                    // (share_plus) rather than a fake "shared to your
                    // timeline" simulation; no link is included since
                    // there is no real backend URL for a post to expose.
                    onTap: () => _sharePost(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Reacting/commenting are account actions — a Guest gets the same
  /// reusable "create an account or sign in" notice any other protected
  /// interaction shows, rather than an action that silently no-ops.
  void _requireAccount(BuildContext context, String featureName, VoidCallback action) {
    if (context.read<CitizenSessionService>().isGuest) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RestrictedFeatureNotice(reason: RestrictionReason.guestOnly, featureName: featureName)),
      );
      return;
    }
    action();
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(post: post, onSubmit: onComment),
    );
  }

  Future<void> _sharePost(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final who = post.isOfficial ? 'Esperanza LGU' : post.author;
    final excerpt = post.body.trim();
    final text = [
      '$who — Balita, Esperanza',
      if (excerpt.isNotEmpty) excerpt,
    ].join('\n\n');
    await SharePlus.instance.share(ShareParams(text: text, subject: 'Balita: $who', sharePositionOrigin: origin));
    onShare();
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 8),
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

/// Renders a post's attached [PostMedia] — a seed/bundled asset or a real
/// image the citizen picked, or a video attachment card (no video_player
/// dependency in this project, so a clear "this is a video" preview
/// stands in for actual playback, per the simulation scope for Balita).
class _PostMediaView extends StatelessWidget {
  final PostMedia media;
  const _PostMediaView({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.type == PostMediaType.image) {
      return media.isAsset
          ? Image.asset(media.path, fit: BoxFit.cover, width: double.infinity)
          : Image.file(File(media.path), fit: BoxFit.cover, width: double.infinity);
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
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
