import 'package:esperanza_mobile/utils/password_standard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the password standard', () {
    test('accepts a password that meets every requirement', () {
      expect(PasswordStandard.isValid('Maganda#2026'), isTrue);
      expect(PasswordStandard.isValid('Abcde1!x'), isTrue, reason: 'exactly 8 characters');
    });

    test('rejects a password for each single missing requirement', () {
      expect(PasswordStandard.isValid('Ab1!xyz'), isFalse, reason: 'too short');
      expect(PasswordStandard.isValid('maganda#2026'), isFalse, reason: 'no uppercase');
      expect(PasswordStandard.isValid('MAGANDA#2026'), isFalse, reason: 'no lowercase');
      expect(PasswordStandard.isValid('Maganda#Bayan'), isFalse, reason: 'no number');
      expect(PasswordStandard.isValid('Maganda2026'), isFalse, reason: 'no special character');
      expect(PasswordStandard.isValid(''), isFalse);
    });

    test('lists every unmet requirement, in Tagalog-English', () {
      final unmet = PasswordStandard.unmetMessages('abc');
      expect(unmet, hasLength(4));
      expect(unmet.first, contains('8 characters'));
      expect(PasswordStandard.unmetMessages('Maganda#2026'), isEmpty);
    });

    test('has the five requirements the checklist shows', () {
      expect(PasswordStandard.requirements.map((r) => r.emphasis), [
        '8 characters',
        '1 uppercase letter',
        '1 lowercase letter',
        '1 number',
        '1 special character',
      ]);
    });
  });
}
