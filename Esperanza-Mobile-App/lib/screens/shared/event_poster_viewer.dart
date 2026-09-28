import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../widgets/image_viewer_scaffold.dart';

/// Full-screen event poster view — the entire poster, pinch-to-zoomable,
/// so dates/times/team names printed on it stay legible even after the
/// card's own thumbnail necessarily shrinks a tall portrait poster to fit
/// a small card. Built on Flutter's built-in `InteractiveViewer` rather
/// than a new image-viewer dependency.
class EventPosterViewer extends StatelessWidget {
  final EventItem event;
  const EventPosterViewer({super.key, required this.event});

  static void open(BuildContext context, EventItem event) {
    if (event.imagePath == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EventPosterViewer(event: event), fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) => ImageViewerScaffold(
    title: event.title,
    image: AssetImage(event.imagePath!),
    semanticLabel: 'Poster for ${event.title}',
  );
}
