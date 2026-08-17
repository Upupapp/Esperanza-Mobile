import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/announcement.dart';
import '../services/citizen_session_service.dart';
import '../widgets/restricted_feature_notice.dart';

/// Reacting/commenting/sharing are all account actions — a Guest gets the
/// same reusable "create an account or sign in" notice any other
/// protected interaction shows, rather than the action silently no-op'ing.
/// Shared by [PostCard] and [PostImageViewer] so both surfaces enforce the
/// exact same rule instead of two copies quietly drifting apart. Ronaldo
/// (signed in, unverified) is *not* treated as a Guest here — Balita
/// engagement only requires an account, not verification.
void requireAccountForBalita(BuildContext context, String featureName, VoidCallback action) {
  if (context.read<CitizenSessionService>().isGuest) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RestrictedFeatureNotice(reason: RestrictionReason.guestOnly, featureName: featureName)),
    );
    return;
  }
  action();
}

/// Shares a Balita post through the OS's native share sheet (share_plus)
/// — never a bespoke Facebook/X integration — using only the post's own
/// existing author/body, never invented text. Shared by [PostCard] and
/// [PostImageViewer] so the exact same share text/behavior applies
/// regardless of where Share was tapped from.
Future<void> shareBalitaPost(BuildContext context, Announcement post, VoidCallback onShared) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
  final who = post.isOfficial ? 'Esperanza LGU' : post.author;
  final excerpt = post.body.trim();
  final text = [
    '$who — Balita, Esperanza',
    if (excerpt.isNotEmpty) excerpt,
  ].join('\n\n');
  await SharePlus.instance.share(ShareParams(text: text, subject: 'Balita: $who', sharePositionOrigin: origin));
  onShared();
}
