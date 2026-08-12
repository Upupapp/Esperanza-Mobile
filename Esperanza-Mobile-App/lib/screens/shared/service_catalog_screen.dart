import 'package:flutter/material.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import 'new_request_screen.dart';

/// Step 1 of the request wizard — pick a document/assistance type. Mirrors
/// the catalog cards in document-requests.blade.php / assistance-requests.blade.php
/// (name, office, fee, processing time, requirements list).
class ServiceCatalogScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select $title Type')),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: catalog.length,
        itemBuilder: (context, i) {
          final item = catalog[i];
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
      ),
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
