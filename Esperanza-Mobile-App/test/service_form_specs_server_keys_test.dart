// The real catalog (GET /services) names services by the server's keys; the
// audited forms live in mock_catalog.dart under the app's older keys. These
// pin the bridge between the two, so a curated form cannot silently fall back
// to the generic wizard again.
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/services/mock_catalog.dart';
import 'package:esperanza_mobile/services/service_form_specs.dart';

void main() {
  test('the common barangay certificates get their audited forms by server key', () {
    for (final key in ['brgy_clearance', 'brgy_residency', 'brgy_indigency', 'brgy_business_clearance', 'brgy_cert_general', 'brgy_first_time_jobseeker']) {
      expect(ServiceFormSpecs.formSpecFor(key), isNotNull, reason: '$key fell back to the generic wizard');
    }
  });

  test('a server key resolves to the same form as the mock key it stands for', () {
    final pairs = {
      'brgy_clearance': 'dokyu_barangay_clearance',
      'osca_senior_citizen': 'dokyu_senior_citizen_id',
      'mcro_marriage': 'dokyu_marriage_certificate_copy',
      'tulong_erpat': 'tulong_erpat_registration',
    };
    for (final entry in pairs.entries) {
      expect(identical(ServiceFormSpecs.formSpecFor(entry.key), ServiceFormSpecs.formSpecFor(entry.value)), isTrue, reason: entry.key);
    }
  });

  test('a key both catalogs share still resolves directly', () {
    final residency = MockCatalog.documentTypes.firstWhere((i) => i.key == 'dokyu_residency');
    expect(identical(ServiceFormSpecs.formSpecFor('dokyu_residency'), residency.formSpec), isTrue);
  });

  test('an unknown key and the ambiguous delayed registration have no form', () {
    expect(ServiceFormSpecs.formSpecFor('no_such_service'), isNull);
    expect(ServiceFormSpecs.formSpecFor('mcro_delayed_registration'), isNull);
  });
}
