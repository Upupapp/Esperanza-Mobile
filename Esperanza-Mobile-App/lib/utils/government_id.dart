import '../models/citizen_account.dart';
import '../models/government_id_record.dart';
import '../services/mock_catalog.dart';

/// Every account id that resolves to a seeded government ID record — a
/// resident with more than one account (a verified account and its
/// duplicate registration, or two duplicate registrations of the same
/// person) submitted the same physical document each time, so every one of
/// their account ids maps to the SAME record, never a separate copy. An
/// account seeing a record here is what makes "ID submitted" true for it
/// even while still Pending Review; it never implies the account is
/// verified — that's decided entirely by `account.status`/`accessLevel`,
/// never by whether an ID record exists.
Map<String, GovernmentIdRecord> get _governmentIdByAccountId => {
  'ESP-RES-2024-1044': MockCatalog.cristyGovernmentId,
  'ESP-RES-2024-1044-DUP': MockCatalog.cristyGovernmentId,
  'ESP-RES-2024-1102': MockCatalog.ronaldoGovernmentId,
  'ESP-RES-2026-2101': MockCatalog.theodoroGovernmentId,
  'ESP-RES-2026-2102': MockCatalog.theodoroGovernmentId,
};

/// The one seeded government ID record for [account], or null if none is
/// seeded for them. The identity/verification display, My Government IDs,
/// and every unverified account's own "submitted ID" section all call this
/// rather than each keeping its own copy — see each MockCatalog record's
/// own doc comment for why a resident with multiple accounts still has
/// exactly one record.
GovernmentIdRecord? governmentIdFor(CitizenAccount? account) {
  if (account == null) return null;
  return _governmentIdByAccountId[account.id];
}
