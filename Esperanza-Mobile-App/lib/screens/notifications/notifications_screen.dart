import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../shared/request_detail_screen.dart';

/// Notifications are derived live from every non-citizen entry in each
/// request's statusHistory — so using the "Demo: Simulate Web Admin
/// Action" panel on a request detail screen immediately produces a real
/// notification here. This is the concrete "Mobile Reflection" half of the
/// Section 7 flow model, working end-to-end inside the frontend simulation.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<RequestsService>().all;

    final items = <_NotifRow>[];
    for (final r in requests) {
      for (final h in r.statusHistory) {
        if (h.actor == 'Citizen') continue;
        items.add(_NotifRow(request: r, entry: h));
      }
    }
    items.sort((a, b) => b.entry.at.compareTo(a.entry.at));

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              description: 'Updates about your Dokyu and Tulong requests will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final row = items[i];
                final accent = switch (row.request.category) {
                  ServiceCategory.dokyu => AppColors.brand600,
                  ServiceCategory.tulong => AppColors.purple700,
                  ServiceCategory.sakunaIncident => AppColors.rose600,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: row.request.id))),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_iconFor(row.entry.status), size: 17, color: accent),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${row.request.typeName} — ${row.entry.status}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(row.entry.remarks ?? 'Updated by ${row.entry.actor}.', style: const TextStyle(fontSize: 12, color: AppColors.slate500, height: 1.3)),
                              const SizedBox(height: 4),
                              Text(row.request.referenceNumber, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(String status) => switch (status) {
        'Approved' => Icons.check_circle_outline_rounded,
        'Rejected' => Icons.cancel_outlined,
        'Released' || 'Completed' => Icons.task_alt_rounded,
        'Waiting Requirements' => Icons.warning_amber_rounded,
        'Ready for Release' => Icons.inventory_2_outlined,
        _ => Icons.info_outline_rounded,
      };
}

class _NotifRow {
  final ServiceRequest request;
  final dynamic entry;
  _NotifRow({required this.request, required this.entry});
}
