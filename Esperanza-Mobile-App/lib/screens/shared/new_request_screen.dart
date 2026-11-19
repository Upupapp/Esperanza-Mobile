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

/// A Submit whose answer never came (it timed out, the connection dropped,
/// a gateway gave up) may still have filed the request: the server can
/// finish after the app has stopped waiting, and POST /citizen/requests
/// takes no idempotency key yet. Submit came back on and a second tap filed
/// it twice: two references, two fees, the office alerted twice (QA
/// 2026-11-18). Taken just before Submit, this reads the list again after
/// such a failure and finds the request that is new since, so the screen
/// goes on as filed. Shared by [NewRequestScreen] and the service wizard.
class FiledRequestCheck {
  FiledRequestCheck._(this._before, this._at, this._listed);

  /// What the list holds now, just before Submit.
  factory FiledRequestCheck.of(RequestsService service) =>
      FiledRequestCheck._({for (final r in service.all) r.referenceNumber}, DateTime.now(), service.loaded);

  /// The same, taken just before Submit, reading the list first when it
  /// never was (the form opened before anything loaded it): without that,
  /// no answer could never be told from not filed. Reading it can fail;
  /// then nothing is taken as filed after no answer (see [_listed]).
  static Future<FiledRequestCheck> take(RequestsService service) async {
    if (!service.loaded) {
      try {
        await service.refreshRequests();
      } catch (_) {
        // Offline, or unreadable: Submit goes ahead all the same; a reading
        // problem must never stop a filing.
      }
    }
    return FiledRequestCheck.of(service);
  }

  final Set<String> _before;
  final DateTime _at;

  /// Whether the list had been read before Submit. When it had not (the
  /// form opened before Track Requests ever loaded), a request of the same
  /// service filed earlier in the hour would read as this one: then
  /// nothing is taken as filed, and the form says it may have been.
  final bool _listed;

  /// Whether [error] leaves it unknown if the server filed the request: no
  /// answer at all, or the server or a gateway failing (5xx). A refusal (a
  /// 4xx, too many requests) filed nothing.
  static bool unanswered(ApiException error) => error.retryable && error.status != 429;

  /// The request of [serviceName] filed despite [error], read in full; null
  /// when the list has none new (or cannot be read).
  Future<ServiceRequest?> find(ApiException error, RequestsService service, {required String serviceName}) async {
    if (!unanswered(error) || !_listed) return null;
    ServiceRequest? filed;
    try {
      await service.refreshRequests();
      // Never one filed earlier that the list had not loaded yet; the hour
      // is a margin for the phone's clock.
      final since = _at.subtract(const Duration(hours: 1));
      for (final r in service.all) {
        if (r.typeName == serviceName && !_before.contains(r.referenceNumber) && r.submittedAt.isAfter(since)) {
          filed = r;
          break;
        }
      }
    } on ApiException {
      return null;
    }
    if (filed == null) return null;
    try {
      // Its requirement rows, for the documents picked on the form.
      return await service.loadDetail(filed.referenceNumber);
    } on ApiException {
      return filed;
    }
  }

  /// What the form says when nothing new was found: after no answer, that
  /// it may still have been filed.
  static String explain(ApiException error) => unanswered(error)
      ? '${error.explain()} ${tr('It may still have been filed: check your requests before you submit again.')}'
      : error.explain();
}

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
    // The purpose is optional, as on the website and the server (19 Nov
    // MSWDO guide review: the app refused an empty one).
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

    final before = await FiledRequestCheck.take(requestsService);
    if (!mounted) return;
    ServiceRequest request;
    try {
      request = await requestsService.submit(
        serviceKey: widget.item.key,
        formData: {
          if (_purposeController.text.trim().isNotEmpty) 'purpose': _purposeController.text.trim(),
          // The website's applicant block, from the account.
          ...applicantFormData(context.read<CitizenSessionService>().account),
        },
        feeInputs: FeeInputs.collect(widget.item.feeInputs, _feeControllers),
      );
    } on ApiException catch (e) {
      // No answer is not "not filed": look before Submit is offered again.
      final filed = await before.find(e, requestsService, serviceName: widget.item.name);
      if (!mounted) return;
      if (filed == null) {
        setState(() {
          _submitting = false;
          _error = FiledRequestCheck.explain(e);
        });
        return;
      }
      request = filed;
    }

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
