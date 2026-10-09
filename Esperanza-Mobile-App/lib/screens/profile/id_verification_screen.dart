import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/id_verification.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';
import '../../models/identity_status.dart';
import '../../widgets/identity_status_panel.dart';
import '../../services/identity_capture.dart';

/// Valid ID verification after sign-up: the ID the LGU is checking, the
/// officer's reason when it was not accepted, and sending a new one. The
/// web portal's Profile has had this ("Verify ID" / "Send a new ID"); on the
/// phone the ID could only be sent once, during registration, so a resident
/// whose ID was rejected had no way to see why or to fix it.
///
/// Sending is offered only where the server takes it: an account that is
/// Pending Review or Rejected, with no ID still waiting for an officer
/// ([IdVerificationView.canSendNew]) - or one whose identity check failed or
/// was revoked, which only new photos can fix.
///
/// Every ID sent is checked automatically (document, face match, liveness;
/// esperanza-backend IdentityVerification). The check runs after the upload
/// is answered, so the screen polls until it settles and shows the outcome.
/// It is the IDENTITY result only; residency stays the officer's decision.
class IdVerificationScreen extends StatefulWidget {
  const IdVerificationScreen({super.key});

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  IdVerificationView? _view;
  String? _loadError;
  bool _sending = false;
  String? _sendError;
  String? _idType;
  _Picked? _front;
  _Picked? _back;
  _Picked? _selfie;
  bool _checking = false;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final view = await context.read<CitizenSessionService>().idVerification();
      if (!mounted) return;
      setState(() {
        _view = view;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.explain());
    }
  }

  /// Didit's capture screen (identity_capture = hosted): the ID scan and the
  /// face check happen there; the result shown is the one the server reads
  /// from Didit afterwards.
  Future<void> _verifyOnDidit() async {
    setState(() {
      _launching = true;
      _sendError = null;
    });
    try {
      final r = await IdentityCapture.verifyOnDidit();
      if (!mounted) return;
      if (r.view != null) setState(() => _view = r.view);
      if (r.launch.outcome == DiditLaunchOutcome.cancelled) {
        AppDialogs.toast(context, 'Verification closed before it finished. You can start again any time.', success: false);
      } else if (r.launch.outcome == DiditLaunchOutcome.failed && r.launch.error == 'cameraAccessDenied') {
        setState(() => _sendError = 'Esperanza needs your camera for the ID scan and face check. Allow camera access in Settings, then try again.');
      }
      await _awaitCheck();
    } on ApiException catch (e) {
      if (mounted) setState(() => _sendError = e.explain());
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  /// Polls while the automated check runs (seconds when the provider is up).
  /// Gives up quietly after [attempts]: the status says Pending and the
  /// resident is told it will be checked shortly; nothing is lost.
  Future<void> _awaitCheck({int attempts = 12, Duration every = const Duration(seconds: 2)}) async {
    if (!(_view?.identity.awaitingCheck ?? false)) return;
    setState(() => _checking = true);
    try {
      for (var i = 0; i < attempts && mounted; i++) {
        await Future<void>.delayed(every);
        if (!mounted) return;
        try {
          final view = await context.read<CitizenSessionService>().idVerification();
          if (!mounted) return;
          setState(() => _view = view);
          if (!view.identity.awaitingCheck) break;
        } on ApiException {
          // A dropped connection mid-poll: keep the last view and try again.
        }
      }
      if (mounted) await context.read<CitizenSessionService>().refresh().catchError((_) {});
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<_Picked?> _pickIdSide(String side) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.brand600),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: AppColors.brand600),
              title: const Text('Choose Image or PDF'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return null;
    if (choice == 'camera') {
      final file = await pickImageProtected(
        context,
        source: ImageSource.camera,
        maxDimension: 1600,
        explanation: 'Esperanza needs your camera to photograph the $side of your valid ID. The LGU uses it to verify your account.',
      );
      if (file == null) return null;
      return _Picked(path: file.path, name: file.name, bytes: await file.readAsBytes());
    }
    if (!mounted) return null;
    final result = await pickDocumentProtected(
      context,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
      explanation: 'Esperanza needs to let you choose a photo or scan of your valid ID. The LGU uses it to verify your account.',
    );
    final f = result?.files.single;
    if (f == null || f.path == null) return null;
    return _Picked(path: f.path!, name: f.name);
  }

  Future<void> _takeSelfie() async {
    final file = await pickImageProtected(
      context,
      source: ImageSource.camera,
      preferredCamera: CameraDevice.front,
      maxDimension: 1280,
      explanation: 'Esperanza needs your camera to take a selfie. The LGU compares it with your valid ID to verify your account.',
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _selfie = _Picked(path: file.path, name: file.name, bytes: bytes));
  }

  Future<void> _send() async {
    if (_idType == null || _front == null || _selfie == null) {
      setState(
        () => _sendError = _idType == null
            ? 'Choose the type of ID.'
            : _front == null
            ? 'Add the front of your ID.'
            // The face match and liveness check need it (2026-10-09).
            : 'Take a selfie with the camera.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _sendError = null;
    });
    try {
      final view = await context.read<CitizenSessionService>().submitVerificationId(
        idType: _idType!,
        frontPath: _front!.path,
        backPath: _back?.path,
        selfiePath: _selfie?.path,
      );
      if (!mounted) return;
      setState(() {
        _view = view;
        _idType = null;
        _front = null;
        _back = null;
        _selfie = null;
      });
      AppDialogs.toast(context, 'Valid ID sent. Checking your ID and selfie now.');
      await _awaitCheck();
    } on ApiException catch (e) {
      if (mounted) setState(() => _sendError = e.explain());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    return Scaffold(
      appBar: AppBar(title: const Text('Valid ID Verification')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.lg, AppSpacing.screenGutter, AppSpacing.scrollEnd),
            children: [
              if (view == null && _loadError == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (view == null) ...[
                Text(_loadError!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
                const SizedBox(height: AppSpacing.md),
                AppButton(label: 'Try again', variant: AppButtonVariant.secondary, onPressed: _load),
              ] else ...[
                if (view.identity.status != null) ...[
                  _IdentityCard(identity: view.identity, checking: _checking),
                  const SizedBox(height: AppSpacing.md),
                ],
                _SubmissionCard(submission: view.submission, identityVerified: view.identity.status == IdentityStatus.verified),
                const SizedBox(height: AppSpacing.xl),
                if (view.canSendNew && view.onDidit)
                  ..._diditStart(view)
                else if (view.canSendNew)
                  ..._sendForm(view)
                else
                  Text(_whyNoSend(view), style: AppTypography.helper),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _whyNoSend(IdVerificationView view) {
    if (view.identity.status == IdentityStatus.requiresReview) {
      return 'LGU staff will review your ID and selfie. You will be notified when it is reviewed.';
    }
    if (view.submission?.isPending ?? false) {
      return 'An officer is checking the ID you sent. You will be notified when it is reviewed.';
    }
    return 'Your account does not need a valid ID now.';
  }

  List<Widget> _diditStart(IdVerificationView view) => [
    Text(
      (view.submission?.isRejected ?? false) || (view.identity.status?.residentCanResend ?? false) ? 'Verify Again' : 'Verify Your Identity',
      style: AppTypography.sectionTitle,
    ),
    const SizedBox(height: AppSpacing.xs),
    const Text(
      'Have your valid ID ready. You will scan it with your camera, then do a quick face check. It takes about 2 minutes. '
      'The check is done by Didit, our identity verification provider.',
      style: AppTypography.helper,
    ),
    if (_sendError != null) ...[
      const SizedBox(height: AppSpacing.sm),
      Text(_sendError!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
    ],
    const SizedBox(height: AppSpacing.xl),
    AppButton(
      label: 'Start Verification',
      icon: Icons.document_scanner_outlined,
      fullWidth: true,
      size: AppButtonSize.lg,
      loading: _launching,
      onPressed: _launching || _checking ? null : _verifyOnDidit,
    ),
  ];

  List<Widget> _sendForm(IdVerificationView view) => [
    Text(
      (view.submission?.isRejected ?? false) || (view.identity.status?.residentCanResend ?? false) ? 'Send a New ID' : 'Verify Your ID',
      style: AppTypography.sectionTitle,
    ),
    const SizedBox(height: AppSpacing.xs),
    const Text(
      'Any valid government-issued ID, and a selfie taken now with the camera. Your selfie is compared with the photo on your ID to confirm it is you.',
      style: AppTypography.helper,
    ),
    const SizedBox(height: AppSpacing.lg),
    DropdownButtonFormField<String>(
      initialValue: _idType,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Type of ID'),
      items: [for (final t in view.idTypes) DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))],
      onChanged: _sending ? null : (v) => setState(() => _idType = v),
    ),
    const SizedBox(height: AppSpacing.lg),
    _FileRow(
      label: 'Front of ID',
      picked: _front,
      onPick: _sending ? null : () async {
        final p = await _pickIdSide('front');
        if (p != null && mounted) setState(() => _front = p);
      },
    ),
    _FileRow(
      label: 'Back of ID (optional)',
      picked: _back,
      onPick: _sending ? null : () async {
        final p = await _pickIdSide('back');
        if (p != null && mounted) setState(() => _back = p);
      },
    ),
    _FileRow(label: 'Selfie', picked: _selfie, onPick: _sending ? null : _takeSelfie, camera: true),
    if (_sendError != null) ...[
      const SizedBox(height: AppSpacing.sm),
      Text(_sendError!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
    ],
    const SizedBox(height: AppSpacing.xl),
    AppButton(label: 'Send for Verification', fullWidth: true, size: AppButtonSize.lg, loading: _sending, onPressed: _sending ? null : _send),
  ];
}

/// The identity status of the latest ID sent, with what to fix when the
/// check failed. Separate from the ID record's own review below it.
class _IdentityCard extends StatelessWidget {
  final IdentityState identity;
  final bool checking;
  const _IdentityCard({required this.identity, required this.checking});

  @override
  Widget build(BuildContext context) {
    final status = identity.status!;
    final reasons = [for (final r in identity.reasons) ?identityReasonText(r)];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identity check', style: AppTypography.labelText),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              IdentityStatusPill(status: status),
              if (checking && status.awaitingCheck) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: AppSpacing.xs),
                const Flexible(child: Text('Checking your ID…', style: AppTypography.fine)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(status.explanation, style: AppTypography.helper),
          for (final r in reasons) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('• $r', style: AppTypography.helper.copyWith(color: AppColors.rose700)),
          ],
        ],
      ),
    );
  }
}

class _Picked {
  final String path;
  final String name;
  final Uint8List? bytes;
  const _Picked({required this.path, required this.name, this.bytes});
}

class _SubmissionCard extends StatelessWidget {
  final IdSubmission? submission;

  /// Once the identity is verified, what waits is the residency decision.
  final bool identityVerified;
  const _SubmissionCard({required this.submission, this.identityVerified = false});

  @override
  Widget build(BuildContext context) {
    final s = submission;
    if (s == null) {
      return const AppCard(child: Text('You have not sent a valid ID yet.', style: AppTypography.helper));
    }
    final (color, line) = s.isAccepted
        ? (AppColors.emerald700, 'Accepted')
        : s.isRejected
        ? (AppColors.rose700, 'Not accepted${s.remarks != null ? ': ${s.remarks}' : ''}')
        : s.isPending && identityVerified
        ? (AppColors.orange700, 'Identity confirmed. Waiting for the LGU to approve your residency')
        : s.isPending
        ? (AppColors.orange700, 'Waiting for the LGU to check it')
        : (AppColors.slate600, s.status);
    final date = DateFormat('MMM d, y');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Latest ID sent', style: AppTypography.labelText),
          const SizedBox(height: AppSpacing.xs),
          Text(s.idType, style: AppTypography.cardHeading),
          if (s.submittedAt != null) Text('Sent ${date.format(s.submittedAt!.toLocal())}', style: AppTypography.fine),
          const SizedBox(height: AppSpacing.sm),
          Text(line, style: AppTypography.helper.copyWith(color: color, fontWeight: FontWeight.w600)),
          if (s.reviewedAt != null && !s.isPending)
            Text('Reviewed ${date.format(s.reviewedAt!.toLocal())}', style: AppTypography.fine),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final String label;
  final _Picked? picked;
  final VoidCallback? onPick;
  final bool camera;
  const _FileRow({required this.label, required this.picked, required this.onPick, this.camera = false});

  @override
  Widget build(BuildContext context) {
    final p = picked;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: p?.bytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.memory(p!.bytes!, width: 44, height: 44, fit: BoxFit.cover, semanticLabel: label),
            )
          : Icon(
              p != null ? Icons.check_circle_rounded : (camera ? Icons.face_retouching_natural_rounded : Icons.badge_outlined),
              color: p != null ? AppColors.emerald700 : AppColors.brand500,
            ),
      title: Text(label, style: AppTypography.bodyText),
      subtitle: p != null ? Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.fine) : null,
      trailing: TextButton(onPressed: onPick, child: Text(p != null ? 'Change' : (camera ? 'Take' : 'Add'))),
    );
  }
}
