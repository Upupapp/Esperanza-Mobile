import 'api_client.dart';
import 'json_read.dart';

/// One item on the DRRM employment and livelihood list, as
/// `GET /livelihood-classes` returns it (esperanza-backend
/// LivelihoodController): B-3-1 Tricycle Driver under the heading Transport
/// Worker, or B-3-5 Others, which needs the occupation described.
class LivelihoodItem {
  const LivelihoodItem({required this.code, required this.label, this.heading, this.isOther = false});

  final String code;
  final String label;
  final String? heading;
  final bool isOther;

  /// The group letter: A, B, C or D.
  String get group => code.substring(0, 1);

  /// "Transport Worker › Tricycle Driver", or the label alone.
  String get fullLabel => heading == null ? label : '$heading › $label';

  static LivelihoodItem? fromApi(Map<String, dynamic> row) {
    final code = JsonRead.nonEmpty(row['code']);
    final label = JsonRead.nonEmpty(row['label']);
    if (code == null || label == null) return null;
    return LivelihoodItem(code: code, label: label, heading: JsonRead.nonEmpty(row['heading']), isOther: JsonRead.boolean(row['other']) ?? false);
  }
}

/// One of the four groups: A Formal, B Informal, C Agriculture, Fisheries
/// and Natural Resources, D Economic or Non-Economic Roles.
class LivelihoodGroup {
  const LivelihoodGroup({required this.code, required this.label, required this.items});

  final String code;
  final String label;
  final List<LivelihoodItem> items;

  static LivelihoodGroup? fromApi(Map<String, dynamic> row) {
    final code = JsonRead.nonEmpty(row['code']);
    final label = JsonRead.nonEmpty(row['label']);
    if (code == null || label == null) return null;
    return LivelihoodGroup(code: code, label: label, items: JsonRead.rows(row['items'], LivelihoodItem.fromApi));
  }
}

/// A person's occupation as classified on the DRRM list: the `livelihood`
/// object the server sends beside the occupation text.
class Livelihood {
  const Livelihood({this.code, this.fullLabel, this.other, this.status});

  final String? code;
  final String? fullLabel;
  final String? other;

  /// classified, or waiting for staff: needs_review, likely_test, conflict.
  final String? status;

  bool get isClassified => code != null && status == 'classified';

  static Livelihood? fromApi(Object? raw) {
    final row = JsonRead.map(raw);
    if (row == null) return null;
    return Livelihood(
      code: JsonRead.nonEmpty(row['code']),
      fullLabel: JsonRead.nonEmpty(row['full_label']),
      other: JsonRead.nonEmpty(row['other']),
      status: JsonRead.nonEmpty(row['status']),
    );
  }
}

/// The DRRM list, loaded once from the server (owner, 2026-10-28/29): the
/// app, the website and imports all use the same list, so the app keeps no
/// copy of its own. A form that cannot load it keeps the occupation it has.
class LivelihoodService {
  LivelihoodService._();

  static List<LivelihoodGroup>? _groups;
  static Future<List<LivelihoodGroup>>? _loading;

  static List<LivelihoodGroup> get groups => _groups ?? const [];

  static Future<List<LivelihoodGroup>> load({bool refresh = false}) {
    if (!refresh && _groups != null) return Future.value(_groups);
    if (!refresh && _loading != null) return _loading!;
    final loading = () async {
      final res = await api.get('/livelihood-classes');
      final rows = JsonRead.rows(res.list, LivelihoodGroup.fromApi);
      _groups = rows;
      return rows;
    }();
    _loading = loading;
    return loading.whenComplete(() => _loading = null);
  }

  static LivelihoodItem? item(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final g in groups) {
      for (final i in g.items) {
        if (i.code == code) return i;
      }
    }
    return null;
  }

  /// Tests only.
  static void reset() {
    _groups = null;
    _loading = null;
  }
}
