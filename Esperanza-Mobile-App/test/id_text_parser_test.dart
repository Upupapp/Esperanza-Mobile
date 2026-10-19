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

  // The owner's first tries on real cards (2026-10-14), rebuilt with
  // synthetic details.

  test('National ID: a label the phone misread ("Middlie Name") is still a label, never the middle name', () {
    const front = '''
REPUBLIKA NG PILIPINAS
1234-5678-9012-3456
Apelyido/Last Name
SINTETIKO
Mga Pangalan/Given Names
TESTA MARIA
Gitnang Apelyido/Middlie Name
HALIMBAWA
Petsa ng Kapanganakan/Date of Birth
JANUARY 15, 1995
''';
    final r = IdTextParser.parse('philippine_national_id', front, '');
    expect(r.holderName, 'Testa Maria Halimbawa Sintetiko');
  });

  test('National ID: a misread surname label does not borrow the middle name\'s "Apelyido"', () {
    const front = '''
Apelyid0/Las7 Name
SINTETIKO
Mga Pangalan/Given Names
TESTA
Gitnang Apelyido/Middle Name
HALIMBAWA
''';
    expect(IdTextParser.parse('philippine_national_id', front, '').holderName, 'Testa Halimbawa Sintetiko');
  });

  test('PhilHealth: the unlabelled name by the PIN, not the fine print that says "name"', () {
    const front = '''
REPUBLIC OF THE PHILIPPINES
PHILIPPINE HEALTH INSURANCE CORPORATION
12-345678901-2
SINTETIKO, TESTA HALIMBAWA
JANUARY 15, 1995 FEMALE
PUROK 2, BARAS, ESPERANZA, MASBATE
''';
    const back = '''
Signature over printed name
The signatures may apply to all transactions
If found, please return to the nearest PhilHealth office
''';
    final r = IdTextParser.parse('philhealth', front, back);
    expect(r.idNumber, '12-345678901-2');
    expect(r.holderName, 'Testa Halimbawa Sintetiko');
    expect(r.birthdate, DateTime(1995, 1, 15));
    expect(r.sex, 'Female');
  });

  test('a "Name" label whose next line is a sentence gives no name rather than the sentence', () {
    final r = IdTextParser.parse('other', 'Name\nthe signatures may apply\n', '');
    expect(r.holderName, isNull);
  });

  test('positions on the photo pair each label with the value printed below it, whatever order the lines come in', () {
    // The phone listed every label first and every value after, as it does
    // when they fall in different text blocks.
    IdTextLine at(String t, double left, double top, double right) => IdTextLine(t, left: left, top: top, right: right, bottom: top + 20);
    final front = [
      at('Apelyido/Last Name', 300, 100, 520),
      at('Mga Pangalan/Given Names', 300, 180, 560),
      at('Gitnang Apelyido/Middle Name', 300, 260, 600),
      at('SINTETIKO', 300, 125, 460),
      at('TESTA MARIA', 300, 205, 500),
      at('HALIMBAWA', 300, 285, 470),
      at('1234-5678-9012-3456', 300, 40, 600),
    ];
    final r = IdTextParser.parseLines('philippine_national_id', front: front);
    expect(r.holderName, 'Testa Maria Halimbawa Sintetiko');
    expect(r.idNumber, '1234-5678-9012-3456');
  });

  test('National ID: the QR code is read before the printed text, and wins over its misreads', () {
    const qr = '{"DateIssued":"01 January 2024","Issuer":"PSA","subject":{"Suffix":"","lName":"SINTETIKO",'
        '"fName":"TESTA MARIA","mName":"HALIMBAWA","sex":"Female","BF":"[1,1]","DOB":"January 15, 1995",'
        '"POB":"ESPERANZA, MASBATE","PCN":"1234567890123456"},"alg":"EDDSA","signature":"synthetic"}';
    const front = 'Apelyido/Last Name\nSlNTETlKO\nMga Pangalan/Given Names\nTESTA MARlA\n';
    final r = IdTextParser.parse('philippine_national_id', front, '', codes: [qr]);
    expect(r.holderName, 'Testa Maria Halimbawa Sintetiko');
    expect(r.idNumber, '1234-5678-9012-3456');
    expect(r.birthdate, DateTime(1995, 1, 15));
    expect(r.sex, 'Female');
    expect(r.extras['place_of_birth'], 'Esperanza, Masbate');
  });

  test('a QR code that is not the National ID\'s is passed over', () {
    final r = IdTextParser.parse('philippine_national_id', '1234-5678-9012-3456', '', codes: ['https://example.invalid/x', '{"foo":1}']);
    expect(r.idNumber, '1234-5678-9012-3456');
    expect(r.holderName, isNull);
  });

  test('a number with letters the phone mistook for digits is put right', () {
    expect(IdTextParser.parse('philhealth', 'PhilHealth\n12-3456789O1-2', '').idNumber, '12-345678901-2');
  });

  test('nothing readable gives nothing, not a guess', () {
    final r = IdTextParser.parse('sss', 'blurry', '');
    expect(r.idNumber, isNull);
    expect(r.holderName, isNull);
    expect(r.birthdate, isNull);
  });
}
