import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/auth/login_screen.dart';
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
            padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 8),
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

  List<Widget> _guestActions(BuildContext context) => [
        AppButton(
          label: 'Create Account',
          icon: Icons.person_add_alt_1_rounded,
          fullWidth: true,
          size: AppButtonSize.lg,
          onPressed: () async {
            await context.read<CitizenSessionService>().endGuestSession();
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                (route) => false,
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Sign In',
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: () async {
            await context.read<CitizenSessionService>().endGuestSession();
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }
          },
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
