import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_notification.dart';
import '../models/notification_kind.dart';
import '../models/service_request.dart';
import '../screens/notifications/duplicate_account_details_screen.dart';
import '../screens/notifications/unverified_duplicate_resolution_screen.dart';
import '../screens/profile/resident_profile/resident_profile_overview_screen.dart';
import '../screens/shared/request_detail_screen.dart';
import 'citizen_session_service.dart';
import 'mock_catalog.dart';
import 'notifications_service.dart';
import 'requests_service.dart';
import 'resident_profile_service.dart';

/// Builds the same notification feed [NotificationsScreen] shows, as a
/// plain list with stable IDs — shared with [AlertsAction] (the bell icon)
/// so both surfaces agree on exactly what counts as a notification and
/// whether it's read, without keeping two separate copies of this
/// derivation logic. Combines three sources, each visually distinguished
/// by [NotificationKind] (icon + label, never color alone):
///
/// 1. A profile-completion reminder — derived live from
///    [ResidentProfileService], not a stored notification, so it appears
///    exactly while the signed-in citizen's profile is incomplete and
///    disappears the moment it reaches 100%, and never shown to a Guest.
/// 2. Real request-status updates — every non-citizen entry in a
///    request's statusHistory (the "Mobile Reflection" half of the
///    citizen/admin flow model). This is also how the pre-made Dokyu/
///    Tulong status simulations (see MockCatalog demo seed) surface their
///    own Approved/Pending/Rejected notifications — they're just requests
///    with statusHistory like any other, so no separate notification
///    producer was needed for them.
/// 3. Sample notifications for types this frontend-only build has no real
///    producer for yet — illustrative only, never wired to any real state
///    change.
List<AppNotification> buildNotificationFeed(BuildContext context) {
  final session = context.watch<CitizenSessionService>();
  final account = session.account;
  final requests = context.watch<RequestsService>().all;

  final items = <AppNotification>[];

  ResidentProfileService? profileService;
  if (account != null) profileService = context.watch<ResidentProfileService>();
  final profile = account != null ? profileService!.profileFor(account) : null;
  if (profile != null && profile.overallCompletionPercent < 100) {
    items.add(
      AppNotification(
        id: 'profile-reminder-${account!.id}',
        kind: NotificationKind.actionRequired,
        icon: Icons.badge_outlined,
        title: 'Complete Your Profile',
        body: 'Finish your Resident Profile so Esperanza LGU can verify your account and unlock full access. ${profile.overallCompletionPercent}% complete.',
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResidentProfileOverviewScreen())),
        actionLabel: 'Complete Profile',
      ),
    );
  }

  // Inserted right after the profile reminder — ahead of individual
  // request-status updates and the illustrative sample content — since a
  // duplicate-account warning is meant to be noticed quickly, not buried
  // below a long, growing history of routine status updates.
  if (account != null) {
    final duplicateAlerts = context.watch<NotificationsService>();
    items.addAll(_duplicateAccountNotifications(context, account.id, duplicateAlerts));
    items.addAll(_unverifiedDuplicateNotifications(context, account.id, duplicateAlerts));
  }

  final requestItems = <(ServiceRequest, StatusHistoryEntry)>[];
  for (final r in requests) {
    for (final h in r.statusHistory) {
      if (h.actor == 'Citizen') continue;
      requestItems.add((r, h));
    }
  }
  requestItems.sort((a, b) => b.$2.at.compareTo(a.$2.at));

  for (final (request, entry) in requestItems) {
    items.add(
      AppNotification(
        id: 'req-${request.id}-${entry.at.toIso8601String()}-${entry.status}',
        kind: _kindFor(entry.status),
        icon: _iconFor(entry.status),
        title: '${request.typeName} — ${entry.status}',
        body: entry.remarks ?? 'Updated by ${entry.actor}.',
        time: request.referenceNumber,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id))),
      ),
    );
  }

  for (final s in _sampleNotifications) {
    items.add(AppNotification(id: s.id, kind: s.kind, icon: s.icon, title: s.title, body: s.body, time: s.time));
  }

  return items;
}

/// Phase 6 — "One Person, One Account" duplicate-account demo (FRONTEND
/// SIMULATION ONLY, see duplicate_account_details_screen.dart). Two
/// alert scenarios ('a'/'b') on the real Cristy Bonghanoy's own account so
/// both the "Yes, this is me" and "No, this is not me" resolutions can be
/// demonstrated without resetting the app, plus one informational entry
/// on the duplicate account itself. Every id is unique and unrelated to
/// any real request/profile state, so this can never collide with or
/// affect the notification sources above.
List<AppNotification> _duplicateAccountNotifications(
  BuildContext context,
  String accountId,
  NotificationsService duplicateAlerts,
) {
  const originalId = 'ESP-RES-2024-1044';
  final duplicateId = MockCatalog.duplicateCristyAccount.id;

  if (accountId == originalId) {
    return [
      for (final scenarioId in const ['a', 'b'])
        _duplicateAlertFor(context, scenarioId, duplicateAlerts),
    ];
  }

  if (accountId == duplicateId) {
    // No resolution choice on this side — see the class doc comment on
    // DuplicateAccountDetailsScreen for why (only enough information for
    // the *original* resident to confirm ownership, nothing exposed here).
    final resolvedAsSameOwner = duplicateAlerts.duplicateResolutionFor('a') == 'confirmed' ||
        duplicateAlerts.duplicateResolutionFor('b') == 'confirmed';
    final resolvedAsReported = duplicateAlerts.duplicateResolutionFor('a') == 'reported' ||
        duplicateAlerts.duplicateResolutionFor('b') == 'reported';
    return [
      AppNotification(
        id: 'duplicate-under-review-status',
        kind: resolvedAsSameOwner ? NotificationKind.warning : NotificationKind.actionRequired,
        icon: Icons.person_search_rounded,
        title: resolvedAsSameOwner
            ? 'Duplicate / Verification Blocked'
            : resolvedAsReported
                ? 'Duplicate Account Flagged for Investigation'
                : 'Duplicate Account Under Review',
        body: resolvedAsSameOwner
            ? 'The original resident confirmed this registration is theirs. Esperanza allows one account per '
                'resident, so verification cannot continue on this account — sign in with your original account '
                'instead.'
            : resolvedAsReported
                ? 'This registration has been flagged for administrative investigation. Verification remains on '
                    'hold while it is reviewed.'
                : 'An existing Esperanza account appears to match the information submitted for this account. '
                    'Verification is temporarily restricted while the account is reviewed.',
      ),
    ];
  }

  return const [];
}

/// The Unverified+Unverified duplicate demo — independent of
/// [_duplicateAccountNotifications] above, see
/// screens/notifications/unverified_duplicate_resolution_screen.dart.
List<AppNotification> _unverifiedDuplicateNotifications(
  BuildContext context,
  String accountId,
  NotificationsService duplicateAlerts,
) {
  final aId = MockCatalog.unverifiedDuplicateAccountA.id;
  final bId = MockCatalog.unverifiedDuplicateAccountB.id;
  if (accountId != aId && accountId != bId) return const [];

  final thisLabel = accountId == aId ? 'A' : 'B';
  final kept = duplicateAlerts.unverifiedDuplicateKeptAccountId;

  final String title;
  final String body;
  final NotificationKind kind;
  if (kept == null) {
    title = 'Possible Duplicate Registration Detected';
    body = 'Two unverified Esperanza registrations appear to contain matching resident information. Choose which '
        'one to continue using for verification.';
    kind = NotificationKind.warning;
  } else if (kept == thisLabel) {
    title = 'Unverified — Continue Verification';
    body = 'You chose to continue verification with this account. It is still Pending Review — an LGU officer '
        'still has to approve it; this did not make it Verified automatically.';
    kind = NotificationKind.info;
  } else {
    title = 'Duplicate Registration — Verification Cancelled';
    body = 'This registration was marked as a duplicate after the other account was chosen. Its verification has '
        'been cancelled.';
    kind = NotificationKind.warning;
  }

  return [
    AppNotification(
      id: 'unverified-duplicate-$thisLabel',
      kind: kind,
      icon: Icons.person_search_rounded,
      title: title,
      body: body,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UnverifiedDuplicateResolutionScreen()),
      ),
    ),
  ];
}

AppNotification _duplicateAlertFor(BuildContext context, String scenarioId, NotificationsService duplicateAlerts) {
  final resolution = duplicateAlerts.duplicateResolutionFor(scenarioId);
  final label = scenarioId == 'a' ? 'Scenario A' : 'Scenario B';
  return AppNotification(
    id: 'duplicate-alert-$scenarioId',
    kind: resolution == null ? NotificationKind.warning : NotificationKind.info,
    icon: Icons.person_search_rounded,
    title: resolution == null
        ? 'Possible Duplicate Account Detected'
        : 'Possible Duplicate Account Detected ($label — Resolved)',
    body: resolution == null
        ? 'Another Esperanza account was created using information that appears to match your identity. Please '
            'confirm whether the account belongs to you.'
        : resolution == 'confirmed'
            ? 'You confirmed this duplicate account is yours — it remains blocked from verification. Tap to view details.'
            : 'You reported this duplicate account does not belong to you — it has been flagged for '
                'administrative investigation. Tap to view details.',
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DuplicateAccountDetailsScreen(scenarioId: scenarioId)),
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

class _SampleNotification {
  final String id;
  final NotificationKind kind;
  final IconData icon;
  final String title;
  final String body;
  final String time;
  const _SampleNotification({required this.id, required this.kind, required this.icon, required this.title, required this.body, required this.time});
}

/// Illustrative-only demo content for notification types this frontend
/// build has no real producer for. Fixed, never persisted beyond their own
/// read/unread flag, never affects any account/request state.
const _sampleNotifications = <_SampleNotification>[
  _SampleNotification(
    id: 'sample-typhoon-advisory',
    kind: NotificationKind.urgent,
    icon: Icons.warning_amber_rounded,
    title: 'Typhoon Advisory — Esperanza, Masbate',
    body: 'MDRRMO has raised a weather advisory for the municipality. Monitor official channels and prepare a go-bag.',
    time: '1 hr ago',
  ),
  _SampleNotification(
    id: 'sample-evacuation-update',
    kind: NotificationKind.info,
    icon: Icons.home_work_outlined,
    title: 'Evacuation Center Update',
    body: 'Poblacion Covered Court is now open and accepting families ahead of expected heavy rainfall.',
    time: '2 hrs ago',
  ),
  _SampleNotification(
    id: 'sample-new-assistance-program',
    kind: NotificationKind.info,
    icon: Icons.volunteer_activism_outlined,
    title: 'New Assistance Program Available',
    body: 'MSWDO has opened applications for Educational Assistance for School Year 2026–2027.',
    time: 'Yesterday',
  ),
  _SampleNotification(
    id: 'sample-municipal-announcement',
    kind: NotificationKind.info,
    icon: Icons.campaign_outlined,
    title: 'Municipal Announcement',
    body: 'Office of the Municipal Mayor: Fiesta ng Esperanza opening program this August 14 at the Municipal Plaza.',
    time: '2 days ago',
  ),
  _SampleNotification(
    id: 'sample-barangay-santiago',
    kind: NotificationKind.info,
    icon: Icons.apartment_outlined,
    title: 'Barangay Santiago Announcement',
    body: 'Free anti-rabies vaccination for pets this Sunday, 8AM–4PM at the barangay covered court.',
    time: '3 days ago',
  ),
];
