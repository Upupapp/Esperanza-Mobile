import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/service_request.dart';
import '../../services/mock_catalog.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/esperanza_drawer.dart';
import '../home/root_shell.dart';
import '../shared/request_list_screen.dart';

/// Sakuna (Disaster Risk Reduction & Emergency Ops) — citizen-appropriate
/// slice of the Web Admin's much larger Sakuna module (Command Center,
/// Vulnerability Assessment, Resources, Damage Assessment, etc. are
/// staff-only and never belong on mobile — see Section 6/11 of the
/// alignment doc). Citizens get: read-only hotlines/evacuation-center
/// info, and the ability to report an incident + track its status, reusing
/// the same request pipeline as Dokyu/Tulong.
class SakunaScreen extends StatelessWidget {
  const SakunaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const EsperanzaDrawer(),
      appBar: AppBar(title: const Text('Risk Reduction & Emergency'), actions: const [AlertsAction()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.rose600, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('In a life-threatening emergency, call 911 or MDRRMO directly.', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.3)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Report an Incident',
            icon: Icons.report_outlined,
            variant: AppButtonVariant.danger,
            fullWidth: true,
            size: AppButtonSize.lg,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RequestListScreen(
                  category: ServiceCategory.sakunaIncident,
                  title: 'Incident Reports',
                  subtitle: 'Report and track disaster/emergency incidents.',
                  catalog: MockCatalog.incidentTypes,
                  accent: AppColors.rose600,
                  icon: Icons.report_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Text('Emergency Hotlines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          ...MockCatalog.emergencyHotlines.map(
            (h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(h.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    InkWell(
                      onTap: () => launchUrl(Uri.parse('tel:${h.$2}')),
                      child: Row(
                        children: [
                          Text(h.$2, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.rose600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.call_rounded, size: 14, color: AppColors.rose600),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Evacuation Centers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          ...MockCatalog.evacuationCenters.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.home_work_outlined, size: 17, color: AppColors.brand600),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${c.$2} · ${c.$3}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
