/// A catalog's "asked only when" rule, the same as the server's ShowIf and the
/// web's showIfMet (MSWDO forms, 2026-10-26): `{field, contains}` where
/// `contains` is a text or a list of texts, any of which the answer contains;
/// or a list of such rules, all of which must hold. No rule means always.
library;

bool showIfMet(Object? rule, Map<String, dynamic> answers) {
  if (rule == null) return true;
  if (rule is List) return rule.every((r) => showIfMet(r, answers));
  if (rule is! Map) return true;
  final field = rule['field']?.toString() ?? '';
  if (field.isEmpty) return true;
  final raw = answers[field];
  final value = raw is Iterable ? raw.map((e) => e.toString()).join(', ') : (raw?.toString() ?? '');
  final contains = rule['contains'];
  final wanted = contains is List ? contains : [contains];
  return wanted.any((c) => value.contains(c?.toString() ?? ''));
}

/// One required document and, when it is owed only for some answers, its rule.
class RequirementRule {
  final String label;
  final Object? showIf;

  const RequirementRule(this.label, [this.showIf]);

  /// Reads `requirement_rules` (or a `requirements` list that carries objects):
  /// each a text, or `{label, showIf}`.
  static List<RequirementRule> parse(Object? raw) {
    if (raw is! List) return const [];
    final out = <RequirementRule>[];
    for (final r in raw) {
      if (r is Map) {
        final label = (r['label'] ?? '').toString().trim();
        if (label.isNotEmpty) out.add(RequirementRule(label, r['showIf']));
      } else if (r != null && r.toString().trim().isNotEmpty) {
        out.add(RequirementRule(r.toString().trim()));
      }
    }
    return out;
  }
}
