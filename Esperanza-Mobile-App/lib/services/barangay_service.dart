import 'api_client.dart';
import 'json_read.dart';
import 'mock_catalog.dart';

/// One past leader in a barangay's history.
class BarangayLeader {
  const BarangayLeader({required this.name, this.title, this.term});

  final String name;
  final String? title;
  final String? term;
}

/// A landmark or point of interest in a barangay.
class BarangayLandmark {
  const BarangayLandmark({required this.name, this.location, this.note});

  final String name;
  final String? location;
  final String? note;
}

/// One member of the barangay's officials and staff.
class BarangayOfficial {
  const BarangayOfficial({required this.name, this.position, this.committee, this.photoUrl});

  final String name;
  final String? position;
  final String? committee;
  final String? photoUrl;
}

/// The barangay's story, where the LGU has written it.
class BarangayHistory {
  const BarangayHistory({
    this.founding,
    this.renaming,
    this.today,
    this.leadership = const [],
    this.landmarks = const [],
  });

  final String? founding;
  final String? renaming;
  final String? today;
  final List<BarangayLeader> leadership;
  final List<BarangayLandmark> landmarks;

  bool get isEmpty =>
      founding == null && renaming == null && today == null && leadership.isEmpty && landmarks.isEmpty;

  static BarangayHistory? fromApi(Object? raw) {
    final m = JsonRead.map(raw);
    if (m == null) return null;
    final h = BarangayHistory(
      founding: JsonRead.nonEmpty(m['founding']),
      renaming: JsonRead.nonEmpty(m['renaming']),
      today: JsonRead.nonEmpty(m['today']),
      leadership: JsonRead.rows(m['leadership'], (l) {
        final name = JsonRead.nonEmpty(l['name']);
        if (name == null) return null;
        return BarangayLeader(name: name, title: JsonRead.nonEmpty(l['title']), term: JsonRead.nonEmpty(l['term']));
      }),
      landmarks: JsonRead.rows(m['landmarks'], (l) {
        final name = JsonRead.nonEmpty(l['name']);
        if (name == null) return null;
        return BarangayLandmark(
          name: name,
          location: JsonRead.nonEmpty(l['location']),
          note: JsonRead.nonEmpty(l['note']),
        );
      }),
    );
    return h.isEmpty ? null : h;
  }
}

/// A barangay as the server keeps it (public GET /barangays,
/// CatalogController::barangays): its officials, contact, seal, and - where
/// the LGU has written them - its history and full officials roster, the same
/// profile the website's directory shows (parity, 2026-10-15).
class BarangayInfo {
  const BarangayInfo({
    required this.name,
    this.captain,
    this.secretary,
    this.contact,
    this.sealUrl,
    this.history,
    this.roster = const [],
  });

  final String name;
  final String? captain;
  final String? secretary;
  final String? contact;

  /// The seal on the website, as a full address; null when the server has
  /// no website address configured.
  final String? sealUrl;
  final BarangayHistory? history;
  final List<BarangayOfficial> roster;

  bool get hasProfile => history != null || roster.isNotEmpty;

  bool matches(String q) => [name, captain].any((s) => s != null && s.toLowerCase().contains(q));

  static BarangayInfo? fromApi(Map<String, dynamic> m) {
    final name = JsonRead.nonEmpty(m['name']);
    if (name == null) return null;
    // The names may come only inside `officials`, as the website reads them
    // (staging 2026-10-22: the top-level fields were empty).
    final officials = JsonRead.map(m['officials']);
    return BarangayInfo(
      name: name,
      captain: JsonRead.nonEmpty(m['punong_barangay']) ?? JsonRead.nonEmpty(officials?['punong_barangay']),
      secretary: JsonRead.nonEmpty(m['barangay_secretary']) ?? JsonRead.nonEmpty(officials?['barangay_secretary']),
      contact: JsonRead.nonEmpty(m['contact']),
      sealUrl: JsonRead.nonEmpty(m['seal_url']),
      history: BarangayHistory.fromApi(m['history']),
      roster: JsonRead.rows(m['officials_roster'], (o) {
        final name = JsonRead.nonEmpty(o['name']);
        if (name == null) return null;
        return BarangayOfficial(
          name: name,
          position: JsonRead.nonEmpty(o['position']),
          committee: JsonRead.nonEmpty(o['committee']),
          photoUrl: JsonRead.nonEmpty(o['photo_url']),
        );
      }),
    );
  }
}

/// The canonical barangays, from the server (parity, 2026-10-15: every
/// barangay picker in the app used a list built into the app; the website
/// reads GET /barangays). Loaded once and kept for the session; until it
/// arrives, or if it cannot be read, the built-in list - the same 20 names -
/// stands in, so a form never waits on it.
class BarangayService {
  BarangayService._();

  static List<BarangayInfo>? _all;
  static Future<List<BarangayInfo>>? _loading;

  /// The names for a picker: the server's when loaded, else the built-in list.
  static List<String> get names {
    final all = _all;
    return all == null || all.isEmpty ? MockCatalog.barangays : [for (final b in all) b.name];
  }

  /// Every barangay with its profile. [refresh] reads the server again.
  static Future<List<BarangayInfo>> load({bool refresh = false}) {
    if (!refresh && _all != null) return Future.value(_all);
    if (!refresh && _loading != null) return _loading!;
    final loading = () async {
      final res = await api.get('/barangays');
      final rows = JsonRead.rows(res.list, BarangayInfo.fromApi)..sort((a, b) => a.name.compareTo(b.name));
      _all = rows;
      return rows;
    }();
    _loading = loading;
    return loading.whenComplete(() => _loading = null);
  }

  /// Starts loading without waiting, and never throws: the pickers fall back.
  static Future<void> warmUp() async {
    try {
      await load();
    } catch (_) {
      // The built-in list stands in.
    }
  }

  /// Tests only.
  static void reset() {
    _all = null;
    _loading = null;
  }
}
