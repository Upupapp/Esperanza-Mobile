import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/attachment_picker.dart';
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
  final List<Attachment> _attachments = [];
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_purposeController.text.trim().isEmpty) {
      setState(() => _error = 'Please describe the purpose of this request.');
      return;
    }
    if (_attachments.isEmpty) {
      setState(() => _error = 'Please attach at least one requirement document or photo.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final account = context.read<CitizenSessionService>().account!;
    final requestsService = context.read<RequestsService>();
    await Future.delayed(const Duration(milliseconds: 900)); // simulated network/processing delay

    final request = await requestsService.submit(
          applicantId: account.id,
          applicantName: account.fullName,
          typeName: widget.item.name,
          category: widget.category,
          office: widget.item.office,
          purpose: _purposeController.text.trim(),
          expectedDays: widget.item.days,
          attachments: _attachments,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RequestSubmittedScreen(
          referenceNumber: request.referenceNumber,
          typeName: request.typeName,
          accent: widget.accent,
          onViewRequest: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id)),
          ),
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
                        const SizedBox(width: 8),
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
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist_rounded, size: 16, color: widget.accent),
                        const SizedBox(width: 8),
                        const Text('Requirements', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...widget.item.requirements.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.emerald500),
                            const SizedBox(width: 8),
                            Expanded(child: Text(r, style: const TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.3))),
                          ],
                        ),
                      ),
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
              const Text('Attach Requirements', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Take a photo or choose a file for each requirement above.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: AppSpacing.md),
              AttachmentPicker(
                documentTypeLabel: widget.item.name,
                attachments: _attachments,
                onAdd: (a) => setState(() => _attachments.add(a)),
                onRemove: (id) => setState(() => _attachments.removeWhere((a) => a.id == id)),
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
          CircleAvatar(radius: 7, backgroundColor: widget.accent, child: Text('$n', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700))),
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
