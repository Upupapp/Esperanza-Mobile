import 'dart:typed_data';
import '../legal/terms_screen.dart';
import '../legal/privacy_policy_screen.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/json_read.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../utils/ph_mobile.dart';
import '../../utils/password_standard.dart';
import '../../utils/protected_action.dart';
import '../../utils/registration_error_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/onboarding_step_indicator.dart';
import '../../widgets/password_requirements.dart';
import '../../widgets/verification_status_panel.dart';
import '../../theme/app_typography.dart';
import '../../widgets/esperanza_art.dart';
import '../../services/identity_capture.dart';
import '../../models/identity_status.dart';
import '../../widgets/identity_status_panel.dart';
import '../../models/citizen_account.dart';

/// Citizen registration, restructured (Section 9) from one long form into
/// a step-by-step wizard: Personal Information -> Terms & Conditions ->
/// Valid ID Upload -> Selfie -> Review -> Verification Status.
/// The account is created on the server (Pending Review) and, once it signs
/// in, the ID and the selfie go to POST /citizen/verification/id, where the
/// officer who verifies the account sees them (backlog B1, 2026-10-04). The
/// face step used to be a timer that "scanned" nothing.
///
/// Identity on Didit's screen (2026-10-09): when the server's
/// identity_capture is `hosted`, the Valid ID and Selfie steps are skipped -
/// Didit's SDK captures both, and it needs the account to exist first. After
/// the account is created the last step offers "Verify your identity" (Didit)
/// or "do it later" from the profile. Either way the account is Unverified
/// until the identity is verified AND the LGU approves residency.
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
    'Selfie',
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
  final _password = TextEditingController();
  final _otpCode = TextEditingController();
  String? _barangay;

  // Step 0 — the email is proven before the account exists: send a code,
  // confirm it, and keep the single-use token registration presents as proof.
  final _emailCode = TextEditingController();
  bool _emailSending = false;
  bool _emailCodeSent = false;
  bool _emailConfirming = false;
  bool _emailVerified = false;
  String? _emailError;
  String? _emailToken;

  // Step 5 — Verification Status: the real account POST /auth/citizen/register
  // created, and the destination it sent the OTP to.
  String? _accountNo;
  String? _otpDestination;

  // Step 1 — Terms & Conditions
  bool _termsAccepted = false;

  // Step 2 — Valid ID Upload. The types are the LGU's list (GET /id-types).
  List<String> _idTypes = const [];
  String? _idType;
  String? _idFileName;
  String? _idFilePath;

  // Step 3 — Selfie, for the officer to compare with the ID.
  String? _selfiePath;
  Uint8List? _selfieBytes;

  // After sign-in: whether the ID and selfie reached the LGU.
  bool _identitySent = false;
  String? _identityError;
  bool _sendingIdentity = false;

  bool _submitting = false;
  String? _error;

  // Identity on Didit's screen: whether the server uses it, and the step's state.
  bool _hosted = false;
  bool _launchingDidit = false;
  bool _checkingDidit = false;
  String? _diditMessage;

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account;
    _alreadyHasAccount = account != null;
    _step = _alreadyHasAccount ? 5 : 0;
    if (!_alreadyHasAccount) _loadIdTypes();
    _loadCaptureMode();
    // What a failed Continue said goes once the form is edited: "Please enter
    // your first and last name" stayed on screen after both were filled in.
    for (final c in [_firstName, _lastName, _email, _mobile, _purok, _password]) {
      c.addListener(_clearStaleError);
    }
  }

  Future<void> _loadCaptureMode() async {
    final mode = await IdentityCapture.mode();
    if (mounted) setState(() => _hosted = mode == IdentityCapture.hosted);
  }

  /// The steps the indicator shows: without Valid ID and Selfie when Didit's
  /// screen captures them after the account exists.
  List<String> get _visibleLabels => _hosted
      ? const ['Personal Information', 'Terms & Conditions', 'Review', 'Verify Identity']
      : _stepLabels;

  int get _visibleStep => !_hosted ? _step : switch (_step) { 0 => 0, 1 => 1, 4 => 2, _ => 3 };

  /// Didit's capture screen, from the last step. The result shown is the one
  /// the server reads from Didit; nothing here decides it.
  Future<void> _verifyOnDidit() async {
    setState(() {
      _launchingDidit = true;
      _diditMessage = null;
    });
    final session = context.read<CitizenSessionService>();
    try {
      final r = await IdentityCapture.verifyOnDidit();
      if (!mounted) return;
      if (r.launch.outcome == DiditLaunchOutcome.cancelled) {
        setState(() => _diditMessage = 'Verification closed before it finished. You can start again now, or later from your profile.');
        return;
      }
      if (r.launch.outcome == DiditLaunchOutcome.failed && r.launch.error == 'cameraAccessDenied') {
        setState(() => _diditMessage = 'Esperanza needs your camera for the ID scan and face check. Allow camera access in Settings, then try again.');
      }
      // Wait briefly for the result if Didit is still finishing it.
      setState(() => _checkingDidit = true);
      var view = r.view;
      for (var i = 0; i < 12 && (view?.identity.awaitingCheck ?? false) && mounted; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        try {
          view = await session.idVerification();
        } on ApiException {
          // A dropped connection mid-wait: keep the last view.
        }
      }
      await session.refresh();
    } on ApiException catch (e) {
      if (mounted) setState(() => _diditMessage = e.explain());
    } finally {
      if (mounted) {
        setState(() {
          _launchingDidit = false;
          _checkingDidit = false;
        });
      }
    }
  }

  void _clearStaleError() {
    if (_error == null && !_attempted) return;
    setState(() => _error = null);
  }

  Future<void> _loadIdTypes() async {
    try {
      final types = await context.read<CitizenSessionService>().idTypes();
      if (mounted) setState(() => _idTypes = types);
    } on ApiException {
      // Offline: the step says it could not load the list and offers a retry.
    }
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _mobile, _purok, _password, _otpCode, _emailCode]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Set by a Continue that found a problem, so empty fields are marked.
  bool _attempted = false;
  final _errorKey = GlobalKey();

  void _next() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() {
        _error = err;
        _attempted = true;
      });
      // The message sits under the form, below the fold on a phone, so
      // Continue seemed to do nothing. Bring it into view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _errorKey.currentContext;
        if (target != null && target.mounted) {
          Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 250), alignment: 0.5);
        }
      });
      return;
    }
    setState(() {
      _error = null;
      _attempted = false;
      // Didit's screen captures the ID and selfie after the account exists.
      if (_hosted && _step == 1) {
        _step = 4;
      } else if (_step < _stepLabels.length - 1) {
        _step++;
      }
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _step = _hosted && _step == 4 ? 1 : _step - 1;
    });
  }

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
          return 'Please enter your first and last name.';
        }
        if (_email.text.trim().isEmpty) return 'Please enter your email address.';
        if (!_emailVerified) return 'Paki-verify muna ang iyong email bago magpatuloy.';
        final mobileError = PhMobile.validate(_mobile.text);
        if (mobileError != null) return mobileError;
        if (_barangay == null) return 'Please select your barangay.';
        final unmet = PasswordStandard.unmetMessages(_password.text);
        if (unmet.isNotEmpty) return unmet.map((m) => '• $m').join('\n');
        return null;
      case 1:
        if (!_termsAccepted) return 'Please accept the Terms & Conditions to continue.';
        return null;
      case 2:
        if (_idType == null) return 'Please choose the type of ID.';
        if (_idFilePath == null) return 'Please upload a valid ID to continue.';
        return null;
      case 3:
        if (_selfiePath == null) return 'Please take a selfie to continue.';
        return null;
      default:
        return null;
    }
  }

  /// What the citizen signs in with right after registering: the contact they
  /// just registered (the server also takes the ESP-RES account number).
  String _signInIdentifier() => _email.text.trim().isNotEmpty ? _email.text.trim() : _mobile.text.trim();

  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Editing the address invalidates any code or proof issued for the old one.
  void _onEmailChanged(String _) {
    if (!_emailCodeSent && !_emailVerified && _emailError == null) return;
    setState(() {
      _emailCodeSent = false;
      _emailVerified = false;
      _emailToken = null;
      _emailError = null;
      _emailCode.clear();
    });
  }

  Future<void> _sendEmailCode() async {
    final email = _email.text.trim();
    if (!_emailShape.hasMatch(email)) {
      setState(() => _emailError = 'Hindi valid ang email. Tingnan kung tama ang pagkakasulat (halimbawa: name@gmail.com).');
      return;
    }
    setState(() {
      _emailSending = true;
      _emailError = null;
    });
    try {
      await context.read<CitizenSessionService>().sendEmailCode(email);
      if (!mounted) return;
      setState(() {
        _emailSending = false;
        _emailCodeSent = true;
        _emailCode.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailSending = false;
        _emailError = e.code == 'EMAIL_TAKEN'
            ? 'Naka-register na ang email na ito. Gumamit ng ibang email.'
            : registrationErrorText(e);
      });
    }
  }

  Future<void> _confirmEmailCode() async {
    final code = _emailCode.text.trim();
    if (code.length != 6) {
      setState(() => _emailError = 'Ilagay ang 6-digit code na ipinadala sa iyong email.');
      return;
    }
    setState(() {
      _emailConfirming = true;
      _emailError = null;
    });
    try {
      final token = await context.read<CitizenSessionService>().verifyEmailCode(email: _email.text.trim(), code: code);
      if (!mounted) return;
      setState(() {
        _emailConfirming = false;
        _emailVerified = true;
        _emailToken = token;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailConfirming = false;
        _emailError = e.explain();
      });
    }
  }

  Future<void> _pickId() async {
    final result = await pickDocumentProtected(
      context,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
      explanation: 'Esperanza needs to let you choose a photo or scan of your valid ID. The LGU uses it to verify your account.',
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

  Future<void> _takeSelfie() async {
    final file = await pickImageProtected(
      context,
      source: ImageSource.camera,
      // A selfie: the front camera, so the resident need not flip it.
      preferredCamera: CameraDevice.front,
      maxDimension: 1280,
      explanation: 'Esperanza needs your camera to take a selfie. The LGU compares it with your valid ID to verify your account.',
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selfiePath = file.path;
      _selfieBytes = bytes;
      _error = null;
    });
  }

  /// The ID and the selfie, sent with the session the new account just got.
  /// A failure here does not undo the account: the status step says so and
  /// offers to send them again.
  Future<void> _sendIdentity() async {
    if (_hosted || _idType == null || _idFilePath == null || _identitySent) return;
    setState(() => _sendingIdentity = true);
    try {
      await context.read<CitizenSessionService>().submitVerificationId(
        idType: _idType!,
        frontPath: _idFilePath!,
        selfiePath: _selfiePath,
      );
      if (!mounted) return;
      setState(() {
        _identitySent = true;
        _identityError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _identityError = e.explain());
    } finally {
      if (mounted) setState(() => _sendingIdentity = false);
    }
  }

  /// The account exists on the server but is unusable (still Pending
  /// Review) until the OTP this issues is confirmed — [_otpCode] and
  /// [_verifyOtp] below handle that; the wizard's own "Verification
  /// Status" step (5) still shows afterward, same as before, now driven
  /// by the real account this created rather than a synthesized one.
  Future<void> _submitForVerification() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = context.read<CitizenSessionService>();
      final result = await session.register({
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
        'mobile': _mobile.text.trim().isEmpty ? null : _mobile.text.trim(),
        'password': _password.text,
        'barangay': _barangay,
        'purok': _purok.text.trim().isEmpty ? null : _purok.text.trim(),
        'address': '${_purok.text.trim()}, Barangay $_barangay, Esperanza, Masbate',
        'accepts_terms': true,
        'email_verification_token': _emailToken,
      });
      if (!mounted) return;
      final accountNo = JsonRead.nonEmpty(result['account_no']);
      final verification = JsonRead.map(result['verification']);
      final needsCode = JsonRead.boolean(verification?['required']) ?? true;
      if (!needsCode && accountNo != null) {
        // The email was proven in step 1, so there is no second code: sign
        // straight in and show the Pending Review status.
        await session.loginWithCredentials(_signInIdentifier(), _password.text);
        if (!mounted) return;
        await _sendIdentity();
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _step = 5;
        });
        return;
      }
      setState(() {
        _accountNo = accountNo;
        _otpDestination = JsonRead.nonEmpty(verification?['destination']);
        _submitting = false;
        _step = 5;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = registrationErrorText(e);
      });
    }
  }

  /// Confirms the OTP the registration above issued, then signs the citizen
  /// in for real (POST /auth/citizen/login) so the app's session reflects
  /// the account the server actually created.
  Future<void> _verifyOtp() async {
    if (_accountNo == null || _otpCode.text.trim().length != 6) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = context.read<CitizenSessionService>();
      await session.verify(accountNo: _accountNo!, code: _otpCode.text.trim());
      await session.loginWithCredentials(_signInIdentifier(), _password.text);
      if (!mounted) return;
      await _sendIdentity();
      if (!mounted) return;
      setState(() => _submitting = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.explain();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showIndicator = !(_alreadyHasAccount && _step == 5);
    // The design's form wizard (2026-10): a navy header holding the stepper,
    // the step's form on a glass card, the pill buttons below.
    return Scaffold(
      appBar: NavyBand.appBar(title: Text(_step == 5 ? 'Verification Status' : 'Create your account')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (showIndicator)
              NavyBand(child: OnboardingStepIndicator(currentStep: _visibleStep, stepLabels: _visibleLabels, onDark: true)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                child: GlassSurface(radius: 28, padding: wizardCardPadding(context), child: _buildStep()),
              ),
            ),
            if (_step < 5)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
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
        return _selfieStep();
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
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.brand600, size: 18),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "Let's start with your basic information. You can complete your full Resident Profile later.",
                  style: TextStyle(fontSize: AppTextSize.label, color: AppColors.brand700, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'First name',
                controller: _firstName,
                error: _attempted && _firstName.text.trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                label: 'Last name',
                controller: _lastName,
                error: _attempted && _lastName.text.trim().isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Email address',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.mail_outline_rounded,
                error: _emailError,
                onChanged: _onEmailChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 26 = the label above the field (13px text + 8px gap), so the
            // button sits level with the input itself.
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: SizedBox(
                height: 48,
                child: _emailVerified
                    ? const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.emerald700, size: 20),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            'Verified',
                            style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.emerald700),
                          ),
                        ],
                      )
                    : AppButton(
                        label: _emailCodeSent ? 'Resend' : 'Verify',
                        size: AppButtonSize.sm,
                        variant: _emailCodeSent ? AppButtonVariant.secondary : AppButtonVariant.primary,
                        loading: _emailSending,
                        onPressed: _emailSending ? null : _sendEmailCode,
                      ),
              ),
            ),
          ],
        ),
        if (_emailCodeSent && !_emailVerified) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Verification code',
                  controller: _emailCode,
                  keyboardType: TextInputType.number,
                  icon: Icons.mark_email_read_outlined,
                  hintText: '6-digit code',
                  hint: 'Ipinadala ang code sa ${_email.text.trim()}. Tingnan din ang spam folder.',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxl),
                child: SizedBox(
                  height: 48,
                  child: AppButton(
                    label: 'Confirm',
                    loading: _emailConfirming,
                    onPressed: _emailConfirming ? null : _confirmEmailCode,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Mobile number',
          controller: _mobile,
          keyboardType: TextInputType.phone,
          inputFormatters: PhMobile.inputFormatters,
          icon: Icons.phone_outlined,
          hintText: PhMobile.hint,
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
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Password',
          controller: _password,
          obscureText: true,
          icon: Icons.lock_outline_rounded,
          hintText: 'At least 8 characters',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.sm),
        PasswordRequirements(password: _password.text),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, key: _errorKey, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
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
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'By creating an Esperanza account, you agree to provide accurate information for barangay/municipal record-keeping. '
            'Your data is used only for LGU service delivery (document requests, assistance programs, resident records) and is '
            'not shared with third parties. Esperanza LGU staff may contact you to verify submitted information. False or '
            'misleading information may result in your verification being rejected.\n\n'
            'When you finish, your details are sent to the Municipality of Esperanza for verification.',
            style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate600, height: 1.5),
          ),
        ),
        // The full documents the box above summarises: the ones the
        // Municipality publishes, the same the web portal's sign-up links to.
        Wrap(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
              child: const Text('Read the Terms and Conditions'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              child: const Text('Read the Privacy Policy'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        InkWell(
          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
          borderRadius: BorderRadius.circular(AppRadius.sm),
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
                    padding: EdgeInsets.only(top: AppSpacing.md),
                    child: Text(
                      'I have read and agree to the Terms & Conditions and Privacy Policy.',
                      style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, key: _errorKey, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
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
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Upload a photo or scan of any valid government-issued ID. This helps Esperanza LGU verify your identity.',
          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        DropdownButtonFormField<String>(
          initialValue: _idType,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Type of ID'),
          items: [for (final t in _idTypes) DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))],
          onChanged: (v) => setState(() {
            _idType = v;
            _error = null;
          }),
        ),
        if (_idTypes.isEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Expanded(
                child: Text('The list of IDs could not be loaded.', style: TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted)),
              ),
              TextButton(onPressed: _loadIdTypes, child: const Text('Try again')),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (_idFilePath != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.emerald500.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.emerald700, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _idFileName ?? 'ID uploaded',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.emerald700),
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
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.brand200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.badge_outlined, color: AppColors.brand500, size: 30),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Upload Valid ID',
                    style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.brand600),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text('JPG, PNG, or PDF', style: TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Your ID and selfie are sent to the LGU when your account is created. Staff check them before verifying your account.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, key: _errorKey, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _selfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selfie',
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Take a clear photo of your face. The LGU staff who verify your account compare it with your ID.',
          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        // The camera frame (2026-10 design): a gold ring holding a clay
        // camera until the selfie is taken, then the selfie itself.
        Center(
          child: Container(
            width: 168,
            height: 168,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.gold300, AppColors.gold500]),
              boxShadow: [BoxShadow(color: AppColors.gold400.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: ClipOval(
              child: Container(
                color: _selfieBytes != null ? AppColors.emerald50 : AppColors.brand50,
                child: _selfieBytes != null
                    ? Image.memory(_selfieBytes!, fit: BoxFit.cover, semanticLabel: 'Your selfie')
                    : const Center(child: ClayIcon(ClayGlyph.camera, size: 76)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SelfieTips(),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: _selfieBytes != null ? 'Retake Selfie' : 'Take Selfie',
          icon: Icons.camera_alt_outlined,
          variant: _selfieBytes != null ? AppButtonVariant.secondary : AppButtonVariant.primary,
          fullWidth: true,
          onPressed: _takeSelfie,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600),
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
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Make sure everything looks correct before submitting for verification.',
          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
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
        if (!_hosted) ...[
          _reviewRow('Type of ID', _idType ?? '—', onEdit: () => setState(() => _step = 2)),
          _reviewRow('Valid ID', _idFileName ?? '—', onEdit: () => setState(() => _step = 2)),
          _reviewRow('Selfie', _selfiePath != null ? 'Taken' : 'Not taken', onEdit: () => setState(() => _step = 3)),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Next: once your account is created, you will verify your identity by scanning your valid ID and doing a quick face check.',
              style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, key: _errorKey, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _reviewRow(String label, String value, {required VoidCallback onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: AppColors.slate700),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Text(
              'Edit',
              style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.brand600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationStatusStep() {
    final account = context.watch<CitizenSessionService>().account;
    // Between a successful registration and a confirmed OTP, there is no
    // session yet at all (real login only happens once _verifyOtp()
    // succeeds) -- show the pending-review styling rather than the earlier
    // account! that would throw here.
    final status = account == null ? AppStatus.pendingReview : AppStatusX.fromLabel(account.status);
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
          style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (!_alreadyHasAccount)
          Text(
            _accountNo != null && _otpDestination != null
                ? 'Enter the 6-digit code sent to $_otpDestination to confirm your account.'
                : 'Na-verify na ang iyong email. Naipasa na ang iyong impormasyon sa Esperanza LGU para ma-review.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
          ),
        if (_identityError != null && !_identitySent && !_alreadyHasAccount && account != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your account was created, but your ID did not reach the LGU: $_identityError',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Send my ID again',
            icon: Icons.upload_rounded,
            fullWidth: true,
            loading: _sendingIdentity,
            onPressed: _sendingIdentity ? null : _sendIdentity,
          ),
        ],
        if (_accountNo != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: '6-digit code',
            controller: _otpCode,
            keyboardType: TextInputType.number,
            icon: Icons.mark_email_read_outlined,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, key: _errorKey, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Confirm Code',
            fullWidth: true,
            loading: _submitting,
            onPressed: _submitting ? null : _verifyOtp,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (_hosted && account != null) ...[
          _diditStep(account),
          const SizedBox(height: AppSpacing.lg),
        ],
        VerificationStatusPanel(
          status: status,
          waitingOnIdentity: _hosted && account != null && account.identityStatus != 'Verified' && account.status != 'Approved',
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (account != null)
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
          // "Nicanor/Perlita no longer opening" after using this button
          // or the drawer's Sign In from Guest mode.
          onPressed: () => Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }
}

extension on _RegisterScreenState {
  /// "Verify your identity" on Didit's screen, or the result once there is
  /// one. Continue to App below is the "do it later": the profile offers it
  /// again, and Dokyu and Tulong stay closed until it is done.
  Widget _diditStep(CitizenAccount account) {
    final identity = IdentityStatusX.fromLabel(account.identityStatus);
    if (identity != null && !identity.residentCanResend) {
      return IdentityStatusPanel(status: identity);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (identity != null) ...[IdentityStatusPanel(status: identity), const SizedBox(height: AppSpacing.md)],
        const Text(
          'Verify your identity',
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Have your valid ID ready. You will scan it with your camera, then do a quick face check - about 2 minutes. '
          'The check is done by Didit, our identity verification provider. You can also do this later from your profile.',
          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
        ),
        if (_diditMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_diditMessage!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600, height: 1.4)),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: _checkingDidit ? 'Checking your identity…' : 'Verify My Identity',
          icon: Icons.document_scanner_outlined,
          fullWidth: true,
          loading: _launchingDidit,
          onPressed: _launchingDidit ? null : _verifyOnDidit,
        ),
      ],
    );
  }
}

/// The selfie step's guidance: how to take a usable selfie, and what it is
/// used for. Plain and short — this is a security step, not a decoration.
class _SelfieTips extends StatelessWidget {
  const _SelfieTips();

  @override
  Widget build(BuildContext context) {
    Widget tip(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.navy700),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate700, height: 1.35))),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tip(Icons.wb_sunny_outlined, 'Stand in good light, facing the camera.'),
        tip(Icons.face_outlined, 'Show your whole face: no sunglasses, mask or cap.'),
        tip(Icons.person_outline_rounded, 'Only you in the photo, with a plain background if you can.'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.navy800.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.navy700.withValues(alpha: 0.15)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.navy800),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Your selfie is used only to verify your account: the LGU staff who review it compare it with your '
                  'valid ID. It is not your profile photo and is never shown publicly.',
                  style: TextStyle(fontSize: AppTextSize.label, color: AppColors.navy800, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
