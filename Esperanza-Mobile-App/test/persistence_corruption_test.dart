// FE 01 — a stored value this build cannot read must never strand the app.
//
// Every service restores itself from shared_preferences in a future started
// from its constructor. Nothing awaits that future, so a throw inside it used
// to be unhandled: the loaded/loading flag was never flipped and
// notifyListeners() never fired. For CitizenSessionService that put AuthGate on
// a CircularProgressIndicator forever, recoverable only by clearing app data.
//
// These tests write payloads the app cannot read and assert it still finishes
// starting. They are deliberately hostile in three different ways, because the
// three fail differently:
//
//   1. not JSON at all          -> jsonDecode throws
//   2. valid JSON, wrong shape  -> the cast in fromJson throws
//   3. valid JSON, right shape, unknown enum name -> firstWhere throws
//
// (3) is the realistic one. This app has already renamed persisted enum values
// in shipped builds, and all five of its shape migrations run *after* the
// decode that would have thrown.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/services/balita_service.dart';
import 'package:esperanza_mobile/services/citizen_session_service.dart';
import 'package:esperanza_mobile/services/master_file_service.dart';
import 'package:esperanza_mobile/services/notifications_service.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/services/resident_profile_service.dart';

/// The six persisted keys, as owned by their services.
const _sessionKey = 'esperanza_citizen_session';
const _requestsKey = 'esperanza_service_requests';
const _balitaKey = 'esperanza_balita_posts';
const _masterFileKey = 'esperanza_master_file_documents';
const _profilesKey = 'esperanza_resident_profiles';
const _readNotificationsKey = 'esperanza_read_notification_ids';

/// A persisted request, built from a real [ServiceRequest] rather than a
/// hand-written map, so that a new required field on the model breaks this at
/// compile time instead of silently turning these tests into no-ops.
Map<String, dynamic> _persistedRequest(String id, {String? categoryOverride}) {
  final json = ServiceRequest(
    id: id,
    referenceNumber: 'DR-2026-$id',
    applicantId: 'ESP-RES-TEST-0001',
    applicantName: 'Test Resident',
    typeName: 'Barangay Clearance',
    category: ServiceCategory.dokyu,
    office: 'MCRO',
    purpose: 'Testing',
    submittedAt: DateTime(2026, 1, 1),
    status: 'Submitted',
    statusHistory: const [],
    attachments: const [],
    flaggedRequirements: const [],
    expectedDays: '3-5 days',
    formFields: const {},
    fee: '',
  ).toJson();
  if (categoryOverride != null) json['category'] = categoryOverride;
  return json;
}

/// Lets the constructor-started `_restore()` future run to completion.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('a corrupt payload never strands the app', () {
    test('CitizenSessionService stops loading even when the session is garbage', () async {
      SharedPreferences.setMockInitialValues({_sessionKey: 'this is not json'});

      final service = CitizenSessionService();
      await _settle();

      // The whole point: the flag must flip. If this fails, AuthGate spins
      // forever and the app is unusable until app data is cleared.
      expect(service.loading, isFalse, reason: 'loading must clear even when restore fails');
      expect(service.isSignedIn, isFalse);
    });

    test('CitizenSessionService signs out on a session whose shape it cannot read', () async {
      // Valid JSON, valid object, but not a CitizenAccount.
      SharedPreferences.setMockInitialValues({
        _sessionKey: jsonEncode({'unexpected': 'shape'}),
      });

      final service = CitizenSessionService();
      await _settle();

      expect(service.loading, isFalse);
      expect(service.isSignedIn, isFalse, reason: 'half-restoring a session is worse than signing out');
    });

    test('RequestsService finishes loading when the stored list is garbage', () async {
      SharedPreferences.setMockInitialValues({_requestsKey: '{{{ not json'});

      final service = RequestsService(seedDemoData: false);
      await _settle();

      expect(service.loaded, isTrue);
    });

    test('BalitaService finishes loading when the stored list is garbage', () async {
      SharedPreferences.setMockInitialValues({_balitaKey: 'not json'});

      final service = BalitaService();
      await _settle();

      expect(service.loaded, isTrue);
    });

    test('MasterFileService finishes loading when the stored map is garbage', () async {
      SharedPreferences.setMockInitialValues({_masterFileKey: 'not json'});

      final service = MasterFileService();
      await _settle();

      expect(service.loaded, isTrue);
    });

    test('ResidentProfileService finishes loading when the stored map is garbage', () async {
      SharedPreferences.setMockInitialValues({_profilesKey: 'not json'});

      final service = ResidentProfileService();
      await _settle();

      expect(service.loaded, isTrue);
    });

    test('NotificationsService finishes loading when the stored id list is garbage', () async {
      SharedPreferences.setMockInitialValues({_readNotificationsKey: 'not json'});

      final service = NotificationsService();
      await _settle();

      expect(service.loaded, isTrue);
    });
  });

  group('an unknown enum name costs one record, not the app', () {
    test('a request whose category this build does not know is skipped, not fatal', () async {
      // The realistic upgrade failure: a persisted enum value that a later
      // build renamed or removed. Everything else about the record is valid.
      SharedPreferences.setMockInitialValues({
        _requestsKey: jsonEncode([
          _persistedRequest('req-unknown-category', categoryOverride: 'aCategoryThisBuildDoesNotHave'),
        ]),
      });

      final service = RequestsService(seedDemoData: false);
      await _settle();

      expect(service.loaded, isTrue, reason: 'one unreadable record must not stop the restore');
      expect(service.all.where((r) => r.id == 'req-unknown-category'), isEmpty,
          reason: 'skipping is honest; guessing the category would misfile the request');
    });

    test('a good record still survives alongside an unreadable one', () async {
      SharedPreferences.setMockInitialValues({
        _requestsKey: jsonEncode([
          _persistedRequest('req-bad', categoryOverride: 'notARealCategory'),
          _persistedRequest('req-good'),
        ]),
      });

      final service = RequestsService(seedDemoData: false);
      await _settle();

      // This is the reason decoding is entry-tolerant rather than all-or-
      // nothing: one bad record must not cost a citizen their whole history.
      expect(service.all.map((r) => r.id), contains('req-good'));
      expect(service.all.map((r) => r.id), isNot(contains('req-bad')));
    });

    test('an unknown attachment category degrades to `other` rather than being dropped', () {
      // AttachmentCategory has a genuinely neutral member, so unlike
      // ServiceCategory and ReceiptType it can take an orElse without
      // asserting something false.
      final attachment = Attachment.fromJson({
        'id': 'att-1',
        'fileName': 'scan.heic',
        'category': 'aFormatThisBuildDoesNotKnow',
        'sizeBytes': 1024,
        'localPath': null,
        'remoteUrl': null,
        'addedAt': DateTime(2026, 1, 1).toIso8601String(),
        'documentTypeLabel': 'Valid ID',
      });

      expect(attachment.category, AttachmentCategory.other);
      expect(attachment.fileName, 'scan.heic');
    });
  });
}
