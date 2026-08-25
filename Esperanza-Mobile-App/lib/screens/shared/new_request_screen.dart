import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/master_file_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/requirement_document_type.dart';
import '../../utils/tulong_eligibility.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/requirement_uploader.dart';
import 'request_detail_screen.dart';
import 'request_submitted_screen.dart';

/// Step 2 of the request wizard: requirements checklist (informational),
/// purpose, real attachment upload, and submit. Validates required fields
/// and requires at least one attachment before allowing submission —
/// "validate the fields... allow attachments... show confirmation" per
/// Section 5 of the alignment doc.
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

  /// One entry per requirement, keyed by its own label (unique within a
  /// single catalog item) — every Dokyu and Tulong service uses this same
  /// per-requirement architecture (see RequirementUploader and the Dokyu +
  /// Tulong requirement-upload standardization pass); there is no separate
  /// flat/generic attachment list anymore.
  late final List<RequirementInfo> _requirementInfos = resolveRequirements(widget.item.requirements);
  final Map<String, Attachment?> _requirementAttachments = {};

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  String? _requirementsError() {
    // requiresUpload excludes a requirement that isn't something the
    // resident attaches a file for (a staff/office process, or descriptive
    // text already captured elsewhere) — see RequirementInfo.requiresUpload.
    final missing = _requirementInfos
        .where((r) => r.isRequired && r.requiresUpload && _requirementAttachments[r.label] == null)
        .toList();
    if (missing.isEmpty) return null;
    if (missing.length == 1) return 'Please attach your ${missing.first.label}.';
    return 'Please attach: ${missing.map((r) => r.label).join(', ')}.';
  }

  Future<void> _submit() async {
    if (_purposeController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the purpose of this request.');
      return;
    }
    final err = _requirementsError();
    if (err != null) {
      setState(() => _error = err);
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
    await Future.delayed(const Duration(milliseconds: 900)); // simulated network/processing delay

    final attachments = _requirementAttachments.values.whereType<Attachment>().toList();

    final request = await requestsService.submit(
      applicantId: account.id,
      applicantName: account.fullName,
      typeName: widget.item.name,
      category: widget.category,
      office: widget.item.office,
      purpose: _purposeController.text.trim(),
      expectedDays: widget.item.days,
      attachments: attachments,
      requiresPayment: widget.item.fee != 'Free',
      fee: widget.item.fee,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
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
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Requirements',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Attach a document for each requirement below.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.md),
              Consumer<MasterFileService>(
                builder: (context, masterFile, _) {
                  final accountId = context.read<CitizenSessionService>().account!.id;
                  return Column(
                    children: [
                      for (final req in _requirementInfos)
                        RequirementUploader(
                          requirement: req,
                          attachment: _requirementAttachments[req.label],
                          accent: widget.accent,
                          existingMasterDoc: masterFile.findByType(accountId, req.documentType),
                          onAttachNew: (a) {
                            setState(() => _requirementAttachments[req.label] = a);
                            masterFile.saveOrUpdate(
                              accountId: accountId,
                              documentType: req.documentType,
                              label: req.label,
                              attachment: a,
                              origin: widget.category == ServiceCategory.dokyu ? 'Dokyu' : 'Tulong',
                              serviceName: widget.item.name,
                            );
                          },
                          onUseExisting: () {
                            final existing = masterFile.findByType(accountId, req.documentType);
                            if (existing != null) {
                              setState(
                                () => _requirementAttachments[req.label] =
                                    attachmentForReuse(existing.attachment, requirementLabel: req.label),
                              );
                            }
                          },
                          onRemove: () => setState(() => _requirementAttachments[req.label] = null),
                        ),
                    ],
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Submit Request',
                icon: Icons.send_rounded,
                onPressed: _submit,
                loading: _submitting,
                fullWidth: true,
                size: AppButtonSize.lg,
              ),
            ],
          ),
        ),
      ),
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
