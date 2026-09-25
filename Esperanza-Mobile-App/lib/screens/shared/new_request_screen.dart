import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/requirement_document_type.dart';
import '../../utils/tulong_eligibility.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import 'request_detail_screen.dart';
import 'request_submitted_screen.dart';

/// Fallback wizard for a catalog item with no curated [CatalogItem.formSpec]
/// (see [ServiceFormSpecs] — only real backend services whose `key` matches
/// one of [MockCatalog]'s curated document/assistance types get the fuller,
/// structured [ServiceRequestWizardScreen] instead). Just Process info,
/// Purpose, and Submit.
///
/// There is no requirement-file-upload or payment step here (production-
/// readiness programme, 2026-09-25) for the same reason
/// [ServiceRequestWizardScreen] dropped both: `POST /citizen/requests` is
/// JSON-only (no attachments), and receipt issuance is admin-only. See that
/// screen's own doc comment for the fuller explanation — both wizards
/// dropped the same two steps for the same real backend gaps.
class NewRequestScreen extends StatefulWidget {
  final ServiceCategory category;
  final CatalogItem item;
  final Color accent;

  const NewRequestScreen({super.key, required this.category, required this.item, required this.accent});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _purposeController = TextEditingController();

  /// Informational only now — see the class doc comment. Still resolved
  /// from [widget.item.requirements] so the citizen sees what staff may
  /// ask for while reviewing, same as [ServiceRequestWizardScreen]'s own
  /// requirements list.
  late final List<RequirementInfo> _requirementInfos = resolveRequirements(widget.item.requirements);

  bool _submitting = false;
  String? _error;

  /// The primary demo resident — same id used by ResidentProfileService,
  /// RequestsService, and ServiceRequestWizardScreen's own equivalent
  /// constant. Only her requests get [CatalogItem.demoPurpose] applied.
  static const _verifiedDemoAccountId = 'ESP-RES-2024-9002';

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account;
    if (account?.id == _verifiedDemoAccountId && widget.item.demoPurpose != null) {
      _purposeController.text = widget.item.demoPurpose!;
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_purposeController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the purpose of this request.');
      return;
    }

    final account = context.read<CitizenSessionService>().account!;
    final requestsService = context.read<RequestsService>();

    if (widget.category == ServiceCategory.tulong) {
      final result = tulongEligibilityFor(requestsService, applicantId: account.id, typeName: widget.item.name);
      if (!result.isEligible) {
        final viewRequest = await showTulongBlockedDialog(context, result);
        if (viewRequest && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: result.blockingRequest!.id)),
          );
        }
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final request = await requestsService.submit(
        serviceKey: widget.item.key,
        formData: {'purpose': _purposeController.text.trim()},
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestSubmittedScreen(
            referenceNumber: request.referenceNumber,
            typeName: request.typeName,
            accent: widget.accent,
            requestId: request.id,
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
      appBar: AppBar(title: Text(widget.item.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: _formPhase(),
        ),
      ),
    );
  }

  Widget _formPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline_rounded, size: 16, color: widget.accent),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Process', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < widget.item.process.length; i++) ...[
                    _stepChip(i + 1, widget.item.process[i]),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Purpose',
          hintText: 'e.g. Employment requirement, medical assistance for hospital bill...',
          controller: _purposeController,
          maxLines: 3,
        ),
        if (_requirementInfos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Requirements',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            "You'll be asked to submit these if staff need them while reviewing your request — no need to attach "
            'anything now.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final req in _requirementInfos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.description_outlined, size: 15, color: widget.accent),
                        const SizedBox(width: 8),
                        Expanded(child: Text(req.label, style: const TextStyle(fontSize: 12.5, color: AppColors.slate700))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
        const SizedBox(height: AppSpacing.xxl),
        AppButton(
          label: 'Submit Request',
          icon: Icons.send_rounded,
          onPressed: _submitting ? null : _submit,
          loading: _submitting,
          fullWidth: true,
          size: AppButtonSize.lg,
        ),
      ],
    );
  }

  Widget _stepChip(int n, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 7,
            backgroundColor: widget.accent,
            child: Text(
              '$n',
              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              textWidthBasis: TextWidthBasis.longestLine,
              style: const TextStyle(fontSize: 11, color: AppColors.slate600, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
