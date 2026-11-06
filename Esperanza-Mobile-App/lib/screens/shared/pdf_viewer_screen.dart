import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/tr.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/esperanza_art.dart';

/// A PDF, read inside the app (owner, 2026-11-06): My Documents opened every
/// PDF in another app, so a resident left Esperanza to read their own file.
///
/// [load] fetches the file's bytes (a signed link, or the copy on this
/// phone); the screen shows a loader, then the pages to scroll and pinch,
/// or why it could not, with Try Again. Share hands a copy to the phone's
/// share sheet ("Save to device", Drive, a chat), as the Download button on
/// the list does.
///
/// Drawn by pdfx with the phone's own renderer (Android PdfRenderer, iOS
/// PDFKit). On the web build the caller opens the file in the browser
/// instead (see [supported]).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.title, required this.fileName, required this.load});

  final String title;

  /// The name the shared copy is saved under.
  final String fileName;

  final Future<Uint8List> Function() load;

  /// Whether this build can show a PDF in the app. pdfx on the web needs
  /// pdf.js on the page, which this app does not load; the browser's own
  /// viewer is better there anyway.
  static bool get supported => !kIsWeb;

  static const errorTitle = 'This document could not be opened.';
  static const unreadable = 'This PDF could not be shown. Share it to open it in another app.';

  /// Whether a file name or category names a PDF.
  static bool isPdfName(String fileName) => fileName.toLowerCase().trim().endsWith('.pdf');

  /// The bytes behind a (signed) link. Throws when the file cannot be fetched,
  /// or after 30 seconds without it, so the spinner never turns forever (QA
  /// 2026-11-06); the screen then offers Try Again.
  static Future<Uint8List> fetch(Uri uri) async {
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw const _FetchFailed();
    return res.bodyBytes;
  }

  /// Draws the pages. Tests swap it out: pdfx has no platform channel under
  /// `flutter test`.
  @visibleForTesting
  static Widget Function(Uint8List bytes, VoidCallback onError)? debugPagesBuilder;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _FetchFailed implements Exception {
  const _FetchFailed();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late Future<Uint8List> _future;
  Uint8List? _bytes;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _future = _start();
  }

  Future<Uint8List> _start() async {
    final bytes = await widget.load();
    if (bytes.isEmpty) throw const _FetchFailed();
    if (mounted) setState(() => _bytes = bytes);
    return bytes;
  }

  void _retry() => setState(() {
    _bytes = null;
    _future = _start();
  });

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      final dir = await getTemporaryDirectory();
      final name = widget.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/${name.isEmpty ? 'document.pdf' : name}');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: widget.title));
    } catch (_) {
      if (mounted) AppDialogs.toast(context, 'This document could not be downloaded.', success: false);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        titleTextStyle: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: tr('Share'),
            onPressed: _bytes == null || _sharing ? null : _share,
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Uint8List>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: EsperanzaLoader());
            }
            if (snap.hasError || snap.data == null) {
              final err = snap.error;
              return _Problem(
                message: err is ApiException ? err.message() : 'Check your connection and try again.',
                onRetry: _retry,
              );
            }
            return _PdfPages(key: ValueKey(snap.data), bytes: snap.data!);
          },
        ),
      ),
    );
  }
}

/// The pages, scrolled and pinched. A file the renderer cannot read (not a
/// PDF, or damaged) says so; Share still offers it to another app.
class _PdfPages extends StatefulWidget {
  const _PdfPages({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<_PdfPages> createState() => _PdfPagesState();
}

class _PdfPagesState extends State<_PdfPages> {
  PdfControllerPinch? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (PdfViewerScreen.debugPagesBuilder == null) {
      _controller = PdfControllerPinch(document: PdfDocument.openData(widget.bytes));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onError(Object? _) {
    if (mounted && !_failed) setState(() => _failed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _Problem(message: PdfViewerScreen.unreadable);
    final test = PdfViewerScreen.debugPagesBuilder;
    if (test != null) return test(widget.bytes, () => _onError(null));
    return Semantics(
      label: tr('PDF document'),
      child: PdfViewPinch(
        controller: _controller!,
        onDocumentError: _onError,
        backgroundDecoration: const BoxDecoration(color: AppColors.slate100),
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClayBadge(ClayGlyph.error, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text(
              tr(PdfViewerScreen.errorTitle),
              textAlign: TextAlign.center,
              style: AppTypography.cardHeading.copyWith(color: AppColors.navy900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(tr(message), textAlign: TextAlign.center, style: AppTypography.helper.copyWith(color: AppColors.slate600)),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: tr('Try Again'),
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
