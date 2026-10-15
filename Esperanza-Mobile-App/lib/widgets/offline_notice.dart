import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/message_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The offline notice, as on the website (parity, 2026-10-15; the website's
/// app.js offlineNotice): a pill at the top of every screen while the server
/// cannot be reached, "You are back online" for a moment when it can again.
/// While offline it asks the server again every [probeEvery], so the notice
/// clears on its own even when no screen is loading anything.
class OfflineNotice extends StatefulWidget {
  const OfflineNotice({super.key, required this.child, this.probeEvery = const Duration(seconds: 20)});

  final Widget child;
  final Duration probeEvery;

  @override
  State<OfflineNotice> createState() => _OfflineNoticeState();
}

enum _State { hidden, offline, backOnline }

class _OfflineNoticeState extends State<OfflineNotice> {
  _State _state = _State.hidden;
  Timer? _probe;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    ApiClient.unreachable.addListener(_changed);
    if (ApiClient.unreachable.value) _changed();
  }

  @override
  void dispose() {
    ApiClient.unreachable.removeListener(_changed);
    _probe?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  void _changed() {
    final offline = ApiClient.unreachable.value;
    _hide?.cancel();
    if (offline) {
      _probe ??= Timer.periodic(widget.probeEvery, (_) => _ask());
      setState(() => _state = _State.offline);
    } else {
      _probe?.cancel();
      _probe = null;
      if (_state != _State.offline) return;
      setState(() => _state = _State.backOnline);
      _hide = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _state = _State.hidden);
      });
    }
  }

  Future<void> _ask() async {
    try {
      await api.get('/portal-settings');
    } catch (_) {
      // Still offline; the client has said so.
    }
  }

  @override
  Widget build(BuildContext context) {
    final fil = MessageLanguage.filipino.value;
    final online = _state == _State.backOnline;
    final text = online
        ? (fil ? 'May koneksyon na muli.' : 'You are back online.')
        : (fil
              ? 'Walang koneksyon sa internet. Hindi masi-save ang mga pagbabago hangga’t walang koneksyon.'
              : 'No internet connection. Nothing can be saved until you are back online.');
    return Stack(
      children: [
        widget.child,
        if (_state != _State.hidden)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Center(
              child: Semantics(
                liveRegion: true,
                container: true,
                child: Material(
                  color: online ? AppColors.emerald700 : AppColors.navy900,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          size: AppSizes.iconSm,
                          color: AppColors.surface,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            text,
                            style: AppTypography.helper.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
