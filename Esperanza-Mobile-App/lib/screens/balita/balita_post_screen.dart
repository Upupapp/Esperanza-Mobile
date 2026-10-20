import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/balita_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/async_state_view.dart';
import 'post_card.dart';

/// One Balita announcement, opened from its "New in Balita" notification
/// (Esperanza QA, 2026-10-07). The same [PostCard] the feed shows, so likes,
/// comments and sharing work here too; the post comes from the loaded feed
/// when it is there, or from GET /announcements/{id} when it is older.
class BalitaPostScreen extends StatelessWidget {
  final int announcementId;
  const BalitaPostScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Balita')),
      body: AsyncStateView<Announcement>(
        loader: () => context.read<BalitaService>().loadAnnouncement(announcementId),
        builder: (context, loaded, reload) {
          // The feed's own copy, so a like here shows in the feed and back.
          final posts = context.watch<BalitaService>().posts;
          final post = posts.firstWhere((p) => p.remoteId == announcementId, orElse: () => loaded);
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
