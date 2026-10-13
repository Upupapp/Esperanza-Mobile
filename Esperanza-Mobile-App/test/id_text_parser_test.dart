// What the Add ID form fills in from the text found on photos of an ID
// (owner, 2026-10-13). The texts below are synthetic, laid out the way the
// on-phone reader returns a card's lines; no real person's ID.
import 'package:flutter_test/flutter_test.dart';

import 'package:esperanza_mobile/services/id_text_parser.dart';

void main() {
  test('National ID: the PCN, the name from its three labels, birth date and the back', () {
    const front = '''
REPUBLIKA NG PILIPINAS
Republic of the Philippines
PAMBANSANG PAGKAKAKILANLAN
1234-5678-9012-3456
Apelyido/Last Name
SINTETIKO
Mga Pangalan/Given Names
TESTA MARIA
Gitnang Apelyido/Middle Name
HALIMBAWA
Petsa ng Kapanganakan/Date of Birth
JANUARY 15, 1995
Tirahan/Address
PUROK 2, BARAS, ESPERANZA, MASBATE
''';
    const back = '''
Kasarian/Sex
FEMALE
Uri ng Dugo/Blood Type
O+
Kalagayang Sibil/Marital Status
SINGLE
Lugar ng Kapanganakan/Place of Birth
ESPERANZA, MASBATE
''';
    final r = IdTextParser.parse('philippine_national_id', front, back);
    expect(r.idNumber, '1234-5678-9012-3456');
    expect(r.holderName, 'Testa Maria Halimbawa Sintetiko');
    expect(r.birthdate, DateTime(1995, 1, 15));
    expect(r.sex, 'Female');
    expect(r.address, 'Purok 2, Baras, Esperanza, Masbate');
    expect(r.extras['blood_type'], 'O+');
    expect(r.extras['civil_status'], 'Single');
    expect(r.extras['place_of_birth'], 'Esperanza, Masbate');
  });

  test("Driver's license: number, LAST, FIRST MIDDLE name, dates in Y/M/D, restrictions", () {
    const front = '''
REPUBLIC OF THE PHILIPPINES
DRIVER'S LICENSE
Last Name, First Name, Middle Name
SINTETIKO, TESTA MARIA
Nationality Sex Date of Birth Weight (kg) Height(m)
PHL F 1995/01/15 55 1.60
Address
PUROK 2, BARAS, ESPERANZA, MASBATE
License No. Expiration Date Agency Code
N01-23-456789 2030/01/15 N01
Blood Type Eyes Color
O+ BLACK
''';
    final r = IdTextParser.parse('drivers_license', front, '');
    expect(r.idNumber, 'N01-23-456789');
    expect(r.holderName, 'Testa Maria Sintetiko');
    expect(r.birthdate, DateTime(1995, 1, 15));
    expect(r.expiresOn, DateTime(2030, 1, 15));
    expect(r.extras['blood_type'], 'O+');
  });

  test('Passport: everything from the machine-readable lines', () {
    const front = '''
PASAPORTE PASSPORT
REPUBLIKA NG PILIPINAS
P<PHLSINTETIKO<<TESTA<MARIA<<<<<<<<<<<<<<<<<
P1234567A8PHL9501155F3001159<<<<<<<<<<<<<<04
''';
    final r = IdTextParser.parse('passport', front, '');
    expect(r.idNumber, 'P1234567A');
    expect(r.holderName, 'Testa Maria Sintetiko');
    expect(r.birthdate, DateTime(1995, 1, 15));
    expect(r.expiresOn, DateTime(2030, 1, 15));
    expect(r.sex, 'Female');
    expect(r.extras['nationality'], 'Filipino');
  });

  test('SSS, PhilHealth and TIN numbers by their own formats', () {
    expect(IdTextParser.parse('sss', 'SOCIAL SECURITY SYSTEM\nSS No. 34-5678901-2\nTESTA SINTETIKO', '').idNumber, '34-5678901-2');
    expect(IdTextParser.parse('philhealth', 'PhilHealth\n12-345678901-2\nSINTETIKO, TESTA M.', '').idNumber, '12-345678901-2');
    expect(IdTextParser.parse('tin', 'TIN 123-456-789-000\nName SINTETIKO, TESTA', '').idNumber, '123-456-789-000');
  });

  test('a birth date is never taken for the number, and month-first dates read as such', () {
    final r = IdTextParser.parse('other', 'BARANGAY HEALTH WORKER ID\nID NO. BHW-0000-0001\nDATE OF BIRTH 04/12/1995', '');
    expect(r.idNumber, 'BHW-0000-0001');
    expect(r.birthdate, DateTime(1995, 4, 12));
  });

  test('nothing readable gives nothing, not a guess', () {
    final r = IdTextParser.parse('sss', 'blurry', '');
    expect(r.idNumber, isNull);
    expect(r.holderName, isNull);
    expect(r.birthdate, isNull);
  });
}
