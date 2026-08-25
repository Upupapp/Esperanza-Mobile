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

  /// The verified demo resident whose Master Profile is aligned to her real
  /// Web Admin Educational Assistance record — see
  /// _applyCristyMasterProfileAlignment. Same id RequestsService already
  /// uses for its own Cristy-specific seeding.
  static const _cristyVerifiedAccountId = 'ESP-RES-2024-1044';

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
    final cristy = _profiles[_cristyVerifiedAccountId];
    if (cristy != null && _applyCristyMasterProfileAlignment(cristy)) await _persist();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_profiles.map((k, v) => MapEntry(k, v.toJson()))));
  }

  /// Returns the profile for this citizen, creating (and persisting) a
  /// freshly-seeded one on first access. Cristy's own freshly-seeded
  /// profile additionally gets her Master Profile alignment applied right
  /// away (see _applyCristyMasterProfileAlignment) — otherwise a device
  /// that had never opened her profile before this correction would seed a
  /// profile from her (already-corrected) CitizenAccount birthdate but
  /// still be missing the family members / school / family-background
  /// fields that only this alignment step adds.
  ResidentProfile profileFor(CitizenAccount account) {
    return _profiles.putIfAbsent(account.id, () {
      final profile = ResidentProfile.seedFrom(account);
      if (account.id == _cristyVerifiedAccountId) _applyCristyMasterProfileAlignment(profile);
      return profile;
    });
  }

  /// The Web-Admin-sourced correction for Cristy Bonghanoy's
  /// (ESP-RES-2024-1044) resident-fact data — her seeded profile originally
  /// carried a placeholder birthdate (Nov 29, 1988) and no family members;
  /// her real Web Admin Educational Assistance record is now this project's
  /// source of truth (see mock_catalog.dart's CitizenAccount doc comment).
  /// Applied both to a brand-new profile (see [profileFor]'s seeding
  /// closure above) and, as a migration, to a profile a device already
  /// persisted under the old placeholder values (see [_restore]) —
  /// idempotent either way via the per-field equality checks below, and
  /// only ever invoked for Cristy's own specific account id, never applied
  /// generically to another resident's real data. Returns whether anything
  /// actually changed, so callers only persist when needed.
  bool _applyCristyMasterProfileAlignment(ResidentProfile p) {
    var changed = false;
    final personal = p.personal;

    void setPersonal(String current, String next, void Function(String) apply) {
      if (current != next) {
        apply(next);
        changed = true;
      }
    }

    final correctBirthdate = DateTime(2001, 1, 13);
    if (personal.birthdate != correctBirthdate) {
      personal.birthdate = correctBirthdate;
      changed = true;
    }
    setPersonal(personal.civilStatus, 'Married', (v) => personal.civilStatus = v);
    setPersonal(personal.placeOfBirth, 'Milagros, Masbate', (v) => personal.placeOfBirth = v);
    setPersonal(personal.schoolName, 'Masbate National Comprehensive High School', (v) => personal.schoolName = v);
    setPersonal(personal.yearOrGradeLevel, '2nd Year College', (v) => personal.yearOrGradeLevel = v);
    setPersonal(personal.degreeProgramOrCourse, 'BS Education', (v) => personal.degreeProgramOrCourse = v);
    setPersonal(personal.lastSchoolAverageGrade, '90', (v) => personal.lastSchoolAverageGrade = v);
    setPersonal(
      personal.communityInvolvement,
      'Member of the church youth ministry.',
      (v) => personal.communityInvolvement = v,
    );
    setPersonal(
      personal.postGraduationPlans,
      'Plans to apply for government service after graduation.',
      (v) => personal.postGraduationPlans = v,
    );

    if (p.household.monthlyIncome != '₱9,718') {
      p.household.monthlyIncome = '₱9,718';
      changed = true;
    }

    if (!p.familyMembers.any((m) => m.relationshipToHead == 'Father')) {
      p.familyMembers = [
        ...p.familyMembers,
        Individual(
          individualId: 'IND-$_cristyVerifiedAccountId-FATHER',
          firstName: 'Ramon',
          lastName: 'Cristy',
          relationshipToHead: 'Father',
          occupation: 'Construction Worker',
          familyId: p.familyId,
          householdId: p.householdId,
        ),
      ];
      changed = true;
    }
    if (!p.familyMembers.any((m) => m.relationshipToHead == 'Mother')) {
      p.familyMembers = [
        ...p.familyMembers,
        Individual(
          individualId: 'IND-$_cristyVerifiedAccountId-MOTHER',
          firstName: 'Corazon',
          lastName: 'Cristy',
          relationshipToHead: 'Mother',
          occupation: 'Sari-Sari Store Vendor',
          familyId: p.familyId,
          householdId: p.householdId,
        ),
      ];
      changed = true;
    }

    return changed;
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

  /// Immediately persists a new profile photo (or clears it, when
  /// [photoBytes] is null) — deliberately separate from [savePersonal] so
  /// the camera-icon flow's own "Save Profile Photo" step never has to wait
  /// for, or accidentally include, the rest of a possibly half-edited
  /// Personal Information form. Only a real photo save with
  /// [startCooldown] true starts the 6-month cooldown (see
  /// ResidentProfile.isProfilePhotoOnCooldown) — clearing a photo (Remove
  /// photo) does not, since that isn't "changing to a new photo".
  Future<void> updateProfilePhoto(String accountId, {required Uint8List? photoBytes, required bool startCooldown}) async {
    final p = _profiles[accountId]!;
    p.personal.photoBytesBase64 = photoBytes != null ? base64Encode(photoBytes) : null;
    p.personal.photoPath = null;
    if (startCooldown) p.lastProfilePhotoChangeAt = DateTime.now();
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
