import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/account_privacy_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/password_standard.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/password_requirements.dart';

import '../../l10n/tr.dart';
enum _Step { request, reset, done }

/// Forgot password, the web portal's /citizen/password-reset on the phone:
/// the resident's ID, email or mobile, then the 6-digit code sent to the
/// contact they proved, and a new password held to the sign-up standard.
/// The server never says whether the account exists (the same answer
/// either way), so neither does this screen.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialIdentifier;
  const ForgotPasswordScreen({super.key, this.initialIdentifier});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _identifier = TextEditingController(text: widget.initialIdentifier ?? '');
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _Step _step = _Step.request;
  bool _loading = false;
  String? _error;
  String? _codeError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (_identifier.text.trim().isEmpty) {
      setState(() => _error = 'Enter your resident ID, email, or mobile number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AccountPrivacyService.requestPasswordReset(_identifier.text);
      if (!mounted) return;
      setState(() => _step = _Step.reset);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.explain());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    final password = _password.text;
    final unmet = PasswordStandard.unmetMessages(password);
    setState(() {
      _codeError = _code.text.trim().length != 6 ? 'Enter the 6-digit code.' : null;
      _passwordError = unmet.isNotEmpty ? unmet.first : null;
      _confirmError = _confirm.text != password ? 'The two passwords do not match.' : null;
      _error = null;
    });
    if (_codeError != null || _passwordError != null || _confirmError != null) return;
    setState(() => _loading = true);
    try {
      await AccountPrivacyService.resetPassword(identifier: _identifier.text, code: _code.text, password: password);
      if (!mounted) return;
      setState(() => _step = _Step.done);
    } on ApiException catch (e) {
      if (!mounted) return;
      final passwordField = e.fields['password'];
      setState(() {
        _passwordError = passwordField != null && passwordField.isNotEmpty ? passwordField.first : null;
        _error = _passwordError != null ? null : e.explain();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenGutter, AppSpacing.lg, AppSpacing.screenGutter, AppSpacing.scrollEnd),
          children: switch (_step) {
            _Step.request => _requestStep(),
            _Step.reset => _resetStep(),
            _Step.done => _doneStep(),
          },
        ),
      ),
    );
  }

  List<Widget> _requestStep() => [
    const Text(
      'Enter your resident ID, email, or mobile number. If the account is verified, we send a 6-digit code to the '
      'contact you confirmed when you registered.',
      style: AppTypography.helper,
    ),
    const SizedBox(height: AppSpacing.xl),
    AppTextField(
      label: 'Resident ID, email, or mobile',
      hintText: 'ESP-RES-2026-000123',
      icon: Icons.person_outline_rounded,
      controller: _identifier,
      keyboardType: TextInputType.emailAddress,
    ),
    ..._errorLine(),
    const SizedBox(height: AppSpacing.xxl),
    AppButton(label: 'Send Code', fullWidth: true, size: AppButtonSize.lg, loading: _loading, onPressed: _loading ? null : _requestCode),
  ];

  List<Widget> _resetStep() => [
    Text(
      'If ${_identifier.text.trim()} belongs to a verified account, a 6-digit code is on its way. Enter it with your new '
      'password. Every phone and browser signed in to the account will be signed out.',
      style: AppTypography.helper,
    ),
    const SizedBox(height: AppSpacing.xl),
    AppTextField(
      label: 'Verification code',
      hintText: '123456',
      icon: Icons.pin_outlined,
      controller: _code,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      error: _codeError,
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
    ..._errorLine(),
    const SizedBox(height: AppSpacing.xxl),
    AppButton(label: 'Reset Password', fullWidth: true, size: AppButtonSize.lg, loading: _loading, onPressed: _loading ? null : _reset),
    const SizedBox(height: AppSpacing.sm),
    AppButton(
      label: 'Send a new code',
      variant: AppButtonVariant.ghost,
      fullWidth: true,
      onPressed: _loading ? null : _requestCode,
    ),
  ];

  List<Widget> _doneStep() => [
    const Icon(Icons.check_circle_rounded, size: 56, color: AppColors.emerald500),
    const SizedBox(height: AppSpacing.lg),
    Text(tr('Password reset'), textAlign: TextAlign.center, style: AppTypography.sectionTitle),
    const SizedBox(height: AppSpacing.sm),
    const Text(
      'Sign in with your new password.',
      textAlign: TextAlign.center,
      style: AppTypography.helper,
    ),
    const SizedBox(height: AppSpacing.xxl),
    AppButton(label: tr('Back to Sign In'), fullWidth: true, size: AppButtonSize.lg, onPressed: () => Navigator.of(context).pop()),
  ];

  List<Widget> _errorLine() => [
    if (_error != null) ...[
      const SizedBox(height: AppSpacing.md),
      Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
    ],
  ];
}
