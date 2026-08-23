/// A citizen's seeded government-issued ID document — FRONTEND SIMULATION
/// ONLY, no real ID verification service. One record per resident; the
/// same record is read from both the identity/verification side of the
/// app and My Government IDs, rather than either keeping its own copy —
/// see utils/government_id.dart's [governmentIdFor], the single lookup
/// both call sites share.
class GovernmentIdRecord {
  final String accountId;
  final String idType;
  final String assetPath;
  final String idNumber;
  final String issuingOffice;

  const GovernmentIdRecord({
    required this.accountId,
    required this.idType,
    required this.assetPath,
    required this.idNumber,
    required this.issuingOffice,
  });
}
