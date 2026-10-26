import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../widgets/app_dialogs.dart';

/// "Your Document" as an A4 PDF the resident can print, save or send. Like
/// the website's Download PDF (html2pdf: a picture of the page, placed on
/// A4), it is the very page shown on screen ([DocumentPaper]), so the two
/// cannot differ. A reference copy, made on the phone.
class DocumentPdf {
  DocumentPdf._();

  /// The page inside [captureKey]'s RepaintBoundary as a PNG, sharp enough
  /// to print (about 240 dpi on A4).
  static Future<Uint8List> capture(GlobalKey captureKey) async {
    final boundary = captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.5);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return png!.buffer.asUint8List();
  }

  /// One A4 page holding the picture, edge to edge.
  static Future<List<int>> fromPng(Uint8List png, {required String title}) {
    final picture = pw.MemoryImage(png);
    final doc = pw.Document(title: title, author: 'Municipality of Esperanza');
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(child: pw.Image(picture, fit: pw.BoxFit.contain)),
      ),
    );
    return doc.save();
  }

  /// Makes the PDF from the page on screen and hands it to the phone's share
  /// sheet: print, save to Files, or send.
  static Future<void> share(
    BuildContext context,
    GlobalKey captureKey, {
    required String title,
    required String fileName,
  }) async {
    try {
      final bytes = await fromPng(await capture(captureKey), title: title);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], subject: title),
      );
    } catch (_) {
      if (context.mounted) AppDialogs.toast(context, 'The PDF could not be made. Please try again.', success: false);
    }
  }
}
