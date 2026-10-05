// Which catalog lines a resident must upload a file for: the same rule the
// server (RequestRequirement::needsFile) and the staff site use. QA re-run
// 2026-10-05: lines the office does itself (an interview, a thumbmark taken at
// the hall) and conditional forms ("for new registration only", "required if
// ...") must never block filing or a correction.
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/utils/requirement_document_type.dart';

void main() {
  RequirementInfo read(String label) => resolveRequirements([label]).single;

  test('a document the resident owes needs an upload', () {
    for (final label in [
      'One (1) valid government-issued ID',
      'Fire Safety Inspection Certificate (FSIC)',
      'Report Card / Form 138 (GWA 80 and above)',
    ]) {
      final r = read(label);
      expect(r.isRequired && r.requiresUpload, isTrue, reason: label);
    }
  });

  test('a conditional form is optional', () {
    for (final label in [
      'PWD ID (if applicable)',
      'Consent to Marriage (Municipal Form No. 92) — required if either party is below 21 years old',
      'Duly accomplished Municipal Form No. 97 (Certificate of Marriage) — for new registration only',
    ]) {
      expect(read(label).isRequired, isFalse, reason: label);
    }
  });

  test('a step the office or the hall does is never an upload', () {
    for (final label in [
      'Brief interview / social case study with MSWDO',
      'Right Thumbmark (to be taken at Barangay Hall)',
      'None — self-assessment worksheet',
      'Details of the record being requested',
    ]) {
      expect(read(label).requiresUpload, isFalse, reason: label);
    }
  });
}
