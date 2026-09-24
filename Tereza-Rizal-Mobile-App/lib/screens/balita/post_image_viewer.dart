import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/balita_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/balita_post_actions.dart';
import '../../widgets/balita_share_sheet.dart';
import 'post_card.dart';

/// A lightweight full-screen overlay for a single Balita post's image —
/// opened by tapping the image in [PostCard], not a separate post-detail
/// page. Reads the post by [postId] live from [BalitaService] (rather than
/// taking a snapshot [Announcement]) so like/comment/share state is always
/// the exact same state the feed shows: liking here updates the same
/// ChangeNotifier the feed listens to, so there is nothing to keep in sync
/// by hand, and closing this viewer returns to the feed at whatever scroll
/// position it was already at (this is a push on top of it, not a replace).
class PostImageViewer extends StatelessWidget {
  final String postId;
  const PostImageViewer({super.key, required this.postId});

  static void open(BuildContext context, String postId) {
    // Counted here — the one place a citizen actually opens a post, not
    // merely scrolls past it in the feed. See BalitaService.recordView's
    // own doc comment for why this has no per-session dedup.
    context.read<BalitaService>().recordView(postId);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => PostImageViewer(postId: postId)));
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaService>();
    Announcement? post;
    for (final p in balita.posts) {
      if (p.id == postId) {
        post = p;
        break;
      }
    }

    // The post could in principle disappear from under the viewer (e.g.
    // Web Admin content sync); bail out to the feed rather than show a
    // broken screen.
    if (post == null || post.media == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox.shrink());
    }

    final isOfficial = post.isOfficial;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // BoxFit.contain (never cover/fill) inside a *definite*
                  // height (not just a max-height cap) — preserves the
                  // image's real aspect ratio with no stretching or
                  // cropping, letterboxing a very tall image smaller rather
                  // than distorting it. A max-height-only cap left
                  // RenderImage free to report zero height for the one
                  // frame before its asset finishes decoding (Flutter falls
                  // back to `constraints.smallest` until then), which
                  // collapsed this whole Stack — including the close
                  // button positioned over it — to nothing, making the
                  // viewer briefly untappable right after opening. A fixed
                  // height keeps this Stack's size (and the close button
                  // sitting on top of it) stable regardless of decode
                  // timing.
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.52,
                    color: Colors.black,
                    child: PostMediaView(media: post.media!, fit: BoxFit.contain),
                  ),
                  Positioned(top: 10, right: 12, child: _CloseButton(onTap: () => Navigator.of(context).pop())),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
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
                  ],
                ),
              ),
              if (post.body.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Text(
                    post.body,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.slate700, height: 1.45),
                  ),
                ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: BalitaEngagementRow(post: post),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PostActionButton(
                            icon: post.liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            label: 'Like',
                            color: post.liked ? AppColors.rose500 : AppColors.slate500,
                            onTap: () => requireAccountForBalita(
                              context,
                              'Reacting to Balita posts',
                              () => balita.toggleLike(post!.id),
                            ),
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
                              () => openBalitaComments(context, post!, (c) => balita.addComment(post!.id, c)),
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
                              () => BalitaShareSheet.show(context, post!, () => balita.share(post!.id)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(9),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
