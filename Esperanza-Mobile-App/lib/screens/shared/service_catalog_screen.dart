import 'package:flutter/material.dart';
import '../../models/catalog_item.dart';
import '../../models/request_filters.dart';
import '../../models/service_request.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import 'new_request_screen.dart';

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

  List<RequestScope> get _availableScopes => widget.catalog.map((i) => scopeOfOffice(i.office)).toSet().toList()
    ..sort((a, b) => a.index.compareTo(b.index));

  List<CatalogItem> get _afterScope =>
      _scope == null ? widget.catalog : widget.catalog.where((i) => scopeOfOffice(i.office) == _scope).toList();

  List<String> get _availableDepartments => _afterScope.map((i) => i.office).toSet().toList()..sort();

  List<CatalogItem> get _afterDepartment =>
      _department == null ? _afterScope : _afterScope.where((i) => i.office == _department).toList();

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
      body = _DepartmentStep(departments: _availableDepartments, accent: widget.accent, onSelected: (d) => setState(() => _department = d));
    } else {
      body = _ItemList(category: widget.category, items: _afterDepartment, accent: widget.accent);
    }

    final crumbs = <String>[
      ?_scope?.label,
      ?_department,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: crumbs.isNotEmpty
            ? IconButton(
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (int i = 0; i < crumbs.length; i++) ...[
                    if (i > 0) const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.slate400)),
                    Text(crumbs[i], style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: widget.accent)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Where is this service administered?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Choose Barangay or Municipality-level services to narrow the list.', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
        const SizedBox(height: AppSpacing.xl),
        for (final scope in scopes) _StepTile(icon: scope == RequestScope.barangay ? Icons.holiday_village_outlined : Icons.account_balance_outlined, label: scope.label, accent: accent, onTap: () => onSelected(scope)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text('Which office handles this?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Choose a department to see its specific services.', style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
        const SizedBox(height: AppSpacing.xl),
        for (final dept in departments) _StepTile(icon: Icons.apartment_outlined, label: dept, accent: accent, onTap: () => onSelected(dept)),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _StepTile({required this.icon, required this.label, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: accent, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  final ServiceCategory category;
  final List<CatalogItem> items;
  final Color accent;
  const _ItemList({required this.category, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NewRequestScreen(category: category, item: item, accent: accent)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.description_outlined, color: accent, size: 19),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(item.office, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _pill(Icons.schedule_rounded, item.days),
                          _pill(item.amount != null ? Icons.payments_outlined : Icons.receipt_long_outlined, item.amount ?? item.fee),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(icon, size: 11, color: AppColors.slate500),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              textWidthBasis: TextWidthBasis.longestLine,
              style: const TextStyle(fontSize: 10.5, color: AppColors.slate600, fontWeight: FontWeight.w500, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
