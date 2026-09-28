import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/cross_platform_image.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_section.dart';
import '../../theme/app_typography.dart';
import '../../services/support_service.dart';
import '../../services/api_client.dart';

const _categories = SupportService.categories;

/// A simple "report a problem" form reachable from Help & Support.
///
///
/// Files a real support ticket (POST /citizen/support/tickets, see
/// [SupportService]); the confirmation shows the ticket reference staff
/// will use. It replaced a simulation that discarded every report.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  String _category = _categories.first;
  final _subject = TextEditingController();
  final _description = TextEditingController();
  Uint8List? _screenshotBytes;
  String? _screenshotName;
  String? _screenshotPath;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final file = await pickImageProtected(context, source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _screenshotBytes = bytes;
      _screenshotName = file.name;
      _screenshotPath = file.path.isEmpty ? null : file.path;
    });
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _description.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in both the subject and description.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final String ref;
    try {
      ref = await SupportService.fileTicket(
        category: _category,
        subject: _subject.text,
        body: _description.text,
        attachmentPath: _screenshotPath,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message();
      });
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    await AppDialogs.info(
      context,
      title: 'Report Submitted',
      message:
          'Salamat! Your report was sent to Esperanza LGU as ticket $ref. Keep this reference if you contact the '
          'office about it. For anything urgent, use the contact details on the Help & Support page.',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Problem')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppColors.amber700),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Your report goes to the Esperanza LGU support desk, and you\'ll get a ticket number. '
                    'For emergencies, call a hotline instead.',
                    style: TextStyle(fontSize: AppTextSize.label, color: AppColors.amber700, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FormSection(
            title: 'Problem Details',
            children: [
              AppSelectField<String>(
                label: 'Category',
                value: _category,
                options: _categories,
                labelBuilder: (c) => c,
                onChanged: (v) => setState(() => _category = v!),
              ),
              AppTextField(label: 'Subject', controller: _subject, hintText: 'Briefly describe the problem'),
              AppTextField(
                label: 'Description',
                controller: _description,
                hintText: 'What happened? What were you trying to do?',
                maxLines: 5,
              ),
              _ScreenshotField(
                bytes: _screenshotBytes,
                fileName: _screenshotName,
                onPick: _pickScreenshot,
                onRemove: () => setState(() {
                  _screenshotBytes = null;
                  _screenshotName = null;
                  _screenshotPath = null;
                }),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Submit Report',
            fullWidth: true,
            size: AppButtonSize.lg,
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _ScreenshotField extends StatelessWidget {
  final Uint8List? bytes;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ScreenshotField({required this.bytes, required this.fileName, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screenshot (optional)',
          style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (bytes != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image(
                    image: pickedFileImageProvider(bytes: bytes)!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    fileName ?? 'Screenshot attached',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove attachment',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate400),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
            label: const Text('Attach a screenshot'),
          ),
      ],
    );
  }
}
