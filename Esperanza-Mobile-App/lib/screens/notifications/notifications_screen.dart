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
import '../../theme/app_typography.dart';
import '../../services/api_client.dart';
import '../../widgets/app_dialogs.dart';
import '../../theme/app_status.dart';
import '../../widgets/status_chip.dart';

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
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await notifService.loadServer();
          } on ApiException catch (e) {
            if (context.mounted) AppDialogs.toast(context, e.message(), success: false);
          }
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          itemCount: items.isEmpty ? 1 : items.length,
          itemBuilder: (context, i) {
            if (items.isEmpty) {
              return const EmptyState(icon: Icons.notifications_none_rounded, title: "You're all caught up");
            }
            final n = items[i];
            return _NotificationTile(notification: n, unread: !notifService.isRead(n.id));
          },
        ),
      ),
    );
  }
}

/// The canonical status a notification names, when it names one the app
/// knows. An unknown label keeps the generic badge rather than guessing
/// (never invent a status: CLAUDE.md).
AppStatus? _statusOf(AppNotification n) {
  final label = n.status;
  if (label == null) return null;
  for (final s in AppStatus.values) {
    if (s.label == label) return s;
  }
  return null;
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool unread;

  const _NotificationTile({required this.notification, required this.unread});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                  decoration: BoxDecoration(
                    color: n.kind.background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
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
                      decoration: BoxDecoration(
                        color: AppColors.rose500,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
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
                          style: TextStyle(
                            fontSize: AppTextSize.helper,
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Icon + text label together (never color alone) so the
                  // notification's severity/type reads clearly even for
                  // colorblind users or in bright outdoor sunlight.
                  if (_statusOf(n) case final status?)
                    StatusChip(status: status, small: true)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: n.kind.background,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(n.kind.badgeIcon, size: 10, color: n.kind.foreground),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            n.kind.badgeLabel,
                            style: TextStyle(
                              fontSize: AppTextSize.fine,
                              fontWeight: FontWeight.w700,
                              color: n.kind.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    n.body,
                    style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.slate500, height: 1.35),
                  ),
                  if (n.time != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      n.time!,
                      style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
                    ),
                  ],
                  if (n.actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    // A separate tap target only when this notification has
                    // a genuinely distinct action destination (see
                    // AppNotification.onAction's own doc comment) — every
                    // other notification keeps this row purely decorative,
                    // exactly as before, since the whole card already goes
                    // to the one place this label describes.
                    GestureDetector(
                      behavior: n.onAction != null ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
                      onTap: n.onAction == null
                          ? null
                          : () {
                              context.read<NotificationsService>().markRead(n.id);
                              n.onAction!();
                            },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            n.actionLabel!,
                            style: TextStyle(
                              fontSize: AppTextSize.label,
                              fontWeight: FontWeight.w700,
                              color: n.kind.foreground,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: n.kind.foreground),
                        ],
                      ),
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
