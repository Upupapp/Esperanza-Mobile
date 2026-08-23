import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/onboarding_step_indicator.dart';
import '../../widgets/verification_status_panel.dart';

/// Citizen registration, restructured (Section 9) from one long form into
/// a step-by-step wizard: Personal Information -> Terms & Conditions ->
/// Valid ID Upload -> Face Verification -> Review -> Verification Status.
/// Every step is frontend simulation — "Verification" is instantly
/// simulated the same way it always was in this app (status set to
/// 'Pending Review', reviewable via the demo panel), just now with a
/// proper guided flow instead of one screen with every field on it.
///
/// If a citizen already has an account (Section 7 — don't force them
/// through registration again just because they aren't verified yet),
/// opening this screen jumps straight to the final Verification Status
/// step showing their real status.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepLabels = [
    'Personal Information',
    'Terms & Conditions',
    'Valid ID Upload',
    'Face Verification',
    'Review',
    'Verification Status',
  ];

  late int _step;
  late final bool _alreadyHasAccount;

  // Step 0 — Personal Information
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _purok = TextEditingController();
  String? _barangay;

  // Step 1 — Terms & Conditions
  bool _termsAccepted = false;

  // Step 2 — Valid ID Upload
  String? _idFileName;
  String? _idFilePath;

  // Step 3 — Face Verification (simulated — no real camera/ML)
  bool _faceScanCompleted = false;
  bool _faceScanning = false;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account;
    _alreadyHasAccount = account != null;
    _step = _alreadyHasAccount ? 5 : 0;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _mobile, _purok]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      if (_step < _stepLabels.length - 1) _step++;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _step--;
    });
  }

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
          return 'Please enter your first and last name.';
        }
        if (_email.text.trim().isEmpty) return 'Please enter your email address.';
        if (_barangay == null) return 'Please select your barangay.';
        return null;
      case 1:
        if (!_termsAccepted) return 'Please accept the Terms & Conditions to continue.';
        return null;
      case 2:
        if (_idFilePath == null) return 'Please upload a valid ID to continue.';
        return null;
      case 3:
        if (!_faceScanCompleted) return 'Please complete the face verification step to continue.';
        return null;
      default:
        return null;
    }
  }

  Future<void> _pickId() async {
    final result = await pickDocumentProtected(
      context,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.path == null) return;
    setState(() {
      _idFilePath = f.path;
      _idFileName = f.name;
      _error = null;
    });
  }

  Future<void> _runFaceScan() async {
    setState(() => _faceScanning = true);
    await Future.delayed(const Duration(milliseconds: 1200)); // simulated scan
    if (!mounted) return;
    setState(() {
      _faceScanning = false;
      _faceScanCompleted = true;
      _error = null;
    });
  }

  Future<void> _submitForVerification() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final account = CitizenAccount(
      id: 'ESP-RES-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}',
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      mobile: _mobile.text.trim(),
      barangay: _barangay!,
      purok: _purok.text.trim().isEmpty ? '—' : _purok.text.trim(),
      address: '${_purok.text.trim()}, Barangay $_barangay, Esperanza, Masbate',
      birthdate: '—',
      sex: '—',
      civilStatus: '—',
      occupation: '—',
      profileCompleteness: 35,
      status: AppStatus.pendingReview.label,
    );

    await context.read<CitizenSessionService>().login(account);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _step = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = !(_alreadyHasAccount && _step == 5);
    return Scaffold(
      appBar: AppBar(title: Text(_step == 5 ? 'Verification Status' : 'Create your account')),
      body: SafeArea(
        child: Column(
          children: [
            if (showIndicator)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: OnboardingStepIndicator(currentStep: _step, stepLabels: _stepLabels),
              ),
            Expanded(
              child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: _buildStep()),
            ),
            if (_step < 5)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: AppButton(
                          label: 'Back',
                          variant: AppButtonVariant.secondary,
                          fullWidth: true,
                          onPressed: _back,
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: _step == 4 ? 'Submit for Verification' : 'Continue',
                        icon: _step == 4 ? null : Icons.arrow_forward_rounded,
                        iconTrailing: true,
                        fullWidth: true,
                        loading: _submitting,
                        onPressed: _step == 4 ? _submitForVerification : _next,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _personalInfoStep();
      case 1:
        return _termsStep();
      case 2:
        return _idUploadStep();
      case 3:
        return _faceScanStep();
      case 4:
        return _reviewStep();
      default:
        return _verificationStatusStep();
    }
  }

  Widget _personalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.brand600, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Let's start with your basic information. You can complete your full Resident Profile later.",
                  style: TextStyle(fontSize: 12, color: AppColors.brand700, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppTextField(label: 'First name', controller: _firstName),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(label: 'Last name', controller: _lastName),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Email address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Mobile number',
          controller: _mobile,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
          hintText: '09XX XXX XXXX',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSelectField<String>(
          label: 'Barangay',
          value: _barangay,
          options: MockCatalog.barangays,
          labelBuilder: (b) => b,
          onChanged: (v) => setState(() => _barangay = v),
          hintText: 'Select your barangay',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Purok / Sitio', controller: _purok, icon: Icons.place_outlined),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _termsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Terms & Conditions',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'By creating an Esperanza account, you agree to provide accurate information for barangay/municipal record-keeping. '
            'Your data is used only for LGU service delivery (document requests, assistance programs, resident records) and is '
            'not shared with third parties. Esperanza LGU staff may contact you to verify submitted information. False or '
            'misleading information may result in your verification being rejected.\n\n'
            'This is a frontend demo build — no data leaves your device.',
            style: TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.5),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        InkWell(
          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  activeColor: AppColors.brand500,
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'I have read and agree to the Terms & Conditions and Privacy Policy.',
                      style: TextStyle(fontSize: 13, color: AppColors.slate700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _idUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Valid ID Upload',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Upload a photo or scan of any valid government-issued ID. This helps Esperanza LGU verify your identity.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_idFilePath != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.emerald700, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _idFileName ?? 'ID uploaded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.emerald700),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _idFilePath = null;
                    _idFileName = null;
                  }),
                  child: const Text('Change'),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _pickId,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.brand200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.badge_outlined, color: AppColors.brand500, size: 30),
                  SizedBox(height: 10),
                  Text(
                    'Upload Valid ID',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.brand600),
                  ),
                  SizedBox(height: 2),
                  Text('JPG, PNG, or PDF', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _faceScanStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Face Verification',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'We\'ll match a quick face scan against your uploaded ID to help confirm it\'s really you.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _faceScanCompleted ? AppColors.emerald50 : AppColors.slate100,
              border: Border.all(color: _faceScanCompleted ? AppColors.emerald500 : AppColors.slate300, width: 2),
            ),
            child: _faceScanning
                ? const CircularProgressIndicator(color: AppColors.brand500)
                : Icon(
                    _faceScanCompleted ? Icons.check_circle_rounded : Icons.face_retouching_natural_rounded,
                    size: 56,
                    color: _faceScanCompleted ? AppColors.emerald700 : AppColors.slate400,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: _faceScanCompleted ? 'Face Scan Completed' : 'Start Face Scan',
          icon: _faceScanCompleted ? Icons.check_rounded : Icons.camera_alt_outlined,
          variant: _faceScanCompleted ? AppButtonVariant.secondary : AppButtonVariant.primary,
          fullWidth: true,
          loading: _faceScanning,
          onPressed: _faceScanCompleted ? null : _runFaceScan,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Frontend simulation — no camera access or facial data is actually captured in this demo build.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.rose600),
          ),
        ],
      ],
    );
  }

  Widget _reviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Review Your Information',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Make sure everything looks correct before submitting for verification.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        _reviewRow(
          'Name',
          '${_firstName.text.trim()} ${_lastName.text.trim()}',
          onEdit: () => setState(() => _step = 0),
        ),
        _reviewRow('Email', _email.text.trim(), onEdit: () => setState(() => _step = 0)),
        _reviewRow(
          'Mobile',
          _mobile.text.trim().isEmpty ? '—' : _mobile.text.trim(),
          onEdit: () => setState(() => _step = 0),
        ),
        _reviewRow('Barangay', _barangay ?? '—', onEdit: () => setState(() => _step = 0)),
        _reviewRow(
          'Terms & Conditions',
          _termsAccepted ? 'Accepted' : 'Not accepted',
          onEdit: () => setState(() => _step = 1),
        ),
        _reviewRow('Valid ID', _idFileName ?? '—', onEdit: () => setState(() => _step = 2)),
        _reviewRow(
          'Face Verification',
          _faceScanCompleted ? 'Completed' : 'Not completed',
          onEdit: () => setState(() => _step = 3),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _reviewRow(String label, String value, {required VoidCallback onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.slate700),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Text(
              'Edit',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationStatusStep() {
    final account = context.watch<CitizenSessionService>().account!;
    final status = AppStatusX.fromLabel(account.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: status.style.background, shape: BoxShape.circle),
            child: Icon(
              status == AppStatus.approved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              size: 34,
              color: status.style.foreground,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _alreadyHasAccount ? 'Your Verification Status' : 'You\'re All Set!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (!_alreadyHasAccount)
          const Text(
            'Your information has been submitted to Esperanza LGU for verification.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
          ),
        const SizedBox(height: AppSpacing.xl),
        VerificationStatusPanel(status: status),
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: 'Continue to App',
          icon: Icons.arrow_forward_rounded,
          iconTrailing: true,
          fullWidth: true,
          size: AppButtonSize.lg,
          // Pop back to the root route instead of pushing a fresh
          // RootShell.withKey() — the root route is _AuthGate (main.dart),
          // which already reacted to the login() call above and is
          // already showing RootShell on its own. Pushing a *second*
          // RootShell.withKey() here would either collide with that one
          // over RootShell's single static GlobalKey, or (via
          // pushAndRemoveUntil's route removal) tear _AuthGate itself out
          // of the navigator stack — after which no future login()/
          // logout() has anything left to react to, leaving the app stuck
          // on whatever screen was showing. This was the root cause of
          // "Ronaldo/Cristy no longer opening" after using this button
          // or the drawer's Sign In from Guest mode.
          onPressed: () => Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}
