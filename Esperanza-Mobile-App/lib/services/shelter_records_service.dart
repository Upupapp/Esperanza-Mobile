import 'api_client.dart';
import 'json_read.dart';

/// The resident's side of shelter and relief (owner, 2026-10-27, Phase 3),
/// as on the website's Emergency page (resources/js/citizen-shelter.js):
///
///   GET    /citizen/sakuna/records                  their stays and relief
///   POST   /citizen/sakuna/relief/{ref}/acknowledge  received / not received
///   POST   /citizen/sakuna/records/report           a mistake (a support ticket)
///   GET | PUT | DELETE /citizen/sakuna/household    the list kept ready
///
/// The server finds a resident's records through the registry link on the
/// account only, never by name. Staff still check families in and release
/// relief; nothing here changes a shelter record. The resident's answer on
/// an item sits beside the paper signature, never instead of it.

/// One stay at an evacuation centre (a shelter record of the family).
class ShelterStay {
  const ShelterStay({
    required this.ref,
    required this.staying,
    this.center,
    this.checkedIn,
    this.checkedOut,
    this.memberCount = 0,
    this.members = const [],
  });

  final String ref;

  /// Still at the centre (the record's `Processing`).
  final bool staying;
  final String? center;
  final DateTime? checkedIn;
  final DateTime? checkedOut;
  final int memberCount;
  final List<String> members;

  static ShelterStay? fromJson(Map<String, dynamic> row) {
    final ref = JsonRead.nonEmpty(row['ref']);
    if (ref == null) return null;
    return ShelterStay(
      ref: ref,
      staying: JsonRead.nonEmpty(row['status']) == 'Processing',
      center: JsonRead.nonEmpty(row['center']),
      checkedIn: JsonRead.date(row['checked_in']),
      checkedOut: JsonRead.date(row['checked_out']),
      memberCount: JsonRead.integer(row['member_count']) ?? 0,
      members: JsonRead.rows(JsonRead.list(row['members']), (m) => JsonRead.nonEmpty(m['name'])),
    );
  }
}

/// A relief item released to the resident's family.
class ReliefItem {
  const ReliefItem({
    required this.ref,
    required this.item,
    this.operation,
    this.quantity,
    this.unit,
    this.releasedAt,
    this.where,
    this.acknowledgement,
    this.acknowledgedAt,
    this.canAcknowledge = false,
  });

  final String ref;
  final String item;
  final String? operation;
  final int? quantity;
  final String? unit;
  final DateTime? releasedAt;

  /// The centre or the place it was given, when staff recorded one.
  final String? where;

  /// `received`, `not_received`, or null before the resident answers.
  final String? acknowledgement;
  final DateTime? acknowledgedAt;
  final bool canAcknowledge;

  /// "2 pack Family Food Pack", as the website writes it.
  String get line => [if (quantity != null) '$quantity', ?unit, item].join(' ');

  static ReliefItem? fromJson(Map<String, dynamic> row) {
    final ref = JsonRead.nonEmpty(row['ref']);
    final item = JsonRead.nonEmpty(row['item']);
    if (ref == null || item == null) return null;
    final answer = JsonRead.nonEmpty(row['acknowledgement']);
    return ReliefItem(
      ref: ref,
      item: item,
      operation: JsonRead.nonEmpty(row['operation']),
      quantity: JsonRead.integer(row['quantity']),
      unit: JsonRead.nonEmpty(row['unit']),
      releasedAt: JsonRead.date(row['released_at']),
      where: JsonRead.nonEmpty(row['where']),
      // Only the two answers the server gives; anything else is no answer.
      acknowledgement: answer == 'received' || answer == 'not_received' ? answer : null,
      acknowledgedAt: JsonRead.date(row['acknowledged_at']),
      canAcknowledge: JsonRead.boolean(row['can_acknowledge']) ?? false,
    );
  }
}

class ShelterRecords {
  const ShelterRecords({this.enabled = true, this.linked = false, this.stays = const [], this.relief = const []});

  /// Off when the LGU has turned residents' history off.
  final bool enabled;

  /// The account carries a registry link; without one nothing can be found.
  final bool linked;
  final List<ShelterStay> stays;
  final List<ReliefItem> relief;

  static ShelterRecords fromJson(Map<String, dynamic> m) => ShelterRecords(
    enabled: JsonRead.boolean(m['enabled']) ?? true,
    linked: JsonRead.boolean(m['linked']) ?? false,
    stays: JsonRead.rows(JsonRead.list(m['stays']), ShelterStay.fromJson),
    relief: JsonRead.rows(JsonRead.list(m['relief']), ReliefItem.fromJson),
  );
}

/// One person on the household list kept ready for check-in.
class HouseholdPerson {
  HouseholdPerson({this.name = '', this.relation = '', this.sex, this.dob, this.vulnerability});

  String name;
  String relation;
  String? sex;
  DateTime? dob;
  String? vulnerability;

  static HouseholdPerson? fromJson(Map<String, dynamic> m) {
    final name = JsonRead.nonEmpty(m['name']);
    if (name == null) return null;
    final sex = JsonRead.nonEmpty(m['sex']);
    return HouseholdPerson(
      name: name,
      relation: JsonRead.string(m['relation']) ?? '',
      sex: sex == 'Male' || sex == 'Female' ? sex : null,
      dob: JsonRead.date(m['dob']),
      vulnerability: JsonRead.nonEmpty(m['vulnerability']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'relation': relation.trim().isEmpty ? null : relation.trim(),
    'sex': sex,
    'dob': dob == null
        ? null
        : '${dob!.year.toString().padLeft(4, '0')}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}',
    'vulnerability': vulnerability,
  };
}

class HouseholdList {
  const HouseholdList({required this.barangay, this.sitio, this.purok, this.members = const [], this.updatedAt});

  final String barangay;
  final String? sitio;
  final String? purok;
  final List<HouseholdPerson> members;
  final DateTime? updatedAt;

  static HouseholdList? fromJson(Map<String, dynamic>? m) {
    if (m == null) return null;
    return HouseholdList(
      barangay: JsonRead.string(m['barangay']) ?? '',
      sitio: JsonRead.nonEmpty(m['sitio']),
      purok: JsonRead.nonEmpty(m['purok']),
      members: JsonRead.rows(JsonRead.list(m['members']), HouseholdPerson.fromJson),
      updatedAt: JsonRead.date(m['updated_at']),
    );
  }
}

/// Whether the LGU has the household list on, and the resident's list.
typedef HouseholdState = ({bool enabled, HouseholdList? household});

/// The vulnerable sectors staff record at check-in (the portal's list).
const householdVulnerabilities = ['Older person', 'Pregnant', 'Lactating mother', 'PWD', 'Solo parent', 'Child (under 18)'];

class ShelterRecordsService {
  ShelterRecordsService._();

  static Future<ShelterRecords> load() async {
    final res = await api.get('/citizen/sakuna/records');
    return ShelterRecords.fromJson(res.map);
  }

  /// The resident's answer on a released item; the server keeps the first.
  static Future<ReliefItem?> acknowledge(String ref, {required bool received, String? note}) async {
    final res = await api.post(
      '/citizen/sakuna/relief/${ApiClient.segment(ref)}/acknowledge',
      body: {'received': received, if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
    );
    return ReliefItem.fromJson(res.map);
  }

  /// A mistake on a stay or an item, sent as a support ticket; its number.
  static Future<String?> reportMistake(String ref, String message) async {
    final res = await api.post('/citizen/sakuna/records/report', body: {'ref': ref, 'message': message.trim()});
    return JsonRead.nonEmpty(res.map['ticket']);
  }

  static Future<HouseholdState> loadHousehold() async {
    final res = await api.get('/citizen/sakuna/household');
    return (
      enabled: JsonRead.boolean(res.map['enabled']) ?? false,
      household: HouseholdList.fromJson(JsonRead.map(res.map['household'])),
    );
  }

  /// Saved only with [consent]: the server refuses a list without it.
  static Future<HouseholdList?> saveHousehold({
    required bool consent,
    required String barangay,
    String? sitio,
    String? purok,
    required List<HouseholdPerson> members,
  }) async {
    final res = await api.put(
      '/citizen/sakuna/household',
      body: {
        'consent': consent,
        'barangay': barangay,
        'sitio': (sitio ?? '').trim().isEmpty ? null : sitio!.trim(),
        'purok': (purok ?? '').trim().isEmpty ? null : purok!.trim(),
        'members': [
          for (final m in members)
            if (m.name.trim().isNotEmpty) m.toJson(),
        ],
      },
    );
    return HouseholdList.fromJson(JsonRead.map(res.map['household']));
  }

  static Future<void> withdrawHousehold() async {
    await api.delete('/citizen/sakuna/household');
  }
}
