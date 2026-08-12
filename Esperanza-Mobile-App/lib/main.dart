import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/root_shell.dart';
import 'services/balita_service.dart';
import 'services/citizen_session_service.dart';
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
      ],
      child: MaterialApp(
        title: 'Esperanza Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Frontend-only auth gate: shows the citizen login flow until a mock
/// session exists, then the main app shell. Mirrors the Web Admin's own
/// pattern of gating routes on `Alpine.store('citizenSession').account`
/// rather than a real server-verified session.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

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
