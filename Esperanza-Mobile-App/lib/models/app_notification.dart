import 'package:flutter/material.dart';
import 'notification_kind.dart';

/// One entry in the derived notification feed (see notification_feed.dart)
/// — carries a stable [id] so [NotificationsService] can track read/unread
/// state for something that's otherwise recomputed fresh on every build,
/// never stored as its own persisted object.
class AppNotification {
  final String id;
  final NotificationKind kind;
  final IconData icon;
  final String title;
  final String body;
  final String? time;
  final VoidCallback? onTap;
  final String? actionLabel;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.body,
    this.time,
    this.onTap,
    this.actionLabel,
  });
}
