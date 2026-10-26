import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/identity_status.dart';
import 'api_client.dart';
import 'id_portrait.dart';
import 'identity_capture.dart';
import 'digital_id_service.dart';
import 'json_read.dart';

/// What the identity status rests on (esperanza-backend CitizenWallet).
enum IdentitySource { didit, lguOfficer, lguBeforeChecks, testCheck, pending }

/// The Resident ID as the LGU issues it: active only while the account has
/// full access; suspended when the identity or the residency approval was
/// revoked; otherwise not issued yet.
enum ResidentIdState { active, suspended, notIssued }

/// Whether anyone checked one kept ID, and who. Only the LGU's verification
/// gives it the seal; Didit's check (2026-10-14: the ID verified at
/// registration, or one scanned on Didit's screen) is not the LGU's.
enum WalletDocumentStatus { uploadedNotChecked, checkedByDidit, verifiedByLgu, returnedByLgu }

extension WalletDocumentStatusX on WalletDocumentStatus {
  String get label => switch (this) {
    WalletDocumentStatus.uploadedNotChecked => 'Uploaded — Not checked',
    WalletDocumentStatus.checkedByDidit => 'Checked by Didit',
    WalletDocumentStatus.verifiedByLgu => 'Verified by the LGU',
    WalletDocumentStatus.returnedByLgu => 'Returned by the LGU',
  };
}

/// The identity check: its status and what it read. [checkedDocument] is the
/// ID the check actually applied to; no uploaded wallet ID ever is one.
class WalletIdentity {
  const WalletIdentity({this.status, this.source, this.decidedAt, this.checkedDocument});

  final IdentityStatus? status;
  final IdentitySource? source;
  final DateTime? decidedAt;
  final CheckedDocument? checkedDocument;

  String? get sourceLabel => switch (source) {
    IdentitySource.didit => 'Checked by the automated ID and selfie check',
    IdentitySource.lguOfficer => 'Decided by LGU staff',
    IdentitySource.lguBeforeChecks => 'Accepted by LGU staff before automated checks',
    IdentitySource.testCheck => 'Checked by a test check (not a live one)',
    IdentitySource.pending => 'Waiting for the check',
    null => null,
  };

  static WalletIdentity fromApi(Map<String, dynamic> json) {
    final doc = json['checked_document'];
    return WalletIdentity(
      status: IdentityStatusX.fromLabel(JsonRead.nonEmpty(json['status'])),
      source: switch (JsonRead.nonEmpty(json['source'])) {
        'didit' => IdentitySource.didit,
        'lgu_officer' => IdentitySource.lguOfficer,
        'lgu_before_checks' => IdentitySource.lguBeforeChecks,
        'test_check' => IdentitySource.testCheck,
        'pending' => IdentitySource.pending,
        _ => null,
      },
      decidedAt: JsonRead.date(json['decided_at']),
      checkedDocument: doc is Map<String, dynamic> ? CheckedDocument.fromApi(doc) : null,
    );
  }
}

class CheckedDocument {
  const CheckedDocument({this.type, this.issuingCountry, this.numberLast4, this.checkedAt});

  final String? type;
  final String? issuingCountry;
  final String? numberLast4;
  final DateTime? checkedAt;

  static CheckedDocument fromApi(Map<String, dynamic> json) => CheckedDocument(
    type: JsonRead.nonEmpty(json['type']),
    issuingCountry: JsonRead.nonEmpty(json['issuing_country']),
    numberLast4: JsonRead.nonEmpty(json['number_last4']),
    checkedAt: JsonRead.date(json['checked_at']),
  );
}

class WalletResidentId {
  const WalletResidentId({required this.state, this.suspendedBecause, this.card});

  final ResidentIdState state;

  /// 'identity_revoked' or 'approval_revoked' while suspended.
  final String? suspendedBecause;

  /// The card as the server prints it; its QR only while [state] is active.
  final DigitalIdCard? card;

  static WalletResidentId fromApi(Map<String, dynamic> json) {
    final state = switch (JsonRead.nonEmpty(json['state'])) {
      'active' => ResidentIdState.active,
      'suspended' => ResidentIdState.suspended,
      _ => ResidentIdState.notIssued,
    };
    final card = json['card'];
    return WalletResidentId(
      state: state,
      suspendedBecause: JsonRead.nonEmpty(json['suspended_because']),
      card: card is Map<String, dynamic> ? DigitalIdCard.fromApi(card, requireQr: state == ResidentIdState.active) : null,
    );
  }
}

/// What a kept ID says (2026-10-13): read off the resident's photos on the
/// phone and confirmed by them, or typed. The wallet draws its card from
/// these. Nothing here is verified by being kept.
class IdDetails {
  const IdDetails({this.idNumber, this.holderName, this.birthdate, this.sex, this.address, this.extras = const {}});

  final String? idNumber;
  final String? holderName;

  /// As printed, `yyyy-mm-dd`.
  final String? birthdate;

  /// 'Male' or 'Female'.
  final String? sex;
  final String? address;

  /// The kind's own fields: blood_type, restrictions, profession ...
  final Map<String, String> extras;

  bool get isEmpty =>
      [idNumber, holderName, birthdate, sex, address].every((v) => v == null || v.trim().isEmpty) && extras.isEmpty;

  static IdDetails fromApi(Map<String, dynamic> json) {
    final raw = json['details'];
    final extras = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final value = JsonRead.nonEmpty(v);
        if (k is String && value != null) extras[k] = value;
      });
    }
    return IdDetails(
      idNumber: JsonRead.nonEmpty(json['id_number']),
      holderName: JsonRead.nonEmpty(json['holder_name']),
      birthdate: JsonRead.nonEmpty(json['birthdate']),
      sex: JsonRead.nonEmpty(json['sex']),
      address: JsonRead.nonEmpty(json['address']),
      extras: extras,
    );
  }

  /// The fields as the API takes them; empty ones are sent empty, so a
  /// correction can clear a wrong value.
  Map<String, String> toFields() => {
    'id_number': idNumber?.trim() ?? '',
    'holder_name': holderName?.trim() ?? '',
    'birthdate': birthdate?.trim() ?? '',
    if (sex != null && sex!.isNotEmpty) 'sex': sex!,
    'address': address?.trim() ?? '',
    for (final e in extras.entries)
      if (e.value.trim().isNotEmpty) 'details[${e.key}]': e.value.trim(),
  };

  Map<String, dynamic> toJson() => {
    'id_number': idNumber?.trim(),
    'holder_name': holderName?.trim(),
    'birthdate': (birthdate?.trim().isEmpty ?? true) ? null : birthdate!.trim(),
    'sex': (sex?.isEmpty ?? true) ? null : sex,
    'address': address?.trim(),
    'details': {
      for (final e in extras.entries)
        if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
    },
  };
}

/// One government ID the resident keeps in the wallet (a Papeles document).
class WalletDocument {
  const WalletDocument({
    required this.id,
    required this.idKind,
    required this.name,
    required this.status,
    this.issuer,
    this.expiresOn,
    this.uploadedAt,
    this.frontUrl,
    this.backUrl,
    this.hasBack = false,
    this.verifiedAt,
    this.lguRemarks,
    this.details = const IdDetails(),
    this.portraitBox,
    this.checkedAt,
    this.checkSource,
    this.numberLast4,
  });

  final int id;
  final String idKind;
  final String name;
  final String? issuer;
  final DateTime? expiresOn;
  final DateTime? uploadedAt;
  final String? frontUrl;
  final String? backUrl;
  final bool hasBack;
  final WalletDocumentStatus status;

  /// When LGU staff verified or returned this upload.
  final DateTime? verifiedAt;

  /// Why LGU staff returned it, for the resident to read.
  final String? lguRemarks;

  /// What the ID says, for its card.
  final IdDetails details;

  /// Where the face is on the front photo ("x,y,w,h" fractions), or null.
  final String? portraitBox;

  /// When Didit checked it, and where: 'registration' (the ID verified at
  /// sign-up) or 'wallet' (scanned on Didit's screen). Null when it did not.
  final DateTime? checkedAt;
  final String? checkSource;

  /// The last four of the number, on a card made from a registration check
  /// that kept only those; the resident can type the rest.
  final String? numberLast4;

  /// Made from what Didit read: its photos carry no face position yet.
  bool get fromDidit => checkSource != null;

  /// The number as the card shows it: in full, or its last four.
  String? get shownNumber => details.idNumber ?? (numberLast4 == null ? null : '•••• $numberLast4');

  static WalletDocument? fromApi(Map<String, dynamic> json) {
    final id = JsonRead.integer(json['id']);
    final name = JsonRead.nonEmpty(json['name']);
    if (id == null || name == null) return null;
    return WalletDocument(
      id: id,
      idKind: JsonRead.nonEmpty(json['id_kind']) ?? 'other',
      name: name,
      issuer: JsonRead.nonEmpty(json['issuer']),
      expiresOn: JsonRead.date(json['expires_on']),
      uploadedAt: JsonRead.date(json['uploaded_at']),
      frontUrl: JsonRead.mediaUrl(json['front_url']),
      backUrl: JsonRead.mediaUrl(json['back_url']),
      hasBack: JsonRead.boolean(json['has_back']) ?? false,
      verifiedAt: JsonRead.date(json['verified_at']),
      lguRemarks: JsonRead.nonEmpty(json['lgu_remarks']),
      details: IdDetails.fromApi(json),
      portraitBox: JsonRead.nonEmpty(json['portrait_box']),
      checkedAt: JsonRead.date(json['checked_at']),
      checkSource: JsonRead.nonEmpty(json['check_source']),
      numberLast4: JsonRead.nonEmpty(json['number_last4']),
      status: switch (JsonRead.nonEmpty(json['document_status'])) {
        'checked_by_didit' => WalletDocumentStatus.checkedByDidit,
        'verified_by_lgu' => WalletDocumentStatus.verifiedByLgu,
        'returned_by_lgu' => WalletDocumentStatus.returnedByLgu,
        _ => WalletDocumentStatus.uploadedNotChecked,
      },
    );
  }
}

/// An ID the Add ID form offers. [issuer] is null for "other": the resident
/// names it, and who issued it.
class WalletIdType {
  const WalletIdType({required this.key, required this.name, this.issuer});

  final String key;
  final String name;
  final String? issuer;

  bool get isOther => key == 'other';

  static WalletIdType? fromApi(Map<String, dynamic> json) {
    final key = JsonRead.nonEmpty(json['key']);
    final name = JsonRead.nonEmpty(json['name']);
    if (key == null || name == null) return null;
    return WalletIdType(key: key, name: name, issuer: JsonRead.nonEmpty(json['issuer']));
  }
}

/// A Senior Citizen, PWD or Solo Parent ID the LGU released to the resident,
/// with the number the office wrote on it (MSWDO forms, 2026-10-26).
class WalletSectorId {
  const WalletSectorId({
    required this.sector,
    required this.name,
    required this.idNumber,
    this.issuer,
    this.holderName,
    this.category,
    this.issuedOn,
    this.validUntil,
    this.status = 'active',
    this.verifyUrl,
  });

  /// senior, pwd or solo_parent.
  final String sector;
  final String name;
  final String idNumber;
  final String? issuer;
  final String? holderName;
  final String? category;
  final DateTime? issuedOn;
  final DateTime? validUntil;

  /// active, expired or revoked.
  final String status;
  final String? verifyUrl;

  static WalletSectorId? fromApi(Map<String, dynamic> json) {
    final number = JsonRead.nonEmpty(json['id_number']);
    final name = JsonRead.nonEmpty(json['name']);
    if (number == null || name == null) return null;
    return WalletSectorId(
      sector: JsonRead.nonEmpty(json['sector']) ?? '',
      name: name,
      idNumber: number,
      issuer: JsonRead.nonEmpty(json['issuer']),
      holderName: JsonRead.nonEmpty(json['holder_name']),
      category: JsonRead.nonEmpty(json['category']),
      issuedOn: JsonRead.date(json['issued_on']),
      validUntil: JsonRead.date(json['valid_until']),
      status: JsonRead.nonEmpty(json['status']) ?? 'active',
      verifyUrl: JsonRead.nonEmpty(json['verify_url']),
    );
  }
}

/// GET /citizen/wallet (esperanza-backend CitizenWallet): identity,
/// residency, the Resident ID, the resident's uploaded IDs and the ID types,
/// each with a status of its own. Read-only: nothing the app sends sets one.
class CitizenWallet {
  const CitizenWallet({
    required this.identity,
    required this.residencyStatus,
    required this.approvalRevoked,
    required this.residentId,
    required this.documents,
    required this.idTypes,
    this.diditKinds = const [],
    this.sectorIds = const [],
  });

  final WalletIdentity identity;
  final String residencyStatus;
  final bool approvalRevoked;
  final WalletResidentId residentId;
  final List<WalletDocument> documents;
  final List<WalletIdType> idTypes;

  /// The kinds the resident can scan on Didit's screen instead of uploading;
  /// empty while the LGU has not set it up.
  final List<String> diditKinds;

  /// The Senior Citizen, PWD and Solo Parent IDs the LGU released.
  final List<WalletSectorId> sectorIds;

  static CitizenWallet fromApi(Map<String, dynamic> json) {
    Map<String, dynamic> map(Object? v) => v is Map<String, dynamic> ? v : const {};
    final residency = map(json['residency']);
    return CitizenWallet(
      identity: WalletIdentity.fromApi(map(json['identity'])),
      residencyStatus: JsonRead.nonEmpty(residency['status']) ?? '',
      approvalRevoked: JsonRead.boolean(residency['approval_revoked']) ?? false,
      residentId: WalletResidentId.fromApi(map(json['resident_id'])),
      documents: JsonRead.rows(json['documents'], WalletDocument.fromApi),
      idTypes: JsonRead.rows(json['id_types'], WalletIdType.fromApi),
      sectorIds: JsonRead.rows(json['sector_ids'], WalletSectorId.fromApi),
      diditKinds: [
        for (final k in (map(json['didit_check'])['kinds'] as List?) ?? const [])
          ?JsonRead.nonEmpty(k),
      ],
    );
  }
}

/// How a scan on Didit's screen ended (esperanza-backend WalletIdChecks).
enum WalletScanOutcome {
  /// Didit approved it: a card was made, "Checked by Didit".
  checked,

  /// A card was made, but Didit did not finish checking it.
  notChecked,

  /// Didit could not confirm the ID: no card. See [WalletScanResult.reasons].
  declined,

  /// Nothing was made (abandoned, expired, or no image came back).
  closed,

  /// Didit has not finished yet; the card appears when it does.
  pending,

  /// The resident closed Didit's screen before finishing.
  cancelled,
}

class WalletScanResult {
  const WalletScanResult(this.outcome, {this.reasons = const [], this.document});

  final WalletScanOutcome outcome;

  /// Didit's codes for why it declined (SCREEN_CAPTURE_DETECTED ...).
  final List<String> reasons;
  final WalletDocument? document;

  /// Didit's reasons, in words a resident can act on.
  String get explanation {
    final words = {
      for (final r in reasons)
        switch (r) {
          'SCREEN_CAPTURE_DETECTED' || 'PRINTED_COPY_DETECTED' || 'PORTRAIT_IMAGE_ALTERED' =>
            'Scan the ID itself, not a photo, screen or photocopy of it.',
          'DOCUMENT_EXPIRED' => 'The ID has expired.',
          'DOCUMENT_NOT_SUPPORTED_FOR_APPLICATION' || 'DOCUMENT_NOT_SUPPORTED' || 'UNSUPPORTED_DOCUMENT' =>
            'Didit does not check this kind of ID.',
          'NAME_NOT_DETECTED' ||
          'DOCUMENT_NUMBER_NOT_DETECTED' ||
          'MRZ_NOT_DETECTED' ||
          'BLURRY_IMAGE' ||
          'LOW_QUALITY_IMAGE' => 'Parts of the ID could not be read. Try again in good light, holding it steady.',
          _ => 'Didit could not confirm this ID.',
        },
    };
    return words.isEmpty ? 'Didit could not confirm this ID.' : words.join(' ');
  }
}

/// A picked image, as bytes: the preview holds them, and on Flutter Web a
/// picked file's path is a blob: URL.
typedef PickedImage = ({List<int> bytes, String filename});

class WalletService {
  WalletService._();

  static Future<CitizenWallet> fetch() async {
    final res = await api.get('/citizen/wallet');
    return CitizenWallet.fromApi(res.map);
  }

  /// POST /citizen/wallet/ids. [name] and [issuer] are sent only for
  /// "other"; a listed ID takes the server's own. [replaces] is an earlier
  /// upload this one takes the place of (the server archives it).
  static Future<WalletDocument> addId({
    required String idKind,
    required PickedImage front,
    PickedImage? back,
    String? name,
    String? issuer,
    DateTime? expiresOn,
    int? replaces,
    IdDetails details = const IdDetails(),
    String? portraitBox,
  }) async {
    final res = await api.postMultipart(
      '/citizen/wallet/ids',
      fields: {
        'id_kind': idKind,
        if (idKind == 'other' && name != null) 'name': name.trim(),
        if (idKind == 'other' && issuer != null) 'issuer': issuer.trim(),
        if (expiresOn != null) 'expires_on': _date(expiresOn),
        if (replaces != null) 'replaces': '$replaces',
        ...details.toFields()..removeWhere((_, v) => v.isEmpty),
        'portrait_box': ?portraitBox,
      },
      bytesFiles: {'front': front, 'back': ?back},
    );
    final doc = WalletDocument.fromApi(res.map);
    if (doc == null) {
      throw const ApiException(
        messageEn: 'Your ID was sent, but the reply could not be read. Pull down to refresh.',
        messageFil: 'Naipadala ang iyong ID, ngunit hindi mabasa ang sagot. Hilahin pababa para i-refresh.',
      );
    }
    return doc;
  }

  /// PATCH /citizen/wallet/ids/{id}: corrects what the ID says. A change to
  /// one the LGU verified or returned sends it back for review (server side).
  static Future<WalletDocument> updateDetails(int id, IdDetails details, {DateTime? expiresOn}) async {
    final res = await api.patch(
      '/citizen/wallet/ids/${ApiClient.segment(id)}',
      body: {...details.toJson(), 'expires_on': expiresOn == null ? null : _date(expiresOn)},
    );
    final doc = WalletDocument.fromApi(res.map);
    if (doc == null) {
      throw const ApiException(
        messageEn: 'Your changes were saved, but the reply could not be read. Pull down to refresh.',
        messageFil: 'Na-save ang iyong mga pagbabago, ngunit hindi mabasa ang sagot. Hilahin pababa para i-refresh.',
      );
    }
    return doc;
  }

  /// Scans an ID on Didit's screen (2026-10-14; only the kinds in
  /// [CitizenWallet.diditKinds]). Didit's screen opens on the same launcher as
  /// the registration check; the result is the one the server READS from
  /// Didit afterwards, never what the screen reported.
  static Future<WalletScanResult> scanWithDidit(String idKind, {int? replaces}) async {
    final opened = await api.post(
      '/citizen/wallet/ids/check',
      body: {'id_kind': idKind, 'platform': 'app', 'replaces': ?replaces},
    );
    final token = JsonRead.nonEmpty(opened.map['session_token']);
    final sessionId = JsonRead.nonEmpty(opened.map['session_id']);
    if (token == null || sessionId == null) {
      throw const ApiException(
        messageEn: 'The scan could not be started. Please try again, or upload photos instead.',
        messageFil: 'Hindi masimulan ang pag-scan. Pakisubukang muli, o i-upload ang mga larawan.',
      );
    }
    final launch = await IdentityCapture.launcher(token);
    if (launch.outcome == DiditLaunchOutcome.cancelled) return const WalletScanResult(WalletScanOutcome.cancelled);

    final synced = await api.post('/citizen/wallet/ids/check/${ApiClient.segment(sessionId)}/sync');
    final data = synced.map;
    final doc = data['document'];
    return WalletScanResult(
      switch (JsonRead.nonEmpty(data['outcome'])) {
        'checked' => WalletScanOutcome.checked,
        'not_checked' => WalletScanOutcome.notChecked,
        'declined' => WalletScanOutcome.declined,
        'closed' => WalletScanOutcome.closed,
        _ => WalletScanOutcome.pending,
      },
      reasons: [
        for (final r in (data['reasons'] as List?) ?? const [])
          ?JsonRead.nonEmpty(r),
      ],
      document: doc is Map<String, dynamic> ? WalletDocument.fromApi(doc) : null,
    );
  }

  /// Where the face is on the front photo of a card Didit made, found on
  /// the phone afterwards. Placing the face does not end Didit's check.
  static Future<void> setPortrait(int id, String portraitBox) =>
      api.patch('/citizen/wallet/ids/${ApiClient.segment(id)}', body: {'portrait_box': portraitBox});

  /// The front photo's bytes, by its signed link. Replaced in tests.
  @visibleForTesting
  static Future<Uint8List?> Function(String url) fetchImage = _fetchImage;

  static Future<Uint8List?> _fetchImage(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    return res.statusCode == 200 && res.bodyBytes.isNotEmpty ? res.bodyBytes : null;
  }

  /// Ids already tried this session, found or not: a photo with no face is
  /// not fetched again on every visit.
  static final _facesTried = <int>{};

  /// A card Didit made carries Didit's photos, with no face found on them
  /// yet: the face is found on the phone, as for an upload, and saved.
  /// Returns whether it was. Never throws: the card simply shows no picture.
  static Future<bool> placeFace(WalletDocument doc) async {
    final url = doc.frontUrl;
    if (kIsWeb || !doc.fromDidit || doc.portraitBox != null || url == null || !_facesTried.add(doc.id)) return false;
    File? file;
    try {
      final bytes = await fetchImage(url);
      if (bytes == null) return false;
      // The app's own cache: Dart's default temp folder is not always one an
      // Android app may write to.
      final dir = await (await getTemporaryDirectory()).createTemp('esperanza-id');
      file = File('${dir.path}/front.jpg');
      await file.writeAsBytes(bytes, flush: true);
      final box = await IdPortraitFinder.find(file.path, bytes);
      if (box == null) return false;
      await setPortrait(doc.id, box.encode());
      return true;
    } catch (_) {
      return false;
    } finally {
      try {
        await file?.parent.delete(recursive: true);
      } catch (_) {}
    }
  }

  /// Removes it from the wallet: archived, never deleted (Papeles rule).
  static Future<void> remove(int id) => api.post('/citizen/papeles/${ApiClient.segment(id)}/archive');

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
