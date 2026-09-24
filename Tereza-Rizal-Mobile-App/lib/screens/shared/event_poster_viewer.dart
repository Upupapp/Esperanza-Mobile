import 'package:flutter/material.dart';
import '../../models/announcement.dart';

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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventPosterViewer(event: event), fullscreenDialog: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // The app's global AppBarTheme sets an explicit titleTextStyle
        // (navy, for the normal white app bars everywhere else), which
        // overrides a local foregroundColor for the title specifically —
        // icons still follow foregroundColor, but the title needs its own
        // override here or it renders dark on this black header.
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.asset(event.imagePath!, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
