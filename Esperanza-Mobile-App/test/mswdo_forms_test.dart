// The MSWD's own forms in the app (2026-10-26): a requirement owed only for
// some answers (the Solo Parent ID's category documents) is asked only when
// the answers call for it, the same rule as the server and the web; the Solo
// Parent ID has its form; and the IDs the LGU released show in the wallet.
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/models/catalog_item.dart';
import 'package:esperanza_mobile/services/service_form_specs.dart';
import 'package:esperanza_mobile/services/wallet_service.dart';
import 'package:esperanza_mobile/utils/show_if.dart';

void main() {
  const widow = {'application_type': 'New', 'solo_parent_category': '(a2) Widow / widower'};

  test('a rule is met by any of its texts, and a list of rules by all of them', () {
    expect(showIfMet(null, const {}), isTrue);
    expect(showIfMet({'field': 'application_type', 'contains': 'Lost'}, {'application_type': 'Lost ID (replacement)'}), isTrue);
    expect(showIfMet({'field': 'application_type', 'contains': ['New', 'Renewal']}, {'application_type': 'Renewal'}), isTrue);
    expect(
      showIfMet([
        {'field': 'application_type', 'contains': 'New'},
        {'field': 'solo_parent_category', 'contains': '(a2)'},
      ], widow),
      isTrue,
    );
    expect(
      showIfMet([
        {'field': 'application_type', 'contains': 'New'},
        {'field': 'solo_parent_category', 'contains': '(c)'},
      ], widow),
      isFalse,
    );
    expect(showIfMet({'field': 'kinds', 'contains': 'B'}, {'kinds': {'A', 'B'}}), isTrue, reason: 'a multiselect');
  });

  test('the catalog owes a widow the death certificate, not the CENOMAR', () {
    final item = CatalogItem.fromApi({
      'key': 'msw_solo_parent_id',
      'name': 'Solo Parent ID (SPIC)',
      'requirements': ['Death certificate of the spouse', 'Certificate of No Marriage (CENOMAR)', '1x1 ID pictures'],
      'requirement_rules': [
        {
          'label': 'Death certificate of the spouse',
          'showIf': [
            {'field': 'application_type', 'contains': 'New'},
            {'field': 'solo_parent_category', 'contains': '(a2)'},
          ],
        },
        {
          'label': 'Certificate of No Marriage (CENOMAR)',
          'showIf': [
            {'field': 'application_type', 'contains': ['New', 'Renewal']},
            {'field': 'solo_parent_category', 'contains': '(c)'},
          ],
        },
        '1x1 ID pictures',
      ],
    });
    expect(item.requirements, hasLength(3), reason: 'an older screen still reads every label');
    expect(item.requirementsFor(widow), ['Death certificate of the spouse', '1x1 ID pictures']);
    expect(item.requirementsFor(const {'application_type': 'Renewal', 'solo_parent_category': '(c) Unmarried person'}), [
      'Certificate of No Marriage (CENOMAR)',
      '1x1 ID pictures',
    ]);
  });

  test('a catalog with plain requirements owes them all', () {
    final item = CatalogItem.fromApi({
      'key': 'brgy_clearance',
      'name': 'Barangay Clearance',
      'requirements': ['Valid ID', 'Cedula'],
    });
    expect(item.requirementsFor(const {}), ['Valid ID', 'Cedula']);
  });

  test('the Solo Parent ID asks the two answers its documents depend on, by the server keys', () {
    final spec = ServiceFormSpecs.formSpecFor('msw_solo_parent_id');
    expect(spec, isNotNull);
    final fields = {for (final s in spec!.steps) for (final f in s.fields) f.key: f};
    expect(fields['application_type']!.options, ['New', 'Renewal', 'Lost ID (replacement)']);
    expect(fields['solo_parent_category']!.options, hasLength(13));
    expect(fields['previous_spic_number']!.visibleWhenValueIn, ['Renewal', 'Lost ID (replacement)']);
    expect(fields['certify_and_consent'], isNotNull);

    final pwd = {
      for (final s in ServiceFormSpecs.formSpecFor('msw_pwd_id')!.steps)
        for (final f in s.fields) f.key: f,
    };
    for (final key in ['ethnicGroup', 'employmentCategory', 'employmentType', 'orgAffiliated']) {
      expect(pwd.containsKey(key), isTrue, reason: 'PRPWD item $key');
    }
  });

  test('the wallet reads the IDs the LGU released', () {
    final wallet = CitizenWallet.fromApi({
      'sector_ids': [
        {
          'sector': 'pwd',
          'name': 'PWD ID',
          'issuer': 'MSWDO',
          'id_number': '05-4110-000-0000123',
          'holder_name': 'Juan Dela Cruz',
          'valid_until': '2031-10-26',
          'status': 'active',
          'verify_url': 'https://esperanza.example/verify/ABC',
        },
        {'sector': 'senior', 'name': 'Senior Citizen ID'},
      ],
    });
    expect(wallet.sectorIds, hasLength(1), reason: 'a row with no number is skipped');
    final id = wallet.sectorIds.single;
    expect(id.idNumber, '05-4110-000-0000123');
    expect(id.validUntil, DateTime(2031, 10, 26));
    expect(id.verifyUrl, 'https://esperanza.example/verify/ABC');
  });
}
