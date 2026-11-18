import 'package:flutter/material.dart';

import '../screens/balita/balita_post_screen.dart';
import '../screens/home/root_shell.dart';

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

  /// A link while the app is running: its post's screen. Any other link (the
  /// Balita page itself, or a post value that is not a number) shows the
  /// Balita tab: with no route for it, Flutter threw for want of an
  /// onUnknownRoute and nothing opened (QA 2026-11-18).
  static Route<void> routeFor(RouteSettings settings) {
    final id = postIdOf(settings.name);
    if (id != null) {
      return MaterialPageRoute<void>(settings: settings, builder: (_) => BalitaPostScreen(announcementId: id));
    }
    final path = Uri.tryParse(settings.name ?? '')?.path ?? '';
    return PageRouteBuilder<void>(
      settings: settings,
      opaque: false,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => _LinkLanding(toBalita: path.startsWith('/citizen/announcements')),
    );
  }
}

/// A link with no screen of its own: closes at once, showing the Balita tab
/// for a Balita link, and whatever was showing for anything else.
class _LinkLanding extends StatefulWidget {
  const _LinkLanding({required this.toBalita});

  final bool toBalita;

  @override
  State<_LinkLanding> createState() => _LinkLandingState();
}

class _LinkLandingState extends State<_LinkLanding> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.toBalita) RootShell.jumpTo(context, 1);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
