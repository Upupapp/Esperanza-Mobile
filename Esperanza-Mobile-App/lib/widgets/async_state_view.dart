import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Loading/error/data wrapper for a screen backed by a real API call —
/// the mobile equivalent of the Web Admin's `x-ui.skeleton`/`x-ui.error-state`
/// pair, now that screens fetch from [api] instead of reading [MockCatalog]
/// (production-readiness programme, 2026-09-25). One shared shape for every
/// screen doing this, rather than each screen inventing its own spinner/retry.
class AsyncStateView<T> extends StatefulWidget {
  const AsyncStateView({super.key, required this.loader, required this.builder});

  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;

  @override
  State<AsyncStateView<T>> createState() => _AsyncStateViewState<T>();
}

class _AsyncStateViewState<T> extends State<AsyncStateView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _reload() => setState(() => _future = widget.loader());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(AppSpacing.xxxl), child: CircularProgressIndicator()),
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
            const Icon(Icons.cloud_off_outlined, size: 36, color: AppColors.slate400),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.slate600)),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
