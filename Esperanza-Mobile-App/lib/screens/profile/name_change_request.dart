import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/citizen_account.dart';
import '../../services/account_privacy_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';

/// A verified resident asks to change their name, with the reason and proof;
/// the barangay checks it and applies it (the website's nameChangeRequest in
/// Edit Profile). One request waits at a time, and the former name stays on
/// record. POST /citizen/data-requests, kind name_change.
class NameChangeRequest extends StatefulWidget {
  const NameChangeRequest({super.key, required this.account});

  final CitizenAccount account;

  /// The website's cap on the proof, a photo or a PDF.
  static const maxProofBytes = 10 * 1024 * 1024;
  static const proofExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf'];

  @override
  State<NameChangeRequest> createState() => _NameChangeRequestState();
}

class _NameChangeRequestState extends State<NameChangeRequest> {
  DataRequest? _pending;
  bool _open = false;
  String? _reason;
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _note = TextEditingController();
  List<int>? _proof;
  String? _proofName;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _first.dispose();
    _middle.dispose();
    _last.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The request still waiting, if there is one.
  Future<void> _load() async {
    try {
      final rows = await AccountPrivacyService.dataRequests();
      if (!mounted) return;
      setState(() => _pending = rows.where((r) => r.openNameChange).firstOrNull);
    } catch (_) {
      // The form still works; the server refuses a second request.
    }
  }

  NameChangeReason? get _chosen => AccountPrivacyService.nameChangeReasons.where((r) => r.key == _reason).firstOrNull;

  String get _proofHint => _chosen?.proof ?? 'Choose the reason first.';

  void _start() {
    _first.text = widget.account.firstName;
    _middle.clear();
    _last.text = widget.account.lastName;
    _note.clear();
    setState(() {
      _reason = null;
      _proof = null;
      _proofName = null;
      _error = null;
      _open = true;
    });
  }

  Future<void> _pick() async {
    setState(() => _error = null);
    final result = await pickDocumentProtected(
      context,
      allowedExtensions: NameChangeRequest.proofExtensions,
      explanation: 'Esperanza needs access to your files so you can attach a photo or PDF of your proof.',
    );
    final file = result?.files.firstOrNull;
    if (file == null || !mounted) return;
    final ext = file.name.split('.').last.toLowerCase();
    if (!NameChangeRequest.proofExtensions.contains(ext) || file.bytes == null) {
      setState(() => _error = 'Attach a photo or a PDF of the document.');
      return;
    }
    if (file.size > NameChangeRequest.maxProofBytes) {
      setState(() => _error = 'The file is larger than 10 MB. Take a smaller photo or scan.');
      return;
    }
    setState(() {
      _proof = file.bytes;
      _proofName = file.name;
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    final first = _first.text.trim();
    final middle = _middle.text.trim();
    final last = _last.text.trim();
    String? error;
    if (_reason == null) {
      error = 'Choose why your name is changing.';
    } else if (first.isEmpty || last.isEmpty) {
      error = 'Enter your new first and last name.';
    } else if ([first, middle, last].where((p) => p.isNotEmpty).join(' ').toLowerCase() ==
        [widget.account.firstName, widget.account.lastName].where((p) => p.isNotEmpty).join(' ').toLowerCase()) {
      error = 'That is the name already on record.';
    } else if (_proof == null) {
      error = 'Attach your proof: $_proofHint';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final row = await AccountPrivacyService.fileNameChange(
        reason: _reason!,
        firstName: first,
        middleName: middle,
        lastName: last,
        note: _note.text,
        proofBytes: _proof!,
        proofName: _proofName!,
      );
      if (!mounted) return;
      setState(() {
        _pending = row;
        _open = false;
        _sending = false;
      });
      AppDialogs.toast(
        context,
        'Name change request ${row.ref} sent. Your barangay office will check your proof and let you know.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // The form keeps what was typed.
      if (e.code == 'NAME_CHANGE_PENDING') _load();
      setState(() {
        _sending = false;
        _error = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = AppTypography.fine.copyWith(color: AppColors.amber700);
    final pending = _pending;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.amber500.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Your account is verified, so your name can't be changed here. If it has changed (for example, you got "
            'married) or it is misspelled, request a change with your proof: your barangay office will check it and '
            'let you know.',
            style: AppTypography.helper.copyWith(color: AppColors.amber700),
          ),
          if (pending != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: AppSizes.iconSm, color: AppColors.amber700),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          [
                            'Waiting for your barangay: ${pending.ref}',
                            if (pending.requestedName != null) '→ ${pending.requestedName}',
                          ].join(' '),
                          style: note.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Sent ${pending.submittedAt == null ? '' : DateFormat('MMM d, y').format(pending.submittedAt!.toLocal())}. '
                          'You can send another once it is answered.',
                          style: note,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!_open && pending == null) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.edit_note_rounded, size: AppSizes.iconSm),
                label: const Text('Request a name change'),
              ),
            ),
          ],
          if (_open) ...[
            const SizedBox(height: AppSpacing.md),
            AppSelectField<String>(
              label: 'Reason',
              value: _reason,
              hintText: 'Choose…',
              options: [for (final r in AccountPrivacyService.nameChangeReasons) r.key],
              labelBuilder: (k) => AccountPrivacyService.nameChangeReasons.firstWhere((r) => r.key == k).label,
              onChanged: (v) => setState(() => _reason = v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'New first name', controller: _first, maxLength: 80),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'New last name', controller: _last, maxLength: 80),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Middle name (optional)', controller: _middle, maxLength: 80),
            const SizedBox(height: AppSpacing.md),
            const FieldLabel('Proof'),
            Text(_proofHint, style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _sending ? null : _pick,
                icon: const Icon(Icons.attach_file_rounded, size: AppSizes.iconSm),
                label: Text(_proofName ?? 'Attach a photo or PDF', overflow: TextOverflow.ellipsis),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: 'Note (optional)', controller: _note, maxLength: 300),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child: Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Free, and no waiting period, but only one request can be waiting at a time. Your former name stays on record.',
              style: note,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: _sending ? 'Sending…' : 'Send request',
                    size: AppButtonSize.sm,
                    loading: _sending,
                    onPressed: _send,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Never mind',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.secondary,
                    onPressed: _sending ? null : () => setState(() => _open = false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
