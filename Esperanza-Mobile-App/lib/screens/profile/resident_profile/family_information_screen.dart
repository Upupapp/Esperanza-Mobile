import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';
import '../../../widgets/resident_profile_lock_note.dart';
import 'family_member_form_sheet.dart';
import '../../../theme/app_typography.dart';

import '../../../l10n/tr.dart';
/// Step 2 — Family Information, as the website's Family tab: the family
/// surname and the people in the family (not the resident), each with what
/// the barangay keeps (GET/PUT /citizen/resident-profile `family`). Members
/// are added, edited and removed at once; the surname is committed with
/// Save & Continue / Save for Later.
class FamilyInformationScreen extends StatefulWidget {
  const FamilyInformationScreen({super.key});

  @override
  State<FamilyInformationScreen> createState() => _FamilyInformationScreenState();
}

class _FamilyInformationScreenState extends State<FamilyInformationScreen> {
  late final String _accountId;
  late final TextEditingController _familyName;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account!;
    _accountId = account.id;
    final profile = context.read<ResidentProfileService>().profileFor(account);
    _familyName = TextEditingController(text: profile.familyName);
  }

  @override
  void dispose() {
    _familyName.dispose();
    super.dispose();
  }

  ResidentProfileService get _service => context.read<ResidentProfileService>();

  Future<void> _save({required bool markComplete}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final profile = _service.profileFor(context.read<CitizenSessionService>().account!);
    await _service.saveFamily(
      _accountId,
      familyName: _familyName.text.trim(),
      headIndividualId: profile.headIndividualId,
      markComplete: markComplete,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    AppDialogs.toast(context, markComplete ? 'Family information saved.' : 'Saved for later.');
    Navigator.of(context).pop();
  }

  Future<void> _addMember() async {
    final result = await showModalBottomSheet<Individual>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FamilyMemberFormSheet(),
    );
    if (result != null && mounted) await _service.addFamilyMember(_accountId, result);
  }

  Future<void> _editMember(Individual member) async {
    final result = await showModalBottomSheet<Individual>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyMemberFormSheet(existing: member),
    );
    if (result != null && mounted) await _service.updateFamilyMember(_accountId, result);
  }

  Future<void> _removeMember(Individual member) async {
    final ok = await AppDialogs.confirm(
      context,
      title: 'Remove ${member.fullName}?',
      message: 'They will be removed from your Family Information.',
      confirmLabel: tr('Remove'),
      danger: true,
    );
    if (ok && mounted) await _service.removeFamilyMember(_accountId, member.individualId);
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account!;
    final profile = context.watch<ResidentProfileService>().profileFor(account);
    final locked = !profile.editable;

    return Scaffold(
      appBar: AppBar(title: const Text('Family Information')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            Text(
              tr('Add the people in your family (not yourself).'),
              style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
            ),
            if (locked) ...[
              const SizedBox(height: AppSpacing.md),
              ResidentProfileLockNote(status: profile.status),
            ],
            const SizedBox(height: AppSpacing.lg),
            // View only, greyed out, while the barangay has it (as on the website).
            ResidentProfileViewOnly(
              locked: locked,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                FormSection(
                  title: 'Family Details',
                  children: [
                    AppTextField(label: 'Family name', controller: _familyName, icon: Icons.diversity_3_outlined),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoRow(label: 'Members', value: '${profile.allFamilyIndividuals.length}'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  tr('Family Members'),
                  style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.slate600),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (profile.familyMembers.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: const Text(
                      'No family members added yet. Add anyone living with you — even if they don\'t have an Esperanza account.',
                      style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
                    ),
                  )
                else
                  for (final member in profile.familyMembers)
                    _MemberTile(member: member, onEdit: () => _editMember(member), onRemove: () => _removeMember(member)),
                OutlinedButton.icon(
                  onPressed: _addMember,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                  label: const Text('Add Family Member'),
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: AppColors.slate700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Individual member;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  const _MemberTile({required this.member, required this.onEdit, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (member.relationshipToHead.isNotEmpty) member.relationshipToHead,
      if (member.birthdate != null) 'Age ${member.age}',
      member.hasEsperanzaAccount ? 'Has Esperanza account' : 'No Esperanza account',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onEdit,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.slate100,
              child: Text(
                member.firstName.isNotEmpty ? member.firstName.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.slate600),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitleParts.join(' · '), style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove family member',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.rose500),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

