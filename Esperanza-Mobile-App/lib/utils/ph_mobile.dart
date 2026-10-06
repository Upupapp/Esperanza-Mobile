import 'package:flutter/services.dart';

/// A Philippine mobile number as every form in the app takes it: 11 digits,
/// 09XXXXXXXXX, numbers only (Esperanza QA, 2026-10-07: contact fields took
/// letters and any length, and the form still went on). The server checks the
/// same rule (esperanza-backend `App\Rules\PhilippineMobile`).
class PhMobile {
  PhMobile._();

  static const length = 11;
  static const hint = '09XXXXXXXXX';
  static const invalidMessage = 'Contact number must contain 11 digits and numbers only.';

  /// Only digits, and no more than 11 of them, can be typed at all.
  static final List<TextInputFormatter> inputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(length),
  ];

  static final _pattern = RegExp(r'^09\d{9}$');

  static bool isValid(String value) => _pattern.hasMatch(value.trim());

  /// The problem with [value], or null when it is fine. Empty is fine unless
  /// [required]; then it is "please enter" rather than the format message.
  static String? validate(
    String value, {
    bool required = false,
    String emptyMessage = 'Please enter a contact number.',
  }) {
    final v = value.trim();
    if (v.isEmpty) return required ? emptyMessage : null;
    return isValid(v) ? null : invalidMessage;
  }

  /// A number saved before digits-only input ("0917 123 4567",
  /// "+63 917 123 4567") as the 11 digits, so a prefilled field shows what
  /// the formatter allows. Anything that does not become a valid number is
  /// returned unchanged, for the resident to see and correct.
  static String normalise(String raw) {
    var digits = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+63')) digits = '0${digits.substring(3)}';
    if (digits.startsWith('63') && digits.length == 12) digits = '0${digits.substring(2)}';
    return isValid(digits) ? digits : raw;
  }
}
