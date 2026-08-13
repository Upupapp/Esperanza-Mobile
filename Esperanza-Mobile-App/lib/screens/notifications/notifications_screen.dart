import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_kind.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../profile/resident_profile/resident_profile_overview_screen.dart';
import '../shared/request_detail_screen.dart';

/// Notifications combine three sources into one feed, each visually
/// distinguished by [NotificationKind] (icon + label, never color alone):
///
/// 1. A profile-completion reminder — derived live from
///    [ResidentProfileService], not a stored notification, so it appears
///    exactly while the signed-in citizen's profile is incomplete and
///    disappears the moment it reaches 100% — never a repeated nag once
///    done, and never shown to a Guest (there's no profile to complete).
/// 2. Real request-status updates — every non-citizen entry in a
///    request's statusHistory, same as before (the "Mobile Reflection"
///    half of the citizen/admin flow model), now styled with the shared
///    NotificationKind system.
/// 3. Sample notifications for types this frontend-only build has no real
///    producer for yet (emergency/evacuation/LGU/Barangay announcements,
///    new assistance availability) — clearly illustrative, not tappable,
///    and never wired to any real state change, per the notifications
///    spec's "do not connect fake sample notifications to production
///    behavior."
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account;
    final requests = context.watch<RequestsService>().all;

    final requestItems = <_NotifRow>[];
    for (final r in requests) {
      for (final h in r.statusHistory) {
        if (h.actor == 'Citizen') continue;
        requestItems.add(_NotifRow(request: r, entry: h));
      }
    }
    requestItems.sort((a, b) => b.entry.at.compareTo(a.entry.at));

    ResidentProfileService? profileService;
    if (account != null) profileService = context.watch<ResidentProfileService>();
    final profile = account != null ? profileService!.profileFor(account) : null;
    final showProfileReminder = profile != null && profile.overallCompletionPercent < 100;

    final hasAnything = showProfileReminder || requestItems.isNotEmpty || _sampleNotifications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: !hasAnything
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: "You're all caught up")
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (showProfileReminder) ...[
                  _NotificationTile(
                    kind: NotificationKind.actionRequired,
                    icon: Icons.badge_outlined,
                    title: 'Complete Your Profile',
                    body: 'Finish your Resident Profile so Esperanza LGU can verify your account and unlock full access. ${profile.overallCompletionPercent}% complete.',
                    time: null,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResidentProfileOverviewScreen())),
                    actionLabel: 'Complete Profile',
                  ),
                  const SizedBox(height: 4),
                ],
                for (final row in requestItems) ...[
                  _NotificationTile(
                    kind: _kindFor(row.entry.status),
                    icon: _iconFor(row.entry.status),
                    title: '${row.request.typeName} — ${row.entry.status}',
                    body: row.entry.remarks ?? 'Updated by ${row.entry.actor}.',
                    time: row.request.referenceNumber,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: row.request.id))),
                  ),
                ],
                if (_sampleNotifications.isNotEmpty) ...[
                  if (showProfileReminder || requestItems.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Esperanza Updates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate500)),
                    ),
                  ],
                  for (final s in _sampleNotifications)
                    _NotificationTile(kind: s.kind, icon: s.icon, title: s.title, body: s.body, time: s.time, onTap: null),
                ],
              ],
            ),
    );
  }

  NotificationKind _kindFor(String status) => switch (status) {
        'Approved' || 'Released' || 'Completed' => NotificationKind.success,
        'Rejected' => NotificationKind.warning,
        'Waiting Requirements' => NotificationKind.actionRequired,
        _ => NotificationKind.info,
      };

  IconData _iconFor(String status) => switch (status) {
        'Approved' => Icons.check_circle_outline_rounded,
        'Rejected' => Icons.cancel_outlined,
        'Released' || 'Completed' => Icons.task_alt_rounded,
        'Waiting Requirements' => Icons.warning_amber_rounded,
        'Ready for Release' => Icons.inventory_2_outlined,
        _ => Icons.info_outline_rounded,
      };

  /// Illustrative-only demo content for notification types this frontend
  /// build has no real producer for. Fixed, never persisted, never
  /// affects any account/request state — tapping does nothing.
  static final _sampleNotifications = <_SampleNotification>[
    _SampleNotification(
      kind: NotificationKind.urgent,
      icon: Icons.warning_amber_rounded,
      title: 'Typhoon Advisory — Esperanza, Masbate',
      body: 'MDRRMO has raised a weather advisory for the municipality. Monitor official channels and prepare a go-bag.',
      time: '1 hr ago',
    ),
    _SampleNotification(
      kind: NotificationKind.info,
      icon: Icons.home_work_outlined,
      title: 'Evacuation Center Update',
      body: 'Poblacion Covered Court is now open and accepting families ahead of expected heavy rainfall.',
      time: '2 hrs ago',
    ),
    _SampleNotification(
      kind: NotificationKind.info,
      icon: Icons.volunteer_activism_outlined,
      title: 'New Assistance Program Available',
      body: 'MSWDO has opened applications for Educational Assistance for School Year 2026–2027.',
      time: 'Yesterday',
    ),
    _SampleNotification(
      kind: NotificationKind.info,
      icon: Icons.campaign_outlined,
      title: 'Municipal Announcement',
      body: 'Office of the Municipal Mayor: Fiesta ng Esperanza opening program this August 14 at the Municipal Plaza.',
      time: '2 days ago',
    ),
    _SampleNotification(
      kind: NotificationKind.info,
      icon: Icons.apartment_outlined,
      title: 'Barangay Santiago Announcement',
      body: 'Free anti-rabies vaccination for pets this Sunday, 8AM–4PM at the barangay covered court.',
      time: '3 days ago',
    ),
  ];
}

class _NotifRow {
  final ServiceRequest request;
  final dynamic entry;
  _NotifRow({required this.request, required this.entry});
}

class _SampleNotification {
  final NotificationKind kind;
  final IconData icon;
  final String title;
  final String body;
  final String time;
  _SampleNotification({required this.kind, required this.icon, required this.title, required this.body, required this.time});
}

class _NotificationTile extends StatelessWidget {
  final NotificationKind kind;
  final IconData icon;
  final String title;
  final String body;
  final String? time;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _NotificationTile({
    required this.kind,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: kind.background, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: kind.foreground),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Icon + text label together (never color alone) so the
                  // notification's severity/type reads clearly even for
                  // colorblind users or in bright outdoor sunlight.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: kind.background, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(kind.badgeIcon, size: 10, color: kind.foreground),
                        const SizedBox(width: 3),
                        Text(kind.badgeLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: kind.foreground)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(body, style: const TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.35)),
                  if (time != null) ...[
                    const SizedBox(height: 4),
                    Text(time!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(actionLabel!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kind.foreground)),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 13, color: kind.foreground),
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
