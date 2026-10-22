import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/announcement.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../services/json_read.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/esperanza_art.dart';
import '../../widgets/menu_tile.dart';
import '../../widgets/status_chip.dart';
import '../balita/balita_post_screen.dart';
import '../events/event_detail_screen.dart';
import 'request_detail_screen.dart';
import 'service_catalog_screen.dart';

/// Search (2026-10 design, "Search services, permits, or documents";
/// widened for parity with the website's top-bar search, 2026-10-15): every
/// Dokyu and Tulong service, the resident's own requests, Balita
/// announcements and events, filtered as the resident types. Opening a
/// service goes through [openCatalogItem], the same rules as the catalogue.
/// Reached from Home behind the same access guard as the Dokyu and Tulong
/// tabs. Each source loads on its own: one that fails leaves the others.
class ServiceSearchScreen extends StatelessWidget {
  const ServiceSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.read<RequestsService>();
    final balita = context.read<BalitaService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: AsyncStateView<List<EventItem>>(
        loader: () async {
          final events = api
              .getAllPages('/events', query: {'per_page': 50}, maxPages: 2)
              .then((rows) => JsonRead.rows(rows, EventItem.fromApi).where((e) => e.title.isNotEmpty).toList())
              .catchError((Object _) => <EventItem>[]);
          await Future.wait([
            requests.loadCatalog(),
            requests.loadRequests().catchError((Object _) {}),
            if (balita.posts.isEmpty) balita.loadFeed().catchError((Object _) {}),
          ]);
          return events;
        },
        builder: (context, events, reload) => _SearchBody(
          dokyu: requests.dokyuCatalog,
          tulong: requests.tulongCatalog,
          requests: requests.all.where((r) => r.category != ServiceCategory.sakunaIncident).toList(),
          news: balita.posts,
          events: events,
        ),
      ),
    );
  }
}

enum _Filter { all, services, requests, balita, events }

class _SearchBody extends StatefulWidget {
  final List<CatalogItem> dokyu;
  final List<CatalogItem> tulong;
  final List<ServiceRequest> requests;
  final List<Announcement> news;
  final List<EventItem> events;
  const _SearchBody({
    required this.dokyu,
    required this.tulong,
    required this.requests,
    required this.news,
    required this.events,
  });

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    bool has(String? s) => s != null && s.toLowerCase().contains(q);
    bool match(CatalogItem i) => q.isEmpty || has(i.name) || has(i.office);
    bool want(_Filter f) => _filter == _Filter.all || _filter == f;
    final results = [
      if (want(_Filter.services)) ...[
        for (final i in widget.dokyu.where(match)) (item: i, category: ServiceCategory.dokyu),
        for (final i in widget.tulong.where(match)) (item: i, category: ServiceCategory.tulong),
      ],
    ];
    // The rest only once something is typed: the list would be everything.
    final mine = q.isEmpty || !want(_Filter.requests)
        ? const <ServiceRequest>[]
        : [
            for (final r in widget.requests)
              if (has(r.referenceNumber) || has(r.typeName) || has(r.status)) r,
          ];
    final news = q.isEmpty || !want(_Filter.balita)
        ? const <Announcement>[]
        : [
            for (final p in widget.news)
              if (has(p.title) || has(p.body)) p,
          ].take(10).toList();
    final events = q.isEmpty || !want(_Filter.events)
        ? const <EventItem>[]
        : [
            for (final e in widget.events)
              if (has(e.title) || has(e.venue) || has(e.description)) e,
          ];
    final nothing = results.isEmpty && mine.isEmpty && news.isEmpty && events.isEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.page),
      children: [
        TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search services, requests, news or events',
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
                  _Filter.services => 'Services',
                  _Filter.requests => 'My requests',
                  _Filter.balita => 'Balita',
                  _Filter.events => 'Events',
                }),
                selected: _filter == f,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = f),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (nothing)
          EmptyState(
            glyph: ClayGlyph.search,
            title: 'Nothing found',
            description: q.isEmpty ? 'No services are available right now.' : 'Nothing matches "${_query.trim()}". Try another word.',
          )
        else ...[
          if (mine.isNotEmpty) ...[
            const _Heading('My requests'),
            for (final r in mine) _RequestResult(request: r),
          ],
          if (results.isNotEmpty) ...[
            if (q.isNotEmpty) const _Heading('Services'),
            for (final r in results) _ResultCard(item: r.item, category: r.category),
          ],
          if (news.isNotEmpty) ...[
            const _Heading('Balita'),
            for (final p in news) _NewsResult(post: p),
          ],
          if (events.isNotEmpty) ...[
            const _Heading('Events'),
            for (final e in events) _EventResult(event: e),
          ],
        ],
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
    child: Semantics(header: true, child: Text(text, style: AppTypography.subsectionLabel)),
  );
}

/// One of the resident's requests: opens its detail.
class _RequestResult extends StatelessWidget {
  const _RequestResult({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.typeName, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w700)),
                  Text(request.referenceNumber, style: AppTypography.helper),
                ],
              ),
            ),
            // StatusChip.request knows Tulong's own statuses; fromLabel showed
            // them as a grey "Draft" (parity check, 2026-10-22).
            StatusChip.request(request.status, small: true),
          ],
        ),
      ),
    );
  }
}

/// A Balita announcement: opens the post.
class _NewsResult extends StatelessWidget {
  const _NewsResult({required this.post});

  final Announcement post;

  @override
  Widget build(BuildContext context) {
    final title = post.title ?? post.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => BalitaPostScreen(announcementId: post.remoteId))),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: AppColors.brand600),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An event: opens its page.
class _EventResult extends StatelessWidget {
  const _EventResult({required this.event});

  final EventItem event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () => EventDetailScreen.open(context, event),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, color: AppColors.brand600),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                  Text([event.date, event.venue].where((s) => s.isNotEmpty).join(' · '), style: AppTypography.helper),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
