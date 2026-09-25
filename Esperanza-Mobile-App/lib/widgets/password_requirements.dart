import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/password_standard.dart';

/// The password checklist shown under a "create a password" field: one line
/// per requirement, a dot that turns green once the typed password meets it.
class PasswordRequirements extends StatelessWidget {
  final String password;

  const PasswordRequirements({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in PasswordStandard.requirements) _line(r, r.isMet(password)),
      ],
    );
  }

  Widget _line(PasswordRequirement r, bool met) {
    final color = met ? AppColors.emerald700 : AppColors.slate500;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle_rounded : Icons.circle, size: met ? 14 : 10, color: met ? AppColors.emerald700 : AppColors.brand600),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12.5, color: color, height: 1.3),
                children: [
                  TextSpan(text: r.lead),
                  TextSpan(text: r.emphasis, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
