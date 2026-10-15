import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/service_request.dart';
import '../theme/app_typography.dart';
import '../widgets/app_dialogs.dart';
import 'esperanza_seal.dart';

/// Which printable sheet.
enum RequestSheet { slip, notice }

/// The request slip, and Tulong's notice of approval, as a PDF the resident
/// can print, save or send (parity with the website's Track Request,
/// 2026-10-15; request-extras.blade.php and scope-citizen.js requestExtras):
/// the same letterhead, the reference number with its QR, the same table and
/// the same lines. Made on the phone; it is not an official document.
///
/// The PDF's standard font has no peso sign, so amounts read "PHP".
class RequestSheets {
  RequestSheets._();

  /// The approval notice is offered once a Tulong case is approved.
  static bool noticeReady(ServiceRequest r) =>
      r.category == ServiceCategory.tulong &&
      const ['Assistance Processing', 'Ready for Release', 'Completed'].contains(r.status);

  static String _money(String? raw) {
    final n = double.tryParse((raw ?? '').replaceAll(RegExp(r'[^0-9.]'), ''));
    if (n == null || n <= 0) return '';
    return 'PHP ${NumberFormat('#,##0.00').format(n)}';
  }

  /// What to bring, as the website lists it.
  static List<String> bring(ServiceRequest r, RequestSheet sheet) => [
    'A valid ID with your photo',
    sheet == RequestSheet.notice
        ? 'This notice, or your reference number'
        : 'This slip, or your reference number',
    for (final m in r.missingRequired) m.label,
    if (r.requirementRows.any((q) => q.fileName != null))
      'The originals of the documents you uploaded, in case the office asks to see them',
    if (r.payment != null && r.payment!.amount > 0 && !r.payment!.isPaid)
      'The fee of PHP ${NumberFormat('#,##0.00').format(r.payment!.amount)}, paid at the office',
  ];

  static String _where(ServiceRequest r) {
    final p = r.pickup;
    final place = p == null ? '' : [p.office, p.officeContact].whereType<String>().join(' · ');
    return [if (r.office.isNotEmpty) r.office, if (place.isNotEmpty && p?.office != r.office) place].join(' — ');
  }

  static String noticeBody(ServiceRequest r) {
    final office = r.office.isEmpty ? 'the Municipality' : r.office;
    return r.status == 'Completed'
        ? 'This is to certify that the ${r.typeName} applied for under reference ${r.referenceNumber} was approved '
              'by the $office and has been released to the applicant.'
        : 'This is to inform you that your application for ${r.typeName} under reference ${r.referenceNumber} '
              'has been approved by the $office.';
  }

  /// The PDF itself.
  static Future<List<int>> build(
    ServiceRequest r,
    RequestSheet sheet, {
    required String applicant,
    required String barangay,
    DateTime? now,
  }) async {
    final seal = await rootBundle.load(esperanzaSealAsset).then((b) => pw.MemoryImage(b.buffer.asUint8List()));
    final printed = DateFormat('MMM d, y · h:mm a').format(now ?? DateTime.now());
    final notice = sheet == RequestSheet.notice;
    final dokyu = r.category == ServiceCategory.dokyu;
    final a = r.assistance;

    pw.Widget row(String label, String value) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 130, child: pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700))),
          pw.Expanded(child: pw.Text(value.isEmpty ? '—' : value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );

    final doc = pw.Document(title: notice ? 'Notice of approval ${r.referenceNumber}' : 'Request slip ${r.referenceNumber}');
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Image(seal, width: 56, height: 56),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Republic of the Philippines · Province of Masbate', style: const pw.TextStyle(fontSize: AppTextSize.fine)),
                    pw.Text('Municipality of Esperanza', style: pw.TextStyle(fontSize: AppTextSize.card, fontWeight: pw.FontWeight.bold)),
                    if (r.office.isNotEmpty) pw.Text(r.office, style: const pw.TextStyle(fontSize: AppTextSize.label)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1.5),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        notice ? 'NOTICE OF APPROVAL' : 'REQUEST SLIP',
                        style: pw.TextStyle(fontSize: AppTextSize.section, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
                      ),
                      pw.Text('${dokyu ? 'Dokyu' : 'Tulong'} · Esperanza Citizen App', style: const pw.TextStyle(fontSize: AppTextSize.fine)),
                      pw.SizedBox(height: 10),
                      pw.Text('Reference number', style: const pw.TextStyle(fontSize: AppTextSize.fine, color: PdfColors.grey700)),
                      pw.Text(r.referenceNumber, style: pw.TextStyle(fontSize: AppTextSize.card, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: r.referenceNumber, width: 90, height: 90),
              ],
            ),
            pw.SizedBox(height: 16),
            if (!notice) ...[
              row('Service', r.typeName),
              row('Office', r.office),
              row('Applicant', applicant),
              row('Barangay', barangay),
              row('Date filed', DateFormat('MMM d, y').format(r.submittedAt.toLocal())),
              row('Current status', r.status),
              if (r.purpose.isNotEmpty) row('Purpose', r.purpose),
              pw.SizedBox(height: 14),
              pw.Text('What to bring', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              for (final item in bring(r, sheet)) pw.Bullet(text: item),
              if (_where(r).isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Text('Where to go', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_where(r)),
              ],
            ] else ...[
              pw.Text('To: ${applicant.isEmpty ? '—' : applicant}${barangay.isEmpty ? '' : ', Brgy. $barangay'}'),
              pw.SizedBox(height: 8),
              pw.Text(noticeBody(r), style: const pw.TextStyle(lineSpacing: 3)),
              pw.SizedBox(height: 12),
              row('Tulong', r.typeName),
              if (_money(a?.approvedAmount).isNotEmpty) row('Approved amount', _money(a?.approvedAmount)),
              if (_money(a?.releasedAmount).isNotEmpty) row('Amount received', _money(a?.releasedAmount)),
              if (a?.releasedAt != null) row('Date received', DateFormat('MMM d, y').format(a!.releasedAt!.toLocal())),
              if (a?.releaseReference != null) row('Release reference', a!.releaseReference!),
              row('Status', r.status),
              if (r.status != 'Completed') ...[
                pw.SizedBox(height: 12),
                pw.Text('Where to claim', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_where(r)),
                pw.Text('Bring this notice and a valid ID with your photo.'),
              ],
            ],
            pw.Spacer(),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Printed $printed', style: const pw.TextStyle(fontSize: AppTextSize.fine)),
                pw.Flexible(
                  child: pw.Text(
                    notice
                        ? 'Generated from the Esperanza Citizen App. Not an official receipt.'
                        : 'Show this slip at the office. The status may change after printing.',
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: AppTextSize.fine),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Makes the PDF and hands it to the phone's share sheet: print, save to
  /// Files, or send.
  static Future<void> share(
    BuildContext context,
    ServiceRequest r,
    RequestSheet sheet, {
    required String applicant,
    required String barangay,
  }) async {
    try {
      final bytes = await build(r, sheet, applicant: applicant, barangay: barangay);
      final dir = await getTemporaryDirectory();
      final name = '${sheet == RequestSheet.notice ? 'approval-notice' : 'request-slip'}-${r.referenceNumber}.pdf';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: sheet == RequestSheet.notice ? 'Notice of approval ${r.referenceNumber}' : 'Request slip ${r.referenceNumber}',
        ),
      );
    } catch (_) {
      if (context.mounted) AppDialogs.toast(context, 'The PDF could not be made. Please try again.', success: false);
    }
  }
}
