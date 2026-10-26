import 'package:flutter/widgets.dart';

import '../services/message_language.dart';

/// Redraws every screen, the ones already open included, when the language
/// changes: tr() is read at build time, so a screen built before the change
/// would otherwise keep the old language until it rebuilt for some other
/// reason. Nothing is reloaded and no screen is closed.
class LanguageScope extends StatefulWidget {
  final Widget child;
  const LanguageScope({super.key, required this.child});

  @override
  State<LanguageScope> createState() => _LanguageScopeState();
}

class _LanguageScopeState extends State<LanguageScope> {
  @override
  void initState() {
    super.initState();
    MessageLanguage.filipino.addListener(_changed);
  }

  @override
  void dispose() {
    MessageLanguage.filipino.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    void redraw(Element e) {
      e.markNeedsBuild();
      e.visitChildren(redraw);
    }

    (context as Element).visitChildren(redraw);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
