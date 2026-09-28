import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/access_level.dart';
import '../../models/citizen_account.dart';
import '../../models/digital_credential.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/digital_id_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../utils/digital_credentials.dart';
import '../../utils/date_text.dart';
import '../../utils/esperanza_seal.dart';
import '../../widgets/app_card.dart';
import '../../theme/app_typography.dart';
import '../../widgets/image_viewer_scaffold.dart';

/// Esperanza Digital ID — a resident's own wallet for *official,
/// already-issued* digital government/LGU credentials (Barangay Resident
/// ID, PWD ID today; National ID, PhilHealth, Senior Citizen, and other
/// future LGU credentials simply by adding another DigitalCredential
/// record — see utils/digital_credentials.dart). Interaction inspired by
/// eGovPH's own credential-wallet UX in concept only — no eGovPH branding,
/// and this project has no real integration with eGovPH, PhilSys,
/// PhilHealth, or any other government database.
///
/// The physical ID a resident uploads during registration is a *different*
/// concept entirely — that's evidence submitted for LGU verification, shown
/// at Profile > Personal Information > Submitted Government ID (see
/// resident_profile/personal_information_screen.dart), never here. Only a
/// verified account's wallet is shown; an unverified account (including a
/// duplicate registration still Pending Review) sees an explanatory state
/// instead.
class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account!;
    final isVerified = session.accessLevel == AccessLevel.verified;

    return Scaffold(
      appBar: AppBar(title: const Text('Digital ID')),
      body: isVerified
          ? _LiveOrWallet(account: account)
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
              children: [_NotYetVerifiedCard(account: account)],
            ),
    );
  }
}

/// The credential-stack wallet itself — entirely data-driven off
/// [credentials]; nothing here branches on a specific credential's type.
/// Tap the active card to flip it front/back; swipe up/down to move
/// between credentials. See this file's own inline comments per gesture.
class _DigitalIdWallet extends StatefulWidget {
  final List<DigitalCredential> credentials;

  /// Shown above the wallet; says why the live card is not here.
  final Widget? notice;
  const _DigitalIdWallet({required this.credentials, this.notice});

  @override
  State<_DigitalIdWallet> createState() => _DigitalIdWalletState();
}

class _DigitalIdWalletState extends State<_DigitalIdWallet> with TickerProviderStateMixin {
  static const _aspectRatio = 1.58; // matches the seeded ID assets' own ~1573x1000 proportions
  static const _peekVisible = 20.0;

  // A resting stacked-behind credential renders at this fraction of the
  // active card's size/opacity — a compact wallet-deck edge, never a
  // second full-size, fully-readable ID directly behind the active one.
  // Both interpolate up to 1.0 as a drag brings that card toward becoming
  // active, so it visibly "rises and grows" into place rather than
  // popping in at full size the instant it's committed.
  static const _peekRestScale = 0.90;
  static const _peekRestOpacity = 0.5;

  int _activeIndex = 0;
  double _dragOffset = 0;
  bool _dragging = false;
  double _swipeFrom = 0;
  double _swipeTo = 0;

  late final AnimationController _flipController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addListener(() => setState(() {}));

  late final AnimationController _swipeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _flipController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  DigitalCredential get _active => widget.credentials[_activeIndex];
  DigitalCredential? get _next =>
      _activeIndex + 1 < widget.credentials.length ? widget.credentials[_activeIndex + 1] : null;
  DigitalCredential? get _previous => _activeIndex > 0 ? widget.credentials[_activeIndex - 1] : null;
  bool get _showingBack => _flipController.value > 0.5;

  /// The active card's current vertical offset — live-tracks the finger
  /// while dragging, or eases toward its settle target once released
  /// (either committing to the neighboring credential or springing back).
  double get _currentOffset {
    if (_swipeController.isAnimating) {
      final t = Curves.easeOutCubic.transform(_swipeController.value);
      return _swipeFrom + (_swipeTo - _swipeFrom) * t;
    }
    return _dragOffset;
  }

  void _toggleFlip() {
    // Guards against the tap firing mid-drag/mid-settle — the gesture
    // arena already disambiguates tap vs. drag on movement, but this is a
    // cheap extra guarantee a swipe can never also flip the card.
    if (_dragging || _swipeController.isAnimating) return;
    if (_flipController.value > 0.5) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  void _onDragStart(DragStartDetails _) {
    if (_swipeController.isAnimating) return;
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details, double step) {
    if (!_dragging) return;
    setState(() {
      _dragOffset += details.delta.dy;
      if (_previous == null) _dragOffset = _dragOffset.clamp(-step, 0.0);
      if (_next == null) _dragOffset = _dragOffset.clamp(0.0, step);
      _dragOffset = _dragOffset.clamp(-step, step);
    });
  }

  void _onDragEnd(DragEndDetails details, double step) {
    setState(() => _dragging = false);
    final velocity = details.primaryVelocity ?? 0;
    const distanceFraction = 0.32;
    const velocityThreshold = 700.0;

    final wantsNext = (_dragOffset <= -step * distanceFraction || velocity <= -velocityThreshold) && _next != null;
    final wantsPrev = (_dragOffset >= step * distanceFraction || velocity >= velocityThreshold) && _previous != null;

    if (wantsNext) {
      _settle(target: -step, nextIndex: _activeIndex + 1);
    } else if (wantsPrev) {
      _settle(target: step, nextIndex: _activeIndex - 1);
    } else {
      _settle(target: 0, nextIndex: _activeIndex);
    }
  }

  void _settle({required double target, required int nextIndex}) {
    _swipeFrom = _dragOffset;
    _swipeTo = target;
    _swipeController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _activeIndex = nextIndex;
        _dragOffset = 0;
        // Predictable demo behavior: every newly-active credential opens on
        // its front side, regardless of how the previous one was left.
        _flipController.value = 0;
      });
    });
  }

  void _jumpTo(int index) {
    if (_dragging || _swipeController.isAnimating) return;
    setState(() {
      _activeIndex = index;
      _dragOffset = 0;
      _flipController.value = 0;
    });
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _CredentialFullScreenViewer(
          credential: _active,
          front: !_showingBack,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.credentials.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: const [_EmptyWalletCard()],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        if (widget.notice != null) ...[widget.notice!, const SizedBox(height: AppSpacing.lg)],
        _PositionIndicator(activeIndex: _activeIndex, total: widget.credentials.length),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            // Capped, not just full-width: on a wide viewport (tablet,
            // desktop/wide Flutter Web) an uncapped card grows tall enough
            // to push the info panel and View Full Screen button off the
            // bottom of the screen. A resident-card-sized max keeps the
            // wallet looking like a wallet on every screen size, centered
            // when the available width exceeds it.
            final cardWidth = math.min(constraints.maxWidth, 420.0);
            final cardHeight = cardWidth / _aspectRatio;
            final step = cardHeight - _peekVisible;
            final stackHeight = cardHeight + _peekVisible;

            return Center(
              child: SizedBox(
                width: cardWidth,
                height: stackHeight,
                child: GestureDetector(
                  key: const ValueKey('credential-stack'),
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: _onDragStart,
                  onVerticalDragUpdate: (d) => _onDragUpdate(d, step),
                  onVerticalDragEnd: (d) => _onDragEnd(d, step),
                  child: Stack(
                    children: [
                      if (_previous != null) _peekCard(_previous!, cardWidth, cardHeight, step, isNext: false),
                      if (_next != null) _peekCard(_next!, cardWidth, cardHeight, step, isNext: true),
                      _activeCard(cardWidth, cardHeight),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        const _GestureHint(),
        const SizedBox(height: AppSpacing.xl),
        _InformationPanel(credential: _active),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          onTap: () => _openFullScreen(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fullscreen_rounded, size: 18, color: AppColors.brand600),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'View Full Screen (${_showingBack ? 'Back' : 'Front'})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.brand600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A stacked-behind credential — rendered small and dim at rest (a
  /// compact deck edge, per this feature's own "never a second full-size
  /// readable ID" requirement), growing/rising toward full size and
  /// opacity as a drag brings it toward becoming the active card. [isNext]
  /// selects which half of the drag range (up vs. down) drives it.
  Widget _peekCard(DigitalCredential credential, double width, double height, double step, {required bool isNext}) {
    final rawProgress = isNext ? (-_currentOffset / step) : (_currentOffset / step);
    final progress = rawProgress.clamp(0.0, 1.0);
    final scale = _peekRestScale + (1 - _peekRestScale) * progress;
    final opacity = _peekRestOpacity + (1 - _peekRestOpacity) * progress;
    // At rest (progress 0) this sits just below/above the active card,
    // showing only its own top/bottom `_peekVisible` px; as progress -> 1
    // it rises/descends toward y=0, arriving exactly as the active card
    // finishes departing so the handoff reads as one continuous motion.
    final restY = height - _peekVisible;
    final y = isNext ? restY * (1 - progress) : -restY * (1 - progress);
    final scaledWidth = width * scale;
    final scaledHeight = height * scale;

    return Positioned(
      top: y,
      left: (width - scaledWidth) / 2,
      child: Opacity(
        opacity: opacity,
        child: _CredentialFace(
          credential: credential,
          width: scaledWidth,
          height: scaledHeight,
          front: true,
          elevated: false,
        ),
      ),
    );
  }

  Widget _activeCard(double width, double height) {
    return Positioned(
      top: 0,
      left: 0,
      child: Transform.translate(
        offset: Offset(0, _currentOffset),
        child: Semantics(
          label:
              '${_active.displayName}, ${_showingBack ? 'back' : 'front'} side. '
              'Double tap to flip.',
          button: true,
          // A screen reader cannot make the swipe, so the other credentials
          // are also reachable as actions.
          customSemanticsActions: {
            if (_next != null) const CustomSemanticsAction(label: 'Next ID'): () => _jumpTo(_activeIndex + 1),
            if (_previous != null) const CustomSemanticsAction(label: 'Previous ID'): () => _jumpTo(_activeIndex - 1),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleFlip,
            child: AnimatedBuilder(
              animation: _flipController,
              builder: (context, child) {
                final t = _flipController.value;
                final isBack = t >= 0.5;
                // Standard card-flip recipe: on the back half, subtract pi
                // so the back face lands right-way-round instead of
                // mirrored — text on the back must read normally, never
                // backwards.
                final angle = isBack ? (t - 1) * math.pi : t * math.pi;
                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle);
                return Transform(
                  alignment: Alignment.center,
                  transform: matrix,
                  child: _CredentialFace(credential: _active, width: width, height: height, front: !isBack),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders one face (front or back) of a credential inside a fixed-size,
/// rounded, shadowed card — `BoxFit.contain` so the ID's own printed
/// information is never cropped, stretched, or otherwise distorted
/// regardless of a given asset's exact pixel aspect ratio. Decodes at the
/// size it's actually displayed at (`cacheWidth`, DPR-aware) rather than
/// the source's full ~1.6-2MB resolution — these seeded ID assets are
/// large enough that decoding every one at native resolution just to show
/// it at wallet/peek size is a real memory cost, multiplied by however
/// many credentials a resident's wallet eventually holds. Only
/// [_CredentialFullScreenViewer] intentionally skips this, since reading
/// the ID full-quality is the entire point there.
class _CredentialFace extends StatelessWidget {
  final DigitalCredential credential;
  final double width;
  final double height;
  final bool front;

  /// False for a stacked-behind peek card — a visibly lighter shadow than
  /// the active card's, reinforcing the depth cue without an expensive
  /// blur difference (both are the same cheap BoxShadow list, just a
  /// smaller one).
  final bool elevated;

  const _CredentialFace({
    required this.credential,
    required this.width,
    required this.height,
    required this.front,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final asset = front ? credential.frontAsset : credential.backAsset;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: elevated ? AppShadows.float : AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          color: Colors.white,
          child: Image.asset(
            asset,
            width: width,
            height: height,
            fit: BoxFit.contain,
            // Only the width is capped — contain already preserves the
            // source's own aspect ratio, so letting height follow from
            // that (rather than also pinning cacheHeight, which could
            // mismatch the true aspect ratio and force a second resize)
            // is what actually keeps this sharp.
            cacheWidth: (width * dpr).round().clamp(1, 4000),
            errorBuilder: (context, error, stack) => Container(
              color: AppColors.slate100,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined, size: 32, color: AppColors.slate400),
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionIndicator extends StatelessWidget {
  final int activeIndex;
  final int total;
  const _PositionIndicator({required this.activeIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${activeIndex + 1} of $total',
          style: const TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: AppColors.slate500),
        ),
        const SizedBox(width: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < total; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                width: i == activeIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == activeIndex ? AppColors.brand600 : AppColors.slate200,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GestureHint extends StatelessWidget {
  const _GestureHint();

  @override
  Widget build(BuildContext context) {
    // Wrap, not Row — on a narrow viewport both hints no longer fit on one
    // line side by side, so this drops to two lines instead of overflowing.
    return const Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        _HintChip(icon: Icons.touch_app_outlined, label: 'Tap to flip'),
        SizedBox(width: AppSpacing.sm),
        _HintChip(icon: Icons.swap_vert_rounded, label: 'Swipe for other IDs'),
      ],
    );
  }
}

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HintChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.slate400),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.slate500)),
      ],
    );
  }
}

/// Bound entirely to the active credential — swiping to a different one
/// updates this same widget's content, never a second per-credential copy.
class _InformationPanel extends StatelessWidget {
  final DigitalCredential credential;
  const _InformationPanel({required this.credential});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (credential.status) {
      CredentialStatus.active => AppColors.emerald700,
      CredentialStatus.inactive => AppColors.slate500,
      CredentialStatus.expired => AppColors.rose600,
    };
    final statusBg = switch (credential.status) {
      CredentialStatus.active => AppColors.emerald50,
      CredentialStatus.inactive => AppColors.slate100,
      CredentialStatus.expired => AppColors.rose50,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            credential.displayName,
            style: const TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(credential.holderName, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _infoField(
                  'Status',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(AppRadius.full)),
                    child: Text(
                      credential.status.label,
                      style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _infoField(
                  'Valid Until',
                  child: Text(
                    credential.validUntil == null ? 'No Expiry' : shortDate(credential.validUntil!),
                    style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.slate700),
                  ),
                ),
              ),
            ],
          ),
          if (credential.issuer != null) ...[
            const SizedBox(height: AppSpacing.md),
            _infoField(
              'Issued By',
              child: Text(
                credential.issuer!,
                style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.slate700),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Text(
            'This is a frontend simulation. No real government ID system issued this credential.',
            style: TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _infoField(String label, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: AppTextSize.fine, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }

}

class _EmptyWalletCard extends StatelessWidget {
  const _EmptyWalletCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: const Icon(Icons.badge_outlined, size: 26, color: AppColors.slate400),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'No digital credentials yet',
            style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Digital government/LGU credentials will appear here as they become available.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _NotYetVerifiedCard extends StatelessWidget {
  final CitizenAccount account;
  const _NotYetVerifiedCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.amber50, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: const Icon(Icons.hourglass_top_rounded, size: 26, color: AppColors.amber700),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Digital ID not yet available',
            style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your Digital IDs will become available after your resident account has been verified. '
            'Current status: ${AppStatusX.fromLabel(account.status).label}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Full-screen viewer for exactly the side the wallet card was showing when
/// "View Full Screen" was tapped — same simple InteractiveViewer pattern as
/// GovernmentIdViewer/EventPosterViewer, not a new/elaborate image viewer.
class _CredentialFullScreenViewer extends StatelessWidget {
  final DigitalCredential credential;
  final bool front;
  const _CredentialFullScreenViewer({required this.credential, required this.front});

  @override
  Widget build(BuildContext context) {
    final side = front ? 'Front' : 'Back';
    return ImageViewerScaffold(
      title: '${credential.displayName} — $side',
      image: AssetImage(front ? credential.frontAsset : credential.backAsset),
      semanticLabel: '${credential.displayName}, ${side.toLowerCase()} side',
    );
  }
}

/// The LGU-issued card from GET /citizen/digital-id. If the server cannot be
/// reached and this device holds the bundled demo credential art (the three
/// synthetic demo accounts), that wallet is shown instead; otherwise the error
/// with a retry, never an invented card.
class _LiveOrWallet extends StatefulWidget {
  const _LiveOrWallet({required this.account});

  final CitizenAccount account;

  @override
  State<_LiveOrWallet> createState() => _LiveOrWalletState();
}

class _LiveOrWalletState extends State<_LiveOrWallet> {
  late Future<DigitalIdCard> _future = DigitalIdService.fetch();

  // A block body: an arrow here hands setState the Future, which throws in a
  // debug build, so Try Again used to fail there.
  void _retry() {
    setState(() {
      _future = DigitalIdService.fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DigitalIdCard>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final card = snap.data;
        if (card != null) {
          return RefreshIndicator(
            onRefresh: () async {
              final next = DigitalIdService.fetch();
              setState(() => _future = next);
              await next.catchError((Object _) => card);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
              children: [_LiveIdCard(card: card)],
            ),
          );
        }
        final demo = digitalCredentialsFor(widget.account);
        if (demo.isNotEmpty) {
          return _DigitalIdWallet(
            credentials: demo,
            notice: _OfflineNotice(onRetry: _retry),
          );
        }
        final err = snap.error;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, size: AppSizes.iconHero, color: AppColors.textDisabled),
                const SizedBox(height: AppSpacing.md),
                Text(
                  err is ApiException ? err.message() : 'Your Digital ID could not be loaded.',
                  textAlign: TextAlign.center,
                  style: AppTypography.helper,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: _retry,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Over the demo wallet when GET /citizen/digital-id fails. It used to
/// replace the live card silently, with no sign anything had failed and no
/// way to try again short of leaving the screen.
class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice({required this.onRetry});

  final VoidCallback onRetry;

  static const text = 'Your Digital ID could not be loaded, so the sample IDs saved on this phone are shown.';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.amber50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.amber500.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: AppSizes.iconBase, color: AppColors.amber700),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text(text, style: AppTypography.helper)),
          TextButton(onPressed: onRetry, child: const Text('Try Again')),
        ],
      ),
    );
  }
}

class _LiveIdCard extends StatelessWidget {
  const _LiveIdCard({required this.card});

  final DigitalIdCard card;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy');
    final rows = <(String, String)>[
      ('Resident ID no.', card.accountNo),
      ('Barangay', card.barangay),
      if (card.purok != null) ('Purok / Sitio', card.purok!),
      if (card.birthdate != null) ('Date of birth', date.format(card.birthdate!)),
      if (card.sex != null) ('Sex', card.sex!),
      if (card.civilStatus != null) ('Civil status', card.civilStatus!),
      if (card.issuedAt != null) ('Issued', date.format(card.issuedAt!)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.navy900, AppColors.brand700]),
                  ),
                  child: Row(
                    children: [
                      Image.asset(esperanzaSealAsset, width: AppSizes.avatarMd, height: AppSizes.avatarMd),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MUNICIPALITY OF ESPERANZA, MASBATE',
                              style: AppTypography.eyebrow.copyWith(color: AppColors.brand200),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Resident ID', style: AppTypography.cardHeading.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(card.name, style: AppTypography.sectionTitle),
                      const SizedBox(height: AppSpacing.sm),
                      _ValidityChip(valid: card.valid),
                      const SizedBox(height: AppSpacing.lg),
                      for (final (label, value) in rows)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 120, child: Text(label, style: AppTypography.helper)),
                              Expanded(
                                child: Text(
                                  value,
                                  style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            children: [
              Semantics(
                label: 'QR code for verifying this ID',
                image: true,
                child: QrImageView(
                  data: card.qr,
                  size: 180,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.navy900),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.navy900),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'LGU staff scan this code to confirm your ID is genuine and current.',
                textAlign: TextAlign.center,
                style: AppTypography.helper,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValidityChip extends StatelessWidget {
  const _ValidityChip({required this.valid});

  final bool valid;

  @override
  Widget build(BuildContext context) {
    final fg = valid ? AppColors.emerald700 : AppColors.amber700;
    final bg = valid ? AppColors.emerald50 : AppColors.amber50;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(valid ? Icons.verified_rounded : Icons.hourglass_top_rounded, size: AppSizes.iconSm, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Text(valid ? 'Valid · Verified by LGU' : 'Not yet valid', style: AppTypography.labelText.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
