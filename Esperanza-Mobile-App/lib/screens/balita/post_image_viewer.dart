import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../models/balita_media.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../widgets/app_dialogs.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/balita_post_actions.dart';
import '../../widgets/balita_share_sheet.dart';
import '../../widgets/balita_video_player.dart';
import 'post_card.dart';
import '../../theme/app_typography.dart';

import '../../l10n/tr.dart';
/// A lightweight full-screen overlay for a single Balita post's photos and
/// videos (2026-10-18: up to ten, swiped through, a video playing in place) —
/// opened by tapping the image in [PostCard], not a separate post-detail
/// page. Reads the post by [postId] live from [BalitaService] (rather than
/// taking a snapshot [Announcement]) so like/comment state is always the
/// exact same state the feed shows: liking here updates the same
/// ChangeNotifier the feed listens to, so there is nothing to keep in sync
/// by hand, and closing this viewer returns to the feed at whatever scroll
/// position it was already at (this is a push on top of it, not a replace).
class PostImageViewer extends StatefulWidget {
  final String postId;

  /// The photo or video tapped in the card.
  final int initialIndex;
  const PostImageViewer({super.key, required this.postId, this.initialIndex = 0});

  static void open(BuildContext context, String postId, {int initialIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PostImageViewer(postId: postId, initialIndex: initialIndex),
      ),
    );
  }

  @override
  State<PostImageViewer> createState() => _PostImageViewerState();
}

class _PostImageViewerState extends State<PostImageViewer> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.postId;
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
    if (post == null || post.media.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: Colors.black, body: SizedBox.shrink());
    }

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
                    color: AppColors.mediaBackdrop,
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: post.media.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) => _MediaPage(media: post!.media[i], active: i == _index),
                    ),
                  ),
                  Positioned(top: 10, right: 12, child: _CloseButton(onTap: () => Navigator.of(context).pop())),
                  if (post.media.length > 1)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.mediaScrim,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '${_index + 1} / ${post.media.length}',
                          style: const TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w600, color: AppColors.onMedia),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
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
                            post.barangay != null
                                ? 'Brgy. ${post.barangay} · ${post.timeLabel}'
                                : 'Official account · ${post.timeLabel}',
                            style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (post.body.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Text(
                    post.body,
                    style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate700, height: 1.45),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: BalitaEngagementRow(post: post),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: PostActionButton(
                        icon: post.likedByMe == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        label: tr('Like'),
                        color: post.likedByMe == true ? AppColors.rose500 : AppColors.slate500,
                        onTap: () => requireAccountForBalita(
                          context,
                          'Reacting to Balita posts',
                          () => _like(context, balita, post!),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PostActionButton(
                        icon: Icons.mode_comment_outlined,
                        label: tr('Comment'),
                        color: AppColors.slate500,
                        onTap: () => requireAccountForBalita(
                          context,
                          'Commenting on Balita posts',
                          () => openBalitaComments(context, post!),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PostActionButton(
                        icon: Icons.share_outlined,
                        label: tr('Share'),
                        color: AppColors.slate500,
                        onTap: () => BalitaShareSheet.show(context, post!),
                      ),
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

/// One photo (pinch to zoom) or video (playing while it is the page shown).
class _MediaPage extends StatelessWidget {
  final BalitaMedia media;
  final bool active;
  const _MediaPage({required this.media, required this.active});

  @override
  Widget build(BuildContext context) {
    final url = media.url;
    if (url == null) {
      return Center(
        child: Text(tr('Being checked'), style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.onMediaMuted)),
      );
    }
    if (media.isVideo) {
      return Semantics(
        label: 'Video${media.durationLabel != null ? ', ${media.durationLabel}' : ''}',
        child: BalitaVideoPlayer(url: url, posterUrl: media.posterUrl, active: active),
      );
    }
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: PostMediaView(imageUrl: url, fit: BoxFit.contain),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.mediaScrim,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Icon(Icons.close_rounded, color: AppColors.onMedia, size: 22),
        ),
      ),
    );
  }
}

/// Same as the feed card's like: a failure is a message, not an unhandled
/// error (this used to call toggleLike bare).
Future<void> _like(BuildContext context, BalitaService balita, Announcement post) async {
  try {
    await balita.toggleLike(post);
  } on ApiException catch (e) {
    if (context.mounted) AppDialogs.toast(context, e.message(), success: false);
  }
}
