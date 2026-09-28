import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/citizen_account.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../theme/app_typography.dart';

/// "Update/request profile correction" from the Constituent flow (Section
/// 10). Since the Web Admin has no residents API to submit a correction
/// request against yet (see Section 8), this directly updates the local
/// mock profile rather than creating a separate "correction request" —
/// documented as a Web Admin alignment gap for later.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final CitizenAccount _original;
  late final TextEditingController _mobile;
  late final TextEditingController _occupation;
  late final TextEditingController _purok;
  late String _barangay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _original = context.read<CitizenSessionService>().account!;
    _mobile = TextEditingController(text: _original.mobile);
    _occupation = TextEditingController(text: _original.occupation == '—' ? '' : _original.occupation);
    _purok = TextEditingController(text: _original.purok == '—' ? '' : _original.purok);
    _barangay = _original.barangay;
  }

  @override
  void dispose() {
    _mobile.dispose();
    _occupation.dispose();
    _purok.dispose();
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
    if (_purok.text.trim() != orig(_original.purok).trim()) changes['purok'] = blankToNull(_purok.text);
    if (_occupation.text.trim() != orig(_original.occupation).trim()) {
      changes['occupation'] = blankToNull(_occupation.text);
    }
    if (!session.identityLocked && _barangay != _original.barangay) changes['barangay'] = _barangay;
    if (changes.containsKey('purok') || changes.containsKey('barangay')) {
      final purok = _purok.text.trim();
      changes['address'] = [if (purok.isNotEmpty) purok, 'Barangay $_barangay', 'Esperanza, Masbate'].join(', ');
    }
    final newMobile = _mobile.text.trim();
    final mobileChanged = newMobile.isNotEmpty && newMobile != _original.mobile.trim();

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
      AppDialogs.toast(context, 'Profile updated.');
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
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  await session.verifyContactChange(code.text.trim());
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } on ApiException catch (e) {
                  setLocal(() => error = e.message());
                }
              },
              child: const Text('Verify'),
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Full name',
                style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Text(_original.fullName, style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate500)),
              ),
              const _ReadOnlyNote(),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Mobile number',
                controller: _mobile,
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (context.watch<CitizenSessionService>().identityLocked) ...[
                // A verified account's barangay is corrected by the barangay
                // office (the server refuses it with IDENTITY_LOCKED).
                const Text('Barangay', style: AppTypography.labelText),
                const SizedBox(height: AppSpacing.xs),
                Text(_barangay, style: AppTypography.bodyText),
                Text('Verified accounts update their barangay through the barangay office.', style: AppTypography.helper),
              ] else
                AppSelectField<String>(
                  label: 'Barangay',
                  value: _barangay,
                  options: MockCatalog.barangays,
                  labelBuilder: (b) => b,
                  onChanged: (v) => setState(() => _barangay = v ?? _barangay),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Purok / Sitio', controller: _purok, icon: Icons.place_outlined),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: 'Occupation', controller: _occupation, icon: Icons.work_outline_rounded),
              const SizedBox(height: AppSpacing.xxl),
              if (_error != null) ...[
                Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
                const SizedBox(height: AppSpacing.md),
              ],
              AppButton(
                label: 'Save Changes',
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

class _ReadOnlyNote extends StatelessWidget {
  const _ReadOnlyNote();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        'Name and Resident ID are locked — request a correction at your barangay hall if these are incorrect.',
        style: TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
      ),
    );
  }
}
