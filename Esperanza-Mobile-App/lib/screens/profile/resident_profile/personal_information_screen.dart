import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/citizen_account.dart';
import '../../../models/government_id_record.dart';
import '../../../models/resident_profile.dart';
import '../../../models/profile_photo.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/barangay_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/age_calculator.dart';
import '../../../utils/demo_resident_photo.dart';
import '../../../utils/government_id.dart';
import '../../../utils/ph_mobile.dart';
import '../../../utils/protected_action.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_date_field.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';
import '../government_id_viewer.dart';
import 'profile_photo_preview_screen.dart';
import '../../../theme/app_typography.dart';

/// Step 1 — Personal Information. Maps conceptually to a Web Admin
/// Constituents > Individual record for the citizen themself. Pre-filled
/// from whatever's already on the ResidentProfile (seeded from the
/// citizen's account on first visit), edited locally, and only written
/// back to ResidentProfileService on Save.
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late final CitizenAccount _account;
  late final Individual _original;
  late final TextEditingController _firstName;
  late final TextEditingController _middleName;
  late final TextEditingController _lastName;
  late final TextEditingController _suffix;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _sitioPurok;
  late final TextEditingController _completeAddress;
  late final TextEditingController _occupation;

  String? _sex;
  String? _civilStatus;
  String? _barangay;
  String? _educationalAttainment;
  DateTime? _birthdate;
  bool _senior = false;
  bool _pwd = false;
  bool _soloParent = false;
  bool _voter = false;
  bool _fourPs = false;
  List<String> _documentPaths = [];

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _account = context.read<CitizenSessionService>().account!;
    _original = context.read<ResidentProfileService>().profileFor(_account).personal;
    _firstName = TextEditingController(text: _original.firstName);
    _middleName = TextEditingController(text: _original.middleName);
    _lastName = TextEditingController(text: _original.lastName);
    _suffix = TextEditingController(text: _original.suffix);
    _mobile = TextEditingController(text: PhMobile.normalise(_original.mobile));
    _email = TextEditingController(text: _original.email);
    _sitioPurok = TextEditingController(text: _original.sitioPurok);
    _completeAddress = TextEditingController(text: _original.completeAddress);
    _occupation = TextEditingController(text: _original.occupation);
    _sex = _original.sex.isEmpty ? null : _original.sex;
    _civilStatus = _original.civilStatus.isEmpty ? null : _original.civilStatus;
    _barangay = _original.barangay.isEmpty ? null : _original.barangay;
    _educationalAttainment = _original.educationalAttainment.isEmpty ? null : _original.educationalAttainment;
    _birthdate = _original.birthdate;
    _senior = _original.isSeniorCitizen;
    _pwd = _original.isPWD;
    _soloParent = _original.isSoloParent;
    _voter = _original.isVoter;
    _fourPs = _original.isFourPsBeneficiary;
    _documentPaths = List.of(_original.documentPaths);
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _middleName,
      _lastName,
      _suffix,
      _mobile,
      _email,
      _sitioPurok,
      _completeAddress,
      _occupation,
    ]) {
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
      firstName: _firstName.text.trim(),
      middleName: _middleName.text.trim(),
      lastName: _lastName.text.trim(),
      suffix: _suffix.text.trim(),
      sex: _sex ?? '',
      birthdate: _birthdate,
      civilStatus: _civilStatus ?? '',
      mobile: _mobile.text.trim(),
      email: _email.text.trim(),
      barangay: _barangay ?? '',
      sitioPurok: _sitioPurok.text.trim(),
      completeAddress: _completeAddress.text.trim(),
      occupation: _occupation.text.trim(),
      educationalAttainment: _educationalAttainment ?? '',
      isSeniorCitizen: _senior,
      isPWD: _pwd,
      isSoloParent: _soloParent,
      isVoter: _voter,
      isFourPsBeneficiary: _fourPs,
      photoPath: currentPhoto.photoPath,
      photoBytesBase64: currentPhoto.photoBytesBase64,
      documentPaths: _documentPaths,
      hasEsperanzaAccount: true,
      linkedCitizenAccountId: _original.individualId,
      familyId: _original.familyId,
      householdId: _original.householdId,
    );
  }

  String? _missingFieldError() {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      return 'Please enter your first and last name.';
    }
    if (_sex == null) return 'Please select your sex.';
    if (_birthdate == null) return 'Please select your birthdate.';
    if (_civilStatus == null) return 'Please select your civil status.';
    final mobileError = PhMobile.validate(_mobile.text, required: true, emptyMessage: 'Please enter your mobile number.');
    if (mobileError != null) return mobileError;
    if (_barangay == null) return 'Please select your barangay.';
    if (_sitioPurok.text.trim().isEmpty) return 'Please enter your Sitio / Purok.';
    if (_completeAddress.text.trim().isEmpty) return 'Please enter your complete address.';
    if (_occupation.text.trim().isEmpty) return 'Please enter your occupation.';
    return null;
  }

  Future<void> _save({required bool markComplete}) async {
    // A draft may leave the number blank, but never save one that is wrong.
    final mobileError = PhMobile.validate(_mobile.text);
    if (!markComplete && mobileError != null) {
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
    await context.read<ResidentProfileService>().savePersonal(accountId, _buildUpdated(), markComplete: markComplete);
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

  Future<void> _pickDocument() async {
    // withData: true is required for this to work at all on Flutter Web —
    // web never provides PlatformFile.path, only .bytes.
    final result = await pickDocumentProtected(
      context,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.single;
    if (f.bytes == null) return;
    // documentPaths only needs a display identifier here (_DocumentTile
    // just shows a filename, never opens the file) — path on native,
    // name as a stand-in on web where there is no real path.
    setState(() => _documentPaths = [..._documentPaths, f.path ?? f.name]);
  }

  @override
  Widget build(BuildContext context) {
    final governmentId = governmentIdFor(_account);
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
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(label: 'First name', controller: _firstName),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(label: 'Middle name', controller: _middleName),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: AppTextField(label: 'Last name', controller: _lastName),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(label: 'Suffix', controller: _suffix, hintText: 'Jr., Sr., III'),
                      ),
                    ],
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
                    required: true,
                  ),
                  AppTextField(
                    label: 'Email address',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    icon: Icons.mail_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Address',
                children: [
                  AppSelectField<String>(
                    label: 'Barangay',
                    value: _barangay,
                    options: BarangayService.names,
                    labelBuilder: (v) => v,
                    onChanged: (v) => setState(() => _barangay = v),
                  ),
                  AppTextField(label: 'Sitio / Purok', controller: _sitioPurok, icon: Icons.place_outlined),
                  AppTextField(label: 'Complete address', controller: _completeAddress, maxLines: 2),
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
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Supporting Documents',
                description: 'Optional — a valid ID or proof of residency helps LGU verification.',
                children: [
                  for (final path in _documentPaths)
                    _DocumentTile(
                      path: path,
                      onRemove: () => setState(() => _documentPaths = _documentPaths.where((d) => d != path).toList()),
                    ),
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: const Text('Attach ID / Document'),
                  ),
                ],
              ),
              // Very end of the page, after every editable field — this is
              // the physical ID document submitted at registration/
              // verification time, a different concept from the Esperanza
              // Digital ID (see screens/profile/digital_id_screen.dart's own
              // doc comment). It stays visible here regardless of
              // verification status, since it shows what was submitted, not
              // something the LGU has issued.
              if (governmentId != null) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Submitted Government ID',
                  style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'The identification you submitted during registration. This stays on file regardless of your '
                  'verification status.',
                  style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                _SubmittedGovernmentIdCard(record: governmentId),
              ],
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

class _DocumentTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  const _DocumentTile({required this.path, required this.onRemove});

  String get _fileName {
    final normalized = path.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    return idx == -1 ? normalized : normalized.substring(idx + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.slate500),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.slate400),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// The physical government ID document this resident submitted at
/// registration/verification time — the same single seeded
/// [GovernmentIdRecord] read by [governmentIdFor], reused here (not
/// duplicated) and opened in the same [GovernmentIdViewer] used elsewhere.
/// This is deliberately not "verified"/"unverified" itself — that status
/// belongs to the account as a whole, not to the document — so this only
/// ever indicates the document is on file.
class _SubmittedGovernmentIdCard extends StatelessWidget {
  final GovernmentIdRecord record;
  const _SubmittedGovernmentIdCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => GovernmentIdViewer.open(context, record),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              // This card preview is card-width, not full document
              // resolution — the seeded ID assets are ~2MB photos, so
              // decode at the card's own width instead of native size.
              // GovernmentIdViewer (opened on tap) shows the real,
              // full-resolution, zoomable document.
              child: Image.asset(
                record.assetPath,
                fit: BoxFit.cover,
                cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            // A Column, not a Row-of-two-columns: at extreme narrow widths
            // combined with a large text scale, a fixed-width trailing
            // "View ID ›" group next to an Expanded info column overflowed
            // (large text scale alone can push "View ID" past what's left
            // once the ID type + "On File" chip claim their own space) —
            // stacking instead means every line only ever competes for the
            // card's full width, never a shrunken remainder.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      record.idType,
                      style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(AppRadius.full)),
                      child: const Text(
                        'On File',
                        style: TextStyle(fontSize: AppTextSize.fine, fontWeight: FontWeight.w700, color: AppColors.emerald700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Issued by ${record.issuingOffice}',
                  style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    Text(
                      'View ID',
                      style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w600, color: AppColors.brand600),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.brand600),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
