import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../models/notification_kind.dart';
import '../../services/citizen_session_service.dart';
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

import '../../l10n/tr.dart';
/// See notification_feed.dart for how the feed itself is assembled — this
/// screen only renders it plus each tile's read/unread state (tracked by
/// [NotificationsService]).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// The website's tabs (notifications.blade.php), in its order.
enum _Tab { all, unread, read, dokyu, tulong }

class _NotificationsScreenState extends State<NotificationsScreen> {
  _Tab _tab = _Tab.all;

  @override
  void initState() {
    super.initState();
    // The shell loads the feed once, when it appears; without this a
    // notification that arrived since then stayed hidden until the citizen
    // thought to pull down. Quiet on failure: what is already here stays.
    if (context.read<CitizenSessionService>().account != null) {
      context.read<NotificationsService>().loadServer().catchError((Object _) {}, test: (e) => e is ApiException);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = buildNotificationFeed(context);
    final notifService = context.watch<NotificationsService>();
    final ids = all.map((n) => n.id);
    final anyUnread = notifService.hasUnread(ids);
    final unread = all.where((n) => !notifService.isRead(n.id)).length;
    final items = [
      for (final n in all)
        if (switch (_tab) {
          _Tab.all => true,
          _Tab.unread => !notifService.isRead(n.id),
          _Tab.read => notifService.isRead(n.id),
          _Tab.dokyu => n.category == 'dokyu',
          _Tab.tulong => n.category == 'tulong',
        })
          n,
    ];
    final tabs = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in _Tab.values) ...[
              ChoiceChip(
                label: Text(switch (t) {
                  _Tab.all => 'All',
                  _Tab.unread => unread > 0 ? 'Unread ($unread)' : 'Unread',
                  _Tab.read => 'Read',
                  _Tab.dokyu => 'Dokyu',
                  _Tab.tulong => 'Tulong',
                }),
                avatar: switch (t) {
                  _Tab.dokyu => const Icon(Icons.description_outlined, size: AppSizes.iconSm),
                  _Tab.tulong => const Icon(Icons.volunteer_activism_outlined, size: AppSizes.iconSm),
                  _ => null,
                },
                selected: _tab == t,
                onSelected: (_) => setState(() => _tab = t),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Notifications')),
        actions: [
          if (anyUnread)
            TextButton(
              onPressed: () => notifService.markAllRead(ids),
              child: Text(tr('Mark all as read')),
            ),
        ],
      ),
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
          itemCount: 1 + (items.isEmpty ? 1 : items.length),
          itemBuilder: (context, i) {
            if (i == 0) return tabs;
            i -= 1;
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.notifications_none_rounded,
                title: all.isEmpty ? "You're all caught up" : 'No notifications here',
              );
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
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        glass: true,
        tint: n.kind.background,
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
                // A clay ball in the notification's tone (2026-10 design).
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: n.kind.clay),
                    boxShadow: [BoxShadow(color: n.kind.clay.last.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  foregroundDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.45, -0.55),
                      radius: 0.7,
                      colors: [AppColors.surface.withValues(alpha: 0.40), AppColors.surface.withValues(alpha: 0)],
                    ),
                  ),
                  child: Icon(n.icon, size: 19, color: n.kind.onClay),
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
