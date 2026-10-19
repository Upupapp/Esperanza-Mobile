import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/balita_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/async_state_view.dart';
import 'post_card.dart';

/// One Balita announcement, opened from its "New in Balita" notification
/// (Esperanza QA, 2026-10-07), or one of the resident's own community posts,
/// opened from a notification about it ("Your Balita post is live / was
/// hidden", 2026-10-18). The same [PostCard] the feed shows, so likes,
/// comments and sharing work here too; the post comes from the loaded feed
/// when it is there, or from GET /announcements/{id} when it is older.
class BalitaPostScreen extends StatelessWidget {
  final int? announcementId;
  final int? communityPostId;
  const BalitaPostScreen({super.key, this.announcementId, this.communityPostId})
      : assert(announcementId != null || communityPostId != null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balita')),
      body: AsyncStateView<Announcement>(
        loader: () => announcementId != null
            ? context.read<BalitaService>().loadAnnouncement(announcementId!)
            : context.read<BalitaService>().loadCommunityPost(communityPostId!),
        builder: (context, loaded, reload) {
          // The feed's own copy, so a like here shows in the feed and back.
          final kind = announcementId != null ? PostKind.announcement : PostKind.community;
          final id = announcementId ?? communityPostId;
          final posts = context.watch<BalitaService>().posts;
          final post = posts.firstWhere(
            (p) => p.kind == kind && p.remoteId == id,
            orElse: () => loaded,
          );
          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [PostCard(post: post)],
            ),
          );
        },
      ),
    );
  }
}
