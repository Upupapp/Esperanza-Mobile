import 'package:flutter/material.dart';

import '../../services/account_privacy_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/password_standard.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/password_requirements.dart';

/// Change password, against PUT /citizen/password. The new password is held
/// to the same standard as sign-up ([PasswordStandard], the mobile copy of
/// the backend's StrongPassword rule), checked while typing.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _currentError;
  String? _passwordError;
  String? _confirmError;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _validate() {
    final current = _current.text;
    final password = _password.text;
    setState(() {
      _currentError = current.isEmpty ? 'Enter your current password.' : null;
      final unmet = PasswordStandard.unmetMessages(password);
      _passwordError = unmet.isNotEmpty
          ? unmet.first
          : (password == current ? 'Choose a password different from your current one.' : null);
      _confirmError = _confirm.text != password ? 'The two new passwords do not match.' : null;
      _error = null;
    });
    return _currentError == null && _passwordError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      await AccountPrivacyService.changePassword(current: _current.text, password: _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed. Any other phone or browser signed in to your account was signed out.'),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        final wrongCurrent = e.fields.containsKey('current_password');
        final passwordField = e.fields['password'];
        _currentError = wrongCurrent ? 'That is not your current password.' : null;
        _passwordError = passwordField != null && passwordField.isNotEmpty ? passwordField.first : null;
        _error = wrongCurrent || _passwordError != null ? null : e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.lg,
            AppSpacing.screenGutter,
            AppSpacing.scrollEnd,
          ),
          children: [
            const Text(
              'After you change it, any other phone or browser signed in to your account will be signed out. '
              'This phone stays signed in.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Current password',
              controller: _current,
              obscureText: true,
              icon: Icons.lock_outline_rounded,
              error: _currentError,
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            AppTextField(
              label: 'New password',
              controller: _password,
              obscureText: true,
              icon: Icons.lock_reset_rounded,
              error: _passwordError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            PasswordRequirements(password: _password.text),
            const SizedBox(height: AppSpacing.fieldGap),
            AppTextField(
              label: 'Confirm new password',
              controller: _confirm,
              obscureText: true,
              icon: Icons.lock_reset_rounded,
              error: _confirmError,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Change Password',
              fullWidth: true,
              size: AppButtonSize.lg,
              loading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
