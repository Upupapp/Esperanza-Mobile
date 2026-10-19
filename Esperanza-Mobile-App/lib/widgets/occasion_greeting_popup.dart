import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/citizen_account.dart';
import '../models/occasion_greeting.dart';
import '../screens/balita/balita_post_screen.dart';
import '../services/greeting_service.dart';
import '../services/message_language.dart';
import '../services/notifications_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// An occasion greeting from the LGU (2026-10-19) - a festival, a holiday,
/// the town's foundation day - popping up when the resident opens the app,
/// as an officer wrote, scheduled and had approved it in Balita.
///
/// It opens on Home's first frame, after the birthday pop-up and before the
/// welcome poster, so pop-ups never stack, and not at all while a Sakuna
/// alert is waiting: an emergency comes first. The server decides whether
/// one is due and how often; closing it never hides the Balita post, and
/// "Tingnan sa Balita" opens that post while it is in Balita.
class OccasionGreetingPopup extends StatelessWidget {
  const OccasionGreetingPopup({super.key, required this.greeting});

  final OccasionGreeting greeting;

  /// Shows the greeting due for [account] now, if any; completes when it is
  /// closed. A guest has none: greetings follow a resident's barangay.
  static Future<void> showIfAny(BuildContext context, CitizenAccount? account) async {
    if (account == null) return;
    final greeting = await GreetingService.active();
    if (greeting == null || !context.mounted) return;
    if (context.read<NotificationsService>().pendingAlert != null) return;
    // Counted as shown now, as the website does: an app closed with the
    // pop-up still open has still shown it.
    GreetingService.markSeen(greeting.id);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close greeting',
      barrierColor: AppColors.navy950.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => OccasionGreetingPopup(greeting: greeting),
      transitionBuilder: (context, animation, _, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(curve), child: child),
        );
      },
    );
  }

  void _openPost(BuildContext context) {
    final postId = greeting.postId;
    if (postId == null) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => BalitaPostScreen(announcementId: postId)));
  }

  Future<void> _openLink(BuildContext context) async {
    final url = greeting.buttonUrl;
    if (url == null) return;
    Navigator.of(context).pop();
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final filipino = MessageLanguage.filipino.value;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(320.0, size.width - 2 * AppSpacing.xxl);
    final occasion = greeting.occasion?.label(filipino: filipino);
    final hasLink = greeting.buttonUrl != null;
    final hasPost = greeting.postId != null;

    return Center(
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: greeting.title,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: width,
            constraints: BoxConstraints(maxHeight: size.height * 0.86),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy950.withValues(alpha: 0.35),
                  blurRadius: 60,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (greeting.posterUrl != null)
                        // The officer's poster, whole: never cropped, at most
                        // a little over half the screen.
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: size.height * 0.45),
                          child: ColoredBox(
                            color: AppColors.gold50,
                            child: Image.network(
                              greeting.posterUrl!,
                              fit: BoxFit.contain,
                              semanticLabel: greeting.title,
                              errorBuilder: (_, _, _) => const SizedBox(height: AppSpacing.xxxl),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 96,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              radius: 1.2,
                              colors: [AppColors.gold100, AppColors.gold50, AppColors.surface],
                              stops: [0, 0.5, 1],
                            ),
                          ),
                          child: const ExcludeSemantics(
                            child: Icon(Icons.celebration_rounded, size: 44, color: AppColors.gold600),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, AppSpacing.lg, 22, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              [filipino ? 'PAGBATI' : 'GREETING', ?occasion?.toUpperCase()].join(' · '),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: AppTextSize.label,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: AppColors.gold700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              greeting.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: AppTextSize.section,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy900,
                              ),
                            ),
                            if (greeting.message.trim().isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                greeting.message.trim(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: AppTextSize.body,
                                  height: 1.5,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            if (hasLink || hasPost)
                              _PrimaryButton(
                                label:
                                    greeting.buttonLabel ??
                                    (hasLink ? (filipino ? 'Buksan' : 'Open') : 'Tingnan sa Balita'),
                                onPressed: () => hasLink ? _openLink(context) : _openPost(context),
                              ),
                            if (hasLink && hasPost)
                              TextButton(
                                onPressed: () => _openPost(context),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, AppSizes.minTouchTarget),
                                  foregroundColor: AppColors.brand600,
                                ),
                                child: const Text('Tingnan sa Balita'),
                              ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, AppSizes.minTouchTarget),
                                foregroundColor: AppColors.slate600,
                                textStyle: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Salamat!'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Material(
                    color: AppColors.surface.withValues(alpha: 0.85),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      constraints: const BoxConstraints.tightFor(
                        width: AppSizes.minTouchTarget,
                        height: AppSizes.minTouchTarget,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.slate600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.full),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gold300, AppColors.gold500],
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: AppSizes.buttonHeightLg,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTextSize.card,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
