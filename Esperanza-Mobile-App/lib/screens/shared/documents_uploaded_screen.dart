import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/master_file_document.dart';
import '../../models/uploaded_document.dart';
import '../../services/citizen_session_service.dart';
import '../../services/master_file_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/cross_platform_image.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/segmented_tabs.dart';
import '../../theme/app_typography.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/json_read.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/image_viewer_scaffold.dart';

/// Resident-facing history/library of every document uploaded through a
/// Dokyu or Tulong requirement uploader (see widgets/requirement_uploader.dart)
/// — read-only, no delete.
///
/// Since 2026-10-04 the list is the server's (GET /citizen/uploads): every
/// file attached to the resident's requests, from this phone or the website,
/// each once, with replaced files marked. The phone's own records listed one
/// replacement twice and nothing attached on the website. They remain the
/// fallback when the server cannot be reached. Synced with the resident's Papeles wallet on the
/// server (MasterFileService.syncFromServer). Distinct from the Master File (see
/// MasterFileDocument's own doc comment): the Master File is the reusable
/// "offer this again" canonical copy per document type, one entry per type;
/// this screen instead lists every document a resident has ever uploaded
/// through the app, exactly as it happened, and reads from the very same
/// MasterFileService store without duplicating or reinterpreting its data —
/// no second storage system, per this feature's own scope.
class DocumentsUploadedScreen extends StatefulWidget {
  const DocumentsUploadedScreen({super.key});

  @override
  State<DocumentsUploadedScreen> createState() => _DocumentsUploadedScreenState();
}

class _DocumentsUploadedScreenState extends State<DocumentsUploadedScreen> {
  int _tab = 0; // 0 = All, 1 = Dokyu, 2 = Tulong, 3 = Papeles
  bool _adding = false;

  /// Adds a file to the Papeles wallet, outside any request (parity with the
  /// website's My Documents, 2026-10-15).
  Future<void> _add() async {
    final accountId = context.read<CitizenSessionService>().account?.id;
    if (accountId == null || _adding) return;
    final picked = await pickDocumentProtected(
      context,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      withData: false,
      explanation: 'Esperanza needs access to your files so you can keep a document in your Papeles.',
    );
    final file = picked?.files.singleOrNull;
    if (file == null || file.path == null || !mounted) return;
    final dot = file.name.lastIndexOf('.');
    final name = await _askName(dot > 0 ? file.name.substring(0, dot) : file.name);
    if (name == null || !mounted) return;
    setState(() => _adding = true);
    try {
      await context.read<MasterFileService>().addToWallet(accountId: accountId, name: name, filePath: file.path!);
      if (mounted) AppDialogs.toast(context, 'Added to your Papeles.');
    } on ApiException catch (e) {
      if (mounted) AppDialogs.toast(context, e.message(), success: false);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<String?> _askName(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(hintText: 'e.g. Barangay clearance 2026'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.of(context).pop(v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  /// Null until the server answers; then the list this screen shows.
  List<UploadedDocument>? _uploads;
  bool _uploadsFailed = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({bool report = false}) => Future.wait([_loadUploads(report: report), _sync(report: report)]);

  Future<void> _loadUploads({bool report = false}) async {
    try {
      final res = await api.get('/citizen/uploads');
      final rows = JsonRead.rows(res.list, UploadedDocument.fromJson);
      if (!mounted) return;
      setState(() {
        _uploads = rows;
        _uploadsFailed = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _uploadsFailed = true);
      if (report) AppDialogs.toast(context, e.message(), success: false);
    }
  }

  /// Pulls the resident's Papeles wallet from the server (GET
  /// /citizen/papeles). Offline, the list on this device still shows.
  Future<void> _sync({bool report = false}) async {
    final accountId = context.read<CitizenSessionService>().account?.id;
    if (accountId == null) return;
    try {
      await context.read<MasterFileService>().syncFromServer(accountId);
    } on ApiException catch (e) {
      if (report && mounted) AppDialogs.toast(context, e.message(), success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountId = context.watch<CitizenSessionService>().account?.id;
    final documents = accountId == null
        ? const <MasterFileDocument>[]
        : context.watch<MasterFileService>().documentsFor(accountId);

    final filtered = switch (_tab) {
      1 => documents.where((d) => d.origin == 'Dokyu').toList(),
      2 => documents.where((d) => d.origin == 'Tulong').toList(),
      3 => documents.toList(),
      // documentsFor() returns an unmodifiable list — .toList() here makes
      // a fresh, sortable copy, same as the two branches above already do.
      _ => documents.toList(),
    }..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    // The server's list, newest first, when it has answered.
    final uploads = _uploads;
    final serverRows = uploads == null || _tab == 3
        ? null
        : switch (_tab) {
            1 => uploads.where((d) => d.isDokyu).toList(),
            2 => uploads.where((d) => !d.isDokyu).toList(),
            _ => uploads,
          };
    final isEmpty = serverRows == null ? filtered.isEmpty : serverRows.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Documents Uploaded')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _tab == 3
                    ? 'Your Papeles: documents kept on your account, ready to attach to any request.'
                    : 'Documents you’ve uploaded through Dokyu and Tulong requests.',
                style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.lg),
              SegmentedTabs(
                labels: const ['All', 'Dokyu', 'Tulong', 'Papeles'],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              if (_tab == 3) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Add a document',
                  icon: Icons.add_rounded,
                  variant: AppButtonVariant.secondary,
                  fullWidth: true,
                  loading: _adding,
                  onPressed: _adding ? null : _add,
                ),
              ] else if (serverRows == null && _uploadsFailed) ...[
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Showing the documents saved on this phone. Pull down to load everything you uploaded, from the '
                  'app or the website.',
                  style: TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted, height: 1.4),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refresh(report: true),
                  child: isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _tab == 3
                                ? const EmptyState(
                                    icon: Icons.folder_open_outlined,
                                    title: 'No documents in your Papeles yet',
                                    description:
                                        'Add an ID, a certificate or any document to keep it here and attach it to '
                                        'a request later.',
                                  )
                                : const EmptyState(
                                    icon: Icons.folder_open_outlined,
                                    title: 'No documents uploaded yet',
                                    description:
                                        'Documents you upload while submitting a Dokyu or Tulong request will '
                                        'appear here.',
                                  ),
                          ],
                        )
                      : serverRows != null
                      ? ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                          itemCount: serverRows.length,
                          itemBuilder: (context, i) => _UploadCard(document: serverRows[i]),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => _DocumentCard(document: filtered[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

({Color bg, Color fg, IconData icon}) _styleFor(AttachmentCategory category) => switch (category) {
    AttachmentCategory.image => (bg: AppColors.brand50, fg: AppColors.brand500, icon: Icons.image_outlined),
    AttachmentCategory.pdf => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.picture_as_pdf_outlined),
    AttachmentCategory.docx => (bg: AppColors.blue50, fg: AppColors.blue700, icon: Icons.description_outlined),
    AttachmentCategory.video => (bg: AppColors.rose50, fg: AppColors.rose600, icon: Icons.videocam_outlined),
    AttachmentCategory.other => (
      bg: AppColors.slate100,
      fg: AppColors.slate500,
      icon: Icons.insert_drive_file_outlined,
    ),
  };

Widget _tag(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.full),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

/// One file from the server's list. Opens through its signed link; a file
/// the scan has not cleared says why it cannot be opened.
class _UploadCard extends StatelessWidget {
  final UploadedDocument document;
  const _UploadCard({required this.document});

  Future<void> _open(BuildContext context) async {
    final reason = document.unavailableReason;
    if (reason != null) {
      AppDialogs.toast(context, reason, success: false);
      return;
    }
    final uri = Uri.tryParse(document.url!);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) AppDialogs.toast(context, 'This document could not be opened.', success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = AttachmentCategoryX.fromExtension(document.extension);
    final s = _styleFor(category);
    final when = document.uploadedAt;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: () => _open(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(s.icon, size: 20, color: s.fg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.requirement,
                    style: const TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _tag(document.isDokyu ? 'Dokyu' : 'Tulong', document.isDokyu ? AppColors.brand600 : AppColors.purple700),
                      if (document.service != null) _tag(document.service!, AppColors.slate600),
                      _tag(document.ref, AppColors.slate600),
                      if (!document.current) _tag('Replaced', AppColors.slate500),
                      Text(
                        when == null
                            ? category.shortLabel
                            : '${category.shortLabel} · ${DateFormat('MMM d, y').format(when)}',
                        style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              document.url != null ? Icons.open_in_new_rounded : Icons.hourglass_empty_rounded,
              size: 18,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final MasterFileDocument document;
  const _DocumentCard({required this.document});

  bool get _isDokyu => document.origin == 'Dokyu';

  Future<void> _openRemote(BuildContext context) async {
    try {
      final url = await context.read<MasterFileService>().downloadUrl(document);
      final uri = url == null ? null : Uri.tryParse(url);
      if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) AppDialogs.toast(context, 'This document could not be opened.', success: false);
      }
    } on ApiException catch (e) {
      if (context.mounted) AppDialogs.toast(context, e.message(), success: false);
    }
  }

  void _openViewer(BuildContext context) {
    final provider = pickedFileImageProvider(bytes: document.attachment.bytes, path: document.attachment.localPath);
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _DocumentViewer(title: document.label, provider: provider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(document.attachment.category);
    final isImage = document.attachment.category == AttachmentCategory.image;
    final canPreview =
        isImage &&
        pickedFileImageProvider(bytes: document.attachment.bytes, path: document.attachment.localPath) != null;

    // A copy that lives only on the server opens through a short-lived
    // signed link (GET /citizen/papeles/{id}/download).
    final isRemote = document.id.startsWith('pap-');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: canPreview
            ? () => _openViewer(context)
            : isRemote
            ? () => _openRemote(context)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(s.icon, size: 20, color: s.fg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.label,
                    style: const TextStyle(
                      fontSize: AppTextSize.body,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    document.attachment.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _tag(document.origin, _isDokyu ? AppColors.brand600 : AppColors.purple700),
                      if (document.serviceName != null) _tag(document.serviceName!, AppColors.slate600),
                      Text(
                        '${document.attachment.category.shortLabel} · ${DateFormat('MMM d, y').format(document.uploadedAt)}',
                        style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (canPreview) const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.slate400),
          ],
        ),
      ),
    );
  }
}

/// Same simple InteractiveViewer pattern as every other in-app document/ID
/// viewer (see RequirementUploader's own _AttachmentImageViewer,
/// GovernmentIdViewer). [provider] is null when this document's bytes
/// weren't persisted across an app restart (see Attachment's own doc
/// comment on why `bytes` is excluded from JSON) — shown as a plain
/// message instead of crashing.
class _DocumentViewer extends StatelessWidget {
  final String title;
  final ImageProvider? provider;
  const _DocumentViewer({required this.title, required this.provider});

  @override
  Widget build(BuildContext context) =>
      ImageViewerScaffold(title: title, image: provider, semanticLabel: title);
}
