import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/root_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'services/balita_service.dart';
import 'services/citizen_session_service.dart';
import 'services/notifications_service.dart';
import 'services/requests_service.dart';
import 'services/resident_profile_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const EsperanzaMobileApp());
}

class EsperanzaMobileApp extends StatelessWidget {
  const EsperanzaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => RequestsService()),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(
        title: 'Esperanza Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // SplashScreen (every launch) hands off to either the first-run
        // welcome flow or straight to AuthGate — see splash_screen.dart's
        // doc comment for why every handoff uses pushReplacement rather
        // than push, which matters a great deal here: AuthGate must stay
        // the *root* route (index 0) for RootShell/RestrictedFeatureNotice's
        // `popUntil((route) => route.isFirst)` calls to keep working — see
        // AuthGate's own doc comment for the history behind that.
        home: const SplashScreen(),
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
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();

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
