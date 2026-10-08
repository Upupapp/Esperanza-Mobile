import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_art.dart';
import '../../widgets/menu_tile.dart';
import 'service_catalog_screen.dart';

/// Service search (2026-10 design, the design's "Search services, permits,
/// or documents"): every Dokyu and Tulong service in one list, filtered as
/// the resident types, narrowed with All / Dokyu / Tulong. Opening a result
/// goes through [openCatalogItem], the same rules as the catalogue. Reached
/// from Home behind the same access guard as the Dokyu and Tulong tabs.
class ServiceSearchScreen extends StatelessWidget {
  const ServiceSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.read<RequestsService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: AsyncStateView<void>(
        loader: () => requests.loadCatalog(),
        builder: (context, _, reload) => _SearchBody(
          dokyu: requests.dokyuCatalog,
          tulong: requests.tulongCatalog,
        ),
      ),
    );
  }
}

enum _Filter { all, dokyu, tulong }

class _SearchBody extends StatefulWidget {
  final List<CatalogItem> dokyu;
  final List<CatalogItem> tulong;
  const _SearchBody({required this.dokyu, required this.tulong});

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    bool match(CatalogItem i) => q.isEmpty || i.name.toLowerCase().contains(q) || i.office.toLowerCase().contains(q);
    final results = [
      if (_filter != _Filter.tulong)
        for (final i in widget.dokyu.where(match)) (item: i, category: ServiceCategory.dokyu),
      if (_filter != _Filter.dokyu)
        for (final i in widget.tulong.where(match)) (item: i, category: ServiceCategory.tulong),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.page),
      children: [
        TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search services, permits, or documents',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.full)), borderSide: BorderSide(color: AppColors.surface)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.full)), borderSide: BorderSide(color: AppColors.surface)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.full)), borderSide: BorderSide(color: AppColors.gold500, width: 1.8)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final f in _Filter.values)
              ChoiceChip(
                label: Text(switch (f) {
                  _Filter.all => 'All',
                  _Filter.dokyu => 'Dokyu',
                  _Filter.tulong => 'Tulong',
                }),
                selected: _filter == f,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (results.isEmpty)
          EmptyState(
            glyph: ClayGlyph.search,
            title: 'No service found',
            description: q.isEmpty ? 'No services are available right now.' : 'Nothing matches "${_query.trim()}". Try another word.',
          )
        else
          for (final r in results) _ResultCard(item: r.item, category: r.category),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final CatalogItem item;
  final ServiceCategory category;
  const _ResultCard({required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    final dokyu = category == ServiceCategory.dokyu;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () => openCatalogItem(context, category, item, dokyu ? AppColors.brand600 : AppColors.purple700),
        child: Row(
          children: [
            ClayTile(size: 56, radius: 18, child: ClayIcon(dokyu ? ClayGlyph.document : ClayGlyph.heart, size: 34)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.navy900)),
                  const SizedBox(height: 2),
                  Text(
                    '${dokyu ? 'Dokyu' : 'Tulong'} · ${item.office}',
                    style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.slate600, height: 1.35),
                  ),
                ],
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
