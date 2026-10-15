import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/barangay_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/phone_dial.dart';
import '../../widgets/app_card.dart';
import '../../widgets/segmented_tabs.dart';

/// A barangay's profile (parity with the website's directory, 2026-10-15):
/// its seal, officials and contact, and - where the LGU has written them -
/// its history (founding, renaming, today, past leaders, landmarks) and the
/// full officials and staff roster. All from GET /barangays.
class BarangayProfileScreen extends StatefulWidget {
  const BarangayProfileScreen({super.key, required this.barangay});

  final BarangayInfo barangay;

  @override
  State<BarangayProfileScreen> createState() => _BarangayProfileScreenState();
}

class _BarangayProfileScreenState extends State<BarangayProfileScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final b = widget.barangay;
    final history = b.history;
    final call = dialUri(b.contact);
    return Scaffold(
      appBar: AppBar(title: Text('Brgy. ${b.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.md,
          AppSpacing.screenGutter,
          AppSpacing.scrollEnd,
        ),
        children: [
          AppCard(
            child: Row(
              children: [
                BarangaySeal(
                  url: b.sealUrl,
                  size: 56,
                  fallback: const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.brand50,
                    child: Icon(Icons.holiday_village_outlined, color: AppColors.brand600),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Barangay ${b.name}', style: AppTypography.cardHeading),
                      if (b.captain != null)
                        Text('Punong Barangay: ${b.captain}', style: AppTypography.helper),
                      if (b.secretary != null)
                        Text('Barangay Secretary: ${b.secretary}', style: AppTypography.helper),
                    ],
                  ),
                ),
                if (call != null)
                  IconButton(
                    tooltip: 'Call Barangay ${b.name}',
                    onPressed: () => launchUrl(call),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.emerald50,
                      minimumSize: const Size.square(AppSizes.minTouchTarget),
                    ),
                    icon: const Icon(Icons.call_outlined, size: AppSizes.iconBase, color: AppColors.emerald700),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!b.hasProfile)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Column(
                children: [
                  const Icon(Icons.auto_stories_outlined, size: AppSizes.iconLg, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'History and the officials roster are being added barangay by barangay.',
                    textAlign: TextAlign.center,
                    style: AppTypography.helper,
                  ),
                ],
              ),
            )
          else ...[
            SegmentedTabs(
              labels: const ['History', 'Officials & Staff'],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_tab == 0)
              if (history == null)
                const _Empty('The history of this barangay has not been added yet.')
              else
                _HistoryView(history: history)
            else if (b.roster.isEmpty)
              const _Empty('The officials roster has not been added yet.')
            else
              for (final o in b.roster) _OfficialTile(official: o),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
    child: Text(text, textAlign: TextAlign.center, style: AppTypography.helper),
  );
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({required this.history});

  final BarangayHistory history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (history.founding != null) _Section(icon: Icons.spa_outlined, title: 'Founding', text: history.founding!),
        if (history.renaming != null)
          _Section(icon: Icons.signpost_outlined, title: 'Renaming to its Present Name', text: history.renaming!),
        if (history.today != null) _Section(icon: Icons.home_outlined, title: 'Barangay Today', text: history.today!),
        if (history.leadership.isNotEmpty) ...[
          const _Heading(icon: Icons.account_balance_outlined, title: 'Leadership Timeline'),
          for (final l in history.leadership)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8, color: AppColors.brand500),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.name, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                        if (l.title != null || l.term != null)
                          Text([?l.title, ?l.term].join(' — '), style: AppTypography.helper),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (history.landmarks.isNotEmpty) ...[
          const _Heading(icon: Icons.place_outlined, title: 'Landmarks & Points of Interest'),
          for (final lm in history.landmarks)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lm.name, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                    if (lm.location != null) Text(lm.location!, style: AppTypography.helper),
                    if (lm.note != null) Text(lm.note!, style: AppTypography.helper),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.brand500),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title.toUpperCase(), style: AppTypography.eyebrow.copyWith(color: AppColors.textPrimary)),
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(icon: icon, title: title),
        Text(text, style: AppTypography.bodyText.copyWith(height: 1.55)),
      ],
    ),
  );
}

class _OfficialTile extends StatelessWidget {
  const _OfficialTile({required this.official});

  final BarangayOfficial official;

  @override
  Widget build(BuildContext context) {
    final initials = official.name
        .replaceAll(RegExp(r'^(Hon\.|Ma\.)\s*'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final placeholder = CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.brand50,
      child: Text(initials, style: AppTypography.labelText.copyWith(color: AppColors.brand700)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        child: Row(
          children: [
            if (official.photoUrl == null)
              placeholder
            else
              ClipOval(
                child: Image.network(
                  official.photoUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  semanticLabel: 'Photo of ${official.name}',
                  errorBuilder: (_, _, _) => placeholder,
                ),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(official.name, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                  if (official.position != null) Text(official.position!, style: AppTypography.helper),
                  if (official.committee != null)
                    Text(official.committee!, style: AppTypography.helper.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A barangay's seal from the website, round; [fallback] when there is none
/// or it cannot be loaded.
class BarangaySeal extends StatelessWidget {
  const BarangaySeal({super.key, required this.url, required this.size, required this.fallback});

  final String? url;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (url == null) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
