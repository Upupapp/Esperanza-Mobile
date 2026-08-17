import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/fade_page_route.dart';
import '../../widgets/app_button.dart';

class _OnboardingPageData {
  final IconData icon;
  final String headline;
  final String description;
  const _OnboardingPageData({required this.icon, required this.headline, required this.description});
}

/// Three horizontally-swipeable welcome screens shown only on a citizen's
/// very first use of the app (see [OnboardingService]) — the app-opening
/// [SplashScreen] appears every launch regardless, this flow is a
/// separate, one-time thing layered right after it. Copy is written to
/// sell the app's overall value (convenience, easier services, staying
/// connected/prepared), not to explain individual bottom-nav tabs one by
/// one.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(
      icon: Icons.holiday_village_rounded,
      headline: 'Esperanza, Closer to You',
      description: 'Access municipal services and important community information directly from your phone.',
    ),
    _OnboardingPageData(
      icon: Icons.assignment_turned_in_outlined,
      headline: 'Services Made Simpler',
      description: 'Request documents, find assistance, and follow your applications more conveniently without unnecessary trips.',
    ),
    _OnboardingPageData(
      icon: Icons.campaign_outlined,
      headline: 'Stay Connected. Stay Ready.',
      description: 'Stay updated with community announcements, events, important local information, and emergency updates.',
    ),
  ];

  final _pageController = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await OnboardingService.markComplete();
    if (!mounted) return;
    // pushReplacement — AuthGate becomes the new root route, same
    // invariant SplashScreen's own handoff preserves (see its doc
    // comment).
    Navigator.of(context).pushReplacement(fadePageRoute(const AuthGate()));
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset('assets/images/esperanza-seal.png', width: 30, height: 30, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Esperanza',
                    style: TextStyle(fontFamily: AppTypography.display, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  // Skip only on the two non-final pages — the final page
                  // shows just "Get Started" as its one action, per spec.
                  Opacity(
                    opacity: isLast ? 0 : 1,
                    child: IgnorePointer(
                      ignoring: isLast,
                      child: TextButton(
                        onPressed: _finishing ? null : _finish,
                        child: const Text('Skip', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [for (int i = 0; i < _pages.length; i++) _PageDot(active: i == _page)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AppButton(
                label: isLast ? 'Get Started' : 'Next',
                icon: isLast ? null : Icons.arrow_forward_rounded,
                iconTrailing: true,
                fullWidth: true,
                size: AppButtonSize.lg,
                loading: _finishing,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool active;
  const _PageDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.brand500 : AppColors.slate200,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Placeholder illustration slot — no final artwork yet.
                // Swap this Container's `child` for a real Image/SVG later;
                // the surrounding size/shape/spacing is already final, so
                // dropping in real art needs no layout changes.
                AspectRatio(
                  aspectRatio: 1.15,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(28)),
                    alignment: Alignment.center,
                    child: Icon(data.icon, size: 88, color: AppColors.brand400),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  data.headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: AppTypography.display, fontSize: 23, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
