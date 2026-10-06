import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Mirrors `resources/views/components/ui/input.blade.php`: label above,
/// optional leading icon, slate-50 fill, brand-colored focus ring, rose
/// error state with helper text.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? error;
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  /// The server's own length limit, when the field has one: shown as a
  /// counter and enforced while typing, so the citizen is not refused after
  /// pressing submit.
  final int? maxLength;

  /// Marks the label with a red asterisk (see [FieldLabel]).
  final bool required;

  /// What may be typed at all, e.g. digits only for a mobile number.
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.hintText,
    this.icon,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
    this.suffix,
    this.maxLength,
    this.required = false,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          FieldLabel(label!, required: required),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: controller,
          maxLength: maxLength,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: AppTextSize.body, color: AppColors.textBody, height: 1.3),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.slate400) : null,
            suffixIcon: suffix,
            errorText: error,
          ),
        ),
        if (hint != null && error == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(hint!, style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted, height: 1.35)),
        ],
      ],
    );
  }
}

/// A labeled dropdown/select, mirroring the same visual language as
/// AppTextField for use in multi-step forms (document/assistance requests).
class AppSelectField<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  /// Marks the label with a red asterisk (see [FieldLabel]).
  final bool required;

  const AppSelectField({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.hintText,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          FieldLabel(label!, required: required),
          const SizedBox(height: AppSpacing.sm),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.slate400),
          decoration: InputDecoration(hintText: hintText),
          items: options
              .map(
                (o) => DropdownMenuItem<T>(
                  value: o,
                  child: Text(labelBuilder(o), style: const TextStyle(fontSize: AppTextSize.body)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// A form field's label. A required field carries a red asterisk after the
/// label (Esperanza QA, 2026-10-07: nothing said which fields had to be
/// filled). The asterisk is its own widget, so the label text itself stays
/// exactly the field's name.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700);
    if (!required) return Text(text, style: style);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: Text(text, style: style)),
        Semantics(
          label: 'required',
          child: const Text(
            ' *',
            style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: AppColors.rose600),
          ),
        ),
      ],
    );
  }
}
