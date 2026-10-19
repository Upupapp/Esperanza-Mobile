import 'dart:convert';
import 'dart:math' as math;

/// Reads what a Philippine ID says out of the text found on photos of its
/// front and back (owner, 2026-10-13). A best guess the resident always
/// checks and corrects before anything is saved: printed layouts differ by
/// issue, and text found on a phone photo has misreads. Plain Dart, so it is
/// tested without a phone; IdTextReader feeds it.
///
/// After the owner's first tries on real cards (2026-10-14) it no longer
/// trusts "the line after a label": a value is the text beside or below its
/// label on the photo, a label read with a typo ("Middlie Name") is still a
/// label and never a name, a name must look like one (not a line of fine
/// print), and the National ID's QR code is read before any printed text.
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

/// A line of text found on a photo of an ID, with where it sits on that
/// photo when the reader says (the phone's reader does; plain text does not).
class IdTextLine {
  const IdTextLine(this.text, {this.left, this.top, this.right, this.bottom});

  final String text;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
}

class IdTextParser {
  IdTextParser._();

  /// From plain text, one line per row. [codes] are the QR codes found on
  /// the photos.
  static IdReading parse(String kind, String front, String back, {List<String> codes = const []}) =>
      parseLines(kind, front: _plain(front), back: _plain(back), codes: codes);

  static List<IdTextLine> _plain(String s) => [
    for (final l in s.split(RegExp(r'[\r\n]+'))) IdTextLine(l),
  ];

  static IdReading parseLines(String kind, {List<IdTextLine> front = const [], List<IdTextLine> back = const [], List<String> codes = const []}) {
    final d = _Doc([
      for (final l in front) ?_Line.of(l, 0),
      for (final l in back) ?_Line.of(l, 1),
    ]);

    final mrz = kind == 'passport' ? _mrz(d.upper) : null;
    final qr = kind == 'philippine_national_id' ? _philSysQr(codes) : null;

    final extras = <String, String>{};
    void put(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) extras[key] = value.trim();
    }

    put('blood_type', _bloodType(d));
    put('civil_status', _match(_after(d, const ['CIVIL STATUS', 'MARITAL STATUS', 'KALAGAYANG SIBIL', 'KATAYUANG SIBIL']), r'SINGLE|MARRIED|WIDOWED|WIDOW|SEPARATED|ANNULLED|DIVORCED'));
    put('place_of_birth', qr?.placeOfBirth ?? _title(_after(d, const ['PLACE OF BIRTH', 'LUGAR NG KAPANGANAKAN'])));
    put('nationality', mrz?.nationality ?? _title(_after(d, const ['NATIONALITY', 'NASYONALIDAD'])) ?? (d.all.contains('FILIPINO') ? 'Filipino' : null));
    put('restrictions', _after(d, const ['RESTRICTION', 'DL CODES', 'DL CODE', 'AGENCY CODE'])?.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9, ]'), '').trim());
    put('conditions', _after(d, const ['CONDITION'])?.toUpperCase());
    put('profession', _title(_after(d, const ['PROFESSION'])));
    put('precinct', _after(d, const ['PRECINCT'])?.toUpperCase());
    put('destination_country', _title(_after(d, const ['JOBSITE', 'COUNTRY OF DESTINATION', 'DESTINATION'])));
    final registered = _dateNear(d, const ['REGISTRATION DATE', 'DATE OF REGISTRATION', 'REGISTERED']);
    if (registered != null) put('registered_on', _iso(registered));

    final number = qr?.number ?? mrz?.number ?? _number(kind, d);
    final expires = mrz?.expires ?? _dateNear(d, _expiryLabels);
    return IdReading(
      idNumber: number,
      holderName: qr?.name ?? mrz?.name ?? _name(d, number),
      birthdate: qr?.birthdate ?? mrz?.birthdate ?? _dateNear(d, _birthLabels) ?? _onlyOldDate(d, expires),
      expiresOn: expires,
      sex: qr?.sex ?? mrz?.sex ?? _sex(d),
      address: _title(_after(d, const ['ADDRESS', 'TIRAHAN'], takeNext: 2)),
      extras: extras,
    );
  }

  static const _birthLabels = ['DATE OF BIRTH', 'BIRTH DATE', 'BIRTHDATE', 'DOB', 'PETSA NG KAPANGANAKAN', 'KAPANGANAKAN'];
  static const _expiryLabels = ['EXPIRATION', 'EXPIRY', 'EXPIRES', 'VALID UNTIL', 'VALIDITY', 'VALID THRU', 'DATE OF EXPIRY'];

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

  static String? _number(String kind, _Doc d) {
    // Dates look like numbers: keep them out.
    final text = d.all.replaceAll(_datePattern, ' ');
    // As printed, then with the letters a phone mistakes for digits (O for
    // 0, I for 1) put right inside runs that are mostly digits.
    for (final t in [text, _digitsFixed(text)]) {
      for (final p in _patterns[kind] ?? const <String>[]) {
        final m = RegExp(p).firstMatch(t);
        if (m != null) return m.group(0)!.replaceFirst(RegExp(r'^CRN[- :]*'), '');
      }
    }
    // Other kinds, or a layout the patterns miss: what is printed by a number label.
    final token = RegExp(r'[A-Z0-9][A-Z0-9 \-]{4,}[0-9A-Z]');
    final labelled = _after(d, _numberLabels, accept: (v) => token.firstMatch(v.toUpperCase())?.group(0)?.contains(RegExp(r'\d')) ?? false);
    if (labelled != null) return token.firstMatch(labelled.toUpperCase())!.group(0)!.trim();
    final generic = RegExp(r'\b(?=[A-Z0-9-]*\d{4})[A-Z0-9][A-Z0-9-]{5,24}\b').firstMatch(text);
    return generic?.group(0);
  }

  static String _digitsFixed(String text) => text.replaceAllMapped(RegExp(r'[0-9OIDSBZ][0-9OIDSBZ -]{6,}[0-9OIDSBZ]'), (m) {
    final run = m.group(0)!;
    final digits = run.replaceAll(RegExp(r'\D'), '').length;
    final letters = run.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (letters == 0 || digits < letters * 3) return run;
    return run
        .replaceAll(RegExp('[OD]'), '0')
        .replaceAll('I', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('Z', '2');
  });

  // ------------------------------------------------------------- names

  static const _surname = ['LAST NAME', 'SURNAME', 'APELYIDO'];
  static const _given = ['GIVEN NAMES', 'GIVEN NAME', 'FIRST NAME', 'MGA PANGALAN', 'PANGALAN'];
  static const _middle = ['MIDDLE NAME', 'GITNANG APELYIDO'];

  static String? _name(_Doc d, String? number) {
    // "LAST NAME, FIRST NAME, MIDDLE NAME" over "DELA CRUZ, JUAN PEDRO".
    for (var i = 0; i < d.lines.length; i++) {
      final n = d.lines[i].norm;
      if (_labelEnd(n, _surname) == null || _labelEnd(n, _given) == null || !n.contains(',')) continue;
      for (final j in d.followers(i).take(1)) {
        final v = d.lines[j].raw;
        if (v.contains(',') && _nameish(v)) return _commaName(v);
      }
    }
    // One label per part, as on the National ID. A line naming another
    // part ("LAST NAME, FIRST NAME") is not this part's label.
    bool only(_Line l, List<List<String>> others) => others.every((o) => _labelEnd(l.norm, o) == null);
    final last = _after(d, _surname, accept: _nameish, where: (l) => only(l, [_given, _middle]));
    final given = _after(d, _given, accept: _nameish, where: (l) => only(l, [_surname, _middle]));
    final middle = _after(d, _middle, accept: _nameish, where: (l) => only(l, [_surname, _given]));
    if (last != null && given != null) return _title([given, ?middle, last].join(' '));

    // "NAME" on its own: a label line, or a line that starts with it. Not
    // "Signature over printed name" in the fine print.
    final whole = _after(
      d,
      const ['NAME'],
      accept: _nameish,
      where: (l) => only(l, [_surname, _given, _middle]) && (_onlyLabelWords(l.norm) || RegExp(r'^\W*NAME\b').hasMatch(l.norm) || RegExp(r'\bNAME\s*:').hasMatch(l.norm)),
    );
    if (whole != null) return whole.contains(',') ? _commaName(whole) : _title(whole);

    // No label at all, as on a PhilHealth card: the name-shaped line nearest
    // the number.
    final near = _nameNearNumber(d, number);
    if (near != null) return near.contains(',') ? _commaName(near) : _title(near);
    if (given != null) return _title([given, ?middle].join(' '));
    return _title(last);
  }

  static String? _nameNearNumber(_Doc d, String? number) {
    if (number == null) return null;
    final key = number.replaceAll(RegExp(r'[\s-]'), '');
    final at = d.lines.indexWhere((l) => l.upper.replaceAll(RegExp(r'[\s-]'), '').contains(key));
    if (at < 0) return null;
    final anchor = d.lines[at];
    final address = <int>{
      for (var i = 0; i < d.lines.length; i++)
        if (_labelEnd(d.lines[i].norm, const ['ADDRESS', 'TIRAHAN']) != null) ...d.followers(i).take(2),
    };
    String? best;
    var bestScore = double.infinity;
    for (var j = 0; j < d.lines.length; j++) {
      final l = d.lines[j];
      if (j == at || l.side != anchor.side || address.contains(j) || _isLabelLine(l) || !_nameish(l.raw, strict: true)) continue;
      final double distance;
      if (anchor.hasBox && l.hasBox) {
        distance = (l.cy - anchor.cy).abs() / anchor.h;
        if (distance > 5) continue;
      } else {
        distance = (j - at).abs().toDouble();
        if (distance > 3) continue;
      }
      // "SURNAME, GIVEN MIDDLE" is how these cards print it; below the
      // number more often than above.
      final score = distance + (l.raw.contains(',') ? 0 : 0.5) + (j < at ? 0.25 : 0);
      if (score < bestScore) {
        bestScore = score;
        best = l.raw;
      }
    }
    return best;
  }

  static String? _commaName(String v) {
    final parts = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.length < 2) return _title(v.replaceAll(',', ' '));
    return _title('${parts.sublist(1).join(' ')} ${parts.first}');
  }

  /// Words that are never part of a person's name on a card: the card's own
  /// headings, its fine print, places.
  static const _notNameWords = {
    'THE', 'OF', 'IF', 'IS', 'IN', 'ON', 'THIS', 'THAT', 'BE', 'ARE', 'MAY', 'WILL', 'SHALL', 'MUST', 'AND', 'OR', 'FOR', 'TO',
    'WITH', 'BY', 'AT', 'AN', 'NOT', 'NON', 'ANY', 'ALL', 'CARD', 'SIGNATURE', 'SIGNATURES', 'SIGNED', 'APPLY', 'APPLIES', 'FOUND',
    'RETURN', 'PLEASE', 'PROPERTY', 'REPUBLIC', 'REPUBLIKA', 'PHILIPPINES', 'PILIPINAS', 'PHILIPPINE', 'VALID', 'MEMBER',
    'MEMBERSHIP', 'HEALTH', 'INSURANCE', 'CORPORATION', 'PHILHEALTH', 'NATIONAL', 'PAMBANSANG', 'PAGKAKAKILANLAN',
    'IDENTIFICATION', 'IDENTITY', 'ID', 'SYSTEM', 'SECURITY', 'SOCIAL', 'LICENSE', 'DRIVER', "DRIVER'S", 'AUTHORITY', 'OFFICE',
    'DEPARTMENT', 'BUREAU', 'COMMISSION', 'TRANSFERABLE', 'NON-TRANSFERABLE', 'HOLDER', 'OWNER', 'ISSUED', 'ISSUE', 'PRINTED',
    'OVER', 'USE', 'USED', 'GOVERNMENT', 'AGENCY', 'PUROK', 'BARANGAY', 'BRGY', 'STREET', 'CITY', 'PROVINCE', 'MUNICIPALITY',
    'SITIO', 'SUBD', 'VILLAGE', 'LTO', 'GSIS', 'SSS', 'UMID', 'PHLPOST', 'COMELEC', 'VOTER', "VOTER'S", 'PRC', 'PROFESSIONAL',
    'REGULATION', 'BIR', 'TAXPAYER', 'MALE', 'FEMALE', 'PIN', 'PCN', 'TIN', 'CRN', 'NO', 'NUMBER', 'DATE', 'BIRTH', 'ADDRESS', 'SEX',
  };

  /// Whether [s] could be a person's name, or part of one. [strict] (for a
  /// line found without a label) also wants it in capitals, as cards print
  /// names.
  static bool _nameish(String s, {bool strict = false}) {
    final t = s.trim();
    if (t.length < 2 || _hasDigit(t) || RegExp(r"[^A-Za-zÑñ .,'\-]").hasMatch(t)) return false;
    if (','.allMatches(t).length > 1) return false;
    final words = t.split(RegExp(r'[\s,]+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 6) return false;
    for (final w in words) {
      final up = w.toUpperCase().replaceAll(RegExp(r'^[.\-]+|[.\-]+$'), '');
      if (_notNameWords.contains(up) || _nameLabelWords.contains(_Vocab.fix(up))) return false;
    }
    final letters = t.replaceAll(RegExp(r'[^A-Za-zÑñ]'), '');
    final caps = letters.replaceAll(RegExp(r'[^A-ZÑ]'), '').length;
    if (strict) return letters.length >= 4 && caps >= letters.length * 0.8;
    // Labelled: in capitals, or every longer word capitalised. A sentence
    // ("the signatures may apply") is neither.
    return caps >= letters.length * 0.8 || words.where((w) => w.length >= 3).every((w) => RegExp('^[A-ZÑ]').hasMatch(w));
  }

  static const _nameLabelWords = {'NAME', 'NAMES', 'SURNAME', 'MIDDLE', 'GIVEN', 'FIRST', 'APELYIDO', 'GITNANG', 'PANGALAN'};

  // ------------------------------------------------------------- dates

  static final _datePattern = RegExp(
    r'\b\d{4}[/.-]\d{1,2}[/.-]\d{1,2}\b|\b\d{1,2}[/.-]\d{1,2}[/.-]\d{4}\b|'
    r'\b(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z]*\.? \d{1,2},? \d{4}\b|'
    r'\b\d{1,2} (?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|SEPT|OCT|NOV|DEC)[A-Z]*\.?,? \d{4}\b',
  );

  static const _months = {'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6, 'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12};

  static DateTime? _date(String s) {
    final m = _datePattern.firstMatch(s.toUpperCase());
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

  static DateTime? _dateNear(_Doc d, List<String> labels) {
    for (var i = 0; i < d.lines.length; i++) {
      final line = d.lines[i];
      final at = _labelEnd(line.norm, labels);
      if (at == null) continue;
      final found = _date(line.cut(at)) ?? _firstIn(d, i, 2, _date);
      if (found != null) return found;
    }
    return null;
  }

  /// A card with no birth-date label (as some PhilHealth cards): its only
  /// date, when that is at least ten years ago and not the expiry.
  static DateTime? _onlyOldDate(_Doc d, DateTime? expires) {
    final dates = <DateTime>{
      for (final m in _datePattern.allMatches(d.all)) ?_date(m.group(0)!),
    }..remove(expires);
    if (dates.length != 1) return null;
    final only = dates.single;
    return only.isBefore(DateTime.now().subtract(const Duration(days: 3650))) ? only : null;
  }

  // ---------------------------------------------------- the rest

  static String? _sex(_Doc d) {
    final word = RegExp(r'\b(MALE|FEMALE|LALAKI|BABAE|M|F)\b');
    String? found;
    for (var i = 0; i < d.lines.length && found == null; i++) {
      final at = _labelEnd(d.lines[i].norm, const ['SEX', 'KASARIAN']);
      if (at == null) continue;
      // Beside the label only when it comes first ("SEX: F"), not a column
      // header's "HEIGHT(M)"; or on the line below.
      found = RegExp(r'^[\s:/.\-|]*(MALE|FEMALE|LALAKI|BABAE|M|F)\b').firstMatch(d.lines[i].cut(at).toUpperCase())?.group(1) ??
          _firstIn(d, i, 1, (s) => word.firstMatch(s.toUpperCase())?.group(1));
    }
    found ??= RegExp(r'\b(MALE|FEMALE)\b').firstMatch(d.all)?.group(1);
    return switch (found) {
      'M' || 'MALE' || 'LALAKI' => 'Male',
      'F' || 'FEMALE' || 'BABAE' => 'Female',
      _ => null,
    };
  }

  static String? _bloodType(_Doc d) {
    // On the label's line, or the next: on a column header ("BLOOD TYPE
    // EYES COLOR") the value is on the line below.
    final pattern = RegExp(r'\b(AB|A|B|O)(?:\s?([+-]|POS\b|NEG\b)|\b)');
    RegExpMatch? m;
    for (var i = 0; i < d.lines.length && m == null; i++) {
      final at = _labelEnd(d.lines[i].norm, const ['BLOOD TYPE', 'URI NG DUGO', 'BLOOD']);
      if (at == null) continue;
      m = pattern.firstMatch(d.lines[i].cut(at).toUpperCase()) ?? _firstIn(d, i, 1, (s) => pattern.firstMatch(s.toUpperCase()));
    }
    if (m == null) return null;
    final sign = switch (m.group(2)) { '+' || 'POS' => '+', '-' || 'NEG' => '-', _ => '' };
    return '${m.group(1)}$sign';
  }

  /// The first of up to [take] lines beside or below label line [i], before
  /// another label, that [read] finds something in.
  static T? _firstIn<T>(_Doc d, int i, int take, T? Function(String) read) {
    for (final j in d.followers(i).take(take)) {
      if (_isLabelLine(d.lines[j])) return null;
      final v = read(d.lines[j].raw);
      if (v != null) return v;
    }
    return null;
  }

  /// The text by the first of [labels] that [accept] takes: after it on its
  /// line, else the line(s) beside or below it (as on most cards). A label
  /// whose value fails (fine print that happens to say "name") is passed
  /// over for the next one.
  static String? _after(_Doc d, List<String> labels, {int takeNext = 1, bool Function(String)? accept, bool Function(_Line)? where}) {
    bool ok(String s) => accept == null || accept(s);
    for (var i = 0; i < d.lines.length; i++) {
      final line = d.lines[i];
      if (where != null && !where(line)) continue;
      final at = _labelEnd(line.norm, labels);
      if (at == null) continue;
      if (!_onlyLabelWords(line.norm.substring(at))) {
        final rest = _dropLeadingLabelWords(line.cut(at));
        if (rest.length >= 2 && ok(rest)) return rest;
      }
      final next = <String>[];
      for (final j in d.followers(i).take(takeNext)) {
        if (_isLabelLine(d.lines[j])) break;
        next.add(d.lines[j].raw);
      }
      final v = next.join(', ').trim();
      if (v.isNotEmpty && ok(v)) return v;
    }
    return null;
  }

  static const _allLabels = [
    ..._surname, ..._given, ..._middle, 'NAME', 'NAMES', 'DATE OF BIRTH', 'BIRTH', 'SEX', 'ADDRESS', 'NATIONALITY', 'BLOOD', 'EXPIR',
    'VALID', 'CIVIL STATUS', 'MARITAL STATUS', 'PLACE OF BIRTH', 'RESTRICTION', 'CONDITION', 'PROFESSION', 'PRECINCT', 'TIRAHAN',
    'KASARIAN',
  ];

  static bool _isLabelLine(_Line l) => _labelEnd(l.norm, _allLabels) != null;

  /// Where the text after the last-ending of [labels] starts on [norm] (a
  /// line with misread label words put right), or null without one. A label
  /// starts a word; a short one ("PIN", "SEX") is a whole word, so "PINEDA"
  /// and "ESSEX" are not labels. "APELYIDO" after "GITNANG" is the middle
  /// name's label, not the surname's.
  static int? _labelEnd(String norm, List<String> labels) {
    int? best;
    for (final l in labels) {
      for (var i = norm.indexOf(l); i >= 0; i = norm.indexOf(l, i + 1)) {
        final end = i + l.length;
        if (i > 0 && _isLetter(norm[i - 1])) continue;
        if (l.length <= 4 && end < norm.length && _isLetter(norm[end])) continue;
        if (l == 'APELYIDO' && norm.substring(0, i).trimRight().endsWith('GITNANG')) continue;
        if (best == null || end > best) best = end;
        break;
      }
    }
    return best;
  }

  static bool _isLetter(String c) => RegExp('[A-ZÑ]').hasMatch(c);

  /// Whether [s] holds nothing but label words (and punctuation).
  static bool _onlyLabelWords(String s) =>
      RegExp('[A-ZÑ]+').allMatches(s).every((m) => _Vocab.words.contains(_Vocab.fix(m.group(0)!)));

  /// "/Middle Name: X" → "X". Two-letter words stay: "NG" is also a surname.
  static String _dropLeadingLabelWords(String s) {
    var rest = s;
    while (true) {
      rest = rest.replaceFirst(RegExp(r'^[\s:/.\-|]+'), '');
      final m = RegExp('^[A-Za-zÑñ]{3,}').firstMatch(rest);
      if (m == null || !_Vocab.words.contains(_Vocab.fix(m.group(0)!.toUpperCase()))) return rest.trim();
      final after = rest.substring(m.end);
      if (after.isNotEmpty && _isLetter(after[0].toUpperCase())) return rest.trim();
      rest = after;
    }
  }

  static String? _match(String? v, String pattern) {
    if (v == null) return null;
    final m = RegExp(pattern).firstMatch(v.toUpperCase());
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

  // ------------------------------------------------- National ID QR code

  /// The National ID's QR code holds the PCN, the name in parts, the birth
  /// date and sex exactly, as JSON ("subject": {"lName", "fName", "mName",
  /// "DOB", "sex", "PCN", ...}). Read before any printed text; a code in any
  /// other form is passed over.
  static _Qr? _philSysQr(List<String> codes) {
    for (final code in codes) {
      final start = code.indexOf('{');
      if (start < 0) continue;
      Object? json;
      try {
        json = jsonDecode(code.substring(start));
      } on FormatException {
        continue;
      }
      if (json is! Map) continue;
      final subject = json['subject'] is Map ? json['subject'] as Map : json;
      String? v(List<String> keys) {
        for (final e in subject.entries) {
          if (keys.contains(e.key.toString().toLowerCase())) {
            final s = e.value?.toString().trim();
            if (s != null && s.isNotEmpty) return s;
          }
        }
        return null;
      }

      final last = v(const ['lname', 'lastname', 'last_name', 'surname']);
      final first = v(const ['fname', 'firstname', 'first_name', 'givenname', 'givennames', 'given_name']);
      final middle = v(const ['mname', 'middlename', 'middle_name']);
      final suffix = v(const ['suffix']);
      final pcn = v(const ['pcn'])?.replaceAll(RegExp(r'\D'), '');
      final sex = v(const ['sex'])?.toUpperCase();
      final reading = _Qr(
        number: pcn != null && pcn.length == 16
            ? '${pcn.substring(0, 4)}-${pcn.substring(4, 8)}-${pcn.substring(8, 12)}-${pcn.substring(12)}'
            : null,
        name: first != null && last != null ? _title([first, ?middle, last, ?suffix].join(' ')) : null,
        birthdate: switch (v(const ['dob', 'dateofbirth', 'birthdate', 'date_of_birth'])) { final s? => _date(s), null => null },
        sex: sex == null ? null : (sex.startsWith('M') ? 'Male' : (sex.startsWith('F') ? 'Female' : null)),
        placeOfBirth: _title(v(const ['pob', 'placeofbirth', 'place_of_birth'])),
      );
      if (reading.number != null || reading.name != null) return reading;
    }
    return null;
  }

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

/// The words cards print in their labels. A word the phone misread by one
/// letter ("MIDDLIE", "APELYID0") is put right before labels are looked for;
/// the text taken as a value is always the line as read.
class _Vocab {
  static const words = {
    'LAST', 'NAME', 'NAMES', 'SURNAME', 'APELYIDO', 'GIVEN', 'FIRST', 'MGA', 'PANGALAN', 'MIDDLE', 'GITNANG', 'DATE', 'OF', 'BIRTH',
    'BIRTHDATE', 'PETSA', 'NG', 'KAPANGANAKAN', 'ADDRESS', 'TIRAHAN', 'SEX', 'KASARIAN', 'BLOOD', 'TYPE', 'URI', 'DUGO', 'MARITAL',
    'CIVIL', 'STATUS', 'KALAGAYANG', 'KATAYUANG', 'SIBIL', 'PLACE', 'LUGAR', 'NATIONALITY', 'NASYONALIDAD', 'EXPIRATION', 'EXPIRY',
    'VALID', 'UNTIL', 'ISSUE', 'REGISTRATION', 'PRECINCT', 'PROFESSION', 'RESTRICTION', 'RESTRICTIONS', 'CONDITION', 'CONDITIONS',
    'NO', 'NUMBER', 'ID', 'PCN', 'CRN', 'PIN', 'TIN', 'DOB',
  };

  static final _long = words.where((w) => w.length >= 5).toList();

  /// [token] (capitals), or the one label word of five letters or more it is
  /// a single letter away from.
  static String fix(String token) {
    if (token.length < 5 || words.contains(token)) return token;
    String? found;
    for (final w in _long) {
      if ((w.length - token.length).abs() <= 1 && _withinOne(token, w)) {
        if (found != null) return token;
        found = w;
      }
    }
    return found ?? token;
  }

  static bool _withinOne(String a, String b) {
    var i = 0;
    var j = 0;
    var edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (a.length < b.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }
}

/// One line as read, in capitals, and with label words put right (`norm`).
class _Line {
  _Line._(this.raw, this.upper, this.norm, this._toRaw, this.side, this.left, this.top, this.right, this.bottom);

  static _Line? of(IdTextLine l, int side) {
    final raw = l.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (raw.isEmpty) return null;
    final upper = raw.toUpperCase();
    final norm = StringBuffer();
    final toRaw = <int>[];
    for (final m in RegExp(r'[A-ZÑ]+|[^A-ZÑ]+').allMatches(upper)) {
      final seg = m.group(0)!;
      final fixed = _isLetters(seg) ? _Vocab.fix(seg) : seg;
      for (var k = 0; k < fixed.length; k++) {
        toRaw.add(fixed.length == seg.length ? m.start + k : (k == 0 ? m.start : m.end));
      }
      norm.write(fixed);
    }
    toRaw.add(upper.length);
    final boxed = l.left != null && l.top != null && l.right != null && l.bottom != null;
    return _Line._(
      upper.length == raw.length ? raw : upper,
      upper,
      norm.toString(),
      toRaw,
      side,
      boxed ? l.left! : 0,
      boxed ? l.top! : 0,
      boxed ? l.right! : 0,
      boxed ? l.bottom! : 0,
    );
  }

  static bool _isLetters(String s) => RegExp(r'^[A-ZÑ]+$').hasMatch(s);

  final String raw;
  final String upper;
  final String norm;
  final List<int> _toRaw;
  final int side;
  final double left;
  final double top;
  final double right;
  final double bottom;

  bool get hasBox => bottom > top && right > left;
  double get h => math.max(1, bottom - top);
  double get cy => (top + bottom) / 2;

  /// The line as read, from where [normIndex] falls in `norm`.
  String cut(int normIndex) => raw.substring(_toRaw[normIndex]);
}

class _Doc {
  _Doc(this.lines);

  final List<_Line> lines;
  late final List<String> upper = [for (final l in lines) l.upper];
  late final String all = upper.join('\n');

  /// The lines a value for label line [i] can be on, nearest first: on the
  /// photo, those to its right on the same row (not another label, as on a
  /// header row), then those below it that overlap it. Without positions,
  /// the lines that follow it.
  List<int> followers(int i) {
    final a = lines[i];
    if (!a.hasBox) return [for (var j = i + 1; j < lines.length; j++) j];
    final scored = <(int, double)>[];
    for (var j = 0; j < lines.length; j++) {
      final b = lines[j];
      if (j == i || b.side != a.side || !b.hasBox) continue;
      final h = a.h;
      if ((b.cy - a.cy).abs() < 0.6 * h && b.left >= a.right - 0.5 * h) {
        if (!IdTextParser._isLabelLine(b)) scored.add((j, (b.left - a.right).abs() / h * 0.1));
      } else if (b.top >= a.top + 0.5 * h && b.top - a.bottom <= 4 * h && b.right > a.left - h && b.left < a.right) {
        scored.add((j, 1 + (b.top - a.bottom) / h + (b.left - a.left).abs() / (4 * h)));
      }
    }
    scored.sort((x, y) => x.$2.compareTo(y.$2));
    return [for (final s in scored) s.$1];
  }
}

class _Qr {
  const _Qr({this.number, this.name, this.birthdate, this.sex, this.placeOfBirth});

  final String? number;
  final String? name;
  final DateTime? birthdate;
  final String? sex;
  final String? placeOfBirth;
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
