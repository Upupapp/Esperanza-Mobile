import 'package:intl/intl.dart';

import 'request_release.dart';

/// The document a Dokyu request is for, drawn as the website draws it: the
/// barangay certificate (barangay-certificate-preview.blade.php) or the
/// municipal request slip (municipal-request-preview.blade.php), with the
/// same wording, filled from the request's answers. Shown on the request
/// form's Review step and, once the request is approved, as "Your Document"
/// (2026-10-22, app/web parity). It is a reference copy: the signed paper is
/// released at the office.
enum DocumentKind { barangay, municipal }

class DocumentMeta {
  const DocumentMeta(
    this.key,
    this.kind,
    this.title, {
    this.subtitle,
    this.office,
    this.formNo,
    this.officiant,
    this.officiantTitle,
    this.technician,
    this.technicianTitle,
    this.verifier,
    this.verifierTitle,
    this.nameField,
    this.purposeField,
    this.purposeIsArray = false,
  });

  /// The service key (the website's docKey).
  final String key;
  final DocumentKind kind;
  final String title;
  final String? subtitle;

  /// Municipal slips: the office, its form number and named signatories.
  final String? office;
  final String? formNo;
  final String? officiant;
  final String? officiantTitle;
  final String? technician;
  final String? technicianTitle;
  final String? verifier;
  final String? verifierTitle;

  /// As the website's Track Request draws it: no form number and no
  /// signatories (its "Your Document" shows neither; only the request form's
  /// preview does).
  DocumentMeta get asIssued => DocumentMeta(
    key,
    kind,
    title,
    subtitle: subtitle,
    office: office,
    nameField: nameField,
    purposeField: purposeField,
    purposeIsArray: purposeIsArray,
  );

  /// Track Request: where the resident's name and purpose go when the form
  /// did not ask them (esperanza_document_type_lookup.php).
  final String? nameField;
  final String? purposeField;
  final bool purposeIsArray;
}

const _mcro = 'Office of the Municipal Civil Registrar';

/// The documents the website draws (config/esperanza_barangay_documents.php,
/// config/esperanza_municipal_documents.php), keyed by service key.
const documentMetas = <String, DocumentMeta>{
  'brgy_cert_death_registration': DocumentMeta(
    'brgy_cert_death_registration',
    DocumentKind.barangay,
    'BARANGAY CERTIFICATION',
    nameField: 'subject_name',
  ),
  'brgy_cert_late_registration': DocumentMeta(
    'brgy_cert_late_registration',
    DocumentKind.barangay,
    'BARANGAY CERTIFICATION',
    subtitle: 'Late Registration of Birth — for Death Registration',
    nameField: 'subject_name',
  ),
  'brgy_business_clearance': DocumentMeta(
    'brgy_business_clearance',
    DocumentKind.barangay,
    'BARANGAY BUSINESS CLEARANCE',
    nameField: 'applicant_name',
  ),
  'brgy_residency': DocumentMeta(
    'brgy_residency',
    DocumentKind.barangay,
    'BARANGAY RESIDENCY',
    nameField: 'requester_name',
    purposeField: 'purpose',
    purposeIsArray: true,
  ),
  'brgy_first_time_jobseeker': DocumentMeta(
    'brgy_first_time_jobseeker',
    DocumentKind.barangay,
    'BARANGAY CERTIFICATION',
    subtitle: 'First Time Jobseekers Assistance Act RA 11261',
    nameField: 'requester_name',
  ),
  'brgy_indigency': DocumentMeta(
    'brgy_indigency',
    DocumentKind.barangay,
    'BARANGAY INDIGENCY',
    nameField: 'requester_name',
    purposeField: 'purpose',
    purposeIsArray: true,
  ),
  'brgy_clearance': DocumentMeta(
    'brgy_clearance',
    DocumentKind.barangay,
    'BARANGAY CLEARANCE',
    nameField: 'requester_name',
    purposeField: 'purpose',
    purposeIsArray: true,
  ),
  'brgy_cert_national_id': DocumentMeta(
    'brgy_cert_national_id',
    DocumentKind.barangay,
    'BARANGAY CERTIFICATION',
    subtitle: 'For Registration of National ID',
    nameField: 'subject_name',
  ),
  'brgy_cert_land_property': DocumentMeta(
    'brgy_cert_land_property',
    DocumentKind.barangay,
    'BARANGAY CERTIFICATION',
    subtitle: 'Land / Property Ownership',
    nameField: 'owner_name',
  ),
  'brgy_cert_general': DocumentMeta(
    'brgy_cert_general',
    DocumentKind.barangay,
    'BARANGAY CERTIFICATION',
    nameField: 'subject_name',
    purposeField: 'purpose',
  ),
  'brgy_business_permit': DocumentMeta(
    'brgy_business_permit',
    DocumentKind.barangay,
    'BARANGAY BUSINESS PERMIT',
    nameField: 'proprietor_name',
  ),
  'brgy_event_permit': DocumentMeta(
    'brgy_event_permit',
    DocumentKind.barangay,
    'BARANGAY PERMIT',
    subtitle: 'Event / Special Occasion Permit',
    nameField: 'organizer_name',
  ),
  'mcro_marriage': DocumentMeta(
    'mcro_marriage',
    DocumentKind.municipal,
    'REQUEST FOR CERTIFICATE OF MARRIAGE',
    office: _mcro,
    formNo: 'Municipal Form No. 97',
    nameField: 'requester_name',
  ),
  'mcro_marriage_license': DocumentMeta(
    'mcro_marriage_license',
    DocumentKind.municipal,
    'APPLICATION FOR MARRIAGE LICENSE',
    office: _mcro,
    formNo: 'Municipal Form No. 90 (Revised January 2007)',
  ),
  'mcro_live_birth': DocumentMeta(
    'mcro_live_birth',
    DocumentKind.municipal,
    'REQUEST FOR CERTIFICATE OF LIVE BIRTH',
    office: _mcro,
    formNo: 'Municipal Form No. 102',
  ),
  'mcro_death': DocumentMeta(
    'mcro_death',
    DocumentKind.municipal,
    'REQUEST FOR CERTIFICATE OF DEATH',
    office: _mcro,
    formNo: 'Municipal Form No. 103',
  ),
  'mcro_delayed_registration': DocumentMeta(
    'mcro_delayed_registration',
    DocumentKind.municipal,
    'AFFIDAVIT FOR DELAYED REGISTRATION',
    office: _mcro,
    officiant: 'Atty. Marivic S. Ong',
    officiantTitle: 'Municipal Civil Registrar',
    nameField: 'subject_name',
  ),
  'municipal_pet_registration': DocumentMeta(
    'municipal_pet_registration',
    DocumentKind.municipal,
    'PET REGISTRATION FORM',
    office: 'Municipal Agriculture Office',
    technician: 'Antonio G. Ejes',
    technicianTitle: 'Agri. II / Livestock Coordinator',
    verifier: 'Engr. Jever L. Malaras',
    verifierTitle: 'Municipal Agriculturist',
    nameField: 'owner_name',
  ),
  'msw_pwd_id': DocumentMeta(
    'msw_pwd_id',
    DocumentKind.municipal,
    'PHILIPPINE REGISTRY FOR PERSONS WITH DISABILITY — APPLICATION FORM',
    office: 'Municipal Social Welfare & Development Office',
    formNo: 'DOH PRPWD Version 3.0',
    nameField: 'full_name',
  ),
  'osca_senior_citizen': DocumentMeta(
    'osca_senior_citizen',
    DocumentKind.municipal,
    'APPLICATION FOR MEMBERSHIP',
    office: 'Office of Senior Citizens Affairs',
    nameField: 'full_name',
  ),
  'locational_clearance': DocumentMeta(
    'locational_clearance',
    DocumentKind.municipal,
    'APPLICATION FOR LOCATIONAL CLEARANCE',
    office: 'Municipal Planning & Development Office',
  ),
  'dokyu_cedula': DocumentMeta(
    'dokyu_cedula',
    DocumentKind.municipal,
    'CEDULA (COMMUNITY TAX CERTIFICATE)',
    office: "Municipal Treasurer's Office",
    nameField: 'full_name',
  ),
  'dokyu_residency': DocumentMeta(
    'dokyu_residency',
    DocumentKind.municipal,
    'CERTIFICATE OF RESIDENCY',
    office: _mcro,
    nameField: 'requester_name',
    purposeField: 'purpose',
  ),
  'dokyu_indigency': DocumentMeta(
    'dokyu_indigency',
    DocumentKind.municipal,
    'CERTIFICATE OF INDIGENCY',
    office: 'Municipal Social Welfare & Development Office',
    nameField: 'requester_name',
    purposeField: 'purpose',
  ),
  'dokyu_business_new': DocumentMeta(
    'dokyu_business_new',
    DocumentKind.municipal,
    'BUSINESS PERMIT (NEW APPLICATION)',
    office: 'Business Permits & Licensing Office',
    nameField: 'applicant_name',
  ),
  'dokyu_business_renewal': DocumentMeta(
    'dokyu_business_renewal',
    DocumentKind.municipal,
    'BUSINESS PERMIT RENEWAL',
    office: 'Business Permits & Licensing Office',
    nameField: 'applicant_name',
  ),
  'dokyu_rpt': DocumentMeta(
    'dokyu_rpt',
    DocumentKind.municipal,
    'REAL PROPERTY TAX CLEARANCE',
    office: "Municipal Treasurer's Office",
    nameField: 'owner_name',
  ),
};

/// A run of text: a filled-in answer ([field], bold with a dotted
/// underline), a phrase in bold ([bold]), or a muted label ([muted]).
class DocSpan {
  const DocSpan(this.text, {this.field = false, this.bold = false, this.muted = false});
  final String text;
  final bool field;
  final bool bold;
  final bool muted;
}

/// How a paragraph is set, after the website's classes.
enum DocTextStyle {
  /// The body (13px).
  body,

  /// A purpose line: indented, smaller, bold, dotted underline.
  purpose,

  /// A centred bold uppercase heading ("Barangay Business Permit").
  heading,

  /// A small italic muted line.
  note,

  /// Small (12px).
  small,

  /// Small and muted (the affidavit's "Republic of the Philippines" line).
  smallMuted,
}

sealed class DocBlock {
  const DocBlock();
}

/// A paragraph.
class DocText extends DocBlock {
  const DocText(this.spans, {this.style = DocTextStyle.body});
  final List<DocSpan> spans;
  final DocTextStyle style;
}

/// The barangay certificates' two-column grid of labelled answers; a last
/// odd one spans both columns.
class DocPairs extends DocBlock {
  const DocPairs(this.rows);
  final List<(String, String)> rows;
}

/// A municipal slip's bulleted section: an optional heading, then one
/// labelled answer per line.
class DocList extends DocBlock {
  const DocList(this.rows, {this.heading});
  final List<(String, String)> rows;
  final String? heading;
}

/// A municipal slip's boxed form: navy section bars and rows of cells.
class DocBox extends DocBlock {
  const DocBox(this.rows);
  final List<DocBoxRow> rows;
}

sealed class DocBoxRow {
  const DocBoxRow();
}

/// One navy bar, or two side by side (Groom | Bride).
class DocBar extends DocBoxRow {
  const DocBar(this.labels);
  final List<String> labels;
}

/// A row of 1 to 3 cells, each a small label over its answer.
class DocCells extends DocBoxRow {
  const DocCells(this.cells);
  final List<(String, String)> cells;
}

/// Labelled answers listed inside a box (the Cedula's taxpayer).
class DocBoxList extends DocBoxRow {
  const DocBoxList(this.rows);
  final List<(String, String)> rows;
}

/// Small "Label: answer" pairs side by side (Requester / Status).
class DocInline extends DocBlock {
  const DocInline(this.rows);
  final List<(String, String)> rows;
}

/// Small empty boxes filled at the office (thumbmarks, a picture).
class DocBoxes extends DocBlock {
  const DocBoxes(this.labels);
  final List<String> labels;
}

/// One document, ready to draw.
class DocumentSheet {
  DocumentSheet({
    required this.meta,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.barangay,
    this.punongBarangay,
    this.barangaySecretary,
    this.closing,
    this.validity,
    this.note,
    this.issued,
    this.bodyGap = 12,
    this.relaxed = false,
  });

  final DocumentMeta meta;
  final String title;
  final String? subtitle;
  final List<DocBlock> body;
  final String barangay;
  final String? punongBarangay;
  final String? barangaySecretary;

  /// "Given today ..." / "Issued this ..." where the paper form has it.
  final String? closing;

  /// The validity line printed at the foot (Residency, Indigency), as on
  /// Barangay Labangtaytay's papers (2026-11-03).
  final String? validity;

  /// The template's note, from GET /document-templates.
  final String? note;

  /// The issued document (control number, code, QR), once issued.
  final IssuedDocumentInfo? issued;

  /// The space between the body's blocks, and whether its lines are set
  /// loose (the website's space-y-* and leading-relaxed on each template).
  final double bodyGap;
  final bool relaxed;

  bool get isBarangay => meta.kind == DocumentKind.barangay;

  /// The municipal slip's closing line.
  String get disclaimer =>
      'This is a summary of your request, not the final certificate. The ${meta.office ?? 'office'} will prepare and release the official document upon verification against the civil registry.';
}

/// What /document-templates says of one document.
class DocumentTemplate {
  const DocumentTemplate({this.title, this.subtitle, this.note, this.version = 1});
  final String? title;
  final String? subtitle;
  final String? note;
  final int version;
}

const _blank = '_______________________';

/// "22nd day of October, 2026", as the barangay papers write it.
String issuanceDate(DateTime d) {
  final day = d.day;
  final suffix = (day >= 11 && day <= 13) ? 'th' : (const ['th', 'st', 'nd', 'rd'].elementAtOrNull(day % 10) ?? 'th');
  return '$day$suffix day of ${DateFormat('MMMM, y').format(d)}';
}

/// The barangay papers' tick lists (LABANGTATAY BRGY TEMPLATES, 2026-11-03).
const residencyTypes = ['permanent', 'temporary', 'renter'];
const paperPurposes = {
  'brgy_residency': ['Proof of Residency', 'Local Employment', 'Travel Abroad', 'Postal I.D', 'Bank Requirement', 'NBI Clearance', 'Loan Purpose', 'Medical/Financial Assistance'],
  'brgy_clearance': ['Proof of Residency', 'Local Employment', 'Travel Abroad', 'Postal I.D.', 'Bank Requirement', 'NBI Clearance', 'Loan Purposes', 'Medical/Financial Assistance'],
  'brgy_indigency': ['Medical Assistance/Financial Assistance', 'Burial Assistance', 'Educational Assistance'],
};

String _norm(String v) => v.toLowerCase().replaceFirst(RegExp(r'^others:\s*'), '').replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Whether a chosen answer is this option (Postal I.D / I.D., Loan Purpose /
/// Purposes, the old split Medical and Financial Assistance all count).
bool _same(String chosen, String option) {
  final x = _norm(chosen), y = _norm(option);
  return x.isNotEmpty && (x == y || '${x}s' == y || x == '${y}s' || (x.length > 7 && y.contains(x)));
}

/// Builds [meta]'s document from [data] (the request's answers), as the
/// website draws it: the same wording and the same parts.
DocumentSheet buildDocument(
  DocumentMeta meta,
  Map<String, dynamic> data, {
  required String barangay,
  String? punongBarangay,
  String? barangaySecretary,
  DocumentTemplate? template,
  IssuedDocumentInfo? issued,
  DateTime? today,
}) {
  String raw(String key) {
    final v = data[key];
    if (v == null) return '';
    if (v is List) return v.map((e) => '$e').where((e) => e.trim().isNotEmpty).join(', ');
    return '$v'.trim();
  }

  DocSpan f(String key, {String fallback = _blank, bool lower = false}) {
    final v = raw(key);
    return DocSpan(v.isEmpty ? fallback : (lower ? v.toLowerCase() : v), field: true);
  }

  // A labelled answer: blank when unanswered (the website leaves the line).
  (String, String) pair(String label, String key) => (label, raw(key));
  DocText p(List<Object> parts, {DocTextStyle style = DocTextStyle.body}) =>
      DocText([for (final x in parts) x is DocSpan ? x : DocSpan('$x')], style: style);
  final brgy = DocSpan(barangay);
  DocSpan b(String text) => DocSpan(text, bold: true);
  DocSpan m(String text) => DocSpan(text, muted: true);
  DocSpan v(String key, {String fallback = '—'}) => DocSpan(raw(key).isEmpty ? fallback : raw(key), bold: true);

  List<String> chosen(String key) {
    final v = data[key];
    if (v is List) return [for (final e in v) '$e'];
    final s = raw(key);
    return s.isEmpty ? const [] : s.split(RegExp(r',\s*'));
  }

  String tick(bool on) => on ? '( / )' : '(\u00a0\u00a0)';
  // "( / ) permanent, (  ) temporary, (  ) renter"
  DocSpan residency() {
    final c = raw('residency_type').toLowerCase();
    return DocSpan([for (final t in residencyTypes) '${tick(c == t)} $t'].join(', '));
  }

  // The paper's purposes, each ticked or not, then "Others: ..." as typed.
  DocText purposes() {
    final options = paperPurposes[meta.key] ?? const <String>[];
    final c = chosen('purpose');
    final others = [
      for (final x in c)
        if (!options.any((o) => _same(x, o)) && !RegExp(r'^others$', caseSensitive: false).hasMatch(x.trim())) x.replaceFirst(RegExp(r'^others:\s*', caseSensitive: false), ''),
    ].join(', ');
    return DocText([
      for (final o in options) DocSpan('${tick(c.any((x) => _same(x, o)))} $o\n'),
      DocSpan('${tick(others.isNotEmpty)} Others: '),
      DocSpan(others.isEmpty ? _blank : others, field: true),
    ], style: DocTextStyle.purpose);
  }

  final date = issuanceDate(issued?.issuedOn ?? today ?? DateTime.now());
  final body = <DocBlock>[];
  var gap = 10.0;
  var relaxed = meta.kind == DocumentKind.barangay;
  switch (meta.key) {
    case 'brgy_cert_death_registration':
      body.addAll([
        p(['This is to certify that ', f('subject_name'), ', is a bonafide resident of this barangay.']),
        p(['This further certifies for the other information of this person to wit:']),
        DocPairs([
          pair('Name of Father', 'father_name'),
          pair('Name of Mother (Maiden Name)', 'mother_name'),
          pair('Date of Death', 'date_of_death'),
          pair('Place of Death', 'place_of_death'),
          pair('Civil Status', 'civil_status'),
          pair('Religion', 'religion'),
          pair('Citizenship', 'citizenship'),
          pair('Sex', 'sex'),
        ]),
        p([
          'Issued this $date, upon request of the interested party for the ',
          b('REGISTRATION of Death'),
          ' and for whatever legal purposes this will serve him/her best.',
        ]),
      ]);
    case 'brgy_cert_late_registration':
      body.addAll([
        p(['This is to certify that ', f('subject_name'), ', is a bonafide resident of this barangay.']),
        p(['This further certifies for the other information of this person to wit:']),
        DocPairs([
          pair('Name of Father', 'father_name'),
          pair('Name of Mother (Maiden Name)', 'mother_name'),
          pair('Date of Birth', 'date_of_birth'),
          pair('Place of Birth', 'place_of_birth'),
          pair('Sex', 'sex'),
          pair('Citizenship', 'citizenship'),
          pair('Civil Status', 'civil_status'),
          pair('Occupation', 'occupation'),
          pair('Name of Husband/Wife (if married)', 'spouse_name'),
        ]),
        p([
          'Issued this $date upon request of the herein interested party for the ',
          b('LATE REGISTRATION of his/her birth'),
          ' at the Municipal Registry Office of Esperanza, Masbate.',
        ]),
        const DocBoxes(['Right Thumbmark', 'Left Thumbmark', 'Picture']),
      ]);
    case 'brgy_business_clearance':
      body.addAll([
        p([
          'This is to certify that ',
          f('applicant_name'),
          ', ',
          f('age', fallback: '___'),
          ' years of age, having engaged in a business of ',
          f('business_type', fallback: '_______________'),
          ', for almost ',
          f('years_operating', fallback: '___'),
          ' years located at Purok ',
          f('purok', fallback: '___'),
          ', Barangay ',
          brgy,
          ', Esperanza, Masbate with the capital of ( ',
          f('capital_figures', fallback: '_______'),
          ' ) ( ',
          f('capital_words'),
          ' ).',
        ]),
        p([
          'This is non-transferable and shall be null and void upon failure of the aforementioned applicant to strictly comply with the conditions of this clearance.',
        ]),
        p([
          'This clearance is being issued upon request of the interested party for identification and whatever legal purposes it may serve.',
        ]),
      ]);
    case 'brgy_residency':
      body.addAll([
        p([
          'This is to certify that ',
          f('requester_name'),
          ', ',
          f('age', fallback: '___'),
          ' years of age, is a ',
          residency(),
          ' a bonafide resident of Purok ',
          f('purok', fallback: '___'),
          ', Barangay ',
          brgy,
          ', Esperanza, Masbate.',
        ]),
        p([
          'He/She has no pending case/complaint against him/her as per record of this office. He/She has no derogatory record on file in this office.',
        ]),
        p(['This certification is being issued by this office upon the request of the aforementioned name for:']),
        purposes(),
      ]);
    case 'brgy_first_time_jobseeker':
      body.addAll([
        p([
          'This is to certify that ',
          f('requester_name'),
          ', a bonafide resident of Purok ',
          f('purok', fallback: '___'),
          ', Barangay ',
          brgy,
          ', Esperanza, Masbate, ',
          f('age', fallback: '___'),
          ' years of age, is a qualified availee of ',
          b('RA 11261'),
          ' or the First Time Jobseekers Assistance Act of 2019.',
        ]),
        p([
          'I further certify that the holder/bearer was informed of his/her rights, including the duties and responsibilities accorded by RA 11261, through the Oath of Undertaking he/she has signed and executed in the presence of Barangay Officials.',
        ]),
        p(['Signed this $date at Barangay ', brgy, ', Esperanza, Masbate, Philippines.']),
        p(['This certification is valid for one (1) year from the date of issuance.']),
      ]);
    case 'brgy_indigency':
      body.addAll([
        p([
          'This is to certify that ',
          f('requester_name'),
          ', ',
          f('age', fallback: '___'),
          ' years of age, is a ',
          residency(),
          ' a resident of Purok ',
          f('purok', fallback: '___'),
          ', Barangay ',
          brgy,
          ', Esperanza, Masbate, for:',
        ]),
        purposes(),
        p([
          'The way of life of his/her family is a hand-to-mouth existence, meaning they belong below the poverty line. Further certified that he/she has no pending case/complaint, no derogatory record on file against him/her as per record of this office.',
        ]),
      ]);
    case 'brgy_clearance':
      body.addAll([
        p([
          'This is to certify that ',
          f('requester_name'),
          ', ',
          f('age', fallback: '___'),
          ' years of age, is a ',
          residency(),
          ' resident of Purok ',
          f('purok', fallback: '___'),
          ', Barangay ',
          brgy,
          ', Esperanza, Masbate.',
        ]),
        p([
          'He/She has no pending case/complaint against him/her as per record of this office. He/She has no derogatory record on file in this office.',
        ]),
        p(['This certification is being issued by this office upon the request of the aforementioned name for:']),
        purposes(),
      ]);
    case 'brgy_cert_national_id':
      body.addAll([
        p(['This is to certify that ', f('subject_name'), ', is a bonafide resident of this Barangay.']),
        p(['This further certifies for the other information of the above-named person, to wit:']),
        DocPairs([
          pair('Name of Father', 'father_name'),
          pair('Name of Mother (Maiden Name)', 'mother_name'),
          pair('Date of Birth', 'date_of_birth'),
          pair('Place of Birth', 'place_of_birth'),
          pair('Sex', 'sex'),
          pair('Citizenship', 'citizenship'),
          pair('Civil Status', 'civil_status'),
          pair('Occupation', 'occupation'),
          pair('Name of Husband/Wife', 'spouse_name'),
        ]),
        p([
          'Issued upon request of the herein interested party for the ',
          b('Registration of NATIONAL ID'),
          ' and for whatever legal purposes this will serve him/her best.',
        ]),
      ]);
    case 'brgy_cert_land_property':
      body.addAll([
        p([
          'This is to certify that ',
          f('owner_name'),
          ' is the owner of a lot with ',
          f('lot_area', fallback: '___'),
          ' square meters located at ',
          f('lot_location'),
          ', Purok ',
          f('purok', fallback: '___'),
          ', Barangay ',
          brgy,
          ', Esperanza, Masbate.',
        ]),
        if (raw('no_conflict_owner').isNotEmpty)
          p(['This certifies further that this lot has no conflict of ownership with ', f('no_conflict_owner'), '.']),
        p(['This certification is issued for whatever legal purpose it may serve.']),
      ]);
    case 'brgy_cert_general':
      body.addAll([
        p([
          'This is to certify that ',
          f('subject_name'),
          ', ',
          f('age', fallback: '___'),
          ' years of age, ',
          f('civil_status', fallback: '___', lower: true),
          ', is a bonafide resident of Barangay ',
          brgy,
          ', Esperanza, Masbate.',
        ]),
        p(['This certification is issued upon request of the herein interested party for ', f('purpose'), ' purposes.']),
        if (raw('details').isNotEmpty) p([raw('details')]),
      ]);
    case 'brgy_business_permit':
      body.addAll([
        p(['Barangay Business Permit'], style: DocTextStyle.heading),
        DocPairs([
          pair('Proprietor', 'proprietor_name'),
          pair('Nature of Business', 'business_name'),
          pair('Business Location', 'business_location'),
          pair('Amount Paid', 'amount_paid'),
        ]),
        p([
          'This Permit is being issued subject to existing rules and regulations, provided however, that the necessary fees are paid to the Treasurer of the Barangay as assessed. This is non-transferable and shall be deemed null and void upon failure by the owner to follow the said rules and regulations set forth by the Local Government Unit of Esperanza, Masbate.',
        ]),
        p([
          'This License, while in force, shall be posted in a conspicuous place in the business premises.',
        ], style: DocTextStyle.note),
      ]);
    case 'brgy_event_permit':
      body.addAll([
        p([
          'The ',
          f('organizer_name'),
          ', of Barangay ',
          brgy,
          ', Esperanza, Masbate is requesting permission to hold a ',
          f('event_type', fallback: '_______________'),
          ' on ',
          f('event_date', fallback: '___'),
          ', from ',
          f('event_time_from', fallback: '___'),
          ' to ',
          f('event_time_to', fallback: '___'),
          ', at ',
          f('venue'),
          '.',
        ]),
        p([
          'This permit is granted subject to peace and order guidelines of the barangay and may be revoked at any time for cause.',
        ]),
      ]);
    case 'mcro_marriage':
      gap = 12;
      body.addAll([
        p([m('Requester:'), ' ', v('requester_name'), ' ', m('('), DocSpan(raw('relationship').isEmpty ? '—' : raw('relationship'), muted: true), m(')')], style: DocTextStyle.small),
        DocBox([
          DocCells([pair('Husband', 'husband_name'), pair('Wife', 'wife_name')]),
          DocCells([pair('Date of Marriage', 'date_of_marriage'), pair('Place of Marriage', 'place_of_marriage')]),
          DocCells([pair('Registration Status', 'is_delayed')]),
        ]),
      ]);
    case 'mcro_marriage_license':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Groom', 'Bride']),
          DocCells([pair('Full Name', 'groom_name'), pair('Full Name', 'bride_name')]),
          DocCells([pair('Date of Birth', 'groom_dob'), pair('Date of Birth', 'bride_dob')]),
          DocCells([pair('Citizenship', 'groom_citizenship'), pair('Citizenship', 'bride_citizenship')]),
          DocCells([pair('Residence', 'groom_residence'), pair('Residence', 'bride_residence')]),
          DocCells([pair('Civil Status', 'groom_civil_status'), pair('Civil Status', 'bride_civil_status')]),
        ]),
        p([m('Consent/Advice Given By:'), ' ', v('consent_person')], style: DocTextStyle.small),
      ]);
    case 'mcro_live_birth':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Child']),
          DocCells([pair('Name', 'child_name')]),
          DocCells([pair('Sex', 'sex'), pair('Date of Birth', 'date_of_birth'), pair('Place of Birth', 'place_of_birth')]),
        ]),
        DocBox([
          const DocBar(['Mother']),
          DocCells([pair('Maiden Name', 'mother_maiden_name'), pair('Citizenship', 'mother_citizenship')]),
        ]),
        DocBox([
          const DocBar(['Father']),
          DocCells([pair('Full Name', 'father_name'), pair('Citizenship', 'father_citizenship')]),
        ]),
        DocInline([pair('Requester', 'requester_relationship'), pair('Status', 'is_delayed')]),
        if (raw('ethnicity_father').isNotEmpty || raw('ethnicity_mother').isNotEmpty || raw('dob_hijrah').isNotEmpty)
          DocBox([
            const DocBar(['Muslim Attachment']),
            DocCells([pair('Ethnicity of Father', 'ethnicity_father'), pair('Ethnicity of Mother', 'ethnicity_mother')]),
            DocCells([pair('Date of Birth — Hijrah Calendar', 'dob_hijrah')]),
          ]),
      ]);
    case 'mcro_death':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Deceased']),
          DocCells([pair('Name', 'deceased_name')]),
          DocCells([pair('Sex', 'sex'), pair('Date of Death', 'date_of_death'), pair('Place of Death', 'place_of_death')]),
          DocCells([pair('Date of Birth', 'date_of_birth'), pair('Civil Status', 'civil_status')]),
          DocCells([pair('Citizenship', 'citizenship'), pair('Residence', 'residence')]),
          DocCells([pair('Name of Father', 'father_name'), pair("Mother's Maiden Name", 'mother_maiden_name')]),
        ]),
        DocInline([pair('Requester', 'requester_relationship'), pair('Status', 'is_delayed')]),
      ]);
    case 'mcro_delayed_registration':
      gap = 12;
      relaxed = true;
      body.addAll([
        p(['Republic of the Philippines · Municipality of Esperanza'], style: DocTextStyle.smallMuted),
        p([
          'That I am the applicant for the delayed registration of ',
          f('registration_type', fallback: '_______'),
          ' of ',
          f('subject_name'),
          ', to whom I am the ',
          f('applicant_relationship', fallback: '_______'),
          '.',
        ]),
        p(['That the reason for the delay in registering this event was ', f('reason_for_delay'), '.']),
        p([
          'That I am executing this affidavit to attest to the truthfulness of the foregoing statements for all legal intents and purposes.',
        ]),
      ]);
    case 'municipal_pet_registration':
      gap = 16;
      body.addAll([
        DocList(heading: 'Owner Information', [
          pair('Full Name', 'owner_name'),
          pair('Address', 'address'),
          pair('Phone Number', 'phone'),
          pair('Email Address', 'email'),
        ]),
        DocList(heading: 'Pet Information', [
          pair("Pet's Name", 'pet_name'),
          pair('Species', 'species'),
          pair('Breed', 'breed'),
          pair('Color/Markings', 'color_markings'),
          pair('Gender', 'gender'),
          pair('Date of Birth / Age', 'pet_dob'),
          pair('Microchip Number', 'microchip_number'),
        ]),
        DocList(heading: 'Vaccination & Care', [
          pair('Last Rabies Vaccination', 'last_rabies_vaccination'),
          pair('Other Vaccinations', 'other_vaccinations'),
          pair('Spayed / Neutered', 'spay_neuter'),
        ]),
        DocList(heading: 'Emergency Contact', [
          pair('Name', 'emergency_contact_name'),
          pair('Phone Number', 'emergency_contact_phone'),
        ]),
      ]);
    case 'msw_pwd_id':
      gap = 16;
      body.addAll([
        DocList(heading: 'Personal Information', [
          pair('Full Name', 'full_name'),
          pair('Date of Birth', 'date_of_birth'),
          pair('Sex', 'sex'),
          pair('Civil Status', 'civil_status'),
          pair('Religion', 'religion'),
          pair('Blood Type', 'blood_type'),
        ]),
        DocList(heading: 'Disability Information', [
          pair('Type of Disability', 'type_of_disability'),
          pair('Cause of Disability', 'cause_of_disability'),
        ]),
        DocList(heading: 'Residence & Employment', [
          pair('Address', 'residence_address'),
          pair('Educational Attainment', 'educational_attainment'),
          pair('Employment Status', 'employment_status'),
          pair('Occupation', 'occupation'),
        ]),
        DocList(heading: 'ID Reference Numbers', [
          pair('SSS No.', 'sss_no'),
          pair('GSIS No.', 'gsis_no'),
          pair('Pag-IBIG No.', 'pagibig_no'),
          pair('PhilHealth No.', 'philhealth_no'),
        ]),
        DocList(heading: 'Family Background', [
          pair("Father's Name", 'father_name'),
          pair("Mother's Name", 'mother_name'),
          pair("Guardian's Name", 'guardian_name'),
        ]),
      ]);
    case 'osca_senior_citizen':
      gap = 16;
      body.addAll([
        DocList([
          pair('Name', 'full_name'),
          pair('Birthdate', 'birthdate'),
          pair('Birthplace', 'birthplace'),
          pair('Address (Brgy./Sitio)', 'address_purok'),
          pair('Sex', 'sex'),
          pair('Age', 'age'),
          pair('Marital Status', 'marital_status'),
          pair('Educational Attainment', 'educational_attainment'),
          pair('Present Occupation', 'present_occupation'),
          pair('Annual Income', 'annual_income'),
          pair('Pension', 'pension'),
          pair('PhilSys ID No.', 'philsys_id'),
        ]),
        DocList(heading: 'Last Government Service', [
          pair('Office', 'last_govt_office'),
          pair('Year', 'last_govt_year'),
          pair('Address', 'last_govt_address'),
          pair('Position/Designation', 'last_govt_position'),
        ]),
      ]);
    case 'dokyu_cedula':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Taxpayer Information']),
          DocBoxList([
            pair('Full Name', 'full_name'),
            pair('Address', 'address'),
            ('Citizenship', raw('citizenship').isEmpty ? 'Filipino' : raw('citizenship')),
            pair('Civil Status', 'civil_status'),
            pair('Occupation', 'occupation'),
            pair('Employer / Business', 'employer_or_business'),
          ]),
        ]),
        DocBox([
          const DocBar(['Basis of Tax']),
          DocCells([pair('Gross Annual Income / Receipts', 'annual_income'), ('Basic Community Tax', '₱5.00')]),
        ]),
        if (raw('or_number').isNotEmpty || raw('amount_paid').isNotEmpty)
          DocBox([
            const DocBar(['Payment Reference']),
            DocCells([pair('O.R. Number', 'or_number'), pair('Amount Paid', 'amount_paid')]),
          ]),
      ]);
    case 'dokyu_residency':
      relaxed = true;
      body.addAll([
        p([b('TO WHOM IT MAY CONCERN:')]),
        p([
          'This is to certify that ',
          f('requester_name'),
          ', ',
          f('age', fallback: '___'),
          ' years of age, ',
          f('civil_status', fallback: '___', lower: true),
          ', ',
          f('citizenship', fallback: 'Filipino'),
          ' citizen, is a bonafide resident of ',
          f('address'),
          ', Municipality of Esperanza, Province of Masbate, for ',
          f('years_of_residency', fallback: '___'),
          ' years.',
        ]),
        p(['This certification is being issued upon request of the above-named person for ', f('purpose'), ' purposes.']),
      ]);
    case 'dokyu_indigency':
      relaxed = true;
      body.addAll([
        p([b('TO WHOM IT MAY CONCERN:')]),
        p([
          'This is to certify that ',
          f('requester_name'),
          ', ',
          f('age', fallback: '___'),
          ' years of age, residing at ',
          f('address'),
          ', belongs to a household of ',
          f('family_size', fallback: '___'),
          ' member(s) with a monthly household income of ',
          f('monthly_income', fallback: '___'),
          ', and belongs to the indigent sector of this municipality.',
        ]),
        p(['This certification is being issued upon request of the above-named person for ', f('purpose'), ' purposes.']),
      ]);
    case 'dokyu_business_new':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Applicant']),
          DocCells([pair('Taxpayer Name', 'applicant_name'), pair('Type of Business', 'business_type')]),
          DocCells([pair('DTI / SEC / CDA Registration No.', 'dti_sec_cda_no')]),
        ]),
        DocBox([
          const DocBar(['Business']),
          DocCells([pair('Business Name', 'business_name')]),
          DocCells([pair('Business Address', 'business_address')]),
          DocCells([pair('Line of Business', 'line_of_business'), pair('Contact No.', 'contact_no')]),
          DocCells([pair('Capital Investment', 'capital_investment'), pair('Total No. of Employees', 'total_employees')]),
        ]),
      ]);
    case 'dokyu_business_renewal':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Applicant / Business']),
          DocCells([pair('Taxpayer Name', 'applicant_name')]),
          DocCells([pair('Business Name', 'business_name')]),
          DocCells([pair('Business Address', 'business_address')]),
        ]),
        DocBox([
          const DocBar(['Renewal Reference']),
          DocCells([pair('Previous Permit No.', 'prior_permit_no'), pair('Official Receipt No.', 'prior_or_no')]),
          DocCells([pair('Line of Business', 'line_of_business'), pair('Prior Year Gross Receipts', 'gross_receipts_prior_year')]),
        ]),
      ]);
    case 'dokyu_rpt':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Property of Record']),
          DocCells([pair('Registered Owner', 'owner_name')]),
          DocCells([pair('Tax Declaration No.', 'tax_declaration_no'), pair('Property Index No. (PIN)', 'property_index_no')]),
          DocCells([pair('Lot / Block No.', 'lot_block_no'), pair('Assessed Value', 'assessed_value')]),
          DocCells([pair('Property Location', 'property_location')]),
        ]),
        p([
          'This is to certify that the real property described above has no delinquent real property tax as of the date of issuance, per records of this office.',
        ], style: DocTextStyle.small),
      ]);
    case 'locational_clearance':
      gap = 12;
      body.addAll([
        DocBox([
          const DocBar(['Applicant']),
          DocCells([pair('Applicant Type', 'applicant_type'), pair('Authorized Representative', 'authorized_rep_name')]),
          DocCells([pair("Representative's Address", 'authorized_rep_address')]),
        ]),
        DocBox([
          const DocBar(['Project Description']),
          DocCells([pair('Project Title', 'project_title')]),
          DocCells([pair('Nature of Application', 'nature_of_application'), pair('Project Location', 'project_location')]),
          DocCells([pair('Floor Area (sqm)', 'floor_area'), pair('Height (m)', 'building_height'), pair('No. of Storeys', 'number_of_storeys')]),
        ]),
        DocBox([
          const DocBar(['Lot Information']),
          DocCells([pair('Lot Area (sqm)', 'lot_area'), pair('TCT / OCT No.', 'title_number'), pair('Right Over Land', 'right_over_land')]),
          DocCells([pair('Zoning Classification', 'zoning_classification')]),
        ]),
      ]);
  }

  final closing = switch (meta.key) {
    'brgy_clearance' || 'brgy_residency' => 'Given today $date at Barangay $barangay, Esperanza, Masbate, Philippines.',
    'brgy_business_clearance' || 'brgy_indigency' => 'Issued this $date at Barangay $barangay, Esperanza, Masbate, Philippines.',
    _ => null,
  };
  final validity = switch (meta.key) {
    'brgy_residency' => '(Residency certificate valid three (3) months from the date of issuance)',
    'brgy_indigency' => '(Indigency certificate valid three (3) months from the date of issuance)',
    _ => null,
  };
  // As the website's docTemplates store: the template's title, and its
  // subtitle once staff edited it (version 2 and on).
  final t = template;
  return DocumentSheet(
    meta: meta,
    title: (t?.title?.trim().isNotEmpty ?? false) ? t!.title!.trim() : meta.title,
    subtitle: t != null && t.version > 1 ? (t.subtitle?.trim().isEmpty ?? true ? null : t.subtitle!.trim()) : meta.subtitle,
    body: body,
    barangay: barangay,
    punongBarangay: punongBarangay,
    barangaySecretary: barangaySecretary,
    closing: closing,
    validity: validity,
    note: t?.note?.trim().isEmpty ?? true ? null : t!.note!.trim(),
    issued: issued,
    bodyGap: gap,
    relaxed: relaxed,
  );
}

/// The newest issued document that is not revoked (the website's verify strip).
IssuedDocumentInfo? currentIssued(List<IssuedDocumentInfo> docs) {
  for (final d in docs.reversed) {
    if (!d.revoked) return d;
  }
  return null;
}

/// A filed request's answers, completed as the website completes them for
/// "Your Document": the resident's name and purpose where the form did not
/// ask them, then their profile details for anything still blank.
Map<String, dynamic> documentData(
  DocumentMeta meta,
  Map<String, dynamic> formData, {
  required String fullName,
  String purpose = '',
  String? birthdate,
  String? sex,
  String? civilStatus,
  String? occupation,
  String? address,
  String? purok,
}) {
  final out = <String, dynamic>{};
  if (meta.nameField != null && fullName.trim().isNotEmpty) out[meta.nameField!] = fullName.trim();
  if (meta.purposeField != null && purpose.trim().isNotEmpty) {
    out[meta.purposeField!] = meta.purposeIsArray ? [purpose.trim()] : purpose.trim();
  }
  formData.forEach((k, v) {
    final empty = v == null || (v is String && v.trim().isEmpty) || (v is List && v.isEmpty);
    if (!empty) out[k] = v;
  });
  final dob = birthdate == null ? null : DateTime.tryParse(birthdate);
  int? age;
  if (dob != null) {
    final now = DateTime.now();
    age = now.year - dob.year - ((now.month < dob.month || (now.month == dob.month && now.day < dob.day)) ? 1 : 0);
  }
  final profile = <String, Object?>{
    'age': age,
    'date_of_birth': birthdate?.substring(0, birthdate.length >= 10 ? 10 : birthdate.length),
    'sex': sex,
    'civil_status': civilStatus,
    'citizenship': 'Filipino',
    'occupation': occupation,
    'address': address,
    'residence': address,
    'purok': purok?.replaceFirst(RegExp(r'^\s*purok\s*', caseSensitive: false), ''),
  };
  profile.forEach((k, v) {
    if (v == null || '$v'.trim().isEmpty) return;
    out.putIfAbsent(k, () => v);
  });
  return out;
}
