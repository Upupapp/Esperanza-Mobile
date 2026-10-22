import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/citizen_account.dart';
import '../../../models/resident_profile.dart';
import '../../../models/profile_photo.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/age_calculator.dart';
import '../../../utils/demo_resident_photo.dart';
import '../../../utils/ph_mobile.dart';
import '../../../utils/protected_action.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_date_field.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';
import 'profile_photo_preview_screen.dart';
import '../../../theme/app_typography.dart';

/// Step 1 — Personal Information, as the website's "You" tab: only what the
/// barangay keeps (PUT /citizen/resident-profile `personal`). The name comes
/// from the account and is changed in Edit Profile; there is no separate
/// email, barangay or attachment here, since the server keeps none of them
/// on the profile.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late final CitizenAccount _account;
  late final Individual _original;
  late final TextEditingController _mobile;
  late final TextEditingController _sitioPurok;
  late final TextEditingController _occupation;

  String? _sex;
  String? _civilStatus;
  String? _educationalAttainment;
  String? _income;
  DateTime? _birthdate;
  bool _senior = false;
  bool _pwd = false;
  bool _soloParent = false;
  bool _voter = false;
  bool _fourPs = false;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _account = context.read<CitizenSessionService>().account!;
    final profile = context.read<ResidentProfileService>().profileFor(_account);
    _original = profile.personal;
    _mobile = TextEditingController(text: PhMobile.normalise(_original.mobile));
    _sitioPurok = TextEditingController(text: _original.sitioPurok);
    _occupation = TextEditingController(text: _original.occupation);
    _sex = _original.sex.isEmpty ? null : _original.sex;
    _civilStatus = _original.civilStatus.isEmpty ? null : _original.civilStatus;
    _educationalAttainment = _original.educationalAttainment.isEmpty ? null : _original.educationalAttainment;
    final income = profile.household.monthlyIncome;
    _income = ResidentProfileOptions.monthlyIncome.contains(income) ? income : null;
    _birthdate = _original.birthdate;
    _senior = _original.isSeniorCitizen;
    _pwd = _original.isPWD;
    _soloParent = _original.isSoloParent;
    _voter = _original.isVoter;
    _fourPs = _original.isFourPsBeneficiary;
  }

  @override
  void dispose() {
    for (final c in [_mobile, _sitioPurok, _occupation]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The profile photo is deliberately excluded from this form's own save
  /// cycle — it's set independently and immediately by the camera-icon flow
  /// (see [_onCameraIconTap] -> ResidentProfileService.updateProfilePhoto),
  /// so this always carries forward whatever is *currently* persisted
  /// rather than a stale snapshot from when this screen first opened;
  /// otherwise saving other, unrelated field edits here could silently
  /// revert a photo change made moments earlier on this same screen.
  Individual _buildUpdated() {
    final currentPhoto = context.read<ResidentProfileService>().profileFor(_account).personal;
    return Individual(
      individualId: _original.individualId,
      firstName: _account.firstName,
      middleName: _original.middleName,
      lastName: _account.lastName,
      suffix: _original.suffix,
      sex: _sex ?? '',
      birthdate: _birthdate,
      civilStatus: _civilStatus ?? '',
      mobile: _mobile.text.trim(),
      email: _original.email,
      barangay: _account.barangay,
      sitioPurok: _sitioPurok.text.trim(),
      completeAddress: _original.completeAddress,
      occupation: _occupation.text.trim(),
      educationalAttainment: _educationalAttainment ?? '',
      isSeniorCitizen: _senior,
      isPWD: _pwd,
      isSoloParent: _soloParent,
      isVoter: _voter,
      isFourPsBeneficiary: _fourPs,
      photoPath: currentPhoto.photoPath,
      photoBytesBase64: currentPhoto.photoBytesBase64,
      hasEsperanzaAccount: true,
      linkedCitizenAccountId: _original.individualId,
      familyId: _original.familyId,
      householdId: _original.householdId,
    );
  }

  String? _missingFieldError() {
    if (_sex == null) return 'Please select your sex.';
    if (_birthdate == null) return 'Please select your birthdate.';
    if (_civilStatus == null) return 'Please select your civil status.';
    if (_sitioPurok.text.trim().isEmpty) return 'Please enter your Sitio / Purok.';
    return null;
  }

  Future<void> _save({required bool markComplete}) async {
    // The number may be left blank, but is never saved wrong.
    final mobileError = PhMobile.validate(_mobile.text);
    if (mobileError != null) {
      setState(() => _error = mobileError);
      return;
    }
    if (markComplete) {
      final err = _missingFieldError();
      if (err != null) {
        setState(() => _error = err);
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final accountId = context.read<CitizenSessionService>().account!.id;
    final service = context.read<ResidentProfileService>();
    await service.savePersonal(accountId, _buildUpdated(), markComplete: markComplete);
    await service.setMonthlyIncome(accountId, _income ?? '');
    if (!mounted) return;
    setState(() => _saving = false);
    AppDialogs.toast(context, markComplete ? 'Personal information saved.' : 'Saved for later.');
    Navigator.of(context).pop();
  }

  /// The camera icon's full entry point: the 6-month check first (it blocks
  /// everything below without touching the camera), then the "your photo can
  /// only change every 6 months" confirmation, then the front camera and a
  /// preview, with Retake going back to the camera. Nothing is saved until the
  /// preview screen's "Save Profile Photo" succeeds (see
  /// ProfilePhotoPreviewScreen); cancelling at any step changes nothing.
  ///
  /// A profile photo is taken with the camera only, never picked from the
  /// gallery or the phone's files (Esperanza QA, 2026-10-07): it identifies the
  /// resident on the Digital ID, so it is a photo of them taken now.
  Future<void> _onCameraIconTap() async {
    final profile = context.read<ResidentProfileService>().profileFor(_account);
    // The server owns the six-month rule (counted from the officer's
    // approval); the phone's own record is only the fallback before the
    // profile has loaded.
    final serverPhoto = context.read<CitizenSessionService>().photo;
    final onCooldown = serverPhoto != null ? !serverPhoto.canChange : profile.isProfilePhotoOnCooldown;
    if (onCooldown) {
      final next = serverPhoto != null ? serverPhoto.nextChangeAt : profile.nextProfilePhotoChangeAllowedAt;
      await AppDialogs.centeredInfo(
        context,
        title: 'Profile Photo Change Unavailable',
        message: 'You recently changed your profile photo. For account identification and consistency, profile '
            'photos can only be changed once every 6 months.'
            '${next != null ? '\n\nYou can change your profile photo again on ${DateFormat('MMMM d, y').format(next)}.' : ''}',
      );
      return;
    }

    final proceed = await AppDialogs.centeredConfirm(
      context,
      title: 'Change Profile Photo',
      message: 'Your profile photo can only be changed once every 6 months, and it is taken with your camera.\n\n'
          'For better identification, please take it in a well-lit area with a plain or white '
          'background. Make sure your full face is clearly visible and avoid filters, sunglasses, masks, or '
          'anything that may cover your face.',
      confirmLabel: 'Proceed',
    );
    if (!proceed || !mounted) return;

    while (true) {
      final file = await pickImageProtected(
        context,
        source: ImageSource.camera,
        preferredCamera: CameraDevice.front,
        maxDimension: 1024,
        explanation: 'Esperanza needs your camera to take your profile photo. The LGU checks it before it appears on your Digital ID.',
      );
      if (file == null || !mounted) return;
      // Read bytes up front — on Flutter Web, `file.path` is a blob: URL
      // that `dart:io`'s `File()` cannot open, and bytes are what actually
      // get persisted (see ResidentProfileService.updateProfilePhoto).
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProfilePhotoPreviewScreen(bytes: bytes, source: ImageSource.camera),
        ),
      );
      if (!mounted) return;

      if (saved == true) {
        AppDialogs.toast(context, 'Photo sent. It appears on your Digital ID once the LGU approves it.');
        return;
      }
      if (saved == false) continue; // Retake: back to the camera.
      return; // Dismissed (back gesture/app bar back) — nothing changed.
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPersonal = context.watch<ResidentProfileService>().profileFor(_account).personal;
    final serverPhoto = context.watch<CitizenSessionService>().photo;
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoPicker(
                image: profileImageFor(_account, currentPersonal, approvedUrl: serverPhoto?.approvedUrl),
                // The LGU's approved photo is an identification record: it is
                // replaced through the camera button, never removed here.
                hasCustomPhoto: currentPersonal.photoBytesBase64 != null && serverPhoto?.approvedUrl == null,
                status: _photoStatus(serverPhoto),
                onCameraTap: _onCameraIconTap,
                onRemove: () => context.read<ResidentProfileService>().updateProfilePhoto(
                  _account.id,
                  photoBytes: null,
                  startCooldown: false,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Basic Information',
                children: [
                  _ReadOnlyField(
                    label: 'Name',
                    value: _account.fullName,
                    note: 'Your name comes from your account. Change it in Edit Profile.',
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppSelectField<String>(
                          label: 'Sex',
                          value: _sex,
                          options: ResidentProfileOptions.sex,
                          labelBuilder: (v) => v,
                          onChanged: (v) => setState(() => _sex = v),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppDateField(
                          label: 'Birthdate',
                          value: _birthdate,
                          onChanged: (d) => setState(() => _birthdate = d),
                        ),
                      ),
                    ],
                  ),
                  // Read-only/calculated, never a second, independently-
                  // typeable value — Birthdate above is the only source of
                  // truth (see utils/age_calculator.dart). Recomputed from
                  // the real current date on every build, so it stays
                  // correct as time passes rather than freezing at whatever
                  // it was when this screen first opened.
                  _ReadOnlyAgeField(birthdate: _birthdate),
                  AppSelectField<String>(
                    label: 'Civil status',
                    value: _civilStatus,
                    options: ResidentProfileOptions.civilStatus,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _civilStatus = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Contact Information',
                children: [
                  AppTextField(
                    label: 'Mobile number',
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    inputFormatters: PhMobile.inputFormatters,
                    icon: Icons.phone_outlined,
                    hintText: PhMobile.hint,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Address',
                children: [
                  AppTextField(
                    label: 'Sitio / Purok',
                    controller: _sitioPurok,
                    icon: Icons.place_outlined,
                    required: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Resident Information',
                children: [
                  AppTextField(label: 'Occupation', controller: _occupation, icon: Icons.work_outline_rounded),
                  AppSelectField<String>(
                    label: 'Educational attainment',
                    value: _educationalAttainment,
                    options: ResidentProfileOptions.educationalAttainment,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _educationalAttainment = v),
                  ),
                  AppSelectField<String>(
                    label: 'Household monthly income',
                    value: _income,
                    options: ResidentProfileOptions.monthlyIncome,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _income = v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Classifications',
                description: 'Select any that apply to you.',
                children: [
                  _ClassificationSwitch(
                    label: 'Senior Citizen',
                    value: _senior,
                    onChanged: (v) => setState(() => _senior = v),
                  ),
                  _ClassificationSwitch(
                    label: 'Person with Disability (PWD)',
                    value: _pwd,
                    onChanged: (v) => setState(() => _pwd = v),
                  ),
                  _ClassificationSwitch(
                    label: 'Solo Parent',
                    value: _soloParent,
                    onChanged: (v) => setState(() => _soloParent = v),
                  ),
                  _ClassificationSwitch(
                    label: 'Registered Voter',
                    value: _voter,
                    onChanged: (v) => setState(() => _voter = v),
                  ),
                  _ClassificationSwitch(
                    label: '4Ps Beneficiary',
                    value: _fourPs,
                    onChanged: (v) => setState(() => _fourPs = v),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Save & Continue',
                onPressed: () => _save(markComplete: true),
                loading: _saving,
                fullWidth: true,
                size: AppButtonSize.lg,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Save for Later',
                variant: AppButtonVariant.ghost,
                onPressed: _saving ? null : () => _save(markComplete: false),
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same circular-avatar-plus-camera-icon UI as before — only what tapping
/// the camera icon does has changed (see [_PersonalInformationScreenState]
/// .onCameraTap), no redesign of this section itself. [image] is already
/// fully resolved (real saved photo, else the seeded demo portrait, else
/// null) — this widget has no picking/permission logic of its own.
/// What the LGU holds for the photo, under the picture: a new one waiting
/// for approval, one it did not approve and why, or the approved one and
/// when it can next be changed. Null when there is nothing on record.
String? _photoStatus(ProfilePhotoView? photo) {
  if (photo == null) return null;
  if (photo.isPending) return 'New photo sent. It shows here once the LGU approves it.';
  if (photo.isRejected) {
    final why = photo.latestRemarks;
    return 'Your new photo was not approved${why == null || why.isEmpty ? '.' : ': $why'}';
  }
  if (photo.approvedUrl == null) return null;
  final next = photo.nextChangeAt;
  return next == null || photo.canChange
      ? 'Approved by the LGU'
      : 'Approved by the LGU · can be changed from ${DateFormat('MMM d, y').format(next.toLocal())}';
}

class _PhotoPicker extends StatelessWidget {
  final ImageProvider? image;
  final bool hasCustomPhoto;
  final VoidCallback onCameraTap;
  final VoidCallback onRemove;
  final String? status;
  const _PhotoPicker({
    required this.image,
    required this.hasCustomPhoto,
    required this.onCameraTap,
    required this.onRemove,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.brand50,
                backgroundImage: image,
                onBackgroundImageError: image != null ? (error, stackTrace) {} : null,
                child: image == null
                    ? const Icon(Icons.person_outline_rounded, size: 34, color: AppColors.brand400)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: AppColors.brand500,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onCameraTap,
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      child: Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasCustomPhoto)
            TextButton(
              onPressed: onRemove,
              child: const Text('Remove photo', style: TextStyle(fontSize: AppTextSize.label)),
            )
          else if (status != null)
            Text(
              status!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
            )
          else
            Text('Profile photo (optional)', style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// "N years old", calculated live from Birthdate — same read-only visual
/// language as the wizard's own _DerivedAgeField
/// (service_request_wizard_screen.dart), so a resident sees the identical
/// "locked, computed" treatment for Age everywhere it appears in the app.
/// Never a text input: entering a birthdate above is the only way this
/// value ever changes.
/// A value shown, not typed here.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, required this.note});

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        const SizedBox(height: AppSpacing.sm),
        Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Text(value, style: AppTypography.bodyText.copyWith(color: AppColors.slate700)),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(note, style: AppTypography.fine.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

class _ReadOnlyAgeField extends StatelessWidget {
  final DateTime? birthdate;
  const _ReadOnlyAgeField({required this.birthdate});

  @override
  Widget build(BuildContext context) {
    final birthdate = this.birthdate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Age', style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, size: 17, color: AppColors.slate400),
              const SizedBox(width: AppSpacing.sm),
              // Expanded — at extreme narrow widths combined with a large
              // text scale, an unwrapped Text here overflowed the Row on
              // the right (this is the same fix _MasterSourcedField's own
              // value Text already has, just missing on this newer field).
              Expanded(
                child: Text(
                  birthdate == null ? 'Select your Birthdate above first' : '${calculateAge(birthdate)} years old',
                  style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.textBody, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClassificationSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ClassificationSwitch({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.slate700, fontWeight: FontWeight.w500),
              ),
            ),
            Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.brand500),
          ],
        ),
      ),
    );
  }
}

