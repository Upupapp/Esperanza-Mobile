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
void requireAccountForBalita(BuildContext context, String featureName, VoidCallback action) {
  final level = context.read<CitizenSessionService>().accessLevel;
  if (level != AccessLevel.verified) {
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
