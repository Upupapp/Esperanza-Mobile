/// The password standard, mirrored from the backend's `StrongPassword` rule
/// (esperanza-backend `app/Rules/StrongPassword.php`). The server is the
/// authority; this exists so the citizen sees what is required while typing
/// instead of after a failed submit. Keep the two in step.
class PasswordRequirement {
  /// Text before the emphasised part, e.g. "At least ".
  final String lead;

  /// The emphasised part, e.g. "8 characters".
  final String emphasis;

  /// Tagalog-English sentence shown when this requirement is not met.
  final String unmetMessage;

  final bool Function(String) isMet;

  const PasswordRequirement({
    required this.lead,
    required this.emphasis,
    required this.unmetMessage,
    required this.isMet,
  });
}

class PasswordStandard {
  const PasswordStandard._();

  static const minLength = 8;

  static final requirements = <PasswordRequirement>[
    PasswordRequirement(
      lead: 'At least ',
      emphasis: '$minLength characters',
      unmetMessage: 'Dapat hindi bababa sa $minLength characters ang password.',
      isMet: (p) => p.runes.length >= minLength,
    ),
    PasswordRequirement(
      lead: 'At least ',
      emphasis: '1 uppercase letter',
      unmetMessage: 'Dapat may kahit 1 uppercase letter ang password.',
      isMet: (p) => RegExp(r'\p{Lu}', unicode: true).hasMatch(p),
    ),
    PasswordRequirement(
      lead: 'At least ',
      emphasis: '1 lowercase letter',
      unmetMessage: 'Dapat may kahit 1 lowercase letter ang password.',
      isMet: (p) => RegExp(r'\p{Ll}', unicode: true).hasMatch(p),
    ),
    PasswordRequirement(
      lead: 'At least ',
      emphasis: '1 number',
      unmetMessage: 'Dapat may kahit 1 number ang password.',
      isMet: (p) => RegExp(r'\d').hasMatch(p),
    ),
    PasswordRequirement(
      lead: 'At least ',
      emphasis: '1 special character',
      unmetMessage: 'Dapat may kahit 1 special character ang password.',
      isMet: (p) => RegExp(r'[^\p{L}\d]', unicode: true).hasMatch(p),
    ),
  ];

  static bool isValid(String password) => requirements.every((r) => r.isMet(password));

  /// Every unmet requirement, in order, in Tagalog-English.
  static List<String> unmetMessages(String password) =>
      [for (final r in requirements) if (!r.isMet(password)) r.unmetMessage];
}
