import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/access_level.dart';
import '../services/citizen_session_service.dart';
import '../widgets/restricted_feature_notice.dart';

/// Reacting/commenting/sharing are all Verified-only actions — Guest AND
/// signed-in-but-Unverified (e.g. Nicanor) both get the same reusable
/// account/verification notice any other protected interaction shows,
/// rather than the action silently no-op'ing. Public viewing (including
/// opening/zooming the post image) stays open to everyone regardless —
/// this gate only wraps the react/comment/share callbacks, never the image
/// viewer's open action itself. Shared by [PostCard] and [PostImageViewer]
/// so both surfaces enforce the exact same rule instead of two copies
/// quietly drifting apart.
///
/// [minLevel] defaults to [AccessLevel.verified] (react/comment/share's own
/// long-standing rule) but is overridable — reporting a Sakuna incident is
/// open to an unverified citizen (the backend's own rule), so its caller
/// passes [AccessLevel.unverified]. Loosening the default here would change
/// react/comment/share's own policy. (Residents no longer post to Balita at
/// all, owner 2026-10-20: only the LGU does.)
void requireAccountForBalita(
  BuildContext context,
  String featureName,
  VoidCallback action, {
  AccessLevel minLevel = AccessLevel.verified,
}) {
  final level = context.read<CitizenSessionService>().accessLevel;
  if (level.index < minLevel.index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestrictedFeatureNotice(
          reason: level == AccessLevel.guest ? RestrictionReason.guestOnly : RestrictionReason.needsVerification,
          featureName: featureName,
        ),
      ),
    );
    return;
  }
  action();
}
