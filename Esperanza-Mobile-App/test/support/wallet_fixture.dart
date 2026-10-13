// GET /citizen/wallet as esperanza-backend CitizenWallet::view() returns it,
// for the widget tests. Synthetic identities only.

const walletIdTypes = [
  {'key': 'philippine_national_id', 'name': 'Philippine National ID (PhilSys)', 'issuer': 'Philippine Statistics Authority'},
  {'key': 'philhealth', 'name': 'PhilHealth ID', 'issuer': 'Philippine Health Insurance Corporation'},
  {'key': 'sss', 'name': 'SSS ID', 'issuer': 'Social Security System'},
  {'key': 'owwa', 'name': 'OWWA ID', 'issuer': 'Overseas Workers Welfare Administration'},
  {'key': 'drivers_license', 'name': "Driver's License", 'issuer': 'Land Transportation Office'},
  {'key': 'other', 'name': 'Other', 'issuer': null},
];

Map<String, dynamic> walletDocumentJson({
  int id = 41,
  String idKind = 'philhealth',
  String name = 'PhilHealth ID',
  String? issuer = 'Philippine Health Insurance Corporation',
  String documentStatus = 'uploaded_not_checked',
  bool hasBack = false,
  String? lguRemarks,
}) => {
  'id': id,
  'id_kind': idKind,
  'name': name,
  'issuer': issuer,
  'expires_on': null,
  'uploaded_at': '2026-10-12T08:00:00+08:00',
  'front_url': null,
  'back_url': null,
  'has_back': hasBack,
  'document_status': documentStatus,
  'identity_check': 'not_checked',
  'agency_verification': 'not_available',
  'verified_at': documentStatus == 'uploaded_not_checked' ? null : '2026-10-13T10:00:00+08:00',
  'lgu_remarks': lguRemarks,
};

/// [state] is the Resident ID's: 'active' carries the QR, anything else not.
Map<String, dynamic> walletJson({
  String accountNo = 'ESP-TEST-0100',
  String name = 'Testa Sintetiko',
  String? identity = 'Verified',
  String source = 'didit',
  String residency = 'Approved',
  bool approvalRevoked = false,
  String state = 'active',
  String? suspendedBecause,
  List<Map<String, dynamic>> documents = const [],
}) => {
  'identity': {
    'status': identity,
    'source': identity == null ? null : source,
    'decided_at': '2026-10-10T09:00:00+08:00',
    'checked_document': identity == null
        ? null
        : {'type': 'Identity Card', 'issuing_country': 'Philippines', 'number_last4': '1234', 'checked_at': '2026-10-10T09:00:00+08:00'},
  },
  'residency': {'status': residency, 'approval_revoked': approvalRevoked},
  'resident_id': {
    'state': state,
    'suspended_because': suspendedBecause,
    'card': {
      'account_no': accountNo,
      'name': name,
      'barangay': 'Poblacion',
      'purok': 'Purok 4',
      'status': residency,
      'valid': state == 'active',
      'issued_at': '2026-09-01',
      'qr': ?(state == 'active' ? 'ESPID|$accountNo|sig' : null),
      'photo_url': null,
    },
  },
  'documents': documents,
  'id_types': walletIdTypes,
};
