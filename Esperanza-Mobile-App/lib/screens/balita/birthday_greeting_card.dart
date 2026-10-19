import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/citizen_account.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/birthday.dart';

/// The citizen's birthday greeting at the top of Balita, after the owner's
/// design (canvas "Balita Birthday Theme", artboard A, 2026-10-16).
///
/// Only the citizen sees it: the phone draws it from the signed-in account's
/// own birthdate. It is never posted to the feed, never sent to the server,
/// and another account signed in on the same phone does not get it. The
/// close button puts it away until next year's birthday.
class BirthdayGreetingCard extends StatefulWidget {
  const BirthdayGreetingCard({super.key, required this.account});

  final CitizenAccount account;

  @override
  State<BirthdayGreetingCard> createState() => _BirthdayGreetingCardState();
}

class _BirthdayGreetingCardState extends State<BirthdayGreetingCard> {
  // Unknown until the phone's memory is read, so a greeting closed earlier
  // today never flashes up first.
  bool? _hidden;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hidden = await Birthday.doneThisYear('card', widget.account);
    if (mounted) setState(() => _hidden = hidden);
  }

  void _dismiss() {
    setState(() => _hidden = true);
    Birthday.markDone('card', widget.account);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden != false) return const SizedBox.shrink();
    final firstName = widget.account.firstName.trim();
    final today = DateFormat('MMM d').format(Birthday.today()).toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        container: true,
        label: 'Birthday greeting',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.gold200),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gold100, AppColors.gold50, AppColors.surface],
              stops: [0, 0.6, 1],
            ),
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              children: [
                const Positioned.fill(child: _Confetti()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 18, 48, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ExcludeSemantics(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.gold200,
                          child: Icon(Icons.cake_outlined, size: 24, color: AppColors.navy800),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY · $today',
                              semanticsLabel: 'Today',
                              style: const TextStyle(
                                fontSize: AppTextSize.label,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: AppColors.gold700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              firstName.isEmpty ? 'Happy birthday!' : 'Happy birthday, $firstName!',
                              style: const TextStyle(
                                fontSize: AppTextSize.section,
                                height: 1.3,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Maligayang kaarawan! The Municipality of Esperanza wishes you good health '
                              'and a wonderful year ahead.',
                              style: TextStyle(fontSize: AppTextSize.body, height: 1.5, color: AppColors.slate600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    onPressed: _dismiss,
                    tooltip: 'Dismiss birthday greeting',
                    constraints: const BoxConstraints.tightFor(
                      width: AppSizes.minTouchTarget,
                      height: AppSizes.minTouchTarget,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate500),
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

/// A few bits of confetti in the card's lower-right corner.
class _Confetti extends StatelessWidget {
  const _Confetti();

  // (right, bottom, width, height, colour, opacity, turn)
  static const _bits = [
    (22.0, 18.0, 7.0, 7.0, AppColors.gold400, 1.0, 0.0),
    (44.0, 34.0, 4.0, 10.0, AppColors.brand500, 0.55, 0.49),
    (14.0, 52.0, 5.0, 5.0, AppColors.rose500, 0.6, 0.0),
    (64.0, 12.0, 4.0, 9.0, AppColors.gold400, 1.0, -0.42),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Stack(
          children: [
            for (final (right, bottom, w, h, color, opacity, turn) in _bits)
              Positioned(
                right: right,
                bottom: bottom,
                child: Transform.rotate(
                  angle: turn,
                  child: Container(
                    width: w,
                    height: h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(w == h ? w : 2),
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
