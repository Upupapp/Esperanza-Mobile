import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/esperanza_art.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Citizen sign-in — mobile mirrors the Web Admin's citizen-login half of
/// auth.select-portal (Citizen Login vs LGU Personnel Login). The mobile
/// app is citizen-only by design (Section 5/9 of the alignment doc: never
/// expose administrator functionality on mobile), so there is no portal
/// picker here at all — just the citizen flow.
///
/// Real sign-in (production-readiness programme, 2026-09-25): calls
/// POST /auth/citizen/login via CitizenSessionService.loginWithCredentials.
/// This screen used to carry six "Demo: ..." account cards that let anyone
/// browse and one-tap sign in as any seeded resident, including two
/// duplicate-account demo identities -- a real credential-enumeration
/// surface once this talks to a database, not a preview convenience, so
/// they are gone along with the mock catalog match this screen used to do
/// before ever reaching the network.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _emailController.text.trim();
    if (identifier.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your email/resident ID and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<CitizenSessionService>().loginWithCredentials(identifier, _passwordController.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.explain());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await context.read<CitizenSessionService>().continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    // The design's opening scene behind the sign-in (2026-10): the sun over
    // the municipal hall, the gold ribbon, and the form on frosted glass.
    final height = MediaQuery.sizeOf(context).height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: AppColors.navy950,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const RepaintBoundary(
            child: CustomPaint(painter: EsperanzaScenePainter(sunX: 0.80, sun: 0.115, sunScale: 0.55, ground: 0.22, hallWidth: 0.36)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Short enough that the whole form, Continue as Guest
                  // included, fits a 844pt-tall phone without scrolling.
                  SizedBox(height: height * 0.265),
                  const Text(
                    'Esperanza',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lora',
                      fontSize: AppTextSize.display,
                      fontWeight: FontWeight.w700,
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Citizen Portal · Municipality of Esperanza, Masbate',
                    style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.surface.withValues(alpha: 0.75)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
              GlassPanel(
                borderRadius: BorderRadius.circular(28),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(fontSize: AppTextSize.section, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Sign in to manage your requests.',
                      style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Resident ID, email, or mobile',
                      hintText: 'ESP-RES-2026-000123',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailController,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Password',
                      hintText: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(initialIdentifier: _emailController.text.trim()),
                                ),
                              ),
                        child: const Text('Forgot password?', style: TextStyle(fontSize: AppTextSize.helper)),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Sign In',
                      onPressed: _submit,
                      loading: _loading,
                      fullWidth: true,
                      size: AppButtonSize.lg,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Continue as Guest',
                      variant: AppButtonVariant.ghost,
                      fullWidth: true,
                      onPressed: _loading ? null : _continueAsGuest,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  // Text.rich (not a bare RichText) so this inherits the
                  // app's Inter font family from the ambient DefaultTextStyle
                  // the way every other Text on this screen already does —
                  // a raw RichText/TextSpan with no fontFamily set doesn't
                  // pick that up at all and falls back to whatever
                  // undefined system/engine font the platform resolves on
                  // its own, which is exactly what rendered as tofu/missing
                  // glyphs here on some platforms.
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: AppTypography.sans,
                        fontSize: AppTextSize.helper,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      children: const [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Register',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
        ],
      ),
      ),
    );
  }
}
