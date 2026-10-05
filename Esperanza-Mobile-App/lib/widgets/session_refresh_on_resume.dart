import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../services/citizen_session_service.dart';

/// Re-reads the citizen's account whenever the app comes back to the
/// foreground.
///
/// The session was only re-read at sign-in and at app launch, so a status the
/// LGU changed while the app sat in the background -- most often verifying
/// the account -- did not reach the resident until a full restart. They kept
/// seeing "Digital ID not yet available ... Pending Review" and stayed locked
/// out of Dokyu and Tulong with the approval already on the server.
///
/// Lives here rather than in [CitizenSessionService] because it needs a
/// Flutter binding, which the service's own unit tests do not create.
class SessionRefreshOnResume extends StatefulWidget {
  const SessionRefreshOnResume({super.key, required this.child});

  final Widget child;

  @override
  State<SessionRefreshOnResume> createState() => _SessionRefreshOnResumeState();
}

class _SessionRefreshOnResumeState extends State<SessionRefreshOnResume> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<CitizenSessionService>().revalidate();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
