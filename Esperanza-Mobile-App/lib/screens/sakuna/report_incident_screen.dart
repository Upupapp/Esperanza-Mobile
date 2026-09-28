import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/catalog_item.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../shared/request_submitted_screen.dart';
import '../../theme/app_typography.dart';

/// Report an Incident, against POST /citizen/incidents.
///
/// Incidents used to go through the Dokyu/Tulong flow, which posted
/// `service_key: incident_flood` to POST /citizen/requests -- a key the
/// backend's `services` table has never held, so every report failed
/// validation. Incidents are their own backend resource and are open to
/// unverified citizens, so they get their own short form: an emergency
/// report should take seconds, not a wizard.
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key, required this.item, required this.accent});

  /// The incident type picked from the Sakuna catalogue (`MockCatalog
  /// .incidentTypes`). The backend takes `type` as free text, so the name
  /// is sent as-is.
  final CatalogItem item;
  final Color accent;

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

/// The severities the backend and the Web Admin's Sakuna module use.
const incidentSeverities = ['Low', 'Moderate', 'High', 'Critical'];

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _sitio = TextEditingController();
  final _description = TextEditingController();
  String? _severity;
  String? _barangay;
  bool _submitting = false;
  String? _error;

  /// One id per report, reused on every retry of it: the backend treats a
  /// repeated `client_uuid` as the same incident, so a tap on Submit after a
  /// timeout cannot file the flood twice.
  final String _clientUuid = _uuidV4();

  @override
  void initState() {
    super.initState();
    final home = context.read<CitizenSessionService>().account?.barangay;
    if (home != null && MockCatalog.barangays.contains(home)) _barangay = home;
  }

  @override
  void dispose() {
    _sitio.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_severity == null || _barangay == null) {
      setState(() => _error = 'Please choose how serious it is and the barangay where it is happening.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final sitio = _sitio.text.trim();
      final incident = await context.read<RequestsService>().reportIncident(
        type: widget.item.name,
        title: sitio.isEmpty ? '${widget.item.name} — $_barangay' : '${widget.item.name} — $sitio, $_barangay',
        severity: _severity!,
        barangay: _barangay!,
        sitio: sitio,
        description: _description.text,
        clientUuid: _clientUuid,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestSubmittedScreen(
            referenceNumber: incident.referenceNumber,
            typeName: incident.typeName,
            accent: widget.accent,
            requestId: incident.id,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report: ${widget.item.name}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            const Text(
              'For life-threatening emergencies, call a hotline first.',
              style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('How serious is it?', style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in incidentSeverities)
                  ChoiceChip(
                    label: Text(s),
                    selected: _severity == s,
                    selectedColor: AppColors.rose50,
                    onSelected: (_) => setState(() => _severity = s),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _barangay,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Barangay'),
              items: [for (final b in MockCatalog.barangays) DropdownMenuItem(value: b, child: Text(b))],
              onChanged: (v) => setState(() => _barangay = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: 'Sitio / purok / landmark (optional)', controller: _sitio),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'What is happening? (optional)',
              hintText: 'e.g. Water is knee-deep near the chapel; two families need help moving.',
              controller: _description,
              maxLines: 4,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit Report',
              icon: Icons.send_rounded,
              variant: AppButtonVariant.danger,
              fullWidth: true,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

String _uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
