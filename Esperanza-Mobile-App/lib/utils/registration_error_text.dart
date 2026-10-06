import '../services/api_client.dart';
import '../services/message_language.dart';

/// Turns the backend's per-field validation errors (`{"fields": {"email":
/// ["The email has already been taken."]}}`) into a message that says what
/// to change, instead of the generic "Some fields need to be corrected."
/// In the language chosen for messages ([MessageLanguage], English by
/// default like the app's screens: live test 2026-10-07, UX-15).
///
/// Falls back to [ApiException.message] when the server named no field
/// (wrong OTP, no connection, ...), so nothing that worked before is lost.
String registrationErrorText(ApiException e) {
  if (e.fields.isEmpty) return e.message();

  final lines = <String>[];
  e.fields.forEach((field, messages) {
    final label = _label(field);
    final detail = _describe(field, label, messages.join(' ').toLowerCase());
    lines.add('• $detail');
  });
  return lines.join('\n');
}

String _t(String fil, String en) => MessageLanguage.filipino.value ? fil : en;

String _label(String field) => switch (field) {
      'first_name' => 'First name',
      'middle_name' => 'Middle name',
      'last_name' => 'Last name',
      'suffix' => 'Suffix',
      'email' => 'Email',
      'identifier' => _t('Email o mobile number', 'Email or mobile number'),
      'mobile' => 'Mobile number',
      'password' => 'Password',
      'barangay' => 'Barangay',
      'purok' => 'Purok',
      'address' => 'Address',
      'birthdate' => 'Birthdate',
      'accepts_terms' => 'Terms & Conditions',
      _ => field,
    };

String _describe(String field, String label, String server) {
  if (server.contains('already been taken') || server.contains('already')) {
    return switch (field) {
      'email' => _t('Email: Naka-register na ang email na ito. Gumamit ng ibang email.',
          'Email: This email is already registered. Use another email.'),
      'mobile' => _t('Mobile number: Naka-register na ang mobile number na ito. Gumamit ng ibang number.',
          'Mobile number: This mobile number is already registered. Use another number.'),
      _ => _t('$label: Naka-register na ito. Gumamit ng ibang $label.', '$label: This is already registered. Use another $label.'),
    };
  }
  if (field == 'password' && (server.contains('character') || server.contains('uppercase') || server.contains('lowercase') || server.contains('number'))) {
    return _t('Password: Hindi pa natutugunan ang lahat ng requirements ng password. Tingnan ang listahan sa ibaba ng Password.',
        'Password: It does not meet every password requirement yet. See the list below the Password field.');
  }
  if (field == 'identifier' && (server.contains('invalid') || server.contains('maling'))) {
    return _t('$label: Mali ang email, mobile number o password. Pakitama at subukan ulit.',
        '$label: The email, mobile number or password is wrong. Check them and try again.');
  }
  if (field == 'identifier' && (server.contains('not verified') || server.contains('beripikahin'))) {
    return _t('$label: Hindi pa na-verify ang account na ito.', '$label: This account is not verified yet.');
  }
  if (field == 'accepts_terms') {
    return _t('Terms & Conditions: Kailangan mong tanggapin ang Terms & Conditions.', 'Terms & Conditions: You need to accept the Terms & Conditions.');
  }
  if (server.contains('required')) {
    return _t('$label: Kailangan ito. Pakilagay ang $label.', '$label: This is required. Please enter your $label.');
  }
  if (server.contains('valid email') || (field == 'email' && server.contains('must be'))) {
    return _t('Email: Hindi valid ang email. Tingnan kung tama ang pagkakasulat (halimbawa: name@gmail.com).',
        'Email: This is not a valid email. Check how it is written (for example: name@gmail.com).');
  }
  if (field == 'barangay') {
    return _t('Barangay: Hindi kilalang barangay. Pumili mula sa listahan.', 'Barangay: Unknown barangay. Choose one from the list.');
  }
  if (server.contains('before today') || server.contains('valid date')) {
    return _t('$label: Hindi valid ang petsa. Pakitama.', '$label: This is not a valid date. Please correct it.');
  }
  if (server.contains('may not be greater') || server.contains('too long')) {
    return _t('$label: Masyadong mahaba. Paikliin po.', '$label: Too long. Please shorten it.');
  }
  return _t('$label: May mali. Pakitama ang $label.', '$label: Something is wrong. Please correct your $label.');
}
