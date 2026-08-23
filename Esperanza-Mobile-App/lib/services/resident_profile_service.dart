import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/citizen_account.dart';
import '../models/resident_profile.dart';

/// Local, frontend-only "database" for Resident Profiling — same
/// persistence shape as RequestsService/BalitaService: JSON to
/// SharedPreferences, keyed per citizen account so switching between the
/// two demo residents never leaks one profile into the other. There is no
/// backend; every method here just mutates local state and persists it.
class ResidentProfileService extends ChangeNotifier {
  static const _key = 'esperanza_resident_profiles';

  Map<String, ResidentProfile> _profiles = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  ResidentProfileService() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _profiles = map.map((k, v) => MapEntry(k, ResidentProfile.fromJson(v)));
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_profiles.map((k, v) => MapEntry(k, v.toJson()))));
  }

  /// Returns the profile for this citizen, creating (and persisting) a
  /// freshly-seeded one on first access.
  ResidentProfile profileFor(CitizenAccount account) {
    return _profiles.putIfAbsent(account.id, () => ResidentProfile.seedFrom(account));
  }

  Future<void> _save(ResidentProfile p) async {
    _profiles[p.citizenAccountId] = p;
    if (p.status == VerificationStatus.draft) p.status = VerificationStatus.incomplete;
    notifyListeners();
    await _persist();
  }

  Future<void> savePersonal(String accountId, Individual personal, {required bool markComplete}) async {
    final p = _profiles[accountId]!;
    p.personal = personal;
    p.personalSaved = markComplete;
    await _save(p);
  }

  /// Backfills reusable fields the citizen typed into a Dokyu/Tulong
  /// request (e.g. Sex, Civil Status, Occupation) that the Master Profile
  /// didn't have yet — unlike [savePersonal], this never touches
  /// [ResidentProfile.personalSaved]; that flag reflects only the
  /// citizen's own explicit "I've completed Personal Information" action
  /// on PersonalInformationScreen, and an incidental value learned from an
  /// unrelated request form must never silently mark that section done (or
  /// undone, if it happened to already be complete).
  Future<void> backfillPersonalField(String accountId, Individual personal) async {
    final p = _profiles[accountId]!;
    p.personal = personal;
    await _save(p);
  }

  Future<void> saveFamily(
    String accountId, {
    required String familyName,
    required String headIndividualId,
    required bool markComplete,
  }) async {
    final p = _profiles[accountId]!;
    p.familyName = familyName;
    p.headIndividualId = headIndividualId;
    p.familySaved = markComplete;
    await _save(p);
  }

  Future<void> addFamilyMember(String accountId, Individual member) async {
    final p = _profiles[accountId]!;
    member.familyId = p.familyId;
    member.householdId = p.householdId;
    p.familyMembers = [...p.familyMembers, member];
    await _save(p);
  }

  Future<void> updateFamilyMember(String accountId, Individual updated) async {
    final p = _profiles[accountId]!;
    p.familyMembers = p.familyMembers.map((m) => m.individualId == updated.individualId ? updated : m).toList();
    await _save(p);
  }

  Future<void> removeFamilyMember(String accountId, String individualId) async {
    final p = _profiles[accountId]!;
    p.familyMembers = p.familyMembers.where((m) => m.individualId != individualId).toList();
    if (p.headIndividualId == individualId) p.headIndividualId = p.personal.individualId;
    await _save(p);
  }

  Future<void> setHeadOfFamily(String accountId, String individualId) async {
    final p = _profiles[accountId]!;
    p.headIndividualId = individualId;
    await _save(p);
  }

  Future<void> addOtherFamilyToHousehold(
    String accountId,
    String familyName, {
    String headName = '',
    List<OtherFamilyMember> members = const [],
  }) async {
    final p = _profiles[accountId]!;
    final ref = SimpleFamilyRef(
      familyId: 'FAM-${DateTime.now().microsecondsSinceEpoch}',
      familyName: familyName,
      headName: headName,
      members: members,
    );
    p.household.otherFamilies = [...p.household.otherFamilies, ref];
    await _save(p);
  }

  Future<void> removeOtherFamilyFromHousehold(String accountId, String familyId) async {
    final p = _profiles[accountId]!;
    p.household.otherFamilies = p.household.otherFamilies.where((f) => f.familyId != familyId).toList();
    await _save(p);
  }

  Future<void> saveHousehold(String accountId, Household household, {required bool markComplete}) async {
    final p = _profiles[accountId]!;
    p.household = household;
    p.householdSaved = markComplete;
    await _save(p);
  }

  /// Section 8 — simulated "join an existing family record" action. No
  /// real matching/merge happens; this just marks the request as sent and
  /// adopts the matched family's display name so the UI can show it was
  /// acted on.
  Future<void> requestJoinFamily(String accountId, ExistingFamilyMatch match) async {
    final p = _profiles[accountId]!;
    p.joinRequestSent = true;
    if (p.familyName.trim().isEmpty) p.familyName = match.familyName;
    await _save(p);
  }

  Future<void> submit(String accountId) async {
    final p = _profiles[accountId]!;
    p.status = VerificationStatus.pendingVerification;
    p.correctionMessage = null;
    p.submittedAt = DateTime.now();
    await _save(p);
  }

  /// DEMO-ONLY: simulates what an LGU verifier would do on the Web Admin
  /// side (Pending Validation -> Verified / Needs Correction), mirroring
  /// RequestDetailScreen's `_DemoAdminPanel` pattern — there is no real
  /// Web Admin connection yet, so this lets the citizen-facing loop be
  /// previewed end-to-end anyway.
  Future<void> simulateVerify(String accountId) async {
    final p = _profiles[accountId]!;
    p.status = VerificationStatus.verified;
    p.correctionMessage = null;
    await _save(p);
  }

  Future<void> simulateNeedsCorrection(String accountId, String message) async {
    final p = _profiles[accountId]!;
    p.status = VerificationStatus.needsCorrection;
    p.correctionMessage = message;
    await _save(p);
  }
}
