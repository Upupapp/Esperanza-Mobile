import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/resident_profile.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/mock_catalog.dart';
import '../../../services/resident_profile_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/form_section.dart';
import 'family_member_form_sheet.dart';

/// Step 2 — Family Information. Citizen-facing framing of the Web Admin's
/// Constituents > Families module: members are added/edited/removed
/// immediately (each is its own local action), while the family name and
/// head-of-family selection are committed via Save & Continue / Save for
/// Later, same two-button pattern as Personal Information.
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
    if (markComplete && _familyName.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a family name.');
      return;
    }
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
      confirmLabel: 'Remove',
      danger: true,
    );
    if (ok && mounted) await _service.removeFamilyMember(_accountId, member.individualId);
  }

  Future<void> _changeHead(ResidentProfile profile) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _HeadPickerSheet(individuals: profile.allFamilyIndividuals, currentHeadId: profile.headIndividualId),
    );
    if (selected != null && mounted) await _service.setHeadOfFamily(_accountId, selected);
  }

  Future<void> _joinFamily(ExistingFamilyMatch match) async {
    await _service.requestJoinFamily(_accountId, match);
    if (mounted) AppDialogs.toast(context, 'Request to join ${match.familyName} sent (demo).');
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account!;
    final profile = context.watch<ResidentProfileService>().profileFor(account);
    final match = MockCatalog.existingFamilyMatches[profile.personal.barangay];
    final showMatch =
        match != null && profile.familyMembers.isEmpty && !profile.familySaved && !profile.joinRequestSent;

    return Scaffold(
      appBar: AppBar(title: const Text('Family Information')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const Text(
              'Tell us about your family members living with you.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            if (showMatch) ...[
              const SizedBox(height: AppSpacing.lg),
              _ExistingMatchBanner(match: match, onJoin: () => _joinFamily(match)),
            ],
            const SizedBox(height: AppSpacing.lg),
            FormSection(
              title: 'Family Details',
              children: [
                AppTextField(label: 'Family name', controller: _familyName, icon: Icons.diversity_3_outlined),
                _InfoRow(
                  label: 'Head of Family',
                  value: profile.headIndividual.fullName.isEmpty ? account.fullName : profile.headIndividual.fullName,
                  actionLabel: profile.allFamilyIndividuals.length > 1 ? 'Change' : null,
                  onAction: () => _changeHead(profile),
                ),
                _InfoRow(label: 'Members', value: '${profile.allFamilyIndividuals.length}'),
                _InfoRow(label: 'Family ID', value: profile.familyId, muted: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Family Members',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate600),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (profile.familyMembers.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(14)),
                child: const Text(
                  'No family members added yet. Add anyone living with you — even if they don\'t have an Esperanza account.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
                ),
              )
            else
              for (final member in profile.familyMembers)
                _MemberTile(member: member, onEdit: () => _editMember(member), onRemove: () => _removeMember(member)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
              label: const Text('Add Family Member'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool muted;
  const _InfoRow({required this.label, required this.value, this.actionLabel, this.onAction, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: muted ? AppColors.slate400 : AppColors.slate700,
              ),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brand600),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: onEdit,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.slate100,
              child: Text(
                member.firstName.isNotEmpty ? member.firstName.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitleParts.join(' · '), style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
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

class _ExistingMatchBanner extends StatelessWidget {
  final ExistingFamilyMatch match;
  final VoidCallback onJoin;
  const _ExistingMatchBanner({required this.match, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 17, color: AppColors.brand600),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'We found a possible existing family record.',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            match.familyName,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          Text('Brgy. ${match.barangay}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: 'Request to Join Family', size: AppButtonSize.sm, onPressed: onJoin),
        ],
      ),
    );
  }
}

class _HeadPickerSheet extends StatelessWidget {
  final List<Individual> individuals;
  final String currentHeadId;
  const _HeadPickerSheet({required this.individuals, required this.currentHeadId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Head of Family',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 6),
            for (final i in individuals)
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.slate100,
                  child: Text(
                    i.firstName.isNotEmpty ? i.firstName.substring(0, 1).toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate600),
                  ),
                ),
                title: Text(i.fullName, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                trailing: i.individualId == currentHeadId
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.brand600, size: 20)
                    : null,
                onTap: () => Navigator.of(context).pop(i.individualId),
              ),
          ],
        ),
      ),
    );
  }
}
