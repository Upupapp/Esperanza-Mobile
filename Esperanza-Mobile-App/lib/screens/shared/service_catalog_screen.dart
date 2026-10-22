import 'package:flutter/material.dart';
import '../../models/catalog_item.dart';
import '../../models/request_filters.dart';
import '../../models/service_request.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/office_logo.dart';
import '../../widgets/app_card.dart';
import '../../widgets/menu_tile.dart';
import 'new_request_screen.dart';
import 'service_request_wizard_screen.dart';
import '../../theme/app_typography.dart';
import '../../utils/office_name.dart';
import '../../widgets/esperanza_art.dart';

/// Step 1 of the request wizard — pick a document/assistance type, guided
/// by progressive filtering (Barangay/LGU -> Department -> Specific
/// Program) rather than one long flat list, per the filtering spec:
/// "do not show every option at once; respond to previous selections."
/// A step is skipped automatically when it wouldn't actually narrow
/// anything — e.g. Tulong's catalog is entirely LGU/Municipal-level
/// (no barangay-administered assistance program exists), so showing a
/// Barangay/LGU choice there would be a dead end; Dokyu's catalog spans
/// both, so that step appears there. This keeps the same screen correct
/// for both Dokyu and Tulong without hand-tuning per category.
class ServiceCatalogScreen extends StatefulWidget {
  final ServiceCategory category;
  final String title;
  final List<CatalogItem> catalog;
  final Color accent;

  const ServiceCatalogScreen({
    super.key,
    required this.category,
    required this.title,
    required this.catalog,
    required this.accent,
  });

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  RequestScope? _scope;
  String? _department;

  List<RequestScope> get _availableScopes =>
      widget.catalog.map((i) => scopeOfOffice(i.office)).toSet().toList()..sort((a, b) => a.index.compareTo(b.index));

  List<CatalogItem> get _afterScope =>
      _scope == null ? widget.catalog : widget.catalog.where((i) => scopeOfOffice(i.office) == _scope).toList();

  List<String> get _availableDepartments => _afterScope.map((i) => canonicalOffice(i.office)).toSet().toList()..sort();

  List<CatalogItem> get _afterDepartment =>
      _department == null ? _afterScope : _afterScope.where((i) => canonicalOffice(i.office) == _department).toList();

  bool get _needsScopeStep => _availableScopes.length > 1;
  bool get _needsDepartmentStep => _availableDepartments.length > 1;

  @override
  Widget build(BuildContext context) {
    // Steps are resolved in order: Scope -> Department -> Item list. Once
    // a step isn't needed (or has already been answered), fall through to
    // the next one — this is what makes "not enough distinct values to
    // matter" transparently skip instead of showing a single-option menu.
    Widget body;
    final appBarTitle = 'Select ${widget.title} Type';
    if (_needsScopeStep && _scope == null) {
      body = _ScopeStep(scopes: _availableScopes, accent: widget.accent, onSelected: (s) => setState(() => _scope = s));
    } else if (_needsDepartmentStep && _department == null) {
      body = _DepartmentStep(
        departments: _availableDepartments,
        accent: widget.accent,
        onSelected: (d) => setState(() => _department = d),
      );
    } else {
      body = _ItemList(category: widget.category, items: _afterDepartment, accent: widget.accent);
    }

    final crumbs = <String>[?_scope?.label, ?_department];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: crumbs.isNotEmpty
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() {
                  if (_department != null) {
                    _department = null;
                  } else {
                    _scope = null;
                  }
                }),
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (crumbs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (int i = 0; i < crumbs.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        child: Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.slate400),
                      ),
                    Text(
                      crumbs[i],
                      style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: widget.accent),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _ScopeStep extends StatelessWidget {
  final List<RequestScope> scopes;
  final Color accent;
  final ValueChanged<RequestScope> onSelected;
  const _ScopeStep({required this.scopes, required this.accent, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const Text(
          'Where is this service administered?',
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Choose Barangay or Municipality-level services to narrow the list.',
          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final scope in scopes)
          _StepTile(
            icon: scope == RequestScope.barangay ? Icons.holiday_village_outlined : Icons.account_balance_outlined,
            label: scope.label,
            accent: accent,
            onTap: () => onSelected(scope),
          ),
      ],
    );
  }
}

class _DepartmentStep extends StatelessWidget {
  final List<String> departments;
  final Color accent;
  final ValueChanged<String> onSelected;
  const _DepartmentStep({required this.departments, required this.accent, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const Text(
          'Which office handles this?',
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Choose a department to see its specific services.',
          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final dept in departments)
          _StepTile(
            icon: Icons.apartment_outlined,
            logoAsset: officeLogoAsset(dept),
            label: dept,
            accent: accent,
            onTap: () => onSelected(dept),
          ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  /// When set, an office logo replaces [icon] inside the same tinted
  /// container (used for the department/office step only — the
  /// Barangay/Municipality scope step still uses a plain icon).
  final String? logoAsset;

  const _StepTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: logoAsset != null
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Image.asset(logoAsset!, fit: BoxFit.contain),
                    )
                  : Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const ChevronBubble(),
          ],
        ),
      ),
    );
  }
}

/// The services themselves, with a search field over them (2026-10 refresh,
/// from the design's "Search services"): it filters by name and office.
class _ItemList extends StatefulWidget {
  final ServiceCategory category;
  final List<CatalogItem> items;
  final Color accent;
  const _ItemList({required this.category, required this.items, required this.accent});

  @override
  State<_ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<_ItemList> {
  String _query = '';

  ServiceCategory get category => widget.category;
  Color get accent => widget.accent;

  Future<void> _open(BuildContext context, CatalogItem item) => openCatalogItem(context, category, item, accent);

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? widget.items
        : widget.items.where((i) => i.name.toLowerCase().contains(q) || i.office.toLowerCase().contains(q)).toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search services',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate500),
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      borderSide: const BorderSide(color: AppColors.slate200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      borderSide: const BorderSide(color: AppColors.gold500, width: 1.5),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxl),
                    child: Text(
                      'No service matches "${_query.trim()}".',
                      style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
          );
        }
        final item = items[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            onTap: () => _open(context, item),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The service's clay icon (2026-10 design): one icon style
                // across the app, the same as Service Search. The office step
                // above keeps the offices' own logos.
                ClayTile(
                  size: 56,
                  radius: 18,
                  child: ClayIcon(
                    switch (category) {
                      ServiceCategory.tulong => ClayGlyph.heart,
                      ServiceCategory.sakunaIncident => ClayGlyph.shield,
                      _ => ClayGlyph.document,
                    },
                    size: 34,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: AppTextSize.body,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(item.office, style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _pill(Icons.schedule_rounded, item.days),
                          _pill(
                            item.amount != null ? Icons.payments_outlined : Icons.receipt_long_outlined,
                            item.amount ?? item.fee,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Padding(padding: EdgeInsets.only(top: AppSpacing.md), child: ChevronBubble()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Renders as a compact single-line pill for short text, but grows
  /// vertically and wraps for long amounts/descriptions (e.g. "₱1,000/month
  /// (₱3,000 per quarter)") instead of overflowing the card. The `Flexible`
  /// is what makes this safe: without it, a `Row` with no flex children
  /// sizes to its content's *unbounded* intrinsic width, which is exactly
  /// what produced the overflow warnings — `Flexible` forces the Row to
  /// respect the width `Wrap` actually offers it, and `longestLine` keeps
  /// short pills from stretching to fill that width unnecessarily.
  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(icon, size: 11, color: AppColors.slate500),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              textWidthBasis: TextWidthBasis.longestLine,
              style: const TextStyle(
                fontSize: AppTextSize.fine,
                color: AppColors.slate600,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens one service from a catalogue: the request wizard when it has a form
/// spec, the plain request screen otherwise, the incident form for Sakuna.
/// Shared by the catalogue and Service Search, so both apply the same rules.
///
/// Nothing is checked before a Tulong form opens: like the website, the app
/// leaves it to the office whether a second application is accepted
/// (2026-10-22, app/web parity).
Future<void> openCatalogItem(BuildContext context, ServiceCategory category, CatalogItem item, Color accent) async {
  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => item.formSpec != null
          ? ServiceRequestWizardScreen(category: category, item: item, accent: accent)
          : NewRequestScreen(category: category, item: item, accent: accent),
    ),
  );
}
