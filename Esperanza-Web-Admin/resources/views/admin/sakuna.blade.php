@php
    use Illuminate\Support\Arr;
    $activeTab = $tab ?? 'command-center';

    // ── Operational Context ─────────────────────────────────────────────────
    $periods = [
        ['id' => 'SWM-2026-07', 'label' => 'Southwest Monsoon & Flooding — July 2026', 'active' => true],
        ['id' => 'TY-2026-05', 'label' => 'Typhoon Amang — May 2026', 'active' => false],
        ['id' => 'DR-2026-02', 'label' => 'Dry Spell — February 2026', 'active' => false],
    ];

    // ── Barangays ────────────────────────────────────────────────────────────
    $barangays = config('esperanza.barangays');

    // ── Vulnerability profiles ────────────────────────────────────────────────
    $vulnerabilityProfiles = [
        ['barangay' => 'Poblacion',     'population' => 4821, 'households' => 1104, 'vulnerable' => 892, 'hazards' => ['Flooding', 'Fire'], 'exposed' => 430, 'evac_cap' => 800, 'readiness_score' => 62, 'risk_level' => 'High',     'readiness_label' => 'Needs Improvement', 'completeness' => 85, 'last_assessed' => 'Jun 14, 2026', 'focal' => 'Nena Bautista'],
        ['barangay' => 'Masbaranon',    'population' => 3210, 'households' => 723, 'vulnerable' => 631, 'hazards' => ['Flooding', 'Landslide'], 'exposed' => 380, 'evac_cap' => 500, 'readiness_score' => 48, 'risk_level' => 'Critical', 'readiness_label' => 'Major Gaps',        'completeness' => 70, 'last_assessed' => 'May 28, 2026', 'focal' => 'Rolando Cruz'],
        ['barangay' => 'Baras',         'population' => 2890, 'households' => 654, 'vulnerable' => 502, 'hazards' => ['Flash Flood', 'Typhoon'], 'exposed' => 290, 'evac_cap' => 450, 'readiness_score' => 71, 'risk_level' => 'High',     'readiness_label' => 'Needs Improvement', 'completeness' => 90, 'last_assessed' => 'Jun 20, 2026', 'focal' => 'Lorna Reyes'],
        ['barangay' => 'Domorog',       'population' => 1980, 'households' => 445, 'vulnerable' => 318, 'hazards' => ['Landslide', 'Road Isolation'], 'exposed' => 210, 'evac_cap' => 300, 'readiness_score' => 55, 'risk_level' => 'High',     'readiness_label' => 'Needs Improvement', 'completeness' => 65, 'last_assessed' => 'Jun 5, 2026', 'focal' => 'Eduardo Santos'],
        ['barangay' => 'Agoho',         'population' => 2140, 'households' => 482, 'vulnerable' => 374, 'hazards' => ['Flooding'], 'exposed' => 195, 'evac_cap' => 350, 'readiness_score' => 78, 'risk_level' => 'Moderate',  'readiness_label' => 'Ready',             'completeness' => 95, 'last_assessed' => 'Jun 22, 2026', 'focal' => 'Marcelina Abad'],
        ['barangay' => 'Iligan',        'population' => 1640, 'households' => 371, 'vulnerable' => 289, 'hazards' => ['Flooding', 'Fire'], 'exposed' => 160, 'evac_cap' => 250, 'readiness_score' => 60, 'risk_level' => 'Moderate',  'readiness_label' => 'Needs Improvement', 'completeness' => 75, 'last_assessed' => 'Jun 10, 2026', 'focal' => 'Julita Fernandez'],
        ['barangay' => 'Labangtaytay',  'population' => 1210, 'households' => 275, 'vulnerable' => 198, 'hazards' => ['Landslide', 'Typhoon'], 'exposed' => 140, 'evac_cap' => 180, 'readiness_score' => 42, 'risk_level' => 'High',     'readiness_label' => 'Major Gaps',        'completeness' => 55, 'last_assessed' => 'Apr 15, 2026', 'focal' => 'Pedro Villanueva'],
        ['barangay' => 'Labrador',      'population' => 1480, 'households' => 334, 'vulnerable' => 245, 'hazards' => ['Flash Flood'], 'exposed' => 178, 'evac_cap' => 220, 'readiness_score' => 68, 'risk_level' => 'Moderate',  'readiness_label' => 'Needs Improvement', 'completeness' => 80, 'last_assessed' => 'Jun 18, 2026', 'focal' => 'Cecilia Navarro'],
        ['barangay' => 'Libertad',      'population' => 1320, 'households' => 298, 'vulnerable' => 210, 'hazards' => ['Flooding', 'Earthquake'], 'exposed' => 155, 'evac_cap' => 200, 'readiness_score' => 74, 'risk_level' => 'Moderate',  'readiness_label' => 'Ready',             'completeness' => 88, 'last_assessed' => 'Jun 25, 2026', 'focal' => 'Hernando Alcala'],
        ['barangay' => 'Magsaysay',     'population' => 1750, 'households' => 398, 'vulnerable' => 310, 'hazards' => ['Flooding'], 'exposed' => 220, 'evac_cap' => 280, 'readiness_score' => 52, 'risk_level' => 'High',     'readiness_label' => 'Needs Improvement', 'completeness' => 72, 'last_assessed' => 'May 30, 2026', 'focal' => 'Teresita Gomez'],
        ['barangay' => 'Potingbato',    'population' => 980,  'households' => 221, 'vulnerable' => 165, 'hazards' => ['Fire', 'Earthquake'], 'exposed' => 85, 'evac_cap' => 150, 'readiness_score' => 83, 'risk_level' => 'Low',       'readiness_label' => 'Ready',             'completeness' => 92, 'last_assessed' => 'Jun 28, 2026', 'focal' => 'Danilo Mateo'],
        ['barangay' => 'Rizal',         'population' => 1120, 'households' => 253, 'vulnerable' => 195, 'hazards' => ['Flooding', 'Typhoon'], 'exposed' => 130, 'evac_cap' => 190, 'readiness_score' => 66, 'risk_level' => 'Moderate',  'readiness_label' => 'Needs Improvement', 'completeness' => 78, 'last_assessed' => 'Jun 12, 2026', 'focal' => 'Gloria Espiritu'],
        ['barangay' => 'San Roque',     'population' => 1390, 'households' => 315, 'vulnerable' => 248, 'hazards' => ['Flooding'], 'exposed' => 170, 'evac_cap' => 230, 'readiness_score' => 59, 'risk_level' => 'Moderate',  'readiness_label' => 'Needs Improvement', 'completeness' => 68, 'last_assessed' => 'May 22, 2026', 'focal' => 'Ernesto Aguilar'],
        ['barangay' => 'Santiago',      'population' => 1650, 'households' => 374, 'vulnerable' => 285, 'hazards' => ['Flash Flood', 'Landslide'], 'exposed' => 200, 'evac_cap' => 260, 'readiness_score' => 45, 'risk_level' => 'High',     'readiness_label' => 'Major Gaps',        'completeness' => 60, 'last_assessed' => 'Apr 28, 2026', 'focal' => 'Amalia Dela Cruz'],
        ['barangay' => 'Sorosimbajan',  'population' => 890,  'households' => 201, 'vulnerable' => 148, 'hazards' => ['Typhoon', 'Earthquake'], 'exposed' => 78, 'evac_cap' => 140, 'readiness_score' => 80, 'risk_level' => 'Low',       'readiness_label' => 'Ready',             'completeness' => 90, 'last_assessed' => 'Jun 30, 2026', 'focal' => 'Antonio Mendez'],
        ['barangay' => 'Tawad',         'population' => 760,  'households' => 172, 'vulnerable' => 120, 'hazards' => ['Road Isolation'], 'exposed' => 65, 'evac_cap' => 120, 'readiness_score' => 38, 'risk_level' => 'Critical', 'readiness_label' => 'Not Assessed',      'completeness' => 40, 'last_assessed' => 'Mar 10, 2026', 'focal' => 'Unassigned'],
        ['barangay' => 'Tunga',         'population' => 1040, 'households' => 235, 'vulnerable' => 178, 'hazards' => ['Flooding', 'Fire'], 'exposed' => 112, 'evac_cap' => 170, 'readiness_score' => 70, 'risk_level' => 'Moderate',  'readiness_label' => 'Needs Improvement', 'completeness' => 82, 'last_assessed' => 'Jun 8, 2026', 'focal' => 'Maricel Soriano'],
        ['barangay' => 'Villa1',        'population' => 830,  'households' => 188, 'vulnerable' => 134, 'hazards' => ['Drought', 'Extreme Heat'], 'exposed' => 60, 'evac_cap' => 130, 'readiness_score' => 75, 'risk_level' => 'Low',       'readiness_label' => 'Ready',             'completeness' => 88, 'last_assessed' => 'Jun 16, 2026', 'focal' => 'Benito Padilla'],
        ['barangay' => 'Guadalupe',     'population' => 1180, 'households' => 266, 'vulnerable' => 202, 'hazards' => ['Flooding', 'Agricultural Pest'], 'exposed' => 145, 'evac_cap' => 190, 'readiness_score' => 64, 'risk_level' => 'Moderate',  'readiness_label' => 'Needs Improvement', 'completeness' => 76, 'last_assessed' => 'Jun 3, 2026', 'focal' => 'Consuelo Ramos'],
        ['barangay' => 'Almero',        'population' => 940,  'households' => 213, 'vulnerable' => 155, 'hazards' => ['Landslide'], 'exposed' => 90, 'evac_cap' => 140, 'readiness_score' => 57, 'risk_level' => 'Moderate',  'readiness_label' => 'Needs Improvement', 'completeness' => 70, 'last_assessed' => 'May 15, 2026', 'focal' => 'Roberto Flores'],
    ];

    // ── Incidents ────────────────────────────────────────────────────────────
    $incidents = [
        ['id' => 'INC-2026-0084', 'type' => 'Flood', 'barangay' => 'Masbaranon', 'location' => 'Purok 3, near river bank', 'severity' => 'Critical', 'reported' => '2026-07-15 06:12', 'source' => 'Barangay', 'reporter' => 'Rodel Almanza', 'contact' => '09171234567', 'affected' => 142, 'vulnerable' => 38, 'team' => 'Rescue Team Alpha', 'lead' => 'Sgt. Ramiro Dela Vega', 'status' => 'On Scene', 'elapsed' => '2h 14m', 'description' => 'Severe flooding in low-lying areas of Purok 3. At least 38 families stranded on rooftops. Flash flood triggered by overnight heavy rainfall from the southwest monsoon.'],
        ['id' => 'INC-2026-0083', 'type' => 'Landslide', 'barangay' => 'Domorog', 'location' => 'Sitio Lahos, upland road', 'severity' => 'High', 'reported' => '2026-07-15 05:48', 'source' => 'Barangay', 'reporter' => 'Kagawad Robles', 'contact' => '09181234567', 'affected' => 8, 'vulnerable' => 3, 'team' => 'Rescue Team Bravo', 'lead' => 'PO3 Lito Castillo', 'status' => 'En Route', 'elapsed' => '38m', 'description' => 'Partial landslide blocking upland access road. Two households partially covered. Road clearing required before rescue can proceed.'],
        ['id' => 'INC-2026-0082', 'type' => 'Rescue Request', 'barangay' => 'Baras', 'location' => 'Purok 1, flooded crossing', 'severity' => 'High', 'reported' => '2026-07-15 07:20', 'source' => 'MDRRMO Hotline', 'reporter' => 'Maria Panganiban', 'contact' => '09201234567', 'affected' => 6, 'vulnerable' => 2, 'team' => 'Unassigned', 'lead' => '—', 'status' => 'Validated', 'elapsed' => '1h 06m', 'description' => 'Family of 6 stranded at flooded river crossing. Mother with infant and elderly grandmother present.'],
        ['id' => 'INC-2026-0081', 'type' => 'Stranded Resident', 'barangay' => 'Labangtaytay', 'location' => 'Sitio Punglo', 'severity' => 'High', 'reported' => '2026-07-15 04:30', 'source' => 'Citizen Mobile App', 'reporter' => 'Citizen Report', 'contact' => '—', 'affected' => 24, 'vulnerable' => 9, 'team' => 'Rescue Team Bravo', 'lead' => 'PO3 Lito Castillo', 'status' => 'Assigned', 'elapsed' => '3h 56m', 'description' => 'Sitio Punglo road isolated due to flooding. 24 residents unable to evacuate. Senior citizens and children present.'],
        ['id' => 'INC-2026-0080', 'type' => 'Medical Emergency', 'barangay' => 'Poblacion', 'location' => 'Purok 5, evacuation center', 'severity' => 'Medium', 'reported' => '2026-07-15 08:05', 'source' => 'Field Responder', 'reporter' => 'Nurse Carla Mendez', 'contact' => '09251234567', 'affected' => 1, 'vulnerable' => 1, 'team' => 'Municipal Health Team', 'lead' => 'Dr. Rosario Dela Cruz', 'status' => 'On Scene', 'elapsed' => '32m', 'description' => 'Elderly male evacuee at Poblacion covered court experiencing chest pain. Awaiting ambulance transfer to RHU.'],
        ['id' => 'INC-2026-0079', 'type' => 'Damaged Bridge', 'barangay' => 'Santiago', 'location' => 'Brgy. Road, main bridge', 'severity' => 'High', 'reported' => '2026-07-14 22:15', 'source' => 'Barangay', 'reporter' => 'Brgy. Captain Ramos', 'contact' => '09301234567', 'affected' => 0, 'vulnerable' => 0, 'team' => 'MPDO Engineering', 'lead' => 'Engr. Panfilo Ocampo', 'status' => 'Dispatched', 'elapsed' => '9h 51m', 'description' => 'Bridge slab displaced by flood surge. Passable on foot only. Cuts access to upland sitios. Engineering team dispatched for assessment.'],
        ['id' => 'INC-2026-0078', 'type' => 'Road Obstruction', 'barangay' => 'Agoho', 'location' => 'National Highway, Km 14', 'severity' => 'Medium', 'reported' => '2026-07-14 21:40', 'source' => 'Police', 'reporter' => 'PNP Esperanza', 'contact' => '09351234567', 'affected' => 0, 'vulnerable' => 0, 'team' => 'MPDO Engineering', 'lead' => 'Engr. Panfilo Ocampo', 'status' => 'Contained', 'elapsed' => '10h 26m', 'description' => 'Fallen trees and debris blocking national highway. PNP on site. Chainsaw team deployed.'],
        ['id' => 'INC-2026-0077', 'type' => 'Flood', 'barangay' => 'Magsaysay', 'location' => 'Low-lying areas, river vicinity', 'severity' => 'High', 'reported' => '2026-07-14 20:00', 'source' => 'Barangay', 'reporter' => 'Kagawad Laguna', 'contact' => '09401234567', 'affected' => 87, 'vulnerable' => 24, 'team' => 'Rescue Team Alpha', 'lead' => 'Sgt. Ramiro Dela Vega', 'status' => 'Resolved', 'elapsed' => '4h 22m', 'description' => 'River overflowed affecting 87 persons in riverside puroks. All families evacuated to Magsaysay Barangay Hall.'],
        ['id' => 'INC-2026-0076', 'type' => 'Power Interruption', 'barangay' => 'Iligan', 'location' => 'Entire Barangay', 'severity' => 'Low', 'reported' => '2026-07-14 19:30', 'source' => 'Barangay', 'reporter' => 'Brgy. Secretary', 'contact' => '09451234567', 'affected' => 371, 'vulnerable' => 0, 'team' => 'Unassigned', 'lead' => '—', 'status' => 'For Validation', 'elapsed' => '12h 36m', 'description' => 'Power interruption affecting entire barangay. MASELCO notified. Generator for health station requested.'],
        ['id' => 'INC-2026-0075', 'type' => 'Agricultural Damage', 'barangay' => 'Guadalupe', 'location' => 'Rice fields, Purok 2 and 4', 'severity' => 'Medium', 'reported' => '2026-07-14 18:00', 'source' => 'Barangay', 'reporter' => 'Farmer Leader Cañete', 'contact' => '09501234567', 'affected' => 45, 'vulnerable' => 0, 'team' => 'DA Extension Team', 'lead' => 'Agri. Technologist Yap', 'status' => 'Assigned', 'elapsed' => '14h 06m', 'description' => 'Approximately 12 hectares of rice fields inundated. Damage assessment requested.'],
        ['id' => 'INC-2026-0074', 'type' => 'Flood', 'barangay' => 'Rizal', 'location' => 'Riverside sitios', 'severity' => 'Medium', 'reported' => '2026-07-14 16:45', 'source' => 'Citizen Mobile App', 'reporter' => 'Multiple Reports', 'contact' => '—', 'affected' => 52, 'vulnerable' => 15, 'team' => 'Barangay DRRM Team', 'lead' => 'Brgy. Captain Buenaventura', 'status' => 'Resolved', 'elapsed' => '6h 41m', 'description' => 'Flooding in riverside sitios, 12 families evacuated to barangay hall. Waters receding.'],
        ['id' => 'INC-2026-0073', 'type' => 'Missing Person', 'barangay' => 'San Roque', 'location' => 'Near irrigation canal', 'severity' => 'Critical', 'reported' => '2026-07-14 15:00', 'source' => 'MDRRMO Hotline', 'reporter' => 'Family Member', 'contact' => '09551234567', 'affected' => 1, 'vulnerable' => 1, 'team' => 'PNP + Rescue Team Alpha', 'lead' => 'PO1 Ramirez', 'status' => 'Dispatched', 'elapsed' => '17h 26m', 'description' => 'Child (10 years old) missing since yesterday afternoon near swollen irrigation canal. Search and rescue ongoing.'],
    ];

    // ── Evacuation Centers ───────────────────────────────────────────────────
    $centers = [
        ['id' => 'EC-001', 'name' => 'Poblacion Covered Court', 'barangay' => 'Poblacion', 'type' => 'Covered Court', 'manager' => 'Elvira Sison', 'contact' => '09121111001', 'capacity' => 250, 'max_capacity' => 300, 'occupants' => 198, 'families' => 52, 'pwsn' => 14, 'status' => 'Open', 'safety_rating' => 'Good', 'last_inspection' => 'Jun 20, 2026'],
        ['id' => 'EC-002', 'name' => 'Masbaranon Elementary School', 'barangay' => 'Masbaranon', 'type' => 'School', 'manager' => 'Edgardo Navarro', 'contact' => '09121111002', 'capacity' => 200, 'max_capacity' => 250, 'occupants' => 189, 'families' => 48, 'pwsn' => 18, 'status' => 'Near Capacity', 'safety_rating' => 'Fair', 'last_inspection' => 'May 15, 2026'],
        ['id' => 'EC-003', 'name' => 'Baras Barangay Hall', 'barangay' => 'Baras', 'type' => 'Barangay Hall', 'manager' => 'Corazon Tapayan', 'contact' => '09121111003', 'capacity' => 150, 'max_capacity' => 180, 'occupants' => 87, 'families' => 22, 'pwsn' => 8, 'status' => 'Open', 'safety_rating' => 'Good', 'last_inspection' => 'Jun 15, 2026'],
        ['id' => 'EC-004', 'name' => 'Domorog Multi-Purpose Hall', 'barangay' => 'Domorog', 'type' => 'Multi-Purpose Hall', 'manager' => 'Feliciano Reyes', 'contact' => '09121111004', 'capacity' => 120, 'max_capacity' => 150, 'occupants' => 76, 'families' => 19, 'pwsn' => 6, 'status' => 'Open', 'safety_rating' => 'Good', 'last_inspection' => 'Jun 10, 2026'],
        ['id' => 'EC-005', 'name' => 'Magsaysay Barangay Hall', 'barangay' => 'Magsaysay', 'type' => 'Barangay Hall', 'manager' => 'Linda Razon', 'contact' => '09121111005', 'capacity' => 100, 'max_capacity' => 130, 'occupants' => 103, 'families' => 28, 'pwsn' => 11, 'status' => 'Near Capacity', 'safety_rating' => 'Fair', 'last_inspection' => 'Apr 20, 2026'],
        ['id' => 'EC-006', 'name' => 'Esperanza Municipal Gymnasium', 'barangay' => 'Poblacion', 'type' => 'Municipal Building', 'manager' => 'Rodrigo Castillo', 'contact' => '09121111006', 'capacity' => 500, 'max_capacity' => 600, 'occupants' => 321, 'families' => 84, 'pwsn' => 31, 'status' => 'Open', 'safety_rating' => 'Very Good', 'last_inspection' => 'Jul 1, 2026'],
        ['id' => 'EC-007', 'name' => 'Iligan Elementary School', 'barangay' => 'Iligan', 'type' => 'School', 'manager' => 'Priscilla Buena', 'contact' => '09121111007', 'capacity' => 180, 'max_capacity' => 220, 'occupants' => 54, 'families' => 14, 'pwsn' => 5, 'status' => 'Open', 'safety_rating' => 'Good', 'last_inspection' => 'Jun 25, 2026'],
        ['id' => 'EC-008', 'name' => 'Agoho Covered Court', 'barangay' => 'Agoho', 'type' => 'Covered Court', 'manager' => 'Domingo Borja', 'contact' => '09121111008', 'capacity' => 140, 'max_capacity' => 170, 'occupants' => 0, 'families' => 0, 'pwsn' => 0, 'status' => 'Standby', 'safety_rating' => 'Good', 'last_inspection' => 'Jun 18, 2026'],
        ['id' => 'EC-009', 'name' => 'Santiago Barangay Hall', 'barangay' => 'Santiago', 'type' => 'Barangay Hall', 'manager' => 'Unassigned', 'contact' => '—', 'capacity' => 80, 'max_capacity' => 100, 'occupants' => 0, 'families' => 0, 'pwsn' => 0, 'status' => 'Closed', 'safety_rating' => 'Needs Inspection', 'last_inspection' => 'Jan 12, 2026'],
        ['id' => 'EC-010', 'name' => 'San Roque Parish Hall', 'barangay' => 'San Roque', 'type' => 'Church Facility', 'manager' => 'Fr. Domingo Lim', 'contact' => '09121111010', 'capacity' => 200, 'max_capacity' => 250, 'occupants' => 0, 'families' => 0, 'pwsn' => 0, 'status' => 'Standby', 'safety_rating' => 'Good', 'last_inspection' => 'Jun 5, 2026'],
    ];

    // ── Evacuees ─────────────────────────────────────────────────────────────
    $evacuees = [
        ['id' => 'EVA-001', 'head' => 'Rodrigo Panganiban', 'members' => 5, 'home_brgy' => 'Masbaranon', 'home_sitio' => 'Purok 3', 'center' => 'Masbaranon Elementary School', 'zone' => 'Room 1-A', 'checkin' => '2026-07-15 07:30', 'health_flags' => ['Senior Citizen', 'Chronic Medication'], 'needs' => ['Mobility Assistance'], 'status' => 'Checked In'],
        ['id' => 'EVA-002', 'head' => 'Nenita Cruz', 'members' => 4, 'home_brgy' => 'Masbaranon', 'home_sitio' => 'Purok 3', 'center' => 'Masbaranon Elementary School', 'zone' => 'Room 1-A', 'checkin' => '2026-07-15 07:45', 'health_flags' => ['Infant (under 1)'], 'needs' => [], 'status' => 'Checked In'],
        ['id' => 'EVA-003', 'head' => 'Bernardo Reyes', 'members' => 7, 'home_brgy' => 'Masbaranon', 'home_sitio' => 'Purok 4', 'center' => 'Masbaranon Elementary School', 'zone' => 'Room 1-B', 'checkin' => '2026-07-15 08:10', 'health_flags' => ['PWD'], 'needs' => ['Wheelchair'], 'status' => 'Checked In'],
        ['id' => 'EVA-004', 'head' => 'Rosario Dela Cruz', 'members' => 3, 'home_brgy' => 'Baras', 'home_sitio' => 'Purok 1', 'center' => 'Baras Barangay Hall', 'zone' => 'Main Hall', 'checkin' => '2026-07-15 09:00', 'health_flags' => ['Pregnant'], 'needs' => ['Medical Monitoring'], 'status' => 'Checked In'],
        ['id' => 'EVA-005', 'head' => 'Eduardo Santos', 'members' => 6, 'home_brgy' => 'Domorog', 'home_sitio' => 'Purok 2', 'center' => 'Domorog Multi-Purpose Hall', 'zone' => 'Section A', 'checkin' => '2026-07-15 06:50', 'health_flags' => [], 'needs' => [], 'status' => 'Checked In'],
        ['id' => 'EVA-006', 'head' => 'Margarita Flores', 'members' => 4, 'home_brgy' => 'Magsaysay', 'home_sitio' => 'Riverside', 'center' => 'Magsaysay Barangay Hall', 'zone' => 'Main Hall', 'checkin' => '2026-07-14 21:00', 'health_flags' => ['Senior Citizen'], 'needs' => [], 'status' => 'Checked In'],
        ['id' => 'EVA-007', 'head' => 'Antonio Mendez', 'members' => 8, 'home_brgy' => 'Poblacion', 'home_sitio' => 'Purok 5', 'center' => 'Poblacion Covered Court', 'zone' => 'Zone B', 'checkin' => '2026-07-15 05:30', 'health_flags' => ['Children (0-5)', 'Infant (under 1)'], 'needs' => ['Baby Supplies'], 'status' => 'Checked In'],
        ['id' => 'EVA-008', 'head' => 'Felisa Bautista', 'members' => 5, 'home_brgy' => 'Poblacion', 'home_sitio' => 'Purok 5', 'center' => 'Esperanza Municipal Gymnasium', 'zone' => 'Sector 2', 'checkin' => '2026-07-15 06:15', 'health_flags' => ['Bedridden Resident'], 'needs' => ['Medical Equipment', 'Mobility Assistance'], 'status' => 'Checked In'],
        ['id' => 'EVA-009', 'head' => 'Hernando Alcala', 'members' => 3, 'home_brgy' => 'Iligan', 'home_sitio' => 'Purok 2', 'center' => 'Iligan Elementary School', 'zone' => 'Room 2-A', 'checkin' => '2026-07-15 08:45', 'health_flags' => [], 'needs' => [], 'status' => 'Checked In'],
        ['id' => 'EVA-010', 'head' => 'Consuelo Ramos', 'members' => 6, 'home_brgy' => 'Masbaranon', 'home_sitio' => 'Purok 2', 'center' => 'Masbaranon Elementary School', 'zone' => 'Room 2-A', 'checkin' => '2026-07-15 07:20', 'health_flags' => ['Chronic Medication'], 'needs' => ['Medicine'], 'status' => 'Checked In'],
        ['id' => 'EVA-011', 'head' => 'Gerardo Umali', 'members' => 4, 'home_brgy' => 'Baras', 'home_sitio' => 'Purok 2', 'center' => 'Baras Barangay Hall', 'zone' => 'Main Hall', 'checkin' => '2026-07-15 09:30', 'health_flags' => [], 'needs' => [], 'status' => 'Temporarily Out'],
        ['id' => 'EVA-012', 'head' => 'Natividad Villanueva', 'members' => 7, 'home_brgy' => 'Domorog', 'home_sitio' => 'Purok 1', 'center' => 'Domorog Multi-Purpose Hall', 'zone' => 'Section B', 'checkin' => '2026-07-14 23:00', 'health_flags' => ['PWD', 'Senior Citizen'], 'needs' => ['Wheelchair', 'Mobility Assistance'], 'status' => 'Checked In'],
        ['id' => 'EVA-013', 'head' => 'Danilo Mateo', 'members' => 5, 'home_brgy' => 'Magsaysay', 'home_sitio' => 'Sitio Tagbairan', 'center' => 'Esperanza Municipal Gymnasium', 'zone' => 'Sector 1', 'checkin' => '2026-07-15 04:45', 'health_flags' => [], 'needs' => [], 'status' => 'Returned Home'],
        ['id' => 'EVA-014', 'head' => 'Teresita Gomez', 'members' => 3, 'home_brgy' => 'Poblacion', 'home_sitio' => 'Purok 6', 'center' => 'Poblacion Covered Court', 'zone' => 'Zone A', 'checkin' => '2026-07-15 06:00', 'health_flags' => [], 'needs' => [], 'status' => 'Checked In'],
    ];

    // ── Resources ─────────────────────────────────────────────────────────────
    $resources = [
        ['id' => 'RES-001', 'name' => 'Rescue Team Alpha', 'category' => 'Response Teams', 'office' => 'MDRRMO', 'station' => 'Municipal Hall', 'barangay' => 'Poblacion', 'status' => 'On Scene', 'condition' => 'Good', 'personnel' => 8, 'deployment' => 'INC-2026-0084', 'fuel' => 75, 'last_inspection' => 'Jul 10, 2026'],
        ['id' => 'RES-002', 'name' => 'Rescue Team Bravo', 'category' => 'Response Teams', 'office' => 'MDRRMO', 'station' => 'Municipal Hall', 'barangay' => 'Poblacion', 'status' => 'En Route', 'condition' => 'Good', 'personnel' => 6, 'deployment' => 'INC-2026-0083', 'fuel' => 60, 'last_inspection' => 'Jul 10, 2026'],
        ['id' => 'RES-003', 'name' => 'MDRRMO Rescue Boat A', 'category' => 'Boats', 'office' => 'MDRRMO', 'station' => 'MDRRMO Bodega', 'barangay' => 'Poblacion', 'status' => 'Deployed', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'INC-2026-0084', 'fuel' => 50, 'last_inspection' => 'Jul 5, 2026'],
        ['id' => 'RES-004', 'name' => 'MDRRMO Rescue Truck 1', 'category' => 'Rescue Trucks', 'office' => 'MDRRMO', 'station' => 'Municipal Hall', 'barangay' => 'Poblacion', 'status' => 'En Route', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'INC-2026-0083', 'fuel' => 80, 'last_inspection' => 'Jul 8, 2026'],
        ['id' => 'RES-005', 'name' => 'Municipal Ambulance 1', 'category' => 'Ambulances', 'office' => 'Municipal Health Office', 'station' => 'RHU', 'barangay' => 'Poblacion', 'status' => 'On Scene', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'INC-2026-0080', 'fuel' => 85, 'last_inspection' => 'Jul 12, 2026'],
        ['id' => 'RES-006', 'name' => 'Emergency Generator G1', 'category' => 'Generators', 'office' => 'MDRRMO', 'station' => 'MDRRMO Bodega', 'barangay' => 'Poblacion', 'status' => 'Deployed', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'EC-006', 'fuel' => 40, 'last_inspection' => 'Jun 30, 2026'],
        ['id' => 'RES-007', 'name' => 'Emergency Generator G2', 'category' => 'Generators', 'office' => 'MDRRMO', 'station' => 'MDRRMO Bodega', 'barangay' => 'Poblacion', 'status' => 'Available', 'condition' => 'Good', 'personnel' => 0, 'deployment' => '—', 'fuel' => 90, 'last_inspection' => 'Jun 30, 2026'],
        ['id' => 'RES-008', 'name' => 'Water Tanker A', 'category' => 'Vehicles', 'office' => 'LWUA Office', 'station' => 'Municipal Hall', 'barangay' => 'Poblacion', 'status' => 'Deployed', 'condition' => 'Fair', 'personnel' => 0, 'deployment' => 'EC-002', 'fuel' => 55, 'last_inspection' => 'Jun 20, 2026'],
        ['id' => 'RES-009', 'name' => 'Chainsaw Unit 1', 'category' => 'Rescue Equipment', 'office' => 'MDRRMO', 'station' => 'MDRRMO Bodega', 'barangay' => 'Poblacion', 'status' => 'Deployed', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'INC-2026-0078', 'fuel' => 70, 'last_inspection' => 'Jul 1, 2026'],
        ['id' => 'RES-010', 'name' => 'Portable Radio Set (5 units)', 'category' => 'Radios', 'office' => 'MDRRMO', 'station' => 'Municipal Hall', 'barangay' => 'Poblacion', 'status' => 'Assigned', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'Multiple', 'fuel' => null, 'last_inspection' => 'Jul 10, 2026'],
        ['id' => 'RES-011', 'name' => 'Medical Team (RHU)', 'category' => 'Response Teams', 'office' => 'Municipal Health Office', 'station' => 'RHU', 'barangay' => 'Poblacion', 'status' => 'On Scene', 'condition' => 'Good', 'personnel' => 4, 'deployment' => 'EC-006', 'fuel' => null, 'last_inspection' => '—'],
        ['id' => 'RES-012', 'name' => 'MSWD Team (SWAD)', 'category' => 'Response Teams', 'office' => 'MSWD', 'station' => 'Municipal Hall', 'barangay' => 'Poblacion', 'status' => 'On Scene', 'condition' => 'Good', 'personnel' => 3, 'deployment' => 'EC-006', 'fuel' => null, 'last_inspection' => '—'],
        ['id' => 'RES-013', 'name' => 'MDRRMO Rescue Boat B', 'category' => 'Boats', 'office' => 'MDRRMO', 'station' => 'MDRRMO Bodega', 'barangay' => 'Poblacion', 'status' => 'Available', 'condition' => 'Fair', 'personnel' => 0, 'deployment' => '—', 'fuel' => 35, 'last_inspection' => 'Jun 15, 2026'],
        ['id' => 'RES-014', 'name' => 'Dump Truck (MPDO)', 'category' => 'Heavy Equipment', 'office' => 'MPDO', 'station' => 'Municipal Hall', 'barangay' => 'Poblacion', 'status' => 'Dispatched', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'INC-2026-0079', 'fuel' => 65, 'last_inspection' => 'Jul 5, 2026'],
        ['id' => 'RES-015', 'name' => 'Medical Emergency Kit (10 sets)', 'category' => 'Medical Equipment', 'office' => 'MDRRMO', 'station' => 'MDRRMO Bodega', 'barangay' => 'Poblacion', 'status' => 'Assigned', 'condition' => 'Good', 'personnel' => 0, 'deployment' => 'Field Centers', 'fuel' => null, 'last_inspection' => 'Jul 10, 2026'],
    ];

    // ── Relief Inventory ──────────────────────────────────────────────────────
    $inventory = [
        ['code' => 'INV-001', 'name' => 'Rice (50kg sack)', 'category' => 'Food', 'unit' => 'Sack', 'available' => 320, 'reserved' => 80, 'reorder' => 100, 'location' => 'Main Bodega', 'expiry' => '2026-12-31', 'condition' => 'Good', 'source' => 'DSWD Augmentation'],
        ['code' => 'INV-002', 'name' => 'Sardines (155g can)', 'category' => 'Food', 'unit' => 'Can', 'available' => 1800, 'reserved' => 400, 'reorder' => 500, 'location' => 'Main Bodega', 'expiry' => '2027-06-30', 'condition' => 'Good', 'source' => 'LGU Budget'],
        ['code' => 'INV-003', 'name' => 'Bottled Water (1.5L)', 'category' => 'Water', 'unit' => 'Bottle', 'available' => 480, 'reserved' => 200, 'reorder' => 300, 'location' => 'Main Bodega', 'expiry' => '2027-01-31', 'condition' => 'Good', 'source' => 'LGU Budget'],
        ['code' => 'INV-004', 'name' => 'Family Food Pack', 'category' => 'Food', 'unit' => 'Pack', 'available' => 95, 'reserved' => 60, 'reorder' => 100, 'location' => 'Main Bodega', 'expiry' => '2026-09-30', 'condition' => 'Good', 'source' => 'DSWD Pre-positioning'],
        ['code' => 'INV-005', 'name' => 'Hygiene Kit', 'category' => 'Non-Food', 'unit' => 'Kit', 'available' => 210, 'reserved' => 100, 'reorder' => 80, 'location' => 'Main Bodega', 'expiry' => null, 'condition' => 'Good', 'source' => 'LGU Budget'],
        ['code' => 'INV-006', 'name' => 'Sleeping Mat', 'category' => 'Non-Food', 'unit' => 'Piece', 'available' => 380, 'reserved' => 150, 'reorder' => 100, 'location' => 'Main Bodega', 'expiry' => null, 'condition' => 'Good', 'source' => 'LGU Stock'],
        ['code' => 'INV-007', 'name' => 'Blanket', 'category' => 'Non-Food', 'unit' => 'Piece', 'available' => 290, 'reserved' => 100, 'reorder' => 80, 'location' => 'Main Bodega', 'expiry' => null, 'condition' => 'Good', 'source' => 'LGU Stock'],
        ['code' => 'INV-008', 'name' => 'Amoxicillin 500mg', 'category' => 'Medicine', 'unit' => 'Tablet', 'available' => 350, 'reserved' => 50, 'reorder' => 200, 'location' => 'RHU Medicine Room', 'expiry' => '2026-11-30', 'condition' => 'Good', 'source' => 'DOH Allocation'],
        ['code' => 'INV-009', 'name' => 'ORS (Oral Rehydration)', 'category' => 'Medicine', 'unit' => 'Sachet', 'available' => 80, 'reserved' => 30, 'reorder' => 100, 'location' => 'RHU Medicine Room', 'expiry' => '2026-10-31', 'condition' => 'Good', 'source' => 'DOH Allocation'],
        ['code' => 'INV-010', 'name' => 'Baby Diapers (Assorted)', 'category' => 'Baby Supplies', 'unit' => 'Pack', 'available' => 45, 'reserved' => 20, 'reorder' => 50, 'location' => 'Main Bodega', 'expiry' => null, 'condition' => 'Good', 'source' => 'Donation'],
        ['code' => 'INV-011', 'name' => 'Tarpaulin 8x10ft', 'category' => 'Non-Food', 'unit' => 'Piece', 'available' => 62, 'reserved' => 25, 'reorder' => 50, 'location' => 'Main Bodega', 'expiry' => null, 'condition' => 'Good', 'source' => 'LGU Budget'],
        ['code' => 'INV-012', 'name' => 'Diesel (liter)', 'category' => 'Fuel', 'unit' => 'Liter', 'available' => 180, 'reserved' => 80, 'reorder' => 200, 'location' => 'MDRRMO Compound', 'expiry' => null, 'condition' => 'Good', 'source' => 'LGU Budget'],
        ['code' => 'INV-013', 'name' => 'Ready-to-Eat Meals', 'category' => 'Food', 'unit' => 'Pack', 'available' => 25, 'reserved' => 20, 'reorder' => 100, 'location' => 'Main Bodega', 'expiry' => '2026-08-15', 'condition' => 'Good', 'source' => 'OCD Pre-positioning'],
        ['code' => 'INV-014', 'name' => 'First Aid Kit (complete)', 'category' => 'Medical', 'unit' => 'Kit', 'available' => 18, 'reserved' => 5, 'reorder' => 20, 'location' => 'MDRRMO Bodega', 'expiry' => null, 'condition' => 'Good', 'source' => 'LGU Budget'],
        ['code' => 'INV-015', 'name' => 'Face Masks (surgical)', 'category' => 'PPE', 'unit' => 'Piece', 'available' => 900, 'reserved' => 200, 'reorder' => 500, 'location' => 'Main Bodega', 'expiry' => '2027-03-31', 'condition' => 'Good', 'source' => 'DOH Donation'],
    ];

    // ── Damage Assessments ───────────────────────────────────────────────────
    $assessments = [
        ['id' => 'DNA-2026-0018', 'incident' => 'SWM-2026-07', 'barangay' => 'Masbaranon', 'type' => 'Initial Rapid Assessment', 'date' => 'Jul 15, 2026', 'assessor' => 'MDRRMO Staff', 'affected_families' => 48, 'estimated_damage' => 2480000, 'priority_needs' => ['Rescue', 'Food', 'Water'], 'status' => 'Submitted'],
        ['id' => 'DNA-2026-0017', 'incident' => 'SWM-2026-07', 'barangay' => 'Baras', 'type' => 'Barangay Damage Assessment', 'date' => 'Jul 15, 2026', 'assessor' => 'Brgy. DRRM Team', 'affected_families' => 22, 'estimated_damage' => 890000, 'priority_needs' => ['Food', 'Shelter'], 'status' => 'For Validation'],
        ['id' => 'DNA-2026-0016', 'incident' => 'SWM-2026-07', 'barangay' => 'Domorog', 'type' => 'Infrastructure Assessment', 'date' => 'Jul 15, 2026', 'assessor' => 'MPDO Engineering', 'affected_families' => 0, 'estimated_damage' => 1200000, 'priority_needs' => ['Road Clearing'], 'status' => 'Draft'],
        ['id' => 'DNA-2026-0015', 'incident' => 'SWM-2026-07', 'barangay' => 'Magsaysay', 'type' => 'Barangay Damage Assessment', 'date' => 'Jul 14, 2026', 'assessor' => 'Brgy. DRRM Team', 'affected_families' => 28, 'estimated_damage' => 1150000, 'priority_needs' => ['Food', 'Water', 'Medicine'], 'status' => 'Validated'],
        ['id' => 'DNA-2026-0014', 'incident' => 'SWM-2026-07', 'barangay' => 'Santiago', 'type' => 'Infrastructure Assessment', 'date' => 'Jul 14, 2026', 'assessor' => 'MPDO Engineering', 'affected_families' => 0, 'estimated_damage' => 3200000, 'priority_needs' => ['Road Clearing', 'Power Restoration'], 'status' => 'Submitted'],
        ['id' => 'DNA-2026-0013', 'incident' => 'SWM-2026-07', 'barangay' => 'Guadalupe', 'type' => 'Agriculture Assessment', 'date' => 'Jul 14, 2026', 'assessor' => 'DA Extension Team', 'affected_families' => 45, 'estimated_damage' => 560000, 'priority_needs' => ['Livelihood Assistance'], 'status' => 'For Validation'],
        ['id' => 'DNA-2026-0012', 'incident' => 'SWM-2026-07', 'barangay' => 'Rizal', 'type' => 'Barangay Damage Assessment', 'date' => 'Jul 14, 2026', 'assessor' => 'Brgy. DRRM Team', 'affected_families' => 14, 'estimated_damage' => 420000, 'priority_needs' => ['Food', 'Shelter'], 'status' => 'Approved'],
        ['id' => 'DNA-2026-0011', 'incident' => 'SWM-2026-07', 'barangay' => 'Poblacion', 'type' => 'Housing Assessment', 'date' => 'Jul 14, 2026', 'assessor' => 'MDRRMO + MPDO', 'affected_families' => 84, 'estimated_damage' => 1870000, 'priority_needs' => ['Shelter', 'Food'], 'status' => 'Validated'],
    ];

    // ── Alerts ────────────────────────────────────────────────────────────────
    $alerts = [
        ['id' => 'ALT-2026-0024', 'type' => 'Flood Warning', 'level' => 'Warning', 'title' => 'Patuloy na Pagbaha sa Masbaranon at Baras', 'target' => 'Selected Barangays', 'channels' => ['SMS', 'Mobile Push', 'Portal Banner'], 'status' => 'Published', 'published' => '2026-07-15 06:00', 'created_by' => 'EOC Officer Sanchez', 'message' => 'Ang tubig-baha ay patuloy na tumataas sa mga mababang lugar ng Masbaranon at Baras. Inirerekomenda ang agarang bakwit para sa mga pamilyang naninirahan sa tabi ng ilog.'],
        ['id' => 'ALT-2026-0023', 'type' => 'Pre-emptive Evacuation', 'level' => 'Critical', 'title' => 'Sapilitang Bakwit — Masbaranon Purok 3 at 4', 'target' => 'Municipality-Wide', 'channels' => ['SMS', 'Mobile Push', 'Barangay Notification', 'Portal Banner'], 'status' => 'Published', 'published' => '2026-07-15 05:30', 'created_by' => 'MDRRMO Head Salinas', 'message' => 'Ang lahat ng pamilyang naninirahan sa Purok 3 at 4 ng Masbaranon ay kailangang lumikas na agad. Ang lifeboat ay naka-deploy sa Purok 3 embankment.'],
        ['id' => 'ALT-2026-0022', 'type' => 'Class Suspension', 'level' => 'Advisory', 'title' => 'Suspensyon ng Klase — Hulyo 15, 2026', 'target' => 'Municipality-Wide', 'channels' => ['SMS', 'Mobile Push', 'Portal Banner', 'Social Media'], 'status' => 'Published', 'published' => '2026-07-14 22:00', 'created_by' => 'Municipal Mayor\'s Office', 'message' => 'Ang lahat ng antas ng paaralan sa Munisipalidad ng Esperanza ay walang klase sa Hulyo 15, 2026 dahil sa matinding ulan at pagbaha.'],
        ['id' => 'ALT-2026-0021', 'type' => 'Evacuation Center Opening', 'level' => 'Information', 'title' => 'Bukas na ang Esperanza Municipal Gymnasium bilang Evacuation Center', 'target' => 'Municipality-Wide', 'channels' => ['Mobile Push', 'Portal Banner', 'Barangay Notification'], 'status' => 'Published', 'published' => '2026-07-14 20:30', 'created_by' => 'EOC Officer Sanchez', 'message' => 'Ang Esperanza Municipal Gymnasium ay bukas na bilang evacuation center para sa mga apektadong pamilya. Doon na maaaring magtungo ang mga nangangailangan ng tirahan.'],
        ['id' => 'ALT-2026-0020', 'type' => 'Weather Advisory', 'level' => 'Watch', 'title' => 'Babala sa Malakas na Ulan — Hulyo 14-16, 2026', 'target' => 'Municipality-Wide', 'channels' => ['SMS', 'Mobile Push', 'Portal Banner'], 'status' => 'Published', 'published' => '2026-07-14 14:00', 'created_by' => 'MDRRMO Head Salinas', 'message' => 'Ayon sa PAGASA, inaasahan ang patuloy na malakas na ulan sa Masbate province dahil sa southwest monsoon. Maging alerto at iwasan ang mga lugar na madaling bahain.'],
        ['id' => 'ALT-2026-0019', 'type' => 'Relief Distribution Notice', 'level' => 'Information', 'title' => 'Pamamahagi ng Relief Goods — Hulyo 15', 'target' => 'Evacuees', 'channels' => ['Mobile Push', 'Barangay Notification'], 'status' => 'Draft', 'published' => '—', 'created_by' => 'Relief Officer Ramos', 'message' => 'Ang pamamahagi ng family food packs ay isasagawa sa lahat ng evacuation centers mula 10:00 AM hanggang 2:00 PM ng Hulyo 15, 2026.'],
        ['id' => 'ALT-2026-0018', 'type' => 'All Clear', 'level' => 'Information', 'title' => 'All Clear — Magsaysay Flooding Subsiding', 'target' => 'Selected Barangays', 'channels' => ['SMS', 'Mobile Push', 'Barangay Notification'], 'status' => 'Draft', 'published' => '—', 'created_by' => 'EOC Officer Sanchez', 'message' => 'Ang antas ng tubig sa Magsaysay ay bumababa na. Maaaring magsimulang bumalik ang mga pamilyang lumikas, ngunit manatiling alerto.'],
    ];
@endphp

<x-layouts.admin
    title="Sakuna"
    subtitle="Disaster risk, emergency operations, evacuation, relief, and recovery management."
    active="sakuna"
>

<div x-show="!$store.session.can('sakuna')" x-cloak>
    <x-admin.access-restricted module="Sakuna (Disaster Risk & Emergency Ops)" icon="shield-alert" />
</div>

<div
    x-show="$store.session.can('sakuna')"
    x-cloak
    x-data="{
        activeTab: '{{ $activeTab }}',
        opStatus: 'Red Alert',
        selectedPeriod: 'SWM-2026-07',
        selectedBarangay: '',
        ready: false,

        // Incident tab state
        incidentSearch: '',
        incidentTypeFilter: '',
        incidentSeverityFilter: '',
        incidentStatusFilter: '',
        selectedIncident: null,
        showIncidentDetail: false,
        showCreateIncident: false,
        showDispatch: false,
        dispatchTarget: null,

        // Vulnerability tab state
        vulSearch: '',
        vulRiskFilter: '',
        vulHazardFilter: '',
        vulReadinessFilter: '',
        selectedBarangayVul: null,
        showVulDetail: false,

        // Centers tab state
        centerSearch: '',
        centerStatusFilter: '',
        selectedCenter: null,
        showCenterDetail: false,
        showCreateCenter: false,
        showOpenCenterConfirm: false,
        showCloseCenterConfirm: false,
        pendingCenterAction: null,

        // Evacuees tab state
        evacueeSearch: '',
        evCenterFilter: '',
        evStatusFilter: '',
        evHealthFilter: '',
        selectedEvacuee: null,
        showEvacueeDetail: false,
        showEvacueeReg: false,
        evacueeRegStep: 1,

        // Resources tab state
        resourceSearch: '',
        resourceCategoryFilter: '',
        resourceStatusFilter: '',
        selectedResource: null,
        showResourceDetail: false,
        showDeployModal: false,
        deployTarget: null,

        // Relief tab state
        reliefSubtab: 'inventory',
        inventorySearch: '',
        inventoryCategoryFilter: '',
        showStockInModal: false,
        showStockOutModal: false,
        selectedInventoryItem: null,
        showRequestModal: false,

        // Damage tab state
        damageSearch: '',
        damageTypeFilter: '',
        damageStatusFilter: '',
        damageBarangayFilter: '',
        selectedAssessment: null,
        showAssessmentDetail: false,
        showCreateAssessment: false,

        // Alerts tab state
        alertSearch: '',
        alertTypeFilter: '',
        alertLevelFilter: '',
        alertStatusFilter: '',
        selectedAlert: null,
        showAlertDetail: false,
        showCreateAlert: false,
        alertComposerStep: 1,

        // Command center state
        showEOCConfirm: false,
        showDecisionModal: false,
        selectedDecision: null,

        // Reports tab
        reportBarangayFilter: '',
        reportPeriodFilter: 'SWM-2026-07',

        setTab(tab) {
            this.activeTab = tab;
            this.$nextTick(() => window.renderIcons?.());
        },

        opStatusColor() {
            const map = {
                'Normal': 'text-emerald-700 bg-emerald-50 border-emerald-200',
                'Monitoring': 'text-blue-700 bg-blue-50 border-blue-200',
                'Blue Alert': 'text-indigo-700 bg-indigo-50 border-indigo-200',
                'Red Alert': 'text-rose-700 bg-rose-50 border-rose-200',
                'Emergency Operations Activated': 'text-red-700 bg-red-100 border-red-300 font-semibold',
                'Recovery Operations': 'text-amber-700 bg-amber-50 border-amber-200',
            };
            return map[this.opStatus] || 'text-slate-600 bg-slate-50 border-slate-200';
        },

        severityBadge(sev) {
            const map = {
                'Critical': 'bg-rose-100 text-rose-700 border border-rose-200',
                'High': 'bg-orange-100 text-orange-700 border border-orange-200',
                'Medium': 'bg-amber-100 text-amber-700 border border-amber-200',
                'Low': 'bg-slate-100 text-slate-600 border border-slate-200',
            };
            return map[sev] || 'bg-slate-100 text-slate-600';
        },

        statusBadge(st) {
            const map = {
                'New': 'bg-sky-100 text-sky-700',
                'For Validation': 'bg-indigo-100 text-indigo-700',
                'Validated': 'bg-blue-100 text-blue-700',
                'Assigned': 'bg-violet-100 text-violet-700',
                'Dispatched': 'bg-purple-100 text-purple-700',
                'En Route': 'bg-fuchsia-100 text-fuchsia-700',
                'On Scene': 'bg-orange-100 text-orange-700',
                'Contained': 'bg-teal-100 text-teal-700',
                'Resolved': 'bg-emerald-100 text-emerald-700',
                'Closed': 'bg-slate-100 text-slate-500',
                'Referred': 'bg-pink-100 text-pink-700',
                'Open': 'bg-emerald-100 text-emerald-700',
                'Standby': 'bg-blue-100 text-blue-700',
                'Preparing': 'bg-amber-100 text-amber-700',
                'Near Capacity': 'bg-orange-100 text-orange-700',
                'Full': 'bg-rose-100 text-rose-700',
                'Temporarily Unavailable': 'bg-slate-100 text-slate-500',
                'Under Inspection': 'bg-indigo-100 text-indigo-700',
                'Available': 'bg-emerald-100 text-emerald-700',
                'Deployed': 'bg-orange-100 text-orange-700',
                'Returning': 'bg-teal-100 text-teal-700',
                'Under Maintenance': 'bg-slate-100 text-slate-500',
                'Out of Service': 'bg-rose-100 text-rose-700',
                'Checked In': 'bg-emerald-100 text-emerald-700',
                'Temporarily Out': 'bg-amber-100 text-amber-700',
                'Transferred': 'bg-blue-100 text-blue-700',
                'Returned Home': 'bg-slate-100 text-slate-500',
                'Referred to Hospital': 'bg-pink-100 text-pink-700',
                'Draft': 'bg-slate-100 text-slate-600',
                'Submitted': 'bg-blue-100 text-blue-700',
                'For Validation': 'bg-indigo-100 text-indigo-700',
                'For Approval': 'bg-violet-100 text-violet-700',
                'Approved': 'bg-emerald-100 text-emerald-700',
                'Returned for Revision': 'bg-amber-100 text-amber-700',
                'Consolidated': 'bg-teal-100 text-teal-700',
                'Published': 'bg-emerald-100 text-emerald-700',
                'Scheduled': 'bg-blue-100 text-blue-700',
                'Expired': 'bg-slate-100 text-slate-500',
                'Cancelled': 'bg-rose-100 text-rose-700',
                'Archived': 'bg-slate-100 text-slate-500',
            };
            return (map[st] || 'bg-slate-100 text-slate-600') + ' px-2.5 py-0.5 rounded-full text-xs font-medium';
        },

        riskBadge(risk) {
            const map = {
                'Critical': 'bg-rose-100 text-rose-700 border border-rose-200',
                'High': 'bg-orange-100 text-orange-700 border border-orange-200',
                'Moderate': 'bg-amber-100 text-amber-700 border border-amber-200',
                'Low': 'bg-emerald-100 text-emerald-700 border border-emerald-200',
            };
            return (map[risk] || 'bg-slate-100 text-slate-600') + ' px-2.5 py-0.5 rounded-full text-xs font-medium';
        },

        alertLevelBadge(level) {
            const map = {
                'Information': 'bg-sky-100 text-sky-700 border border-sky-200',
                'Advisory': 'bg-teal-100 text-teal-700 border border-teal-200',
                'Watch': 'bg-amber-100 text-amber-700 border border-amber-200',
                'Warning': 'bg-orange-100 text-orange-700 border border-orange-200',
                'Critical': 'bg-rose-100 text-rose-700 border border-rose-200',
            };
            return (map[level] || 'bg-slate-100 text-slate-600') + ' px-2.5 py-0.5 rounded-full text-xs font-medium';
        },

        occupancyBar(pct) {
            if (pct >= 90) return 'bg-rose-500';
            if (pct >= 75) return 'bg-orange-400';
            if (pct >= 50) return 'bg-amber-400';
            return 'bg-emerald-500';
        },

        toast(message, variant = 'success') {
            this.$dispatch('toast', { message, variant });
        },
    }"
    x-init="
        setTimeout(() => { ready = true; $nextTick(() => window.renderIcons?.()); }, 600);
    "
    class="space-y-4"
>
    {{-- ── Operational Status Bar ──────────────────────────────────────────── --}}
    <div class="flex flex-wrap items-center gap-2">
        <div class="relative" x-data="{ open: false }" @click.outside="open = false">
            <button @click="open = !open" :class="opStatusColor()" class="inline-flex items-center gap-2 text-sm font-medium border rounded-xl px-3 py-1.5 transition-all shadow-card">
                <i data-lucide="shield-alert" class="w-4 h-4"></i>
                <span x-text="opStatus"></span>
                <i data-lucide="chevron-down" class="w-3.5 h-3.5 opacity-60" :class="open && 'rotate-180'" style="transition: transform 0.2s"></i>
            </button>
            <div x-show="open" x-cloak x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 scale-95 -translate-y-1" x-transition:enter-end="opacity-100 scale-100 translate-y-0" class="absolute left-0 mt-2 w-64 bg-white rounded-2xl shadow-float border border-slate-100 overflow-hidden z-30 py-1.5">
                @foreach(['Normal', 'Monitoring', 'Blue Alert', 'Red Alert', 'Emergency Operations Activated', 'Recovery Operations'] as $s)
                    <button @click="opStatus = '{{ $s }}'; open = false; toast('Operational status set to {{ $s }}.', 'info')" class="w-full text-left px-4 py-2 text-sm transition-colors hover:bg-slate-50" :class="opStatus === '{{ $s }}' ? 'text-brand-600 font-medium bg-brand-50/60' : 'text-slate-600'">{{ $s }}</button>
                @endforeach
            </div>
        </div>

        <div class="relative" x-data="{ open: false, label: 'Southwest Monsoon & Flooding — July 2026' }" @click.outside="open = false">
            <button @click="open = !open" class="inline-flex items-center gap-2 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-1.5 shadow-card hover:border-slate-300 transition-colors">
                <i data-lucide="radio-tower" class="w-4 h-4 text-slate-400"></i>
                <span x-text="label" class="max-w-48 truncate"></span>
                <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-slate-400"></i>
            </button>
            <div x-show="open" x-cloak x-transition:enter="transition ease-out duration-150" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100" class="absolute left-0 mt-2 w-80 bg-white rounded-2xl shadow-float border border-slate-100 z-30 py-1.5">
                @foreach($periods as $p)
                    <button @click="label = '{{ $p['label'] }}'; selectedPeriod = '{{ $p['id'] }}'; open = false" class="w-full text-left px-4 py-2.5 text-sm hover:bg-slate-50 transition-colors {{ $p['active'] ? 'text-brand-600 font-medium' : 'text-slate-600' }}">
                        <div class="flex items-center gap-2">
                            @if($p['active'])<span class="w-1.5 h-1.5 rounded-full bg-brand-500 inline-block"></span>@endif
                            {{ $p['label'] }}
                        </div>
                    </button>
                @endforeach
            </div>
        </div>

        <span class="text-xs text-slate-400 flex items-center gap-1"><i data-lucide="refresh-cw" class="w-3 h-3"></i>Updated Jul 15, 2026 — 08:26 AM</span>

        <div class="ml-auto flex items-center gap-2">
            <button @click="toast('Situation report exported.', 'success')" class="inline-flex items-center gap-1.5 text-sm text-slate-600 bg-white border border-slate-200 rounded-xl px-3 py-1.5 shadow-card hover:border-slate-300 transition-colors">
                <i data-lucide="download" class="w-4 h-4 text-slate-400"></i> Export SitRep
            </button>
            <button @click="showEOCConfirm = true; $nextTick(() => window.renderIcons?.())" class="inline-flex items-center gap-1.5 text-sm font-medium text-white bg-rose-600 hover:bg-rose-700 rounded-xl px-3 py-1.5 shadow-card transition-colors">
                <i data-lucide="siren" class="w-4 h-4"></i> Activate EOC
            </button>
        </div>
    </div>

    {{-- ── Tab Navigation ───────────────────────────────────────────────────── --}}
    <div class="bg-white rounded-2xl border border-slate-100 shadow-card overflow-hidden">
        <div class="overflow-x-auto">
            <nav class="flex border-b border-slate-100 min-w-max">
                @php
                    $tabs = [
                        ['key' => 'command-center',    'label' => 'Command Center',    'icon' => 'monitor-check'],
                        ['key' => 'vulnerability',      'label' => 'Vulnerability',     'icon' => 'map-pin'],
                        ['key' => 'incidents',          'label' => 'Incidents',         'icon' => 'flame'],
                        ['key' => 'evacuation-centers', 'label' => 'Evac. Centers',    'icon' => 'house'],
                        ['key' => 'evacuees',           'label' => 'Evacuees',          'icon' => 'users'],
                        ['key' => 'resources',          'label' => 'Resources',         'icon' => 'truck'],
                        ['key' => 'relief',             'label' => 'Relief & Logistics','icon' => 'package'],
                        ['key' => 'damage-assessment',  'label' => 'Damage',            'icon' => 'clipboard-list'],
                        ['key' => 'alerts',             'label' => 'Alerts',            'icon' => 'bell-ring'],
                        ['key' => 'reports',            'label' => 'Reports',           'icon' => 'chart-bar'],
                    ];
                @endphp
                @foreach($tabs as $t)
                    <button
                        @click="setTab('{{ $t['key'] }}')"
                        :class="activeTab === '{{ $t['key'] }}' ? 'border-b-2 border-brand-500 text-brand-600 bg-brand-50/40' : 'text-slate-500 hover:text-slate-700 hover:bg-slate-50/60'"
                        class="inline-flex items-center gap-2 px-4 py-3.5 text-sm font-medium whitespace-nowrap transition-colors"
                    >
                        <i data-lucide="{{ $t['icon'] }}" class="w-4 h-4"></i>
                        {{ $t['label'] }}
                    </button>
                @endforeach
            </nav>
        </div>

        {{-- ── Tab Panels ───────────────────────────────────────────────────── --}}
        <div class="p-5">

            {{-- Command Center --}}
            <div x-show="activeTab === 'command-center'" x-cloak>
                @include('admin.partials.sakuna.tab-command', ['incidents' => $incidents, 'centers' => $centers, 'resources' => $resources])
            </div>

            {{-- Vulnerability --}}
            <div x-show="activeTab === 'vulnerability'" x-cloak>
                @include('admin.partials.sakuna.tab-vulnerability', ['profiles' => $vulnerabilityProfiles, 'barangays' => $barangays])
            </div>

            {{-- Incidents --}}
            <div x-show="activeTab === 'incidents'" x-cloak>
                @include('admin.partials.sakuna.tab-incidents', ['incidents' => $incidents, 'barangays' => $barangays])
            </div>

            {{-- Evacuation Centers --}}
            <div x-show="activeTab === 'evacuation-centers'" x-cloak>
                @include('admin.partials.sakuna.tab-centers', ['centers' => $centers, 'barangays' => $barangays])
            </div>

            {{-- Evacuees --}}
            <div x-show="activeTab === 'evacuees'" x-cloak>
                @include('admin.partials.sakuna.tab-evacuees', ['evacuees' => $evacuees, 'centers' => $centers, 'barangays' => $barangays])
            </div>

            {{-- Resources --}}
            <div x-show="activeTab === 'resources'" x-cloak>
                @include('admin.partials.sakuna.tab-resources', ['resources' => $resources, 'incidents' => $incidents, 'centers' => $centers])
            </div>

            {{-- Relief & Logistics --}}
            <div x-show="activeTab === 'relief'" x-cloak>
                @include('admin.partials.sakuna.tab-relief', ['inventory' => $inventory, 'barangays' => $barangays, 'centers' => $centers])
            </div>

            {{-- Damage Assessment --}}
            <div x-show="activeTab === 'damage-assessment'" x-cloak>
                @include('admin.partials.sakuna.tab-damage', ['assessments' => $assessments, 'barangays' => $barangays, 'incidents' => $incidents])
            </div>

            {{-- Alerts --}}
            <div x-show="activeTab === 'alerts'" x-cloak>
                @include('admin.partials.sakuna.tab-alerts', ['alerts' => $alerts, 'barangays' => $barangays])
            </div>

            {{-- Reports --}}
            <div x-show="activeTab === 'reports'" x-cloak>
                @include('admin.partials.sakuna.tab-reports', ['barangays' => $barangays, 'incidents' => $incidents, 'centers' => $centers])
            </div>

        </div>
    </div>

    {{-- ── EOC Activation Confirmation Modal ──────────────────────────────── --}}
    <div x-show="showEOCConfirm" x-cloak x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0" x-transition:enter-end="opacity-100" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm" @click.self="showEOCConfirm = false">
        <div x-transition:enter="transition ease-out duration-200" x-transition:enter-start="opacity-0 scale-95" x-transition:enter-end="opacity-100 scale-100" class="bg-white rounded-2xl shadow-float w-full max-w-md p-6">
            <div class="flex items-center gap-3 mb-4">
                <div class="w-12 h-12 rounded-2xl bg-rose-100 flex items-center justify-center flex-shrink-0">
                    <i data-lucide="siren" class="w-6 h-6 text-rose-600"></i>
                </div>
                <div>
                    <h3 class="text-base font-semibold text-slate-800">Activate Emergency Operations Center</h3>
                    <p class="text-sm text-slate-500">This is a high-impact action. Please confirm.</p>
                </div>
            </div>
            <p class="text-sm text-slate-600 mb-5">Activating the EOC will notify all department heads, MDRRMO personnel, and partner agencies. An EOC activation log will be recorded with your credentials and timestamp.</p>
            <div class="flex gap-3">
                <button @click="showEOCConfirm = false" class="flex-1 px-4 py-2.5 text-sm font-medium text-slate-600 bg-slate-100 rounded-xl hover:bg-slate-200 transition-colors">Cancel</button>
                <button @click="showEOCConfirm = false; opStatus = 'Emergency Operations Activated'; toast('EOC activated. All department heads notified.', 'success'); $nextTick(() => window.renderIcons?.())" class="flex-1 px-4 py-2.5 text-sm font-semibold text-white bg-rose-600 rounded-xl hover:bg-rose-700 transition-colors">Confirm Activation</button>
            </div>
        </div>
    </div>

</div>

</x-layouts.admin>
