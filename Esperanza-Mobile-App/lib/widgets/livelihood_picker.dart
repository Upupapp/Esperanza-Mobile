import 'package:flutter/material.dart';

import '../l10n/tr.dart';
import '../services/livelihood_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_text_field.dart';

/// The occupation as two dropdowns from the DRRM list (owner, 2026-10-28/29):
/// Employment group, then the occupation in that group, with "Others,
/// specify" where the form has it. The website uses the same list.
///
/// [previousText] is the occupation typed before the list existed: shown as
/// a reminder until a choice is made, never sent back as a choice.
class LivelihoodPicker extends StatefulWidget {
  const LivelihoodPicker({
    super.key,
    required this.code,
    required this.other,
    required this.onChanged,
    this.previousText = '',
  });

  final String code;
  final String other;
  final String previousText;

  /// Called with the chosen code ('' when cleared) and the Others words.
  final void Function(String code, String other) onChanged;

  @override
  State<LivelihoodPicker> createState() => _LivelihoodPickerState();
}

class _LivelihoodPickerState extends State<LivelihoodPicker> {
  late Future<List<LivelihoodGroup>> _list;
  late String _group = widget.code.isEmpty ? '' : widget.code.substring(0, 1);
  late String _code = widget.code;
  late final TextEditingController _other = TextEditingController(text: widget.other);

  @override
  void initState() {
    super.initState();
    _list = LivelihoodService.load();
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_code, LivelihoodService.item(_code)?.isOther == true ? _other.text.trim() : '');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LivelihoodGroup>>(
      future: _list,
      builder: (context, snap) {
        if (snap.hasError) {
          // Wraps rather than sits in a row: at large text on a narrow phone the
          // button no longer fits beside the message.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    tr('The occupation list could not load. Try again later.'),
                    style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.rose600),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _list = LivelihoodService.load(refresh: true)),
                    child: Text(tr('Try again')),
                  ),
                ],
              ),
              // What is on record stays visible, and unchanged.
              if (widget.previousText.trim().isNotEmpty)
                Text(
                  '${tr('Recorded before as:')} ${widget.previousText.trim()}',
                  style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted, height: 1.35),
                ),
            ],
          );
        }
        final groups = snap.data;
        if (groups == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        final group = groups.where((g) => g.code == _group).firstOrNull;
        final item = LivelihoodService.item(_code);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSelectField<String>(
              label: tr('Employment group'),
              value: _group.isEmpty ? null : _group,
              options: [for (final g in groups) g.code],
              labelBuilder: (c) {
                final g = groups.firstWhere((x) => x.code == c);
                return '${g.code} · ${g.label}';
              },
              onChanged: (c) => setState(() {
                if ((c ?? '') == _group) return;
                _group = c ?? '';
                _code = '';
                _other.clear();
                _emit();
              }),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSelectField<String>(
              // A new group is a new list: rebuilt rather than left holding a code from another.
              key: ValueKey('livelihood-item-$_group'),
              label: tr('Occupation or livelihood'),
              value: _code.isEmpty || item == null ? null : _code,
              options: [for (final i in group?.items ?? const <LivelihoodItem>[]) i.code],
              labelBuilder: (c) => LivelihoodService.item(c)?.fullLabel ?? c,
              hintText: group == null ? tr('Choose a group first') : null,
              onChanged: (c) => setState(() {
                _code = c ?? '';
                if (LivelihoodService.item(_code)?.isOther != true) _other.clear();
                _emit();
              }),
            ),
            if (item?.isOther == true) ...[
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: tr('Specify the occupation'),
                controller: _other,
                maxLength: 100,
                required: true,
                onChanged: (_) => _emit(),
              ),
            ],
            if (_code.isEmpty && widget.previousText.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${tr('Recorded before as:')} ${widget.previousText.trim()}. ${tr('Choose the matching item from the list.')}',
                style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted, height: 1.35),
              ),
            ],
          ],
        );
      },
    );
  }
}
