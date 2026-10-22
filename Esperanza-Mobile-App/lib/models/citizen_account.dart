/// Mirrors the shape of one entry in config/esperanza_citizens.php's
/// `accounts` array — the Web Admin's mock "log in as this resident" data.
/// The mobile app's registration/profile screens produce and consume this
/// same shape so a future backend integration maps cleanly onto a
/// `residents` table + `users` row (see Section 8 of the alignment doc:
/// the Web Admin currently has no such table at all).
class CitizenAccount {
  final String id;
  final String firstName;
  final String lastName;

  /// As the server keeps it; '' when there is none (or for an account saved
  /// by an older build). Kept so a name change starts from the whole name.
  final String middleName;
  final String email;
  final String mobile;
  final String barangay;
  final String purok;
  final String address;
  final String birthdate;
  final String sex;
  final String civilStatus;
  final String occupation;
  final int profileCompleteness;

  /// The LGU's residency decision (Pending Review, Approved, Rejected...).
  final String status;

  /// Whether Esperanza currently recognises the identity (models/identity_status.dart);
  /// null before any ID was sent, or for a cached account from an older build.
  final String? identityStatus;

  /// The server's `access_level` (Verified | Unverified): Verified only while
  /// the account is Approved AND the identity is Verified. Null on an account
  /// cached by an older build, which then falls back to `status`.
  final String? serverAccessLevel;

  CitizenAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName = '',
    required this.email,
    required this.mobile,
    required this.barangay,
    required this.purok,
    required this.address,
    required this.birthdate,
    required this.sex,
    required this.civilStatus,
    required this.occupation,
    required this.profileCompleteness,
    required this.status,
    this.identityStatus,
    this.serverAccessLevel,
  });

  String get fullName => '$firstName $lastName';
  String get initials => ((firstName.isNotEmpty ? firstName[0] : '') + (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'middleName': middleName,
        'email': email,
        'mobile': mobile,
        'barangay': barangay,
        'purok': purok,
        'address': address,
        'birthdate': birthdate,
        'sex': sex,
        'civilStatus': civilStatus,
        'occupation': occupation,
        'profileCompleteness': profileCompleteness,
        'status': status,
        'identityStatus': identityStatus,
        'serverAccessLevel': serverAccessLevel,
      };

  factory CitizenAccount.fromJson(Map<String, dynamic> json) => CitizenAccount(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        middleName: json['middleName'] is String ? json['middleName'] as String : '',
        email: json['email'],
        mobile: json['mobile'],
        barangay: json['barangay'],
        purok: json['purok'],
        address: json['address'],
        birthdate: json['birthdate'],
        sex: json['sex'],
        civilStatus: json['civilStatus'],
        occupation: json['occupation'],
        profileCompleteness: json['profileCompleteness'],
        status: json['status'],
        identityStatus: json['identityStatus'] is String ? json['identityStatus'] as String : null,
        serverAccessLevel: json['serverAccessLevel'] is String ? json['serverAccessLevel'] as String : null,
      );
}
