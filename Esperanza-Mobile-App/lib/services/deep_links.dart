import 'package:flutter/material.dart';

import '../screens/balita/balita_post_screen.dart';

/// The website's links that open in the app (Android App Links,
/// AndroidManifest.xml): a shared Balita post, `/citizen/announcements?post=ID`
/// on the website's address. It always opened the website (parity check,
/// 2026-10-26). Flutter hands the link's path and query over as a route name.
class DeepLinks {
  DeepLinks._();

  /// A post the app was opened with, kept until the main screen is showing
  /// (the splash, sign-in or onboarding come first).
  static int? _pendingPost;

  /// The post a route names, or null.
  static int? postIdOf(String? route) {
    if (route == null) return null;
    final uri = Uri.tryParse(route);
    if (uri == null) return null;
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    if (path != '/citizen/announcements') return null;
    return int.tryParse(uri.queryParameters['post'] ?? '');
  }

  /// The app started from a link: remember its post.
  static void rememberInitial(String? route) => _pendingPost = postIdOf(route);

  /// The post to open now, once; null when there is none.
  static int? takePendingPost() {
    final id = _pendingPost;
    _pendingPost = null;
    return id;
  }

  /// A link while the app is running: its post's screen, or null.
  static Route<void>? routeFor(RouteSettings settings) {
    final id = postIdOf(settings.name);
    if (id == null) return null;
    return MaterialPageRoute<void>(settings: settings, builder: (_) => BalitaPostScreen(announcementId: id));
  }
}
