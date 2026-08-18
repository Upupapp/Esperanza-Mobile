import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../models/notification_kind.dart';
import '../../services/notification_feed.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';

/// See notification_feed.dart for how the feed itself is assembled — this
/// screen only renders it plus each tile's read/unread state (tracked by
/// [NotificationsService]).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = buildNotificationFeed(context);
    final notifService = context.watch<NotificationsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: "You're all caught up")
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [for (final n in items) _NotificationTile(notification: n, unread: !notifService.isRead(n.id))],
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool unread;

  const _NotificationTile({required this.notification, required this.unread});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () {
          context.read<NotificationsService>().markRead(n.id);
          n.onTap?.call();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: n.kind.background, borderRadius: BorderRadius.circular(10)),
                  child: Icon(n.icon, size: 17, color: n.kind.foreground),
                ),
                // Small, subtle unread marker — not a numeric badge, since
                // this app has no unread-count system beyond "read or not".
                if (unread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: AppColors.rose500, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(fontSize: 13, fontWeight: unread ? FontWeight.w700 : FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Icon + text label together (never color alone) so the
                  // notification's severity/type reads clearly even for
                  // colorblind users or in bright outdoor sunlight.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: n.kind.background, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(n.kind.badgeIcon, size: 10, color: n.kind.foreground),
                        const SizedBox(width: 3),
                        Text(n.kind.badgeLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: n.kind.foreground)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(n.body, style: const TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.35)),
                  if (n.time != null) ...[
                    const SizedBox(height: 4),
                    Text(n.time!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                  if (n.actionLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(n.actionLabel!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: n.kind.foreground)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: n.kind.foreground),
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
