import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_client.dart';
import '../../services/json_read.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/date_text.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

import '../../l10n/tr.dart';
/// What GET /verify/{code} says about an issued document
/// (IssuanceService::verify).
class VerifiedDocument {
  const VerifiedDocument({
    required this.authentic,
    required this.controlNumber,
    this.title,
    this.office,
    this.barangay,
    this.issuedOn,
    this.validUntil,
    this.expired = false,
    this.revoked = false,
    this.revokedOn,
    this.revokedReason,
    this.isReprint = false,
    this.holder,
    this.purpose,
    this.checkedByCode = false,
    this.contentSha256,
  });

  /// Who it was issued to and for what - only when checked by its code or
  /// QR, never by the control number alone (privacy, as on the website).
  final String? holder;
  final String? purpose;
  final bool checkedByCode;

  /// Lets a holder confirm their copy is the record, without its contents.
  final String? contentSha256;

  final bool authentic;
  final String controlNumber;
  final String? title;
  final String? office;
  final String? barangay;
  final DateTime? issuedOn;
  final DateTime? validUntil;
  final bool expired;
  final bool revoked;
  final DateTime? revokedOn;
  final String? revokedReason;
  final bool isReprint;

  static VerifiedDocument? fromApi(Map<String, dynamic> m) {
    final control = JsonRead.nonEmpty(m['control_number']);
    if (control == null) return null;
    return VerifiedDocument(
      authentic: JsonRead.boolean(m['authentic']) ?? false,
      controlNumber: control,
      title: JsonRead.nonEmpty(m['title']) ?? JsonRead.nonEmpty(m['service']),
      office: JsonRead.nonEmpty(m['office']),
      barangay: JsonRead.nonEmpty(m['barangay']),
      issuedOn: JsonRead.date(m['issued_on']),
      validUntil: JsonRead.date(m['valid_until']),
      expired: JsonRead.boolean(m['expired']) ?? false,
      revoked: JsonRead.boolean(m['revoked']) ?? false,
      revokedOn: JsonRead.date(m['revoked_on']),
      revokedReason: JsonRead.nonEmpty(m['revoked_reason']),
      isReprint: JsonRead.boolean(m['is_reprint']) ?? false,
      holder: JsonRead.nonEmpty(m['holder']),
      purpose: JsonRead.nonEmpty(m['purpose']),
      checkedByCode: JsonRead.nonEmpty(m['checked_by']) == 'code',
      contentSha256: JsonRead.nonEmpty(m['content_sha256']),
    );
  }
}

/// Verify a document the LGU issued (parity with the website's public Verify
/// page, 2026-10-15): scan its QR code, or type the code printed under it -
/// the verification code or the control number. Public: anyone handed an
/// Esperanza document can check it, signed in or not.
class VerifyDocumentScreen extends StatefulWidget {
  const VerifyDocumentScreen({super.key});

  /// The code inside a scanned QR: the link's `code` or `token`, else its
  /// last path segment, else the text as it is.
  static String codeFrom(String scanned) {
    final text = scanned.trim();
    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      final q = uri.queryParameters['code'] ?? uri.queryParameters['token'];
      if (q != null && q.isNotEmpty) return q;
      final last = uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull;
      if (last != null && last.toLowerCase() != 'verify') return last;
    }
    return text;
  }

  @override
  State<VerifyDocumentScreen> createState() => _VerifyDocumentScreenState();
}

class _VerifyDocumentScreenState extends State<VerifyDocumentScreen> {
  final _code = TextEditingController();
  bool _checking = false;
  VerifiedDocument? _result;
  String? _problem;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check([String? code]) async {
    final c = (code ?? _code.text).trim();
    if (c.isEmpty || _checking) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _checking = true;
      _problem = null;
      _result = null;
    });
    try {
      final res = await api.get('/verify/${ApiClient.segment(c)}');
      final doc = VerifiedDocument.fromApi(res.map);
      setState(() => doc == null ? _problem = 'The answer could not be read. Please try again.' : _result = doc);
    } on ApiException catch (e) {
      setState(
        () => _problem = e.status == 404
            ? 'No document matches this code. Check it against the one printed on the document.'
            : e.status == 429
            ? 'Too many checks in a short time. Please wait a minute and try again.'
            : e.message(),
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _scan() async {
    final photo = await pickImageProtected(
      context,
      source: ImageSource.camera,
      explanation: 'Esperanza needs the camera to read the QR code on the document.',
    );
    if (photo == null || !mounted) return;
    final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    String? value;
    try {
      final codes = await scanner.processImage(InputImage.fromFilePath(photo.path));
      value = codes.map((c) => c.rawValue).whereType<String>().where((v) => v.isNotEmpty).firstOrNull;
    } catch (_) {
      value = null;
    } finally {
      await scanner.close();
    }
    if (!mounted) return;
    if (value == null) {
      setState(() => _problem = 'No QR code was found in the photo. Hold the camera closer, or type the code instead.');
      return;
    }
    final code = VerifyDocumentScreen.codeFrom(value);
    _code.text = code;
    await _check(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Verify a Document'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          Text(
            'Check that a document from the Municipality of Esperanza is genuine and still valid. '
            'Scan its QR code, or type the code printed under it.',
            style: AppTypography.helper,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Scan the QR code',
            icon: Icons.qr_code_scanner_rounded,
            fullWidth: true,
            onPressed: _checking ? null : _scan,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _code,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _check(),
            decoration: InputDecoration(
              labelText: tr('Verification code or control number'),
              hintText: 'e.g. ABCD-EFGH-JKLM',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Check',
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            loading: _checking,
            onPressed: _checking ? null : _check,
          ),
          if (_problem != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              liveRegion: true,
              child: Text(_problem!, style: AppTypography.helper.copyWith(color: AppColors.rose700)),
            ),
          ],
          if (_result != null) ...[const SizedBox(height: AppSpacing.lg), _Result(doc: _result!)],
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.doc});

  final VerifiedDocument doc;

  @override
  Widget build(BuildContext context) {
    // The website's three states, in its words (verify.blade.php).
    final (String headline, String line, Color fg, Color bg, IconData icon) = doc.revoked
        ? ('This document has been revoked and is no longer valid.', 'Reason: ${doc.revokedReason ?? 'Not stated.'}',
            AppColors.rose700, AppColors.rose50, Icons.block_rounded)
        : doc.expired
        ? ('This document is genuine, but it has expired.',
            'It was issued by LGU Esperanza, but its valid-until date has passed. Ask the office for a new one if needed.',
            AppColors.amber700, AppColors.amber50, Icons.history_rounded)
        : ('This document is genuine and valid.', 'It was issued by LGU Esperanza and has not been revoked.',
            AppColors.emerald700, AppColors.emerald50, Icons.verified_rounded);
    final rows = <(String, String)>[
      if (doc.title != null) ('Document', doc.title!),
      ('Control number', doc.controlNumber),
      if (doc.office != null) ('Issuing office', doc.office!),
      if (doc.barangay != null) ('Barangay', doc.barangay!),
      ('Issued on', doc.issuedOn == null ? '—' : shortDate(doc.issuedOn!)),
      // A revoked document's validity no longer counts: when it was revoked does.
      if (doc.revoked)
        ('Revoked on', doc.revokedOn == null ? '—' : shortDate(doc.revokedOn!))
      else
        ('Valid until', doc.validUntil == null ? '—' : shortDate(doc.validUntil!)),
      if (doc.isReprint) ('Copy', 'Reprint'),
    ];
    return Semantics(
      liveRegion: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(headline, style: AppTypography.cardHeading.copyWith(color: fg)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(line, style: AppTypography.helper.copyWith(color: fg)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (doc.holder != null || doc.purpose != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(tr('ISSUED TO'), style: AppTypography.eyebrow.copyWith(color: AppColors.textMuted)),
              if (doc.holder != null) Text(doc.holder!, style: AppTypography.cardHeading),
              if (doc.purpose != null) Text('Purpose: ${doc.purpose}', style: AppTypography.helper),
            ],
            const SizedBox(height: AppSpacing.md),
            // The main defence against a code copied from someone else's paper.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Compare with the paper in your hands'),
                    style: AppTypography.bodySmallMedium.copyWith(color: AppColors.amber700, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final line in const [
                    'Is the name on the paper the same as here?',
                    'Are the document type, control number and dates the same?',
                    'If anything differs, do not accept the paper.',
                  ])
                    Text('• $line', style: AppTypography.helper.copyWith(color: AppColors.amber700)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "The QR or code may have been copied from someone else's document. Report it to the issuing office.",
                    style: AppTypography.fine.copyWith(color: AppColors.amber700),
                  ),
                ],
              ),
            ),
            if (!doc.checkedByCode) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'For privacy, the name is not shown when only the control number is entered. To see who it was '
                'issued to, scan the QR code or enter the 12-character verification code beside it.',
                style: AppTypography.fine.copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 120, child: Text(label, style: AppTypography.helper)),
                    Expanded(
                      child: Text(value, style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No other personal details (address, birth date) are shown here. The QR and verification code are '
              'printed on the paper only.',
              style: AppTypography.fine.copyWith(color: AppColors.textMuted),
            ),
            if (doc.contentSha256 != null)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(tr('Technical details'), style: AppTypography.helper.copyWith(fontWeight: FontWeight.w600)),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        "SHA-256 of the document's content:\n${doc.contentSha256}",
                        style: AppTypography.fine.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
