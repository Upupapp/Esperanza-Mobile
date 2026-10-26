import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/gold_action_button.dart';
import '../../widgets/opening_waves.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

import '../../l10n/tr.dart';
/// The sign-in screen's photograph: the Esperanza Municipal Hall.
const signInPhotoAsset = 'assets/images/municipal_hall.jpg';

/// Citizen sign-in — mobile mirrors the Web Admin's citizen-login half of
/// auth.select-portal (Citizen Login vs LGU Personnel Login). The mobile
/// app is citizen-only by design (Section 5/9 of the alignment doc: never
/// expose administrator functionality on mobile), so there is no portal
/// picker here at all — just the citizen flow.
///
/// The look is the owner's design ("Esperanza Onboarding Prototype", screen
/// 5, 2026-10-12): the municipal hall across the top with a gold and navy
/// curve along its foot; "Esperanza", CITIZEN PORTAL and the municipality
/// under it; the form on a translucent navy card (gold-iconed fields, Forgot
/// password?, the gold Sign In, "or", Continue as Guest); Register below;
/// soft navy shapes and a gold corner behind. Colours are the nearest
/// [AppColors] tokens and the face is Inter, as on the welcome pages.
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
  bool _showPassword = false;
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

  void _forgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialIdentifier: _emailController.text.trim())),
    );
  }

  void _register() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final muted = AppTypography.signInBody.copyWith(color: AppColors.slate300);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.navy900,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned(
              top: 240,
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(child: CustomPaint(painter: SignInBackdropPainter())),
            ),
            SingleChildScrollView(
              controller: _scrollController,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  // The design's entrance: the whole screen rises 16 into
                  // place as it fades in.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduce ? 0 : 16, end: 0),
                    duration: Duration(milliseconds: reduce ? 0 : 450),
                    curve: const Cubic(0.2, 0.8, 0.25, 1),
                    builder: (context, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The photograph is 250 tall; the wordmark below rides
                        // 30 up over its foot.
                        const SizedBox(
                          height: 220,
                          child: OverflowBox(alignment: Alignment.topCenter, maxHeight: 250, minHeight: 250, child: _Photograph()),
                        ),
                        _Wordmark(muted: muted),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _FormCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(tr('Welcome back'), style: AppTypography.signInTitle.copyWith(color: AppColors.surface)),
                                const SizedBox(height: 4),
                                Text('Sign in to manage your requests.', style: muted),
                                const SizedBox(height: 14),
                                _Field(
                                  label: 'Resident ID, email, or mobile',
                                  hint: 'ESP-RES-2026-000123',
                                  icon: Icons.mail_outline_rounded,
                                  controller: _emailController,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 12),
                                _Field(
                                  label: 'Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  controller: _passwordController,
                                  obscure: !_showPassword,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _loading ? null : _submit(),
                                  suffix: IconButton(
                                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                                    onPressed: () => setState(() => _showPassword = !_showPassword),
                                    icon: Icon(
                                      _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AppColors.slate300,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _loading ? null : _forgotPassword,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.gold400,
                                      minimumSize: const Size(44, 44),
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                    ),
                                    child: Text(
                                      tr('Forgot password?'),
                                      style: TextStyle(fontFamily: AppTypography.sans, fontSize: AppTextSize.body, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  Text(
                                    _error!,
                                    style: const TextStyle(fontFamily: AppTypography.sans, fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.rose500),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 2),
                                GoldActionButton(
                                  label: tr('Sign In'),
                                  textStyle: AppTypography.signInAction.copyWith(color: AppColors.navy900),
                                  height: 50,
                                  arrow: true,
                                  loading: _loading,
                                  onPressed: _loading ? null : _submit,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(child: Container(height: 1, color: AppColors.surface.withValues(alpha: 0.14))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'or',
                                        style: const TextStyle(fontFamily: AppTypography.sans, fontSize: AppTextSize.helper, fontWeight: FontWeight.w500)
                                            .copyWith(color: AppColors.slate300),
                                      ),
                                    ),
                                    Expanded(child: Container(height: 1, color: AppColors.surface.withValues(alpha: 0.14))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _GuestButton(onPressed: _loading ? null : _continueAsGuest),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(20, 14, 20, 22 + bottom),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text("Don't have an account?", style: muted),
                              TextButton(
                                onPressed: _register,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.gold400,
                                  minimumSize: const Size(44, 44),
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                ),
                                child: Text('Register', style: AppTypography.signInBody.copyWith(fontWeight: FontWeight.w700, color: AppColors.gold400)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The municipal hall, with a navy wash at top and bottom and the gold and
/// navy curve along its foot.
class _Photograph extends StatelessWidget {
  const _Photograph();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.navy800,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              signInPhotoAsset,
              fit: BoxFit.cover,
              // object-position 50% 40%.
              alignment: const Alignment(0, -0.2),
              semanticLabel: 'Esperanza Municipal Hall',
              errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.navy800),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navy900.withValues(alpha: 0.3),
                      AppColors.navy900.withValues(alpha: 0),
                      AppColors.navy900.withValues(alpha: 0),
                      AppColors.navy900.withValues(alpha: 0.6),
                    ],
                    stops: const [0, 0.3, 0.6, 1],
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: -1,
              height: 120,
              child: IgnorePointer(child: CustomPaint(painter: SignInPhotoEdgePainter())),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Esperanza", CITIZEN PORTAL, and the municipality between two rules.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.muted});

  final TextStyle muted;

  @override
  Widget build(BuildContext context) {
    final rule = Container(width: 24, height: 1, color: AppColors.slate600);
    return Semantics(
      header: true,
      child: Column(
        children: [
          Text('Esperanza', textAlign: TextAlign.center, style: AppTypography.signInWordmark.copyWith(color: AppColors.surface)),
          const SizedBox(height: 4),
          // The trailing letter-space is balanced on the left, so the spaced
          // capitals sit centred.
          Padding(
            padding: const EdgeInsets.only(left: 4.2),
            child: Text(tr('CITIZEN PORTAL'), textAlign: TextAlign.center, style: AppTypography.signInEyebrow.copyWith(color: AppColors.gold400)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(child: rule),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Municipality of Esperanza, Masbate',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: AppTypography.sans, fontSize: AppTextSize.helper, fontWeight: FontWeight.w500)
                      .copyWith(color: AppColors.slate300),
                ),
              ),
              const SizedBox(width: 10),
              ExcludeSemantics(child: rule),
            ],
          ),
        ],
      ),
    );
  }
}

/// The form's translucent navy card, frosted over what is behind it.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.navy800.withValues(alpha: 0.55),
            borderRadius: radius,
            border: Border.all(color: AppColors.surface.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A labelled field: a gold icon inside, a dark fill, gold edge and ring when
/// focused.
class _Field extends StatefulWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    OutlineInputBorder edge(Color c, double w) => OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));
    final text = AppTypography.signInBody.copyWith(color: AppColors.surface, letterSpacing: widget.obscure ? 1.2 : 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontFamily: AppTypography.sans, fontSize: AppTextSize.helper, fontWeight: FontWeight.w600).copyWith(color: AppColors.slate200),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _focus.hasFocus ? [BoxShadow(color: AppColors.gold400.withValues(alpha: 0.18), spreadRadius: 3)] : const [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscure,
            // A password, shown or not, is not something to autocorrect or learn.
            autocorrect: widget.suffix == null,
            enableSuggestions: widget.suffix == null,
            autofillHints: widget.autofillHints,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted,
            style: text,
            cursorColor: AppColors.gold400,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.signInBody.copyWith(color: AppColors.slate400),
              filled: true,
              fillColor: AppColors.navy900.withValues(alpha: 0.6),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              prefixIcon: Icon(widget.icon, size: 20, color: AppColors.gold400),
              prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
              suffixIcon: widget.suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
              border: edge(AppColors.surface.withValues(alpha: 0.16), 1),
              enabledBorder: edge(AppColors.surface.withValues(alpha: 0.16), 1),
              focusedBorder: edge(AppColors.gold400, 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Continue as Guest: an outlined pill with a gold person icon.
class _GuestButton extends StatelessWidget {
  const _GuestButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.surface,
          // Clear, not the app theme's raised fill: an outline on the card.
          backgroundColor: AppColors.clear,
          disabledBackgroundColor: AppColors.clear,
          elevation: 0,
          shadowColor: AppColors.clear,
          shape: const StadiumBorder(),
          side: BorderSide(color: AppColors.surface.withValues(alpha: 0.28), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        icon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.gold400),
        label: Text('Continue as Guest', style: AppTypography.signInBody.copyWith(fontWeight: FontWeight.w600, color: AppColors.surface)),
      ),
    );
  }
}
