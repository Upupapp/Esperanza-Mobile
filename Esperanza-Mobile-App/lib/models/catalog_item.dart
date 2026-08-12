/// A selectable document type (Dokyu) or assistance program (Tulong),
/// copied from the exact catalogs defined inline in the Web Admin's
/// `resources/views/citizen/document-requests.blade.php` and
/// `assistance-requests.blade.php` ($documentTypes / $assistanceTypes),
/// plus `config/esperanza_municipal_documents.php` and
/// `config/esperanza_barangay_documents.php`. Kept as static Dart data in
/// `MockCatalog` (see services/mock_catalog.dart) rather than re-typed
/// inline per screen.
class CatalogItem {
  final String key;
  final String name;
  final String office;
  final String fee;
  final String days;
  final List<String> requirements;
  final List<String> process;
  final String? amount; // Tulong only
  final String? icon; // lucide-style icon name, mapped to Material in UI

  const CatalogItem({
    required this.key,
    required this.name,
    required this.office,
    required this.fee,
    required this.days,
    required this.requirements,
    required this.process,
    this.amount,
    this.icon,
  });
}
