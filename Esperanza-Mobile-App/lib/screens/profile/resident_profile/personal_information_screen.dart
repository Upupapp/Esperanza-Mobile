import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/mock_catalog.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_date_field.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';

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
  String? _photoPath;
  List<String> _documentPaths = [];

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account!;
    _original = context.read<ResidentProfileService>().profileFor(account).personal;
    _firstName = TextEditingController(text: _original.firstName);
    _middleName = TextEditingController(text: _original.middleName);
    _lastName = TextEditingController(text: _original.lastName);
    _suffix = TextEditingController(text: _original.suffix);
    _mobile = TextEditingController(text: _original.mobile);
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
    _photoPath = _original.photoPath;
    _documentPaths = List.of(_original.documentPaths);
  }

  @override
  void dispose() {
    for (final c in [_firstName, _middleName, _lastName, _suffix, _mobile, _email, _sitioPurok, _completeAddress, _occupation]) {
      c.dispose();
    }
    super.dispose();
  }

  Individual _buildUpdated() => Individual(
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
        photoPath: _photoPath,
        documentPaths: _documentPaths,
        hasEsperanzaAccount: true,
        linkedCitizenAccountId: _original.individualId,
        familyId: _original.familyId,
        householdId: _original.householdId,
      );

  String? _missingFieldError() {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) return 'Please enter your first and last name.';
    if (_sex == null) return 'Please select your sex.';
    if (_birthdate == null) return 'Please select your birthdate.';
    if (_civilStatus == null) return 'Please select your civil status.';
    if (_mobile.text.trim().isEmpty) return 'Please enter your mobile number.';
    if (_barangay == null) return 'Please select your barangay.';
    if (_sitioPurok.text.trim().isEmpty) return 'Please enter your Sitio / Purok.';
    if (_completeAddress.text.trim().isEmpty) return 'Please enter your complete address.';
    if (_occupation.text.trim().isEmpty) return 'Please enter your occupation.';
    return null;
  }

  Future<void> _save({required bool markComplete}) async {
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

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _photoPath = file.path);
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png']);
    if (result == null || result.files.isEmpty || !mounted) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() => _documentPaths = [..._documentPaths, path]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoPicker(photoPath: _photoPath, onPick: _pickPhoto, onRemove: () => setState(() => _photoPath = null)),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Basic Information',
                children: [
                  Row(
                    children: [
                      Expanded(child: AppTextField(label: 'First name', controller: _firstName)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(label: 'Middle name', controller: _middleName)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(flex: 2, child: AppTextField(label: 'Last name', controller: _lastName)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: AppTextField(label: 'Suffix', controller: _suffix, hintText: 'Jr., Sr., III')),
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
                  AppTextField(label: 'Mobile number', controller: _mobile, keyboardType: TextInputType.phone, icon: Icons.phone_outlined, hintText: '09XX XXX XXXX'),
                  AppTextField(label: 'Email address', controller: _email, keyboardType: TextInputType.emailAddress, icon: Icons.mail_outline_rounded),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Address',
                children: [
                  AppSelectField<String>(
                    label: 'Barangay',
                    value: _barangay,
                    options: MockCatalog.barangays,
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
                  _ClassificationSwitch(label: 'Senior Citizen', value: _senior, onChanged: (v) => setState(() => _senior = v)),
                  _ClassificationSwitch(label: 'Person with Disability (PWD)', value: _pwd, onChanged: (v) => setState(() => _pwd = v)),
                  _ClassificationSwitch(label: 'Solo Parent', value: _soloParent, onChanged: (v) => setState(() => _soloParent = v)),
                  _ClassificationSwitch(label: 'Registered Voter', value: _voter, onChanged: (v) => setState(() => _voter = v)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Supporting Documents',
                description: 'Optional — a valid ID or proof of residency helps LGU verification.',
                children: [
                  for (final path in _documentPaths)
                    _DocumentTile(path: path, onRemove: () => setState(() => _documentPaths = _documentPaths.where((d) => d != path).toList())),
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    label: const Text('Attach ID / Document'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              AppButton(label: 'Save & Continue', onPressed: () => _save(markComplete: true), loading: _saving, fullWidth: true, size: AppButtonSize.lg),
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

class _PhotoPicker extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _PhotoPicker({required this.photoPath, required this.onPick, required this.onRemove});

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
                backgroundImage: photoPath != null ? FileImage(File(photoPath!)) : null,
                child: photoPath == null ? const Icon(Icons.person_outline_rounded, size: 34, color: AppColors.brand400) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: AppColors.brand500,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onPick,
                    child: const Padding(padding: EdgeInsets.all(7), child: Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (photoPath != null)
            TextButton(onPressed: onRemove, child: const Text('Remove photo', style: TextStyle(fontSize: 12)))
          else
            Text('Profile photo (optional)', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.slate700, fontWeight: FontWeight.w500))),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.slate500),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.slate700)),
          ),
          IconButton(
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
