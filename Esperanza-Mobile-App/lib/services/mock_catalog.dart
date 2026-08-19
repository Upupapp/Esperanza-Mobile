import '../models/announcement.dart';
import '../models/catalog_item.dart';
import '../models/citizen_account.dart';
import '../models/evacuation_center.dart';
import '../models/resident_profile.dart';
import '../models/service_form_spec.dart';

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
    'Agoho',
    'Almero',
    'Baras',
    'Domorog',
    'Guadalupe',
    'Iligan',
    'Labangtaytay',
    'Labrador',
    'Libertad',
    'Magsaysay',
    'Masbaranon',
    'Poblacion',
    'Potingbato',
    'Rizal',
    'San Roque',
    'Santiago',
    'Sorosimbajan',
    'Tawad',
    'Tunga',
    'Villa',
  ];

  /// Reusable purpose options sourced from BRGY.CLEARANCE NEW.docx / BRGY.
  /// RESIDENCY.docx — both official Esperanza barangay forms use the same
  /// purpose checklist.
  static const _barangayPurposeOptions = [
    'Proof of Residency',
    'Local Employment',
    'Travel Abroad',
    'Postal ID Application',
    'Bank Requirement',
    'NBI Clearance',
    'Loan Purpose',
    'Medical / Financial Assistance',
    'Others',
  ];

  static const documentTypes = <CatalogItem>[
    CatalogItem(
      key: 'dokyu_cedula',
      name: 'Cedula (Community Tax Certificate)',
      office: "Treasurer's Office",
      fee: '₱5.00 base + ₱1.00 per ₱1,000 income',
      days: 'Same day',
      requirements: [
        'One (1) valid government-issued ID',
        'Proof of income or Certificate of Employment (if applicable)',
      ],
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
      // Sourced: BRGY.CLEARANCE NEW.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Clearance Details',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(
                key: 'purpose',
                label: 'Purpose',
                type: ServiceFieldType.select,
                options: _barangayPurposeOptions,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_residency',
      name: 'Certificate of Residency',
      office: 'Civil Registrar',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: [
        'One (1) valid government-issued ID',
        'Barangay Clearance',
        'Proof of residency (utility bill or lease contract)',
      ],
      process: ['Submit Request', 'Verify Residency', 'Approval', 'Release'],
      icon: 'home',
      // Sourced: BRGY. RESIDENCY.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Residency Details',
            fields: [
              ServiceFormField(
                key: 'residencyType',
                label: 'Residency Type',
                type: ServiceFieldType.select,
                options: ['Permanent Resident', 'Temporary Resident', 'Renter / Lessee'],
              ),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(
                key: 'purpose',
                label: 'Purpose',
                type: ServiceFieldType.select,
                options: _barangayPurposeOptions,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_indigency',
      name: 'Certificate of Indigency',
      office: 'MSWDO',
      fee: 'Free',
      days: '2-3 working days',
      requirements: [
        'One (1) valid government-issued ID',
        'Barangay Certification of Indigency',
        'Brief interview / case assessment with MSWDO',
      ],
      process: ['Submit Request', 'MSWDO Interview', 'Case Assessment', 'Release'],
      icon: 'heart-handshake',
      // Sourced: BRGY.INDIGENCY 2024-1.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Indigency Details',
            fields: [
              ServiceFormField(
                key: 'purpose',
                label: 'Purpose',
                type: ServiceFieldType.select,
                options: [
                  'Medical Assistance',
                  'Financial Assistance',
                  'Burial Assistance',
                  'Educational Assistance (e.g. Scholarship)',
                  'Others',
                ],
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_business_new',
      name: 'Business Permit (New Application)',
      office: 'BPLO',
      fee: '₱500.00 and up (based on capital)',
      days: '7 working days',
      requirements: [
        'DTI or SEC Registration',
        'Barangay Business Clearance',
        'Locational / Zoning Clearance',
        'Sanitary Permit',
        'Cedula',
      ],
      process: ['Submit Requirements', 'Zoning & Fire Inspection', 'Assessment & Payment', 'Release'],
      icon: 'store',
    ),
    CatalogItem(
      key: 'dokyu_rpt',
      name: 'Real Property Tax Clearance',
      office: "Treasurer's Office",
      fee: '₱100.00',
      days: 'Same day',
      requirements: [
        'Latest Tax Declaration',
        'Official Receipt of last RPT payment',
        'One (1) valid government-issued ID',
      ],
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
    CatalogItem(
      key: 'dokyu_barangay_business_clearance',
      name: 'Barangay Business Clearance',
      office: 'Barangay Hall',
      fee: '₱100.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID', 'Proof of business location (lease contract or land title)'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'store',
      // Sourced: BRGY. BUSINESS CLEARANCE.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Business Details',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(key: 'businessName', label: 'Business Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'businessNature', label: 'Nature of Business', type: ServiceFieldType.text),
              ServiceFormField(key: 'yearsOperating', label: 'Years Operating', type: ServiceFieldType.number),
              ServiceFormField(key: 'capitalAmount', label: 'Capital Amount (₱)', type: ServiceFieldType.number),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_barangay_certification',
      name: 'Barangay Certification (General Purpose)',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'file-text',
      // Sourced: Barangay Certification.docx / PSA CERTIFICATION.docx — a
      // batch of issued examples covering many purposes (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Certification Details',
            fields: [
              ServiceFormField(
                key: 'purpose',
                label: 'State the purpose of this certification',
                type: ServiceFieldType.textarea,
                hint: 'e.g. proof of residency, unemployment for TESDA, property ownership, event permit...',
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_first_time_jobseeker',
      name: 'First Time Job Seeker Certificate (RA 11261)',
      office: 'Barangay Hall',
      fee: 'Free',
      days: 'Same day',
      requirements: ['One (1) valid government-issued ID or Birth Certificate', 'Proof of Barangay residency'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'user-check',
      // Sourced: First Time Job Seeker Certificate.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Applicant Details',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(
                key: 'confirmFirstTime',
                label: 'I confirm this is my first time seeking employment and I have never been previously employed.',
                type: ServiceFieldType.checkbox,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_marriage_license',
      name: 'Application for Marriage License',
      office: 'Civil Registrar (MCRO)',
      fee: '₱300.00',
      days: '10 working days (includes 10-day posting period)',
      requirements: [
        'PSA Birth Certificate of both parties',
        'Community Tax Certificate (Cedula) of both parties',
        'Certificate of No Marriage (CENOMAR) from PSA',
        "Parent's Consent (if 18-20 y/o) or Advice (if 21-25 y/o)",
        '2x2 ID photos of both parties',
      ],
      process: ['Submit Application', '10-Day Posting Period', 'Payment', 'Release of License'],
      icon: 'heart',
      // Sourced: MCRO - Application for Marriage License.pdf, Municipal
      // Form 90 (official). "Consent to a Marriage of Person" / "Advice
      // Upon Intended Marriage" folded in as a requirement rather than a
      // separate service, per docs/DOKYU_TULONG_FORM_AUDIT.md.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: "First Party's Information",
            fields: [
              ServiceFormField(key: 'party1FullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1DateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'party1PlaceOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1Citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1Residence', label: 'Residence', type: ServiceFieldType.text),
              ServiceFormField(key: 'party1Religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'party1CivilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Widowed', 'Divorced / Annulled'],
              ),
              ServiceFormField(key: 'party1FatherName', label: "Father's Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'party1MotherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
              ),
            ],
          ),
          ServiceFormStep(
            label: "Second Party's Information",
            fields: [
              ServiceFormField(key: 'party2FullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2DateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'party2PlaceOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2Citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2Residence', label: 'Residence', type: ServiceFieldType.text),
              ServiceFormField(key: 'party2Religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'party2CivilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Widowed', 'Divorced / Annulled'],
              ),
              ServiceFormField(key: 'party2FatherName', label: "Father's Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'party2MotherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Consent / Advice',
            description: 'Required only if either party is 18–25 years old.',
            fields: [
              ServiceFormField(
                key: 'consentGuardianName',
                label: 'Name of person giving consent/advice',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'consentGuardianRelationship',
                label: 'Relationship to applicant',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_marriage_certificate_copy',
      name: 'Certified Copy of Marriage Certificate',
      office: 'Civil Registrar (MCRO)',
      fee: '₱155.00',
      days: '3-5 working days',
      requirements: [
        'One (1) valid government-issued ID',
        'Details of the record being requested (names of husband and wife, date of marriage)',
      ],
      process: ['Submit Request', 'Records Verification', 'Payment', 'Release'],
      icon: 'file-text',
      // Sourced: "Certified Copy of Marriage certificate.pdf" (official,
      // Municipal Form 97 — the same Certificate of Marriage record also
      // referenced by MCRO - Certificate of Marriage.pdf). This is a
      // request for a copy of an ALREADY-REGISTERED marriage — distinct
      // from dokyu_marriage_license above, which is for couples preparing
      // to marry. The certificate itself is the issued-output civil
      // registry record (parties' full bio-data, parents, consent,
      // solemnizing officer's certification, witnesses, LCRO/OCRG
      // processing boxes) — none of that is citizen-fillable, so only the
      // handful of identifying facts needed to actually locate the
      // existing record are asked here, per the same "the certificate is
      // the output, not the request form" principle already applied to
      // the Delayed Registration of Birth/Death items and Certificate of
      // Fetal Death.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Marriage Record Information',
            fields: [
              ServiceFormField(key: 'husbandFullName', label: "Husband's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'wifeFullName', label: "Wife's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfMarriage', label: 'Date of Marriage', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'placeOfMarriage',
                label: 'Place of Marriage',
                type: ServiceFieldType.text,
                hint: 'City/Municipality, Province',
              ),
              ServiceFormField(
                key: 'registryNumber',
                label: 'Registry Number',
                type: ServiceFieldType.text,
                required: false,
                hint: 'If known',
              ),
              ServiceFormField(
                key: 'numberOfCopies',
                label: 'Number of Copies',
                type: ServiceFieldType.number,
                required: false,
                hint: 'Defaults to 1 if left blank',
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_delayed_birth_registration',
      name: 'Delayed Registration of Birth',
      office: 'Civil Registrar (MCRO)',
      fee: '₱200.00',
      days: '5-7 working days',
      requirements: [
        'Certificate of Non-Registration of Birth (PSA)',
        'Barangay Certification for Late Registration',
        'Baptismal Certificate or School Record, if available',
        'Affidavit of two (2) disinterested persons',
      ],
      process: ['Submit Application', 'MCRO Evaluation', 'Posting (if required)', 'Registration & Release'],
      icon: 'file-text',
      // Sourced: "Affidavit for Delayed Registration of Birth" within MCRO
      // - Certificate of Live Birth.pdf (official — pages 2-3 of that
      // file; page 1 is the issued-output record, excluded).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Birth Details',
            fields: [
              ServiceFormField(key: 'childFullName', label: "Child's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'fatherFullName', label: "Father's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'motherMaidenName', label: "Mother's Maiden Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'reasonForDelay',
                label: 'Reason for Delayed Registration',
                type: ServiceFieldType.textarea,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_delayed_death_registration',
      name: 'Delayed Registration of Death',
      office: 'Civil Registrar (MCRO)',
      fee: '₱200.00',
      days: '5-7 working days',
      requirements: [
        'Certificate of Non-Registration of Death (PSA)',
        'Barangay Certification for Registration of Death',
        'Death records from attending physician/hospital, if available',
        'Affidavit of two (2) disinterested persons',
      ],
      process: ['Submit Application', 'MCRO Evaluation', 'Posting (if required)', 'Registration & Release'],
      icon: 'file-text',
      // Sourced: "Affidavit for Delayed Registration of Death" within MCRO
      // - Certificate of Death.pdf (official — page 2 of that file; page 1
      // is the issued-output record, excluded).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Death Details',
            fields: [
              ServiceFormField(key: 'deceasedFullName', label: "Deceased's Full Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfDeath', label: 'Date of Death', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfDeath', label: 'Place of Death', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'motherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'reasonForDelay',
                label: 'Reason for Delayed Registration',
                type: ServiceFieldType.textarea,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_fetal_death',
      name: 'Certificate of Fetal Death',
      office: 'Civil Registrar (MCRO)',
      fee: '₱200.00',
      days: '5-7 working days',
      requirements: [
        'Medical Certificate of Fetal Death, signed by the attending physician, nurse, midwife, or hilot/traditional birth attendant',
        'Burial or Cremation Permit',
        'One (1) valid government-issued ID of the applicant/informant',
        'Affidavit of two (2) disinterested persons (for delayed registration)',
      ],
      process: ['Submit Application', 'MCRO Evaluation', 'Posting (if required)', 'Registration & Release'],
      icon: 'file-text',
      // Sourced: MCRO - Certificate of Fetal Death.pdf (official, Municipal
      // Form 103A). Page 1's Fetus/Mother/Father/Marriage-of-Parents
      // sections are the citizen-known identifying facts the informant can
      // actually supply; the Medical Certificate's clinical
      // disease/condition entries (item 19a-19e), the physician's/health
      // officer's own certification, the Postmortem Certificate, the
      // Embalmer's Certification, and the civil registrar's processing
      // boxes are all filled and signed by medical/registrar staff, not
      // the applicant — excluded as a source of citizen-input fields, same
      // principle already applied to the sibling Delayed Registration of
      // Birth/Death items above. "Cause of Fetal Death" and "Reason for
      // Delay" instead come from page 2's "Affidavit for Delayed
      // Registration of Fetal Death", phrased as the informant's own lay
      // statement. Item 21 "Length of Pregnancy (in completed weeks)" is
      // gestational age, not a person's age — kept as its own plain number
      // field, deliberately never folded into the Date of Birth/Age rule.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Fetal Information',
            fields: [
              ServiceFormField(
                key: 'fetusFullName',
                label: "Fetus's Name",
                type: ServiceFieldType.text,
                required: false,
                hint: 'Leave blank if the fetus was not given a name',
              ),
              ServiceFormField(
                key: 'fetusSex',
                label: 'Sex',
                type: ServiceFieldType.select,
                options: ['Male', 'Female', 'Undetermined'],
              ),
              ServiceFormField(key: 'dateOfDelivery', label: 'Date of Delivery', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'placeOfDelivery',
                label: 'Place of Delivery',
                type: ServiceFieldType.text,
                hint: 'Hospital/Clinic/Institution, Barangay, City/Municipality, Province',
              ),
              ServiceFormField(
                key: 'typeOfDelivery',
                label: 'Type of Delivery',
                type: ServiceFieldType.select,
                options: ['Single', 'Twin', 'Triplet', 'Quadruplet', 'Other'],
              ),
              ServiceFormField(
                key: 'multipleDeliveryOrder',
                label: 'If Multiple Delivery, Fetus Was',
                type: ServiceFieldType.select,
                options: ['First', 'Second', 'Third', 'Fourth', 'Other'],
                visibleWhenKey: 'typeOfDelivery',
                visibleWhenValueIn: ['Twin', 'Triplet', 'Quadruplet', 'Other'],
              ),
              ServiceFormField(
                key: 'methodOfDelivery',
                label: 'Method of Delivery',
                type: ServiceFieldType.text,
                hint: 'e.g. Normal spontaneous vertex; specify if others',
              ),
              ServiceFormField(
                key: 'birthOrder',
                label: 'Birth Order',
                type: ServiceFieldType.number,
                required: false,
                hint: 'Live births and fetal deaths including this delivery',
              ),
              ServiceFormField(
                key: 'weightOfFetus',
                label: 'Weight of Fetus (grams)',
                type: ServiceFieldType.number,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: "Mother's Information",
            fields: [
              ServiceFormField(key: 'motherMaidenName', label: "Mother's Maiden Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'motherCitizenship', label: "Mother's Citizenship", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'motherReligion',
                label: "Mother's Religion",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'motherOccupation',
                label: "Mother's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'motherAgeAtDelivery',
                label: "Mother's Age at the Time of Delivery",
                type: ServiceFieldType.number,
              ),
              ServiceFormField(
                key: 'childrenBornAlive',
                label: 'Total Number of Children Born Alive',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'childrenStillLiving',
                label: 'Number of Children Still Living',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'childrenBornAliveNowDead',
                label: 'Number of Children Born Alive but Now Dead',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'motherResidence',
                label: "Mother's Residence",
                type: ServiceFieldType.text,
                hint: 'House No., Street, Barangay, City/Municipality, Province',
              ),
            ],
          ),
          ServiceFormStep(
            label: "Father's Information",
            description: 'Leave blank if not applicable.',
            fields: [
              ServiceFormField(
                key: 'fatherFullName',
                label: "Father's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherCitizenship',
                label: "Father's Citizenship",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherReligion',
                label: "Father's Religion",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherOccupation',
                label: "Father's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'fatherAgeAtDelivery',
                label: "Father's Age at the Time of Delivery",
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'parentsMarriageDate',
                label: 'Date of Marriage of Parents',
                type: ServiceFieldType.date,
                required: false,
              ),
              ServiceFormField(
                key: 'parentsMarriagePlace',
                label: 'Place of Marriage of Parents',
                type: ServiceFieldType.text,
                required: false,
                hint: 'City/Municipality, Province, Country',
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Supporting Information',
            fields: [
              ServiceFormField(
                key: 'fetusDiedWhen',
                label: 'Fetus Died',
                type: ServiceFieldType.select,
                options: ['Before Labor', 'During Labor/Delivery', 'Unknown'],
              ),
              ServiceFormField(
                key: 'lengthOfPregnancy',
                label: 'Length of Pregnancy (completed weeks)',
                type: ServiceFieldType.number,
                hint: 'Gestational age — not the mother\'s or father\'s age',
              ),
              ServiceFormField(
                key: 'fetusAttendedStatus',
                label: 'Was the Delivery Attended',
                type: ServiceFieldType.select,
                options: ['Attended', 'Not Attended'],
              ),
              ServiceFormField(
                key: 'attendedByName',
                label: 'Attended By',
                type: ServiceFieldType.text,
                hint: 'Physician, Nurse, Midwife, Hilot/Traditional Birth Attendant, etc.',
                visibleWhenKey: 'fetusAttendedStatus',
                visibleWhenValueIn: ['Attended'],
              ),
              ServiceFormField(
                key: 'causeOfFetalDeath',
                label: 'Cause of Fetal Death',
                type: ServiceFieldType.textarea,
                hint: 'As known to you — describe in your own words',
              ),
              ServiceFormField(
                key: 'reasonForDelay',
                label: 'Reason for the Delay in Registering This Fetal Death',
                type: ServiceFieldType.textarea,
              ),
              ServiceFormField(
                key: 'corpseDisposal',
                label: 'Corpse Disposal',
                type: ServiceFieldType.select,
                options: ['Burial', 'Cremation', 'Other'],
                required: false,
              ),
              ServiceFormField(
                key: 'placeOfBurialOrCremation',
                label: 'Place of Burial/Cremation',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'dateOfBurialOrCremation',
                label: 'Date of Burial/Cremation',
                type: ServiceFieldType.date,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_barangay_cert_late_birth',
      name: 'Barangay Certification for Late Registration of Birth',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID', 'Baptismal Certificate or School Record, if available'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'file-text',
      // Sourced: BRGY.CERTIFICATION LATE REGISTRATION.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: "Person's Details",
            fields: [
              ServiceFormField(key: 'personFullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'motherMaidenName', label: "Mother's Maiden Name", type: ServiceFieldType.text),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'spouseName',
                label: "Spouse's Name (if married)",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_barangay_cert_death',
      name: 'Barangay Certification for Registration of Death',
      office: 'Barangay Hall',
      fee: '₱50.00',
      days: '1-2 working days',
      requirements: ['One (1) valid government-issued ID of claimant', 'Proof of relationship to the deceased'],
      process: ['Submit Request', 'Barangay Verification', 'Approval', 'Release'],
      icon: 'file-text',
      // Sourced: BRGY.CERTIFICATION REGISTRATION OF DEATH.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: "Deceased's Details",
            fields: [
              ServiceFormField(key: 'deceasedFullName', label: 'Full Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'motherMaidenName',
                label: "Mother's Maiden Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(key: 'dateOfDeath', label: 'Date of Death', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfDeath', label: 'Place of Death', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'citizenship', label: 'Citizenship', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_pet_registration',
      name: 'Pet Registration',
      office: 'Municipal Agriculture Office',
      fee: '₱50.00',
      days: 'Same day',
      requirements: ['Proof of rabies vaccination, if applicable', 'One (1) valid government-issued ID of owner'],
      process: ['Submit Request', 'Records Verification', 'Approval', 'Release'],
      icon: 'paw-print',
      // Sourced: PET REGISTRATION FORM.docx (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Pet Information',
            fields: [
              ServiceFormField(key: 'petName', label: "Pet's Name", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'species',
                label: 'Species',
                type: ServiceFieldType.select,
                options: ['Dog', 'Cat', 'Other'],
              ),
              ServiceFormField(key: 'breed', label: 'Breed', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'colorMarkings', label: 'Color / Markings', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'gender',
                label: 'Gender',
                type: ServiceFieldType.select,
                options: ['Male', 'Female'],
              ),
              ServiceFormField(
                key: 'dobOrApproxAge',
                label: 'Date of Birth / Approximate Age',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'microchipNumber',
                label: 'Microchip Number',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Health Information',
            fields: [
              ServiceFormField(
                key: 'lastRabiesVaccinationDate',
                label: 'Last Rabies Vaccination Date',
                type: ServiceFieldType.date,
                required: false,
              ),
              ServiceFormField(
                key: 'otherVaccinations',
                label: 'Other Vaccinations',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'spayedNeutered',
                label: 'Spayed / Neutered',
                type: ServiceFieldType.select,
                options: ['Yes', 'No', 'Unknown'],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Owner & Emergency Contact',
            fields: [
              ServiceFormField(key: 'ownerAddress', label: "Owner's Address", type: ServiceFieldType.text),
              ServiceFormField(
                key: 'emergencyContactName',
                label: 'Emergency Contact Name',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'emergencyContactNumber',
                label: 'Emergency Contact Number',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'additionalInfo',
                label: 'Additional Information',
                type: ServiceFieldType.textarea,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'dokyu_locational_clearance',
      name: 'Locational Clearance',
      office: 'Municipal Planning & Development Office (MPDO)',
      fee: '₱500.00 and up (based on project)',
      days: '5-7 working days',
      requirements: [
        'Lot Title (TCT/OCT) or Tax Declaration',
        'Barangay Clearance',
        'Vicinity / Location Map',
        'Site Development Plan (for new construction)',
      ],
      process: ['Submit Application', 'Site Evaluation', 'Assessment & Payment', 'Release'],
      icon: 'map-pin',
      // Sourced: Placeholders/Dokyu/CPDO-Application-for-Locational-
      // Clearance.pdf — no official Esperanza Locational Clearance form
      // was found, so this Placeholder is used (see audit doc). Adapted:
      // office renamed from the source's City CPDO to the municipal-level
      // equivalent, MPDO; no other City-specific details carried over.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Applicant & Representative',
            fields: [
              ServiceFormField(
                key: 'applicantType',
                label: 'Applicant Type',
                type: ServiceFieldType.select,
                options: ['Individual', 'Corporation', 'Partnership', 'Other'],
              ),
              ServiceFormField(
                key: 'authorizedRepName',
                label: "Authorized Representative's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'authorizedRepAddress',
                label: "Authorized Representative's Address",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Project Details',
            fields: [
              ServiceFormField(
                key: 'natureOfApplication',
                label: 'Nature of Application',
                type: ServiceFieldType.select,
                options: ['New Development', 'Improvement / Renovation', 'Change of Use', 'Other'],
              ),
              ServiceFormField(key: 'projectTitle', label: 'Project Title', type: ServiceFieldType.text),
              ServiceFormField(key: 'projectLocation', label: 'Project Location', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'floorArea',
                label: 'Floor Area (sqm)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'buildingHeight',
                label: 'Building Height (m)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'numberOfStoreys',
                label: 'Number of Storeys',
                type: ServiceFieldType.number,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Lot Information',
            fields: [
              ServiceFormField(key: 'lotArea', label: 'Lot Area (sqm)', type: ServiceFieldType.number),
              ServiceFormField(key: 'titleNumber', label: 'TCT / OCT No.', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'rightOverLand',
                label: 'Right Over Land',
                type: ServiceFieldType.select,
                options: ['Owner', 'Lessee', 'Other'],
              ),
              ServiceFormField(
                key: 'projectTenure',
                label: 'Project Tenure',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'zoningClassification',
                label: 'Land Use / Zoning Classification',
                type: ServiceFieldType.multiselect,
                options: [
                  'Residential',
                  'Commercial',
                  'Industrial',
                  'Institutional',
                  'Agricultural',
                  'Open Space',
                  'Forestry',
                  'Other',
                ],
              ),
            ],
          ),
        ],
      ),
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
      requirements: [
        'One (1) valid government-issued ID',
        "Medical Abstract or Doctor's prescription",
        'Hospital bill or Statement of Account',
        'Barangay Certificate of Indigency',
      ],
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
      requirements: [
        'Death Certificate',
        'Valid ID of claimant',
        'Proof of relationship to the deceased',
        'Barangay Certificate of Indigency',
      ],
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
      requirements: [
        'Certificate of Enrollment',
        'Report Card (GWA 80 and above)',
        'Certificate of Indigency',
        'Barangay Residency Certificate',
      ],
      process: ['Submit Requirements', 'Scholarship Committee Review', 'Approval', 'Disbursement'],
      icon: 'graduation-cap',
      // Field shape adapted from Placeholders/Tulong/2F5.Application-for-
      // Scholarship.pdf — that source form is actually an NCIP (Indigenous
      // Peoples) scholarship application, so its IP/ICC-specific fields
      // (ethnolinguistic group, ancestral domain, etc.) were excluded;
      // only the general applicant/school/family shape was kept. See
      // audit doc.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Student Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married'],
              ),
              ServiceFormField(key: 'schoolName', label: 'School Name', type: ServiceFieldType.text),
              ServiceFormField(key: 'yearOrGradeLevel', label: 'Year / Grade Level', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'degreeProgramOrCourse',
                label: 'Degree Program / Course',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'lastSchoolAverageGrade',
                label: 'Last School Year Average Grade',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Family Background',
            fields: [
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'fatherOccupation',
                label: "Father's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(key: 'motherName', label: "Mother's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'motherOccupation',
                label: "Mother's Occupation",
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'parentsMonthlyIncome',
                label: "Parents' Monthly Income (₱)",
                type: ServiceFieldType.number,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Additional Information',
            fields: [
              ServiceFormField(
                key: 'communityInvolvement',
                label: 'Community / School Involvement',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'postGraduationPlans',
                label: 'Plans After Graduation',
                type: ServiceFieldType.textarea,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'tulong_financial',
      name: 'Financial Assistance (AICS)',
      office: 'MSWDO',
      fee: 'Free',
      days: '3-5 working days',
      amount: 'Based on social worker assessment',
      requirements: [
        'One (1) valid government-issued ID',
        'Barangay Certificate of Indigency',
        'Brief interview / social case study with MSWDO',
      ],
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
      requirements: [
        'Senior Citizen ID',
        'Affidavit of no pension, income, or family support',
        'Barangay Certification',
      ],
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
      // Sourced: MSWD - SOLO Parent Application Form.xlsx, DSWD Annex B
      // 2023 (official) — the richest single source found in the audit.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Identifying Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated', 'Annulled'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'monthlyIncome',
                label: 'Monthly Income (₱)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'employmentStatus',
                label: 'Employment Status',
                type: ServiceFieldType.select,
                options: ['Employed', 'Self-Employed', 'Unemployed'],
              ),
              ServiceFormField(
                key: 'isPantawidBeneficiary',
                label: '4Ps (Pantawid) Beneficiary',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
              ServiceFormField(
                key: 'isIndigenousPerson',
                label: 'Indigenous Person / IP Member',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Family Composition',
            description: 'List your children / dependents.',
            fields: [
              ServiceFormField(
                key: 'familyComposition',
                label: 'Children / Dependents (name, age, relationship)',
                type: ServiceFieldType.textarea,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Classification',
            description: 'Select the circumstance that best describes your situation as a solo parent.',
            fields: [
              ServiceFormField(
                key: 'soloParentClassification',
                label: 'Circumstance of Being a Solo Parent',
                type: ServiceFieldType.select,
                options: [
                  'Birth from rape / exploitation',
                  'Spouse of OFW abroad',
                  'Widow / widower',
                  'Unmarried parent who chose to keep the child',
                  'Spouse of a person detained or imprisoned',
                  'Legal guardian / adoptive / foster parent',
                  'Spouse with permanent incapacity',
                  'Relative caring for a child within the 4th degree of consanguinity',
                  'Legal or de facto separation',
                  'Pregnant woman who will raise the child alone',
                  'Annulment / nullity of marriage',
                  'Abandonment by spouse for at least 1 year',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Needs & Emergency Contact',
            fields: [
              ServiceFormField(
                key: 'needsOrProblems',
                label: 'Needs / Problems You Would Like Assistance With',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'emergencyContactName',
                label: 'Emergency Contact Name',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'emergencyContactNumber',
                label: 'Emergency Contact Number',
                type: ServiceFieldType.text,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'tulong_senior_citizen_id',
      name: 'Senior Citizen ID Application (OSCA Membership)',
      office: 'OSCA',
      fee: 'Free',
      days: '3-5 working days',
      requirements: [
        'PSA Birth Certificate or valid ID showing birthdate',
        '2 recent 1x1 ID photos',
        'Barangay Certification',
      ],
      process: ['Submit Requirements', 'OSCA Verification', 'Approval', 'ID Release'],
      icon: 'id-card',
      // Sourced: MSWD - Senior Citizen Application Form.docx, OSCA
      // Membership Application (official). Distinct from the existing
      // Social Pension item, which is a cash-benefit program, not plain
      // membership/ID registration.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'presentOccupation',
                label: 'Present Occupation',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'annualIncome',
                label: 'Annual Income (₱)',
                type: ServiceFieldType.number,
                required: false,
              ),
              ServiceFormField(
                key: 'receivingPension',
                label: 'Currently Receiving a Pension',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
              ServiceFormField(
                key: 'philsysIdNumber',
                label: 'PhilSys ID Number',
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: "Government Service Record",
            description: 'Fill in if you previously worked in government.',
            fields: [
              ServiceFormField(
                key: 'lastGovtOffice',
                label: 'Last Government Office',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'lastGovtPosition',
                label: 'Position',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(key: 'lastGovtYear', label: 'Year', type: ServiceFieldType.text, required: false),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'tulong_pwd_registration',
      name: 'PWD Registration (PRPWD)',
      office: 'MSWD / PDAO',
      fee: 'Free',
      days: '5-7 working days',
      requirements: [
        'Medical Certificate or School/Employer Assessment confirming disability',
        '1x1 ID photo',
        'Barangay Certification',
      ],
      process: ['Submit Requirements', 'MSWD/PDAO Assessment', 'Approval', 'ID Release'],
      icon: 'accessibility',
      // Sourced: MSWD - PRPWD Form 2.pdf, DOH Philippine Registry for
      // Persons with Disability v3.0 (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'bloodType', label: 'Blood Type', type: ServiceFieldType.text, required: false),
            ],
          ),
          ServiceFormStep(
            label: 'Disability Information',
            fields: [
              ServiceFormField(
                key: 'disabilityType',
                label: 'Type of Disability',
                type: ServiceFieldType.multiselect,
                options: [
                  'Deaf / Hard of Hearing',
                  'Intellectual Disability',
                  'Learning Disability',
                  'Mental Disability',
                  'Orthopedic Disability',
                  'Physical Disability (Non-Orthopedic)',
                  'Psychosocial Disability',
                  'Speech and Language Impairment',
                  'Visual Disability',
                ],
              ),
              ServiceFormField(
                key: 'causeOfDisability',
                label: 'Cause of Disability',
                type: ServiceFieldType.multiselect,
                options: [
                  'Acquired',
                  'Cancer',
                  'Chronic Illness',
                  'Congenital / Inborn',
                  'Injury',
                  'Rare Disease',
                  'Autism Spectrum Disorder',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Education & Employment',
            fields: [
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'employmentStatus',
                label: 'Employment Status',
                type: ServiceFieldType.select,
                options: ['Employed', 'Unemployed', 'Self-Employed', 'Student', 'Not Applicable'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
            ],
          ),
          ServiceFormStep(
            label: 'Family Background',
            description: 'Fill in whichever is applicable.',
            fields: [
              ServiceFormField(key: 'fatherName', label: "Father's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'motherName', label: "Mother's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(
                key: 'guardianName',
                label: "Guardian's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'tulong_tupad',
      name: 'TUPAD Emergency Employment',
      office: 'MPESO',
      fee: 'Free',
      days: '5-10 working days',
      amount: 'Minimum wage x days engaged',
      requirements: [
        'Valid government-issued ID',
        'Barangay Certification of Residency',
        'Certificate of Indigency, if applicable',
      ],
      process: ['Submit Profile', 'MPESO Screening', 'Approval', 'Deployment & Payout'],
      icon: 'briefcase',
      // Sourced: MPESO - DOLE TUPAD PROFILE FORM.pdf, TSSD-EFIS03-010
      // (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Worker Classification',
            fields: [
              ServiceFormField(
                key: 'typeOfWorker',
                label: 'Type of Worker',
                type: ServiceFieldType.select,
                options: [
                  'Underemployed',
                  'Laid-off due to natural calamity',
                  'Laid-off due to economic crisis',
                  'Laid-off due to armed conflict',
                  'Self-employed with lost livelihood (seasonality)',
                ],
              ),
              ServiceFormField(
                key: 'specificBeneficiaryType',
                label: 'Specific Type of Beneficiary',
                type: ServiceFieldType.select,
                options: [
                  'Crop Grower / Farmer',
                  'Homebased Worker',
                  'Transport Driver',
                  'Vendor / Self-Employed',
                  'Livestock / Poultry Raiser',
                  'Fisherfolk',
                  'Laborer',
                  'PWD',
                  'Other',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Personal & Household Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'spouseName', label: "Spouse's Name", type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'monthlyIncome', label: 'Monthly Income (₱)', type: ServiceFieldType.number),
              ServiceFormField(key: 'numberOfDependents', label: 'Number of Dependents', type: ServiceFieldType.number),
              ServiceFormField(
                key: 'currentOrPreviousEmployer',
                label: 'Current / Previous Employer',
                type: ServiceFieldType.text,
                required: false,
              ),
              ServiceFormField(
                key: 'highestEducationalAttainment',
                label: 'Highest Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Skills Training',
            fields: [
              ServiceFormField(
                key: 'intentionToAvailSkillsTraining',
                label: 'I intend to avail of skills training after this project',
                type: ServiceFieldType.checkbox,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'tulong_tesda_registration',
      name: 'TESDA Skills Training Registration',
      office: 'MPESO',
      fee: 'Free',
      days: '3-5 working days',
      requirements: ['Valid government-issued ID or Birth Certificate', '2x2 ID photo'],
      process: ['Submit Profile', 'MPESO/TESDA Screening', 'Enrollment', 'Training Start'],
      icon: 'graduation-cap',
      // Sourced: MPESO - TESDA-DPA Form 1 Registration Form (MIS 03-01).pdf
      // (official).
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'email', label: 'Email / Facebook', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'nationality', label: 'Nationality', type: ServiceFieldType.text),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(
                key: 'employmentStatusBeforeTraining',
                label: 'Employment Status Before Training',
                type: ServiceFieldType.select,
                options: ['Employed', 'Unemployed', 'Self-Employed'],
              ),
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(key: 'placeOfBirth', label: 'Place of Birth', type: ServiceFieldType.text),
              ServiceFormField(
                key: 'educationalAttainmentBeforeTraining',
                label: 'Educational Attainment Before Training',
                type: ServiceFieldType.select,
                options: ['Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'parentGuardianName',
                label: "Parent / Guardian's Name",
                type: ServiceFieldType.text,
                required: false,
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Learner Classification',
            fields: [
              ServiceFormField(
                key: 'learnerClassification',
                label: 'Learner Classification',
                type: ServiceFieldType.multiselect,
                options: [
                  '4Ps Beneficiary',
                  'Agrarian Reform Beneficiary',
                  'Balik Probinsya',
                  'Displaced Worker',
                  'Farmer / Fisherman',
                  'Indigenous People / Cultural Community',
                  'Industry Worker',
                  'OFW / OFW Dependent',
                  'Out-of-School Youth',
                  'Rebel Returnee',
                  'Repatriated OFW',
                  'Student',
                  'TESDA Alumni',
                  'Uniformed Personnel',
                  'Victim of Natural Disaster',
                  'Other',
                ],
              ),
            ],
          ),
          ServiceFormStep(
            label: 'Training Preference',
            fields: [
              ServiceFormField(
                key: 'courseOrQualification',
                label: 'Course / Qualification',
                type: ServiceFieldType.text,
              ),
              ServiceFormField(
                key: 'scholarshipPackage',
                label: 'Scholarship Package',
                type: ServiceFieldType.select,
                options: ['TWSP', 'PESFA', 'STEP', 'Other / None'],
              ),
            ],
          ),
        ],
      ),
    ),
    CatalogItem(
      key: 'tulong_erpat_registration',
      name: "ERPAT Program Registration (Fathers' Empowerment)",
      office: 'MSWD',
      fee: 'Free',
      days: '3-5 working days',
      requirements: ['Valid government-issued ID', 'Barangay Certification'],
      process: ['Submit Registration', 'MSWD Review', 'Enrollment', 'Program Orientation'],
      icon: 'users',
      // Sourced: MSWD - ERPAT FORMS.docx — Registration Form portion only
      // (official); the file's meeting-minutes portions are internal
      // staff records and excluded, see audit doc.
      formSpec: ServiceFormSpec(
        steps: [
          ServiceFormStep(
            label: 'Personal Information',
            fields: [
              ServiceFormField(key: 'dateOfBirth', label: 'Date of Birth', type: ServiceFieldType.date),
              ServiceFormField(
                key: 'age',
                label: 'Age',
                type: ServiceFieldType.derivedAge,
                required: false,
                derivedFromKey: 'dateOfBirth',
              ),
              ServiceFormField(key: 'sex', label: 'Sex', type: ServiceFieldType.select, options: ['Male', 'Female']),
              ServiceFormField(
                key: 'civilStatus',
                label: 'Civil Status',
                type: ServiceFieldType.select,
                options: ['Single', 'Married', 'Widowed', 'Separated'],
              ),
              ServiceFormField(key: 'occupation', label: 'Occupation', type: ServiceFieldType.text, required: false),
              ServiceFormField(key: 'religion', label: 'Religion', type: ServiceFieldType.text, required: false),
            ],
          ),
          ServiceFormStep(
            label: 'Family & Background',
            fields: [
              ServiceFormField(
                key: 'familyComposition',
                label: 'Household Members (name, age, relationship)',
                type: ServiceFieldType.textarea,
              ),
              ServiceFormField(
                key: 'educationalAttainment',
                label: 'Educational Attainment',
                type: ServiceFieldType.select,
                options: ['None', 'Elementary', 'High School', 'Vocational', 'College', 'Post Graduate'],
              ),
              ServiceFormField(
                key: 'specialSkillsHobbies',
                label: 'Special Abilities / Skills / Hobbies',
                type: ServiceFieldType.textarea,
                required: false,
              ),
              ServiceFormField(
                key: 'communityInvolvement',
                label: 'Community Involvement',
                type: ServiceFieldType.textarea,
                required: false,
              ),
            ],
          ),
        ],
      ),
    ),
  ];

  /// Incident types a citizen can report — mirrors the Web Admin's Sakuna >
  /// Incidents module intent (config/esperanza_rbac.php's 'sakuna_incidents'
  /// submodule), scaled down to what a citizen-facing report form needs.
  static const incidentTypes = <CatalogItem>[
    CatalogItem(
      key: 'incident_flood',
      name: 'Flooding',
      office: 'MDRRMO',
      fee: 'Free',
      days: 'Immediate — 24 hrs',
      requirements: ['Location / landmark', 'Photo of the affected area if safe to take'],
      process: ['Submit Report', 'MDRRMO Validation', 'Dispatch / Response', 'Close'],
      icon: 'waves',
    ),
    CatalogItem(
      key: 'incident_fire',
      name: 'Fire',
      office: 'BFP / MDRRMO',
      fee: 'Free',
      days: 'Immediate',
      requirements: ['Location / landmark', 'Photo if safe to take'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'flame',
    ),
    CatalogItem(
      key: 'incident_landslide',
      name: 'Landslide',
      office: 'MDRRMO',
      fee: 'Free',
      days: 'Immediate — 24 hrs',
      requirements: ['Location / landmark', 'Photo of the affected area if safe to take'],
      process: ['Submit Report', 'MDRRMO Validation', 'Dispatch / Response', 'Close'],
      icon: 'mountain',
    ),
    CatalogItem(
      key: 'incident_medical',
      name: 'Medical Emergency',
      office: 'Municipal Health Office / MDRRMO',
      fee: 'Free',
      days: 'Immediate',
      requirements: ['Location / landmark', 'Nature of emergency'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'siren',
    ),
    CatalogItem(
      key: 'incident_road',
      name: 'Road Accident',
      office: 'MDRRMO / PNP',
      fee: 'Free',
      days: 'Immediate',
      requirements: ['Location / landmark', 'Photo if safe to take'],
      process: ['Submit Report', 'Dispatch', 'Response', 'Close'],
      icon: 'car-crash',
    ),
    CatalogItem(
      key: 'incident_other',
      name: 'Other Concern',
      office: 'MDRRMO',
      fee: 'Free',
      days: '1-2 working days',
      requirements: ['Description of the concern', 'Location / landmark'],
      process: ['Submit Report', 'Validation', 'Response', 'Close'],
      icon: 'flag',
    ),
  ];

  /// `distanceKm` is a simulated value standing in for real device
  /// geolocation (this app has no `geolocator`/location-permission
  /// integration wired up — see EvacuationCenterDetailScreen's doc
  /// comment for why, and what a real integration would need to
  /// replace). `currentOccupancy` is deliberately left unset everywhere:
  /// there is no live capacity feed, and the emergency spec explicitly
  /// forbids inventing one — the detail screen shows "Capacity
  /// information unavailable" instead.
  static const evacuationCenters = <EvacuationCenter>[
    EvacuationCenter(
      name: 'Poblacion Covered Court',
      barangay: 'Poblacion',
      totalCapacity: 300,
      distanceKm: 0.8,
      services: ['Emergency Shelter', 'Medical Aid Station', 'Relief Goods Distribution'],
      amenities: ['Restrooms', 'Drinking Water', 'Electricity', 'Covered Sleeping Area'],
      contactNumber: '(056) 333-1090',
    ),
    EvacuationCenter(
      name: 'Santiago Elementary School',
      barangay: 'Santiago',
      totalCapacity: 180,
      distanceKm: 2.4,
      services: ['Emergency Shelter', 'Feeding Program'],
      amenities: ['Restrooms', 'Drinking Water', 'Classrooms for Families'],
      contactNumber: '(056) 333-1056',
    ),
    EvacuationCenter(
      name: 'Labangtaytay Barangay Hall',
      barangay: 'Labangtaytay',
      totalCapacity: 120,
      distanceKm: 4.1,
      services: ['Emergency Shelter'],
      amenities: ['Restrooms', 'Drinking Water'],
      contactNumber: '(056) 333-1021',
    ),
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

  /// Real Esperanza event posters, each its own independent entry (never
  /// combined into one container, even the three same-tournament
  /// basketball posters — see EventItem's doc comment). Ordered
  /// chronologically by actual event date.
  ///
  /// Note on asset filenames vs. content: the on-disk filenames "Event
  /// 1.png" / "Eventt 1.2.png" / "Event 1.3.png" do not actually match
  /// the "1 / 1.2 / 1.3" numbering implied by their names once opened —
  /// "Event 1.3.png" is the Aug 3 match schedule, "Eventt 1.2.png" is the
  /// Aug 12 quarter-final, and "Event 1.png" is the Aug 13 quarter-final.
  /// The titles/dates/matchups below were set from each poster's actual
  /// visible content, not from its filename.
  static final events = [
    EventItem(
      title: 'Basketball Match Schedule — Baras vs Tunga, Villa vs Poblacion',
      date: 'Aug 3, 2026',
      time: '6:00 PM & 8:00 PM',
      venue: 'Felimon S. Conag Cultural and Sports Center',
      imagePath: 'assets/images/Event 1.3.png',
      category: 'Sports',
    ),
    EventItem(
      title: 'Mega Shoe Caravan',
      date: 'Aug 7–8, 2026',
      time: '7:00 AM – 2:00 PM',
      venue: 'Esperanza Covered Court',
      imagePath: 'assets/images/Event 3.png',
      category: 'Promo',
    ),
    EventItem(
      title: 'Basketball Quarter Final — Sorosimbajan vs Labangtaytay, Potingbato vs Iligan',
      date: 'Aug 12, 2026',
      time: '6:00 PM & 8:00 PM',
      venue: 'Felimon S. Conag Cultural and Sports Center',
      imagePath: 'assets/images/Eventt 1.2.png',
      category: 'Sports',
    ),
    EventItem(
      title: 'Basketball Quarter Final — Tawad vs Santiago, Villa vs Domorog',
      date: 'Aug 13, 2026',
      time: '6:00 PM & 8:00 PM',
      venue: 'Felimon S. Conag Cultural and Sports Center',
      imagePath: 'assets/images/Event 1.png',
      category: 'Sports',
    ),
    EventItem(
      title: 'Pa Jollibee ug Sorbetes ni Mayor JJ!',
      date: 'Aug 21, 2026',
      time: '2:00 PM',
      venue: 'Felimon S. Conag Cultural and Sports Center',
      imagePath: 'assets/images/Event 2.jpg',
      category: 'Community',
    ),
  ];

  static final announcements = [
    // Admin-published recognition photo — visible content only: a DENR
    // Certificate of Recognition naming "Domorog & Sorosimbahan
    // Mangroves" as 2nd Runner-Up (per the certificate's own wording;
    // the accompanying trophy plaque separately reads "2nd Place") in
    // the "4th Gawad Iba Ka Juan: Best Mangrove Award in the Bicol
    // Region," dated July 27, 2026, presented to LGU Esperanza. No
    // claims beyond what's legible on the certificate/trophy.
    Announcement(
      id: 'bal-mangrove-award',
      official: 'Esperanza LGU',
      author: 'Esperanza LGU',
      barangay: null,
      body:
          'Domorog & Sorosimbahan Mangroves Receive Recognition\n\n'
          'LGU Esperanza was recognized as 2nd Runner-Up in the 4th Gawad Iba Ka Juan: Best Mangrove Award in the Bicol Region, '
          'presented in celebration of International Day for the Conservation of the Mangrove Ecosystem, held July 27, 2026 in Legazpi City, Albay. '
          'Maraming salamat sa ating mga taga-Domorog at Sorosimbahan sa pag-aalaga ng ating mangroves! 🌿',
      time: '2 weeks ago',
      media: const PostMedia(path: 'assets/images/News page section.png', type: PostMediaType.image, isAsset: true),
      likes: 89,
      shares: 21,
      comments: const [],
    ),
    Announcement(
      id: 'bal-1',
      official: 'Esperanza LGU',
      author: 'Esperanza LGU',
      barangay: null,
      body:
          'Sumali sa buong-munisipyong pagdiriwang ngayong Agosto! Street dancing, trade fair, at gabi-gabing cultural program sa Municipal Plaza. Maligayang pagdating sa lahat! 🎉',
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
      body:
          'Successful po ang blood donation drive natin ngayong araw dito sa Brgy. Santiago! Umabot ng 40+ na donors. Maraming salamat sa lahat ng dumalo at sa Red Cross Masbate! 🩸🙏',
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
      body:
          'Libreng anti-rabies vaccination para sa mga alagang aso at pusa sa Poblacion Covered Court ngayong Linggo, 8AM-4PM. Dalhin ang inyong alagang hayop!',
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
      body:
          'Paalala: Disaster preparedness orientation sa lahat ng barangay captains bukas, 9AM sa Municipal Hall Conference Room. Mandatory ang attendance bilang parte ng Typhoon Season Readiness Program.',
      time: '4 days ago',
      likes: 58,
      shares: 12,
      comments: [
        PostComment(
          author: 'Marites Ferrer',
          body: 'Noted po, sasabihin ko sa Brgy. Captain namin.',
          time: '3 days ago',
        ),
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
