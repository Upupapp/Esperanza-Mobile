/// The one office a catalogue `office` string belongs to, for grouping.
///
/// The service catalogue (esperanza-backend, vendored from the web
/// platform's config) names the same office three ways -- "Office of the
/// Municipal Civil Registrar" (19 services), "Civil Registrar" (4) and
/// "Civil Registrar / appropriate local office" (1) -- so the Dokyu office
/// step listed the Civil Registrar twice and split its services between the
/// two. Grouping only: each service still shows the office text the server
/// sent. The data fix belongs upstream (PENDING.md).
String canonicalOffice(String office) => _aliases[office.trim()] ?? office.trim();

const _aliases = <String, String>{
  'Civil Registrar': 'Office of the Municipal Civil Registrar',
  'Civil Registrar / appropriate local office': 'Office of the Municipal Civil Registrar',
};
