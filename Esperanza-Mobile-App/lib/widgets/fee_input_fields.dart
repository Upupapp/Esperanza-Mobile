import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/fee_inputs.dart';
import 'app_text_field.dart';

import '../l10n/tr.dart';
/// One amount field per [names] (a service's `fee.required_inputs`), under a
/// short note on why it is asked. Renders nothing for a service whose fee
/// needs no declared amount.
class FeeInputFields extends StatelessWidget {
  final List<String> names;
  final Map<String, TextEditingController> controllers;

  const FeeInputFields({super.key, required this.names, required this.controllers});

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Fee details'),
          style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'The fee for this service is computed from the amount you declare. Staff confirm it during review.',
          style: TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted, height: 1.4),
        ),
        for (final name in names) ...[
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: FeeInputs.label(name),
            hintText: 'e.g. 50,000',
            controller: controllers[name],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ],
    );
  }
}
