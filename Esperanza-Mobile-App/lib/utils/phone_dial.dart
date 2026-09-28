/// The `tel:` URI for a contact string as the directory and hotline APIs
/// return it -- free text typed by LGU staff, e.g. `(056) 123-4567`,
/// `0917 123 4567 / 0998 765 4321`, `Globe: 0917-123-4567`, or `911`.
///
/// `Uri.parse('tel:$contact')` passed that text through verbatim: spaces,
/// letters and a second number all went to the dialler, which on some
/// devices opens an empty or wrong number -- on an emergency hotline. Only
/// the first number is dialled, reduced to digits and a leading `+`.
/// Returns null when the text holds no number at all, so the caller can hide
/// its call button rather than show one that does nothing.
Uri? dialUri(String? contact) {
  if (contact == null) return null;
  final first = contact.split(RegExp(r'[/,;]|\bor\b')).map((s) => s.trim()).firstWhere(
        (s) => RegExp(r'\d').hasMatch(s),
        orElse: () => '',
      );
  final digits = first.replaceAll(RegExp(r'[^\d+]'), '');
  final number = digits.startsWith('+') ? '+${digits.substring(1).replaceAll('+', '')}' : digits.replaceAll('+', '');
  if (number.replaceAll('+', '').length < 3) return null;
  return Uri(scheme: 'tel', path: number);
}
