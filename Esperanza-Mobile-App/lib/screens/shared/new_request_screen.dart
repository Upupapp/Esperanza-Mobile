import 'package:flutter/material.dart';
import '../../widgets/payment_guidance_card.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/tulong_status.dart';
import '../../utils/applicant_form_data.dart';
import '../../utils/fee_inputs.dart';
import '../../utils/requirement_document_type.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/fee_input_fields.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/request_documents_picker.dart';
import 'request_submitted_screen.dart';
import '../../theme/app_typography.dart';

import '../../l10n/tr.dart';
/// Fallback wizard for a catalog item with no curated [CatalogItem.formSpec]
/// (see [ServiceFormSpecs] — only real backend services whose `key` matches
/// one of [MockCatalog]'s curated document/assistance types get the fuller,
/// structured [ServiceRequestWizardScreen] instead). Just Process info,
/// Purpose, and Submit.
///
/// There is no payment step here: receipt issuance is admin-only. The
/// required documents are picked on this screen and uploaded to the new
/// request right after it is filed (`POST .../requirements/{key}/attach`),
/// as in [ServiceRequestWizardScreen] (live test 2026-10-07, UX-16).
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

  /// One per [CatalogItem.feeInputs] — the amounts this service's fee is
  /// computed from.
  late final Map<String, TextEditingController> _feeControllers = {
    for (final name in widget.item.feeInputs) name: TextEditingController(),
  };

  /// What the office needs, resolved from [widget.item.requirements]; each
  /// one is picked below and uploaded once the request is filed.
  late final List<RequirementInfo> _requirementInfos = resolveRequirements(widget.item.requirements);

  // Every request takes its documents while it is filled in, Dokyu as well
  // as Tulong (live test 2026-10-07, UX-16): a Dokyu request said 'no need
  // to attach anything now', and then waited for the office to ask.

  /// Files picked below, by requirement label.
  final Map<String, Attachment> _picked = {};

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
    for (final c in _feeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_purposeController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the purpose of this request.');
      return;
    }
    final feeError = FeeInputs.validate(widget.item.feeInputs, _feeControllers);
    if (feeError != null) {
      setState(() => _error = feeError);
      return;
    }

    final requestsService = context.read<RequestsService>();


    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final request = await requestsService.submit(
        serviceKey: widget.item.key,
        formData: {
          'purpose': _purposeController.text.trim(),
          // The website's applicant block, from the account.
          ...applicantFormData(context.read<CitizenSessionService>().account),
        },
        feeInputs: FeeInputs.collect(widget.item.feeInputs, _feeControllers),
      );
      final notUploaded = await requestsService.attachPicked(request, _picked);

      if (!mounted) return;
      setState(() => _submitting = false);
      if (notUploaded.isNotEmpty) {
        AppDialogs.toast(
          context,
          'Your request was filed, but ${notUploaded.join(', ')} could not be uploaded. Add it from your request.',
          success: false,
        );
      }

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
        _error = e.explain();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          child: _formPhase(),
        ),
      ),
    );
  }

  /// A Tulong case runs the office's case steps, the same ones its timeline
  /// shows after filing; the catalogue's four-step copy predates that flow.
  List<String> get _processSteps =>
      widget.category == ServiceCategory.tulong ? TulongStatus.mainSequence : widget.item.process;

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
                  const Text('Process', style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (int i = 0; i < _processSteps.length; i++) ...[
                    _stepChip(i + 1, _processSteps[i]),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: tr('Purpose'),
          hintText: 'e.g. Employment requirement, medical assistance for hospital bill...',
          controller: _purposeController,
          maxLines: 3,
        ),
        if (widget.item.feeInputs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          FeeInputFields(names: widget.item.feeInputs, controllers: _feeControllers),
        ],
        if (_requirementInfos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RequestDocumentsPicker(
            requirements: _requirementInfos,
            picked: _picked,
            onPicked: (e) => setState(() => _picked[e.key] = e.value),
            accent: widget.accent,
            serviceName: widget.item.name,
            category: widget.category,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PaymentGuidanceCard(item: widget.item, sayWhenFree: widget.category == ServiceCategory.dokyu),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 7,
            backgroundColor: widget.accent,
            child: Text(
              '$n',
              style: const TextStyle(fontSize: AppTextSize.fine, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              textWidthBasis: TextWidthBasis.longestLine,
              style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.slate600, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
