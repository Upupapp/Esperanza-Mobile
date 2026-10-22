import 'package:flutter/material.dart';

import '../../l10n/tr.dart';
/// One first-run scene: a photograph, two lines of headline, and a promise the
/// app can keep.
///
/// Structured after the Servana client's `WelcomeSceneSpec` — copy, assets and
/// screen-reader descriptions live here rather than inside animation widgets,
/// so the words can be reviewed without reading a layout.
///
/// **What is deliberately absent.** The retired composite artwork advertised
/// "Business Permit — Approved" on screen two. Business permits are a real
/// Dokyu service; an onboarding screen implying one has been *approved* is not,
/// because nothing in this app approves anything — there is no backend. Every
/// line below is one the frontend can keep.
@immutable
class OnboardingSceneSpec {
  const OnboardingSceneSpec({
    required this.id,
    required this.headline,
    required this.subtext,
    required this.backgroundAsset,
    required this.semanticDescription,
    required this.features,
  });

  /// Stable id, used for widget keys.
  final String id;

  /// Two short lines. The break is authored, not left to the layout — these
  /// are the words a citizen reads first and they should break where they were
  /// meant to. The second line is set in gold.
  final String headline;

  /// One sentence of detail. Must not describe anything the app cannot do.
  final String subtext;

  final String backgroundAsset;

  /// What the photograph shows, for a screen reader.
  final String semanticDescription;

  /// The three capabilities under the copy: icon tiles on page one, row
  /// cards on pages two and three.
  final List<OnboardingFeature> features;

  /// The first headline line (white).
  String get headlineLead => headline.split('\n').first;

  /// The second headline line (gold).
  String get headlineAccent => headline.split('\n').last;
}

@immutable
class OnboardingFeature {
  const OnboardingFeature({required this.icon, required this.label, this.motion = FeatureMotion.bob});

  final IconData icon;
  final String label;

  /// How the icon moves while the page is open (the design's own choice
  /// per icon).
  final FeatureMotion motion;
}

/// The design's small ambient motions for a feature icon.
enum FeatureMotion { bob, swing, wobble, pulse }

/// The three scenes, as the owner's design sets them ("Esperanza Onboarding
/// Prototype", 2026-10-12).
///
/// **Copy language.** Filipino headline, English supporting line. That is the
/// split the app already uses — its home hero greets in Filipino ("Magandang
/// araw") over an English interface — and it is the split the municipality's
/// own campaign artwork uses.
///
/// Page two used to carry a line of its own, "Dokyu and Tulong are available
/// to verified residents."; the design has none, and Dokyu and Tulong still
/// say so themselves to anyone not yet verified.
final onboardingScenes = <OnboardingSceneSpec>[
  OnboardingSceneSpec(
    id: 'scene_bayan',
    headline: 'Ang Esperanza,\nnasa iyong kamay.',
    subtext:
        'Municipal services, local news, and your resident account — all in one app.',
    backgroundAsset: 'assets/images/welcome/page_1_bg.jpg',
    semanticDescription: 'Page 1 of 3: the Esperanza coastline at sunset',
    features: [
      OnboardingFeature(icon: Icons.person_outline_rounded, label: 'Resident Profile'),
      OnboardingFeature(icon: Icons.badge_outlined, label: 'Digital ID'),
      OnboardingFeature(icon: Icons.account_balance_outlined, label: 'LGU Services'),
    ],
  ),
  OnboardingSceneSpec(
    id: 'scene_serbisyo',
    headline: 'Mag-request.\nHindi na pumila.',
    subtext:
        'Send Dokyu and Tulong requests, upload your requirements, and follow every update from your phone.',
    backgroundAsset: 'assets/images/welcome/page_2_bg.jpg',
    semanticDescription:
        'Page 2 of 3: a municipal staff member reviewing a document at her desk',
    features: [
      OnboardingFeature(icon: Icons.description_rounded, label: 'Submit Requirements'),
      OnboardingFeature(icon: Icons.trending_up_rounded, label: 'Track Status'),
      OnboardingFeature(icon: Icons.notifications_rounded, label: 'View Updates', motion: FeatureMotion.swing),
    ],
  ),
  OnboardingSceneSpec(
    id: 'scene_handa',
    headline: 'Laging alam.\nLaging handa.',
    subtext:
        'Official news and events, emergency hotlines, evacuation centers, and incident reporting — ready when you need them.',
    backgroundAsset: 'assets/images/welcome/page_3_bg.jpg',
    semanticDescription:
        'Page 3 of 3: an emergency response team assisting a family during a flood',
    features: [
      OnboardingFeature(icon: Icons.campaign_rounded, label: 'Official Balita', motion: FeatureMotion.wobble),
      OnboardingFeature(icon: Icons.calendar_month_rounded, label: tr('Upcoming Events')),
      OnboardingFeature(icon: Icons.health_and_safety_rounded, label: 'Emergency Help', motion: FeatureMotion.pulse),
    ],
  ),
];

/// Shown beside the seal on every scene, on two lines in the design.
const onboardingBrandName = 'Municipalidad ng Esperanza';

/// `rectangle_cityhall.jpg` is deliberately unused here. It is a genuine
/// municipal hall, but the seal on its facade reads *Esperanza, Agusan del
/// Sur* — a different municipality from the *Esperanza, Masbate* this app
/// serves (`settings_screen.dart`: "Municipality of Esperanza, Masbate —
/// Region V"). It is fine where it sits today, as media on one mock Balita
/// post; on the first screen a citizen ever sees it would name the wrong LGU
/// in the most prominent place in the app.
const onboardingExcludedAsset = 'assets/images/rectangle_cityhall.jpg';
