import 'package:flutter/material.dart';
import '../../models/government_id_record.dart';
import '../../widgets/image_viewer_scaffold.dart';

/// Full-screen, pinch-to-zoomable view of a seeded government ID document —
/// same pattern as EventPosterViewer, built on Flutter's own
/// InteractiveViewer rather than a new dependency.
class GovernmentIdViewer extends StatelessWidget {
  final GovernmentIdRecord record;
  const GovernmentIdViewer({super.key, required this.record});

  static void open(BuildContext context, GovernmentIdRecord record) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GovernmentIdViewer(record: record), fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) => ImageViewerScaffold(
    title: record.idType,
    image: AssetImage(record.assetPath),
    semanticLabel: 'Your submitted ${record.idType}',
  );
}
