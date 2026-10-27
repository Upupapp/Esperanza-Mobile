import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/tr.dart';
import '../../services/api_client.dart';
import '../../services/barangay_service.dart';
import '../../services/citizen_session_service.dart';
import '../../services/shelter_records_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/date_text.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/async_state_view.dart';

/// The resident's own shelter stays and relief (owner, 2026-10-27, Phase 3),
/// as on the website's Emergency page ("My Shelter and Relief"). A released
/// item is confirmed here, beside the paper signature, never instead of it;
/// a mistake is sent as a support ticket; and, while the LGU has it on, a
/// household list is kept ready for check-in, with consent.
typedef _Data = ({ShelterRecords records, HouseholdState household});

class MyShelterScreen extends StatefulWidget {
  const MyShelterScreen({super.key});

  @override
  State<MyShelterScreen> createState() => _MyShelterScreenState();
}

class _MyShelterScreenState extends State<MyShelterScreen> {
  int _generation = 0;
  String? _answering;

  Future<_Data> _load() async {
    final results = await Future.wait<Object>([ShelterRecordsService.load(), ShelterRecordsService.loadHousehold()]);
    return (records: results[0] as ShelterRecords, household: results[1] as HouseholdState);
  }

  void _say(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? AppColors.rose600 : null),
    );
  }

  Future<void> _answer(ReliefItem r, bool received, VoidCallback reload) async {
    if (_answering != null) return;
    String? note;
    if (!received) {
      note = await _askText(
        context,
        title: tr('Not received'),
        hint: tr('Tell the office what happened (optional). They will check the release.'),
        required: false,
      );
      if (note == null) return;
    }
    setState(() => _answering = r.ref);
    try {
      await ShelterRecordsService.acknowledge(r.ref, received: received, note: note);
      if (!mounted) return;
      _say(received ? tr('Thank you. Recorded as received.') : tr('Recorded as not received. The office has been told.'));
      reload();
    } on ApiException catch (e) {
      if (mounted) _say(e.message(), error: true);
    } catch (_) {
      if (mounted) _say(tr('Could not record your answer.'), error: true);
    } finally {
      if (mounted) setState(() => _answering = null);
    }
  }

  Future<void> _report(String ref) async {
    final message = await _askText(
      context,
      title: '${tr('Report a mistake')} · $ref',
      hint: tr('This is sent as a support ticket; the office replies there.'),
      required: true,
    );
    if (message == null || message.trim().length < 5) return;
    try {
      final ticket = await ShelterRecordsService.reportMistake(ref, message);
      if (mounted) _say('${tr('Sent as support ticket')} ${ticket ?? ''}');
    } on ApiException catch (e) {
      if (mounted) _say(e.message(), error: true);
    } catch (_) {
      if (mounted) _say(tr('Could not send your report.'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('My Shelter and Relief'))),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _generation++),
        child: AsyncStateView<_Data>(
          key: ValueKey('shelter-$_generation'),
          loader: _load,
          builder: (context, data, reload) {
            final r = data.records;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenGutter,
                AppSpacing.md,
                AppSpacing.screenGutter,
                AppSpacing.scrollEnd + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                Text(
                  tr("Your family's stays at evacuation centres and the relief released to you. Staff still record check-ins and relief."),
                  style: AppTypography.helper,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                if (r.enabled && !r.linked)
                  _Note(tr('Your records appear here once your account is linked to the resident registry (after the Municipality verifies it).'))
                else if (r.enabled && r.stays.isEmpty && r.relief.isEmpty)
                  _Note(tr('No stay or relief is on record for your family yet.')),
                if (r.stays.isNotEmpty) ...[
                  Text(tr('Stays'), style: AppTypography.subsectionLabel),
                  const SizedBox(height: AppSpacing.headingGap),
                  for (final s in r.stays)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                      child: _StayCard(stay: s, onReport: () => _report(s.ref)),
                    ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (r.relief.isNotEmpty) ...[
                  Text(tr('Relief Released'), style: AppTypography.subsectionLabel),
                  const SizedBox(height: AppSpacing.headingGap),
                  for (final item in r.relief)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
                      child: _ReliefCard(
                        item: item,
                        busy: _answering == item.ref,
                        onAnswer: (received) => _answer(item, received, reload),
                        onReport: () => _report(item.ref),
                      ),
                    ),
                  Text(
                    tr('Your answer here sits beside the signature on the paper relief sheet; it does not replace the signature.'),
                    style: AppTypography.fine,
                  ),
                ],
                if (data.household.enabled) ...[
                  const SizedBox(height: AppSpacing.sectionGap),
                  _HouseholdSection(household: data.household.household, onChanged: reload),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A short text, asked for in a sheet; null when cancelled.
Future<String?> _askText(BuildContext context, {required String title, required String hint, required bool required}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TextSheet(title: title, hint: hint, required: required),
  );
}

/// The sheet owns its text field's controller and disposes it with itself:
/// disposed when the sheet's future completed, it was still listened to while
/// the sheet animated closed (a red error screen on the demo, 2026-10-27).
class _TextSheet extends StatefulWidget {
  const _TextSheet({required this.title, required this.hint, required this.required});
  final String title;
  final String hint;
  final bool required;

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sheetPadding,
        AppSpacing.sheetPadding,
        AppSpacing.sheetPadding,
        AppSpacing.sheetPadding + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(widget.hint, style: AppTypography.helper),
          const SizedBox(height: AppSpacing.md),
          AppTextField(controller: _controller, maxLines: 4, maxLength: widget.required ? 2000 : 500),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(label: tr('Cancel'), variant: AppButtonVariant.secondary, onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(width: AppSpacing.inlineGap),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (_, value, _) => AppButton(
                    label: tr('Send'),
                    onPressed: widget.required && value.text.trim().length < 5 ? null : () => Navigator.pop(context, value.text),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.md),
    child: Text(text, style: AppTypography.helper),
  );
}

class _StayCard extends StatelessWidget {
  const _StayCard({required this.stay, required this.onReport});
  final ShelterStay stay;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final when = [
      if (stay.checkedIn != null) '${tr('Checked in')} ${shortDate(stay.checkedIn!)}',
      if (stay.checkedOut != null) '${tr('Left the centre')} ${shortDate(stay.checkedOut!)}',
    ].join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(stay.center ?? tr('Evacuation centre'), style: AppTypography.cardTitle)),
              const SizedBox(width: AppSpacing.inlineGap),
              Text(
                stay.staying ? tr('Staying now') : tr('Left the centre'),
                style: AppTypography.labelText.copyWith(color: stay.staying ? AppColors.emerald700 : AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('${stay.ref}${when.isEmpty ? '' : ' · $when'}', style: AppTypography.fine),
          if (stay.members.isNotEmpty) Text(stay.members.join(', '), style: AppTypography.helper),
          TextButton(onPressed: onReport, child: Text(tr('Report a mistake'))),
        ],
      ),
    );
  }
}

class _ReliefCard extends StatelessWidget {
  const _ReliefCard({required this.item, required this.busy, required this.onAnswer, required this.onReport});
  final ReliefItem item;
  final bool busy;
  final ValueChanged<bool> onAnswer;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final meta = [?item.operation, if (item.releasedAt != null) shortDate(item.releasedAt!), ?item.where].join(' · ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.line, style: AppTypography.cardTitle),
          if (meta.isNotEmpty) Text(meta, style: AppTypography.fine),
          if (item.canAcknowledge) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(tr('Did your family receive this?'), style: AppTypography.bodyText),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: AppButton(label: tr('Received'), loading: busy, onPressed: busy ? null : () => onAnswer(true))),
                const SizedBox(width: AppSpacing.inlineGap),
                Expanded(
                  child: AppButton(
                    label: tr('Not received'),
                    variant: AppButtonVariant.secondary,
                    onPressed: busy ? null : () => onAnswer(false),
                  ),
                ),
              ],
            ),
          ],
          if (item.acknowledgement != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                item.acknowledgement == 'received' ? tr('You confirmed this was received') : tr('You said this was not received'),
                if (item.acknowledgedAt != null) shortDate(item.acknowledgedAt!),
              ].join(' · '),
              style: AppTypography.labelText.copyWith(
                color: item.acknowledgement == 'received' ? AppColors.emerald700 : AppColors.amber700,
              ),
            ),
          ],
          TextButton(onPressed: onReport, child: Text(tr('Report a mistake'))),
        ],
      ),
    );
  }
}

/// The household list, kept ready for check-in, while the LGU has it on.
class _HouseholdSection extends StatelessWidget {
  const _HouseholdSection({required this.household, required this.onChanged});
  final HouseholdList? household;
  final VoidCallback onChanged;

  Future<void> _edit(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => HouseholdListScreen(existing: household)),
    );
    if (saved == true) onChanged();
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await AppDialogs.confirm(
      context,
      title: tr('Delete'),
      message: tr('Delete your household list? Staff will fill the check-in form by hand.'),
      confirmLabel: tr('Delete'),
      danger: true,
    );
    if (!ok) return;
    try {
      await ShelterRecordsService.withdrawHousehold();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Your household list is deleted.'))));
      }
      onChanged();
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = household;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Household List for Evacuation'), style: AppTypography.subsectionLabel),
        const SizedBox(height: AppSpacing.sm),
        Text(
          tr('Keep a list of the people in your home ready. If you evacuate, staff can fill the check-in from it; they still record your arrival.'),
          style: AppTypography.helper,
        ),
        const SizedBox(height: AppSpacing.md),
        if (h == null)
          AppButton(label: tr('Prepare my household list'), fullWidth: true, onPressed: () => _edit(context))
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${h.members.length} ${tr('people')} · Brgy. ${h.barangay}${h.purok == null ? '' : ', ${h.purok}'}',
                  style: AppTypography.cardTitle,
                ),
                Text(h.members.map((m) => m.name).join(', '), style: AppTypography.helper),
                if (h.updatedAt != null) Text('${tr('Updated')} ${shortDate(h.updatedAt!)}', style: AppTypography.fine),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: AppButton(label: tr('Edit'), variant: AppButtonVariant.secondary, onPressed: () => _edit(context))),
                    const SizedBox(width: AppSpacing.inlineGap),
                    Expanded(child: AppButton(label: tr('Delete'), variant: AppButtonVariant.ghost, onPressed: () => _delete(context))),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Preparing or changing the household list. Saved only with consent.
class HouseholdListScreen extends StatefulWidget {
  const HouseholdListScreen({super.key, this.existing});
  final HouseholdList? existing;

  @override
  State<HouseholdListScreen> createState() => _HouseholdListScreenState();
}

class _HouseholdListScreenState extends State<HouseholdListScreen> {
  late String? _barangay = widget.existing?.barangay ?? context.read<CitizenSessionService>().account?.barangay;
  late final _sitio = TextEditingController(text: widget.existing?.sitio ?? '');
  late final _purok = TextEditingController(text: widget.existing?.purok ?? '');
  late final List<HouseholdPerson> _people = [
    for (final m in widget.existing?.members ?? const <HouseholdPerson>[])
      HouseholdPerson(name: m.name, relation: m.relation, sex: m.sex, dob: m.dob, vulnerability: m.vulnerability),
  ];
  bool _consent = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_people.isEmpty) _people.add(HouseholdPerson());
  }

  @override
  void dispose() {
    _sitio.dispose();
    _purok.dispose();
    super.dispose();
  }

  bool get _ready => _consent && (_barangay ?? '').isNotEmpty && _people.any((p) => p.name.trim().isNotEmpty);

  Future<void> _save() async {
    if (!_ready || _saving) return;
    setState(() => _saving = true);
    try {
      await ShelterRecordsService.saveHousehold(
        consent: _consent,
        barangay: _barangay!,
        sitio: _sitio.text,
        purok: _purok.text,
        members: _people,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('Your household list is saved.'))));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.explain())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final barangays = BarangayService.names;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Household List for Evacuation'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.md,
          AppSpacing.screenGutter,
          AppSpacing.scrollEnd + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          DropdownButtonFormField<String>(
            initialValue: barangays.contains(_barangay) ? _barangay : null,
            decoration: const InputDecoration(labelText: 'Barangay'),
            items: [for (final b in barangays) DropdownMenuItem(value: b, child: Text(b))],
            onChanged: (v) => setState(() => _barangay = v),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          AppTextField(label: 'Sitio', controller: _sitio, maxLength: 120),
          AppTextField(label: 'Purok', controller: _purok, maxLength: 80),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < _people.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
              child: _PersonCard(
                key: ObjectKey(_people[i]),
                index: i,
                person: _people[i],
                onChanged: () => setState(() {}),
                onRemove: _people.length == 1 ? null : () => setState(() => _people.removeAt(i)),
              ),
            ),
          if (_people.length < 30)
            TextButton(
              onPressed: () => setState(() => _people.add(HouseholdPerson())),
              child: Text(tr('+ Add a person')),
            ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr("I agree that the Municipality keeps this list, including children's details, only for check-in at an evacuation centre. I can delete it at any time."),
              style: AppTypography.helper,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(label: tr('Save list'), fullWidth: true, loading: _saving, onPressed: _ready ? _save : null),
        ],
      ),
    );
  }
}

class _PersonCard extends StatefulWidget {
  const _PersonCard({super.key, required this.index, required this.person, required this.onChanged, this.onRemove});
  final int index;
  final HouseholdPerson person;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  State<_PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<_PersonCard> {
  late final _name = TextEditingController(text: widget.person.name);
  late final _relation = TextEditingController(text: widget.person.relation);

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.person;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: tr('Full name'),
            controller: _name,
            maxLength: 160,
            onChanged: (v) {
              p.name = v;
              widget.onChanged();
            },
          ),
          AppTextField(
            label: tr('Relation'),
            hintText: widget.index == 0 ? 'Head' : null,
            controller: _relation,
            maxLength: 60,
            onChanged: (v) => p.relation = v,
          ),
          DropdownButtonFormField<String>(
            initialValue: p.sex,
            decoration: InputDecoration(labelText: tr('Sex')),
            items: [
              DropdownMenuItem(value: 'Male', child: Text(tr('Male'))),
              DropdownMenuItem(value: 'Female', child: Text(tr('Female'))),
            ],
            onChanged: (v) => setState(() => p.sex = v),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          AppDateField(
            label: tr('Birth date'),
            value: p.dob,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => p.dob = d),
          ),
          const SizedBox(height: AppSpacing.fieldGap),
          DropdownButtonFormField<String?>(
            initialValue: p.vulnerability,
            decoration: InputDecoration(labelText: tr('Needs special care')),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(tr('No special care needed'))),
              for (final v in householdVulnerabilities) DropdownMenuItem<String?>(value: v, child: Text(v)),
            ],
            onChanged: (v) => setState(() => p.vulnerability = v),
          ),
          if (widget.onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: widget.onRemove, child: Text(tr('Remove'))),
            ),
        ],
      ),
    );
  }
}
