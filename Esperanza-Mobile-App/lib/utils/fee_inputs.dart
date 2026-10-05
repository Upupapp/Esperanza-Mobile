import 'package:flutter/widgets.dart';

/// The declared amounts a fee is assessed on -- the service's own
/// `fee.required_inputs` from GET /services (`declared_capital` for a new
/// Business Permit, `income` for Cedula, ...). POST /citizen/requests refuses
/// a request without them, so both request screens ask for each one and send
/// it as `fee_inputs` (backend finding B-053: it used to be a 500, and the
/// app never asked).
class FeeInputs {
  FeeInputs._();

  static String label(String name) => switch (name) {
    'declared_capital' => 'Declared capital (₱)',
    'prior_year_gross_receipts' => "Last year's gross receipts (₱)",
    'income' => 'Annual income (₱)',
    'project_cost' => 'Project cost (₱)',
    _ => '${_sentenceCase(name.replaceAll('_', ' '))} (₱)',
  };

  /// "50,000", "₱ 50000.50" -> the number; null for anything that isn't a
  /// non-negative amount.
  static num? parse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[₱,\s]'), '');
    if (cleaned.isEmpty) return null;
    final value = num.tryParse(cleaned);
    if (value == null || value < 0 || !value.isFinite) return null;
    return value;
  }

  /// The first problem with what was typed, or null when every amount is a
  /// usable number.
  static String? validate(List<String> names, Map<String, TextEditingController> controllers) {
    for (final name in names) {
      final raw = controllers[name]?.text.trim() ?? '';
      final field = label(name).replaceAll(' (₱)', '').toLowerCase();
      if (raw.isEmpty) return 'Please enter the $field — the fee is computed from it.';
      if (parse(raw) == null) return 'Please enter the $field as an amount, e.g. 50,000.';
    }
    return null;
  }

  /// What POST /citizen/requests takes as `fee_inputs`. Call after [validate].
  static Map<String, num> collect(List<String> names, Map<String, TextEditingController> controllers) => {
    for (final name in names) name: ?parse(controllers[name]?.text ?? ''),
  };

  static String _sentenceCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
