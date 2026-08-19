import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.3),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon, size: 18, color: AppColors.slate400) : null,
            suffixIcon: suffix,
            errorText: error,
          ),
        ),
        if (hint != null && error == null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.35)),
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

  const AppSelectField({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
          ),
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
                  child: Text(labelBuilder(o), style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
