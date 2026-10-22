import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/identity_status.dart';
import '../../services/api_client.dart';
import '../../services/digital_id_service.dart';
import '../../services/id_portrait.dart';
import '../../services/id_text_parser.dart';
import '../../services/id_text_reader.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../utils/ambient_motion.dart';
import '../../utils/esperanza_seal.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/image_viewer_scaffold.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/wallet_id_card.dart';

import '../../l10n/tr.dart';
/// The Unified Digital ID Wallet (owner decisions, 2026-10-13), from
/// GET /citizen/wallet, laid out after the owner's designs (2026-10-13,
/// "Esperanza Digital ID" canvas; 2026-10-15, "Resident ID Redesign"):
///
/// - the Resident ID card the LGU issues, a navy card that turns over when
///   tapped: the front is the ID (seal, photo, name, number, the record's
///   details), the back the signed QR LGU staff scan. Plainly marked
///   suspended or not issued, with no QR, when it is not a credential;
/// - My IDs: the resident's own government IDs as a stacked deck of their
///   uploaded photos, swiped or stepped through, each tapped open full size
///   and flipped to its back. "Not checked" unless LGU staff verified that
///   very upload (then it carries the seal) or returned it, or Didit checked
///   it (2026-10-14: the ID verified at registration, or one scanned on
///   Didit's screen) - a mark of its own, never the seal;
/// - where things stand: identity, residency and the Resident ID, each with
///   a status of its own, never merged.
///
/// Every status comes from the server; nothing here sets one. There is no
/// sample wallet: when the wallet cannot be loaded, the screen says so and
/// offers Try Again.
class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.slate100,
      appBar: AppBar(
        backgroundColor: AppColors.slate100,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        leadingWidth: canPop ? 64 : null,
        titleSpacing: canPop ? 14 : AppSpacing.lg,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Center(
                  child: SizedBox.square(
                    dimension: 48,
                    child: IconButton(
                      tooltip: tr('Back'),
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.slate200),
                        shape: const CircleBorder(),
                      ),
                      icon: const Icon(Icons.chevron_left_rounded, size: 26, color: AppColors.navy900),
                    ),
                  ),
                ),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital ID',
              style: AppTypography.pageTitle.copyWith(fontWeight: FontWeight.w800, height: 1.1),
            ),
            const SizedBox(height: 2),
            Text('Resident ID · Esperanza LGU', style: AppTypography.bodyText.copyWith(color: AppColors.slate600)),
          ],
        ),
      ),
      body: const _WalletView(),
    );
  }
}

class _WalletView extends StatefulWidget {
  const _WalletView();

  @override
  State<_WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<_WalletView> {
  late Future<CitizenWallet> _future = _fetch();

  /// The wallet, and afterwards, out of the way, the face on any card Didit
  /// made (its photos come without one): found on the phone, then shown.
  Future<CitizenWallet> _fetch() async {
    final wallet = await WalletService.fetch();
    _placeFaces(wallet);
    return wallet;
  }

  Future<void> _placeFaces(CitizenWallet wallet) async {
    var placed = false;
    for (final d in wallet.documents) {
      if (d.fromDidit && d.portraitBox == null) placed = await WalletService.placeFace(d) || placed;
    }
    if (placed && mounted) _reload();
  }

  // A block body: an arrow here hands setState the Future, which throws in a
  // debug build.
  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<void> _openAdd(CitizenWallet wallet, {WalletDocument? replacing}) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddWalletIdScreen(types: wallet.idTypes, diditKinds: wallet.diditKinds, replacing: replacing),
      ),
    );
    if (added == true && mounted) _reload();
  }

  Future<void> _openDocument(CitizenWallet wallet, WalletDocument doc) async {
    final result = await Navigator.of(
      context,
    ).push<_DocumentAction>(MaterialPageRoute(builder: (_) => _WalletIdDetailScreen(document: doc)));
    if (!mounted) return;
    if (result == _DocumentAction.replace) {
      await _openAdd(wallet, replacing: doc);
    } else if (result == _DocumentAction.removed || result == _DocumentAction.edited) {
      _reload();
    }
  }

  /// The tapped ID, full size: flip it, close it, or go to its details.
  Future<void> _view(CitizenWallet wallet, WalletDocument doc) async {
    final details = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close ID',
      barrierColor: AppColors.navy950.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (context, animation, _) => Material(
        type: MaterialType.transparency,
        child: _IdViewer(document: doc, animation: animation),
      ),
    );
    if (details == true && mounted) await _openDocument(wallet, doc);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CitizenWallet>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final wallet = snap.data;
        if (wallet == null) {
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
                  OutlinedButton(onPressed: _reload, child: Text(tr('Try Again'))),
                ],
              ),
            ),
          );
        }
        final card = wallet.residentId.card;
        final active = wallet.residentId.state == ResidentIdState.active && card != null && card.qr != null;
        return RefreshIndicator(
          onRefresh: () async {
            final next = _fetch();
            setState(() => _future = next);
            await next.catchError((Object _) => wallet);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.page),
            children: [
              if (active) _FlipResidentId(card: card) else _ResidentIdCard(wallet: wallet),
              const SizedBox(height: AppSpacing.xl),
              _MyIds(
                wallet: wallet,
                onAdd: wallet.idTypes.isEmpty ? null : () => _openAdd(wallet),
                onOpen: (doc) => _view(wallet, doc),
              ),
              const SizedBox(height: AppSpacing.xl),
              _WhereThingsStand(wallet: wallet),
            ],
          ),
        );
      },
    );
  }
}

String _date(DateTime d) => DateFormat('MMM d, yyyy').format(d);

/// The eyebrow over a field on the card: NAME, BARANGAY, ISSUED.
Widget _fieldLabel(String text) => Text(text, style: AppTypography.eyebrow.copyWith(color: AppColors.slate600));

// ─────────────────────────────────────────────────────────── Resident ID

/// The Resident ID while it is not a credential: suspended, or not issued.
class _ResidentIdCard extends StatelessWidget {
  const _ResidentIdCard({required this.wallet});

  final CitizenWallet wallet;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Resident ID card',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg + 2),
          border: Border.all(color: AppColors.slate200),
          boxShadow: AppShadows.float,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(),
            Container(height: 4, color: AppColors.gold500),
            CustomPaint(
              painter: const _WatermarkPainter(),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _InactiveCardBody(wallet: wallet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navy, with a fine guilloche like a printed ID, the seal ringed in gold.
class _CardHeader extends StatelessWidget {
  const _CardHeader();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _GuillochePainter(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, AppSpacing.lg, 18, 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.gold500, spreadRadius: 2)],
              ),
              child: ClipOval(
                child: Image.asset(
                  esperanzaSealAsset,
                  fit: BoxFit.cover,
                  semanticLabel: 'Municipality of Esperanza official seal',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MUNICIPALITY OF ESPERANZA · MASBATE',
                    style: AppTypography.eyebrow.copyWith(color: AppColors.brand200),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Resident ID',
                    style: AppTypography.cardHeading.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card when it is not a credential: suspended, or not issued yet. No
/// record details and no QR, so a screenshot of it proves nothing.
class _InactiveCardBody extends StatelessWidget {
  const _InactiveCardBody({required this.wallet});

  final CitizenWallet wallet;

  @override
  Widget build(BuildContext context) {
    final rid = wallet.residentId;
    final suspended = rid.state == ResidentIdState.suspended;
    final name = rid.card?.name;
    final String title;
    final String message;
    if (suspended) {
      title = 'Resident ID suspended';
      message = rid.suspendedBecause == 'identity_revoked'
          ? 'The LGU withdrew the verification of your identity, so your Resident ID is not valid and its QR code '
                'no longer verifies. Send a new valid ID and selfie from your profile, or visit your barangay office.'
          : 'The LGU withdrew the approval of your residency, so your Resident ID is not valid and its QR code '
                'no longer verifies. Please visit your barangay office.';
    } else {
      title = 'Resident ID not issued yet';
      message = wallet.identity.status == IdentityStatus.verified
          ? 'Your identity is verified. Your Resident ID is issued once the LGU approves your residency.'
          : 'Your Resident ID is issued once your identity is verified and the LGU approves your residency. '
                'Your identity is not verified yet.';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardPhoto(url: null),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name != null && name.isNotEmpty) ...[
                    _fieldLabel(tr('NAME')),
                    const SizedBox(height: 2),
                    Text(name, style: AppTypography.sectionTitle.copyWith(height: 1.15)),
                    const SizedBox(height: 10),
                  ],
                  _Pill(
                    label: suspended ? 'Suspended' : 'Not issued yet',
                    icon: suspended ? Icons.block_rounded : Icons.hourglass_top_rounded,
                    foreground: suspended ? AppColors.rose700 : AppColors.amber700,
                    background: suspended ? AppColors.rose50 : AppColors.amber50,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _DashedRule(),
        const SizedBox(height: 14),
        Text(title, style: AppTypography.cardHeading),
        const SizedBox(height: AppSpacing.xs),
        Text(message, style: AppTypography.helper.copyWith(color: AppColors.slate600, height: 1.45)),
      ],
    );
  }
}

/// The LGU-approved photo on the card, or a plain placeholder until there is
/// one (a link that fails to load shows the placeholder too).
class _CardPhoto extends StatelessWidget {
  const _CardPhoto({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const w = 88.0;
    const h = 108.0;
    final placeholder = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        border: Border.all(color: AppColors.slate300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person_outline_rounded, color: AppColors.slate400, size: 40),
    );
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: w,
        height: h,
        fit: BoxFit.cover,
        semanticLabel: 'Resident photo',
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

/// A small rounded status pill with an optional leading icon.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.foreground, required this.background, this.icon, this.border});

  final String label;
  final IconData? icon;
  final Color foreground;
  final Color background;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 9 : 7, 4, 10, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: foreground), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelText.copyWith(color: foreground, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(painter: _DashPainter()),
  );
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.slate300
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, 0.5), Offset(math.min(x + 4, size.width), 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Two crossing sets of hairlines over navy, like the guilloche on a printed ID.
class _GuillochePainter extends CustomPainter {
  const _GuillochePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.navy900);
    void hatch(double step, double alpha, bool rising) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..strokeWidth = 1;
      for (double d = -size.height; d < size.width + size.height; d += step) {
        if (rising) {
          canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), paint);
        } else {
          canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
        }
      }
    }

    hatch(7, 0.045, false);
    hatch(9, 0.03, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A faint quarter disc in the card's bottom corner.
class _WatermarkPainter extends CustomPainter {
  const _WatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(size.width, size.height), 90, Paint()..color = AppColors.brand800.withValues(alpha: 0.06));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────── the flip card

/// The active Resident ID as a card that turns over (owner's design,
/// 2026-10-15, "Resident ID Redesign" canvas): the front is the ID itself,
/// the back the signed QR LGU staff scan. Both faces are always built; the
/// one turned away is hidden from taps and from the screen reader.
class _FlipResidentId extends StatefulWidget {
  const _FlipResidentId({required this.card});

  final DigitalIdCard card;

  @override
  State<_FlipResidentId> createState() => _FlipResidentIdState();
}

class _FlipResidentIdState extends State<_FlipResidentId> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _eased = CurvedAnimation(parent: _turn, curve: const Cubic(0.3, 0.8, 0.3, 1));
  bool _back = false;

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _back = !_back);
    // Reduce motion: turn over at once.
    if (MediaQuery.of(context).disableAnimations) {
      _turn.value = _back ? 1 : 0;
    } else if (_back) {
      _turn.forward();
    } else {
      _turn.reverse();
    }
  }

  Widget _face({required bool shown, required double angle, required Widget child}) {
    return IgnorePointer(
      ignoring: !shown,
      child: ExcludeSemantics(
        excluding: !shown,
        child: Opacity(
          opacity: shown ? 1 : 0,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Column(
      children: [
        Semantics(
          button: true,
          toggled: _back,
          label: _back
              ? 'Resident ID, back: QR code for LGU staff. Tap to show the front.'
              : 'Resident ID, front: ${card.name}, ${card.accountNo}. Tap to show the QR code.',
          onTap: _flip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _flip,
            child: AnimatedBuilder(
              animation: _eased,
              builder: (context, _) {
                final angle = _eased.value * math.pi;
                final backUp = angle > math.pi / 2;
                return Stack(
                  children: [
                    // The front sets the card's size; the back takes the same.
                    _face(shown: !backUp, angle: angle, child: _CardFront(card: card)),
                    Positioned.fill(
                      child: _face(shown: backUp, angle: angle - math.pi, child: _CardBack(card: card)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _back ? 'Tap the card to see your details' : 'Tap the card to show your QR code',
                style: AppTypography.helper.copyWith(color: AppColors.slate600),
              ),
            ),
            const SizedBox(width: 14),
            ExcludeSemantics(
              child: Row(
                children: [
                  _SideDot(active: !_back),
                  const SizedBox(width: 5),
                  _SideDot(active: _back),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Which side of the card is up: the long dot.
class _SideDot extends StatelessWidget {
  const _SideDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 18 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.navy900 : AppColors.slate300,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}

const _cardRadius = 16.0;
final _cardShadow = [
  BoxShadow(
    color: AppColors.navy900.withValues(alpha: 0.55),
    blurRadius: 36,
    offset: const Offset(0, 18),
    spreadRadius: -14,
  ),
  BoxShadow(color: AppColors.navy900.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
];

/// The eyebrow on the card: small capitals, spaced out.
TextStyle _cardEyebrow(Color color) =>
    AppTypography.eyebrow.copyWith(color: color, fontWeight: FontWeight.w700, letterSpacing: 1.1, height: 1.25);

/// "Valid", or "Not yet valid", on a light pill.
class _CardPill extends StatelessWidget {
  const _CardPill({required this.label, required this.valid});

  final String label;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final fg = valid ? AppColors.emerald700 : AppColors.amber700;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 9, 3),
      decoration: BoxDecoration(
        color: valid ? AppColors.emerald50 : AppColors.amber50,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(valid ? Icons.check_rounded : Icons.hourglass_top_rounded, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTypography.fine.copyWith(color: fg, fontWeight: FontWeight.w700, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.card});

  final DigitalIdCard card;

  @override
  Widget build(BuildContext context) {
    final fields = <(String, String)>[
      ('BARANGAY', card.barangay),
      if (card.purok != null) ('PUROK / SITIO', card.purok!),
      if (card.birthdate != null) ('DATE OF BIRTH', _date(card.birthdate!)),
      if (card.sex != null) ('SEX', card.sex!),
      if (card.civilStatus != null) ('CIVIL STATUS', card.civilStatus!),
      if (card.issuedAt != null) ('ISSUED', _date(card.issuedAt!)),
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.circular(_cardRadius),
        boxShadow: _cardShadow,
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _CardFrontPainter())),
          // The seal again, large and faint, behind the details.
          Positioned(
            right: -18,
            top: 52,
            width: 150,
            height: 150,
            child: ExcludeSemantics(
              child: Opacity(
                opacity: 0.08,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0.2126, 0.7152, 0.0722, 0, 0, //
                    0, 0, 0, 1, 0, //
                  ]),
                  child: ClipOval(child: Image.asset(esperanzaSealAsset, fit: BoxFit.cover)),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
                decoration: const BoxDecoration(
                  color: AppColors.navy950,
                  border: Border(bottom: BorderSide(color: AppColors.gold500, width: 2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.gold500, spreadRadius: 2)],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          esperanzaSealAsset,
                          fit: BoxFit.cover,
                          semanticLabel: 'Official seal of the Municipality of Esperanza',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REPUBLIC OF THE PHILIPPINES',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _cardEyebrow(AppColors.brand200).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Municipality of Esperanza · Masbate',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelText.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CardPill(label: card.valid ? 'Valid' : 'Not yet valid', valid: card.valid),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FrontPhoto(url: card.photoUrl, name: card.name),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RESIDENT ID', style: _cardEyebrow(AppColors.gold400)),
                          const SizedBox(height: 3),
                          Text(
                            card.name,
                            style: AppTypography.sectionTitle.copyWith(
                              color: AppColors.surface,
                              fontSize: AppTextSize.section,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            card.accountNo,
                            style: AppTypography.bodyText.copyWith(
                              color: AppColors.gold300,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              height: 1.2,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final third = (constraints.maxWidth - 20) / 3;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        for (final (label, value) in fields)
                          SizedBox(
                            width: third,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _cardEyebrow(AppColors.brand200).copyWith(letterSpacing: 0.6),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  value,
                                  style: AppTypography.labelText.copyWith(
                                    color: AppColors.surface,
                                    fontSize: AppTextSize.helper,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The LGU-approved photo, or the resident's initials until there is one.
class _FrontPhoto extends StatelessWidget {
  const _FrontPhoto({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final placeholder = Container(
      width: 62,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brand900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.18)),
      ),
      child: Text(
        initials,
        style: AppTypography.sectionTitle.copyWith(color: AppColors.brand50, fontWeight: FontWeight.w800),
      ),
    );
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 62,
        height: 74,
        fit: BoxFit.cover,
        semanticLabel: 'Resident photo',
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

/// Fine rings from the bottom corner and a faint gold wave, like a printed ID.
class _CardFrontPainter extends CustomPainter {
  const _CardFrontPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.surface.withValues(alpha: 0.06);
    final centre = Offset(w * 0.922, h * 0.885);
    for (var r = 40.0; r <= 160; r += 30) {
      canvas.drawCircle(centre, r, rings);
    }
    final wave = Path()
      ..moveTo(0, h)
      ..lineTo(0, h - 30)
      ..quadraticBezierTo(w * 0.25, h - 56, w * 0.5, h - 30)
      ..quadraticBezierTo(w * 0.75, h - 4, w, h - 40)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(wave, Paint()..color = AppColors.gold500.withValues(alpha: 0.07));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.card});

  final DigitalIdCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: AppColors.slate200),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: const BoxDecoration(
              color: AppColors.navy900,
              border: Border(bottom: BorderSide(color: AppColors.gold500, width: 2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 15, color: AppColors.gold500),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Show this to LGU staff',
                    style: AppTypography.labelText.copyWith(color: AppColors.surface, fontWeight: FontWeight.w700),
                  ),
                ),
                Text('ESPERANZA LGU', style: _cardEyebrow(AppColors.brand200).copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 136,
                    height: 136,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.slate200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Semantics(
                      label: 'QR code for Resident ID ${card.accountNo}',
                      image: true,
                      child: QrImageView(
                        data: card.qr!,
                        size: 116,
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.surface,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.navy900),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.navy900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RESIDENT ID NO.', style: _cardEyebrow(AppColors.slate600)),
                        const SizedBox(height: 4),
                        Text(
                          card.accountNo,
                          style: AppTypography.labelText.copyWith(
                            color: AppColors.navy900,
                            fontSize: AppTextSize.helper,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'LGU staff scan this code to confirm your ID is genuine and current.',
                          style: AppTypography.fine.copyWith(color: AppColors.slate700, height: 1.45),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _CardPill(label: card.valid ? 'Valid · Verified by LGU' : 'Not yet valid', valid: card.valid),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── My IDs

class _MyIds extends StatelessWidget {
  const _MyIds({required this.wallet, required this.onAdd, required this.onOpen});

  final CitizenWallet wallet;
  final VoidCallback? onAdd;
  final ValueChanged<WalletDocument> onOpen;

  @override
  Widget build(BuildContext context) {
    final docs = wallet.documents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(tr('My IDs'), style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w800)),
            ),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(tr('Add ID')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSizes.minTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                foregroundColor: AppColors.navy900,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.navy900, width: 2),
                shape: const StadiumBorder(),
                textStyle: AppTypography.cardHeading.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          decoration: BoxDecoration(color: AppColors.brand100, borderRadius: BorderRadius.circular(14)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.info_outline_rounded, size: 18, color: AppColors.navy800),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: 'Keep copies of your government IDs here for reference. '),
                      TextSpan(
                        text: 'Adding an ID does not verify it:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            ' IDs Didit checked say so; IDs verified by the LGU have the Esperanza seal on them.',
                      ),
                    ],
                  ),
                  style: AppTypography.helper.copyWith(color: AppColors.navy800, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.itemGap),
        if (docs.isEmpty) const _EmptyDeck() else _IdDeck(documents: docs, onOpen: onOpen),
      ],
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.brand100, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.credit_card_rounded, size: 26, color: AppColors.navy800),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(tr('No IDs added yet'), style: AppTypography.cardHeading.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add your PhilSys National ID, PhilHealth, SSS, driver\'s license or any other ID to keep a copy here.',
            textAlign: TextAlign.center,
            style: AppTypography.helper.copyWith(color: AppColors.slate600),
          ),
        ],
      ),
    );
  }
}

/// Where one card of the deck sits: lifted, tilted, shrunk, faded.
@immutable
class _Pose {
  const _Pose({this.dy = 0, this.turn = 0, this.scale = 1, this.opacity = 1, this.dim = 0});

  final double dy;

  /// Degrees.
  final double turn;
  final double scale;
  final double opacity;

  /// 0 is full brightness; a card further back is dimmed a little.
  final double dim;

  static _Pose lerp(_Pose a, _Pose b, double t) => _Pose(
    dy: a.dy + (b.dy - a.dy) * t,
    turn: a.turn + (b.turn - a.turn) * t,
    scale: a.scale + (b.scale - a.scale) * t,
    opacity: a.opacity + (b.opacity - a.opacity) * t,
    dim: a.dim + (b.dim - a.dim) * t,
  );
}

class _PoseTween extends Tween<_Pose> {
  _PoseTween({super.begin});

  @override
  _Pose lerp(double t) => _Pose.lerp(begin!, end!, t);
}

/// A deck card that eases to its new [pose], or follows a finger at once
/// when [duration] is zero.
class _PosedCard extends ImplicitlyAnimatedWidget {
  const _PosedCard({required this.pose, required this.child, required super.duration})
    : super(curve: const Cubic(0.2, 0.8, 0.2, 1));

  final _Pose pose;
  final Widget child;

  @override
  AnimatedWidgetBaseState<_PosedCard> createState() => _PosedCardState();
}

class _PosedCardState extends AnimatedWidgetBaseState<_PosedCard> {
  _PoseTween? _pose;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _pose = visitor(_pose, widget.pose, (v) => _PoseTween(begin: v as _Pose)) as _PoseTween?;
  }

  @override
  Widget build(BuildContext context) {
    final p = _pose!.evaluate(animation);
    final transform = Matrix4.translationValues(0, p.dy, 0)
      ..multiply(Matrix4.rotationZ(p.turn * math.pi / 180))
      ..multiply(Matrix4.diagonal3Values(p.scale, p.scale, 1));
    return Opacity(
      opacity: p.opacity.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.topCenter,
        transform: transform,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (p.dim > 0.001)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.navy950.withValues(alpha: p.dim),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The resident's IDs as a stacked deck: the front card on top, the next two
/// peeking out above it. Swipe up for the next, down for the one before, or
/// use the arrows; tap the front card to open it.
class _IdDeck extends StatefulWidget {
  const _IdDeck({required this.documents, required this.onOpen});

  final List<WalletDocument> documents;
  final ValueChanged<WalletDocument> onOpen;

  @override
  State<_IdDeck> createState() => _IdDeckState();
}

class _IdDeckState extends State<_IdDeck> {
  /// The card's height at [width], in the wallet card's proportions.
  static double _heightFor(double width) => width * WalletIdCard.designHeight / WalletIdCard.designWidth;

  /// Set from the deck's width on each layout.
  double cardHeight = 216;
  static const ease = Duration(milliseconds: 520);

  int _a = 0;
  double _drag = 0;
  bool _dragging = false;
  int? _leave;
  int? _enter;

  int get _n => widget.documents.length;

  /// How far the cards behind the front one rise above it (see [_poseOf]).
  double get _peekRoom => 15.0 * math.min(_n - 1, 2);

  @override
  void didUpdateWidget(_IdDeck old) {
    super.didUpdateWidget(old);
    if (_a >= _n) _a = 0;
  }

  void _go(int dir, {bool fromDrag = false}) {
    if (_n < 2) return;
    final cur = _a;
    final next = (cur + dir + _n) % _n;
    if (dir > 0) {
      setState(() {
        _a = next;
        _leave = cur;
        _enter = null;
        _dragging = false;
        _drag = 0;
      });
      Future<void>.delayed(const Duration(milliseconds: 560), () {
        if (mounted && _leave == cur) setState(() => _leave = null);
      });
    } else if (fromDrag) {
      setState(() {
        _a = next;
        _leave = null;
        _enter = null;
        _dragging = false;
        _drag = 0;
      });
    } else {
      // The card before drops in from above: placed there first, then let go.
      setState(() {
        _enter = next;
        _leave = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _a = next;
            _enter = null;
          });
        }
      });
    }
  }

  (_Pose, int, bool) _poseOf(int i) {
    final rel = (i - _a + _n) % _n;
    final lift = -(cardHeight + 70);
    final pullingBack = rel == _n - 1 && _n > 1 && _dragging && _drag > 0;
    if ((i == _leave && i != _a) || i == _enter || pullingBack) {
      if (pullingBack) {
        return (
          _Pose(
            dy: lift + math.min(_drag * 1.6, cardHeight + 70),
            turn: -5 + math.min(5.0, _drag / 30),
            scale: 0.97,
            opacity: math.min(1.0, _drag / 110),
          ),
          60,
          true,
        );
      }
      return (_Pose(dy: lift, turn: -5, scale: 0.97, opacity: 0), 60, i == _enter);
    }
    if (rel == 0) {
      if (_dragging) {
        return (_Pose(dy: _drag < 0 ? _drag : _drag * 0.25, turn: _drag < 0 ? _drag * 0.025 : 0), 50, true);
      }
      return (const _Pose(), 50, false);
    }
    final k = math.min(rel, 3);
    final step = math.min(k, 2);
    return (
      _Pose(
        dy: -15.0 * step,
        scale: 1 - 0.055 * step,
        turn: k.isOdd ? 2 : -1.6,
        dim: 0.04 * k,
        opacity: rel > 2 ? 0 : 1,
      ),
      50 - k,
      false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final docs = widget.documents;
    final current = docs[_a];
    final cards = [for (var i = 0; i < _n; i++) (i, _poseOf(i))]..sort((x, y) => x.$2.$2.compareTo(y.$2.$2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: '${current.name}, ${_badgeText(current.status)}. ${_a + 1} of $_n. Double tap to view it.',
          onTap: () => widget.onOpen(current),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onOpen(current),
            onVerticalDragStart: (_) => setState(() {
              _dragging = true;
              _drag = 0;
            }),
            onVerticalDragUpdate: (d) => setState(() => _drag += d.delta.dy),
            onVerticalDragEnd: (_) {
              if (_drag < -60) {
                _go(1, fromDrag: true);
              } else if (_drag > 60) {
                _go(-1, fromDrag: true);
              } else {
                setState(() {
                  _dragging = false;
                  _drag = 0;
                });
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The card as wide as the deck, at its own proportions.
                cardHeight = _heightFor(constraints.maxWidth);
                return SizedBox(
                  // Room above the front card only for the cards peeking out
                  // behind it: 15 each, at most two; none with a single ID.
                  height: _peekRoom + cardHeight + 6,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final (i, (pose, _, live)) in cards)
                        Positioned(
                          key: ValueKey(docs[i].id),
                          top: _peekRoom,
                          left: 0,
                          right: 0,
                          height: cardHeight,
                          child: _PosedCard(
                            pose: pose,
                            duration: live ? Duration.zero : ease,
                            child: _IdCardFace(document: docs[i], back: false),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (var i = 0; i < _n; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 5),
                width: i == _a ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _a ? AppColors.brand800 : AppColors.slate300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            const SizedBox(width: 5),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${_a + 1} of $_n',
                  style: AppTypography.helper.copyWith(color: AppColors.slate600, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            _RoundIconButton(
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'Previous ID',
              onPressed: _n < 2 ? null : () => _go(-1),
            ),
            const SizedBox(width: AppSpacing.sm),
            _RoundIconButton(
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Next ID',
              onPressed: _n < 2 ? null : () => _go(1),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Swipe up or down to browse. Tap a card to view it.',
          style: AppTypography.label.copyWith(color: AppColors.slate600, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

String _badgeText(WalletDocumentStatus s) => switch (s) {
  WalletDocumentStatus.uploadedNotChecked => 'Not checked',
  WalletDocumentStatus.checkedByDidit => 'Checked by Didit',
  WalletDocumentStatus.verifiedByLgu => 'Verified by the LGU',
  WalletDocumentStatus.returnedByLgu => 'Returned by the LGU',
};

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.slate300)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: AppSizes.minTouchTarget,
            height: AppSizes.minTouchTarget,
            child: Icon(icon, size: 22, color: onPressed == null ? AppColors.textDisabled : AppColors.navy900),
          ),
        ),
      ),
    );
  }
}

/// One side of a kept ID, card-shaped: the resident's own photo of it, its
/// kind in the corner, and what has been done with it: not checked,
/// returned, or verified by the LGU (the seal).
class _IdCardFace extends StatelessWidget {
  const _IdCardFace({required this.document, required this.back});

  final WalletDocument document;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final d = document;
    final url = d.frontUrl;
    const noPhoto = Icon(Icons.image_not_supported_outlined, color: AppColors.textDisabled);
    // The front's picture is the face on the ID, cropped from the resident's
    // photo; with no face found, a plain placeholder rather than the whole
    // card shrunk into the slot. The back has no picture (owner, 2026-10-13);
    // its photo is on the ID's details page.
    final face = back ? null : PortraitBox.decode(d.portraitBox);
    Widget? photo;
    if (url != null && face != null) {
      photo = _RetryingImage(
        url: url,
        fit: BoxFit.cover,
        crop: face,
        waiting: const SizedBox.shrink(),
        failed: noPhoto,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.float),
      child: WalletIdCard(
        document: d,
        back: back,
        photo: photo,
        badge: back ? null : _CornerBadge(status: d.status),
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({required this.status});

  final WalletDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      WalletDocumentStatus.verifiedByLgu => const _HoloSeal(key: ValueKey('verified-seal'), size: 62),
      WalletDocumentStatus.returnedByLgu => _Pill(
        label: tr('Returned'),
        icon: Icons.undo_rounded,
        foreground: AppColors.rose700,
        background: AppColors.rose50,
        border: AppColors.rose500,
      ),
      WalletDocumentStatus.uploadedNotChecked => _Pill(
        label: tr('Not checked'),
        icon: Icons.arrow_upward_rounded,
        foreground: AppColors.amber700,
        background: AppColors.amber50,
        border: AppColors.gold200,
      ),
      // Didit's check, not the LGU's: a plain mark, never the seal.
      WalletDocumentStatus.checkedByDidit => _Pill(
        label: tr('Checked'),
        icon: Icons.verified_outlined,
        foreground: AppColors.sky700,
        background: AppColors.sky50,
        border: AppColors.sky500,
      ),
    };
  }
}

/// The Esperanza seal as a silver hologram, on an ID the LGU verified. Its
/// sheen turns slowly unless motion is off.
class _HoloSeal extends StatefulWidget {
  const _HoloSeal({super.key, required this.size});

  final double size;

  @override
  State<_HoloSeal> createState() => _HoloSealState();
}

class _HoloSealState extends State<_HoloSeal> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AmbientMotion.of(context)) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  static const _grey = ColorFilter.matrix([
    0.3, 0.59, 0.11, 0, 60, //
    0.3, 0.59, 0.11, 0, 60,
    0.3, 0.59, 0.11, 0, 60,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      label: tr('Esperanza seal: verified by the LGU'),
      child: Opacity(
        opacity: 0.8,
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              const BoxShadow(color: Colors.white, spreadRadius: 1),
              BoxShadow(color: AppColors.navy900.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 1)),
            ],
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: _grey,
                  child: Image.asset(esperanzaSealAsset, fit: BoxFit.cover),
                ),
                AnimatedBuilder(
                  animation: _spin,
                  builder: (context, _) => Opacity(
                    opacity: 0.45,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: SweepGradient(
                          transform: GradientRotation(_spin.value * 2 * math.pi),
                          colors: const [
                            AppColors.slate50,
                            AppColors.slate400,
                            AppColors.brand100,
                            AppColors.slate300,
                            AppColors.gold100,
                            AppColors.slate400,
                            AppColors.slate50,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0),
                      ],
                      stops: const [0.32, 0.47, 0.6],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One ID full size: turned to fill the screen, tap to flip it to its back,
/// then Close, or Details for what is known about it and Replace / Remove.
class _IdViewer extends StatefulWidget {
  const _IdViewer({required this.document, required this.animation});

  final WalletDocument document;
  final Animation<double> animation;

  @override
  State<_IdViewer> createState() => _IdViewerState();
}

class _IdViewerState extends State<_IdViewer> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 640));
  bool _back = false;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _back = !_back);
    if (_back) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.document;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    // The card is the deck's card, turned a quarter and grown to fit.
    final cardW = math.min(size.width - 40, 350.0);
    final cardH = cardW / 1.62;
    final roomH = size.height - padding.vertical - 140;
    final scale = math.min(1.55, math.min((size.width - 32) / cardH, roomH / cardW));
    final pop = CurvedAnimation(parent: widget.animation, curve: const Cubic(0.2, 0.8, 0.2, 1));

    Widget face(bool back) => SizedBox(
      width: cardW,
      height: cardH,
      child: _IdCardFace(document: d, back: back),
    );

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([pop, _flip]),
                builder: (context, _) {
                  final t = pop.value;
                  final f = Curves.easeInOut.transform(_flip.value);
                  final angle = f * math.pi;
                  final showingBack = angle > math.pi / 2;
                  final flip = Matrix4.identity()
                    ..setEntry(3, 2, 0.0007)
                    ..rotateX(angle);
                  return Opacity(
                    opacity: 0.4 + 0.6 * t.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: t * math.pi / 2,
                      child: Transform.scale(
                        scale: 1 + (scale - 1) * t,
                        child: Semantics(
                          button: true,
                          label:
                              '${d.name}, ${showingBack ? 'back' : 'front'}. Double tap to show the ${showingBack ? 'front' : 'back'}.',
                          child: GestureDetector(
                            onTap: _toggle,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: flip,
                              child: showingBack
                                  ? Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationX(math.pi),
                                      child: face(true),
                                    )
                                  : face(false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          FadeTransition(
            opacity: widget.animation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  _ViewerButton(
                    icon: Icons.close_rounded,
                    label: tr('Close'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  _ViewerButton(
                    icon: Icons.info_outline_rounded,
                    label: tr('Details'),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(),
      elevation: 6,
      shadowColor: AppColors.navy950,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SizedBox(
            height: AppSizes.buttonHeightLg,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.navy900),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: AppTypography.bodyText.copyWith(color: AppColors.navy900, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────── where things stand

/// The three statuses as a short timeline, each with its own pill.
class _WhereThingsStand extends StatelessWidget {
  const _WhereThingsStand({required this.wallet});

  final CitizenWallet wallet;

  @override
  Widget build(BuildContext context) {
    final identity = wallet.identity;
    final idStatus = identity.status;
    final doc = identity.checkedDocument;
    final residency = AppStatus.values.where((s) => s.label == wallet.residencyStatus).firstOrNull;
    final rid = wallet.residentId;

    final identityStep = _Step(
      title: tr('Identity'),
      color: idStatus?.foreground ?? AppColors.slate500,
      icon: switch (idStatus) {
        IdentityStatus.verified => Icons.check_rounded,
        IdentityStatus.failed || IdentityStatus.revoked => Icons.close_rounded,
        null => Icons.remove_rounded,
        _ => Icons.schedule_rounded,
      },
      pill: idStatus == null
          ? _Pill(label: tr('Not started'), foreground: AppColors.slate600, background: AppColors.slate100)
          : _Pill(label: idStatus.label, foreground: idStatus.foreground, background: idStatus.background),
      lines: [
        ?identity.sourceLabel,
        if (doc != null)
          [
            'Checked ID: ${doc.type ?? 'ID document'}',
            if (doc.numberLast4 != null) 'ending ${doc.numberLast4}',
          ].join(', '),
      ],
    );

    final residencyStep = _Step(
      title: tr('Residency'),
      color: switch (residency) {
        AppStatus.approved => AppColors.emerald700,
        AppStatus.rejected => AppColors.rose700,
        AppStatus.pendingReview => AppColors.amber700,
        _ => AppColors.slate500,
      },
      icon: switch (residency) {
        AppStatus.approved => Icons.check_rounded,
        AppStatus.rejected => Icons.close_rounded,
        _ => Icons.schedule_rounded,
      },
      pill: residency == null
          ? _Pill(label: wallet.residencyStatus, foreground: AppColors.slate600, background: AppColors.slate100)
          : StatusChip(status: residency, small: true),
      lines: [
        wallet.approvalRevoked
            ? 'The LGU withdrew the approval of your residency.'
            : 'Decided by the LGU, separately from your identity.',
      ],
    );

    final issued = rid.card?.issuedAt;
    final ridStep = _Step(
      title: 'Resident ID',
      color: switch (rid.state) {
        ResidentIdState.active => AppColors.navy900,
        ResidentIdState.suspended => AppColors.rose700,
        ResidentIdState.notIssued => AppColors.slate500,
      },
      icon: switch (rid.state) {
        ResidentIdState.suspended => Icons.block_rounded,
        _ => Icons.badge_outlined,
      },
      pill: switch (rid.state) {
        ResidentIdState.active => _Pill(label: tr('Active'), foreground: Colors.white, background: AppColors.navy900),
        ResidentIdState.suspended => _Pill(
          label: tr('Suspended'),
          foreground: AppColors.rose700,
          background: AppColors.rose50,
        ),
        ResidentIdState.notIssued => _Pill(
          label: tr('Not issued yet'),
          foreground: AppColors.amber700,
          background: AppColors.amber50,
        ),
      },
      lines: [
        switch (rid.state) {
          ResidentIdState.active =>
            issued == null ? 'Valid while your identity and residency stand.' : 'Issued ${_date(issued)}',
          ResidentIdState.suspended => 'Not valid until the LGU restores it.',
          ResidentIdState.notIssued => 'Issued once your identity is verified and your residency approved.',
        },
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Where things stand'),
            style: AppTypography.sectionTitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TimelineRow(step: identityStep, last: false),
          _TimelineRow(step: residencyStep, last: false),
          _TimelineRow(step: ridStep, last: true),
        ],
      ),
    );
  }
}

class _Step {
  const _Step({required this.title, required this.color, required this.icon, required this.pill, required this.lines});

  final String title;
  final Color color;
  final IconData icon;
  final Widget pill;
  final List<String> lines;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step, required this.last});

  final _Step step;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: step.color, shape: BoxShape.circle),
                  child: Icon(step.icon, size: 18, color: AppColors.surface),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: const BoxConstraints(minHeight: 28),
                      color: step.color.withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: last ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: AppTypography.cardHeading.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      step.pill,
                    ],
                  ),
                  for (final line in step.lines) ...[
                    const SizedBox(height: 3),
                    Text(line, style: AppTypography.helper.copyWith(color: AppColors.slate600, height: 1.45)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────── shared by the details and Add ID

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.title, required this.status, required this.details});

  final String title;
  final Widget status;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: AppTypography.labelText.copyWith(color: AppColors.textPrimary)),
            ),
            status,
          ],
        ),
        for (final d in details) ...[const SizedBox(height: AppSpacing.xs), Text(d, style: AppTypography.helper)],
      ],
    );
  }
}

/// A small pill for the wallet's own states, which are not badge statuses.
class _PlainChip extends StatelessWidget {
  const _PlainChip({required this.label, required this.foreground, required this.background, this.icon});

  final String label;
  final IconData? icon;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconSm, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(label, style: AppTypography.labelText.copyWith(color: foreground)),
          ),
        ],
      ),
    );
  }
}

class _DocumentStatusChip extends StatelessWidget {
  const _DocumentStatusChip({required this.status});

  final WalletDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      WalletDocumentStatus.uploadedNotChecked => _PlainChip(
        label: status.label,
        icon: Icons.upload_file_rounded,
        foreground: AppColors.slate700,
        background: AppColors.slate100,
      ),
      WalletDocumentStatus.checkedByDidit => _PlainChip(
        label: status.label,
        icon: Icons.verified_outlined,
        foreground: AppColors.sky700,
        background: AppColors.sky50,
      ),
      WalletDocumentStatus.verifiedByLgu => _PlainChip(
        label: status.label,
        icon: Icons.fact_check_rounded,
        foreground: AppColors.emerald700,
        background: AppColors.emerald50,
      ),
      WalletDocumentStatus.returnedByLgu => _PlainChip(
        label: status.label,
        icon: Icons.undo_rounded,
        foreground: AppColors.rose700,
        background: AppColors.rose50,
      ),
    };
  }
}

/// A signed link to one side of a kept ID. A photo that fails to arrive
/// (a dropped connection on a weak signal) is tried again twice on its own;
/// after that, with [tapToRetry], the resident can tap to try once more.
class _RetryingImage extends StatefulWidget {
  const _RetryingImage({
    required this.url,
    required this.waiting,
    required this.failed,
    this.fit = BoxFit.contain,
    this.tapToRetry = false,
    this.crop,
  });

  final String url;

  /// Show only this part of the photo once it has loaded (the face on an
  /// ID); waiting and failed states are shown whole, never cropped away.
  final PortraitBox? crop;

  /// Shown between tries.
  final Widget waiting;

  /// Shown once the tries are used up.
  final Widget failed;
  final BoxFit fit;
  final bool tapToRetry;

  @override
  State<_RetryingImage> createState() => _RetryingImageState();
}

class _RetryingImageState extends State<_RetryingImage> {
  static const automaticTries = 2;

  int _attempt = 0;
  int _triesLeft = automaticTries;
  bool _scheduled = false;

  void _again() {
    if (!mounted) return;
    NetworkImage(widget.url).evict();
    setState(() {
      _attempt++;
      _scheduled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    return Image.network(
      widget.url,
      key: ValueKey(_attempt),
      fit: crop == null ? widget.fit : BoxFit.fill,
      frameBuilder: crop == null
          ? null
          : (context, child, frame, _) => frame == null ? widget.waiting : CroppedPortrait(box: crop, child: child),
      errorBuilder: (context, _, _) {
        if (_triesLeft > 0) {
          if (!_scheduled) {
            _scheduled = true;
            _triesLeft--;
            Future<void>.delayed(Duration(milliseconds: 700 * (automaticTries - _triesLeft)), _again);
          }
          return widget.waiting;
        }
        if (!widget.tapToRetry) return widget.failed;
        return Semantics(
          button: true,
          label: 'Try loading the image again',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _triesLeft = automaticTries;
              _again();
            },
            child: widget.failed,
          ),
        );
      },
    );
  }
}

enum _DocumentAction { replace, removed, edited }

/// One kept ID: both sides, what is known about it, Replace and Remove.
class _WalletIdDetailScreen extends StatefulWidget {
  const _WalletIdDetailScreen({required this.document});

  final WalletDocument document;

  @override
  State<_WalletIdDetailScreen> createState() => _WalletIdDetailScreenState();
}

class _WalletIdDetailScreenState extends State<_WalletIdDetailScreen> {
  bool _removing = false;

  Future<void> _remove() async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Remove this ID?',
      message: 'It leaves your wallet. The LGU keeps its record of the upload, as with every document you send.',
      confirmLabel: tr('Remove'),
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _removing = true);
    try {
      await WalletService.remove(widget.document.id);
      if (mounted) Navigator.of(context).pop(_DocumentAction.removed);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _removing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message())));
    }
  }

  Future<void> _editDetails() async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => _EditIdDetailsScreen(document: widget.document)));
    if (saved == true && mounted) Navigator.of(context).pop(_DocumentAction.edited);
  }

  void _view(String side, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageViewerScaffold(
          title: '${widget.document.name} — $side',
          image: NetworkImage(url),
          semanticLabel: '${widget.document.name}, ${side.toLowerCase()} side',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.document;
    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          _SideImage(
            label: tr('Front'),
            url: d.frontUrl,
            onView: d.frontUrl == null ? null : () => _view(tr('Front'), d.frontUrl!),
          ),
          const SizedBox(height: AppSpacing.md),
          if (d.hasBack)
            _SideImage(
              label: tr('Back'),
              url: d.backUrl,
              onView: d.backUrl == null ? null : () => _view(tr('Back'), d.backUrl!),
            )
          else
            const Text('No back side added.', style: AppTypography.helper),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field('ID', d.name),
                _Field(tr('Issued by'), d.issuer ?? 'Not given'),
                _Field(WalletIdDesign.of(d.idKind).numberLabel, d.shownNumber ?? 'Not entered'),
                _Field(tr('Name'), d.details.holderName ?? 'Not entered'),
                for (final key in {...WalletIdDesign.of(d.idKind).front, ...WalletIdDesign.of(d.idKind).back})
                  if (fieldValue(key, d) case final v?) _Field(fieldLabel(key), v),
                if (d.expiresOn == null) _Field(tr('Valid until'), 'No expiry date given'),
                if (d.uploadedAt != null) _Field(tr('Added'), _date(d.uploadedAt!.toLocal())),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: tr('Edit details'),
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  onPressed: _removing ? null : _editDetails,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Checks on this ID'), style: AppTypography.cardHeading),
                const SizedBox(height: AppSpacing.md),
                _StatusRow(
                  title: tr('This upload'),
                  status: _DocumentStatusChip(status: d.status),
                  details: [
                    if (d.status == WalletDocumentStatus.verifiedByLgu)
                      'LGU staff verified this ID${d.verifiedAt == null ? '' : ' on ${_date(d.verifiedAt!.toLocal())}'}. '
                          'It carries the Esperanza seal in your wallet.',
                    if (d.status == WalletDocumentStatus.returnedByLgu) ...[
                      'Reason: ${d.lguRemarks ?? 'No reason given.'}',
                      'Use Replace below to send a clearer photo.',
                    ],
                    if (d.status == WalletDocumentStatus.checkedByDidit)
                      'Only LGU staff can verify it for the Esperanza seal.',
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                _StatusRow(
                  title: tr('Didit check'),
                  status: d.checkedAt != null
                      ? _PlainChip(
                          label: tr('Checked'),
                          icon: Icons.verified_outlined,
                          foreground: AppColors.sky700,
                          background: AppColors.sky50,
                        )
                      : _PlainChip(
                          label: tr('Not checked'),
                          foreground: AppColors.slate600,
                          background: AppColors.slate100,
                        ),
                  details: [
                    if (d.checkedAt != null)
                      '${d.checkSource == 'registration' ? 'Didit checked this ID when you verified your account' : 'Didit checked this ID when you scanned it'}'
                          ' on ${_date(d.checkedAt!.toLocal())}.'
                    else
                      'Didit did not check this ID.',
                    if (d.checkSource == 'registration' && d.details.idNumber == null && d.numberLast4 != null)
                      'Only the last four digits were kept. Use Edit details to add the full number.',
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                _StatusRow(
                  title: tr('Issuing agency'),
                  status: _PlainChip(
                    label: tr('Not available'),
                    foreground: AppColors.slate600,
                    background: AppColors.slate100,
                  ),
                  details: ['Esperanza is not connected to the agency that issued this ID.'],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: tr('Replace'),
            icon: Icons.sync_rounded,
            variant: AppButtonVariant.secondary,
            fullWidth: true,
            onPressed: _removing ? null : () => Navigator.of(context).pop(_DocumentAction.replace),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: tr('Remove from wallet'),
            icon: Icons.delete_outline_rounded,
            variant: AppButtonVariant.danger,
            fullWidth: true,
            loading: _removing,
            onPressed: _remove,
          ),
        ],
      ),
    );
  }
}

class _SideImage extends StatelessWidget {
  const _SideImage({required this.label, required this.url, required this.onView});

  final String label;
  final String? url;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    final missing = Container(
      color: AppColors.slate100,
      alignment: Alignment.center,
      child: Text(tr('This image cannot be shown right now.'), style: AppTypography.helper),
    );
    final waiting = Container(color: AppColors.slate100);
    final failed = Container(
      color: AppColors.slate100,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh_rounded, size: AppSizes.iconBase, color: AppColors.textMuted),
          SizedBox(height: AppSpacing.xs),
          Text(
            'This image could not be loaded. Tap to try again.',
            textAlign: TextAlign.center,
            style: AppTypography.helper,
          ),
        ],
      ),
    );
    return Semantics(
      button: onView != null,
      label: '$label side. ${onView == null ? '' : 'Double tap to view full screen.'}',
      child: GestureDetector(
        onTap: onView,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AspectRatio(
            aspectRatio: 1.58,
            child: url == null
                ? missing
                : _RetryingImage(url: url!, waiting: waiting, failed: failed, tapToRetry: true),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTypography.helper)),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyText.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── Add ID

/// Add an ID to the wallet, or replace one ([replacing]): the type (a listed
/// one, or Other with its own name and issuer), an optional expiry date, the
/// front (required) and the back. Nothing chosen here sets a status.
///
/// A kind Didit reads ([diditKinds], 2026-10-14) is scanned on Didit's screen
/// instead, and its card made from Didit's result, "Checked by Didit"; the
/// resident can still upload photos instead.
class AddWalletIdScreen extends StatefulWidget {
  const AddWalletIdScreen({super.key, required this.types, this.diditKinds = const [], this.replacing});

  final List<WalletIdType> types;
  final List<String> diditKinds;
  final WalletDocument? replacing;

  @override
  State<AddWalletIdScreen> createState() => _AddWalletIdScreenState();
}

class _AddWalletIdScreenState extends State<AddWalletIdScreen> {
  /// Over this the image is refused before sending (the server checks too).
  static const maxBytes = 10 * 1024 * 1024;

  WalletIdType? _type;
  final _name = TextEditingController();
  final _issuer = TextEditingController();
  DateTime? _expires;
  PickedImage? _front;
  PickedImage? _back;
  String? _frontPath;
  String? _backPath;
  final _details = _DetailsControllers();
  bool _reading = false;

  /// The face on the front photo, for the card's picture.
  PortraitBox? _portrait;

  /// Set once text was read off the photos into the fields.
  bool _readFromPhotos = false;
  bool _sending = false;
  String? _error;
  bool _tried = false;

  @override
  void initState() {
    super.initState();
    final r = widget.replacing;
    if (r != null) {
      _type = widget.types.where((t) => t.key == r.idKind).firstOrNull;
      if (r.idKind == 'other') {
        _name.text = r.name;
        _issuer.text = r.issuer ?? '';
      }
      _expires = r.expiresOn;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _issuer.dispose();
    _details.dispose();
    super.dispose();
  }

  /// Reads the photos on the phone and fills what is still empty.
  Future<void> _readPhotos() async {
    final kind = _type?.key;
    if (kind == null || (_frontPath == null && _backPath == null)) return;
    setState(() => _reading = true);
    final reading = await IdTextReader.read(kind, frontPath: _frontPath, backPath: _backPath);
    if (!mounted) return;
    setState(() {
      _reading = false;
      if (reading != null) {
        final filled = _details.fillEmpty(reading);
        if (_expires == null && reading.expiresOn != null) {
          _expires = reading.expiresOn;
        }
        _readFromPhotos = _readFromPhotos || filled || reading.expiresOn != null;
      }
    });
  }

  bool get _isOther => _type?.isOther ?? false;

  /// The resident chose to upload photos of a kind Didit could scan.
  bool _uploadInstead = false;

  /// This kind is scanned on Didit's screen, unless the resident chose not to.
  bool get _scan => !_uploadInstead && _type != null && widget.diditKinds.contains(_type!.key);

  Future<void> _scanWithDidit() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final r = await WalletService.scanWithDidit(_type!.key, replaces: widget.replacing?.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      switch (r.outcome) {
        case WalletScanOutcome.checked || WalletScanOutcome.notChecked:
          if (r.document case final doc?) await WalletService.placeFace(doc);
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                r.outcome == WalletScanOutcome.checked
                    ? 'Added to your wallet, checked by Didit.'
                    : 'Added to your wallet. Didit did not finish checking it.',
              ),
            ),
          );
          Navigator.of(context).pop(true);
        case WalletScanOutcome.pending:
          messenger.showSnackBar(
            SnackBar(content: Text(tr('Didit is still checking your ID. It appears in your wallet when it is done.'))),
          );
          Navigator.of(context).pop(true);
        case WalletScanOutcome.cancelled:
          setState(() {
            _sending = false;
            _error = 'The scan was not finished. Try again, or upload photos instead.';
          });
        case WalletScanOutcome.declined:
          setState(() {
            _sending = false;
            _error = '${r.explanation} Try again, or upload photos instead.';
          });
        case WalletScanOutcome.closed:
          setState(() {
            _sending = false;
            _error = 'Didit did not finish the scan. Try again, or upload photos instead.';
          });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message();
      });
    }
  }

  String? get _problem {
    if (_type == null) return 'Choose the type of ID.';
    if (_isOther && _name.text.trim().isEmpty) return 'Enter the name of the ID.';
    if (_isOther && _issuer.text.trim().isEmpty) return 'Enter who issued the ID.';
    if (_front == null) return 'Add a photo of the front of the ID.';
    return null;
  }

  Future<void> _pick({required bool front, required ImageSource source}) async {
    final file = await pickImageProtected(
      context,
      source: source,
      maxDimension: 2000,
      explanation: 'Esperanza needs this to add a photo of your ID to your wallet.',
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > maxBytes) {
      setState(() => _error = 'That image is larger than 10 MB. Please choose a smaller one.');
      return;
    }
    final picked = (bytes: bytes, filename: file.name);
    setState(() {
      _error = null;
      if (front) {
        _front = picked;
        _frontPath = file.path;
        _portrait = null;
      } else {
        _back = picked;
        _backPath = file.path;
      }
    });
    if (front) {
      final portrait = await IdPortraitFinder.find(file.path, bytes);
      if (mounted) setState(() => _portrait = portrait);
    }
    await _readPhotos();
  }

  Future<void> _submit() async {
    setState(() => _tried = true);
    final problem = _problem;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await WalletService.addId(
        idKind: _type!.key,
        front: _front!,
        back: _back,
        name: _isOther ? _name.text : null,
        issuer: _isOther ? _issuer.text : null,
        expiresOn: _expires,
        replaces: widget.replacing?.id,
        details: _details.toDetails(WalletIdDesign.of(_type!.key)),
        portraitBox: _portrait?.encode(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final replacing = widget.replacing;
    return Scaffold(
      appBar: AppBar(title: Text(replacing == null ? 'Add ID' : 'Replace ID')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          if (replacing != null) ...[
            Text('The new photos take the place of your ${replacing.name}.', style: AppTypography.helper),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppSelectField<WalletIdType>(
            label: tr('Type of ID'),
            required: true,
            value: _type,
            options: widget.types,
            labelBuilder: (t) => t.name,
            hintText: tr('Choose the type of ID'),
            onChanged: replacing != null
                ? (_) {}
                : (t) {
                    setState(() {
                      _type = t;
                      _uploadInstead = false;
                      _error = null;
                    });
                    _readPhotos();
                  },
          ),
          if (_type != null && !_isOther && _type!.issuer != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Issued by ${_type!.issuer}', style: AppTypography.helper),
          ],
          if (_isOther) ...[
            const SizedBox(height: AppSpacing.fieldGap),
            AppTextField(
              label: tr('Name of the ID'),
              required: true,
              controller: _name,
              maxLength: 80,
              hintText: tr('e.g. Barangay Health Worker ID'),
              error: _tried && _name.text.trim().isEmpty ? 'Enter the name of the ID.' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.fieldGap),
            AppTextField(
              label: tr('Issued by'),
              required: true,
              controller: _issuer,
              maxLength: 120,
              hintText: tr('The office or organization that issued it'),
              error: _tried && _issuer.text.trim().isEmpty ? 'Enter who issued the ID.' : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_scan) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_outlined, size: AppSizes.iconBase, color: AppColors.sky700),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(tr('Scan it with Didit'), style: AppTypography.cardHeading)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Didit reads and checks your ${_type!.name} on its own screen, and its card in your wallet '
                    'shows "Checked by Didit". Only LGU staff can verify it for the Esperanza seal.',
                    style: AppTypography.helper,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.rose700)),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: tr('Scan with Didit'),
              icon: Icons.document_scanner_outlined,
              fullWidth: true,
              loading: _sending,
              onPressed: _scanWithDidit,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: tr('Upload photos instead'),
              variant: AppButtonVariant.ghost,
              fullWidth: true,
              onPressed: _sending
                  ? null
                  : () => setState(() {
                      _uploadInstead = true;
                      _error = null;
                    }),
            ),
          ] else ...[
          const SizedBox(height: AppSpacing.lg),
          _ImageSlot(
            title: tr('Front'),
            required: true,
            image: _front,
            missing: _tried && _front == null,
            onPick: (source) => _pick(front: true, source: source),
            onRemove: () => setState(() {
              _front = null;
              _frontPath = null;
              _portrait = null;
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ImageSlot(
            title: tr('Back'),
            image: _back,
            onPick: (source) => _pick(front: false, source: source),
            onRemove: () => setState(() {
              _back = null;
              _backPath = null;
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Your ID is kept as uploaded and is not checked. JPG, PNG or WebP, up to 10 MB per side.',
            style: AppTypography.helper,
          ),
          if (_type != null) ...[
            const SizedBox(height: AppSpacing.sectionGap),
            Text(tr('What the ID says'), style: AppTypography.cardHeading),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _reading
                  ? 'Reading your photos…'
                  : _readFromPhotos
                  ? 'Read from your photos on this phone. Check every detail against your ID and correct anything that is wrong.'
                  : 'These go on your ID\'s card in the wallet. Add a photo and they are read from it, or type them.',
              style: AppTypography.helper.copyWith(color: _readFromPhotos && !_reading ? AppColors.amber700 : null),
            ),
            if (_reading) ...[const SizedBox(height: AppSpacing.sm), const LinearProgressIndicator()],
            const SizedBox(height: AppSpacing.headingGap),
            _DetailFields(
              kind: _type!.key,
              c: _details,
              expires: _expires,
              onExpires: (v) => setState(() => _expires = v),
              onChanged: () => setState(() {}),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.rose700)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: replacing == null ? 'Add to wallet' : 'Replace',
            fullWidth: true,
            loading: _sending,
            onPressed: _submit,
          ),
          ],
        ],
      ),
    );
  }
}

/// The form fields for what an ID says, shared by Add ID and Edit details.
class _DetailsControllers {
  final number = TextEditingController();
  final name = TextEditingController();
  final address = TextEditingController();
  final _extras = <String, TextEditingController>{};
  DateTime? birthdate;
  String? sex;

  TextEditingController extra(String key) => _extras.putIfAbsent(key, TextEditingController.new);

  void fillFrom(IdDetails d) {
    number.text = d.idNumber ?? '';
    name.text = d.holderName ?? '';
    address.text = d.address ?? '';
    birthdate = d.birthdate == null ? null : DateTime.tryParse(d.birthdate!);
    sex = d.sex;
    d.extras.forEach((k, v) => extra(k).text = v);
  }

  /// Fills only what is still empty, so nothing the resident typed is
  /// overwritten. True when anything was filled.
  bool fillEmpty(IdReading r) {
    var filled = false;
    void text(TextEditingController c, String? v) {
      if (v != null && v.trim().isNotEmpty && c.text.trim().isEmpty) {
        c.text = v.trim();
        filled = true;
      }
    }

    text(number, r.idNumber);
    text(name, r.holderName);
    text(address, r.address);
    if (birthdate == null && r.birthdate != null) {
      birthdate = r.birthdate;
      filled = true;
    }
    if (sex == null && r.sex != null) {
      sex = r.sex;
      filled = true;
    }
    r.extras.forEach((k, v) => text(extra(k), v));
    return filled;
  }

  IdDetails toDetails(WalletIdDesign design) => IdDetails(
    idNumber: number.text.trim().isEmpty ? null : number.text.trim(),
    holderName: name.text.trim().isEmpty ? null : name.text.trim(),
    birthdate: birthdate == null ? null : _isoDate(birthdate!),
    sex: sex,
    address: address.text.trim().isEmpty ? null : address.text.trim(),
    extras: {
      for (final k in design.extras)
        if ((_extras[k]?.text.trim() ?? '').isNotEmpty) k: _extras[k]!.text.trim(),
    },
  );

  void dispose() {
    number.dispose();
    name.dispose();
    address.dispose();
    for (final c in _extras.values) {
      c.dispose();
    }
  }
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// What the ID says: its number (by the name it goes by on that kind of ID),
/// the name, birth date, sex, address, expiry and the kind's own fields.
class _DetailFields extends StatelessWidget {
  const _DetailFields({
    required this.kind,
    required this.c,
    required this.expires,
    required this.onExpires,
    required this.onChanged,
  });

  final String kind;
  final _DetailsControllers c;
  final DateTime? expires;
  final ValueChanged<DateTime?> onExpires;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final design = WalletIdDesign.of(kind);
    final usesSex = [...design.front, ...design.back].contains('sex');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: kind == 'other' ? 'ID number' : 'ID number (${design.numberLabel})',
          controller: c.number,
          maxLength: 40,
          hintText: tr('As printed on the ID'),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        AppTextField(label: tr('Name as printed'), controller: c.name, maxLength: 160, onChanged: (_) => onChanged()),
        const SizedBox(height: AppSpacing.fieldGap),
        AppDateField(
          label: tr('Date of birth'),
          value: c.birthdate,
          hintText: tr('Not entered'),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          onChanged: (d) {
            c.birthdate = d;
            onChanged();
          },
        ),
        if (usesSex) ...[
          const SizedBox(height: AppSpacing.fieldGap),
          AppSelectField<String>(
            label: tr('Sex'),
            value: c.sex,
            options: const ['Male', 'Female'],
            labelBuilder: (s) => s,
            hintText: tr('Not entered'),
            onChanged: (s) {
              c.sex = s;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: AppSpacing.fieldGap),
        AppTextField(
          label: tr('Address'),
          controller: c.address,
          maxLength: 255,
          maxLines: 2,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        AppDateField(
          label: tr('Valid until (if printed on the ID)'),
          value: expires,
          hintText: 'No expiry date',
          firstDate: DateTime(2000),
          lastDate: DateTime(DateTime.now().year + 30),
          onChanged: onExpires,
        ),
        if (expires != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: () => onExpires(null), child: const Text('Clear expiry date')),
          ),
        for (final key in design.extras) ...[
          const SizedBox(height: AppSpacing.fieldGap),
          AppTextField(
            label: key == 'registered_on' ? '${fieldLabel(key)} (yyyy-mm-dd)' : fieldLabel(key),
            controller: c.extra(key),
            maxLength: 120,
            onChanged: (_) => onChanged(),
          ),
        ],
      ],
    );
  }
}

/// Correct what a kept ID says. Saving a change to an ID the LGU verified or
/// returned sends it back for review.
class _EditIdDetailsScreen extends StatefulWidget {
  const _EditIdDetailsScreen({required this.document});

  final WalletDocument document;

  @override
  State<_EditIdDetailsScreen> createState() => _EditIdDetailsScreenState();
}

class _EditIdDetailsScreenState extends State<_EditIdDetailsScreen> {
  final _c = _DetailsControllers();
  DateTime? _expires;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c.fillFrom(widget.document.details);
    _expires = widget.document.expiresOn;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final d = widget.document;
      await WalletService.updateDetails(d.id, _c.toDetails(WalletIdDesign.of(d.idKind)), expiresOn: _expires);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.document;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Edit details'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          Text('What your ${d.name} says, as printed on it.', style: AppTypography.helper),
          if (d.status == WalletDocumentStatus.verifiedByLgu || d.status == WalletDocumentStatus.returnedByLgu) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              tr('Saving a change sends this ID back to the LGU for review.'),
              style: AppTypography.helper.copyWith(color: AppColors.amber700),
            ),
          ],
          if (d.checkedAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Changing the number, name or dates ends Didit\'s check of this ID.',
              style: AppTypography.helper.copyWith(color: AppColors.amber700),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _DetailFields(
            kind: d.idKind,
            c: _c,
            expires: _expires,
            onExpires: (v) => setState(() => _expires = v),
            onChanged: () => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: AppTypography.helper.copyWith(color: AppColors.rose700)),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: tr('Save'), fullWidth: true, loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({
    required this.title,
    required this.image,
    required this.onPick,
    required this.onRemove,
    this.required = false,
    this.missing = false,
  });

  final String title;
  final PickedImage? image;
  final bool required;
  final bool missing;
  final void Function(ImageSource source) onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final img = image;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            required ? '$title (required)' : '$title (optional)',
            style: AppTypography.labelText.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (img != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AspectRatio(
                aspectRatio: 1.58,
                child: Image.memory(
                  img.bytes is Uint8List ? img.bytes as Uint8List : Uint8List.fromList(img.bytes),
                  fit: BoxFit.contain,
                  semanticLabel: '$title of the ID',
                ),
              ),
            )
          else
            Container(
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: missing ? AppColors.rose50 : AppColors.slate50,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                missing ? 'Add a photo of the $title.' : 'No photo yet',
                style: AppTypography.helper.copyWith(color: missing ? AppColors.rose700 : null),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: img == null ? 'Take photo' : 'Retake',
                icon: Icons.photo_camera_outlined,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: () => onPick(ImageSource.camera),
              ),
              AppButton(
                label: img == null ? 'Choose photo' : 'Choose another',
                icon: Icons.photo_library_outlined,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
                onPressed: () => onPick(ImageSource.gallery),
              ),
              if (img != null)
                AppButton(
                  label: tr('Remove'),
                  icon: Icons.close_rounded,
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.ghost,
                  onPressed: onRemove,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
