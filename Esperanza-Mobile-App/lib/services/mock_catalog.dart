import '../models/announcement.dart';
import '../models/catalog_item.dart';
import '../models/citizen_account.dart';
import '../models/resident_profile.dart';

/// Static reference data copied out of the Web Admin (read-only source —
/// see config/esperanza.php, esperanza_citizens.php, esperanza_balita.php,
/// and the inline $documentTypes / $assistanceTypes arrays in
/// citizen/document-requests.blade.php + assistance-requests.blade.php).
/// This is a representative subset, not a byte-for-byte copy of every
/// barangay-specific document — see ESPERANZA_MOBILE_WEB_ALIGNMENT.md
/// Section 7 for what's intentionally trimmed for the mobile demo.
class MockCatalog {
  MockCatalog._();

  static const barangays = [
    'Agoho', 'Almero', 'Baras', 'Domorog', 'Guadalupe', 'Iligan', 'Labangtaytay',
    'Labrador', 'Libertad', 'Magsaysay', 'Masbaranon', 'Poblacion', 'Potingbato',
    'Rizal', 'San Roque', 'Santiago', 'Sorosimbajan', 'Tawad', 'Tunga', 'Villa',
  ];

  static const documentTypes = <CatalogItem>[
    CatalogItem(
      key: 'dokyu_cedula',
      name: 'Cedula (Community Tax Certificate)',
      office: "Treasurer's Office",
      fee: '₱5.00 base + ₱1.00 per ₱1,000 income',
      days: 'Same day',
      requirements: ['One (1) valid government-issued ID', 'Proof of income or Certificate of Employment (if applicable)'],
      process: ['Submit Request', 'Compute Tax Due', 'Pay Fee', 'Release'],
      icon: 'receipt',
    ),
    CatalogItem(
      key: 'dokyu_barangay_clearance',
      name: 'Barangay Clearance',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID', 'Proof of residency'],
      process: ['Submit Request', 'Verify Residency', 'Approval', 'Release'],
      icon: 'file-check',
    ),
    CatalogItem(
      key: 'dokyu_residency',
      name: 'Certificate of Residency',
      office: 'Civil Registrar',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID', 'Barangay Clearance', 'Proof of residency (utility bill or lease contract)'],
      process: ['Submit Request', 'Verify Residency', 'Approval', 'Release'],
      icon: 'home',
    ),
    CatalogItem(
      key: 'dokyu_indigency',
      name: 'Certificate of Indigency',
      office: 'MSWDO',
      fee: 'Free',
      days: '2-3 working days',
      requirements: ['One (1) valid government-issued ID', 'Barangay Certification of Indigency', 'Brief interview / case assessment with MSWDO'],
      process: ['Submit Request', 'MSWDO Interview', 'Case Assessment', 'Release'],
      icon: 'heart-handshake',
    ),
    CatalogItem(
      key: 'dokyu_business_new',
      name: 'Business Permit (New Application)',
      office: 'BPLO',
      fee: '₱500.00 and up (based on capital)',
      days: '7 working days',
      requirements: ['DTI or SEC Registration', 'Barangay Business Clearance', 'Locational / Zoning Clearance', 'Sanitary Permit', 'Cedula'],
      process: ['Submit Requirements', 'Zoning & Fire Inspection', 'Assessment & Payment', 'Release'],
      icon: 'store',
    ),
    CatalogItem(
      key: 'dokyu_rpt',
      name: 'Real Property Tax Clearance',
      office: "Treasurer's Office",
      fee: '₱100.00',
      days: 'Same day',
      requirements: ['Latest Tax Declaration', 'Official Receipt of last RPT payment', 'One (1) valid government-issued ID'],
      process: ['Submit Request', 'Verify Tax Records', 'Settle Balance (if any)', 'Release'],
      icon: 'landmark',
    ),
    CatalogItem(
      key: 'mcro_live_birth',
      name: 'Certificate of Live Birth (Certified Copy)',
      office: 'Civil Registrar (MCRO)',
      fee: '₱155.00',
      days: '3-5 working days',
      requirements: ['One (1) valid government-issued ID', 'Details of the record being requested'],
      process: ['Submit Request', 'Records Verification', 'Payment', 'Release'],
      icon: 'file-text',
    ),
  ];

  static const assistanceTypes = <CatalogItem>[
    CatalogItem(
      key: 'tulong_medical',
      name: 'Medical Assistance (AICS)',
      office: 'MSWDO',
      fee: 'Free',
      days: '3-5 working days',
      amount: '₱1,000 – ₱150,000 per case',
      requirements: ['One (1) valid government-issued ID', "Medical Abstract or Doctor's prescription", 'Hospital bill or Statement of Account', 'Barangay Certificate of Indigency'],
      process: ['Submit Request', 'MSWDO Assessment', 'Approval', 'Cash / Guarantee Letter Release'],
      icon: 'stethoscope',
    ),
    CatalogItem(
      key: 'tulong_burial',
      name: 'Burial Assistance (AICS)',
      office: 'MSWDO',
      fee: 'Free',
      days: '2-3 working days',
      amount: 'Up to ₱5,000',
      requirements: ['Death Certificate', 'Valid ID of claimant', 'Proof of relationship to the deceased', 'Barangay Certificate of Indigency'],
      process: ['Submit Request', 'Verify Death Certificate', 'Approval', 'Release'],
      icon: 'flower',
    ),
    CatalogItem(
      key: 'tulong_educational',
      name: 'Educational Assistance',
      office: "MSWDO / Mayor's Office",
      fee: 'Free',
      days: '10-15 working days',
      amount: 'Tuition + allowance per semester',
      requirements: ['Certificate of Enrollment', 'Report Card (GWA 80 and above)', 'Certificate of Indigency', 'Barangay Residency Certificate'],
      process: ['Submit Requirements', 'Scholarship Committee Review', 'Approval', 'Disbursement'],
      icon: 'graduation-cap',
    ),
    CatalogItem(
      key: 'tulong_financial',
      name: 'Financial Assistance (AICS)',
      office: 'MSWDO',
      fee: 'Free',
      days: '3-5 working days',
      amount: 'Based on social worker assessment',
      requirements: ['One (1) valid government-issued ID', 'Barangay Certificate of Indigency', 'Brief interview / social case study with MSWDO'],
      process: ['Submit Request', 'Social Case Study', 'Approval', 'Release'],
      icon: 'wallet',
    ),
    CatalogItem(
      key: 'tulong_food',
      name: 'Food / Relief Assistance',
      office: 'MSWDO / MDRRMO',
      fee: 'Free',
      days: '1-2 working days',
      amount: 'Relief goods package',
      requirements: ['Barangay Certification', 'One (1) valid government-issued ID'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Distribution'],
      icon: 'package',
    ),
    CatalogItem(
      key: 'tulong_pension',
      name: 'Social Pension (Indigent Senior Citizen)',
      office: 'OSCA',
      fee: '₱100.00',
      days: '5-7 working days',
      amount: '₱1,000/month (₱3,000 per quarter)',
      requirements: ['Senior Citizen ID', 'Affidavit of no pension, income, or family support', 'Barangay Certification'],
      process: ['Submit Requirements', 'OSCA / DSWD Verification', 'Enrollment', 'Quarterly Release'],
      icon: 'users',
    ),
    CatalogItem(
      key: 'tulong_solo_parent',
      name: 'Solo Parent Cash Assistance',
      office: 'MSWDO',
      fee: 'Free',
      days: '3-5 working days',
      amount: 'Cash grant + goods, per assessment',
      requirements: ['Solo Parent ID', 'PSA Birth Certificate(s) of children', 'Barangay Certification'],
      process: ['Submit Requirements', 'MSWDO Assessment', 'Approval', 'Release'],
      icon: 'heart-handshake',
    ),
  ];

  /// Incident types a citizen can report — mirrors the Web Admin's Sakuna >
  /// Incidents module intent (config/esperanza_rbac.php's 'sakuna_incidents'
  /// submodule), scaled down to what a citizen-facing report form needs.
  static const incidentTypes = <CatalogItem>[
    CatalogItem(
      key: 'incident_flood', name: 'Flooding', office: 'MDRRMO', fee: 'Free', days: 'Immediate — 24 hrs',
      requirements: ['Location / landmark', 'Photo of the affected area if safe to take'],
      process: ['Submit Report', 'MDRRMO Validation', 'Dispatch / Response', 'Close'],
      icon: 'waves',
    ),
    CatalogItem(
      key: 'incident_fire', name: 'Fire', office: 'BFP / MDRRMO', fee: 'Free', days: 'Immediate',
      requirements: ['Location / landmark', 'Photo if safe to take'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'flame',
    ),
    CatalogItem(
      key: 'incident_landslide', name: 'Landslide', office: 'MDRRMO', fee: 'Free', days: 'Immediate — 24 hrs',
      requirements: ['Location / landmark', 'Photo of the affected area if safe to take'],
      process: ['Submit Report', 'MDRRMO Validation', 'Dispatch / Response', 'Close'],
      icon: 'mountain',
    ),
    CatalogItem(
      key: 'incident_medical', name: 'Medical Emergency', office: 'Municipal Health Office / MDRRMO', fee: 'Free', days: 'Immediate',
      requirements: ['Location / landmark', 'Nature of emergency'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'siren',
    ),
    CatalogItem(
      key: 'incident_road', name: 'Road Accident', office: 'MDRRMO / PNP', fee: 'Free', days: 'Immediate',
      requirements: ['Location / landmark', 'Photo if safe to take'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'car-crash',
    ),
    CatalogItem(
      key: 'incident_other', name: 'Other Concern', office: 'MDRRMO', fee: 'Free', days: '1-2 working days',
      requirements: ['Description of the concern', 'Location / landmark'],
      process: ['Submit Report', 'Validation', 'Response', 'Close'],
      icon: 'flag',
    ),
  ];

  static final evacuationCenters = [
    ('Poblacion Covered Court', 'Brgy. Poblacion', 'Capacity: 300'),
    ('Santiago Elementary School', 'Brgy. Santiago', 'Capacity: 180'),
    ('Labangtaytay Barangay Hall', 'Brgy. Labangtaytay', 'Capacity: 120'),
  ];

  static const emergencyHotlines = [
    ('MDRRMO Esperanza', '(056) 333-1090'),
    ('Municipal Health Office', '(056) 333-1056'),
    ('Bureau of Fire Protection', '(056) 333-1077'),
    ('PNP Esperanza', '(056) 333-1000'),
  ];

  static final directoryOffices = [
    ('Office of the Municipal Mayor', 'Hon. Ricardo M. Espallardo', '(056) 333-1021'),
    ('Municipal Social Welfare & Development Office', 'Ms. Corazon P. Villareal', '(056) 333-1044'),
    ("Municipal Treasurer's Office", 'Mr. Bienvenido T. Salazar', '(056) 333-1032'),
    ('Municipal Health Office', 'Dr. Leilani F. Domingo', '(056) 333-1056'),
    ('Office of the Municipal Civil Registrar', 'Narec N. Conag', '(056) 333-1067'),
    ('ICT Office', 'Engr. Paolo J. Reyes', '(056) 333-1099'),
  ];

  /// Section 8 of the Resident Profiling spec — a static "we found a
  /// similar family already on record" simulation, keyed by barangay. No
  /// real matching happens; this is what ResidentProfile's Family
  /// Information step checks against before showing the "Request to Join
  /// Family" banner.
  static const existingFamilyMatches = <String, ExistingFamilyMatch>{
    'Labangtaytay': ExistingFamilyMatch(familyName: 'Bautista Family', barangay: 'Labangtaytay'),
    'Agoho': ExistingFamilyMatch(familyName: 'Ferrer Family', barangay: 'Agoho'),
  };

  static final events = [
    EventItem(title: 'Fiesta ng Esperanza — Opening Program', date: 'Aug 14, 2026', time: '6:00 PM', venue: 'Municipal Plaza'),
    EventItem(title: 'Barangay Poblacion Medical Mission', date: 'Jul 18, 2026', time: '8:00 AM', venue: 'Poblacion Covered Court'),
    EventItem(title: 'Livelihood Skills Training', date: 'Jul 25, 2026', time: '1:00 PM', venue: 'Municipal Hall Conference Room'),
  ];

  static final announcements = [
    Announcement(
      id: 'bal-1',
      official: 'Esperanza LGU',
      author: 'Esperanza LGU',
      barangay: null,
      body: 'Sumali sa buong-munisipyong pagdiriwang ngayong Agosto! Street dancing, trade fair, at gabi-gabing cultural program sa Municipal Plaza. Maligayang pagdating sa lahat! 🎉',
      time: 'Posted yesterday',
      media: const PostMedia(path: 'assets/images/esperanza-aerial.jpg', type: PostMediaType.image, isAsset: true),
      likes: 214,
      shares: 18,
      comments: [
        PostComment(author: 'Ronaldo Bautista', body: 'Sama-sama tayo dito, Esperanza! 🎉', time: '20 hrs ago'),
        PostComment(author: 'Marites Ferrer', body: 'Anong oras magsisimula yung trade fair po?', time: '15 hrs ago'),
      ],
    ),
    Announcement(
      id: 'bal-2',
      official: '',
      author: 'Elmer Bantillo',
      barangay: 'Santiago',
      body: 'Successful po ang blood donation drive natin ngayong araw dito sa Brgy. Santiago! Umabot ng 40+ na donors. Maraming salamat sa lahat ng dumalo at sa Red Cross Masbate! 🩸🙏',
      time: '3 hrs ago',
      likes: 47,
      shares: 4,
      comments: [
        PostComment(author: 'Esperanza LGU', body: 'Salamat sa inyong serbisyo, Brgy. Santiago! 👏', time: '2 hrs ago'),
      ],
    ),
    Announcement(
      id: 'bal-3',
      official: 'Esperanza LGU',
      author: 'Esperanza LGU',
      barangay: null,
      body: 'Libreng anti-rabies vaccination para sa mga alagang aso at pusa sa Poblacion Covered Court ngayong Linggo, 8AM-4PM. Dalhin ang inyong alagang hayop!',
      time: '2 days ago',
      media: const PostMedia(path: 'assets/images/rectangle_cityhall.jpg', type: PostMediaType.image, isAsset: true),
      likes: 132,
      shares: 9,
      comments: const [],
    ),
    Announcement(
      id: 'bal-4',
      official: 'Esperanza LGU',
      author: 'MDRRMO Esperanza',
      barangay: null,
      body: 'Paalala: Disaster preparedness orientation sa lahat ng barangay captains bukas, 9AM sa Municipal Hall Conference Room. Mandatory ang attendance bilang parte ng Typhoon Season Readiness Program.',
      time: '4 days ago',
      likes: 58,
      shares: 12,
      comments: [
        PostComment(author: 'Marites Ferrer', body: 'Noted po, sasabihin ko sa Brgy. Captain namin.', time: '3 days ago'),
      ],
    ),
  ];

  /// One sample resident per barangay is available in the real config —
  /// this mobile demo carries a smaller representative set for the "log in
  /// as this resident" quick-demo login, mirroring the Web Admin's own
  /// frontend-only session-simulation pattern (no real password checking).
  static final demoAccounts = [
    CitizenAccount(
      id: 'ESP-RES-2024-1102',
      firstName: 'Ronaldo',
      lastName: 'Bautista',
      email: 'ronaldo.bautista@email.com',
      mobile: '0918 224 5567',
      barangay: 'Labangtaytay',
      purok: 'Purok 2',
      address: 'Purok 2, Barangay Labangtaytay, Esperanza, Masbate',
      birthdate: 'August 22, 1990',
      sex: 'Male',
      civilStatus: 'Married',
      occupation: 'Fisherman',
      profileCompleteness: 78,
      // Demo account for the "registered but not yet verified" state — see
      // Section 7 of the nav-and-access spec. Registration is complete;
      // LGU verification is still pending.
      status: 'Pending Review',
    ),
    CitizenAccount(
      id: 'ESP-RES-2024-1203',
      firstName: 'Marites',
      lastName: 'Ferrer',
      email: 'marites.ferrer@email.com',
      mobile: '0917 335 8821',
      barangay: 'Agoho',
      purok: 'Purok 1',
      address: 'Purok 1, Barangay Agoho, Esperanza, Masbate',
      birthdate: 'March 4, 1985',
      sex: 'Female',
      civilStatus: 'Married',
      occupation: 'Farmer',
      profileCompleteness: 82,
      // Demo account for the "fully verified resident" state — full
      // access to verified-only features (Dokyu/Tulong).
      status: 'Approved',
    ),
  ];
}
