import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../models/incident_status.dart';
import '../../models/notification_kind.dart';
import '../../services/citizen_session_service.dart';
import '../../services/notification_feed.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/segmented_tabs.dart';
import '../../theme/app_typography.dart';
import '../../services/api_client.dart';
import '../../widgets/app_dialogs.dart';
import '../../theme/app_status.dart';
import '../../widgets/status_chip.dart';
import '../../utils/date_text.dart';

import '../../l10n/tr.dart';

/// See notification_feed.dart for how the feed itself is assembled — this
/// screen renders it with its filters, and each tile's read/unread state
/// (tracked by [NotificationsService]).
///
/// The website's redesign (28 Nov 2026, after eBPCO's): All / Unread with
/// their counts; a search; the kinds this resident actually has, with
/// counts; and when (Any time, Today, Last 7 days, Last 30 days, or a date
/// picked). Clear filters shows once something is filtered. An unread
/// notification is a blue-tinted card with a bold title and a blue dot:
/// tapping the dot marks it read, and so does opening it. There is no Read
/// tab any more, and no Dokyu/Tulong tabs: Category holds them.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

/// The When filter's choices, as on the website.
enum NotificationWhen { any, today, week, month, on }

/// The name of a kind of notification (the server's category) in the
/// Category filter, as on the website (resources/js/notifications.js).
String notificationKindName(String key) => switch (key) {
  'dokyu' => 'Dokyu',
  'tulong' => 'Tulong',
  'sakuna' => 'Sakuna',
  'account' => tr('Account'),
  'community' => tr('Balita and events'),
  'events' => tr('Appointments'),
  'request' => tr('Requests'),
  _ => key.isEmpty ? key : key[0].toUpperCase() + key.substring(1).replaceAll('_', ' '),
};

/// Whether [n] passes the filters. [readHere] keeps a notification read
/// on this screen in the Unread list (now plain) until the screen is
/// opened again, as the website keeps it until the list reloads.
bool notificationMatches(
  AppNotification n, {
  required bool unread,
  required bool unreadOnly,
  String? category,
  String query = '',
  NotificationWhen when = NotificationWhen.any,
  DateTime? date,
  DateTime? now,
}) {
  if (unreadOnly && !unread) return false;
  if (category != null && n.category != category) return false;
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isNotEmpty) {
    final text = [n.title, n.body, ?n.ref].join(' ').toLowerCase();
    if (!words.every(text.contains)) return false;
  }
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final at = n.at;
  return switch (when) {
    NotificationWhen.any => true,
    NotificationWhen.today => !at.isBefore(today),
    NotificationWhen.week => !at.isBefore(today.subtract(const Duration(days: 6))),
    NotificationWhen.month => !at.isBefore(today.subtract(const Duration(days: 29))),
    NotificationWhen.on => date == null || DateUtils.isSameDay(at, date),
  };
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;
  String? _category;
  NotificationWhen _when = NotificationWhen.any;
  DateTime? _date;
  final _search = TextEditingController();
  final Set<String> _readHere = {};

  bool get _filtered => _search.text.trim().isNotEmpty || _category != null || _when != NotificationWhen.any;

  @override
  void initState() {
    super.initState();
    // The shell loads the feed once, when it appears; without this a
    // notification that arrived since then stayed hidden until the citizen
    // thought to pull down. Quiet on failure: what is already here stays.
    if (context.read<CitizenSessionService>().account != null) {
      context.read<NotificationsService>().loadServer().catchError((Object _) {}, test: (e) => e is ApiException);
    }
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() => setState(() {
    _search.clear();
    _category = null;
    _when = NotificationWhen.any;
    _date = null;
  });

  void _markRead(NotificationsService service, AppNotification n) {
    setState(() => _readHere.add(n.id));
    service.markRead(n.id);
  }

  String _whenLabel() => switch (_when) {
    NotificationWhen.any => tr('Any time'),
    NotificationWhen.today => tr('Today'),
    NotificationWhen.week => tr('Last 7 days'),
    NotificationWhen.month => tr('Last 30 days'),
    NotificationWhen.on => _date == null ? tr('On a date…') : shortDate(_date!),
  };

  Future<void> _pickCategory(List<({String key, int total, int unread})> kinds) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Text(tr('Category'), style: AppTypography.cardHeading),
            ),
            _SheetOption(label: tr('All categories'), selected: _category == null, onTap: () => Navigator.pop(ctx, '')),
            for (final k in kinds)
              _SheetOption(
                label: notificationKindName(k.key),
                count: _unreadOnly ? k.unread : k.total,
                selected: _category == k.key,
                onTap: () => Navigator.pop(ctx, k.key),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _category = picked.isEmpty ? null : picked);
  }

  Future<void> _pickWhen() async {
    final picked = await showModalBottomSheet<NotificationWhen>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Text(tr('When'), style: AppTypography.cardHeading),
            ),
            for (final w in NotificationWhen.values)
              _SheetOption(
                label: switch (w) {
                  NotificationWhen.any => tr('Any time'),
                  NotificationWhen.today => tr('Today'),
                  NotificationWhen.week => tr('Last 7 days'),
                  NotificationWhen.month => tr('Last 30 days'),
                  NotificationWhen.on => tr('On a date…'),
                },
                selected: _when == w,
                onTap: () => Navigator.pop(ctx, w),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    if (picked != NotificationWhen.on) {
      setState(() {
        _when = picked;
        _date = null;
      });
      return;
    }
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    setState(() {
      _when = NotificationWhen.on;
      _date = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = buildNotificationFeed(context);
    final notifService = context.watch<NotificationsService>();
    final ids = all.map((n) => n.id);
    final anyUnread = notifService.hasUnread(ids);
    final unread = all.where((n) => !notifService.isRead(n.id)).length;

    // The kinds this resident has, with how many and how many unread.
    final counts = <String, ({int total, int unread})>{};
    for (final n in all) {
      final key = n.category;
      if (key == null) continue;
      final c = counts[key] ?? (total: 0, unread: 0);
      counts[key] = (total: c.total + 1, unread: c.unread + (notifService.isRead(n.id) ? 0 : 1));
    }
    final kinds = [for (final e in counts.entries) (key: e.key, total: e.value.total, unread: e.value.unread)]
      ..sort((a, b) => b.total.compareTo(a.total));

    final items = [
      for (final n in all)
        if (notificationMatches(
          n,
          unread: !notifService.isRead(n.id) || _readHere.contains(n.id),
          unreadOnly: _unreadOnly,
          category: _category,
          query: _search.text,
          when: _when,
          date: _date,
        ))
          n,
    ];

    final filters = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            labels: ['${tr('All')} (${all.length})', '${tr('Unread')} ($unread)'],
            selectedIndex: _unreadOnly ? 1 : 0,
            onChanged: (i) => setState(() => _unreadOnly = i == 1),
            accent: AppColors.brand600,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.textBody),
            decoration: InputDecoration(
              isDense: true,
              hintText: tr('Search notifications'),
              prefixIcon: const Icon(Icons.search_rounded, size: AppSizes.iconSm),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: tr('Clear'),
                      icon: const Icon(Icons.close_rounded, size: AppSizes.iconSm),
                      onPressed: _search.clear,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterButton(
                  icon: Icons.category_outlined,
                  label: _category == null ? tr('All categories') : notificationKindName(_category!),
                  active: _category != null,
                  onTap: () => _pickCategory(kinds),
                ),
                const SizedBox(width: AppSpacing.sm),
                _FilterButton(
                  icon: Icons.event_outlined,
                  label: _whenLabel(),
                  active: _when != NotificationWhen.any,
                  onTap: _pickWhen,
                ),
                if (_filtered) ...[
                  const SizedBox(width: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.close_rounded, size: AppSizes.iconSm),
                    label: Text(tr('Clear filters')),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Notifications')),
        actions: [
          if (anyUnread)
            TextButton(
              onPressed: () {
                setState(() => _readHere.addAll(ids.where((id) => !notifService.isRead(id))));
                notifService.markAllRead(ids);
              },
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
            if (i == 0) return filters;
            i -= 1;
            if (items.isEmpty) {
              return EmptyState(
                icon: _filtered ? Icons.search_off_rounded : Icons.notifications_none_rounded,
                title: _filtered
                    ? tr('No notifications match these filters.')
                    : _unreadOnly
                    ? tr("You're all caught up.")
                    : tr('No notifications yet.'),
                action: _filtered || _unreadOnly
                    ? OutlinedButton(
                        onPressed: () {
                          _clearFilters();
                          setState(() => _unreadOnly = false);
                        },
                        child: Text(tr('Show all notifications')),
                      )
                    : null,
              );
            }
            final n = items[i];
            return _NotificationTile(
              notification: n,
              unread: !notifService.isRead(n.id),
              onMarkRead: () => _markRead(notifService, n),
            );
          },
        ),
      ),
    );
  }
}

/// One choice in the Category or When sheet.
class _SheetOption extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _SheetOption({required this.label, this.count, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        count == null ? label : '$label ($count)',
        style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.brand700 : AppColors.textBody),
      ),
      trailing: selected ? const Icon(Icons.check_rounded, color: AppColors.brand600) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// A Category or When button: a pill that names the choice, blue once set.
class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand600 : AppColors.slate700;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: AppSizes.iconSm, color: color),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.expand_more_rounded, size: AppSizes.iconSm, color: color),
        ],
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSizes.minTouchTarget),
        backgroundColor: active ? AppColors.brand50 : null,
        side: BorderSide(color: active ? AppColors.brand300 : AppColors.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
    );
  }
}

/// The canonical status a notification names, when it names one the app
/// knows. An unknown label keeps the generic badge rather than guessing
/// (never invent a status: CLAUDE.md).
AppStatus? _statusOf(AppNotification n) {
  final label = n.status;
  // An incident names the server's status (Under Verification, Processing):
  // its own words go in the plain chip below (2026-11-13).
  if (label == null || n.category == 'sakuna') return null;
  for (final s in AppStatus.values) {
    if (s.label == label) return s;
  }
  return null;
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool unread;
  final VoidCallback onMarkRead;

  const _NotificationTile({required this.notification, required this.unread, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        glass: true,
        // Unread: blue-tinted, as on the website; read: plain.
        tint: unread ? AppColors.brand100 : AppColors.surface,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.xs, AppSpacing.lg),
        onTap: () {
          context.read<NotificationsService>().markRead(n.id);
          n.onTap?.call();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: AppTextSize.helper,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                            n.category == 'sakuna' && n.status != null ? incidentStatusLabel(n.status!) : n.kind.badgeLabel,
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
                      style: TextStyle(
                        fontSize: AppTextSize.fine,
                        // The time in blue while unread, as on the website.
                        color: unread ? AppColors.brand700 : AppColors.textMuted,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                      ),
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
            // The blue dot: unread. Tapping it marks the notification read
            // without opening it. A whole touch target around a small dot.
            SizedBox(
              width: AppSizes.minTouchTarget,
              child: unread
                  ? Semantics(
                      button: true,
                      label: tr('Mark as read'),
                      child: InkResponse(
                        key: ValueKey('mark-read-${n.id}'),
                        onTap: onMarkRead,
                        radius: AppSizes.minTouchTarget / 2,
                        child: const SizedBox(
                          width: AppSizes.minTouchTarget,
                          height: AppSizes.minTouchTarget,
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: AppColors.brand600, shape: BoxShape.circle),
                              child: SizedBox(width: 10, height: 10),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
