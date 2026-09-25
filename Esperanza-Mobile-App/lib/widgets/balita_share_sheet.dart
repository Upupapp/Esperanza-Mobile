import 'package:flutter/material.dart';
import '../theme/app_elevation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/announcement.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_dialogs.dart';

/// Social-share chooser opened from Balita's Share action — a small sheet
/// of practical destinations rather than jumping straight to the OS share
/// sheet. There's no real share-count endpoint (a citizen's own like/
/// comment/report are all real now, but nothing increments `shares` server-
/// side — confirmed against the backend directly, not assumed), so every
/// destination shares the same plain-text summary [_shareText]; app-
/// specific entries just pre-target that text at each app's own share
/// intent instead of making the citizen pick it out of a full OS chooser.
/// The share action itself is real (it's a genuine OS share/deep-link),
/// only the "N shares" counter it used to bump locally is gone.
///
/// This never crashes when a platform app isn't installed (common on the
/// emulator this is tested on): each app entry tries its own `url_launcher`
/// scheme first and falls back to the native share sheet the moment
/// `canLaunchUrl` says no, rather than assuming the app exists.
class BalitaShareSheet {
  BalitaShareSheet._();

  static Future<void> show(BuildContext context, Announcement post) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(post: post),
    );
  }
}

String _shareText(Announcement post) {
  final who = post.isOfficial ? 'Esperanza LGU' : post.author;
  final excerpt = post.body.trim();
  return ['$who — Balita, Esperanza', if (excerpt.isNotEmpty) excerpt].join('\n\n');
}

class _ShareSheet extends StatelessWidget {
  final Announcement post;
  const _ShareSheet({required this.post});

  Future<void> _launchOrFallback(BuildContext context, Uri uri) async {
    final launched = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return;
    // App isn't installed (or the platform refused the scheme, common on
    // an emulator) — never a dead tap, always land somewhere useful.
    if (!context.mounted) return;
    await _nativeShare(context);
  }

  Future<void> _nativeShare(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final who = post.isOfficial ? 'Esperanza LGU' : post.author;
    await SharePlus.instance.share(
      ShareParams(text: _shareText(post), subject: 'Balita: $who', sharePositionOrigin: origin),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _shareText(post)));
    if (context.mounted) AppDialogs.toast(context, 'Link copied');
  }

  @override
  Widget build(BuildContext context) {
    final text = Uri.encodeComponent(_shareText(post));

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.md),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share Balita Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 18,
              runSpacing: 16,
              children: [
                _ShareOption(
                  icon: Icons.facebook_rounded,
                  color: ThirdPartyBrandColors.facebook,
                  label: 'Facebook',
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchOrFallback(
                      context,
                      Uri.parse('https://www.facebook.com/sharer/sharer.php?quote=$text'),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.chat_bubble_rounded,
                  color: ThirdPartyBrandColors.messenger,
                  label: 'Messenger',
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchOrFallback(context, Uri.parse('fb-messenger://share?text=$text'));
                  },
                ),
                _ShareOption(
                  icon: Icons.alternate_email_rounded,
                  color: Colors.black,
                  label: 'X',
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchOrFallback(context, Uri.parse('https://twitter.com/intent/tweet?text=$text'));
                  },
                ),
                _ShareOption(
                  icon: Icons.forum_rounded,
                  color: ThirdPartyBrandColors.viber,
                  label: 'Viber',
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchOrFallback(context, Uri.parse('viber://forward?text=$text'));
                  },
                ),
                _ShareOption(
                  icon: Icons.chat_rounded,
                  color: ThirdPartyBrandColors.whatsapp,
                  label: 'WhatsApp',
                  onTap: () {
                    Navigator.of(context).pop();
                    _launchOrFallback(context, Uri.parse('whatsapp://send?text=$text'));
                  },
                ),
                _ShareOption(
                  icon: Icons.link_rounded,
                  color: AppColors.slate600,
                  label: 'Copy Link',
                  onTap: () {
                    Navigator.of(context).pop();
                    _copyLink(context);
                  },
                ),
                _ShareOption(
                  icon: Icons.more_horiz_rounded,
                  color: AppColors.slate600,
                  label: 'More',
                  onTap: () {
                    Navigator.of(context).pop();
                    _nativeShare(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ShareOption({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
