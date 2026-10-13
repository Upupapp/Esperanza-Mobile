import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/id_portrait.dart';
import '../services/wallet_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The wallet's own card for each kind of ID (owner, 2026-10-13): its colours,
/// icon, the name its number goes by, and which of what the ID says goes on
/// the front and the back. Deliberately NOT the agency's design: no seal,
/// logo or layout of the real card, and every card says it is a wallet copy,
/// so it cannot be passed off as the ID itself.
@immutable
class WalletIdDesign {
  const WalletIdDesign({
    required this.top,
    required this.bottom,
    required this.icon,
    required this.numberLabel,
    this.front = const ['birthdate'],
    this.back = const ['address'],
  });

  /// The header band's two colours.
  final Color top;
  final Color bottom;
  final IconData icon;

  /// What the number is called on this kind of ID (PCN, CRN, SS No. ...).
  final String numberLabel;

  /// Field keys under the name and number on the front, and on the back:
  /// birthdate, sex, address, expires_on, or one of the kind's [extraLabels].
  final List<String> front;
  final List<String> back;

  /// The kind's own fields (stored in details), in form order.
  List<String> get extras => [...front, ...back].where(extraLabels.containsKey).toList();

  static WalletIdDesign of(String idKind) => _designs[idKind] ?? _designs['other']!;
}

/// The kind's own fields and how they are labelled.
const extraLabels = <String, String>{
  'blood_type': 'Blood type',
  'civil_status': 'Civil status',
  'place_of_birth': 'Place of birth',
  'restrictions': 'Restrictions',
  'conditions': 'Conditions',
  'nationality': 'Nationality',
  'destination_country': 'Country of work',
  'profession': 'Profession',
  'registered_on': 'Registered',
  'precinct': 'Precinct',
};

const _designs = <String, WalletIdDesign>{
  'philippine_national_id': WalletIdDesign(
    top: AppColors.navy700,
    bottom: AppColors.brand600,
    icon: Icons.fingerprint_rounded,
    numberLabel: 'PCN',
    front: ['birthdate', 'sex'],
    back: ['address', 'blood_type', 'civil_status', 'place_of_birth'],
  ),
  'drivers_license': WalletIdDesign(
    top: AppColors.blue700,
    bottom: AppColors.sky700,
    icon: Icons.directions_car_filled_rounded,
    numberLabel: 'License no.',
    front: ['birthdate', 'sex', 'expires_on'],
    back: ['address', 'blood_type', 'restrictions', 'conditions'],
  ),
  'passport': WalletIdDesign(
    top: AppColors.navy900,
    bottom: AppColors.indigo700,
    icon: Icons.flight_rounded,
    numberLabel: 'Passport no.',
    front: ['birthdate', 'sex', 'expires_on'],
    back: ['nationality', 'place_of_birth'],
  ),
  'umid': WalletIdDesign(
    top: AppColors.teal700,
    bottom: AppColors.cyan700,
    icon: Icons.credit_card_rounded,
    numberLabel: 'CRN',
    front: ['birthdate', 'sex'],
    back: ['address'],
  ),
  'sss': WalletIdDesign(
    top: AppColors.blue700,
    bottom: AppColors.brand500,
    icon: Icons.shield_outlined,
    numberLabel: 'SS no.',
    front: ['birthdate'],
    back: ['address'],
  ),
  'gsis': WalletIdDesign(
    top: AppColors.emerald700,
    bottom: AppColors.teal500,
    icon: Icons.account_balance_rounded,
    numberLabel: 'BP no.',
    front: ['birthdate'],
    back: ['address'],
  ),
  'philhealth': WalletIdDesign(
    top: AppColors.green700,
    bottom: AppColors.emerald500,
    icon: Icons.health_and_safety_outlined,
    numberLabel: 'PIN',
    front: ['birthdate', 'sex'],
    back: ['address'],
  ),
  'owwa': WalletIdDesign(
    top: AppColors.sky700,
    bottom: AppColors.blue500,
    icon: Icons.public_rounded,
    numberLabel: 'OWWA no.',
    front: ['birthdate'],
    back: ['destination_country', 'address'],
  ),
  'prc': WalletIdDesign(
    top: AppColors.indigo700,
    bottom: AppColors.purple500,
    icon: Icons.workspace_premium_outlined,
    numberLabel: 'Reg. no.',
    front: ['profession', 'expires_on'],
    back: ['registered_on', 'birthdate'],
  ),
  'postal': WalletIdDesign(
    top: AppColors.orange700,
    bottom: AppColors.amber500,
    icon: Icons.local_post_office_outlined,
    numberLabel: 'PRN',
    front: ['birthdate', 'expires_on'],
    back: ['address', 'nationality'],
  ),
  'voters': WalletIdDesign(
    top: AppColors.purple700,
    bottom: AppColors.indigo500,
    icon: Icons.how_to_vote_outlined,
    numberLabel: 'VIN',
    front: ['birthdate'],
    back: ['address', 'precinct'],
  ),
  'tin': WalletIdDesign(
    top: AppColors.slate700,
    bottom: AppColors.slate500,
    icon: Icons.receipt_long_outlined,
    numberLabel: 'TIN',
    front: ['birthdate'],
    back: ['address'],
  ),
  'other': WalletIdDesign(
    top: AppColors.navy800,
    bottom: AppColors.slate600,
    icon: Icons.badge_outlined,
    numberLabel: 'ID no.',
    front: ['birthdate', 'expires_on'],
    back: ['address'],
  ),
};

/// How a field is labelled on the card.
String fieldLabel(String key) => switch (key) {
  'birthdate' => 'Birth date',
  'sex' => 'Sex',
  'address' => 'Address',
  'expires_on' => 'Valid until',
  _ => extraLabels[key] ?? key,
};

String _formatDate(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  return d == null ? (iso ?? '') : DateFormat('MMM d, yyyy').format(d);
}

/// A field's value for [d], formatted for the card; null when it says nothing.
String? fieldValue(String key, WalletDocument d) {
  final v = switch (key) {
    'birthdate' => d.details.birthdate == null ? null : _formatDate(d.details.birthdate),
    'sex' => d.details.sex,
    'address' => d.details.address,
    'expires_on' => d.expiresOn == null ? null : DateFormat('MMM d, yyyy').format(d.expiresOn!),
    'registered_on' => d.details.extras[key] == null ? null : _formatDate(d.details.extras[key]),
    _ => d.details.extras[key],
  };
  return (v == null || v.trim().isEmpty) ? null : v;
}

/// One side of a kept ID, drawn as the wallet's card for its kind from what
/// the ID says. Laid out at a fixed size and scaled to fit, so the deck and
/// the full-size view look the same; [photoUrl] (the resident's own photo of
/// that side) sits where a card would carry its picture, and [badge] in the
/// top corner.
class WalletIdCard extends StatelessWidget {
  const WalletIdCard({super.key, required this.document, required this.back, this.photo, this.badge});

  static const designWidth = 350.0;
  static const designHeight = 216.0;

  final WalletDocument document;
  final bool back;

  /// The resident's photo of this side, or null.
  final Widget? photo;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final d = document;
    final design = WalletIdDesign.of(d.idKind);
    return FittedBox(
      fit: BoxFit.contain,
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.navy900.withValues(alpha: 0.12)),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Band(design: design, title: back ? '${d.name} · Back' : d.name, issuer: d.issuer, slim: back),
                      Expanded(
                        child: back
                            ? _BackBody(document: d, design: design)
                            : _FrontBody(document: d, design: design, photo: photo),
                      ),
                      _Footer(design: design),
                    ],
                  ),
                ),
              ),
              if (badge != null) Positioned(top: 8, right: 8, child: badge!),
            ],
          ),
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.design, required this.title, required this.issuer, required this.slim});

  final WalletIdDesign design;
  final String title;
  final String? issuer;
  final bool slim;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: slim ? 36 : 50,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, 96, 0),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [design.top, design.bottom])),
      child: Row(
        children: [
          Container(
            width: slim ? 22 : 30,
            height: slim ? 22 : 30,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
            child: Icon(design.icon, size: slim ? 13 : 17, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelText.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                if (!slim && issuer != null)
                  Text(
                    issuer!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.fine.copyWith(color: Colors.white.withValues(alpha: 0.8), letterSpacing: 0.4),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FrontBody extends StatelessWidget {
  const _FrontBody({required this.document, required this.design, required this.photo});

  final WalletDocument document;
  final WalletIdDesign design;
  final Widget? photo;

  @override
  Widget build(BuildContext context) {
    final d = document.details;
    final fields = [
      for (final k in design.front)
        if (fieldValue(k, document) case final v?) (fieldLabel(k), v),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PhotoSlot(photo: photo, tint: design.top),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            // A card, not a page: an unusually long value is cut at the
            // card's edge rather than breaking its layout.
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Name'),
                  Text(
                    d.holderName ?? 'Not entered',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: d.holderName == null ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _Label(design.numberLabel),
                  Text(
                    d.idNumber ?? 'Not entered',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyText.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: d.idNumber == null ? AppColors.textMuted : design.top,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 2,
                    children: [
                      for (final (label, value) in fields)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [_Label(label), _Value(value)],
                        ),
                    ],
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

class _BackBody extends StatelessWidget {
  // No picture on the back: the card's picture is the face on the front.
  const _BackBody({required this.document, required this.design});

  final WalletDocument document;
  final WalletIdDesign design;

  @override
  Widget build(BuildContext context) {
    final fields = [
      for (final k in design.back)
        if (fieldValue(k, document) case final v?) (k, fieldLabel(k), v),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: fields.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nothing entered for the back.',
                      style: AppTypography.fine.copyWith(color: AppColors.textMuted),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: 6,
                      children: [
                        for (final (key, label, value) in fields)
                          SizedBox(
                            width: key == 'address' ? 230 : 110,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Label(label),
                                _Value(value, lines: key == 'address' ? 2 : 1),
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

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.photo, required this.tint});

  final Widget? photo;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: photo ?? Icon(Icons.person_outline_rounded, size: 36, color: tint.withValues(alpha: 0.5)),
    );
  }
}

/// Shows only [box] of [child] (a photo laid out to fill), scaled to fill
/// the space it is given: the face on an ID as the card's picture.
class CroppedPortrait extends StatelessWidget {
  const CroppedPortrait({super.key, required this.box, required this.child});

  final PortraitBox box;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // The whole photo at the size where the box fills the slot.
        final w = c.maxWidth / box.w;
        final h = c.maxHeight / box.h;
        double align(double start, double size) => size >= 1 ? 0 : (start / (1 - size)) * 2 - 1;
        return ClipRect(
          child: OverflowBox(
            minWidth: w,
            maxWidth: w,
            minHeight: h,
            maxHeight: h,
            alignment: Alignment(align(box.x, box.w), align(box.y, box.h)),
            child: child,
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.design});

  final WalletIdDesign design;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: design.top.withValues(alpha: 0.08),
      alignment: Alignment.centerLeft,
      child: Text(
        'Esperanza wallet copy · not an official ID',
        style: AppTypography.fine.copyWith(color: AppColors.slate600, letterSpacing: 0.2),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.fine.copyWith(color: AppColors.slate600, letterSpacing: 0.6, height: 1.2),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text, {this.lines = 1});

  final String text;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: lines,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.label.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.25),
    );
  }
}
