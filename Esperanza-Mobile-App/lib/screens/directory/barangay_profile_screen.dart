import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/barangay_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/phone_dial.dart';
import '../../widgets/segmented_tabs.dart';

/// A barangay's profile (the redesign, 2026-10-22; the website's barangay
/// modal is the same): its seal and a call button, then History - a few
/// facts, where the name comes from, livelihood, past leaders, places to
/// know, and the full text behind "Read full history" - and Officials &
/// Staff - the Punong Barangay, the officers and the kagawad by committee,
/// each opening a profile with the official photo. All from GET /barangays;
/// a part the LGU has not written is left out.
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
    final subtitle = history?.summary ?? (b.captain == null ? null : 'Punong Barangay: ${b.captain}');
    return Scaffold(
      appBar: AppBar(title: Text('Brgy. ${b.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.xs,
          AppSpacing.screenGutter,
          AppSpacing.scrollEnd,
        ),
        children: [
          _Panel(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                BarangaySeal(
                  url: b.sealUrl,
                  size: 52,
                  fallback: const CircleAvatar(
                    radius: 26,
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
                      if (subtitle != null) Text(subtitle, style: AppTypography.helper),
                    ],
                  ),
                ),
                if (call != null)
                  IconButton(
                    tooltip: 'Call barangay hall',
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
              _OfficialsView(roster: b.roster, leadership: history?.leadership ?? const []),
          ],
        ],
      ),
    );
  }
}

/// The white rounded block every section sits on.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(AppSpacing.lg)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
    child: child,
  );
}

/// A white list block: its rows divided by thin lines.
class _ListPanel extends StatelessWidget {
  const _ListPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: ColoredBox(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.slate100),
            children[i],
          ],
        ],
      ),
    ),
  );
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

/// A section's heading, with an optional action on the right.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.sm),
    child: Row(
      children: [
        Expanded(child: Semantics(header: true, child: Text(title, style: AppTypography.cardHeading))),
        ?trailing,
      ],
    ),
  );
}

/// The small capitals over a card ("THE NAME", "LIVELIHOOD").
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: AppTypography.eyebrow.copyWith(color: AppColors.textMuted));
}

class _HistoryView extends StatefulWidget {
  const _HistoryView({required this.history});

  final BarangayHistory history;

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  static const _shownLeaders = 3;
  bool _allLeaders = false;
  bool _fullText = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.history;
    // Newest first, as the redesign reads them.
    final leaders = h.leadership.reversed.toList();
    final shown = _allLeaders ? leaders : leaders.take(_shownLeaders).toList();
    final gap = const SizedBox(height: AppSpacing.xl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (h.facts.isNotEmpty) ...[
          _FactsGrid(facts: h.facts),
          gap,
        ],
        if (h.nameTitle != null || h.nameText != null) ...[
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow('The name'),
                const SizedBox(height: AppSpacing.xs),
                if (h.nameTitle != null) Text(h.nameTitle!, style: AppTypography.cardHeading),
                if (h.nameText != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(h.nameText!, style: AppTypography.bodySmall.copyWith(height: 1.5, color: AppColors.textBody)),
                ],
              ],
            ),
          ),
          gap,
        ],
        if (h.livelihood.isNotEmpty) ...[
          _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Eyebrow('Livelihood'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final l in h.livelihood) _Chip(l)],
                ),
                if (h.livelihoodNote != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(h.livelihoodNote!, style: AppTypography.helper),
                ],
              ],
            ),
          ),
          gap,
        ],
        if (leaders.isNotEmpty) ...[
          _SectionTitle(
            'Leadership',
            trailing: leaders.length > _shownLeaders
                ? TextButton(
                    onPressed: () => setState(() => _allLeaders = !_allLeaders),
                    style: TextButton.styleFrom(minimumSize: const Size(0, AppSizes.minTouchTarget)),
                    child: Text(_allLeaders ? 'Show less' : 'Show all ${leaders.length}'),
                  )
                : null,
          ),
          _ListPanel(
            children: [
              for (final l in shown)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            if (l.title != null || l.term != null)
                              Text([?l.title, ?l.term].join(' · '), style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (_isCurrent(l)) const _Chip('Current', green: true),
                    ],
                  ),
                ),
            ],
          ),
          gap,
        ],
        if (h.landmarks.isNotEmpty) ...[
          const _SectionTitle('Places to know'),
          _ListPanel(
            children: [
              for (final p in h.landmarks)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined, size: AppSizes.iconSm, color: AppColors.brand600),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            if (p.note != null)
                              Text(p.note!, style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (p.location != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(p.location!, style: AppTypography.fine.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          gap,
        ],
        if (h.hasFullText) ...[
          OutlinedButton(
            onPressed: () => setState(() => _fullText = !_fullText),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.brand600,
              side: const BorderSide(color: AppColors.brand100),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text(_fullText ? 'Hide full history' : 'Read full history'),
          ),
          if (_fullText) ...[
            const SizedBox(height: AppSpacing.md),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in [?h.founding, ?h.renaming, ?h.today])
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(t, style: AppTypography.bodySmall.copyWith(height: 1.7, color: AppColors.textBody)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

bool _isCurrent(BarangayLeader l) => (l.term ?? '').toLowerCase().contains('present');

class _FactsGrid extends StatelessWidget {
  const _FactsGrid({required this.facts});

  final List<BarangayFact> facts;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < facts.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _FactCard(fact: facts[i])),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: i + 1 < facts.length ? _FactCard(fact: facts[i + 1]) : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          rows[i],
        ],
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.fact});

  final BarangayFact fact;

  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fact.value, style: AppTypography.sectionTitle.copyWith(color: AppColors.brand600)),
        Text(fact.label, style: AppTypography.helper),
      ],
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.green = false});

  final String text;
  final bool green;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    decoration: BoxDecoration(
      color: green ? AppColors.emerald50 : AppColors.brand50,
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      text,
      style: AppTypography.labelText.copyWith(color: green ? AppColors.emerald700 : AppColors.brand700),
    ),
  );
}

/// Where an official sits in the roster.
enum _Role { punongBarangay, officer, kagawad }

_Role _roleOf(BarangayOfficial o) {
  final p = (o.position ?? '').toLowerCase();
  if (p.contains('punong barangay')) return _Role.punongBarangay;
  if (p.contains('kagawad')) return _Role.kagawad;
  return _Role.officer;
}

/// The name without "Hon.", for initials and for matching past leaders.
String _plainName(String name) => name.replaceAll(RegExp(r'^\s*Hon\.\s*'), '').trim();

String _initials(String name) => _plainName(name)
    .replaceAll(RegExp(r'^Ma\.\s*'), '')
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty && !w.endsWith('.'))
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();

/// An earlier term in the barangay's leadership history, if this official
/// had one ("Punong Barangay, 2007 – 2010").
String? _alsoServed(BarangayOfficial o, List<BarangayLeader> leadership) {
  final me = _plainName(o.name).toLowerCase();
  final past = [
    for (final l in leadership)
      if (_plainName(l.name).toLowerCase() == me && !_isCurrent(l)) [?l.title, ?l.term].join(', '),
  ];
  return past.isEmpty ? null : past.join('; ');
}

/// The committee, without a "(Former Punong Barangay, ...)" note that Also
/// served already says.
String? _committeeShown(BarangayOfficial o, String? alsoServed) {
  final c = o.committee;
  if (c == null || alsoServed == null) return c;
  return c.replaceAll(RegExp(r'\s*\(Former [^)]*\)'), '');
}

class _OfficialsView extends StatelessWidget {
  const _OfficialsView({required this.roster, required this.leadership});

  final List<BarangayOfficial> roster;
  final List<BarangayLeader> leadership;

  void _open(BuildContext context, BarangayOfficial o) {
    // A pop-up in the middle of the screen (owner, 2026-10-22).
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: _OfficialSheet(official: o, alsoServed: _alsoServed(o, leadership)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final captains = roster.where((o) => _roleOf(o) == _Role.punongBarangay).toList();
    final officers = roster.where((o) => _roleOf(o) == _Role.officer).toList();
    final kagawad = roster.where((o) => _roleOf(o) == _Role.kagawad).toList();
    final gap = const SizedBox(height: AppSpacing.xl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final pb in captains) ...[
          Semantics(
            button: true,
            label: 'View profile of ${pb.name}',
            excludeSemantics: true,
            child: Material(
              color: AppColors.brand600,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => _open(context, pb),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      _Avatar(official: pb, size: 60, inverted: true),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PUNONG BARANGAY',
                              style: AppTypography.eyebrow.copyWith(color: AppColors.brand100),
                            ),
                            Text(pb.name, style: AppTypography.cardHeading.copyWith(color: AppColors.surface)),
                            if (pb.committee != null)
                              Text(pb.committee!, style: AppTypography.helper.copyWith(color: AppColors.brand50)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          gap,
        ],
        if (officers.isNotEmpty) ...[
          const _SectionTitle('Officers'),
          _ListPanel(
            children: [
              for (final o in officers)
                _OfficialRow(official: o, subtitle: o.position, emphasise: true, onTap: () => _open(context, o)),
            ],
          ),
          gap,
        ],
        if (kagawad.isNotEmpty) ...[
          _SectionTitle(
            'Barangay Kagawad',
            trailing: Text('${kagawad.length} · by committee', style: AppTypography.helper),
          ),
          _ListPanel(
            children: [
              for (final k in kagawad)
                _OfficialRow(
                  official: k,
                  subtitle: _committeeShown(k, _alsoServed(k, leadership)),
                  onTap: () => _open(context, k),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _OfficialRow extends StatelessWidget {
  const _OfficialRow({required this.official, required this.subtitle, required this.onTap, this.emphasise = false});

  final BarangayOfficial official;
  final String? subtitle;
  final VoidCallback onTap;
  final bool emphasise;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            _Avatar(official: official, size: 40),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(official.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: emphasise
                          ? AppTypography.helper.copyWith(color: AppColors.brand600, fontWeight: FontWeight.w600)
                          : AppTypography.helper,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The official's photo, round; their initials while it loads or if there is
/// none.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.official, required this.size, this.inverted = false});

  final BarangayOfficial official;
  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final initials = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: inverted ? AppColors.surface : AppColors.brand50),
      child: Text(
        _initials(official.name),
        style: AppTypography.labelText.copyWith(color: inverted ? AppColors.brand600 : AppColors.brand700),
      ),
    );
    if (official.photoUrl == null) return initials;
    return ClipOval(
      child: Image.network(
        official.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => initials,
      ),
    );
  }
}

/// One official, centred: the photo, full size, and what they handle.
class _OfficialSheet extends StatelessWidget {
  const _OfficialSheet({required this.official, required this.alsoServed});

  final BarangayOfficial official;
  final String? alsoServed;

  @override
  Widget build(BuildContext context) {
    final role = _roleOf(official);
    final areaLabel = switch (role) {
      _Role.punongBarangay => 'Also chairs',
      _Role.officer => 'Handles',
      _Role.kagawad => 'Committee',
    };
    final placeholder = Container(
      color: AppColors.brand50,
      alignment: Alignment.center,
      child: Text(
        _initials(official.name),
        style: AppTypography.displayTitle.copyWith(color: AppColors.brand700),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  color: AppColors.brand50,
                  alignment: Alignment.center,
                  child: official.photoUrl == null
                      ? placeholder
                      : Image.network(
                          official.photoUrl!,
                          // The whole photo, in the middle.
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          semanticLabel: 'Photo of ${official.name}',
                          errorBuilder: (_, _, _) => placeholder,
                        ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton(
                    tooltip: 'Close profile',
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface.withValues(alpha: 0.9),
                      minimumSize: const Size.square(AppSizes.minTouchTarget),
                    ),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (official.position != null)
                    Text(
                      official.position!.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTypography.eyebrow.copyWith(color: AppColors.brand600),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(official.name, textAlign: TextAlign.center, style: AppTypography.pageTitle),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.slate100),
                  const SizedBox(height: AppSpacing.md),
                  if (official.committee != null)
                    _SheetRow(
                      label: areaLabel,
                      value: _committeeShown(official, alsoServed)!,
                    ),
                  if (alsoServed != null) _SheetRow(label: 'Also served', value: alsoServed!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
        Text(value, textAlign: TextAlign.center, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    ),
  );
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
