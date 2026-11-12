import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/document_preview.dart';
import '../theme/app_colors.dart';
import '../utils/esperanza_seal.dart';

import '../l10n/tr.dart';
/// A [DocumentSheet] as the website draws it: one A4 page (210 × 297 mm,
/// 794 × 1123 at 96 dpi), laid out with the website's own sizes, colours and
/// spacing (barangay-certificate-preview / municipal-request-preview and
/// their Tailwind classes), then scaled to the width it is given. Pinch to
/// read it closer where it is shown in full.
class DocumentPaper extends StatelessWidget {
  const DocumentPaper({super.key, required this.sheet, this.barangaySealUrl, this.captureKey});

  final DocumentSheet sheet;

  /// The barangay's own seal, when the server has one; else Esperanza's.
  final String? barangaySealUrl;

  /// Wraps the page, so it can be saved as a picture (Download PDF).
  final GlobalKey? captureKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${sheet.title}, the document as it is printed',
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: RepaintBoundary(
          key: captureKey,
          child: DocumentPage(sheet: sheet, barangaySealUrl: barangaySealUrl),
        ),
      ),
    );
  }
}

/// The page at its real size.
class DocumentPage extends StatelessWidget {
  const DocumentPage({super.key, required this.sheet, this.barangaySealUrl});

  final DocumentSheet sheet;
  final String? barangaySealUrl;

  static const width = 794.0;
  static const height = 1123.0;

  // The website's text: Georgia (a serif where it is missing), slate-800.
  static TextStyle t(
    double size, {
    Color color = AppColors.slate800,
    FontWeight weight = FontWeight.w400,
    double height = 1.5,
    bool italic = false,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: 'serif',
    fontFamilyFallback: const ['Georgia', 'Times New Roman'],
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    letterSpacing: spacing,
  );

  bool get _brgy => sheet.isBarangay;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: t(13),
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.slate200, width: _brgy ? 1 : 2),
        ),
        child: IntrinsicHeight(
          child: Stack(
            children: [
              // The seal behind everything: 68% of the page, 5% strong.
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.05,
                    child: Image.asset(esperanzaSealAsset, width: width * 0.68, excludeFromSemantics: true),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_brgy) ..._barangayHead() else ..._municipalHead(),
                    ..._body(),
                    const Spacer(),
                    if (_brgy) ..._barangayFoot() else ..._municipalFoot(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Heads

  Widget _seal({String? url, required double size, bool gold = false}) {
    final fallback = Image.asset(
      esperanzaSealAsset,
      fit: gold ? BoxFit.cover : BoxFit.contain,
      excludeFromSemantics: true,
    );
    return Container(
      width: size,
      height: size,
      padding: gold ? EdgeInsets.zero : const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: gold ? AppColors.gold400 : AppColors.slate200, width: gold ? 2 : 1),
      ),
      child: ClipOval(
        child: url == null
            ? fallback
            : Image.network(url, fit: BoxFit.contain, excludeFromSemantics: true, errorBuilder: (_, _, _) => fallback),
      ),
    );
  }

  List<Widget> _barangayHead() => [
    Row(
      children: [
        _seal(url: barangaySealUrl, size: 64),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              Text('Republic of the Philippines', style: t(11, color: AppColors.slate500)),
              Text(
                'PROVINCE OF MASBATE',
                style: t(12, color: AppColors.slate700, weight: FontWeight.w600),
              ),
              Text('Municipality of Esperanza', style: t(12, color: AppColors.slate600)),
              Text(
                'Barangay ${sheet.barangay}'.toUpperCase(),
                textAlign: TextAlign.center,
                style: t(14, color: AppColors.navy900, weight: FontWeight.w700, spacing: 0.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _seal(size: 64),
      ],
    ),
    const SizedBox(height: 16),
    Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.slate300)),
      ),
      child: Column(
        children: [
          Text(
            sheet.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: t(18, color: AppColors.navy900, weight: FontWeight.w700, spacing: 0.45).copyWith(
              decoration: TextDecoration.underline,
              decorationThickness: 2,
              decorationColor: AppColors.navy900,
            ),
          ),
          if (sheet.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              sheet.subtitle!,
              textAlign: TextAlign.center,
              style: t(12, color: AppColors.slate500, weight: FontWeight.w500),
            ),
          ],
        ],
      ),
    ),
    const SizedBox(height: 20),
  ];

  List<Widget> _municipalHead() => [
    Row(
      children: [
        _seal(size: 56, gold: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Republic of the Philippines · Province of Masbate', style: t(11, color: AppColors.slate500)),
              Text(
                'MUNICIPALITY OF ESPERANZA',
                style: t(12, color: AppColors.slate700, weight: FontWeight.w600, spacing: 0.3),
              ),
              if (sheet.meta.office != null)
                Text(
                  sheet.meta.office!,
                  style: t(14, color: AppColors.navy900, weight: FontWeight.w700),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.brand100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined, size: 12, color: AppColors.brand700),
                  const SizedBox(width: 6),
                  Text(
                    tr('Request Slip'),
                    style: t(10, color: AppColors.brand700, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (sheet.meta.formNo != null) ...[
              const SizedBox(height: 4),
              Text(sheet.meta.formNo!, style: t(10, color: AppColors.slate500)),
            ],
          ],
        ),
      ],
    ),
    const SizedBox(height: 16),
    Text(
      sheet.title.toUpperCase(),
      textAlign: TextAlign.center,
      style: t(
        16,
        color: AppColors.navy900,
        weight: FontWeight.w700,
        spacing: 0.4,
      ).copyWith(decoration: TextDecoration.underline, decorationThickness: 2, decorationColor: AppColors.navy900),
    ),
    const SizedBox(height: 20),
  ];

  // -- Body

  List<Widget> _body() {
    final lineHeight = sheet.relaxed ? 1.625 : 1.5;
    final blocks = <Widget>[
      if (_brgy) ...[
        Text(
          'TO WHOM IT MAY CONCERN:',
          style: t(13, weight: FontWeight.w600, height: lineHeight),
        ),
        const SizedBox(height: 12),
      ],
    ];
    for (var i = 0; i < sheet.body.length; i++) {
      if (i > 0) blocks.add(SizedBox(height: sheet.bodyGap));
      blocks.add(_block(sheet.body[i], lineHeight));
    }
    if (sheet.closing != null) {
      blocks
        ..add(const SizedBox(height: 16))
        ..add(Text(sheet.closing!, style: t(13, height: lineHeight)));
    }
    return blocks;
  }

  static const _fieldDecoration = TextStyle(
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.dotted,
    decorationColor: AppColors.slate800,
  );

  TextSpan _spans(List<DocSpan> spans) => TextSpan(
    children: [
      for (final s in spans)
        TextSpan(
          text: s.text,
          style: s.field
              ? _fieldDecoration
              : s.bold
              ? const TextStyle(fontWeight: FontWeight.w600)
              : s.muted
              ? const TextStyle(color: AppColors.slate500)
              : null,
        ),
    ],
  );

  Widget _block(DocBlock block, double lineHeight) {
    switch (block) {
      case DocText(:final spans, :final style):
        return switch (style) {
          DocTextStyle.body => Text.rich(_spans(spans), style: t(13, height: lineHeight)),
          DocTextStyle.purpose => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text.rich(
              _spans(spans),
              style: t(12, weight: FontWeight.w600, height: lineHeight),
            ),
          ),
          DocTextStyle.heading => Text.rich(
            _spans([for (final s in spans) DocSpan(s.text.toUpperCase())]),
            textAlign: TextAlign.center,
            style: t(13, weight: FontWeight.w600, height: lineHeight, spacing: 0.33),
          ),
          DocTextStyle.note => Text.rich(_spans(spans), style: t(10, color: AppColors.slate500, italic: true)),
          DocTextStyle.small => Text.rich(_spans(spans), style: t(12, height: lineHeight)),
          DocTextStyle.smallMuted => Text.rich(_spans(spans), style: t(12, color: AppColors.slate500)),
        };
      case DocPairs(:final rows):
        final out = <Widget>[];
        for (var i = 0; i < rows.length; i += 2) {
          if (i > 0) out.add(const SizedBox(height: 8));
          final last = i == rows.length - 1;
          out.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _labelled(rows[i], 6)),
                if (!last) ...[const SizedBox(width: 16), Expanded(child: _labelled(rows[i + 1], 6))],
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: DefaultTextStyle.merge(
            style: t(12),
            child: Column(children: out),
          ),
        );
      case DocList(:final rows, :final heading):
        return DefaultTextStyle.merge(
          style: t(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (heading != null) ...[
                Text(
                  heading.toUpperCase(),
                  style: t(10, color: AppColors.navy900, weight: FontWeight.w700, spacing: 0.5),
                ),
                const SizedBox(height: 6),
              ],
              for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 6), _labelled(rows[i], 8)],
            ],
          ),
        );
      case DocBox(:final rows):
        final children = <Widget>[];
        for (var i = 0; i < rows.length; i++) {
          final ruled = i > 0 && rows[i - 1] is! DocBar;
          children.add(
            Container(
              decoration: ruled
                  ? const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.slate300)),
                    )
                  : null,
              child: _boxRow(rows[i]),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.slate300),
            borderRadius: BorderRadius.circular(2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        );
      case DocInline(:final rows):
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${rows[i].$1}: ',
                          style: const TextStyle(color: AppColors.slate500),
                        ),
                        TextSpan(
                          text: rows[i].$2.isEmpty ? '—' : rows[i].$2,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    style: t(12),
                  ),
                ),
              ],
            ],
          ),
        );
      case DocBoxes(:final labels):
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              for (final l in labels) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: l == 'Picture' ? 24 : 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.slate300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(l, style: t(10, color: AppColors.slate500)),
                ),
                const SizedBox(width: 24),
              ],
            ],
          ),
        );
    }
  }

  /// "Label: answer", the answer on a dotted line to the end.
  Widget _labelled((String, String) row, double gap) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The label as long as it needs (within reason); the dotted line runs
        // from it to the edge, as on the website.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text('${row.$1}:', style: const TextStyle(color: AppColors.slate500)),
        ),
        SizedBox(width: gap),
        Expanded(
          child: CustomPaint(
            foregroundPainter: const _DottedRule(color: AppColors.slate400),
            child: Text(row.$2.isEmpty ? ' ' : row.$2, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }

  Widget _boxRow(DocBoxRow row) {
    switch (row) {
      case DocBar(:final labels):
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: AppColors.slate300),
                Expanded(
                  child: Container(
                    color: AppColors.navy800,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      labels[i].toUpperCase(),
                      style: t(8, color: AppColors.surface, weight: FontWeight.w700, spacing: 0.4),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case DocCells(:final cells):
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) const VerticalDivider(width: 1, thickness: 1, color: AppColors.slate300),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          cells[i].$1.toUpperCase(),
                          style: t(8, color: AppColors.slate500, weight: FontWeight.w600, spacing: 0.4),
                        ),
                        Container(
                          constraints: const BoxConstraints(minHeight: 22.4),
                          padding: const EdgeInsets.only(bottom: 4),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.slate300)),
                          ),
                          child: Text(cells[i].$2, style: t(13, weight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      case DocBoxList(:final rows):
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: 6), _labelled(rows[i], 8)],
            ],
          ),
        );
    }
  }

  // -- Feet

  // Each of Barangay Labangtaytay's papers signs its own way, as the website
  // draws them (2026-11-03): the requester's line and right-thumbmark box,
  // "Certified by:", "Released by" the Secretary, the Jobseeker's Date line.
  List<Widget> _barangayFoot() {
    final key = sheet.meta.key;
    final requester = switch (key) {
      'brgy_residency' || 'brgy_indigency' || 'brgy_first_time_jobseeker' => null,
      'brgy_clearance' || 'brgy_business_clearance' => 'Resident Signature',
      _ => 'Signature over Printed Name of the requester',
    };
    final thumb = key == 'brgy_clearance' || key == 'brgy_business_clearance';
    final certified = key == 'brgy_cert_late_registration' || key == 'brgy_cert_death_registration';
    final released = sheet.barangaySecretary != null && !certified && key != 'brgy_first_time_jobseeker';
    final pbRaw = (sheet.punongBarangay ?? '').trim();
    final pb = pbRaw.isEmpty
        ? 'Hon. Punong Barangay'
        : (key == 'brgy_cert_late_registration'
              ? (RegExp(r'^hon\.?\s', caseSensitive: false).hasMatch(pbRaw) ? pbRaw : 'Hon. $pbRaw')
              : pbRaw.replaceFirst(RegExp(r'^hon\.?\s+', caseSensitive: false), ''));
    Widget line(String caption, {double width = 160}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width,
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate400))),
        ),
        const SizedBox(height: 4),
        Text(caption, style: t(10, color: AppColors.slate500)),
      ],
    );
    return [
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (requester != null)
            Flexible(
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  line(requester, width: 140),
                  if (thumb)
                    Container(
                      width: 86,
                      height: 48,
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.slate500)),
                      child: Text('Right Thumbmark', style: t(8, color: AppColors.slate500)),
                    ),
                ],
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 24),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (certified) ...[
                  Text('Certified by:', style: t(11)),
                  const SizedBox(height: 10),
                ],
                Text(
                  pb.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: t(14, color: AppColors.navy900, weight: FontWeight.w700).copyWith(decoration: TextDecoration.underline),
                ),
                Text('Punong Barangay', style: t(10, color: AppColors.slate500)),
                if (key == 'brgy_first_time_jobseeker') ...[
                  const SizedBox(height: 20),
                  line('Date', width: 120),
                ],
              ],
            ),
          ),
        ],
      ),
      if (released) ...[
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Released by: '),
              TextSpan(
                text: sheet.barangaySecretary!.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate700, decoration: TextDecoration.underline),
              ),
            ],
          ),
          style: t(11, color: AppColors.slate700),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 70),
          child: Text('Barangay Secretary', style: t(10, color: AppColors.slate500)),
        ),
      ],
      if (sheet.validity != null) ...[
        const SizedBox(height: 10),
        Text(sheet.validity!, style: t(11, color: AppColors.slate500)),
      ],
    ..._verifyStrip(),
    const SizedBox(height: 20),
    Text(
      'Not Valid without Barangay Seal',
      textAlign: TextAlign.center,
      style: t(10, color: AppColors.slate500, italic: true),
    ),
    ];
  }

  List<Widget> _municipalFoot() {
    final m = sheet.meta;
    final people = <Widget>[
      if (m.officiant != null) _signatory(m.officiant!, m.officiantTitle ?? '', line: true),
      if (m.technician != null) _signatory(m.technician!, m.technicianTitle ?? ''),
      if (m.verifier != null) _signatory(m.verifier!, m.verifierTitle ?? ''),
    ];
    return [
      if (m.officiant != null || m.technician != null) ...[
        const SizedBox(height: 16),
        const CustomPaint(
          painter: _DottedRule(color: AppColors.slate200, top: true, dash: 6),
          child: SizedBox(height: 16, width: double.infinity),
        ),
        // Two to a row, as the website's grid.
        for (var i = 0; i < people.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: people[i]),
              const SizedBox(width: 16),
              Expanded(child: i + 1 < people.length ? people[i + 1] : const SizedBox.shrink()),
            ],
          ),
        ],
      ],
      ..._verifyStrip(),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.info_outline_rounded, size: 16, color: AppColors.slate500),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(sheet.disclaimer, style: t(11, color: AppColors.slate500)),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _signatory(String name, String title, {bool line = false}) => Column(
    children: [
      if (line) ...[
        Container(
          height: 24,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.slate400)),
          ),
        ),
        const SizedBox(height: 4),
      ],
      Text(
        name.toUpperCase(),
        textAlign: TextAlign.center,
        style: t(12, color: AppColors.navy900, weight: FontWeight.w700),
      ),
      Text(
        title,
        textAlign: TextAlign.center,
        style: t(10, color: AppColors.slate500),
      ),
    ],
  );

  /// The template's note, and once issued the control number, the code and
  /// the QR that opens the verification page (the website's verify strip).
  List<Widget> _verifyStrip() {
    final issued = sheet.issued;
    if (sheet.note == null && issued == null) return const [];
    final url = issued?.verifyUrl;
    final host = url == null ? null : Uri.tryParse(url)?.host;
    final small = t(9, color: AppColors.slate600, height: 1.25);
    const strong = TextStyle(fontWeight: FontWeight.w600, color: AppColors.slate800);
    return [
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (sheet.note != null)
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: (width - 80) * 0.62),
                child: Text(sheet.note!, style: t(10, color: AppColors.slate600, italic: true)),
              ),
            ),
          if (issued != null) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Control No. '),
                        TextSpan(text: issued.controlNumber, style: strong),
                      ],
                    ),
                    style: small,
                  ),
                  if (issued.serial != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Code '),
                          TextSpan(
                            text: issued.serial,
                            style: strong.copyWith(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      style: small,
                    ),
                  if (host != null && host.isNotEmpty)
                    Text('Verify at $host/verify', textAlign: TextAlign.end, style: small),
                ],
              ),
            ),
            if (url != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 79,
                height: 79,
                child: QrImageView(data: url, padding: EdgeInsets.zero, semanticsLabel: 'Verification QR code'),
              ),
            ],
          ],
        ],
      ),
    ];
  }
}

/// A dotted (or dashed) line along the bottom, or the top, of what it paints.
class _DottedRule extends CustomPainter {
  const _DottedRule({required this.color, this.top = false, this.dash = 1.5});

  final Color color;
  final bool top;
  final double dash;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = top ? 0.5 : size.height - 0.5;
    for (var x = 0.0; x < size.width; x += dash * 2) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_DottedRule old) => old.color != color || old.top != top || old.dash != dash;
}
