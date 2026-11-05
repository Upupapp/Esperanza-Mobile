import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/resident_certificate.dart';
import '../services/json_read.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/esperanza_seal.dart';

/// A signatory under the certificate's body.
class CertificateSignatory {
  const CertificateSignatory({required this.name, this.position = '', this.accreditationNo, this.accreditationValidUntil});
  final String name;
  final String position;
  final String? accreditationNo;
  final String? accreditationValidUntil;
}

/// The certificate as drawn: the website's `buildCertificate`
/// (resources/js/welfare-certificate.js), from the document's own
/// field_values first, then what the row knows. The certificate itself is an
/// official document, in English as the office issues it on paper.
class CertificateSheet {
  const CertificateSheet({
    required this.title,
    required this.subtitle,
    required this.names,
    required this.holders,
    required this.body,
    required this.office,
    required this.signatories,
    required this.control,
    required this.code,
    required this.issuedLong,
    required this.given,
    required this.verifyUrl,
    required this.verifyHost,
    required this.revoked,
  });

  static const _office = 'Municipal Social Welfare and Development Office';
  static const _eventBody = 'This is to certify that :name participated in :event held on :date at :venue.';
  static const _sessionBody = 'This is to certify that :names attended the session on :date at :venue.';

  final String title;
  final String subtitle;
  final String names;
  final List<String> holders;
  final String body;
  final String office;
  final List<CertificateSignatory> signatories;
  final String control;
  final String code;
  final String issuedLong;
  final String given;
  final String verifyUrl;
  final String verifyHost;
  final bool revoked;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// `12 November 2026`, as an LGU certificate writes a date (in English,
  /// whatever the phone's language: it is the paper's wording).
  static String longDate(DateTime? d) => d == null ? '' : '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// `12th day of November 2026`, for the Given line.
  static String givenDate(DateTime? d) {
    if (d == null) return '';
    final n = d.day;
    final suffix = n % 100 >= 11 && n % 100 <= 13 ? 'th' : const {1: 'st', 2: 'nd', 3: 'rd'}[n % 10] ?? 'th';
    return '$n$suffix day of ${_months[d.month - 1]} ${d.year}';
  }

  static CertificateSheet of(ResidentCertificate c) {
    final fv = c.fieldValues;
    String? s(String key) => JsonRead.nonEmpty(fv[key]);
    final names = c.holderNames.join(' and ');
    final date = longDate(JsonRead.date(fv['session_date']) ?? JsonRead.date(fv['event_date']) ?? c.date);
    final venue = s('venue') ?? s('session_venue') ?? c.venue ?? (c.isEvent ? 'Esperanza, Masbate' : '');
    final event = s('cert_subtitle') ?? c.eventTitle ?? '';
    final body = s('body') ??
        (c.isEvent ? _eventBody : _sessionBody)
            .replaceAll(RegExp(r':names?\b'), names)
            .replaceAll(RegExp(r':event\b'), event.isEmpty ? 'the event' : event)
            .replaceAll(':date', date)
            .replaceAll(':venue', venue.isEmpty ? 'the $_office' : venue);
    final fvOffice = s('office') ?? '';
    final eventOffice = RegExp(r'^municipality of esperanza$', caseSensitive: false).hasMatch(fvOffice) ? '' : fvOffice;
    final host = Uri.tryParse(c.verifyUrl ?? '')?.host ?? '';
    return CertificateSheet(
      title: s('cert_title') ?? c.title ?? 'Certificate',
      subtitle: s('cert_subtitle') ?? '',
      names: names,
      holders: c.holderNames,
      body: body,
      office: s('office_name') ?? (c.isEvent ? eventOffice : _office),
      signatories: _signatories(fv),
      control: c.controlNumber,
      code: c.serial ?? '',
      issuedLong: longDate(c.issuedOn),
      given: givenDate(c.issuedOn),
      verifyUrl: c.verifyUrl ?? '',
      verifyHost: host.isEmpty ? '' : '$host/verify',
      revoked: c.revoked,
    );
  }

  /// The document's own signatories; else its facilitators (the accredited
  /// counselors only when it is signed by them); else the office head.
  static List<CertificateSignatory> _signatories(Map<String, dynamic> fv) {
    final own = JsonRead.list(fv['signatories']);
    var rows = own.isNotEmpty ? own : JsonRead.list(fv['facilitators']);
    if (own.isEmpty && JsonRead.string(fv['signed_by']) == 'counselor') {
      final counselors = rows.where((f) => JsonRead.string(JsonRead.map(f)?['role']) == 'counselor').toList();
      if (counselors.isNotEmpty) rows = counselors;
    }
    if (rows.isEmpty && fv['office_head'] != null) {
      final head = JsonRead.map(fv['office_head']);
      rows = [
        {
          'name': head == null ? fv['office_head'] : head['name'],
          'position': (head == null ? fv['office_head_position'] : head['position']) ??
              'Municipal Social Welfare and Development Officer',
        },
      ];
    }
    return [
      for (final raw in rows)
        if (JsonRead.map(raw) case final f? when JsonRead.nonEmpty(f['name']) != null)
          CertificateSignatory(
            name: JsonRead.nonEmpty(f['name'])!,
            position: JsonRead.string(f['position']) ?? '',
            accreditationNo: JsonRead.nonEmpty(f['accreditation_no']),
            accreditationValidUntil: JsonRead.nonEmpty(f['accreditation_valid_until']),
          ),
    ];
  }
}

/// The certificate page at its real size: A4 landscape (the website's
/// `.cert-paper`, app.css), every size a share of the page's width as the
/// website's `cqw` units are, so it reads the same scaled to a phone.
class CertificatePaper extends StatelessWidget {
  const CertificatePaper({super.key, required this.sheet});

  final CertificateSheet sheet;

  static const width = 1123.0;
  static const height = width * 210 / 297;

  /// One `cqw`: a hundredth of the page's width.
  static const _u = width / 100;

  static TextStyle _serif(double size, {Color color = AppColors.slate800, FontWeight weight = FontWeight.w400, bool italic = false, double height = 1.35, double spacing = 0}) =>
      TextStyle(
        fontFamily: 'serif',
        fontFamilyFallback: const ['Georgia', 'Times New Roman'],
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        height: height,
        letterSpacing: spacing,
      );

  static TextStyle _sans(double size, {Color color = AppColors.slate700, FontWeight weight = FontWeight.w400, double spacing = 0}) =>
      TextStyle(fontFamily: AppTypography.sans, fontSize: size, color: color, fontWeight: weight, height: 1.35, letterSpacing: spacing);

  /// The body with the holders' names in bold, as they are typed on paper.
  List<TextSpan> _bodySpans() {
    final strong = _serif(_u * 1.75, color: AppColors.slate800, weight: FontWeight.w700, height: 1.6);
    if (sheet.holders.isEmpty) return [TextSpan(text: sheet.body)];
    final pattern = RegExp(sheet.holders.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var at = 0;
    for (final m in pattern.allMatches(sheet.body)) {
      if (m.start > at) spans.add(TextSpan(text: sheet.body.substring(at, m.start)));
      spans.add(TextSpan(text: m.group(0), style: strong));
      at = m.end;
    }
    if (at < sheet.body.length) spans.add(TextSpan(text: sheet.body.substring(at)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    const frameInset = _u * 2.2;
    const rule = _u * 0.15;
    const innerWidth = width - 2 * frameInset - 6 * rule - 2 * _u * 4;
    final s = sheet;
    return Semantics(
      label: s.title,
      container: true,
      child: Container(
        width: width,
        height: height,
        color: AppColors.surface,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(frameInset),
                // The website's double rule.
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.navy600, width: rule)),
                  child: Padding(
                    padding: const EdgeInsets.all(rule),
                    child: DecoratedBox(
                      decoration: BoxDecoration(border: Border.all(color: AppColors.navy600, width: rule)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(_u * 4, _u * 2.2, _u * 4, _u * 1.8),
                        child: Column(
                          children: [
                            // Long wording shrinks to fit the page rather
                            // than running off it (the website clips).
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: SizedBox(width: innerWidth, child: _upper(s)),
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: _u * 4,
                              runSpacing: _u * 1.6,
                              children: [for (final g in s.signatories) _sign(g)],
                            ),
                            const SizedBox(height: _u * 1.6),
                            _foot(s),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (s.revoked)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.rotate(
                      angle: -18 * math.pi / 180,
                      child: Text(
                        'REVOKED',
                        style: _sans(_u * 9, color: AppColors.rose600.withValues(alpha: 0.18), weight: FontWeight.w700, spacing: _u * 0.9),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _upper(CertificateSheet s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(esperanzaSealAsset, width: _u * 8.5, height: _u * 8.5, fit: BoxFit.contain, semanticLabel: 'Seal of the Municipality of Esperanza'),
            const SizedBox(width: _u * 2),
            Column(
              children: [
                Text('Republic of the Philippines', style: _sans(_u * 1.15)),
                Text('Province of Masbate', style: _sans(_u * 1.15)),
                Text('MUNICIPALITY OF ESPERANZA', style: _sans(_u * 1.5, color: AppColors.slate800, weight: FontWeight.w700, spacing: _u * 0.06)),
                if (s.office.isNotEmpty) Text(s.office, style: _sans(_u * 1.15)),
              ],
            ),
          ],
        ),
        const SizedBox(height: _u * 2.4),
        Text(
          s.title.toUpperCase(),
          textAlign: TextAlign.center,
          style: _serif(_u * 3.6, color: AppColors.navy600, weight: FontWeight.w700, height: 1.1, spacing: _u * 0.22),
        ),
        if (s.subtitle.isNotEmpty) ...[
          const SizedBox(height: _u * 0.6),
          Text(s.subtitle, textAlign: TextAlign.center, style: _serif(_u * 1.45, color: AppColors.slate600, italic: true)),
        ],
        const SizedBox(height: _u * 2.4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _u * 82),
          child: Text.rich(
            TextSpan(children: _bodySpans()),
            textAlign: TextAlign.center,
            style: _serif(_u * 1.55, height: 1.6),
          ),
        ),
        if (s.given.isNotEmpty) ...[
          const SizedBox(height: _u * 1.4),
          Text(
            'Given this ${s.given} at the Municipality of Esperanza, Masbate, Philippines.',
            textAlign: TextAlign.center,
            style: _serif(_u * 1.3, color: AppColors.slate700),
          ),
        ],
        const SizedBox(height: _u * 1.6),
      ],
    );
  }

  Widget _sign(CertificateSignatory g) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _u * 20, maxWidth: _u * 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: _u * 0.3),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.slate800, width: _u * 0.12))),
            child: Text(g.name.toUpperCase(), textAlign: TextAlign.center, style: _sans(_u * 1.3, color: AppColors.slate800, weight: FontWeight.w700)),
          ),
          const SizedBox(height: _u * 0.3),
          if (g.position.isNotEmpty) Text(g.position, textAlign: TextAlign.center, style: _sans(_u * 1.05)),
          if (g.accreditationNo != null)
            Text(
              'DSWD Accreditation No. ${g.accreditationNo}${g.accreditationValidUntil == null ? '' : ' (valid until ${g.accreditationValidUntil})'}',
              textAlign: TextAlign.center,
              style: _sans(_u * 0.95, color: AppColors.slate600),
            ),
        ],
      ),
    );
  }

  Widget _foot(CertificateSheet s) {
    final line = _sans(_u * 0.95, color: AppColors.slate600);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(children: [const TextSpan(text: 'Control No. '), TextSpan(text: s.control, style: const TextStyle(fontWeight: FontWeight.w700))]),
                style: line,
              ),
              if (s.issuedLong.isNotEmpty) Text('Issued ${s.issuedLong}', style: line),
              if (s.code.isNotEmpty) Text('Verification code ${s.code}', style: line),
              if (s.verifyHost.isNotEmpty) Text('Scan the QR code or visit ${s.verifyHost} to check this certificate.', style: line),
            ],
          ),
        ),
        const SizedBox(width: _u * 2),
        SizedBox(
          width: _u * 8,
          height: _u * 8,
          child: s.verifyUrl.isEmpty
              ? null
              : QrImageView(data: s.verifyUrl, padding: EdgeInsets.zero, semanticsLabel: 'QR code to verify this certificate'),
        ),
      ],
    );
  }
}
