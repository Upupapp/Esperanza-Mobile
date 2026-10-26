import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/access_level.dart';
import '../services/citizen_session_service.dart';
import '../widgets/restricted_feature_notice.dart';

/// Reacting and commenting need a signed-in resident, verified or not:
/// the website lets any resident like and comment, and the server asks
/// only for a citizen session. A Guest gets the same reusable account
/// notice any other protected interaction shows, rather than the action
/// silently no-op'ing. Public viewing (opening and zooming the post image)
/// and sharing a post's link stay open to everyone. Shared by [PostCard]
/// and [PostImageViewer] so both surfaces enforce the exact same rule
/// instead of two copies quietly drifting apart.
///
/// [minLevel] defaults to [AccessLevel.unverified] (a signed-in account).
/// Reporting a Sakuna incident passes the same, the backend's own rule.
/// (Residents do not post to Balita at all, owner 2026-10-20: only the
/// LGU does.)
void requireAccountForBalita(
  BuildContext context,
  String featureName,
  VoidCallback action, {
  AccessLevel minLevel = AccessLevel.unverified,
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
