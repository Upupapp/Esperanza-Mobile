import '../models/citizen_account.dart';

/// The applicant block every request carries, in the website's names
/// (document-requests / assistance-requests submitRequest): who filed it, as
/// their account says.
Map<String, String> applicantFormData(CitizenAccount? account) => {
  'applicant_first_name': account?.firstName ?? '',
  'applicant_last_name': account?.lastName ?? '',
  'applicant_address': account?.address ?? '',
  'applicant_mobile': account?.mobile ?? '',
  'applicant_email': account?.email ?? '',
};
