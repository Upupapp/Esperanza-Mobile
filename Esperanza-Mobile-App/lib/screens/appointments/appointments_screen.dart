import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/appointments_service.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/calendar_export.dart';
import '../../utils/date_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';

/// Appointments (scope round 2026-10-15; the web portal's Appointments page):
/// the resident's own appointments, upcoming first, each cancellable while it
/// can be, and booking a new one.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late Future<List<Appointment>> _future = AppointmentsService.mine();
  String? _cancelling;

  void _reload() {
    setState(() {
      _future = AppointmentsService.mine();
    });
  }

  Future<void> _book() async {
    final booked = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const BookAppointmentScreen()));
    if (booked == true && mounted) _reload();
  }

  Future<void> _cancel(Appointment a) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Cancel this appointment?',
      message: '${a.place ?? 'The office'}, ${a.when ?? shortDate(a.date)}. The time is freed for someone else.',
      confirmLabel: 'Cancel appointment',
      cancelLabel: 'Keep it',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _cancelling = a.ref);
    try {
      await AppointmentsService.cancel(a.ref);
      if (!mounted) return;
      AppDialogs.toast(context, 'Appointment ${a.ref} cancelled.');
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      AppDialogs.toast(context, AppointmentsService.explain(e), success: false);
      if (e.code == 'NOT_CANCELLABLE' || e.code == 'ALREADY_STARTED') _reload();
    } finally {
      if (mounted) setState(() => _cancelling = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: FutureBuilder<List<Appointment>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final e = snap.error;
            return _Problem(
              message: e is ApiException ? e.message() : 'Your appointments could not be loaded.',
              onRetry: _reload,
            );
          }
          final all = snap.data ?? const [];
          final upcoming = [
            for (final a in all)
              if (a.upcoming) a,
          ];
          final past = [
            for (final a in all)
              if (!a.upcoming) a,
          ];
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future.catchError((Object _) => <Appointment>[]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                AppSpacing.page,
              ),
              children: [
                const Text(
                  'Book a time with an office instead of waiting in line. The office confirms your booking. You can hold up to three upcoming appointments.',
                  style: AppTypography.helper,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: 'Book an appointment', icon: Icons.add_rounded, fullWidth: true, onPressed: _book),
                const SizedBox(height: AppSpacing.sectionGap),
                const Text('Upcoming', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.headingGap),
                if (upcoming.isEmpty)
                  const Text('You have no upcoming appointments.', style: AppTypography.helper)
                else
                  for (final a in upcoming) ...[
                    _AppointmentCard(
                      appointment: a,
                      busy: _cancelling == a.ref,
                      onCancel: a.canCancel && _cancelling == null ? () => _cancel(a) : null,
                    ),
                    const SizedBox(height: AppSpacing.itemGap),
                  ],
                const SizedBox(height: AppSpacing.sectionGap),
                const Text('Past', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.headingGap),
                if (past.isEmpty)
                  const Text('No past appointments yet.', style: AppTypography.helper)
                else
                  for (final a in past) ...[
                    _AppointmentCard(appointment: a),
                    const SizedBox(height: AppSpacing.itemGap),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// An appointment status's colours: the appointment book's own closed set.
(Color, Color) _statusColors(String status) => switch (status) {
  'Confirmed' => (AppColors.emerald700, AppColors.emerald50),
  'Booked' => (AppColors.sky700, AppColors.sky50),
  'Completed' => (AppColors.slate700, AppColors.slate100),
  'No Show' => (AppColors.amber700, AppColors.amber50),
  _ => (AppColors.rose700, AppColors.rose50),
};

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, this.onCancel, this.busy = false});

  final Appointment appointment;
  final VoidCallback? onCancel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final (fg, bg) = _statusColors(a.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.place ?? 'Office', style: AppTypography.cardHeading),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      a.when ?? shortDate(a.date),
                      style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
                child: Text(a.status, style: AppTypography.labelText.copyWith(color: fg)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (a.schedule != null) Text(a.schedule!, style: AppTypography.helper),
          if (a.location != null) Text(a.location!, style: AppTypography.helper),
          if (a.purpose != null) Text('Purpose: ${a.purpose}', style: AppTypography.helper),
          if (a.requestRef != null) Text('For request ${a.requestRef}', style: AppTypography.helper),
          Text('Reference ${a.ref}', style: AppTypography.helper),
          if (a.status == 'Cancelled' && a.cancelReason != null)
            Text('Cancelled: ${a.cancelReason}', style: AppTypography.helper.copyWith(color: AppColors.rose700)),
          if (a.upcoming || onCancel != null || busy) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                // As on the website: onto the phone's calendar, reminded the day before.
                if (a.upcoming)
                  TextButton.icon(
                    onPressed: () => CalendarExport.offer(
                      context,
                      CalendarEntry(
                        uid: '${a.ref}@esperanza-lgu',
                        title: 'Appointment: ${a.place ?? 'LGU Esperanza'}',
                        date: a.date,
                        time: a.startTime == null ? null : '${a.startTime}-${a.endTime ?? ''}',
                        place: [?a.place, ?a.location].join(', '),
                        description: [
                          if (a.purpose != null) 'Purpose: ${a.purpose}',
                          'Reference ${a.ref}',
                          'Bring a valid ID.',
                        ].join('\n'),
                      ),
                    ),
                    icon: const Icon(Icons.event_available_outlined, size: AppSizes.iconSm),
                    label: const Text('Add to calendar'),
                  ),
                if (onCancel != null || busy)
                  TextButton.icon(
                    onPressed: busy ? null : onCancel,
                    icon: busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.event_busy_rounded, size: AppSizes.iconSm),
                    label: const Text('Cancel appointment'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.rose700),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppTypography.helper),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

/// Book a time with an office: its schedule, then a day and a free time, then
/// what the visit is for and, optionally, which of the resident's requests.
/// Only a verified account books; anyone signed in can look at the times.
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key, this.requestRef});

  /// A request this booking is for, chosen beforehand.
  final String? requestRef;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late Future<List<AppointmentSchedule>> _schedules = AppointmentsService.schedules();
  AppointmentSchedule? _schedule;
  Future<List<AppointmentDay>>? _days;
  AppointmentDay? _day;
  AppointmentSlot? _slot;
  late String? _requestRef = widget.requestRef;
  final _purpose = TextEditingController();
  bool _sending = false;
  bool _tried = false;
  String? _error;
  Appointment? _booked;

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  void _pickSchedule(AppointmentSchedule s) {
    setState(() {
      _schedule = s;
      _day = null;
      _slot = null;
      _error = null;
      _days = AppointmentsService.availability(s.id);
    });
  }

  void _reloadDays() {
    final s = _schedule;
    if (s == null) return;
    setState(() {
      _day = null;
      _slot = null;
      _days = AppointmentsService.availability(s.id);
    });
  }

  Future<void> _confirm() async {
    setState(() => _tried = true);
    if (_schedule == null || _day == null || _slot == null) {
      setState(() => _error = 'Choose an office, a day and a time.');
      return;
    }
    if (_purpose.text.trim().length < 3) {
      setState(() => _error = 'Say what the visit is for, in at least 3 characters.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final booked = await AppointmentsService.book(
        scheduleId: _schedule!.id,
        date: _day!.date,
        startTime: _slot!.start,
        purpose: _purpose.text,
        requestRef: _requestRef,
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _booked = booked;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = AppointmentsService.explain(e);
      });
      if (e.code == 'SLOT_FULL' || e.code == 'SLOT_NOT_OFFERED') _reloadDays();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booked = _booked;
    return Scaffold(
      appBar: AppBar(title: Text(booked == null ? 'Book an appointment' : 'Appointment booked')),
      body: booked != null ? _BookedView(appointment: booked) : _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final verified = context.watch<CitizenSessionService>().account?.status == 'Approved';
    final requests = [
      for (final r in context.watch<RequestsService>().all)
        if (!r.referenceNumber.startsWith('INC-') && !const ['Rejected', 'Cancelled', 'Archived'].contains(r.status)) r,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.md,
        AppSpacing.screenGutter,
        AppSpacing.page,
      ),
      children: [
        if (!verified) ...[
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: AppSizes.iconBase, color: AppColors.amber700),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Your account must be verified before you can book. You can still look at the open times.',
                    style: AppTypography.bodyText.copyWith(color: AppColors.amber700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        const _Step(number: 1, title: 'Choose an office'),
        FutureBuilder<List<AppointmentSchedule>>(
          future: _schedules,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              final e = snap.error;
              return _Problem(
                message: e is ApiException ? e.message() : 'The offices could not be loaded.',
                onRetry: () => setState(() => _schedules = AppointmentsService.schedules()),
              );
            }
            final schedules = snap.data ?? const [];
            if (schedules.isEmpty) {
              return const Text(
                'No office is taking appointments online yet. Visit or call the office, or check again another day.',
                style: AppTypography.helper,
              );
            }
            return Column(
              children: [
                for (final s in schedules) ...[
                  _Choice(
                    selected: _schedule?.id == s.id,
                    onTap: () => _pickSchedule(s),
                    title: s.place,
                    lines: [s.label, s.openText, if (s.service != null) 'For ${s.service}', ?s.location],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
        if (_schedule != null) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          const _Step(number: 2, title: 'Choose a day and time'),
          if (_schedule!.notes != null) ...[
            Text(_schedule!.notes!, style: AppTypography.helper.copyWith(color: AppColors.amber700)),
            const SizedBox(height: AppSpacing.sm),
          ],
          FutureBuilder<List<AppointmentDay>>(
            future: _days,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                final e = snap.error;
                return _Problem(
                  message: e is ApiException ? e.message() : 'The open times could not be loaded.',
                  onRetry: _reloadDays,
                );
              }
              final days = snap.data ?? const [];
              if (!days.any((d) => d.hasOpenSlot)) {
                return const Text(
                  'No open times in the coming days. Try another office or check again later.',
                  style: AppTypography.helper,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final d = days[i];
                        final selected = _day?.date == d.date;
                        return _DayChip(
                          day: d,
                          selected: selected,
                          onTap: d.hasOpenSlot
                              ? () => setState(() {
                                  _day = d;
                                  _slot = null;
                                  _error = null;
                                })
                              : null,
                        );
                      },
                    ),
                  ),
                  if (_day != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final slot in _day!.slots)
                          ChoiceChip(
                            label: Text(
                              slot.left > 0
                                  ? '${clock(slot.start)} · ${slot.left} left'
                                  : '${clock(slot.start)} · Full',
                            ),
                            selected: _slot?.start == slot.start,
                            onSelected: slot.left > 0 ? (_) => setState(() => _slot = slot) : null,
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
        if (_slot != null) ...[
          const SizedBox(height: AppSpacing.sectionGap),
          const _Step(number: 3, title: 'What is the visit for?'),
          AppTextField(
            label: 'Purpose',
            required: true,
            controller: _purpose,
            maxLines: 3,
            maxLength: 500,
            hintText: 'e.g. Claim my barangay clearance',
            error: _tried && _purpose.text.trim().length < 3 ? 'Write at least 3 characters.' : null,
            onChanged: (_) => setState(() {}),
          ),
          if (requests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.fieldGap),
            AppSelectField<String?>(
              label: 'For one of your requests (optional)',
              value: _requestRef,
              options: [null, for (final r in requests) r.referenceNumber],
              labelBuilder: (ref) {
                if (ref == null) return 'None';
                final r = requests.firstWhere((x) => x.referenceNumber == ref);
                return '$ref · ${r.typeName}';
              },
              onChanged: (ref) => setState(() => _requestRef = ref),
            ),
          ],
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.rose700)),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Confirm booking',
          fullWidth: true,
          loading: _sending,
          onPressed: verified && _slot != null ? _confirm : null,
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.headingGap),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.brand700,
            child: Text('$number', style: AppTypography.labelText.copyWith(color: AppColors.surface)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title, style: AppTypography.cardHeading)),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.selected, required this.onTap, required this.title, this.lines = const []});

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand50 : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: selected ? AppColors.brand700 : AppColors.slate200, width: selected ? 2 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    for (final l in lines.where((l) => l.isNotEmpty)) Text(l, style: AppTypography.helper),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.brand700, size: AppSizes.iconBase),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.selected, this.onTap});

  final AppointmentDay day;
  final bool selected;
  final VoidCallback? onTap;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final open = onTap != null;
    final note = day.closedReason != null
        ? 'Closed'
        : (open ? '${day.slots.where((s) => s.left > 0).length} times' : 'Full');
    return Semantics(
      button: open,
      selected: selected,
      label: '${_weekdays[day.date.weekday - 1]} ${_months[day.date.month - 1]} ${day.date.day}, $note',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand700 : (open ? AppColors.surface : AppColors.slate100),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: selected ? AppColors.brand700 : AppColors.slate200),
          ),
          // Shrinks rather than overflows at large text sizes.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdays[day.date.weekday - 1],
                  style: AppTypography.labelText.copyWith(color: selected ? AppColors.surface : AppColors.slate600),
                ),
                Text(
                  '${_months[day.date.month - 1]} ${day.date.day}',
                  style: AppTypography.bodyText.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.surface : AppColors.textPrimary,
                  ),
                ),
                Text(
                  note,
                  style: AppTypography.fine.copyWith(color: selected ? AppColors.surface : AppColors.slate600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookedView extends StatelessWidget {
  const _BookedView({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenGutter,
        AppSpacing.lg,
        AppSpacing.screenGutter,
        AppSpacing.page,
      ),
      children: [
        const Icon(Icons.event_available_rounded, size: AppSizes.iconHero, color: AppColors.emerald700),
        const SizedBox(height: AppSpacing.md),
        const Text('Your appointment is booked', textAlign: TextAlign.center, style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'The office will confirm it, and you will be notified.',
          textAlign: TextAlign.center,
          style: AppTypography.helper,
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _AppointmentCard(appointment: a),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Done', fullWidth: true, onPressed: () => Navigator.of(context).pop(true)),
      ],
    );
  }
}
