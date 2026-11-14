import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/live_updates.dart';

/// Reloads what a screen shows when the server says it changed (live
/// updates, 2026-11-15; see [LiveUpdates]).
///
/// When one of [topics] moves while [child] is on show - its tab is the one
/// selected in RootShell's IndexedStack, and its page is on top with no
/// other page or dialog over it - [onChange] runs at once. When it moves
/// while [child] is hidden nothing is read then: [onChange] runs once as soon
/// as [child] shows again, however often the topic moved meanwhile. One
/// reload at a time; a change that comes in during one reloads again after.
///
/// [onChange] reloads quietly: what is on screen stays until the new data
/// arrives (no loader, the scroll position kept), and stays if the reload
/// fails. A failure is thrown, not shown: the next change, or the next time
/// [child] shows, tries again. Reads only - a reload must never write, or
/// the write's own change would set every open app reloading again.
class LiveRefresh extends StatefulWidget {
  const LiveRefresh({super.key, required this.topics, required this.onChange, required this.child});

  /// The [LiveUpdates] topics whose data [child] shows.
  final Set<String> topics;

  /// Reloads it, told which of [topics] moved.
  final Future<void> Function(Set<String> moved) onChange;

  final Widget child;

  @override
  State<LiveRefresh> createState() => _LiveRefreshState();
}

class _LiveRefreshState extends State<LiveRefresh> {
  late final LiveUpdates _live;

  /// Each topic's [LiveUpdates.stamp] as of the last reload (or the start).
  final Map<String, int> _seen = {};
  bool _onShow = false;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _live = LiveUpdates.instance..addListener(_onLive);
    for (final topic in widget.topics) {
      _seen[topic] = _live.stamp([topic]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Called again when its tab is switched to or away from, and when a page
    // opens over it or closes. Only this widget rebuilds then: [build] hands
    // back the same child.
    _onShow = Visibility.of(context) && (ModalRoute.isCurrentOf(context) ?? true);
    // After this frame: a reload tells listeners, which must not happen while
    // the tree is being built.
    if (_onShow) WidgetsBinding.instance.addPostFrameCallback((_) => _onLive());
  }

  @override
  void dispose() {
    _live.removeListener(_onLive);
    super.dispose();
  }

  void _onLive() => unawaited(_catchUp());

  Future<void> _catchUp() async {
    if (_reloading || !mounted || !_onShow) return;
    final moved = {
      for (final topic in widget.topics)
        if (_live.stamp([topic]) != (_seen[topic] ?? 0)) topic,
    };
    if (moved.isEmpty) return;
    final before = Map.of(_seen);
    for (final topic in moved) {
      _seen[topic] = _live.stamp([topic]);
    }
    _reloading = true;
    try {
      await widget.onChange(moved);
    } catch (_) {
      // What is shown stays; the next change, or the next time it shows,
      // tries again.
      _seen
        ..clear()
        ..addAll(before);
      return;
    } finally {
      _reloading = false;
    }
    // A change that came in while it reloaded.
    await _catchUp();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
