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

  /// The real catalog's key -> the mock item that holds that service's audited
  /// form, where the two keys differ. Without this, a lookup by the server's
  /// key found nothing for these services and they fell back to the generic
  /// wizard, even though their forms were authored here: every common barangay
  /// certificate among them. Names checked one by one against GET /services;
  /// mcro_delayed_registration is left out on purpose, as the server has one
  /// service where this file has a birth form and a death form.
  static const Map<String, String> _serverKeyAliases = {
    'brgy_clearance': 'dokyu_barangay_clearance',
    'brgy_residency': 'dokyu_residency',
    'brgy_indigency': 'dokyu_indigency',
    'brgy_business_clearance': 'dokyu_barangay_business_clearance',
    'brgy_cert_general': 'dokyu_barangay_certification',
    'brgy_first_time_jobseeker': 'dokyu_first_time_jobseeker',
    'brgy_cert_late_registration': 'dokyu_barangay_cert_late_birth',
    'brgy_cert_death_registration': 'dokyu_barangay_cert_death',
    'osca_senior_citizen': 'dokyu_senior_citizen_id',
    'mcro_marriage_license': 'dokyu_marriage_license',
    'mcro_marriage': 'dokyu_marriage_certificate_copy',
    'municipal_pet_registration': 'dokyu_pet_registration',
    'locational_clearance': 'dokyu_locational_clearance',
    'msw_pwd_id': 'tulong_pwd_registration',
    'tulong_tesda': 'tulong_tesda_registration',
    'tulong_erpat': 'tulong_erpat_registration',
  };

  static CatalogItem? _itemFor(String key) => _byKey[key] ?? _byKey[_serverKeyAliases[key]];

  static ServiceFormSpec? formSpecFor(String key) => _itemFor(key)?.formSpec;

  static Map<String, dynamic> demoDefaultsFor(String key) => _itemFor(key)?.demoDefaults ?? const {};

  static String? demoPurposeFor(String key) => _itemFor(key)?.demoPurpose;

  /// A lucide-style icon name for services this app doesn't otherwise have
  /// an icon source for -- CatalogItem.icon was always mobile-only UI, no
  /// server field, same reasoning as [formSpecFor].
  static String? iconFor(String key) => _itemFor(key)?.icon;
}
