import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'json_read.dart';
import 'persistence_recovery.dart';
import '../models/citizen_account.dart';
import '../models/resident_profile.dart';
import '../utils/ph_mobile.dart';

/// Local, frontend-only "database" for Resident Profiling — same
/// persistence shape as RequestsService/BalitaService: JSON to
/// SharedPreferences, keyed per citizen account so switching between the
/// two demo residents never leaks one profile into the other. There is no
/// backend; every method here just mutates local state and persists it.
class ResidentProfileService extends ChangeNotifier {
  static const _key = 'esperanza_resident_profiles';

  /// The verified demo resident whose Master Profile is aligned to the synthetic
  /// Web Admin Educational Assistance record — see
  /// _applyVerifiedDemoMasterProfileAlignment. Same id RequestsService already
  /// uses for its own Perlita-specific seeding.
  static const _verifiedDemoAccountId = 'ESP-RES-2024-9002';

  /// The exact Household/Family ids from Perlita's Web Admin constituent
  /// record (see _migrateVerifiedDemoHouseholdFamilyIds) — distinct from the
  /// generic hash-derived scheme ResidentProfile.seedFrom uses for every
  /// other account.
  static const _verifiedDemoHouseholdId = 'HH-2026-9002';
  static const _verifiedDemoFamilyId = 'FAM-2026-9002';

  Map<String, ResidentProfile> _profiles = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  ResidentProfileService() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _profiles = PersistenceRecovery.decodeEntries(
          map,
          (v) => ResidentProfile.fromJson(v),
          what: 'resident profile',
        );
      }
      final perlita = _profiles[_verifiedDemoAccountId];
      if (perlita != null) {
        final fieldsChanged = _applyVerifiedDemoMasterProfileAlignment(perlita);
        final idsChanged = _migrateVerifiedDemoHouseholdFamilyIds();
        if (fieldsChanged || idsChanged) await _persist();
      }
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _profiles = {};
      await PersistenceRecovery.discardUnreadable(
        service: 'ResidentProfileService',
        keys: const [_key],
        error: error,
      );
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// Erases [accountId]'s resident profile — including the base64 profile
  /// photo, birthdate, address, household and family data — from memory and
  /// from disk. Called on sign-out.
  Future<void> forgetAccount(String accountId) async {
    _profiles.remove(accountId);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_profiles.map((k, v) => MapEntry(k, v.toJson()))));
  }

  /// Returns the profile for this citizen, creating (and persisting) a
  /// freshly-seeded one on first access. Perlita's own freshly-seeded
  /// profile additionally gets her Master Profile alignment applied right
  /// away (see _applyVerifiedDemoMasterProfileAlignment) — otherwise a device
  /// that had never opened her profile before this correction would seed a
  /// profile from her (already-corrected) CitizenAccount birthdate but
  /// still be missing the family members / school / family-background
  /// fields that only this alignment step adds.
  ResidentProfile profileFor(CitizenAccount account) {
    return _profiles.putIfAbsent(account.id, () {
      final isVerifiedDemo = account.id == _verifiedDemoAccountId;
      final profile = ResidentProfile.seedFrom(
        account,
        familyIdOverride: isVerifiedDemo ? _verifiedDemoFamilyId : null,
        householdIdOverride: isVerifiedDemo ? _verifiedDemoHouseholdId : null,
      );
      if (isVerifiedDemo) _applyVerifiedDemoMasterProfileAlignment(profile);
      return profile;
    });
  }

  /// The Web-Admin-sourced correction for Perlita Quiambao's
  /// (ESP-RES-2024-9002) resident-fact data. Her seeded profile has gone
  /// through two corrections against the Web Admin's own constituent
  /// record: first from a placeholder birthdate (Nov 29, 1988) with no
  /// family members, then from an intermediate birthdate (Jan 13, 2001)
  /// sourced from an Educational Assistance record that has since been
  /// superseded by the current synthetic profile (February 4, 2001; Single;
  /// Student — see mock_catalog.dart's CitizenAccount doc comment). Applied
  /// both to a brand-new profile (see [profileFor]'s seeding closure above)
  /// and, as a migration, to a profile a device already persisted under
  /// either older set of values (see [_restore]) — idempotent either way
  /// via the per-field equality checks below, and only ever invoked for
  /// Perlita's own specific account id, never applied generically to another
  /// resident's real data. Returns whether anything actually changed, so
  /// callers only persist when needed.
  ///
  /// Deliberately does NOT touch her Educational Assistance application's
  /// own service-specific demo fields (school, grade level, course,
  /// household monthly income) — those model an application form's own
  /// answers, not resident-identity facts, and stay exactly as they were
  /// even though they aren't part of the Constituents record below (see
  /// this correction's own report for why the two are kept separate).
  bool _applyVerifiedDemoMasterProfileAlignment(ResidentProfile p) {
    var changed = false;
    final personal = p.personal;

    void setPersonal(String current, String next, void Function(String) apply) {
      if (current != next) {
        apply(next);
        changed = true;
      }
    }

    final correctBirthdate = DateTime(2001, 3, 15);
    if (personal.birthdate != correctBirthdate) {
      personal.birthdate = correctBirthdate;
      changed = true;
    }
    setPersonal(personal.civilStatus, 'Single', (v) => personal.civilStatus = v);
    setPersonal(personal.occupation, 'Student', (v) => personal.occupation = v);
    // 'Senior High School Graduate' per the Web Admin record — the closest
    // valid option in ResidentProfileOptions.educationalAttainment's fixed
    // list is 'Senior High School' (no separate "graduate" tier exists
    // there); DropdownButtonFormField requires its value to exactly match
    // one of its own items, so an unlisted string here would crash
    // PersonalInformationScreen the moment it opens.
    setPersonal(personal.educationalAttainment, 'Senior High School', (v) => personal.educationalAttainment = v);
    // "Email: not on file" per the Web Admin record — this is her Resident
    // Profile's own contact field (personal.email), never her
    // CitizenAccount login email, which stays untouched.
    setPersonal(personal.email, '', (v) => personal.email = v);
    if (!personal.isFourPsBeneficiary) {
      personal.isFourPsBeneficiary = true;
      changed = true;
    }
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
          individualId: 'IND-$_verifiedDemoAccountId-FATHER',
          firstName: 'Anselmo',
          lastName: 'Quiambao',
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
          individualId: 'IND-$_verifiedDemoAccountId-MOTHER',
          firstName: 'Lourdes',
          lastName: 'Quiambao',
          maidenName: 'Escano',
          relationshipToHead: 'Mother',
          occupation: 'Sari-Sari Store Vendor',
          familyId: p.familyId,
          householdId: p.householdId,
        ),
      ];
      changed = true;
    }

    // Targeted migrations for a device that already persisted Father/Mother
    // before one of these corrections existed: the earlier "Anselmo Perlita" /
    // "Lourdes Perlita" placeholder surname ("Perlita" is her first name, the
    // family surname is Quiambao), and a Mother record saved before her
    // maiden name (Escano) was captured at all. The two blocks above only
    // ever *add* a Father/Mother when neither exists yet, so they never
    // reach either of these cases — fix them in place instead, never
    // duplicating the family member.
    for (final m in p.familyMembers) {
      if ((m.relationshipToHead == 'Father' || m.relationshipToHead == 'Mother') && m.lastName == 'Perlita') {
        m.lastName = 'Quiambao';
        changed = true;
      }
      if (m.relationshipToHead == 'Mother' && m.maidenName != 'Escano') {
        m.maidenName = 'Escano';
        changed = true;
      }
    }

    // Only ever applies the seeded default while the citizen hasn't saved
    // their own edit yet (see FamilyInformationScreen's Edit action and
    // ResidentProfileService.saveEmergencyContact) — once
    // emergencyContactEdited is true, this must never again overwrite
    // whatever they've saved, on this or any later app launch.
    if (!p.emergencyContactEdited) {
      setPersonal(p.emergencyContactName, 'Rogelio Escano', (v) => p.emergencyContactName = v);
      setPersonal(p.emergencyContactRelationship, 'Brother', (v) => p.emergencyContactRelationship = v);
      setPersonal(p.emergencyContactNumber, '0919 000 9012', (v) => p.emergencyContactNumber = v);
    }

    return changed;
  }

  /// [ResidentProfile.familyId]/[householdId] are immutable (`final`) once
  /// constructed — a device that already persisted Perlita's profile before
  /// her Web Admin record's exact ids (HH-2026-9002/FAM-2026-9002) were known
  /// has them fixed at whatever the old generic hash-derived scheme
  /// produced. Unlike the plain field mutations in
  /// [_applyVerifiedDemoMasterProfileAlignment], fixing these requires rebuilding
  /// the whole [ResidentProfile] (and every child record's own
  /// familyId/householdId reference) and replacing the map entry outright —
  /// same reconstruction pattern RequestsService's own identity migration
  /// uses for its immutable fields. Never touches another resident's
  /// profile, and never invented for Perlita beyond what her Web Admin
  /// record specifies.
  bool _migrateVerifiedDemoHouseholdFamilyIds() {
    final p = _profiles[_verifiedDemoAccountId];
    if (p == null || (p.familyId == _verifiedDemoFamilyId && p.householdId == _verifiedDemoHouseholdId)) return false;

    for (final m in p.familyMembers) {
      m.familyId = _verifiedDemoFamilyId;
      m.householdId = _verifiedDemoHouseholdId;
    }
    final household = p.household;
    p.household = Household(
      householdId: _verifiedDemoHouseholdId,
      barangay: household.barangay,
      sitioPurok: household.sitioPurok,
      completeAddress: household.completeAddress,
      housingOwnership: household.housingOwnership,
      housingType: household.housingType,
      numberOfRooms: household.numberOfRooms,
      waterSource: household.waterSource,
      toiletFacility: household.toiletFacility,
      electricitySource: household.electricitySource,
      hasInternetAccess: household.hasInternetAccess,
      monthlyIncome: household.monthlyIncome,
      familyIds: [_verifiedDemoFamilyId],
      otherFamilies: household.otherFamilies,
    );
    _profiles[_verifiedDemoAccountId] = ResidentProfile(
      citizenAccountId: p.citizenAccountId,
      personal: p.personal,
      familyMembers: p.familyMembers,
      familyName: p.familyName,
      headIndividualId: p.headIndividualId,
      familyId: _verifiedDemoFamilyId,
      householdId: _verifiedDemoHouseholdId,
      household: p.household,
      personalSaved: p.personalSaved,
      familySaved: p.familySaved,
      householdSaved: p.householdSaved,
      status: p.status,
      correctionMessage: p.correctionMessage,
      submittedAt: p.submittedAt,
      joinRequestSent: p.joinRequestSent,
      emergencyContactName: p.emergencyContactName,
      emergencyContactRelationship: p.emergencyContactRelationship,
      emergencyContactNumber: p.emergencyContactNumber,
      emergencyContactEdited: p.emergencyContactEdited,
      lastProfilePhotoChangeAt: p.lastProfilePhotoChangeAt,
    );
    return true;
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

  /// The household's monthly income, asked on Personal Information as the
  /// website asks it (sent as `personal.income_range`).
  Future<void> setMonthlyIncome(String accountId, String income) async {
    final p = _profiles[accountId]!;
    if (p.household.monthlyIncome == income) return;
    p.household.monthlyIncome = income;
    await _save(p);
  }

  /// Submits the profile to Esperanza LGU: PUT /citizen/resident-profile
  /// (esperanza-backend ResidentProfileService::submit()). The server sets
  /// the record "For Validation" for barangay staff; nothing on this device
  /// can mark it verified any more (the old demo verifier panel is gone).
  ///
  /// The form asks only what the backend stores (as the website's does).
  /// Throws [ApiException] on failure, and
  /// then the local status is left unchanged.
  Future<void> submit(String accountId) async {
    final p = _profiles[accountId]!;
    if (!p.editable) {
      throw const ApiException(
        messageEn: 'Your barangay office has your Resident Profile. You can change it again if they send it back.',
        messageFil: 'Nasa iyong barangay office ang iyong Resident Profile. Maaari mo itong baguhin kapag ibinalik nila.',
      );
    }
    // The family members already on the server are matched first, so a
    // resubmit updates them rather than adding them again (parity check,
    // 2026-10-22: every resubmit from the app duplicated the family).
    try {
      final current = await api.get('/citizen/resident-profile');
      if (current.data != null) _takeMemberRefs(p, current.map);
    } on ApiException {
      // Nothing on file yet, or unreachable: the PUT below says which.
    }
    final res = await api.put('/citizen/resident-profile', body: _payloadFor(p));
    _applyServerStatus(p, res.map);
    _takeMemberRefs(p, res.map);
    p.correctionMessage = null;
    p.submittedAt ??= DateTime.now();
    await _save(p);
  }

  /// What Home shows after sign-in, on opening and on resume (live test
  /// 2026-10-07, BUG-9): it showed a note from an older review, or "65%,
  /// Continue" after signing in again, while the barangay had verified the
  /// profile. The server's status is adopted; and a phone holding no
  /// submitted copy (a new sign-in, another phone) takes what the server has
  /// on file, so the resident is not asked to fill it all in again.
  Future<void> sync(CitizenAccount account) async {
    final p = profileFor(account);
    final res = await api.get('/citizen/resident-profile');
    if (res.data == null) return;
    var changed = _applyServerStatus(p, res.map);
    final onServer = p.status == VerificationStatus.verified ||
        p.status == VerificationStatus.pendingVerification ||
        p.status == VerificationStatus.needsCorrection;
    if (onServer && !p.personalSaved) {
      _adoptServerRecord(p, res.map);
      changed = true;
    }
    if (changed) {
      await _save(p);
      notifyListeners();
    }
  }

  /// Fills what this phone does not have from the server's record, never
  /// overwriting an answer already here. A choice is taken only when it is
  /// one of the form's own options (a dropdown with an unknown value fails).
  void _adoptServerRecord(ResidentProfile p, Map<String, dynamic> view) {
    String fill(String current, Object? server, [List<String>? options]) {
      if (current.trim().isNotEmpty) return current;
      final v = JsonRead.nonEmpty(server);
      if (v == null || (options != null && !options.contains(v))) return current;
      return v;
    }

    final me = JsonRead.map(view['individual']);
    final person = p.personal;
    if (me != null) {
      person.sex = fill(person.sex, me['sex'], ResidentProfileOptions.sex);
      person.birthdate ??= JsonRead.date(me['dob']);
      person.civilStatus = fill(person.civilStatus, me['civil_status'], ResidentProfileOptions.civilStatus);
      person.sitioPurok = fill(person.sitioPurok, me['sitio']);
      // The record's contact is the email when the resident gave no mobile
      // number; only a mobile number belongs in this field.
      person.mobile = fill(person.mobile, _mobileOrNull(me['contact']));
      person.occupation = fill(person.occupation, me['occupation']);
      person.educationalAttainment =
          fill(person.educationalAttainment, me['education'], ResidentProfileOptions.educationalAttainment);
      final tags = JsonRead.strings(me['tags']).toSet();
      person.isSeniorCitizen = person.isSeniorCitizen || tags.contains('Senior Citizen');
      person.isPWD = person.isPWD || tags.contains('PWD');
      person.isSoloParent = person.isSoloParent || tags.contains('Solo Parent');
      person.isVoter = person.isVoter || tags.contains('Registered Voter');
      person.isFourPsBeneficiary = person.isFourPsBeneficiary || tags.contains('4Ps');
      p.household.monthlyIncome = fill(p.household.monthlyIncome, me['income_range']);
      p.personalSaved = true;
    }

    final hh = JsonRead.map(view['household']);
    if (hh != null) {
      final h = p.household;
      h.sitioPurok = fill(h.sitioPurok, hh['sitio']);
      h.completeAddress = fill(h.completeAddress, hh['address']);
      h.housingType = fill(h.housingType, hh['dwelling_type'], ResidentProfileOptions.housingType);
      h.housingOwnership = fill(h.housingOwnership, hh['housing_tenure'], ResidentProfileOptions.housingOwnership);
      h.electricitySource = fill(h.electricitySource, hh['electricity'], ResidentProfileOptions.electricitySource);
      h.waterSource = fill(h.waterSource, hh['water'], ResidentProfileOptions.waterSource);
      h.toiletFacility = fill(h.toiletFacility, hh['toilet'], ResidentProfileOptions.toiletFacility);
      p.householdSaved = true;
    }

    final fam = JsonRead.map(view['family']);
    if (fam != null) {
      p.familyName = fill(p.familyName, fam['surname']);
      if (p.familyMembers.isEmpty) {
        for (final m in JsonRead.list(fam['members']).map(JsonRead.map).whereType<Map<String, dynamic>>()) {
          final name = JsonRead.nonEmpty(m['name']);
          if (name == null) continue;
          p.familyMembers.add(Individual(
            individualId: JsonRead.nonEmpty(m['ref']) ?? 'server-${p.familyMembers.length + 1}',
            serverRef: JsonRead.nonEmpty(m['ref']),
            firstName: name,
            sex: fill('', m['sex'], ResidentProfileOptions.sex),
            birthdate: JsonRead.date(m['dob']),
            civilStatus: fill('', m['civil_status'], ResidentProfileOptions.civilStatus),
            relationshipToHead: fill('', m['relation'], ResidentProfileOptions.relationshipToHead),
            occupation: fill('', m['occupation']),
            educationalAttainment: fill('', m['education'], ResidentProfileOptions.educationalAttainment),
            mobile: fill('', _mobileOrNull(m['contact'])),
            barangay: person.barangay,
            familyId: p.familyId,
            householdId: p.householdId,
          ));
        }
      }
      p.familySaved = true;
    }
  }

  /// Gives each family member here the server's reference for the same
  /// person (matched by name), when it does not have one yet.
  void _takeMemberRefs(ResidentProfile p, Map<String, dynamic> view) {
    final members = JsonRead.list(JsonRead.map(view['family'])?['members']).map(JsonRead.map).whereType<Map<String, dynamic>>();
    final taken = {for (final m in p.familyMembers) ?m.serverRef};
    String key(String name) => name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    for (final row in members) {
      final ref = JsonRead.nonEmpty(row['ref']);
      final name = JsonRead.nonEmpty(row['name']);
      if (ref == null || name == null || taken.contains(ref)) continue;
      for (final m in p.familyMembers) {
        if (m.serverRef == null && key(m.fullName) == key(name)) {
          m.serverRef = ref;
          taken.add(ref);
          break;
        }
      }
    }
  }

  /// A Philippine mobile number as 09XXXXXXXXX, or null for anything else.
  static String? _mobileOrNull(Object? v) {
    final n = PhMobile.normalise(JsonRead.nonEmpty(v) ?? '');
    return PhMobile.isValid(n) ? n : null;
  }

  /// GET /citizen/resident-profile: adopts the verification status barangay
  /// staff have set. A record the server has never seen (null) changes
  /// nothing.
  Future<void> syncStatus(String accountId) async {
    final p = _profiles[accountId];
    if (p == null) return;
    final res = await api.get('/citizen/resident-profile');
    if (res.data == null) return;
    if (_applyServerStatus(p, res.map)) await _save(p);
  }

  /// Individual.verification: Unverified / For Validation / Verified, and the
  /// barangay's decision (`review`). A profile the barangay sent back is
  /// Unverified with `review.outcome` 'returned' and a note saying what to
  /// change: that is Needs Correction here, with the note as the message
  /// (2026-10-06: nothing could leave Pending Verification before).
  bool _applyServerStatus(ResidentProfile p, Map<String, dynamic> view) {
    final individual = JsonRead.map(view['individual']);
    final verification = JsonRead.nonEmpty(individual?['verification']);
    final review = JsonRead.map(view['review']);
    final returned = verification == 'Unverified' && JsonRead.nonEmpty(review?['outcome']) == 'returned';
    final next = switch (verification) {
      'Verified' => VerificationStatus.verified,
      'For Validation' => VerificationStatus.pendingVerification,
      _ when returned => VerificationStatus.needsCorrection,
      _ => null,
    };
    final message = returned ? JsonRead.nonEmpty(review?['note']) : null;
    final messageChanged = next != null && message != p.correctionMessage;
    if (next != null) p.correctionMessage = message;
    final submitted = JsonRead.date(view['submitted_at'])?.toLocal();
    if (submitted != null) p.submittedAt = submitted;
    if (next == null || (next == p.status && !messageChanged)) return submitted != null;
    p.status = next;
    notifyListeners();
    return true;
  }

  static String? _text(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty || t == '—') ? null : t;
  }

  static String? _date(DateTime? d) =>
      d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _personOf(Individual i) => {
        'sex': _text(i.sex),
        'dob': _date(i.birthdate),
        'civil_status': _text(i.civilStatus),
        'occupation': _text(i.occupation),
        'education': _text(i.educationalAttainment),
        'contact': _text(i.mobile),
      };

  static Map<String, dynamic> _payloadFor(ResidentProfile p) {
    final me = p.personal;
    final h = p.household;
    return {
      'personal': {
        ..._personOf(me),
        'sitio': _text(me.sitioPurok),
        'income_range': _text(h.monthlyIncome),
        'tags': [
          if (me.isSeniorCitizen) 'Senior Citizen',
          if (me.isPWD) 'PWD',
          if (me.isSoloParent) 'Solo Parent',
          if (me.isVoter) 'Registered Voter',
          if (me.isFourPsBeneficiary) '4Ps',
        ],
      },
      'household': {
          'sitio': _text(h.sitioPurok),
          'address': _text(h.completeAddress),
          'dwelling_type': _text(h.housingType),
          'housing_tenure': _text(h.housingOwnership),
          'electricity': _text(h.electricitySource),
          'water': _text(h.waterSource),
          'toilet': _text(h.toiletFacility),
        },
      'family': {
          'surname': _text(p.familyName),
          'members': [
            for (final m in p.familyMembers)
              if (m.individualId != me.individualId && _text(m.fullName) != null)
                {
                  'ref': ?m.serverRef,
                  'name': m.fullName.trim(),
                  ..._personOf(m),
                  'relation': _text(m.relationshipToHead),
                },
          ],
        },
    };
  }
}
