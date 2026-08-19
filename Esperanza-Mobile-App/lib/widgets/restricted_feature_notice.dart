import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth/register_screen.dart';
import '../services/citizen_session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Why a feature is being withheld — drives which message/actions
/// [RestrictedFeatureNotice] shows. See Sections 6/7 of the nav-and-access
/// spec for the exact copy.
enum RestrictionReason { guestOnly, needsVerification }

/// Shown in place of a screen's real content when the signed-in-state
/// doesn't meet that screen's required [AccessLevel] (see AccessGuard).
/// Never navigates a Guest/unverified user into a broken or empty screen —
/// this is the one, reusable "you can't be here yet, here's what to do"
/// notice for the whole app.
class RestrictedFeatureNotice extends StatelessWidget {
  final RestrictionReason reason;
  final String featureName;

  const RestrictedFeatureNotice({super.key, required this.reason, required this.featureName});

  @override
  Widget build(BuildContext context) {
    final isGuest = reason == RestrictionReason.guestOnly;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isGuest ? AppColors.brand50 : AppColors.amber50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGuest ? Icons.lock_outline_rounded : Icons.verified_user_outlined,
                      size: 36,
                      color: isGuest ? AppColors.brand500 : AppColors.amber700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    featureName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isGuest
                        ? 'This feature is available to registered Esperanza users. Create an account or sign in to continue.'
                        : 'Complete your account verification to access this service.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (isGuest) ..._guestActions(context) else ..._unverifiedActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Pop back to the root route instead of pushing a fresh LoginScreen/
  // RegisterScreen on top of an otherwise-emptied stack — see
  // esperanza_drawer.dart's _goToAuth for the full explanation. The root
  // route is _AuthGate (main.dart), already reactively showing
  // LoginScreen once endGuestSession() completes; the previous
  // `pushAndRemoveUntil(..., (route) => false)` removed _AuthGate from
  // the stack entirely, so any later login()/logout() had nothing left
  // to react to — the root cause behind demo accounts appearing to "stop
  // opening" once reached through this notice.
  Future<void> _endGuestAndGoToRoot(BuildContext context) async {
    await context.read<CitizenSessionService>().endGuestSession();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    }
  }

  List<Widget> _guestActions(BuildContext context) => [
    AppButton(
      label: 'Create Account',
      icon: Icons.person_add_alt_1_rounded,
      fullWidth: true,
      size: AppButtonSize.lg,
      onPressed: () async {
        await _endGuestAndGoToRoot(context);
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
        }
      },
    ),
    const SizedBox(height: AppSpacing.sm),
    AppButton(
      label: 'Sign In',
      variant: AppButtonVariant.secondary,
      fullWidth: true,
      onPressed: () => _endGuestAndGoToRoot(context),
    ),
  ];

  List<Widget> _unverifiedActions(BuildContext context) => [
    AppButton(
      label: 'Continue Verification',
      icon: Icons.arrow_forward_rounded,
      iconTrailing: true,
      fullWidth: true,
      size: AppButtonSize.lg,
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
    ),
  ];
}
