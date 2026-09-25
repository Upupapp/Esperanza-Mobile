// A fake /services + /citizen/requests backend built from MockCatalog's own
// documentTypes/assistanceTypes, for tests that drive DokyuScreen, TulongScreen,
// or the request wizards through the real widget tree.
//
// Both screens now call RequestsService.loadCatalog()/loadRequests() as soon
// as they build (see dokyu_screen.dart's own doc comment) -- production-
// readiness programme, 2026-09-25 converted them off MockCatalog directly.
// A test that reaches either screen without a fake handler installed gets
// flutter_test_config.dart's default fake, which throws "did not configure a
// fake response" on first request, not a real network call.
//
// Re-serving MockCatalog's own items through the fake /services JSON shape
// (rather than inventing new fixture data) keeps every key, requirement,
// formSpec, demoDefaults and demoPurpose identical to what these tests
// asserted against before the conversion -- ServiceFormSpecs still looks
// them up from MockCatalog by key regardless of where the base catalog data
// itself came from (see service_form_specs.dart).
import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/services/mock_catalog.dart';

import 'fake_api.dart';

Map<String, dynamic> _serviceJson(CatalogItem item, String type) => {
  'key': item.key,
  'name': item.name,
  'office': item.office,
  'fee': item.fee,
  'days': item.days,
  'requirements': item.requirements,
  'process': item.process,
  'type': type,
  'policy_blocked': false,
};

class DokyuTulongFixtures {
  DokyuTulongFixtures._();

  static final List<Map<String, dynamic>> dokyuServices =
      MockCatalog.documentTypes.map((i) => _serviceJson(i, 'dokyu')).toList();
  static final List<Map<String, dynamic>> tulongServices =
      MockCatalog.assistanceTypes.map((i) => _serviceJson(i, 'tulong')).toList();

  /// Installs a fake API serving the full real catalog and, by default, an
  /// empty request list. [requests] seeds GET /citizen/requests (the
  /// CitizenRequestController::index() thin shape: ref/type/service/status/
  /// submitted). [onSubmit] and [onResubmit], when given, back POST
  /// /citizen/requests and POST /citizen/requests/{ref}/resubmit; a test
  /// that never submits/resubmits can leave them unset.
  static void install({
    List<Map<String, dynamic>> requests = const [],
    Map<String, dynamic> Function(Map<String, dynamic> body)? onSubmit,
    Map<String, dynamic> Function(String ref)? onResubmit,
  }) {
    FakeApi.installFull((req) {
      if (req.method == 'GET' && req.path == '/services') {
        return req.query['type'] == 'tulong' ? tulongServices : dokyuServices;
      }
      if (req.method == 'GET' && req.path == '/citizen/requests') {
        return requests;
      }
      if (req.method == 'GET' && req.path.startsWith('/citizen/requests/')) {
        final ref = req.path.split('/').last;
        return requests.firstWhere(
          (r) => r['ref'] == ref,
          orElse: () => throw const FakeApiError(messageEn: 'No such request in this fixture.'),
        );
      }
      if (req.method == 'POST' && req.path == '/citizen/requests') {
        if (onSubmit == null) {
          throw const FakeApiError(messageEn: 'This fixture was not given an onSubmit handler.');
        }
        return onSubmit(req.body ?? const {});
      }
      if (req.method == 'POST' && req.path.endsWith('/resubmit')) {
        if (onResubmit == null) {
          throw const FakeApiError(messageEn: 'This fixture was not given an onResubmit handler.');
        }
        final ref = req.path.split('/')[req.path.split('/').length - 2];
        return onResubmit(ref);
      }
      throw FakeApiError(messageEn: 'DokyuTulongFixtures has no handler for ${req.method} ${req.path}.');
    });
  }
}
