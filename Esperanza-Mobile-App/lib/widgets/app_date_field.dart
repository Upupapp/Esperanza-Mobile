import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// A labeled, tappable date field matching AppTextField/AppSelectField's
/// visual language (it reuses the app-wide InputDecorationTheme via a
/// read-only TextFormField rather than hand-rolling a lookalike box), that
/// opens the platform date picker — the mobile-native way to satisfy
/// "dropdowns/date pickers that work on mobile" without a custom calendar
/// widget.
class AppDateField extends StatelessWidget {
  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hintText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  AppDateField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.hintText = 'Select date',
    DateTime? firstDate,
    DateTime? lastDate,
  })  : firstDate = firstDate ?? DateTime(1900),
        lastDate = lastDate ?? DateTime.now();

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(lastDate!.year - 25),
      firstDate: firstDate!,
      lastDate: lastDate!,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700)),
          const SizedBox(height: 6),
        ],
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: value != null ? DateFormat('MMM d, y').format(value!) : ''),
          onTap: () => _pick(context),
          style: const TextStyle(fontSize: 14, color: AppColors.textBody),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.slate400),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.slate400),
          ),
        ),
      ],
    );
  }
}
