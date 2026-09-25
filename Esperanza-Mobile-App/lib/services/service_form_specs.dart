import '../models/catalog_item.dart';
import '../models/service_form_spec.dart';
import 'mock_catalog.dart';

/// The wizard's own question set per service, keyed by [CatalogItem.key] --
/// looked up to augment a real catalog item fetched from GET /services,
/// which has no equivalent field (see catalog_item.dart's own doc comment
/// on why [ServiceFormSpec] stays local rather than trying to map onto the
/// server's unconfirmed `form_spec`/`fields[]` shape).
///
/// Still sourced from mock_catalog.dart's `documentTypes`/`assistanceTypes`
/// -- not because those lists are still the catalog's source of truth (they
/// aren't, as of the Dokyu/Tulong conversion, production-readiness
/// programme, 2026-09-25), but because they're where each service's
/// formSpec/demoDefaults/demoPurpose were originally authored and audited
/// against the real paper forms (docs/DOKYU_TULONG_FORM_AUDIT.md), and
/// nothing about that audit changed when the rest of the catalog started
/// coming from the real API.
class ServiceFormSpecs {
  ServiceFormSpecs._();

  static final Map<String, CatalogItem> _byKey = {
    for (final item in [...MockCatalog.documentTypes, ...MockCatalog.assistanceTypes]) item.key: item,
  };

  static ServiceFormSpec? formSpecFor(String key) => _byKey[key]?.formSpec;

  static Map<String, dynamic> demoDefaultsFor(String key) => _byKey[key]?.demoDefaults ?? const {};

  static String? demoPurposeFor(String key) => _byKey[key]?.demoPurpose;

  /// A lucide-style icon name for services this app doesn't otherwise have
  /// an icon source for -- CatalogItem.icon was always mobile-only UI, no
  /// server field, same reasoning as [formSpecFor].
  static String? iconFor(String key) => _byKey[key]?.icon;
}
