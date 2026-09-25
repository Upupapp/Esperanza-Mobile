import 'package:esperanza_mobile/services/api_client.dart';
import 'package:esperanza_mobile/utils/registration_error_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ApiException validation(Map<String, List<String>> fields) => ApiException(
        status: 422,
        code: 'VALIDATION_FAILED',
        messageFil: 'May mga field na kailangang itama.',
        messageEn: 'Some fields need to be corrected.',
        fields: fields,
      );

  test('a taken email names the email and says what to do', () {
    final text = registrationErrorText(validation({
      'email': ['The email has already been taken.'],
    }));
    expect(text, contains('Email'));
    expect(text, contains('Naka-register na'));
    expect(text, isNot(contains('May mga field na kailangang itama')));
  });

  test('a taken mobile number is reported separately from the email', () {
    final text = registrationErrorText(validation({
      'mobile': ['The mobile has already been taken.'],
    }));
    expect(text, contains('Mobile number'));
    expect(text, isNot(contains('Email')));
  });

  test('every failing field gets its own line', () {
    final text = registrationErrorText(validation({
      'email': ['The email has already been taken.'],
      'password': ['Dapat hindi bababa sa 8 characters ang password. / The password must be at least 8 characters.'],
    }));
    expect(text.split('\n'), hasLength(2));
    expect(text, contains('requirements ng password'));
  });

  test('with no field named it falls back to the server message', () {
    final text = registrationErrorText(const ApiException(
      status: 422,
      code: 'CONTACT_REQUIRED',
      messageFil: 'Kailangan ng email o mobile number para sa beripikasyon.',
    ));
    expect(text, 'Kailangan ng email o mobile number para sa beripikasyon.');
  });

  test('a rejected sign-in names email or mobile number, not the raw field key', () {
    final text = registrationErrorText(validation({
      'identifier': ['Maling identifier o password. / Invalid identifier or password.'],
    }));
    expect(text, contains('Email o mobile number'));
    expect(text, isNot(contains('identifier')));
  });
}
