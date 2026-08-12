<?php

// Static reference data describing the Esperanza LGU role-based access
// control model: modules → submodules → permission types, the 8 default
// system roles, and 11 sample personnel accounts used to demo "log in as
// this role" across the Administrative Portal. Not a model/business logic —
// same category as config/esperanza.php: shared display data consumed by
// Blade views and embedded as JSON for the frontend session simulation.

// ---------------------------------------------------------------
// Module → Submodule structure. Mirrors the real Dokyu / Tulong
// catalogues used elsewhere in the app so the RBAC model reflects
// actual Esperanza LGU workflows rather than generic placeholders.
// ---------------------------------------------------------------
$permissionModules = [
    [
        'key' => 'dokyu', 'name' => 'Dokyu (Document Requests)', 'icon' => 'file-text',
        'submodules' => [
            ['key' => 'dokyu_barangay_clearance', 'name' => 'Barangay Clearance', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'dokyu_cedula', 'name' => 'Cedula (Community Tax Certificate)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'dokyu_residency', 'name' => 'Certificate of Residency', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'dokyu_indigency', 'name' => 'Certificate of Indigency', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'dokyu_business_new', 'name' => 'Business Permit (New Application)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'dokyu_business_renewal', 'name' => 'Business Permit Renewal', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'dokyu_rpt', 'name' => 'Real Property Tax Clearance', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release']],
            ['key' => 'dokyu_senior_id', 'name' => 'Senior Citizen ID', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release']],
            // Additional municipal documents (see config/esperanza_municipal_documents.php).
            // Keys match the citizen-facing document 'key' exactly so both sides stay in sync.
            ['key' => 'mcro_marriage', 'name' => 'Certificate of Marriage (Certified Copy / Registration)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'mcro_live_birth', 'name' => 'Certificate of Live Birth (Certified Copy / Registration)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'mcro_delayed_registration', 'name' => 'Affidavit for Delayed Registration', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'municipal_pet_registration', 'name' => 'Pet Registration', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            // Barangay-issued documents (see config/esperanza_barangay_documents.php).
            // Keys match the citizen-facing document 'key' exactly so both sides stay in sync.
            ['key' => 'brgy_cert_death_registration', 'name' => 'Barangay Certification (Registration of Death)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'brgy_cert_late_registration', 'name' => 'Barangay Certification (Late Registration)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'brgy_business_clearance', 'name' => 'Barangay Business Clearance', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'brgy_residency', 'name' => 'Barangay Residency', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'brgy_first_time_jobseeker', 'name' => 'First Time Jobseeker Certificate (RA 11261)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
            ['key' => 'brgy_indigency', 'name' => 'Barangay Indigency', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive']],
        ],
    ],
    [
        'key' => 'tulong', 'name' => 'Tulong (Citizen Assistance)', 'icon' => 'hand-heart',
        'submodules' => [
            ['key' => 'tulong_medical', 'name' => 'Medical Assistance (AICS)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'tulong_burial', 'name' => 'Burial Assistance (AICS)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'tulong_educational', 'name' => 'Educational Assistance', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'tulong_financial', 'name' => 'Financial Assistance (AICS)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'reject', 'release', 'archive']],
            ['key' => 'tulong_food', 'name' => 'Food / Relief Assistance', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release']],
            ['key' => 'tulong_pension', 'name' => 'Social Pension (Indigent Senior Citizen)', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release']],
            ['key' => 'tulong_solo_parent', 'name' => 'Solo Parent Cash Assistance', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'release']],
        ],
    ],
    [
        'key' => 'constituents', 'name' => 'Constituent Management', 'icon' => 'users',
        'submodules' => [
            ['key' => 'const_resident', 'name' => 'Resident Profiles', 'perms' => ['view', 'create', 'edit', 'delete', 'export']],
            ['key' => 'const_household', 'name' => 'Household Profiles', 'perms' => ['view', 'create', 'edit', 'delete', 'export']],
            ['key' => 'const_family', 'name' => 'Family Profiles', 'perms' => ['view', 'create', 'edit', 'delete']],
            ['key' => 'const_barangay', 'name' => 'Barangay Profiles', 'perms' => ['view', 'edit', 'export']],
            ['key' => 'const_data_quality', 'name' => 'Data Quality Management', 'perms' => ['view', 'verify', 'assign', 'merge', 'resolve', 'view_sensitive', 'export']],
        ],
    ],
    [
        'key' => 'payments', 'name' => 'Payments', 'icon' => 'receipt',
        'submodules' => [
            ['key' => 'pay_dokyu', 'name' => 'Dokyu Invoices & Receipts', 'perms' => ['view', 'review', 'approve', 'reject', 'export', 'print']],
            ['key' => 'pay_tulong', 'name' => 'Tulong Invoices & Receipts', 'perms' => ['view', 'review', 'approve', 'reject', 'export', 'print']],
        ],
    ],
    [
        'key' => 'communications', 'name' => 'Announcements & Directory', 'icon' => 'megaphone',
        'submodules' => [
            ['key' => 'comm_news', 'name' => 'News & Announcements', 'perms' => ['view', 'create', 'edit', 'delete', 'review', 'approve', 'archive']],
            ['key' => 'comm_community', 'name' => 'Community Posts (Moderation)', 'perms' => ['view', 'review', 'approve', 'reject', 'archive']],
            ['key' => 'comm_events', 'name' => 'Events', 'perms' => ['view', 'create', 'edit', 'delete', 'archive']],
            ['key' => 'comm_directory', 'name' => 'Government Directory', 'perms' => ['view', 'create', 'edit', 'delete']],
            ['key' => 'comm_barangay_directory', 'name' => 'Barangay Directory', 'perms' => ['view', 'edit']],
        ],
    ],
    [
        'key' => 'reports', 'name' => 'Reports & Analytics', 'icon' => 'chart-column',
        'submodules' => [
            ['key' => 'rep_population', 'name' => 'Population Reports', 'perms' => ['view', 'export', 'print']],
            ['key' => 'rep_assistance', 'name' => 'Assistance Reports', 'perms' => ['view', 'export', 'print']],
            ['key' => 'rep_document', 'name' => 'Document Reports', 'perms' => ['view', 'export', 'print']],
            ['key' => 'rep_financial', 'name' => 'Financial / Payment Reports', 'perms' => ['view', 'export', 'print']],
        ],
    ],
    [
        'key' => 'user_management', 'name' => 'User Management', 'icon' => 'user-cog',
        'submodules' => [
            ['key' => 'um_personnel', 'name' => 'Personnel Accounts', 'perms' => ['view', 'create', 'edit', 'delete']],
            ['key' => 'um_roles', 'name' => 'Roles & Permissions', 'perms' => ['view', 'create', 'edit', 'delete']],
            ['key' => 'um_audit', 'name' => 'Audit Logs', 'perms' => ['view', 'export']],
        ],
    ],
    [
        'key' => 'settings', 'name' => 'System Settings', 'icon' => 'settings',
        'submodules' => [
            ['key' => 'set_general', 'name' => 'General Settings', 'perms' => ['view', 'edit']],
            ['key' => 'set_branding', 'name' => 'Municipality Branding', 'perms' => ['view', 'edit']],
        ],
    ],
    [
        'key' => 'sakuna', 'name' => 'Sakuna (Disaster Risk & Emergency Ops)', 'icon' => 'shield-alert',
        'submodules' => [
            ['key' => 'sakuna_command', 'name' => 'Command Center', 'perms' => ['view', 'create', 'edit', 'dispatch', 'escalate', 'close', 'export']],
            ['key' => 'sakuna_vulnerability', 'name' => 'Vulnerability Assessment', 'perms' => ['view', 'create', 'edit', 'approve', 'export']],
            ['key' => 'sakuna_incidents', 'name' => 'Incidents', 'perms' => ['view', 'create', 'edit', 'validate', 'assign', 'dispatch', 'escalate', 'resolve', 'close', 'export']],
            ['key' => 'sakuna_centers', 'name' => 'Evacuation Centers', 'perms' => ['view', 'create', 'edit', 'open', 'close', 'assign', 'export']],
            ['key' => 'sakuna_evacuees', 'name' => 'Evacuees', 'perms' => ['view', 'create', 'edit', 'check_in', 'transfer', 'check_out', 'export']],
            ['key' => 'sakuna_resources', 'name' => 'Resources', 'perms' => ['view', 'create', 'edit', 'assign', 'deploy', 'return', 'export']],
            ['key' => 'sakuna_relief', 'name' => 'Relief Operations', 'perms' => ['view', 'create', 'edit', 'approve', 'release', 'export']],
            ['key' => 'sakuna_damage', 'name' => 'Damage Assessment', 'perms' => ['view', 'create', 'edit', 'validate', 'approve', 'export']],
            ['key' => 'sakuna_alerts', 'name' => 'Public Alerts', 'perms' => ['view', 'create', 'edit', 'review', 'approve', 'publish', 'cancel', 'archive', 'export']],
            ['key' => 'sakuna_reports', 'name' => 'Reports', 'perms' => ['view', 'export', 'print']],
        ],
    ],
];

// ---------------------------------------------------------------
// Preset levels used to derive each default role's starting grant
// per module, so the 8 system roles stay realistic without having
// to hand-type every submodule/permission combination.
// ---------------------------------------------------------------
$presetLevels = [
    'full' => fn ($perms) => $perms,
    'process' => fn ($perms) => array_values(array_intersect($perms, ['view', 'create', 'edit'])),
    'approve' => fn ($perms) => array_values(array_intersect($perms, ['view', 'review', 'approve', 'reject', 'release'])),
    'view_export' => fn ($perms) => array_values(array_intersect($perms, ['view', 'export', 'print'])),
    'view' => fn ($perms) => array_values(array_intersect($perms, ['view'])),
];

$buildPermissions = function (array $moduleLevels) use ($permissionModules, $presetLevels) {
    $grants = [];
    foreach ($permissionModules as $mod) {
        if (!isset($moduleLevels[$mod['key']])) {
            continue;
        }
        $apply = $presetLevels[$moduleLevels[$mod['key']]];
        foreach ($mod['submodules'] as $sub) {
            $grants[$sub['key']] = $apply($sub['perms']);
        }
    }
    return $grants;
};

$superAdminPermissions = [];
foreach ($permissionModules as $mod) {
    foreach ($mod['submodules'] as $sub) {
        $superAdminPermissions[$sub['key']] = $sub['perms'];
    }
}

// ---------------------------------------------------------------
// Default system roles. Super Administrator is the only one that
// is not editable, per the LGU governance model.
// ---------------------------------------------------------------
$roles = [
    [
        'key' => 'super_admin', 'name' => 'Super Administrator', 'icon' => 'crown',
        'color' => 'text-navy-700 bg-navy-50', 'users' => 1, 'editable' => false,
        'desc' => 'Unrestricted access to every module, including personnel, roles, and system configuration. This role cannot be edited, renamed, or deleted.',
        'permissions' => $superAdminPermissions,
    ],
    [
        'key' => 'municipal_admin', 'name' => 'Municipal Administrator', 'icon' => 'shield-check',
        'color' => 'text-brand-700 bg-brand-50', 'users' => 2, 'editable' => true,
        'desc' => 'Full operational control across Dokyu, Tulong, Constituents, Payments, and Communications, plus personnel and role management for the municipality.',
        'permissions' => $buildPermissions([
            'dokyu' => 'full', 'tulong' => 'full', 'constituents' => 'full', 'payments' => 'full',
            'communications' => 'full', 'reports' => 'view_export', 'user_management' => 'full', 'settings' => 'full',
            'sakuna' => 'full',
        ]),
    ],
    [
        'key' => 'department_head', 'name' => 'Department Head', 'icon' => 'briefcase',
        'color' => 'text-purple-700 bg-purple-50', 'users' => 6, 'editable' => true,
        'desc' => 'Reviews, approves, and releases requests handled by their assigned department (e.g. MSWDO, Treasurer\'s Office, Civil Registrar).',
        'permissions' => $buildPermissions([
            'dokyu' => 'approve', 'tulong' => 'approve', 'constituents' => 'view', 'payments' => 'approve', 'reports' => 'view_export',
        ]),
    ],
    [
        'key' => 'department_staff', 'name' => 'Department Staff', 'icon' => 'keyboard',
        'color' => 'text-emerald-700 bg-emerald-50', 'users' => 24, 'editable' => true,
        'desc' => 'Handles day-to-day encoding and processing of document and assistance requests within their department.',
        'permissions' => $buildPermissions([
            'dokyu' => 'process', 'tulong' => 'process', 'constituents' => 'view', 'payments' => 'view',
        ]),
    ],
    [
        'key' => 'front_desk', 'name' => 'Front Desk Officer', 'icon' => 'concierge-bell',
        'color' => 'text-orange-700 bg-orange-50', 'users' => 8, 'editable' => true,
        'desc' => 'First point of contact at the municipal hall — intakes new document and assistance requests and assists walk-in constituents.',
        'permissions' => $buildPermissions([
            'dokyu' => 'process', 'tulong' => 'process', 'constituents' => 'process', 'payments' => 'view',
        ]),
    ],
    [
        'key' => 'records_officer', 'name' => 'Records Officer', 'icon' => 'archive',
        'color' => 'text-cyan-700 bg-cyan-50', 'users' => 3, 'editable' => true,
        'desc' => 'Maintains resident, household, and barangay records, and prepares official copies of civil registry documents.',
        'permissions' => $buildPermissions([
            'constituents' => 'full', 'dokyu' => 'process', 'reports' => 'view_export',
        ]),
    ],
    [
        'key' => 'info_officer', 'name' => 'Information Officer', 'icon' => 'megaphone',
        'color' => 'text-rose-700 bg-rose-50', 'users' => 2, 'editable' => true,
        'desc' => 'Owns public-facing communications — drafts, reviews, and publishes announcements, events, and moderates community posts.',
        'permissions' => $buildPermissions([
            'communications' => 'full', 'reports' => 'view',
        ]),
    ],
    [
        'key' => 'barangay_secretary', 'name' => 'Barangay Secretary', 'icon' => 'map-pinned',
        'color' => 'text-teal-700 bg-teal-50', 'users' => 20, 'editable' => true,
        'desc' => 'Processes and releases their barangay\'s own certifications and clearances (residency, indigency, business clearance, etc.), manages their barangay\'s directory profile, and views resident records for their barangay. Always Barangay-scoped, never Municipal-wide.',
        'permissions' => array_merge(
            $buildPermissions(['constituents' => 'view']),
            [
                'comm_barangay_directory' => ['view', 'edit'],
                'brgy_cert_death_registration' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive'],
                'brgy_cert_late_registration' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive'],
                'brgy_business_clearance' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive'],
                'brgy_residency' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive'],
                'brgy_first_time_jobseeker' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive'],
                'brgy_indigency' => ['view', 'create', 'edit', 'review', 'approve', 'release', 'archive'],
            ]
        ),
    ],
    [
        'key' => 'citizen', 'name' => 'Citizen', 'icon' => 'user-round',
        'color' => 'text-slate-600 bg-slate-100', 'users' => 8420, 'editable' => true,
        'desc' => 'Default role for residents registered on the Citizen Portal. Citizens manage only their own requests and profile — they have no access to Administrative Portal modules.',
        'permissions' => [],
    ],
];

// ---------------------------------------------------------------
// Sakuna (Disaster Risk Reduction & Emergency Operations) grants —
// hand-authored per submodule rather than the generic preset levels above,
// since Sakuna's action vocabulary (dispatch, validate, check_in, deploy...)
// doesn't map onto the view/create/edit/approve preset shape. Merged into
// each role's 'permissions' by role name below. Super Administrator gets
// full access automatically (its permissions cover every submodule of
// every module in $permissionModules); Municipal Administrator gets full
// access via the 'sakuna' => 'full' preset above.
// ---------------------------------------------------------------
$sakunaGrantsByRoleName = [
    'Department Head' => [
        'sakuna_command' => ['view', 'dispatch', 'escalate', 'close', 'export'],
        'sakuna_vulnerability' => ['view', 'approve', 'export'],
        'sakuna_incidents' => ['view', 'validate', 'assign', 'dispatch', 'escalate', 'resolve', 'close', 'export'],
        'sakuna_centers' => ['view', 'open', 'close', 'assign', 'export'],
        'sakuna_evacuees' => ['view', 'check_in', 'transfer', 'check_out', 'export'],
        'sakuna_resources' => ['view', 'assign', 'deploy', 'return', 'export'],
        'sakuna_relief' => ['view', 'approve', 'release', 'export'],
        'sakuna_damage' => ['view', 'validate', 'approve', 'export'],
        'sakuna_alerts' => ['view', 'approve', 'export'],
        'sakuna_reports' => ['view', 'export'],
    ],
    'Department Staff' => [
        'sakuna_command' => ['view', 'create', 'edit'],
        'sakuna_vulnerability' => ['view', 'create', 'edit'],
        'sakuna_incidents' => ['view', 'create', 'edit', 'validate', 'assign'],
        'sakuna_centers' => ['view', 'create', 'edit'],
        'sakuna_evacuees' => ['view', 'create', 'edit', 'check_in'],
        'sakuna_resources' => ['view', 'create', 'edit', 'assign'],
        'sakuna_relief' => ['view', 'create', 'edit'],
        'sakuna_damage' => ['view', 'create', 'edit', 'validate'],
        'sakuna_alerts' => ['view', 'create', 'edit'],
        'sakuna_reports' => ['view'],
    ],
    'Front Desk Officer' => [
        'sakuna_incidents' => ['view', 'create'],
        'sakuna_evacuees' => ['view', 'create', 'check_in'],
    ],
    'Records Officer' => [
        'sakuna_vulnerability' => ['view', 'export'],
        'sakuna_evacuees' => ['view', 'export'],
        'sakuna_damage' => ['view', 'export'],
        'sakuna_reports' => ['view', 'export', 'print'],
    ],
    'Information Officer' => [
        'sakuna_command' => ['view'],
        'sakuna_incidents' => ['view'],
        'sakuna_centers' => ['view'],
        'sakuna_evacuees' => ['view'],
        'sakuna_alerts' => ['view', 'create', 'edit', 'review', 'approve', 'publish', 'cancel', 'archive'],
        'sakuna_reports' => ['view', 'export', 'print'],
    ],
];

foreach ($roles as &$role) {
    if (isset($sakunaGrantsByRoleName[$role['name']])) {
        $role['permissions'] = array_merge($role['permissions'], $sakunaGrantsByRoleName[$role['name']]);
    }
}
unset($role);

// ---------------------------------------------------------------
// Sample personnel accounts — one (or more, to contrast Municipal vs.
// Barangay scope) per role, used to demo "log in as this role" on the
// LGU Personnel Login screen. Employee IDs are prefixed per role
// (SA/MA/DH/DS/FD/RO/IO) so the role is recognizable from the ID alone.
// ---------------------------------------------------------------
$accounts = [
    ['id' => 'SA-001', 'name' => 'Ricardo Villanueva', 'roleKey' => 'super_admin', 'dept' => 'Office of the Mayor', 'scope' => 'Municipal', 'status' => 'Approved'],
    ['id' => 'MA-001', 'name' => 'Juan Dela Cruz', 'roleKey' => 'municipal_admin', 'dept' => 'Office of the Mayor', 'scope' => 'Municipal', 'status' => 'Approved'],
    ['id' => 'DH-001', 'name' => 'Corazon Villareal', 'roleKey' => 'department_head', 'dept' => 'MSWDO', 'scope' => 'Municipal', 'status' => 'Approved'],
    ['id' => 'DH-002', 'name' => 'Marivic Ong', 'roleKey' => 'department_head', 'dept' => 'Civil Registrar', 'scope' => 'Municipal', 'status' => 'Approved'],
    ['id' => 'DH-003', 'name' => 'Leilani Domingo', 'roleKey' => 'department_head', 'dept' => 'Municipal Health Office', 'scope' => 'Municipal', 'status' => 'Approved'],
    ['id' => 'DS-001', 'name' => 'Ferdinand Cortez', 'roleKey' => 'department_staff', 'dept' => "Treasurer's Office", 'scope' => 'Municipal', 'status' => 'Archived'],
    ['id' => 'FD-001', 'name' => 'Angeline Mercado', 'roleKey' => 'front_desk', 'dept' => 'Office of the Mayor', 'scope' => 'Municipal', 'status' => 'Pending Review'],
    ['id' => 'FD-002', 'name' => 'Rowena Aguilar', 'roleKey' => 'front_desk', 'dept' => 'Barangay Poblacion', 'scope' => 'Poblacion', 'status' => 'Approved'],
    ['id' => 'RO-001', 'name' => 'Bienvenido Salazar', 'roleKey' => 'records_officer', 'dept' => "Treasurer's Office", 'scope' => 'Municipal', 'status' => 'Approved'],
    ['id' => 'RO-002', 'name' => 'Dexter Villamor', 'roleKey' => 'records_officer', 'dept' => 'Barangay Santiago', 'scope' => 'Santiago', 'status' => 'Approved'],
    ['id' => 'IO-001', 'name' => 'Paolo Reyes', 'roleKey' => 'info_officer', 'dept' => 'ICT Office', 'scope' => 'Municipal', 'status' => 'Approved'],
    ['id' => 'BS-001', 'name' => 'Leonora Batac', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Poblacion', 'scope' => 'Poblacion', 'status' => 'Approved'],
    ['id' => 'BS-002', 'name' => 'Herminia Cordova', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Santiago', 'scope' => 'Santiago', 'status' => 'Approved'],
    // Labangtaytay is the first barangay fully onboarded (real document templates,
    // officials, and seal). Names below match config/esperanza_barangay_documents.php's
    // 'barangay_secretary' entry per barangay — keep the two in sync.
    ['id' => 'BS-003', 'name' => 'Jenneth A. Cachila', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Labangtaytay', 'scope' => 'Labangtaytay', 'status' => 'Approved'],
    ['id' => 'BS-004', 'name' => 'Rosalinda T. Bagsic', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Agoho', 'scope' => 'Agoho', 'status' => 'Approved'],
    ['id' => 'BS-005', 'name' => 'Milagros D. Fernandez', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Almero', 'scope' => 'Almero', 'status' => 'Approved'],
    ['id' => 'BS-006', 'name' => 'Corazon B. Ilagan', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Baras', 'scope' => 'Baras', 'status' => 'Approved'],
    ['id' => 'BS-007', 'name' => 'Teresita M. Ronquillo', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Domorog', 'scope' => 'Domorog', 'status' => 'Approved'],
    ['id' => 'BS-008', 'name' => 'Susana R. Palma', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Guadalupe', 'scope' => 'Guadalupe', 'status' => 'Approved'],
    ['id' => 'BS-009', 'name' => 'Anabelle F. Torion', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Iligan', 'scope' => 'Iligan', 'status' => 'Approved'],
    ['id' => 'BS-010', 'name' => 'Marilou G. Sarona', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Labrador', 'scope' => 'Labrador', 'status' => 'Approved'],
    ['id' => 'BS-011', 'name' => 'Josefina L. Roxas', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Libertad', 'scope' => 'Libertad', 'status' => 'Approved'],
    ['id' => 'BS-012', 'name' => 'Erlinda C. Nacario', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Magsaysay', 'scope' => 'Magsaysay', 'status' => 'Approved'],
    ['id' => 'BS-013', 'name' => 'Perla S. Villaruel', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Masbaranon', 'scope' => 'Masbaranon', 'status' => 'Approved'],
    ['id' => 'BS-014', 'name' => 'Gloria T. Manlangit', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Potingbato', 'scope' => 'Potingbato', 'status' => 'Approved'],
    ['id' => 'BS-015', 'name' => 'Lourdes M. Abrenica', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Rizal', 'scope' => 'Rizal', 'status' => 'Approved'],
    ['id' => 'BS-016', 'name' => 'Adelina R. Cortez', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay San Roque', 'scope' => 'San Roque', 'status' => 'Approved'],
    ['id' => 'BS-017', 'name' => 'Remedios A. Pantoja', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Sorosimbajan', 'scope' => 'Sorosimbajan', 'status' => 'Approved'],
    ['id' => 'BS-018', 'name' => 'Victoria C. Salceda', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Tawad', 'scope' => 'Tawad', 'status' => 'Approved'],
    ['id' => 'BS-019', 'name' => 'Felicidad B. Marasigan', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Tunga', 'scope' => 'Tunga', 'status' => 'Approved'],
    ['id' => 'BS-020', 'name' => 'Consolacion S. Empuerto', 'roleKey' => 'barangay_secretary', 'dept' => 'Barangay Villa', 'scope' => 'Villa', 'status' => 'Approved'],
];

$roleByKey = collect($roles)->keyBy('key');

$accounts = array_map(function ($account) use ($roleByKey, $permissionModules) {
    $role = $roleByKey[$account['roleKey']];
    $account['role'] = $role['name'];
    $account['roleIcon'] = $role['icon'];
    $account['roleColor'] = $role['color'];
    $account['permissions'] = $role['permissions'];
    $account['moduleKeys'] = collect($permissionModules)
        ->filter(fn ($mod) => collect($mod['submodules'])->contains(fn ($sub) => !empty($account['permissions'][$sub['key']])))
        ->pluck('key')
        ->values()
        ->all();

    return $account;
}, $accounts);

return [
    'permission_types' => [
        'view' => 'View', 'create' => 'Create', 'edit' => 'Edit', 'delete' => 'Delete',
        'review' => 'Review', 'approve' => 'Approve', 'reject' => 'Reject', 'release' => 'Release',
        'export' => 'Export', 'print' => 'Print', 'archive' => 'Archive',
        'verify' => 'Verify', 'assign' => 'Assign', 'merge' => 'Merge', 'resolve' => 'Resolve', 'view_sensitive' => 'View Sensitive',
        'dispatch' => 'Dispatch', 'escalate' => 'Escalate', 'validate' => 'Validate', 'open' => 'Open',
        'check_in' => 'Check In', 'transfer' => 'Transfer', 'check_out' => 'Check Out', 'deploy' => 'Deploy',
        'return' => 'Return', 'publish' => 'Publish', 'cancel' => 'Cancel',
    ],
    'permission_modules' => $permissionModules,
    'roles' => $roles,
    'accounts' => $accounts,
];
