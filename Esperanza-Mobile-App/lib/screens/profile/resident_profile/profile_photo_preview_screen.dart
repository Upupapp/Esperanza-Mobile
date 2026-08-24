import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';

/// The mandatory preview step between picking/capturing a photo and it
/// actually replacing the profile photo — nothing is saved just because a
/// picture was taken or selected. Pops `true` only after "Save Profile
/// Photo" successfully persists (which is also the only moment the
/// 6-month cooldown starts, on ResidentProfileService.updateProfilePhoto);
/// pops `false` for "Retake"/"Choose Another" (the caller re-opens the
/// source picker and pushes a fresh instance of this screen); pops `null`
/// (back gesture / app bar back) to abandon the whole flow with nothing
/// changed.
class ProfilePhotoPreviewScreen extends StatefulWidget {
  final Uint8List bytes;
  final ImageSource source;
  const ProfilePhotoPreviewScreen({super.key, required this.bytes, required this.source});

  @override
  State<ProfilePhotoPreviewScreen> createState() => _ProfilePhotoPreviewScreenState();
}

class _ProfilePhotoPreviewScreenState extends State<ProfilePhotoPreviewScreen> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final accountId = context.read<CitizenSessionService>().account!.id;
    await context.read<ResidentProfileService>().updateProfilePhoto(
      accountId,
      photoBytes: widget.bytes,
      startCooldown: true,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Photo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              CircleAvatar(radius: 96, backgroundColor: AppColors.brand50, backgroundImage: MemoryImage(widget.bytes)),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'This is how your profile photo will look. Make sure your full face is clearly visible before saving.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
              ),
              const Spacer(),
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
    );
  }
}
