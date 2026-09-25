import '../services/api_client.dart';

/// Turns the backend's per-field validation errors (`{"fields": {"email":
/// ["The email has already been taken."]}}`) into a message that says what
/// to change, in the app's Tagalog-English voice, instead of the generic
/// "May mga field na kailangang itama."
///
/// Falls back to [ApiException.message] when the server named no field
/// (wrong OTP, no connection, ...), so nothing that worked before is lost.
String registrationErrorText(ApiException e) {
  if (e.fields.isEmpty) return e.message();

  final lines = <String>[];
  e.fields.forEach((field, messages) {
    final label = _labels[field] ?? field;
    final detail = _describe(field, label, messages.join(' ').toLowerCase());
    lines.add('• $detail');
  });
  return lines.join('\n');
}

const _labels = <String, String>{
  'first_name': 'First name',
  'middle_name': 'Middle name',
  'last_name': 'Last name',
  'suffix': 'Suffix',
  'email': 'Email',
  'identifier': 'Email o mobile number',
  'mobile': 'Mobile number',
  'password': 'Password',
  'barangay': 'Barangay',
  'purok': 'Purok',
  'address': 'Address',
  'birthdate': 'Birthdate',
  'accepts_terms': 'Terms & Conditions',
};

String _describe(String field, String label, String server) {
  if (server.contains('already been taken') || server.contains('already')) {
    return switch (field) {
      'email' => 'Email: Naka-register na ang email na ito. Gumamit ng ibang email.',
      'mobile' => 'Mobile number: Naka-register na ang mobile number na ito. Gumamit ng ibang number.',
      _ => '$label: Naka-register na ito. Gumamit ng ibang $label.',
    };
  }
  if (field == 'password' && (server.contains('character') || server.contains('uppercase') || server.contains('lowercase') || server.contains('number'))) {
    return 'Password: Hindi pa natutugunan ang lahat ng requirements ng password. Tingnan ang listahan sa ibaba ng Password.';
  }
  if (field == 'identifier' && (server.contains('invalid') || server.contains('maling'))) {
    return 'Email o mobile number: Mali ang email, mobile number o password. Pakitama at subukan ulit.';
  }
  if (field == 'identifier' && (server.contains('not verified') || server.contains('beripikahin'))) {
    return 'Email o mobile number: Hindi pa na-verify ang account na ito.';
  }
  if (field == 'accepts_terms') {
    return 'Terms & Conditions: Kailangan mong tanggapin ang Terms & Conditions.';
  }
  if (server.contains('required')) {
    return '$label: Kailangan ito. Pakilagay ang $label.';
  }
  if (server.contains('valid email') || (field == 'email' && server.contains('must be'))) {
    return 'Email: Hindi valid ang email. Tingnan kung tama ang pagkakasulat (halimbawa: name@gmail.com).';
  }
  if (field == 'barangay') {
    return 'Barangay: Hindi kilalang barangay. Pumili mula sa listahan.';
  }
  if (server.contains('before today') || server.contains('valid date')) {
    return '$label: Hindi valid ang petsa. Pakitama.';
  }
  if (server.contains('may not be greater') || server.contains('too long')) {
    return '$label: Masyadong mahaba. Paikliin po.';
  }
  return '$label: May mali. Pakitama ang $label.';
}
