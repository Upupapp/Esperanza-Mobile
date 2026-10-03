import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../services/api_client.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../theme/app_typography.dart';

/// The mandatory preview step between picking/capturing a photo and it
/// actually replacing the profile photo — nothing is saved just because a
/// picture was taken or selected. Pops `true` only after "Save Profile
/// Photo" has sent it to the LGU (POST /citizen/profile/photo), where it
/// waits for an officer; the server owns the 6-month rule;
/// pops `false` for "Retake"/"Choose Another" (the caller re-opens the
/// source picker and pushes a fresh instance of this screen); pops `null`
/// (back gesture / app bar back) to abandon the whole flow with nothing
/// changed.
class ProfilePhotoPreviewScreen extends StatefulWidget {
  final Uint8List bytes;
  final ImageSource source;
  const ProfilePhotoPreviewScreen({super.key, required this.bytes, required this.source});

  static const saveFailedText = 'Your photo could not be saved. Please try again.';

  /// The photo is an identification record (owner ruling, backlog B9): it
  /// goes to the Municipality and waits for an officer before it is on the
  /// Digital ID.
  static const sentText = 'Your photo is sent to the Municipality. It appears on your Digital ID once the LGU approves it.';


  @override
  State<ProfilePhotoPreviewScreen> createState() => _ProfilePhotoPreviewScreenState();
}

class _ProfilePhotoPreviewScreenState extends State<ProfilePhotoPreviewScreen> {
  bool _saving = false;

  // A camera capture/gallery pick can be several MB at several-thousand-px
  // resolution — decoding all of that just to paint a 192-logical-px
  // preview circle wastes memory for no visible gain. The full-resolution
  // `widget.bytes` are still what gets saved/persisted below; only this
  // preview's own decode is capped.
  static const _previewDiameter = 192.0;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final session = context.read<CitizenSessionService>();
      final profiles = context.read<ResidentProfileService>();
      final accountId = session.account!.id;
      await session.uploadProfilePhoto(widget.bytes);
      // The phone keeps a copy to show the resident; the server counts the
      // six months from the officer's approval, not from here.
      await profiles.updateProfilePhoto(accountId, photoBytes: widget.bytes, startCooldown: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // A stated refusal (the six-month rule) in the server's words; anything
      // else as the general failure.
      final refused = e.code == 'PHOTO_CHANGE_TOO_SOON' || e.code == 'ACCOUNT_ARCHIVED';
      AppDialogs.toast(context, refused ? e.message() : ProfilePhotoPreviewScreen.saveFailedText, success: false);
      return;
    } catch (_) {
      // Until 2026-09-28 a failed save left the spinner running and both
      // buttons disabled for good; the only way out was the back arrow.
      if (!mounted) return;
      setState(() => _saving = false);
      AppDialogs.toast(context, ProfilePhotoPreviewScreen.saveFailedText, success: false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Photo')),
      body: SafeArea(
        // Scrolls when it must (a short phone, large text) while the buttons
        // still sit at the bottom when there is room.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - AppSpacing.xl * 2),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),
                    CircleAvatar(
                      radius: _previewDiameter / 2,
                      backgroundColor: AppColors.brand50,
                      backgroundImage: ResizeImage.resizeIfNeeded(
                        (_previewDiameter * MediaQuery.devicePixelRatioOf(context)).round(),
                        null,
                        MemoryImage(widget.bytes),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'This is how your profile photo will look. Make sure your full face is clearly visible before saving.',
                      textAlign: TextAlign.center,
                      style: AppTypography.helper,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: EdgeInsets.only(right: AppSpacing.xs),
                              child: Icon(Icons.verified_user_outlined, size: AppSizes.iconSm, color: AppColors.textMuted),
                            ),
                          ),
                          TextSpan(text: ProfilePhotoPreviewScreen.sentText),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: AppTypography.fine,
                    ),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: widget.source == ImageSource.camera ? 'Retake' : 'Choose Another',
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Save Profile Photo',
                      fullWidth: true,
                      size: AppButtonSize.lg,
                      loading: _saving,
                      onPressed: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
