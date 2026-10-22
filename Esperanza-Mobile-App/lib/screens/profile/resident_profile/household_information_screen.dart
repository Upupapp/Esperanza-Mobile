import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';
import '../../../widgets/resident_profile_lock_note.dart';
import '../../../theme/app_typography.dart';

import '../../../l10n/tr.dart';
/// Step 3 — Household Information, as the website's Household tab: only
/// what the barangay keeps (PUT /citizen/resident-profile `household`). "Number of People" / "Number of Families" are shown as
/// read-only summaries derived from Family Information rather than
/// re-typed here — asking the citizen to manually keep a count in sync
/// with the family members they already entered would just invite drift.
class HouseholdInformationScreen extends StatefulWidget {
  const HouseholdInformationScreen({super.key});

  @override
  State<HouseholdInformationScreen> createState() => _HouseholdInformationScreenState();
}

class _HouseholdInformationScreenState extends State<HouseholdInformationScreen> {
  late final Household _original;
  late final String _accountId;
  late final TextEditingController _sitioPurok;
  late final TextEditingController _completeAddress;
  String? _housingOwnership;
  String? _housingType;
  String? _waterSource;
  String? _toiletFacility;
  String? _electricitySource;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account!;
    _accountId = account.id;
    _original = context.read<ResidentProfileService>().profileFor(account).household;
    _sitioPurok = TextEditingController(text: _original.sitioPurok);
    _completeAddress = TextEditingController(text: _original.completeAddress);
    _housingOwnership = _original.housingOwnership.isEmpty ? null : _original.housingOwnership;
    _housingType = _original.housingType.isEmpty ? null : _original.housingType;
    _waterSource = _original.waterSource.isEmpty ? null : _original.waterSource;
    _toiletFacility = _original.toiletFacility.isEmpty ? null : _original.toiletFacility;
    _electricitySource = _original.electricitySource.isEmpty ? null : _original.electricitySource;
  }

  @override
  void dispose() {
    _sitioPurok.dispose();
    _completeAddress.dispose();
    super.dispose();
  }

  Future<void> _save({required bool markComplete}) async {
    // Every household answer is optional, as on the website.
    setState(() {
      _saving = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final updated = Household(
      householdId: _original.householdId,
      barangay: _original.barangay,
      sitioPurok: _sitioPurok.text.trim(),
      completeAddress: _completeAddress.text.trim(),
      housingOwnership: _housingOwnership ?? '',
      housingType: _housingType ?? '',
      numberOfRooms: _original.numberOfRooms,
      waterSource: _waterSource ?? '',
      toiletFacility: _toiletFacility ?? '',
      electricitySource: _electricitySource ?? '',
      hasInternetAccess: _original.hasInternetAccess,
      familyIds: _original.familyIds,
      otherFamilies: _original.otherFamilies,
    );
    await context.read<ResidentProfileService>().saveHousehold(_accountId, updated, markComplete: markComplete);
    if (!mounted) return;
    setState(() => _saving = false);
    AppDialogs.toast(context, markComplete ? 'Household information saved.' : 'Saved for later.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ResidentProfileService>().profileFor(context.watch<CitizenSessionService>().account!);
    final locked = !profile.editable;

    return Scaffold(
      appBar: AppBar(title: const Text('Household Information')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Text(
                  'A household represents the people who live together at the same residence. This is different from a family — one household can contain more than one family.',
                  style: TextStyle(fontSize: AppTextSize.label, color: AppColors.brand700, height: 1.4),
                ),
              ),
              if (locked) ...[
                const SizedBox(height: AppSpacing.md),
                ResidentProfileLockNote(status: profile.status),
              ],
              // View only, greyed out, while the barangay has it (as on the website).
              ResidentProfileViewOnly(
                locked: locked,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const SizedBox(height: AppSpacing.lg),
                  FormSection(
                    title: 'Location',
                    children: [
                      AppTextField(label: tr('Sitio / Purok of the house'), controller: _sitioPurok, icon: Icons.place_outlined),
                      AppTextField(label: tr('Complete address'), controller: _completeAddress, maxLines: 2),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FormSection(
                    title: 'Residence',
                    children: [
                      AppSelectField<String>(
                        label: 'Housing ownership',
                        value: _housingOwnership,
                        options: ResidentProfileOptions.housingOwnership,
                        labelBuilder: (v) => v,
                        onChanged: (v) => setState(() => _housingOwnership = v),
                      ),
                      AppSelectField<String>(
                        label: 'Housing type / material',
                        value: _housingType,
                        options: ResidentProfileOptions.housingType,
                        labelBuilder: (v) => v,
                        onChanged: (v) => setState(() => _housingType = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FormSection(
                    title: 'Utilities / Services',
                    children: [
                      AppSelectField<String>(
                        label: 'Water source',
                        value: _waterSource,
                        options: ResidentProfileOptions.waterSource,
                        labelBuilder: (v) => v,
                        onChanged: (v) => setState(() => _waterSource = v),
                      ),
                      AppSelectField<String>(
                        label: 'Toilet / sanitation',
                        value: _toiletFacility,
                        options: ResidentProfileOptions.toiletFacility,
                        labelBuilder: (v) => v,
                        onChanged: (v) => setState(() => _toiletFacility = v),
                      ),
                      AppSelectField<String>(
                        label: 'Electricity',
                        value: _electricitySource,
                        options: ResidentProfileOptions.electricitySource,
                        labelBuilder: (v) => v,
                        onChanged: (v) => setState(() => _electricitySource = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FormSection(
                    title: 'Household Composition',
                    description: 'Based on your Family Information — update that section to change these.',
                    children: [
                      _CompositionRow(label: 'People living in household', value: '${profile.householdResidentCount}'),
                    ],
                  ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600)),
              ],
              if (!locked) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

class _CompositionRow extends StatelessWidget {
  final String label;
  final String value;
  const _CompositionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate600)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

