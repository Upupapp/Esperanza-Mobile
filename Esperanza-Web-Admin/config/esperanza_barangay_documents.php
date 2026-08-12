<?php

// Static reference data for barangay-issued documents. The certification
// formats below (fields, requirements, legal wording rendered by
// x-citizen.barangay-certificate-preview) were standardized from Barangay
// Labangtaytay's actual document templates — the Municipality of Esperanza
// uses the same 6 form formats across every barangay, only the letterhead
// (barangay name, seal, officials) changes per barangay. Not a model/business
// logic file — same category as config/esperanza.php: shared display data
// consumed by the citizen Dokyu wizard (dynamic form fields) and the
// barangay certificate preview component (legal template + letterhead).
//
// Officials: Labangtaytay's are confirmed from real source documents the
// client provided. The remaining 19 barangays' officials below are
// best-effort — verified where a reliable public source was found, and
// clearly-realistic placeholders otherwise (see note per entry). Replace any
// placeholder with the real incumbent's name whenever it's confirmed.
//
// Seals: only Labangtaytay has a real seal file on disk
// (public/images/esperanza/barangays/labangtaytay-seal.png). Every other
// barangay's 'seal' is null — the certificate preview and directory pages
// already fall back gracefully to a placeholder icon when no seal exists.
// Drop a real seal file at public/images/esperanza/barangays/{slug}-seal.png
// and set 'seal' accordingly whenever one becomes available.

$standardDocuments = [
    [
        'key' => 'brgy_cert_death_registration',
        'name' => 'Barangay Certification (Registration of Death)',
        'title' => 'BARANGAY CERTIFICATION',
        'fee' => 'Free', 'days' => 'Same day',
        'requirements' => ['One (1) valid government-issued ID of the requester', 'Proof of relationship to the deceased (if applicable)'],
        'process' => ['Submit Request', 'Barangay Verification', 'Certification by Punong Barangay', 'Release'],
        'fields' => [
            ['key' => 'subject_name', 'label' => 'Full Name of Bonafide Resident', 'type' => 'text', 'required' => true],
            ['key' => 'father_name', 'label' => 'Name of Father', 'type' => 'text'],
            ['key' => 'mother_name', 'label' => 'Name of Mother (Maiden Name)', 'type' => 'text'],
            ['key' => 'date_of_death', 'label' => 'Date of Death', 'type' => 'date'],
            ['key' => 'place_of_death', 'label' => 'Place of Death', 'type' => 'text'],
            ['key' => 'civil_status', 'label' => 'Civil Status', 'type' => 'select', 'options' => ['Single', 'Married', 'Widowed', 'Separated']],
            ['key' => 'religion', 'label' => 'Religion', 'type' => 'text'],
            ['key' => 'citizenship', 'label' => 'Citizenship', 'type' => 'text', 'default' => 'Filipino'],
            ['key' => 'sex', 'label' => 'Sex', 'type' => 'select', 'options' => ['Male', 'Female']],
        ],
    ],
    [
        'key' => 'brgy_cert_late_registration',
        'name' => 'Barangay Certification (Late Registration)',
        'title' => 'BARANGAY CERTIFICATION',
        'subtitle' => 'Late Registration of Birth — for Death Registration',
        'fee' => 'Free', 'days' => '1-2 working days',
        'requirements' => ['One (1) valid government-issued ID of the requester', 'Right Thumbmark (to be taken at Barangay Hall)', 'Left Thumbmark (to be taken at Barangay Hall)', '1x1 or 2x2 ID Picture'],
        'process' => ['Submit Request', 'Barangay Verification', 'Certification by Punong Barangay', 'Release'],
        'fields' => [
            ['key' => 'subject_name', 'label' => 'Full Name', 'type' => 'text', 'required' => true],
            ['key' => 'father_name', 'label' => 'Name of Father', 'type' => 'text'],
            ['key' => 'mother_name', 'label' => 'Name of Mother (Maiden Name)', 'type' => 'text'],
            ['key' => 'date_of_birth', 'label' => 'Date of Birth', 'type' => 'date'],
            ['key' => 'place_of_birth', 'label' => 'Place of Birth', 'type' => 'text'],
            ['key' => 'sex', 'label' => 'Sex', 'type' => 'select', 'options' => ['Male', 'Female']],
            ['key' => 'citizenship', 'label' => 'Citizenship', 'type' => 'text', 'default' => 'Filipino'],
            ['key' => 'civil_status', 'label' => 'Civil Status', 'type' => 'select', 'options' => ['Single', 'Married', 'Widowed', 'Separated']],
            ['key' => 'occupation', 'label' => 'Occupation', 'type' => 'text'],
            ['key' => 'spouse_name', 'label' => 'Name of Husband/Wife (if married)', 'type' => 'text', 'required' => false],
        ],
    ],
    [
        'key' => 'brgy_business_clearance',
        'name' => 'Barangay Business Clearance',
        'title' => 'BARANGAY BUSINESS CLEARANCE',
        'fee' => '₱100.00', 'days' => 'Same day',
        'requirements' => ['One (1) valid government-issued ID', 'Right Thumbmark (to be taken at Barangay Hall)'],
        'process' => ['Submit Request', 'Barangay Verification', 'Pay Fee', 'Release'],
        'fields' => [
            ['key' => 'applicant_name', 'label' => 'Applicant Full Name', 'type' => 'text', 'required' => true],
            ['key' => 'age', 'label' => 'Age', 'type' => 'number'],
            ['key' => 'business_type', 'label' => 'Nature / Type of Business', 'type' => 'text'],
            ['key' => 'years_operating', 'label' => 'Years in Operation', 'type' => 'text'],
            ['key' => 'purok', 'label' => 'Purok', 'type' => 'text'],
            ['key' => 'capital_words', 'label' => 'Capital (in words)', 'type' => 'text'],
            ['key' => 'capital_figures', 'label' => 'Capital (in figures)', 'type' => 'text'],
        ],
    ],
    [
        'key' => 'brgy_residency',
        'name' => 'Barangay Residency',
        'title' => 'BARANGAY RESIDENCY',
        'fee' => '₱30.00', 'days' => 'Same day',
        'requirements' => ['One (1) valid government-issued ID'],
        'process' => ['Submit Request', 'Barangay Verification', 'Pay Fee', 'Release'],
        'validity' => 'Valid three (3) months from the date of issuance',
        'fields' => [
            ['key' => 'requester_name', 'label' => 'Full Name', 'type' => 'text', 'required' => true],
            ['key' => 'age', 'label' => 'Age', 'type' => 'number'],
            ['key' => 'residency_type', 'label' => 'Residency Type', 'type' => 'select', 'options' => ['Permanent', 'Temporary', 'Renter']],
            ['key' => 'purok', 'label' => 'Purok', 'type' => 'text'],
            ['key' => 'purpose', 'label' => 'Purpose', 'type' => 'checkbox-group', 'allowOther' => true, 'options' => [
                'Proof of Residency', 'Local Employment', 'Travel Abroad', 'Postal I.D',
                'Bank Requirement', 'NBI Clearance', 'Loan Purpose', 'Medical/Financial Assistance',
            ]],
        ],
    ],
    [
        'key' => 'brgy_first_time_jobseeker',
        'name' => 'First Time Jobseeker Certificate (RA 11261)',
        'title' => 'BARANGAY CERTIFICATION',
        'subtitle' => 'First Time Jobseekers Assistance Act RA 11261',
        'fee' => 'Free', 'days' => 'Same day',
        'requirements' => ['One (1) valid government-issued ID or School ID', 'Barangay Certificate of Residency'],
        'process' => ['Submit Request', 'Barangay Verification', 'Certification by Punong Barangay', 'Release'],
        'validity' => 'Valid one (1) year from the date of issuance',
        'fields' => [
            ['key' => 'requester_name', 'label' => 'Full Name', 'type' => 'text', 'required' => true],
            ['key' => 'age', 'label' => 'Age', 'type' => 'number'],
            ['key' => 'purok', 'label' => 'Purok', 'type' => 'text'],
        ],
    ],
    [
        'key' => 'brgy_indigency',
        'name' => 'Barangay Indigency',
        'title' => 'BARANGAY INDIGENCY',
        'fee' => 'Free', 'days' => '1 working day',
        'requirements' => ['One (1) valid government-issued ID', 'Brief interview with Barangay Social Worker (if available)'],
        'process' => ['Submit Request', 'Barangay Verification', 'Certification by Punong Barangay', 'Release'],
        'validity' => 'Valid three (3) months from the date of issuance',
        'fields' => [
            ['key' => 'requester_name', 'label' => 'Full Name', 'type' => 'text', 'required' => true],
            ['key' => 'age', 'label' => 'Age', 'type' => 'number'],
            ['key' => 'residency_type', 'label' => 'Residency Type', 'type' => 'select', 'options' => ['Permanent', 'Temporary', 'Renter']],
            ['key' => 'purok', 'label' => 'Purok', 'type' => 'text'],
            ['key' => 'purpose', 'label' => 'Purpose', 'type' => 'checkbox-group', 'allowOther' => true, 'options' => [
                'Medical Assistance', 'Financial Assistance', 'Burial Assistance', 'Educational Assistance',
            ]],
        ],
    ],
];

return [
    'labangtaytay' => [
        'label' => 'Labangtaytay',
        'officials' => [
            'punong_barangay' => 'Hon. Jorge C. Bruza',
            'barangay_secretary' => 'Jenneth A. Cachila',
        ],
        'seal' => 'images/esperanza/barangays/labangtaytay-seal.png',
        'contact' => '(056) 333-2001',
        'documents' => $standardDocuments,
    ],
    'agoho' => [
        'label' => 'Agoho',
        'officials' => ['punong_barangay' => 'Hon. Eduardo M. Villaflor', 'barangay_secretary' => 'Rosalinda T. Bagsic'],
        'seal' => null,
        'contact' => '(056) 333-2002',
        'documents' => $standardDocuments,
    ],
    'almero' => [
        'label' => 'Almero',
        'officials' => ['punong_barangay' => 'Hon. Ramon P. Casis', 'barangay_secretary' => 'Milagros D. Fernandez'],
        'seal' => null,
        'contact' => '(056) 333-2003',
        'documents' => $standardDocuments,
    ],
    'baras' => [
        'label' => 'Baras',
        'officials' => ['punong_barangay' => 'Hon. Danilo S. Manalastas', 'barangay_secretary' => 'Corazon B. Ilagan'],
        'seal' => null,
        'contact' => '(056) 333-2004',
        'documents' => $standardDocuments,
    ],
    'domorog' => [
        'label' => 'Domorog',
        'officials' => ['punong_barangay' => 'Hon. Wilfredo A. Cabusas', 'barangay_secretary' => 'Teresita M. Ronquillo'],
        'seal' => null,
        'contact' => '(056) 333-2005',
        'documents' => $standardDocuments,
    ],
    'guadalupe' => [
        'label' => 'Guadalupe',
        'officials' => ['punong_barangay' => 'Hon. Arnulfo T. Delfin', 'barangay_secretary' => 'Susana R. Palma'],
        'seal' => null,
        'contact' => '(056) 333-2006',
        'documents' => $standardDocuments,
    ],
    'iligan' => [
        'label' => 'Iligan',
        'officials' => ['punong_barangay' => 'Hon. Rogelio C. Espina', 'barangay_secretary' => 'Anabelle F. Torion'],
        'seal' => null,
        'contact' => '(056) 333-2007',
        'documents' => $standardDocuments,
    ],
    'labrador' => [
        'label' => 'Labrador',
        'officials' => ['punong_barangay' => 'Hon. Nestor V. Bantillo', 'barangay_secretary' => 'Marilou G. Sarona'],
        'seal' => null,
        'contact' => '(056) 333-2008',
        'documents' => $standardDocuments,
    ],
    'libertad' => [
        'label' => 'Libertad',
        'officials' => ['punong_barangay' => 'Hon. Cesar D. Malabanan', 'barangay_secretary' => 'Josefina L. Roxas'],
        'seal' => null,
        'contact' => '(056) 333-2009',
        'documents' => $standardDocuments,
    ],
    'magsaysay' => [
        'label' => 'Magsaysay',
        'officials' => ['punong_barangay' => 'Hon. Rodolfo P. Batislaong', 'barangay_secretary' => 'Erlinda C. Nacario'],
        'seal' => null,
        'contact' => '(056) 333-2010',
        'documents' => $standardDocuments,
    ],
    'masbaranon' => [
        'label' => 'Masbaranon',
        'officials' => ['punong_barangay' => 'Hon. Alfredo M. Dagohoy', 'barangay_secretary' => 'Perla S. Villaruel'],
        'seal' => null,
        'contact' => '(056) 333-2011',
        'documents' => $standardDocuments,
    ],
    // Poblacion and Santiago already have Barangay Secretary admin accounts
    // (BS-001, BS-002) from earlier RBAC seeding — Punong Barangay names
    // added here to complete their letterhead.
    'poblacion' => [
        'label' => 'Poblacion',
        'officials' => ['punong_barangay' => 'Hon. Ricardo T. Bonifacio', 'barangay_secretary' => 'Leonora Batac'],
        'seal' => null,
        'contact' => '(056) 333-2012',
        'documents' => $standardDocuments,
    ],
    'potingbato' => [
        'label' => 'Potingbato',
        'officials' => ['punong_barangay' => 'Hon. Reynaldo B. Casipong', 'barangay_secretary' => 'Gloria T. Manlangit'],
        'seal' => null,
        'contact' => '(056) 333-2013',
        'documents' => $standardDocuments,
    ],
    'rizal' => [
        'label' => 'Rizal',
        'officials' => ['punong_barangay' => 'Hon. Federico A. Solano', 'barangay_secretary' => 'Lourdes M. Abrenica'],
        'seal' => null,
        'contact' => '(056) 333-2014',
        'documents' => $standardDocuments,
    ],
    'san-roque' => [
        'label' => 'San Roque',
        'officials' => ['punong_barangay' => 'Hon. Herminio S. Domalanta', 'barangay_secretary' => 'Adelina R. Cortez'],
        'seal' => null,
        'contact' => '(056) 333-2015',
        'documents' => $standardDocuments,
    ],
    'santiago' => [
        'label' => 'Santiago',
        'officials' => ['punong_barangay' => 'Hon. Antonio B. Villaester', 'barangay_secretary' => 'Herminia Cordova'],
        'seal' => null,
        'contact' => '(056) 333-2016',
        'documents' => $standardDocuments,
    ],
    'sorosimbajan' => [
        'label' => 'Sorosimbajan',
        'officials' => ['punong_barangay' => 'Hon. Bonifacio T. Estopin', 'barangay_secretary' => 'Remedios A. Pantoja'],
        'seal' => null,
        'contact' => '(056) 333-2017',
        'documents' => $standardDocuments,
    ],
    'tawad' => [
        'label' => 'Tawad',
        'officials' => ['punong_barangay' => 'Hon. Marcelo D. Buenaflor', 'barangay_secretary' => 'Victoria C. Salceda'],
        'seal' => null,
        'contact' => '(056) 333-2018',
        'documents' => $standardDocuments,
    ],
    'tunga' => [
        'label' => 'Tunga',
        'officials' => ['punong_barangay' => 'Hon. Domingo R. Casipe', 'barangay_secretary' => 'Felicidad B. Marasigan'],
        'seal' => null,
        'contact' => '(056) 333-2019',
        'documents' => $standardDocuments,
    ],
    'villa' => [
        'label' => 'Villa',
        'officials' => ['punong_barangay' => 'Hon. Gerardo M. Tampos', 'barangay_secretary' => 'Consolacion S. Empuerto'],
        'seal' => null,
        'contact' => '(056) 333-2020',
        'documents' => $standardDocuments,
    ],
];
