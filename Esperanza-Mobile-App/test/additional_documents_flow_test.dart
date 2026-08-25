// Coverage for the "Needs Additional Documents" simulation added for the
// Web Admin -> Mobile warnings/demo-map task — distinct from a full
// rejectDemo(): the request stays active, only one specific requirement is
// flagged, the resident replaces just that document via RequestDetailScreen,
// and the request resumes its normal milestone sequence afterward.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:esperanza_mobile/models/attachment.dart';
import 'package:esperanza_mobile/models/service_request.dart';
import 'package:esperanza_mobile/screens/shared/request_detail_screen.dart';
import 'package:esperanza_mobile/services/requests_service.dart';
import 'package:esperanza_mobile/theme/app_status.dart';
import 'package:esperanza_mobile/widgets/app_button.dart';

Attachment _fakeAttachment(String fileName, String documentTypeLabel) {
  return Attachment(
    id: 'att-$fileName',
    fileName: fileName,
    category: AttachmentCategory.pdf,
    sizeBytes: 12345,
    bytes: Uint8List(0),
    addedAt: DateTime(2026, 1, 1),
    documentTypeLabel: documentTypeLabel,
  );
}

Future<RequestsService> _readyRequests(WidgetTester tester) async {
  final requests = RequestsService(seedDemoData: false);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

void main() {
  group('RequestsService.flagAdditionalDocuments / resolveAdditionalDocuments', () {
    testWidgets('flagging sets Waiting Requirements + flaggedRequirementLabel, distinct from rejectDemo', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-1044',
        applicantName: 'Cristy Bonghanoy',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: [_fakeAttachment('id.pdf', 'One (1) valid government-issued ID')],
      );

      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Proof of residency',
        reason: 'The submitted "Proof of residency" could not be verified.',
      );

      final flagged = requests.all.firstWhere((r) => r.id == request.id);
      expect(flagged.status, 'Waiting Requirements');
      expect(flagged.status, isNot('Rejected'));
      expect(flagged.flaggedRequirementLabel, 'Proof of residency');
      expect(flagged.adminRemarks, contains('Proof of residency'));
      expect(flagged.statusHistory.last.status, AppStatus.waitingRequirements.label);
      expect(flagged.statusHistory.last.actor, 'Demo Simulation');
    });

    testWidgets('resolving replaces only the flagged attachment, clears the flag, resumes at Under Verification', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-1044',
        applicantName: 'Cristy Bonghanoy',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: [
          _fakeAttachment('id.pdf', 'One (1) valid government-issued ID'),
          _fakeAttachment('old-residency.pdf', 'Proof of residency'),
        ],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Proof of residency',
        reason: 'Please resubmit.',
      );

      final newAttachment = _fakeAttachment('new-residency.pdf', 'Proof of residency');
      await requests.resolveAdditionalDocuments(request.id, newAttachment: newAttachment);

      final resolved = requests.all.firstWhere((r) => r.id == request.id);
      expect(resolved.flaggedRequirementLabel, isNull);
      expect(resolved.status, 'Under Verification');
      expect(resolved.attachments.length, 2); // replaced, not appended
      expect(
        resolved.attachments.firstWhere((a) => a.documentTypeLabel == 'Proof of residency').fileName,
        'new-residency.pdf',
      );
      // The other requirement's attachment is completely untouched.
      expect(
        resolved.attachments.firstWhere((a) => a.documentTypeLabel == 'One (1) valid government-issued ID').fileName,
        'id.pdf',
      );
      expect(resolved.statusHistory.last.actor, 'Citizen');
    });
  });

  group('RequestDetailScreen — Needs Additional Documents UI', () {
    Future<RequestsService> pumpDetail(WidgetTester tester, String requestId, RequestsService requests) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider<RequestsService>.value(
          value: requests,
          child: MaterialApp(home: RequestDetailScreen(requestId: requestId)),
        ),
      );
      await tester.pumpAndSettle();
      return requests;
    }

    Future<void> scrollToBottom(WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }

    testWidgets('flagging via Demo Controls shows the warning panel, never the Rejected panel', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-1044',
        applicantName: 'Cristy Bonghanoy',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await pumpDetail(tester, request.id, requests);
      await scrollToBottom(tester);

      await tester.tap(find.text('Request Additional Documents (Demo)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Flag Document (Demo)'));
      await tester.pumpAndSettle();

      expect(find.text('Additional Document Needed'), findsOneWidget);
      expect(find.text('Application Rejected'), findsNothing);
      expect(find.textContaining('could not be verified'), findsWidgets);
      // Demo Controls disappear while flagged (canAdvance is false — the
      // flagged 'Waiting Requirements' entry isn't part of the fixed
      // milestone sequence), matching how they disappear once Rejected.
      expect(find.text('Next Demo Step'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('resubmitting the flagged requirement clears the panel and shows the resumed timeline', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-1044',
        applicantName: 'Cristy Bonghanoy',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'One (1) valid government-issued ID',
        reason: 'Please upload a clearer copy.',
      );
      await pumpDetail(tester, request.id, requests);
      await scrollToBottom(tester);

      expect(find.text('Additional Document Needed'), findsOneWidget);

      await requests.resolveAdditionalDocuments(
        request.id,
        newAttachment: _fakeAttachment('new-id.pdf', 'One (1) valid government-issued ID'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Additional Document Needed'), findsNothing);
      final resumed = requests.all.firstWhere((r) => r.id == request.id);
      expect(resumed.status, 'Under Verification');
      expect(tester.takeException(), isNull);
    });
  });
}
