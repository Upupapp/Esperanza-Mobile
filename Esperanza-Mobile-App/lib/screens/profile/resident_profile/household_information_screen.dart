import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/mock_catalog.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';

/// Step 3 — Household Information. Maps to Web Admin Constituents >
/// Households. "Number of People" / "Number of Families" are shown as
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
  late final TextEditingController _numberOfRooms;
  String? _barangay;
  String? _housingOwnership;
  String? _housingType;
  String? _waterSource;
  String? _toiletFacility;
  String? _electricitySource;
  bool _hasInternet = false;
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
    _numberOfRooms = TextEditingController(text: _original.numberOfRooms > 0 ? '${_original.numberOfRooms}' : '');
    _barangay = _original.barangay.isEmpty ? null : _original.barangay;
    _housingOwnership = _original.housingOwnership.isEmpty ? null : _original.housingOwnership;
    _housingType = _original.housingType.isEmpty ? null : _original.housingType;
    _waterSource = _original.waterSource.isEmpty ? null : _original.waterSource;
    _toiletFacility = _original.toiletFacility.isEmpty ? null : _original.toiletFacility;
    _electricitySource = _original.electricitySource.isEmpty ? null : _original.electricitySource;
    _hasInternet = _original.hasInternetAccess;
  }

  @override
  void dispose() {
    _sitioPurok.dispose();
    _completeAddress.dispose();
    _numberOfRooms.dispose();
    super.dispose();
  }

  String? _missingFieldError() {
    if (_barangay == null) return 'Please select your barangay.';
    if (_sitioPurok.text.trim().isEmpty) return 'Please enter your Sitio / Purok.';
    if (_completeAddress.text.trim().isEmpty) return 'Please enter your complete address.';
    if (_housingOwnership == null) return 'Please select your housing ownership.';
    if (_housingType == null) return 'Please select your housing type.';
    if (_waterSource == null) return 'Please select your water source.';
    if (_toiletFacility == null) return 'Please select your toilet / sanitation facility.';
    if (_electricitySource == null) return 'Please select your electricity source.';
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
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final updated = Household(
      householdId: _original.householdId,
      barangay: _barangay ?? '',
      sitioPurok: _sitioPurok.text.trim(),
      completeAddress: _completeAddress.text.trim(),
      housingOwnership: _housingOwnership ?? '',
      housingType: _housingType ?? '',
      numberOfRooms: int.tryParse(_numberOfRooms.text.trim()) ?? 0,
      waterSource: _waterSource ?? '',
      toiletFacility: _toiletFacility ?? '',
      electricitySource: _electricitySource ?? '',
      hasInternetAccess: _hasInternet,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Household Information')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  'A household represents the people who live together at the same residence. This is different from a family — one household can contain more than one family.',
                  style: TextStyle(fontSize: 12, color: AppColors.brand700, height: 1.4),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Location',
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
                  AppTextField(label: 'Number of rooms', controller: _numberOfRooms, keyboardType: TextInputType.number, icon: Icons.meeting_room_outlined),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Internet Access', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.slate700)),
                        ),
                        Switch(value: _hasInternet, onChanged: (v) => setState(() => _hasInternet = v), activeThumbColor: AppColors.brand500),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSection(
                title: 'Household Composition',
                description: 'Based on your Family Information — update that section to change these.',
                children: [
                  _CompositionRow(label: 'People living in household', value: '${profile.householdResidentCount}'),
                  _CompositionRow(label: 'Families living in household', value: '${profile.householdFamilyCount}'),
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

class _CompositionRow extends StatelessWidget {
  final String label;
  final String value;
  const _CompositionRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate600))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
