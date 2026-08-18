import 'package:flutter/material.dart';
import '../../main.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/fade_page_route.dart';
import '../../widgets/app_button.dart';

class _OnboardingPageData {
  final String imagePath;
  const _OnboardingPageData({required this.imagePath});
}

/// Three horizontally-swipeable welcome screens shown only on a citizen's
/// very first use of the app (see [OnboardingService]) — the app-opening
/// [SplashScreen] appears every launch regardless, this flow is a
/// separate, one-time thing layered right after it. Each screen is the
/// final full-bleed artwork itself (no placeholder illustration/headline
/// column anymore) with a small branding overlay (seal + municipality
/// name) pinned to the upper middle and Skip/Next/Get Started controls —
/// the artwork already carries the messaging, so the overlay only adds
/// identity + navigation, never competing text.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(imagePath: 'assets/images/Welcome Screen 1.png'),
    _OnboardingPageData(imagePath: 'assets/images/Welcome Screen 2.png'),
    _OnboardingPageData(imagePath: 'assets/images/Welcome Screen 3.png'),
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
      backgroundColor: AppColors.navy900,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
          ),
          // Page indicator, just above the bottom action button — small
          // and out of the way of the artwork itself.
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (int i = 0; i < _pages.length; i++) _PageDot(active: i == _page)],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Esperanza seal + "Municipalidad ng Esperanza" — upper
                  // middle, per spec — on its own dark pill so it stays
                  // legible over any part of any photo underneath.
                  const _BrandBadge(),
                  // Skip — upper right, only on non-final pages so the
                  // final page shows just "Get Started".
                  Align(
                    alignment: Alignment.topRight,
                    child: Opacity(
                      opacity: isLast ? 0 : 1,
                      child: IgnorePointer(
                        ignoring: isLast,
                        child: _PillButton(
                          onTap: _finishing ? null : _finish,
                          child: const Text('Skip', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Next / Get Started — lower middle, per spec — sitting on the
          // same soft bottom scrim every page uses for legibility (see
          // _OnboardingPage's gradient) rather than a full-width bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: SizedBox(
                width: 220,
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
            ),
          ),
        ],
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
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
    );
  }
}

/// Small dark rounded backdrop shared by the Skip control and (via
/// [_BrandBadge]) the seal/name badge — guarantees legibility over any
/// part of any onboarding photo without needing to know the image's own
/// brightness ahead of time.
class _PillButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _PillButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: child,
        ),
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
            ),
            child: ClipOval(child: Image.asset('assets/images/esperanza-seal.png', fit: BoxFit.cover)),
          ),
          const SizedBox(width: 8),
          // Flexible + ellipsis: a Row with mainAxisSize.min still demands
          // its full natural width regardless of what's actually
          // available — on a narrow phone this text alone can exceed the
          // room left after the top padding/Skip button, which is exactly
          // what caused a real RenderFlex overflow here. Flexible lets it
          // shrink and truncate instead of overflowing.
          Flexible(
            child: Text(
              'Municipalidad ng Esperanza',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: AppTypography.display, fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(data.imagePath, fit: BoxFit.cover),
        // Soft top/bottom scrims so the brand badge/Skip and the page
        // dots/Next button stay readable regardless of what's directly
        // behind them in the artwork, without covering the middle of the
        // image where its own content lives.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black38, Colors.transparent],
              stops: [0.0, 0.22],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black45, Colors.transparent],
              stops: [0.0, 0.28],
            ),
          ),
        ),
      ],
    );
  }
}
