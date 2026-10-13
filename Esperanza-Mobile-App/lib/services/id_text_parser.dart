/// Reads what a Philippine ID says out of the text found on photos of its
/// front and back (owner, 2026-10-13). A best guess the resident always
/// checks and corrects before anything is saved: printed layouts differ by
/// issue, and text found on a phone photo has misreads. Plain Dart, so it is
/// tested without a phone; IdTextReader feeds it.
class IdReading {
  const IdReading({this.idNumber, this.holderName, this.birthdate, this.expiresOn, this.sex, this.address, this.extras = const {}});

  final String? idNumber;
  final String? holderName;
  final DateTime? birthdate;
  final DateTime? expiresOn;

  /// 'Male' or 'Female'.
  final String? sex;
  final String? address;

  /// The kind's own fields, keyed as WalletIdDesign names them.
  final Map<String, String> extras;

  bool get isEmpty =>
      idNumber == null && holderName == null && birthdate == null && expiresOn == null && sex == null && address == null && extras.isEmpty;
}

class IdTextParser {
  IdTextParser._();

  static IdReading parse(String kind, String front, String back) {
    final lines = '$front\n$back'
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final upper = lines.map((l) => l.toUpperCase()).toList();
    final all = upper.join('\n');

    final mrz = kind == 'passport' ? _mrz(upper) : null;

    final extras = <String, String>{};
    void put(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) extras[key] = value.trim();
    }

    put('blood_type', _bloodType(upper));
    put('civil_status', _match(_after(upper, const ['CIVIL STATUS', 'MARITAL STATUS', 'KATAYUANG SIBIL']), r'SINGLE|MARRIED|WIDOWED|WIDOW|SEPARATED|ANNULLED|DIVORCED'));
    put('place_of_birth', _title(_after(upper, const ['PLACE OF BIRTH', 'LUGAR NG KAPANGANAKAN'])));
    put('nationality', mrz?.nationality ?? _title(_after(upper, const ['NATIONALITY', 'NASYONALIDAD'])) ?? (all.contains('FILIPINO') ? 'Filipino' : null));
    put('restrictions', _after(upper, const ['RESTRICTION', 'DL CODES', 'DL CODE', 'AGENCY CODE'])?.replaceAll(RegExp(r'[^A-Z0-9, ]'), '').trim());
    put('conditions', _after(upper, const ['CONDITION']));
    put('profession', _title(_after(upper, const ['PROFESSION'])));
    put('precinct', _after(upper, const ['PRECINCT']));
    put('destination_country', _title(_after(upper, const ['JOBSITE', 'COUNTRY OF DESTINATION', 'DESTINATION'])));
    final registered = _dateNear(upper, const ['REGISTRATION DATE', 'DATE OF REGISTRATION', 'REGISTERED']);
    if (registered != null) put('registered_on', _iso(registered));

    return IdReading(
      idNumber: mrz?.number ?? _number(kind, upper, all),
      holderName: mrz?.name ?? _name(upper),
      birthdate: mrz?.birthdate ?? _dateNear(upper, const ['DATE OF BIRTH', 'BIRTH DATE', 'BIRTHDATE', 'DOB', 'PETSA NG KAPANGANAKAN', 'KAPANGANAKAN']),
      expiresOn: mrz?.expires ?? _dateNear(upper, const ['EXPIRATION', 'EXPIRY', 'EXPIRES', 'VALID UNTIL', 'VALIDITY', 'VALID THRU', 'DATE OF EXPIRY']),
      sex: mrz?.sex ?? _sex(upper),
      address: _title(_after(upper, const ['ADDRESS', 'TIRAHAN'], takeNext: 2)),
      extras: extras,
    );
  }

  // ----------------------------------------------------------- numbers

  static const _patterns = <String, List<String>>{
    'philippine_national_id': [r'\b\d{4}[- ]\d{4}[- ]\d{4}[- ]\d{4}\b', r'\b\d{16}\b'],
    'drivers_license': [r'\b[A-Z]\d{2}[- ]?\d{2}[- ]?\d{6}\b'],
    'passport': [r'\b[A-Z]{1,2}\d{6,7}[A-Z]?\b'],
    'umid': [r'\bCRN[- :]*\d{4}[- ]?\d{7}[- ]?\d\b', r'\b\d{4}-\d{7}-\d\b'],
    'sss': [r'\b\d{2}-\d{7}-\d\b', r'\b\d{10}\b'],
    'gsis': [r'\b\d{11}\b', r'\bCRN[- :]*\d{4}[- ]?\d{7}[- ]?\d\b'],
    'philhealth': [r'\b\d{2}-\d{9}-\d\b', r'\b\d{12}\b'],
    'tin': [r'\b\d{3}-\d{3}-\d{3}(?:-\d{3,5})?\b'],
    'prc': [r'\b\d{7}\b'],
    'postal': [r'\b\d{12} ?[A-Z]\b'],
    'voters': [r'\b\d{4}-\d{4}[A-Z]-[A-Z0-9]{8,}\b'],
  };

  static const _numberLabels = ['ID NO', 'ID NUMBER', 'LICENSE NO', 'CARD NO', 'NUMBER', 'NO.', 'PCN', 'CRN', 'PIN', 'TIN', 'PRN', 'VIN', 'SS NO', 'REG NO', 'REGISTRATION NO'];

  static String? _number(String kind, List<String> upper, String all) {
    // Dates look like numbers: keep them out.
    final text = all.replaceAll(_datePattern, ' ');
    for (final p in _patterns[kind] ?? const <String>[]) {
      final m = RegExp(p).firstMatch(text);
      if (m != null) return m.group(0)!.replaceFirst(RegExp(r'^CRN[- :]*'), '');
    }
    // Other kinds, or a layout the patterns miss: what follows a number label.
    final labelled = _after(upper, _numberLabels);
    final token = labelled == null ? null : RegExp(r'[A-Z0-9][A-Z0-9 \-]{4,}[0-9A-Z]').firstMatch(labelled)?.group(0);
    if (token != null && RegExp(r'\d').hasMatch(token)) return token.trim();
    final generic = RegExp(r'\b(?=[A-Z0-9-]*\d{4})[A-Z0-9][A-Z0-9-]{5,24}\b').firstMatch(text);
    return generic?.group(0);
  }

  // ------------------------------------------------------------- names

  static const _surname = ['LAST NAME', 'SURNAME', 'APELYIDO'];
  static const _given = ['GIVEN NAMES', 'GIVEN NAME', 'FIRST NAME', 'MGA PANGALAN', 'PANGALAN'];
  static const _middle = ['MIDDLE NAME', 'GITNANG APELYIDO'];
  static const _labelWords = [..._surname, ..._given, ..._middle, 'NAME', 'NAMES'];

  static String? _name(List<String> upper) {
    // "LAST NAME, FIRST NAME, MIDDLE NAME" over "DELA CRUZ, JUAN PEDRO".
    for (var i = 0; i < upper.length - 1; i++) {
      final l = upper[i];
      if (l.contains('LAST') && l.contains('FIRST') && l.contains(',')) {
        final v = upper[i + 1];
        if (v.contains(',') && !_hasDigit(v)) {
          final parts = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (parts.length >= 2) return _title('${parts.sublist(1).join(' ')} ${parts.first}');
        }
      }
    }
    final last = _nameAfter(upper, _surname);
    final given = _nameAfter(upper, _given);
    final middle = _nameAfter(upper, _middle);
    if (last != null && given != null) return _title([given, ?middle, last].join(' '));
    final whole = _nameAfter(upper, const ['NAME']);
    if (whole != null) {
      if (whole.contains(',')) {
        final parts = whole.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (parts.length >= 2) return _title('${parts.sublist(1).join(' ')} ${parts.first}');
      }
      return _title(whole);
    }
    return null;
  }

  static String? _nameAfter(List<String> upper, List<String> labels) {
    final v = _after(upper, labels, strip: _labelWords);
    if (v == null || _hasDigit(v)) return null;
    final cleaned = v.replaceAll(RegExp(r"[^A-ZÑ .,'-]"), '').trim();
    return cleaned.length < 2 ? null : cleaned;
  }

  // ------------------------------------------------------------- dates

  static final _datePattern = RegExp(
    r'\b\d{4}[/.-]\d{1,2}[/.-]\d{1,2}\b|\b\d{1,2}[/.-]\d{1,2}[/.-]\d{4}\b|'
    r'\b(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z]*\.? \d{1,2},? \d{4}\b|'
    r'\b\d{1,2} (?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z]*\.?,? \d{4}\b',
  );

  static const _months = {'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6, 'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12};

  static DateTime? _date(String s) {
    final m = _datePattern.firstMatch(s);
    if (m == null) return null;
    final t = m.group(0)!;
    DateTime? make(int y, int mo, int d) {
      if (y < 1900 || y > 2100 || mo < 1 || mo > 12 || d < 1 || d > 31) return null;
      final dt = DateTime(y, mo, d);
      return dt.month == mo ? dt : null;
    }

    var g = RegExp(r'^(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})$').firstMatch(t);
    if (g != null) return make(int.parse(g[1]!), int.parse(g[2]!), int.parse(g[3]!));
    g = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$').firstMatch(t);
    // Philippine IDs print month first.
    if (g != null) return make(int.parse(g[3]!), int.parse(g[1]!), int.parse(g[2]!));
    g = RegExp(r'^([A-Z]{3})[A-Z]*\.? (\d{1,2}),? (\d{4})$').firstMatch(t);
    if (g != null) return make(int.parse(g[3]!), _months[g[1]] ?? 0, int.parse(g[2]!));
    g = RegExp(r'^(\d{1,2}) ([A-Z]{3})[A-Z]*\.?,? (\d{4})$').firstMatch(t);
    if (g != null) return make(int.parse(g[3]!), _months[g[2]] ?? 0, int.parse(g[1]!));
    return null;
  }

  static DateTime? _dateNear(List<String> upper, List<String> labels) {
    for (var i = 0; i < upper.length; i++) {
      final at = _labelAt(upper[i], labels);
      if (at == null) continue;
      for (final candidate in [upper[i].substring(at), if (i + 1 < upper.length) upper[i + 1], if (i + 2 < upper.length) upper[i + 2]]) {
        final d = _date(candidate);
        if (d != null) return d;
      }
    }
    return null;
  }

  // ---------------------------------------------------- the rest

  static String? _sex(List<String> upper) {
    final v = _after(upper, const ['SEX', 'KASARIAN']);
    final word = v == null ? null : RegExp(r'\b(MALE|FEMALE|LALAKI|BABAE|M|F)\b').firstMatch(v)?.group(1);
    final found = word ?? RegExp(r'\b(MALE|FEMALE)\b').firstMatch(upper.join(' '))?.group(1);
    return switch (found) {
      'M' || 'MALE' || 'LALAKI' => 'Male',
      'F' || 'FEMALE' || 'BABAE' => 'Female',
      _ => null,
    };
  }

  static String? _bloodType(List<String> upper) {
    // On the label's line, or the next: on a column header ("BLOOD TYPE
    // EYES COLOR") the value is on the line below.
    final pattern = RegExp(r'\b(AB|A|B|O)(?:\s?([+-]|POS\b|NEG\b)|\b)');
    RegExpMatch? m;
    for (var i = 0; i < upper.length && m == null; i++) {
      final at = _labelAt(upper[i], const ['BLOOD TYPE', 'URI NG DUGO', 'BLOOD']);
      if (at == null) continue;
      m = pattern.firstMatch(upper[i].substring(at)) ?? (i + 1 < upper.length ? pattern.firstMatch(upper[i + 1]) : null);
    }
    if (m == null) return null;
    final sign = switch (m.group(2)) { '+' || 'POS' => '+', '-' || 'NEG' => '-', _ => '' };
    return '${m.group(1)}$sign';
  }

  /// The text after the first of [labels] on its line, or the next line(s)
  /// when the label stands alone (as it does on most cards).
  static String? _after(List<String> upper, List<String> labels, {int takeNext = 1, List<String> strip = const []}) {
    for (var i = 0; i < upper.length; i++) {
      final at = _labelAt(upper[i], labels);
      if (at == null) continue;
      var rest = upper[i].substring(at);
      for (final s in strip) {
        rest = rest.replaceAll(s, ' ');
      }
      rest = rest.replaceAll(RegExp(r'^[\s:/.\-|]+'), '').trim();
      if (rest.length >= 2) return rest;
      final next = [for (var j = i + 1; j < upper.length && j <= i + takeNext; j++) upper[j]]
          .where((l) => _labelAt(l, _allLabels) == null)
          .join(', ');
      return next.trim().isEmpty ? null : next.trim();
    }
    return null;
  }

  static const _allLabels = [
    ..._labelWords, 'DATE OF BIRTH', 'BIRTH', 'SEX', 'ADDRESS', 'NATIONALITY', 'BLOOD', 'EXPIR', 'VALID', 'CIVIL STATUS',
    'PLACE OF BIRTH', 'RESTRICTION', 'CONDITION', 'PROFESSION', 'PRECINCT', 'TIRAHAN', 'KASARIAN',
  ];

  /// Where the text after a label starts on [line], or null without one.
  static int? _labelAt(String line, List<String> labels) {
    for (final l in labels) {
      final i = line.indexOf(l);
      if (i >= 0) return i + l.length;
    }
    return null;
  }

  static String? _match(String? v, String pattern) {
    if (v == null) return null;
    final m = RegExp(pattern).firstMatch(v);
    return m == null ? null : _title(m.group(0));
  }

  static bool _hasDigit(String s) => RegExp(r'\d').hasMatch(s);

  static String? _title(String? s) {
    if (s == null) return null;
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return null;
    return t
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------- passport

  /// The two machine-readable lines at the foot of a passport's photo page.
  static _Mrz? _mrz(List<String> upper) {
    final rows = upper.map((l) => l.replaceAll(' ', '')).where((l) => l.length >= 40 && l.contains('<')).toList();
    final i = rows.indexWhere((l) => l.startsWith('P<') || l.startsWith('P0') || l.startsWith('PO'));
    if (i < 0 || i + 1 >= rows.length) return null;
    final l1 = rows[i];
    final l2 = rows[i + 1];
    final names = l1.substring(5).split('<<');
    final surname = names.first.replaceAll('<', ' ').trim();
    final given = names.length > 1 ? names[1].replaceAll('<', ' ').trim() : '';
    DateTime? yymmdd(String s, {required bool birth}) {
      if (!RegExp(r'^\d{6}$').hasMatch(s)) return null;
      final yy = int.parse(s.substring(0, 2));
      final now = DateTime.now().year % 100;
      final year = birth ? (yy > now ? 1900 + yy : 2000 + yy) : 2000 + yy;
      final mo = int.parse(s.substring(2, 4));
      final d = int.parse(s.substring(4, 6));
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
      return DateTime(year, mo, d);
    }

    String part(int from, int to) => l2.length >= to ? l2.substring(from, to) : '';
    final sexChar = part(20, 21);
    return _Mrz(
      number: part(0, 9).replaceAll('<', '').isEmpty ? null : part(0, 9).replaceAll('<', ''),
      nationality: part(10, 13) == 'PHL' ? 'Filipino' : null,
      birthdate: yymmdd(part(13, 19), birth: true),
      sex: sexChar == 'M' ? 'Male' : (sexChar == 'F' ? 'Female' : null),
      expires: yymmdd(part(21, 27), birth: false),
      name: _title([given, surname].where((s) => s.isNotEmpty).join(' ')),
    );
  }
}

class _Mrz {
  const _Mrz({this.number, this.nationality, this.birthdate, this.sex, this.expires, this.name});

  final String? number;
  final String? nationality;
  final DateTime? birthdate;
  final String? sex;
  final DateTime? expires;
  final String? name;
}
