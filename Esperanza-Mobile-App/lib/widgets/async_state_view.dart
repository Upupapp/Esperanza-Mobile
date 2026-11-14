import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'esperanza_art.dart';
import 'live_refresh.dart';

import '../l10n/tr.dart';
/// Loading/error/data wrapper for a screen backed by a real API call —
/// the mobile equivalent of the Web Admin's `x-ui.skeleton`/`x-ui.error-state`
/// pair, now that screens fetch from [api] instead of reading [MockCatalog]
/// (production-readiness programme, 2026-09-25). One shared shape for every
/// screen doing this, rather than each screen inventing its own spinner/retry.
class AsyncStateView<T> extends StatefulWidget {
  const AsyncStateView({super.key, required this.loader, required this.builder, this.liveTopics = const {}});

  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;

  /// Live updates (2026-11-15, [LiveRefresh]): when one of these topics
  /// moves while the data shows, [loader] runs again in the background and
  /// its data replaces what is shown, with no loader in between; a failure
  /// keeps what is shown. None by default.
  final Set<String> liveTopics;

  @override
  State<AsyncStateView<T>> createState() => _AsyncStateViewState<T>();
}

class _AsyncStateViewState<T> extends State<AsyncStateView<T>> {
  late Future<T> _future;

  /// [_future] came back with data (it is not loading, and not an error).
  bool _hasData = false;

  /// [_future] is a quiet reload's data: for the one frame before
  /// FutureBuilder reports it, the data already shown stays, not the loader.
  bool _quiet = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final future = widget.loader();
    _future = future;
    _hasData = false;
    _quiet = false;
    future.then((_) {
      if (identical(_future, future)) _hasData = true;
    }, onError: (Object _) {});
  }

  // A block, not an arrow: an arrow returns the assigned Future, which
  // setState refuses (an assertion in debug builds, hit by every Retry and
  // by a screen reloading itself, 2026-10-27).
  void _reload() => setState(() {
    _load();
  });

  /// Only over data: while it still loads, or shows an error with Try Again,
  /// that is what the screen shows. Throws when the loader fails.
  Future<void> _reloadQuietly() async {
    if (!_hasData) return;
    final data = await widget.loader();
    if (!mounted) return;
    setState(() {
      _future = Future<T>.value(data);
      _hasData = true;
      _quiet = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          if (_quiet) return widget.builder(context, snapshot.data as T, _reload);
          return const Center(
            child: Padding(padding: EdgeInsets.all(AppSpacing.xxxl), child: EsperanzaLoader()),
          );
        }
        if (snapshot.hasError) {
          final err = snapshot.error;
          final message = err is ApiException ? err.message() : 'Something went wrong. Please try again.';
          return _ErrorState(message: message, onRetry: _reload);
        }
        return widget.builder(context, snapshot.data as T, _reload);
      },
    );
    if (widget.liveTopics.isEmpty) return view;
    return LiveRefresh(topics: widget.liveTopics, onChange: (_) => _reloadQuietly(), child: view);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClayBadge(ClayGlyph.error, size: 64),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.navy900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate600, height: 1.4)),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: tr('Try Again'), icon: Icons.refresh_rounded, variant: AppButtonVariant.secondary, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
