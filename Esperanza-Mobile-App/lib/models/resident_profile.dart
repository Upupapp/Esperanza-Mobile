/// The Resident Profiling data model — the mobile-side half of the Web
/// Admin's Constituents module (Individuals / Families / Households /
/// Pending Validation). This is entirely frontend simulation: no network
/// call is made anywhere in this file or in ResidentProfileService.
/// [Individual], [Family], and [Household] are shaped so a future backend
/// developer can map them 1:1 onto Constituents tables — see the class
/// docs below for the exact mapping each is meant to support.
///
/// Relationship rules (kept intentionally simple for this prototype):
/// - One Individual belongs to zero or one primary Family.
/// - One Family contains one or more Individuals (by ID reference, never
///   duplicated inline).
/// - One Family belongs to one Household.
/// - One Household can reference more than one Family.
library;

import 'citizen_account.dart';

/// Where a Constituents record originated — lets a future Web Admin
/// distinguish citizen self-service submissions from barangay encoding.
class RecordSource {
  static const mobileApp = 'Mobile App';
  static const barangayEncoder = 'Barangay Encoder';
}

enum VerificationStatus { draft, incomplete, pendingVerification, needsCorrection, verified }

extension VerificationStatusX on VerificationStatus {
  String get label => switch (this) {
        VerificationStatus.draft => 'Draft',
        VerificationStatus.incomplete => 'Incomplete',
        VerificationStatus.pendingVerification => 'Pending Verification',
        VerificationStatus.needsCorrection => 'Needs Correction',
        VerificationStatus.verified => 'Verified',
      };

  /// The short citizen-facing explanation shown under the status label —
  /// see Section 13 of the spec for the exact copy per state.
  String get citizenMessage => switch (this) {
        VerificationStatus.draft => 'Complete your resident and household information.',
        VerificationStatus.incomplete => 'Continue your Resident Profile.',
        VerificationStatus.pendingVerification => 'Esperanza LGU is reviewing your submission.',
        VerificationStatus.needsCorrection => 'Some information needs to be updated.',
        VerificationStatus.verified => 'Your resident profile has been verified.',
      };
}

/// Whether a profiling section (Personal/Family/Household) is untouched,
/// partly filled, or has everything its required-field checklist needs.
enum SectionStatus { notStarted, inProgress, complete }

extension SectionStatusX on SectionStatus {
  String get label => switch (this) {
        SectionStatus.notStarted => 'Not Started',
        SectionStatus.inProgress => 'In Progress',
        SectionStatus.complete => 'Complete',
      };
}

/// A single Constituents "Individual" record — the citizen's own personal
/// information (Step 1) or one family member added in Step 2. Maps to Web
/// Admin: Constituents > Individuals.
class Individual {
  final String individualId;
  String firstName;
  String middleName;
  String lastName;
  String suffix;
  String sex;
  DateTime? birthdate;
  String civilStatus;
  String mobile;
  String email;
  String barangay;
  String sitioPurok;
  String completeAddress;
  String occupation;
  String educationalAttainment;
  bool isSeniorCitizen;
  bool isPWD;
  bool isSoloParent;
  bool isVoter;
  String? photoPath;
  List<String> documentPaths;

  /// Empty for the head of the family; e.g. "Son", "Spouse" for members.
  String relationshipToHead;

  /// Family/dependent members frequently have no smartphone/account of
  /// their own — this must never be required. See Section 4.
  bool hasEsperanzaAccount;
  String? linkedCitizenAccountId;

  String? familyId;
  String? householdId;
  final String source;

  Individual({
    required this.individualId,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.suffix = '',
    this.sex = '',
    this.birthdate,
    this.civilStatus = '',
    this.mobile = '',
    this.email = '',
    this.barangay = '',
    this.sitioPurok = '',
    this.completeAddress = '',
    this.occupation = '',
    this.educationalAttainment = '',
    this.isSeniorCitizen = false,
    this.isPWD = false,
    this.isSoloParent = false,
    this.isVoter = false,
    this.photoPath,
    List<String>? documentPaths,
    this.relationshipToHead = '',
    this.hasEsperanzaAccount = false,
    this.linkedCitizenAccountId,
    this.familyId,
    this.householdId,
    this.source = RecordSource.mobileApp,
  }) : documentPaths = documentPaths ?? [];

  /// Family members are captured as a single "Full Name" field (Section
  /// 4); the citizen's own record splits first/middle/last/suffix
  /// (Section 3). Falls back to whatever was actually typed either way.
  String get fullName {
    if (middleName.trim().isEmpty && lastName.trim().isEmpty) return firstName.trim();
    final parts = [firstName, middleName, lastName].where((p) => p.trim().isNotEmpty).join(' ');
    return suffix.trim().isEmpty ? parts : '$parts ${suffix.trim()}';
  }

  int get age {
    if (birthdate == null) return 0;
    final now = DateTime.now();
    var years = now.year - birthdate!.year;
    if (now.month < birthdate!.month || (now.month == birthdate!.month && now.day < birthdate!.day)) years--;
    return years < 0 ? 0 : years;
  }

  Map<String, dynamic> toJson() => {
        'individualId': individualId,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'suffix': suffix,
        'sex': sex,
        'birthdate': birthdate?.toIso8601String(),
        'civilStatus': civilStatus,
        'mobile': mobile,
        'email': email,
        'barangay': barangay,
        'sitioPurok': sitioPurok,
        'completeAddress': completeAddress,
        'occupation': occupation,
        'educationalAttainment': educationalAttainment,
        'isSeniorCitizen': isSeniorCitizen,
        'isPWD': isPWD,
        'isSoloParent': isSoloParent,
        'isVoter': isVoter,
        'photoPath': photoPath,
        'documentPaths': documentPaths,
        'relationshipToHead': relationshipToHead,
        'hasEsperanzaAccount': hasEsperanzaAccount,
        'linkedCitizenAccountId': linkedCitizenAccountId,
        'familyId': familyId,
        'householdId': householdId,
        'source': source,
      };

  factory Individual.fromJson(Map<String, dynamic> json) => Individual(
        individualId: json['individualId'],
        firstName: json['firstName'] ?? '',
        middleName: json['middleName'] ?? '',
        lastName: json['lastName'] ?? '',
        suffix: json['suffix'] ?? '',
        sex: json['sex'] ?? '',
        birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
        civilStatus: json['civilStatus'] ?? '',
        mobile: json['mobile'] ?? '',
        email: json['email'] ?? '',
        barangay: json['barangay'] ?? '',
        sitioPurok: json['sitioPurok'] ?? '',
        completeAddress: json['completeAddress'] ?? '',
        occupation: json['occupation'] ?? '',
        educationalAttainment: json['educationalAttainment'] ?? '',
        isSeniorCitizen: json['isSeniorCitizen'] ?? false,
        isPWD: json['isPWD'] ?? false,
        isSoloParent: json['isSoloParent'] ?? false,
        isVoter: json['isVoter'] ?? false,
        photoPath: json['photoPath'],
        documentPaths: (json['documentPaths'] as List?)?.cast<String>() ?? [],
        relationshipToHead: json['relationshipToHead'] ?? '',
        hasEsperanzaAccount: json['hasEsperanzaAccount'] ?? false,
        linkedCitizenAccountId: json['linkedCitizenAccountId'],
        familyId: json['familyId'],
        householdId: json['householdId'],
        source: json['source'] ?? RecordSource.mobileApp,
      );
}

/// Maps to Web Admin: Constituents > Families. Individuals are referenced
/// by ID only (`headIndividualId` / `memberIndividualIds`) — never
/// duplicated inline — per Section 20's "don't duplicate the same
/// resident" rule.
class Family {
  final String familyId;
  String familyName;
  String headIndividualId;
  List<String> memberIndividualIds;
  String? householdId;
  String barangay;
  final String source;

  Family({
    required this.familyId,
    required this.familyName,
    required this.headIndividualId,
    List<String>? memberIndividualIds,
    this.householdId,
    this.barangay = '',
    this.source = RecordSource.mobileApp,
  }) : memberIndividualIds = memberIndividualIds ?? [];

  Map<String, dynamic> toJson() => {
        'familyId': familyId,
        'familyName': familyName,
        'headIndividualId': headIndividualId,
        'memberIndividualIds': memberIndividualIds,
        'householdId': householdId,
        'barangay': barangay,
        'source': source,
      };

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        familyId: json['familyId'],
        familyName: json['familyName'] ?? '',
        headIndividualId: json['headIndividualId'] ?? '',
        memberIndividualIds: (json['memberIndividualIds'] as List?)?.cast<String>() ?? [],
        householdId: json['householdId'],
        barangay: json['barangay'] ?? '',
        source: json['source'] ?? RecordSource.mobileApp,
      );
}

/// A lightweight reference to another family sharing this household, per
/// Section 7 — deliberately NOT a full [Family] record, since the citizen
/// is only acknowledging that family exists in the household, not
/// encoding its members. A future Web Admin integration would resolve
/// this to a real Family record once one exists.
class SimpleFamilyRef {
  final String familyId;
  final String familyName;

  const SimpleFamilyRef({required this.familyId, required this.familyName});

  Map<String, dynamic> toJson() => {'familyId': familyId, 'familyName': familyName};

  factory SimpleFamilyRef.fromJson(Map<String, dynamic> json) =>
      SimpleFamilyRef(familyId: json['familyId'], familyName: json['familyName']);
}

/// Maps to Web Admin: Constituents > Households. `familyIds` supports one
/// household containing multiple families (Section 7); resident/family
/// counts are derived from actual Family/Individual data rather than
/// re-entered by the citizen, so they can never drift out of sync.
class Household {
  final String householdId;
  String barangay;
  String sitioPurok;
  String completeAddress;
  String housingOwnership;
  String housingType;
  int numberOfRooms;
  String waterSource;
  String toiletFacility;
  String electricitySource;
  bool hasInternetAccess;
  List<String> familyIds;
  List<SimpleFamilyRef> otherFamilies;
  final String source;

  Household({
    required this.householdId,
    this.barangay = '',
    this.sitioPurok = '',
    this.completeAddress = '',
    this.housingOwnership = '',
    this.housingType = '',
    this.numberOfRooms = 0,
    this.waterSource = '',
    this.toiletFacility = '',
    this.electricitySource = '',
    this.hasInternetAccess = false,
    List<String>? familyIds,
    List<SimpleFamilyRef>? otherFamilies,
    this.source = RecordSource.mobileApp,
  })  : familyIds = familyIds ?? [],
        otherFamilies = otherFamilies ?? [];

  Map<String, dynamic> toJson() => {
        'householdId': householdId,
        'barangay': barangay,
        'sitioPurok': sitioPurok,
        'completeAddress': completeAddress,
        'housingOwnership': housingOwnership,
        'housingType': housingType,
        'numberOfRooms': numberOfRooms,
        'waterSource': waterSource,
        'toiletFacility': toiletFacility,
        'electricitySource': electricitySource,
        'hasInternetAccess': hasInternetAccess,
        'familyIds': familyIds,
        'otherFamilies': otherFamilies.map((f) => f.toJson()).toList(),
        'source': source,
      };

  factory Household.fromJson(Map<String, dynamic> json) => Household(
        householdId: json['householdId'],
        barangay: json['barangay'] ?? '',
        sitioPurok: json['sitioPurok'] ?? '',
        completeAddress: json['completeAddress'] ?? '',
        housingOwnership: json['housingOwnership'] ?? '',
        housingType: json['housingType'] ?? '',
        numberOfRooms: json['numberOfRooms'] ?? 0,
        waterSource: json['waterSource'] ?? '',
        toiletFacility: json['toiletFacility'] ?? '',
        electricitySource: json['electricitySource'] ?? '',
        hasInternetAccess: json['hasInternetAccess'] ?? false,
        familyIds: (json['familyIds'] as List?)?.cast<String>() ?? [],
        otherFamilies: (json['otherFamilies'] as List? ?? []).map((f) => SimpleFamilyRef.fromJson(f)).toList(),
        source: json['source'] ?? RecordSource.mobileApp,
      );
}

/// A simulated "we found a similar family already on record" suggestion —
/// Section 8. No real matching happens; this is a static mock lookup keyed
/// by barangay (see MockCatalog.existingFamilyMatches).
class ExistingFamilyMatch {
  final String familyName;
  final String barangay;
  const ExistingFamilyMatch({required this.familyName, required this.barangay});
}

/// The per-citizen aggregate the UI actually reads/writes — everything
/// ResidentProfileService persists for one signed-in resident. Derives
/// [family] and [household] (the Web-Admin-shaped records) from the
/// working fields below rather than keeping two copies that could drift.
class ResidentProfile {
  final String citizenAccountId;
  Individual personal;
  List<Individual> familyMembers;
  String familyName;
  String headIndividualId;
  final String familyId;
  final String householdId;
  Household household;
  bool personalSaved;
  bool familySaved;
  bool householdSaved;
  VerificationStatus status;
  String? correctionMessage;
  DateTime? submittedAt;
  bool joinRequestSent;

  ResidentProfile({
    required this.citizenAccountId,
    required this.personal,
    List<Individual>? familyMembers,
    required this.familyName,
    required this.headIndividualId,
    required this.familyId,
    required this.householdId,
    required this.household,
    this.personalSaved = false,
    this.familySaved = false,
    this.householdSaved = false,
    this.status = VerificationStatus.draft,
    this.correctionMessage,
    this.submittedAt,
    this.joinRequestSent = false,
  }) : familyMembers = familyMembers ?? [];

  /// Seeds a brand-new profile from the citizen's existing account so the
  /// Personal Information step starts pre-filled rather than blank.
  factory ResidentProfile.seedFrom(CitizenAccount account) {
    final year = DateTime.now().year;
    final shortId = account.id.hashCode.abs() % 900 + 100;
    return ResidentProfile(
      citizenAccountId: account.id,
      personal: Individual(
        individualId: account.id,
        firstName: account.firstName,
        lastName: account.lastName,
        sex: account.sex == '—' ? '' : account.sex,
        birthdate: _tryParseDisplayDate(account.birthdate),
        civilStatus: account.civilStatus == '—' ? '' : account.civilStatus,
        mobile: account.mobile,
        email: account.email,
        barangay: account.barangay,
        sitioPurok: account.purok == '—' ? '' : account.purok,
        completeAddress: account.address,
        occupation: account.occupation == '—' ? '' : account.occupation,
        householdId: 'HH-$year-$shortId',
      ),
      familyName: '${account.lastName} Family',
      headIndividualId: account.id,
      familyId: 'FAM-$year-$shortId',
      householdId: 'HH-$year-$shortId',
      household: Household(
        householdId: 'HH-$year-$shortId',
        barangay: account.barangay,
        sitioPurok: account.purok == '—' ? '' : account.purok,
        completeAddress: account.address,
      ),
    );
  }

  static DateTime? _tryParseDisplayDate(String display) {
    // Demo accounts store birthdate as "August 22, 1990" — best-effort
    // parse so the seeded profile can pre-fill the date picker; falls
    // back to null (unset) for anything that doesn't parse cleanly.
    try {
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ];
      final parts = display.replaceAll(',', '').split(' ');
      if (parts.length != 3) return null;
      final month = months.indexOf(parts[0]) + 1;
      if (month == 0) return null;
      return DateTime(int.parse(parts[2]), month, int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  // ---- Completion ---------------------------------------------------

  static const _personalWeight = 0.4;
  static const _familyWeight = 0.3;
  static const _householdWeight = 0.3;

  List<bool> get _personalRequiredFlags => [
        personal.firstName.trim().isNotEmpty,
        personal.lastName.trim().isNotEmpty,
        personal.sex.trim().isNotEmpty,
        personal.birthdate != null,
        personal.civilStatus.trim().isNotEmpty,
        personal.mobile.trim().isNotEmpty,
        personal.barangay.trim().isNotEmpty,
        personal.sitioPurok.trim().isNotEmpty,
        personal.completeAddress.trim().isNotEmpty,
        personal.occupation.trim().isNotEmpty,
      ];

  List<bool> get _householdRequiredFlags => [
        household.barangay.trim().isNotEmpty,
        household.sitioPurok.trim().isNotEmpty,
        household.completeAddress.trim().isNotEmpty,
        household.housingOwnership.trim().isNotEmpty,
        household.housingType.trim().isNotEmpty,
        household.waterSource.trim().isNotEmpty,
        household.toiletFacility.trim().isNotEmpty,
        household.electricitySource.trim().isNotEmpty,
      ];

  double get personalCompletion => _personalRequiredFlags.where((f) => f).length / _personalRequiredFlags.length;
  double get familyCompletion => familyName.trim().isNotEmpty ? 1.0 : 0.0;
  double get householdCompletion => _householdRequiredFlags.where((f) => f).length / _householdRequiredFlags.length;

  int get overallCompletionPercent => (((personalCompletion * _personalWeight) +
              (familyCompletion * _familyWeight) +
              (householdCompletion * _householdWeight)) *
          100)
      .clamp(0, 100)
      .round();

  SectionStatus get personalStatus {
    if (personalSaved && personalCompletion >= 1.0) return SectionStatus.complete;
    if (personalCompletion > 0) return SectionStatus.inProgress;
    return SectionStatus.notStarted;
  }

  SectionStatus get familyStatus {
    if (familySaved && familyCompletion >= 1.0) return SectionStatus.complete;
    if (familyName.trim().isNotEmpty || familyMembers.isNotEmpty) return SectionStatus.inProgress;
    return SectionStatus.notStarted;
  }

  SectionStatus get householdStatus {
    if (householdSaved && householdCompletion >= 1.0) return SectionStatus.complete;
    if (householdCompletion > 0) return SectionStatus.inProgress;
    return SectionStatus.notStarted;
  }

  bool get readyToSubmit =>
      personalStatus == SectionStatus.complete && familyStatus == SectionStatus.complete && householdStatus == SectionStatus.complete;

  /// All individuals in the family, including the head — used everywhere
  /// "who's in this family" needs to be shown without duplicating the
  /// head's record into [familyMembers] itself.
  List<Individual> get allFamilyIndividuals => [personal, ...familyMembers];

  Individual get headIndividual => allFamilyIndividuals.firstWhere(
        (i) => i.individualId == headIndividualId,
        orElse: () => personal,
      );

  int get householdResidentCount => 1 + familyMembers.length;
  int get householdFamilyCount => 1 + household.otherFamilies.length;
  int get documentCount => personal.documentPaths.length + (personal.photoPath != null ? 1 : 0);

  /// Derives the Web-Admin-shaped [Family] record from current state —
  /// this is what a future backend integration would actually submit.
  Family toFamily() => Family(
        familyId: familyId,
        familyName: familyName,
        headIndividualId: headIndividualId,
        memberIndividualIds: allFamilyIndividuals.map((i) => i.individualId).toList(),
        householdId: householdId,
        barangay: personal.barangay,
      );

  Map<String, dynamic> toJson() => {
        'citizenAccountId': citizenAccountId,
        'personal': personal.toJson(),
        'familyMembers': familyMembers.map((m) => m.toJson()).toList(),
        'familyName': familyName,
        'headIndividualId': headIndividualId,
        'familyId': familyId,
        'householdId': householdId,
        'household': household.toJson(),
        'personalSaved': personalSaved,
        'familySaved': familySaved,
        'householdSaved': householdSaved,
        'status': status.name,
        'correctionMessage': correctionMessage,
        'submittedAt': submittedAt?.toIso8601String(),
        'joinRequestSent': joinRequestSent,
      };

  factory ResidentProfile.fromJson(Map<String, dynamic> json) => ResidentProfile(
        citizenAccountId: json['citizenAccountId'],
        personal: Individual.fromJson(json['personal']),
        familyMembers: (json['familyMembers'] as List? ?? []).map((m) => Individual.fromJson(m)).toList(),
        familyName: json['familyName'] ?? '',
        headIndividualId: json['headIndividualId'] ?? json['citizenAccountId'],
        familyId: json['familyId'],
        householdId: json['householdId'],
        household: Household.fromJson(json['household']),
        personalSaved: json['personalSaved'] ?? false,
        familySaved: json['familySaved'] ?? false,
        householdSaved: json['householdSaved'] ?? false,
        status: VerificationStatus.values.firstWhere((s) => s.name == json['status'], orElse: () => VerificationStatus.draft),
        correctionMessage: json['correctionMessage'],
        submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
        joinRequestSent: json['joinRequestSent'] ?? false,
      );
}

/// Shared dropdown option lists for the Resident Profile forms — kept in
/// one place so Personal/Family/Household screens (and any future admin
/// mapping) all use the same category values.
class ResidentProfileOptions {
  ResidentProfileOptions._();

  static const sex = ['Male', 'Female'];
  static const civilStatus = ['Single', 'Married', 'Widowed', 'Separated', 'Divorced'];
  static const educationalAttainment = [
    'No Formal Education', 'Elementary', 'High School', 'Senior High School', 'Vocational', 'College', 'Post Graduate',
  ];
  static const relationshipToHead = [
    'Spouse', 'Son', 'Daughter', 'Parent', 'Sibling', 'Grandchild', 'Other Relative', 'Non-Relative',
  ];
  static const housingOwnership = ['Owned', 'Renting', 'Rent-Free with Consent', 'Informal Settler'];
  static const housingType = ['Concrete', 'Semi-Concrete', 'Wood', 'Mixed / Light Materials'];
  static const waterSource = ['Piped / Communal System', 'Deep Well', 'Shallow Well', 'Bottled / Refilled', 'Other'];
  static const toiletFacility = ['Water-Sealed (Own Use)', 'Water-Sealed (Shared)', 'Open Pit', 'None'];
  static const electricitySource = ['Grid-Connected (Meralco/Coop)', 'Solar', 'Shared / Informal Connection', 'None'];
}
