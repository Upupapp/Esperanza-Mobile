import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/root_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'services/barangay_service.dart';
import 'services/balita_service.dart';
import 'services/citizen_session_service.dart';
import 'services/master_file_service.dart';
import 'services/notifications_service.dart';
import 'services/push_service.dart';
import 'services/requests_service.dart';
import 'services/message_language.dart';
import 'services/resident_profile_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/language_scope.dart';
import 'widgets/offline_notice.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MessageLanguage.load();
  // The LGU's Default Language, until the resident picks one; not awaited.
  unawaited(MessageLanguage.followServerDefault());
  // The barangay list from the server, for every picker; not awaited.
  unawaited(BarangayService.warmUp());
  // Push notifications, when this build has its Firebase file.
  await PushService.start();
  runApp(const EsperanzaMobileApp());
}

class EsperanzaMobileApp extends StatelessWidget {
  const EsperanzaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Every screen redraws in the new language when it changes.
    return LanguageScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          // Dokyu/Tulong requests come from the real backend now (production-
          // readiness programme, 2026-09-25) -- there is no local demo-seed
          // simulation left to configure.
          ChangeNotifierProvider(create: (_) => RequestsService()),
          ChangeNotifierProvider(create: (_) => BalitaService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
          ChangeNotifierProvider(create: (_) => MasterFileService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
        ],
        child: MaterialApp(
          title: 'Esperanza Mobile',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          // A tapped push opens its screen; one arriving in the app shows a banner.
          navigatorKey: PushService.navigatorKey,
          scaffoldMessengerKey: PushService.messengerKey,
          // "No internet connection", over every screen, as on the website.
          builder: (context, child) => OfflineNotice(child: child ?? const SizedBox.shrink()),
          // SplashScreen (every launch) hands off to either the first-run
          // welcome flow or straight to AuthGate — see splash_screen.dart's
          // doc comment for why every handoff uses pushReplacement rather
          // than push, which matters a great deal here: AuthGate must stay
          // the *root* route (index 0) for RootShell/RestrictedFeatureNotice's
          // `popUntil((route) => route.isFirst)` calls to keep working — see
          // AuthGate's own doc comment for the history behind that.
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

/// Frontend-only auth gate: shows the citizen login flow until a mock
/// session exists, then the main app shell. Mirrors the Web Admin's own
/// pattern of gating routes on `Alpine.store('citizenSession').account`
/// rather than a real server-verified session.
///
/// Must remain the *root* route once reached (see SplashScreen/
/// OnboardingScreen, which both reach it via `pushReplacement`, never
/// `push`) — RootShell.jumpTo and RestrictedFeatureNotice's "back to
/// root" actions rely on `Navigator.popUntil((route) => route.isFirst)`
/// landing here. A previous bug (see git history around this comment)
/// came from a button pushing a *second* RootShell on top of this one
/// instead of trusting AuthGate to react to session changes on its own.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Signed in (not a guest) on the last build.
  bool _wasSignedIn = false;

  /// The session ended while the resident was inside the app (the server
  /// refused the sign-in: expired, revoked, or the account removed). Pages
  /// opened on top of this one would stay on screen showing "Authentication
  /// is required" with a Try Again that can never work (2026-10-13), so they
  /// are closed and the reason is said once on the sign-in screen. Only on
  /// that change: Register opened from sign-in is left alone.
  void _sessionEnded({required bool byServer}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      if (byServer) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Your session has ended. Please sign in again.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final signedIn = session.isSignedIn && !session.isGuest;
    if (_wasSignedIn && !signedIn && !session.loading) _sessionEnded(byServer: session.endedByServer);
    if (!session.loading) _wasSignedIn = signedIn;

    if (session.loading) {
      return const Scaffold(
        backgroundColor: AppColors.navy900,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!session.isSignedIn && !session.isGuest) {
      return const LoginScreen();
    }

    return RootShell.withKey();
  }
}
