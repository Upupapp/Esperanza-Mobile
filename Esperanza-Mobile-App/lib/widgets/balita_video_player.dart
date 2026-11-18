import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../l10n/tr.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// A Balita video in the full-screen viewer (2026-10-18): streamed from its
/// signed link (the server answers byte ranges, so it starts at once and can
/// be skipped forward), playing while its page is the one shown ([active]),
/// with play/pause, a scrubbing bar and the time.
class BalitaVideoPlayer extends StatefulWidget {
  final String url;
  final String? posterUrl;
  final bool active;

  const BalitaVideoPlayer({super.key, required this.url, this.posterUrl, this.active = true});

  /// Makes the player for a link. Tests swap it out: video_player has no
  /// platform channel under `flutter test`.
  @visibleForTesting
  static VideoPlayerController Function(Uri url)? debugControllerFactory;

  @override
  State<BalitaVideoPlayer> createState() => _BalitaVideoPlayerState();
}

class _BalitaVideoPlayerState extends State<BalitaVideoPlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final uri = Uri.parse(widget.url);
    final controller = BalitaVideoPlayer.debugControllerFactory?.call(uri) ?? VideoPlayerController.networkUrl(uri);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      setState(() {});
      if (widget.active) await controller.play();
    } catch (_) {
      if (mounted && _controller == controller) setState(() => _failed = true);
    }
  }

  /// Try Again: a new player for the same link. A player that failed, at the
  /// start or partway through (a dropped mobile connection), stays dead:
  /// video_player ignores play() once its value is an error (QA 2026-11-18).
  void _retry() {
    final old = _controller;
    setState(() {
      _controller = null;
      _failed = false;
    });
    old?.dispose();
    _open();
  }

  Widget _failure(String? poster) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (poster != null) Image.network(poster, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        Container(
          color: AppColors.mediaScrimStrong,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This video could not be played. Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.onMedia, fontSize: AppTextSize.helper),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: tr('Try Again'),
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onPressed: _retry,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant BalitaVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c == null || !c.value.isInitialized || oldWidget.active == widget.active) return;
    widget.active ? c.play() : c.pause();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  static String _time(Duration d) {
    final s = d.inSeconds;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final poster = widget.posterUrl;

    // A player that errored after it started has isInitialized false and a
    // zero duration, so it is a failure, not "still loading".
    if (_failed || (c != null && c.value.hasError)) return _failure(poster);

    if (c == null || !c.value.isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (poster != null) Image.network(poster, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          const Center(child: CircularProgressIndicator(color: AppColors.onMedia)),
        ],
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      // A new player after Try Again gets new controls, listening to it.
      key: ObjectKey(c),
      valueListenable: c,
      builder: (context, value, _) {
        // A stream error partway through (a dropped connection): play would
        // do nothing and the time would read 0:00 / 0:00.
        if (value.hasError) return _failure(poster);
        final playing = value.isPlaying;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => playing ? c.pause() : c.play(),
                child: Center(
                  child: AspectRatio(aspectRatio: value.aspectRatio, child: VideoPlayer(c)),
                ),
              ),
            ),
            if (!playing)
              Center(
                child: IgnorePointer(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(color: AppColors.mediaScrim, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.onMedia, size: 40),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, AppSpacing.md, AppSpacing.xs),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppColors.mediaScrimStrong, AppColors.clear],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: playing ? 'Pause' : 'Play',
                      onPressed: () => playing ? c.pause() : c.play(),
                      icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.onMedia),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        c,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        colors: const VideoProgressColors(
                          playedColor: AppColors.onMedia,
                          bufferedColor: AppColors.onMediaMuted,
                          backgroundColor: AppColors.onMediaFaint,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${_time(value.position)} / ${_time(value.duration)}',
                      style: const TextStyle(color: AppColors.onMedia, fontSize: AppTextSize.fine),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
