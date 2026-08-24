/// Resolves each catalog requirement line (still a plain `String` on
/// `CatalogItem.requirements` — see mock_catalog.dart) into a stable
/// document-type identity, without touching the catalog data itself. The
/// catalog's own requirement text is already the one place each service's
/// requirements are authored/sourced from real government forms (see
/// docs/DOKYU_TULONG_FORM_AUDIT.md) — deriving from it here, rather than
/// hand-tagging every one of the ~80 requirement lines across every
/// service, keeps that sourced data untouched and gives one place to fix
/// or extend the canonical-document mapping later.
library;

/// One catalog requirement, resolved — [label] is exactly the catalog's own
/// text (shown to the citizen unchanged); [documentType] is the stable key
/// used to look up/save a matching document in the resident's Master File
/// (see services/master_file_service.dart); [isRequired] is false only when
/// the requirement's own wording already says it's conditional (e.g. "...,
/// if applicable"), since no catalog item currently carries a separate
/// required/optional flag.
class RequirementInfo {
  final String label;
  final String documentType;
  final bool isRequired;

  const RequirementInfo({required this.label, required this.documentType, required this.isRequired});
}

List<RequirementInfo> resolveRequirements(List<String> requirements) =>
    requirements.map((label) => RequirementInfo(label: label, documentType: documentTypeFor(label), isRequired: !_isOptionalPhrasing(label))).toList();

final _optionalPhrasing = RegExp(r'if applicable|if available|if any', caseSensitive: false);

bool _isOptionalPhrasing(String label) => _optionalPhrasing.hasMatch(label);

/// The same physical document is asked for, worded almost identically, by
/// many different services (a valid ID above all) — matched here so a
/// document uploaded once can be offered again elsewhere (see
/// MasterFileService.findByType). Anything not recognized falls back to a
/// slug of its own label: still a stable key (the catalog's wording for a
/// given requirement doesn't change at runtime), just not shared with a
/// differently-worded requirement that happens to mean the same thing.
String documentTypeFor(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('valid government-issued id')) return 'valid_government_id';
  if (lower.contains('cedula')) return 'cedula';
  if (lower.contains('barangay business clearance')) return 'barangay_business_clearance';
  if (lower.contains('barangay clearance')) return 'barangay_clearance';
  if (lower.contains('barangay certification')) return 'barangay_certification';
  if (lower.contains('dti') && lower.contains('sec')) return 'dti_or_sec_registration';
  if (lower.contains('locational') || lower.contains('zoning')) return 'zoning_clearance';
  if (lower.contains('sanitary permit')) return 'sanitary_permit';
  if (lower.contains('proof of residency') || lower.contains('proof of barangay residency')) return 'proof_of_residency';
  if (lower.contains('solo parent id')) return 'solo_parent_id';
  if (lower.contains('psa birth certificate')) return 'psa_birth_certificate';
  if (lower.contains('2x2')) return 'id_photo_2x2';
  if (lower.contains('birth certificate')) return 'birth_certificate';
  return _slugify(label);
}

String _slugify(String label) {
  final cleaned = label
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return cleaned.isEmpty ? 'document' : cleaned;
}
