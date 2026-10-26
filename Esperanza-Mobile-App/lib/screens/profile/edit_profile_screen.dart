import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/citizen_account.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/barangay_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/ph_mobile.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../theme/app_typography.dart';
import 'name_change_request.dart';

import '../../l10n/tr.dart';
/// Edit Profile, as the website's: before verification the resident types
/// their own first and last name; once verified the name is locked, and a
/// change goes to the barangay as a request with the reason and proof
/// ([NameChangeRequest]).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final CitizenAccount _original;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _mobile;
  late final TextEditingController _occupation;
  late final TextEditingController _address;
  late String _barangay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _original = context.read<CitizenSessionService>().account!;
    _firstName = TextEditingController(text: _original.firstName);
    _lastName = TextEditingController(text: _original.lastName);
    _mobile = TextEditingController(text: PhMobile.normalise(_original.mobile));
    _occupation = TextEditingController(text: _original.occupation == '—' ? '' : _original.occupation);
    _address = TextEditingController(text: _original.address == '—' ? '' : _original.address);
    _barangay = _original.barangay;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _mobile.dispose();
    _occupation.dispose();
    _address.dispose();
    super.dispose();
  }

  String? _error;

  /// Saves through the backend (PUT /citizen/profile). A new mobile number
  /// is not a plain field there: it is verified by a code sent to the new
  /// number first (POST /citizen/profile/contact, then .../verify), so the
  /// number changes only once the citizen proves they hold it.
  Future<void> _save() async {
    final session = context.read<CitizenSessionService>();
    String? blankToNull(String v) => v.trim().isEmpty ? null : v.trim();
    String orig(String v) => v == '—' ? '' : v;

    final changes = <String, dynamic>{};
    if (!session.identityLocked) {
      final first = _firstName.text.trim();
      final last = _lastName.text.trim();
      if (first.isEmpty || last.isEmpty) {
        setState(() => _error = 'Enter your first and last name.');
        return;
      }
      if (first != _original.firstName.trim()) changes['first_name'] = first;
      if (last != _original.lastName.trim()) changes['last_name'] = last;
    }
    // The whole address as typed, as the website edits it: it kept a purok
    // and rebuilt the address, overwriting one typed on the website
    // (parity check, 2026-10-26). Barangay goes on its own.
    if (_address.text.trim() != orig(_original.address).trim()) changes['address'] = blankToNull(_address.text);
    if (_occupation.text.trim() != orig(_original.occupation).trim()) {
      changes['occupation'] = blankToNull(_occupation.text);
    }
    if (!session.identityLocked && _barangay != _original.barangay) changes['barangay'] = _barangay;
    final newMobile = _mobile.text.trim();
    final mobileChanged = newMobile.isNotEmpty && newMobile != PhMobile.normalise(_original.mobile.trim());
    final mobileError = mobileChanged ? PhMobile.validate(newMobile) : null;
    if (mobileError != null) {
      setState(() => _error = mobileError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await session.saveProfile(changes);
      if (mobileChanged) {
        final destination = await session.requestContactChange(channel: 'mobile', value: newMobile);
        if (!mounted) return;
        final verified = await _confirmCode(session, destination ?? newMobile);
        if (!mounted) return;
        if (!verified) {
          setState(() => _saving = false);
          AppDialogs.toast(
            context,
            changes.isEmpty ? 'Mobile number not changed.' : 'Profile saved. Mobile number not changed.',
            success: false,
          );
          return;
        }
      }
      if (!mounted) return;
      setState(() => _saving = false);
      AppDialogs.toast(context, tr('Profile updated.'));
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message();
      });
    }
  }

  /// Asks for the 6-digit code sent to [destination]; true once verified.
  Future<bool> _confirmCode(CitizenSessionService session, String destination) async {
    final code = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Verify your new number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter the 6-digit code sent to $destination.', style: AppTypography.helper),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(hintText: '000000', errorText: error, counterText: ''),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr('Cancel'))),
            FilledButton(
              onPressed: () async {
                try {
                  await session.verifyContactChange(code.text.trim());
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } on ApiException catch (e) {
                  setLocal(() => error = e.message());
                }
              },
              child: Text(tr('Verify')),
            ),
          ],
        ),
      ),
    );
    code.dispose();
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Edit Profile'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter, vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (context.watch<CitizenSessionService>().identityLocked) ...[
                _LockedField(
                  label: tr('Full name'),
                  value: _original.fullName,
                  note: 'Verified accounts change their name through the barangay office.',
                ),
                const SizedBox(height: AppSpacing.md),
                NameChangeRequest(account: _original),
              ] else ...[
                AppTextField(label: 'First name', controller: _firstName, maxLength: 100),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: 'Last name', controller: _lastName, maxLength: 100),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: tr('Mobile number'),
                controller: _mobile,
                keyboardType: TextInputType.phone,
                inputFormatters: PhMobile.inputFormatters,
                icon: Icons.phone_outlined,
                hintText: PhMobile.hint,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (context.watch<CitizenSessionService>().identityLocked)
                // A verified account's barangay is corrected by the barangay
                // office (the server refuses it with IDENTITY_LOCKED).
                _LockedField(
                  label: 'Barangay',
                  value: _barangay,
                  note: 'Verified accounts update their barangay through the barangay office.',
                )
              else
                AppSelectField<String>(
                  label: 'Barangay',
                  value: _barangay,
                  options: BarangayService.names,
                  labelBuilder: (b) => b,
                  onChanged: (v) => setState(() => _barangay = v ?? _barangay),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: tr('Complete address'),
                controller: _address,
                icon: Icons.home_outlined,
                hintText: 'Street / Sitio, Barangay, Esperanza, Masbate',
                maxLength: 255,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: tr('Occupation'), controller: _occupation, icon: Icons.work_outline_rounded),
              const SizedBox(height: AppSpacing.xxl),
              if (_error != null) ...[
                Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
                const SizedBox(height: AppSpacing.md),
              ],
              AppButton(
                label: tr('Save Changes'),
                onPressed: _save,
                loading: _saving,
                fullWidth: true,
                size: AppButtonSize.lg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A value the citizen can see but not change here: the same label, grey
/// box and note for every locked field, so they read as one kind of thing.
class _LockedField extends StatelessWidget {
  const _LockedField({required this.label, required this.value, required this.note});

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      readOnly: true,
      label: label,
      value: value,
      hint: note,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Text(value, style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate500)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(note, style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
