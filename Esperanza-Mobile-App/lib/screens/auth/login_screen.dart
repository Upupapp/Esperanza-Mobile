import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/demo_account_card.dart';
import '../../widgets/parallax_header.dart';
import 'register_screen.dart';

/// Citizen sign-in — mobile mirrors the Web Admin's citizen-login half of
/// auth.select-portal (Citizen Login vs LGU Personnel Login). The mobile
/// app is citizen-only by design (Section 5/9 of the alignment doc: never
/// expose administrator functionality on mobile), so there is no portal
/// picker here at all — just the citizen flow. Sign-in is entirely a
/// frontend simulation, same as the Web Admin's authForm Alpine component:
/// no real backend call is made (the Web Admin has no /api/login of its
/// own for citizens yet either — see Section 8, Missing Web Admin Processes).
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
    final email = _emailController.text.trim();
    if (email.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 700));

    final match = MockCatalog.demoAccounts.where((a) => a.email.toLowerCase() == email.toLowerCase());
    if (!mounted) return;
    setState(() => _loading = false);

    if (match.isEmpty) {
      setState(() => _error = 'No resident account found for that email in this demo. Try a quick demo login below, or register.');
      return;
    }
    await context.read<CitizenSessionService>().login(match.first);
  }

  Future<void> _quickLogin(CitizenAccount account) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _loading = false);
    await context.read<CitizenSessionService>().login(account);
    if (mounted) {
      AppDialogs.toast(context, 'This app is a frontend simulation — sign-in is mocked for now.');
    }
  }

  Future<void> _continueAsGuest() async {
    await context.read<CitizenSessionService>().continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ParallaxHeader(
                scrollController: _scrollController,
                parallaxFactor: 0.25,
                background: Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [AppColors.brand500.withValues(alpha: 0.28), Colors.transparent]),
                    ),
                  ),
                ),
                foreground: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/images/esperanza-seal.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Esperanza',
                        style: TextStyle(fontFamily: 'Lora', fontSize: 26, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Citizen Portal · Municipality of Esperanza, Masbate',
                        style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.55)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Welcome back', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Sign in to manage your requests.', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Email address',
                      hintText: 'juan.delacruz@email.com',
                      icon: Icons.mail_outline_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Password',
                      hintText: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      controller: _passwordController,
                      obscureText: true,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(label: 'Sign In', onPressed: _submit, loading: _loading, fullWidth: true, size: AppButtonSize.lg),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Continue as Guest',
                      variant: AppButtonVariant.ghost,
                      fullWidth: true,
                      onPressed: _loading ? null : _continueAsGuest,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('or try a demo account', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ...MockCatalog.demoAccounts.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DemoAccountCard(
                          account: a,
                          onTap: _loading ? null : () => _quickLogin(a),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                      children: const [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(text: 'Register', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
