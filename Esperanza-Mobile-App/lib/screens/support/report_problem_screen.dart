import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/service_request.dart';
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
import '../../services/requests_service.dart';

import '../../l10n/tr.dart';
const _categories = SupportService.categories;

/// A simple "report a problem" form reachable from Suporta.
///
///
/// Files a real support ticket (POST /citizen/support/tickets, see
/// [SupportService]); the confirmation shows the ticket reference staff
/// will use. It replaced a simulation that discarded every report.
class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key, this.initialSubject, this.initialCategory, this.initialRequestRef});

  /// Prefilled when a closed ticket is followed up with a new one.
  final String? initialSubject;
  final String? initialCategory;
  final String? initialRequestRef;

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  late String _category = _categories.contains(widget.initialCategory) ? widget.initialCategory! : _categories.first;
  late final _subject = TextEditingController(text: widget.initialSubject);
  final _description = TextEditingController();
  Uint8List? _screenshotBytes;
  String? _screenshotName;
  String? _screenshotPath;
  bool _submitting = false;
  String? _error;

  /// The request the ticket is about ('' for none), as on the website:
  /// the ticket then goes to the office handling that request.
  late String _requestRef = widget.initialRequestRef ?? '';
  List<ServiceRequest> _requests = const [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  /// The resident's Dokyu and Tulong requests, newest first.
  Future<void> _loadRequests() async {
    final service = context.read<RequestsService?>();
    if (service == null) return;
    if (!service.loaded) {
      try {
        await service.loadRequests();
      } catch (_) {
        // The ticket can still be filed without a request.
      }
    }
    if (!mounted) return;
    setState(() {
      _requests = service.all.where((r) => r.category != ServiceCategory.sakunaIncident).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    });
  }

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot(ImageSource source) async {
    final file = await pickImageProtected(
      context,
      source: source,
      maxDimension: 1600,
      explanation: source == ImageSource.camera
          ? 'Esperanza needs the camera so you can take a photo of the problem for your report.'
          : 'Esperanza needs access to your photos so you can attach a photo or screenshot to your report.',
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _screenshotBytes = bytes;
      _screenshotName = file.name;
      _screenshotPath = file.path.isEmpty ? null : file.path;
    });
  }

  /// A PDF instead of a photo, as the website's form takes either.
  Future<void> _pickPdf() async {
    final result = await pickDocumentProtected(
      context,
      allowedExtensions: const ['pdf'],
      explanation: 'Choose a PDF to attach to your report. Esperanza only reads the file you pick.',
    );
    final file = result?.files.singleOrNull;
    if (file == null || file.path == null || !mounted) return;
    setState(() {
      _screenshotBytes = file.bytes ?? Uint8List(0);
      _screenshotName = file.name;
      _screenshotPath = file.path;
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
        requestRef: _requestRef,
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
          'office about it. For anything urgent, use the contact details on the Suporta page.',
    );
    if (mounted) Navigator.of(context).pop();
  }

  Widget _relatedRequestField() {
    final refs = ['', ..._requests.map((r) => r.referenceNumber)];
    // A follow-up's request may not be in the list (yet): keep it chosen.
    if (!refs.contains(_requestRef)) refs.add(_requestRef);
    String label(String ref) {
      if (ref.isEmpty) return 'None';
      final r = _requests.where((r) => r.referenceNumber == ref).firstOrNull;
      return r == null ? ref : [r.referenceNumber, r.typeName, r.status].where((p) => p.isNotEmpty).join(' · ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSelectField<String>(
          key: ValueKey('related-request-${refs.length}'),
          label: tr('Related request (optional)'),
          value: _requestRef,
          options: refs,
          labelBuilder: label,
          onChanged: (v) => setState(() => _requestRef = v ?? ''),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          tr('The ticket goes to the office handling that request.'),
          style: AppTypography.fine.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
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
                label: tr('Category'),
                value: _category,
                options: _categories,
                labelBuilder: (c) => c,
                onChanged: (v) => setState(() => _category = v!),
              ),
              AppTextField(label: 'Subject', controller: _subject, hintText: 'Briefly describe the problem'),
              _relatedRequestField(),
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
                onPickPdf: _pickPdf,
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
            Text(
              _error!,
              style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: tr('Submit Report'),
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
  final void Function(ImageSource source) onPick;
  final VoidCallback onPickPdf;
  final VoidCallback onRemove;

  const _ScreenshotField({
    required this.bytes,
    required this.fileName,
    required this.onPick,
    required this.onPickPdf,
    required this.onRemove,
  });

  bool get _isPdf => (fileName ?? '').toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo, screenshot or PDF (optional)',
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
                if (_isPdf)
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.rose50,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, size: 22, color: AppColors.rose600),
                  )
                else
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
                    style: const TextStyle(
                      fontSize: AppTextSize.helper,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate700,
                    ),
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
          // A photo of the problem itself (a broken streetlight, a blocked
          // canal) is as useful as a screenshot of the app (scope round
          // 2026-10-15: feedback with photos).
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 17),
                label: const Text('Take a photo'),
              ),
              OutlinedButton.icon(
                onPressed: () => onPick(ImageSource.gallery),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
                label: const Text('Attach a screenshot'),
              ),
              OutlinedButton.icon(
                onPressed: onPickPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                label: const Text('Attach a PDF'),
              ),
            ],
          ),
      ],
    );
  }
}
