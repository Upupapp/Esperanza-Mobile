import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_state_view.dart';

/// GET /directory (public, CommunicationsController::directory), the same
/// endpoint citizen/directory.blade.php on the Web Admin already calls.
/// Previously a hardcoded copy of that file's inline $offices array
/// (production-readiness programme, 2026-09-25).
class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  Future<List<_Office>> _load() async {
    final res = await api.get('/directory');
    return res.list.map((raw) {
      final m = raw as Map<String, dynamic>;
      return _Office(
        name: m['office'] as String? ?? '',
        head: m['official_name'] as String? ?? '',
        contact: m['contact'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Directory')),
      body: AsyncStateView<List<_Office>>(
        loader: _load,
        builder: (context, offices, reload) => RefreshIndicator(
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const Text('Municipal Offices', style: AppTypography.subsectionLabel),
              const SizedBox(height: AppSpacing.md),
              if (offices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Text('No offices listed yet.', style: TextStyle(color: AppColors.textMuted)),
                ),
              ...offices.map((o) => _OfficeTile(name: o.name, head: o.head, contact: o.contact)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Office {
  final String name;
  final String head;
  final String contact;
  const _Office({required this.name, required this.head, required this.contact});
}

class _OfficeTile extends StatelessWidget {
  final String name;
  final String head;
  final String contact;
  const _OfficeTile({required this.name, required this.head, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.navy900, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(head, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            if (contact.isNotEmpty)
              InkWell(
                onTap: () => launchUrl(Uri.parse('tel:$contact')),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(color: AppColors.emerald50, shape: BoxShape.circle),
                  child: const Icon(Icons.call_outlined, size: 16, color: AppColors.emerald700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
