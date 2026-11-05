import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/announcement.dart';
import '../../models/event_registration.dart';
import '../../models/resident_certificate.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/event_registration_service.dart';
import '../../services/json_read.dart';
import '../../services/message_language.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/date_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/restricted_feature_notice.dart';
import '../shared/certificate_view_screen.dart';

/// Filipino first, as on the website's citizen Events page (each phrase is
/// written there as Filipino / English); shown in the language chosen in
/// Settings.
String _t(String fil, String en) => MessageLanguage.filipino.value ? fil : en;

/// Registering for an event, on its page (owner, 2026-10-30, round 2
/// item 6), the same as the website's citizen Events page:
///
/// - registration open: "Magparehistro", with the places left when the LGU
///   set a limit and until when it is open; full and closed say so instead.
///   Signed out, a prompt to sign in.
/// - registered: "Nakarehistro ka" and the code (`ABCD-EFGH`, and as a QR
///   code) that staff check the resident in by, and "Kanselahin" while the
///   event is still ahead.
/// - attended: "Dumalo ka", and "Tingnan ang sertipiko" once the LGU has
///   issued the certificate, which opens the certificate itself in the app.
///
/// Shows nothing (not even its top spacing) for an event that takes no
/// registrations, a bundled mock event, or a past event the resident did
/// not register for.
class EventRegistrationPanel extends StatefulWidget {
  const EventRegistrationPanel({super.key, required this.event, this.onRegistered});

  final EventItem event;

  /// Registering also turns on the day-before reminder on the server: the
  /// page's reminder button follows.
  final VoidCallback? onRegistered;

  @override
  State<EventRegistrationPanel> createState() => _EventRegistrationPanelState();
}

class _EventRegistrationPanelState extends State<EventRegistrationPanel> {
  EventRegistrationInfo? _info;
  EventRegistration? _mine;
  bool _signedIn = false;

  /// The resident's own registration has been read (or there is none to
  /// read: signed out).
  bool _loaded = false;
  bool _loadFailed = false;
  bool _busy = false;

  /// The server answered REGISTRATION_CLOSED before the closing time this
  /// page knew of (no closing time set: it closes at the event's start).
  bool _closedByServer = false;

  String? get _key => widget.event.key;

  @override
  void initState() {
    super.initState();
    _info = widget.event.registration;
    if (_key == null) return;
    _signedIn = context.read<CitizenSessionService>().isSignedIn;
    // Nothing of the resident's to read when signed out, or when the server
    // sent no registration block (one from before registration existed).
    final read = _signedIn && _info != null;
    _loaded = !read;
    if (read) _load();
  }

  Future<void> _load() async {
    final key = _key;
    if (key == null) return;
    if (_loadFailed) setState(() => _loadFailed = false);
    try {
      final mine = await EventRegistrationService.forEvent(key);
      if (!mounted) return;
      setState(() {
        _mine = mine;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  /// Places left after someone else registered or cancelled. Kept as it
  /// was when the server cannot be reached.
  Future<void> _refreshInfo() async {
    final key = _key;
    if (key == null) return;
    try {
      final info = await EventRegistrationService.summary(key);
      if (mounted && info != null) setState(() => _info = info);
    } catch (_) {
      // The page keeps what it knew.
    }
  }

  Future<void> _register() async {
    final key = _key;
    if (key == null || _busy) return;
    setState(() => _busy = true);
    try {
      final registration = await EventRegistrationService.register(key);
      if (!mounted) return;
      final info = _info;
      setState(() {
        _mine = registration;
        if (info != null) {
          final count = info.count + 1;
          _info = info.copyWith(count: count, full: info.capacity != null && count >= info.capacity!);
        }
      });
      widget.onRegistered?.call();
      AppDialogs.toast(
        context,
        _t(
          'Nakarehistro ka na. Paaalalahanan ka isang araw bago ang kaganapan.',
          'You are registered. We will remind you the day before.',
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == EventRegistrationService.eventFull) {
        final info = _info;
        if (info != null) setState(() => _info = info.copyWith(full: true));
        unawaited(_refreshInfo());
      } else if (e.code == EventRegistrationService.registrationClosed) {
        setState(() => _closedByServer = true);
      }
      AppDialogs.toast(context, e.message(), success: false);
    } catch (_) {
      if (mounted) AppDialogs.toast(context, _t('Hindi ito natuloy. Subukang muli.', 'That did not go through. Try again.'), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final key = _key;
    if (key == null || _busy) return;
    final sure = await AppDialogs.confirm(
      context,
      title: _t('Kanselahin ang pagpaparehistro?', 'Cancel your registration?'),
      message: _t(
        'Mapupunta sa iba ang iyong puwesto. Maaari kang magparehistro muli habang bukas pa ito at may puwesto pa.',
        'Your place will go to someone else. You can register again while registration is open and there is room.',
      ),
      confirmLabel: _t('Kanselahin', 'Cancel registration'),
      cancelLabel: _t('Huwag na', 'Keep it'),
      danger: true,
    );
    if (!sure || !mounted) return;
    setState(() => _busy = true);
    try {
      await EventRegistrationService.cancel(key);
      if (!mounted) return;
      final info = _info;
      setState(() {
        _mine = null;
        if (info != null) _info = info.copyWith(count: info.count > 0 ? info.count - 1 : 0, full: false);
      });
      AppDialogs.toast(context, _t('Kinansela ang iyong pagpaparehistro.', 'Your registration was cancelled.'));
      unawaited(_refreshInfo());
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } catch (_) {
      if (mounted) AppDialogs.toast(context, _t('Hindi ito natuloy. Subukang muli.', 'That did not go through. Try again.'), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The certificate itself, drawn in the app as the website's certificate
  /// window does (owner, 2026-11-05): the one view My certificates opens too.
  void _openCertificate(EventCertificate certificate) {
    final event = widget.event;
    final shown = certificate.details ??
        ResidentCertificate(
          controlNumber: certificate.controlNumber ?? '',
          source: CertificateSource.event,
          eventKey: event.key,
          eventTitle: event.title,
          date: JsonRead.date(event.date),
          venue: event.venue,
          verifyUrl: certificate.verifyUrl,
        );
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateViewScreen(certificate: shown)));
  }

  void _signIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestrictedFeatureNotice(
          reason: RestrictionReason.guestOnly,
          featureName: _t('Pagpaparehistro sa kaganapan', 'Event registration'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state();
    return state == null
        ? const SizedBox.shrink()
        : Padding(padding: const EdgeInsets.only(top: AppSpacing.lg), child: state);
  }

  Widget? _state() {
    if (_key == null || (_signedIn && !_loaded && !_loadFailed)) return null;
    final now = DateTime.now();
    final past = widget.event.isPast(now);
    final mine = _mine;
    if (mine != null) return _registered(mine, past);

    final info = _info;
    if (info == null || !info.open || past) return null;
    if (_loadFailed) return _couldNotLoad();
    if (_closedByServer || info.closedBy(now)) return _closed(info);
    if (info.isFull) return _full(info);
    return _open(info);
  }

  // ------------------------------------------------------------ states

  Widget _open(EventRegistrationInfo info) {
    final left = info.placesLeft;
    final closes = info.closesAt;
    return _Box(
      key: const Key('event_registration_open'),
      icon: Icons.how_to_reg_outlined,
      tone: _Tone.brand,
      title: _t('Bukas ang pagpaparehistro', 'Registration is open'),
      children: [
        if (left != null)
          _Line(
            _t(
              'May $left pang bakanteng puwesto sa ${info.capacity}',
              left == 1 ? '1 of ${info.capacity} places left' : '$left of ${info.capacity} places left',
            ),
            strong: true,
          )
        else if (info.count > 0)
          _Line(_t('${info.count} na ang nakarehistro', '${info.count} registered so far')),
        if (closes != null) _Line(_t('Bukas hanggang ${dateAndTime(closes)}', 'Open until ${dateAndTime(closes)}')),
        _Line(
          _signedIn
              ? _t(
                  'Magparehistro para maitala ng munisipyo ang iyong pagdalo. Paaalalahanan ka rin isang araw bago ang kaganapan.',
                  'Register so the municipality has a record of your attendance. You will also be reminded the day before.',
                )
              : _t('Kailangan ng account para makapagparehistro.', 'You need an account to register.'),
          muted: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_signedIn)
          AppButton(
            label: _t('Magparehistro', 'Register'),
            icon: Icons.how_to_reg_rounded,
            fullWidth: true,
            loading: _busy,
            onPressed: _busy ? null : _register,
          )
        else
          AppButton(
            label: _t('Mag-sign in para magparehistro', 'Sign in to register'),
            icon: Icons.login_rounded,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: _signIn,
          ),
      ],
    );
  }

  Widget _full(EventRegistrationInfo info) => _Box(
    key: const Key('event_registration_full'),
    icon: Icons.event_busy_outlined,
    tone: _Tone.amber,
    title: _t('Puno na ang kaganapang ito', 'This event is full'),
    children: [
      _Line(
        info.capacity != null
            ? _t(
                'Nakuha na ang lahat ng ${info.capacity} na puwesto. Tingnan muli mamaya kung may mababakante.',
                'All ${info.capacity} places are taken. Check again later in case a place opens up.',
              )
            : _t(
                'Wala nang bakanteng puwesto. Tingnan muli mamaya kung may mababakante.',
                'There are no places left. Check again later in case one opens up.',
              ),
        muted: true,
      ),
    ],
  );

  Widget _closed(EventRegistrationInfo info) {
    final closes = info.closesAt;
    return _Box(
      key: const Key('event_registration_closed'),
      icon: Icons.lock_clock_outlined,
      tone: _Tone.slate,
      title: _t('Sarado na ang pagpaparehistro', 'Registration is closed'),
      children: [
        _Line(
          closes != null && !_closedByServer
              ? _t(
                  'Nagsara ito noong ${dateAndTime(closes)}. Hindi na tumatanggap ng pagpaparehistro para sa kaganapang ito.',
                  'It closed on ${dateAndTime(closes)}. This event is no longer taking registrations.',
                )
              : _t(
                  'Hindi na tumatanggap ng pagpaparehistro para sa kaganapang ito.',
                  'This event is no longer taking registrations.',
                ),
          muted: true,
        ),
      ],
    );
  }

  Widget _couldNotLoad() => _Box(
    key: const Key('event_registration_error'),
    icon: Icons.cloud_off_outlined,
    tone: _Tone.slate,
    title: _t('Pagpaparehistro', 'Registration'),
    children: [
      _Line(_t('Hindi ma-load ang iyong pagpaparehistro.', 'Your registration could not be loaded.'), muted: true),
      const SizedBox(height: AppSpacing.sm),
      AppButton(
        label: _t('Subukang muli', 'Try again'),
        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.secondary,
        fullWidth: true,
        onPressed: _load,
      ),
    ],
  );

  Widget _registered(EventRegistration mine, bool past) {
    final certificate = mine.certificate;
    if (mine.attended == true) {
      return _Box(
        key: const Key('event_registration_attended'),
        icon: Icons.verified_rounded,
        tone: _Tone.emerald,
        title: _t('Dumalo ka', 'You attended'),
        children: [
          if (certificate != null) ...[
            if (certificate.controlNumber != null)
              _Line(_t('Sertipiko blg. ${certificate.controlNumber}', 'Certificate no. ${certificate.controlNumber}')),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: _t('Tingnan ang sertipiko', 'View certificate'),
              icon: Icons.workspace_premium_outlined,
              fullWidth: true,
              onPressed: () => _openCertificate(certificate),
            ),
          ] else
            _Line(
              _t(
                'Kung may sertipiko ang kaganapang ito, aabisuhan ka kapag handa na.',
                'If this event gives certificates, you will be told when yours is ready.',
              ),
              muted: true,
            ),
        ],
      );
    }
    if (past) {
      final notAttended = mine.attended == false;
      return _Box(
        key: const Key('event_registration_past'),
        icon: notAttended ? Icons.event_busy_outlined : Icons.how_to_reg_outlined,
        tone: _Tone.slate,
        title: notAttended
            ? _t('Hindi ka naitalang dumalo', 'You were not recorded as attending')
            : _t('Nakarehistro ka', 'You registered'),
        children: [
          _Line(
            notAttended
                ? _t(
                    'Kung dumalo ka, makipag-ugnayan sa tanggapang nag-ayos ng kaganapan.',
                    'If you did attend, contact the office that held the event.',
                  )
                : _t('Hindi pa naitatala ang pagdalo.', 'Attendance has not been recorded yet.'),
            muted: true,
          ),
        ],
      );
    }
    final registeredAt = mine.registeredAt;
    return _Box(
      key: const Key('event_registration_registered'),
      icon: Icons.check_circle_rounded,
      tone: _Tone.emerald,
      title: _t('Nakarehistro ka', 'You are registered'),
      children: [
        if (registeredAt != null)
          _Line(_t('Nakarehistro noong ${shortDate(registeredAt)}', 'Registered on ${shortDate(registeredAt)}'), muted: true),
        const SizedBox(height: AppSpacing.md),
        Center(child: Text(_t('Iyong code', 'Your code').toUpperCase(), style: AppTypography.eyebrow)),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Semantics(
            label: _t('Iyong code: ${mine.displayCode.split('').join(' ')}', 'Your code: ${mine.displayCode.split('').join(' ')}'),
            excludeSemantics: true,
            child: Text(
              mine.displayCode,
              key: const Key('event_registration_code'),
              style: AppTypography.pageTitle.copyWith(letterSpacing: 3),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.slate200),
            ),
            // The code itself, as staff type it at check-in.
            child: QrImageView(
              data: mine.code,
              size: 148,
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.surface,
              semanticsLabel: _t('QR code ng iyong code', 'QR code of your code'),
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.navy900),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.navy900),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Line(
          _t(
            'Ipakita ang code o QR na ito pagdating mo sa kaganapan para maitala ang iyong pagdalo.',
            'Show this code or QR code when you arrive so your attendance is recorded.',
          ),
          muted: true,
          center: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: _t('Kanselahin ang pagpaparehistro', 'Cancel registration'),
          icon: Icons.event_busy_outlined,
          variant: AppButtonVariant.ghost,
          fullWidth: true,
          loading: _busy,
          onPressed: _busy ? null : _cancel,
        ),
      ],
    );
  }
}

enum _Tone { brand, emerald, amber, slate }

/// One state of the registration, as a card with its icon and heading.
class _Box extends StatelessWidget {
  const _Box({super.key, required this.icon, required this.tone, required this.title, required this.children});

  final IconData icon;
  final _Tone tone;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _Tone.brand => (AppColors.brand50, AppColors.brand600),
      _Tone.emerald => (AppColors.emerald50, AppColors.emerald700),
      _Tone.amber => (AppColors.amber50, AppColors.amber700),
      _Tone.slate => (AppColors.slate100, AppColors.slate600),
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.avatarSm,
                height: AppSizes.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: AppSizes.iconBase, color: fg),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: AppTypography.cardHeading)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text, {this.strong = false, this.muted = false, this.center = false});

  final String text;
  final bool strong;
  final bool muted;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final base = muted ? AppTypography.helper : AppTypography.bodyText;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : null,
        style: strong ? base.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary) : base,
      ),
    );
  }
}
