import 'package:flutter/material.dart';

/// The kinds of incident a resident can report, the same list and names the
/// website's Emergency page offers (INCIDENT_TYPES and MORE_INCIDENT_TYPES in
/// resources/js/scope-citizen.js) and the server files by
/// (SakunaVocabulary::TYPES). Six are shown as tiles; the rest under
/// "More kinds", as on the website.
class IncidentType {
  const IncidentType(this.key, this.name, this.fil, this.icon);

  final String key;

  /// What is sent as `type`, and shown.
  final String name;
  final String fil;
  final IconData icon;
}

const incidentTypes = <IncidentType>[
  IncidentType('incident_flood', 'Flood', 'Baha', Icons.flood_outlined),
  IncidentType('incident_fire', 'Fire', 'Sunog', Icons.local_fire_department_outlined),
  IncidentType('incident_landslide', 'Landslide', 'Pagguho ng lupa', Icons.landslide_outlined),
  IncidentType('incident_medical', 'Medical Emergency', 'Medikal na emergency', Icons.medical_services_outlined),
  IncidentType('incident_road', 'Vehicular Accident', 'Aksidente sa sasakyan', Icons.car_crash_outlined),
  IncidentType('incident_other', 'Other', 'Iba pa', Icons.flag_outlined),
];

const moreIncidentTypes = <IncidentType>[
  IncidentType('incident_rescue', 'Rescue Request', 'Humihingi ng saklolo', Icons.support_outlined),
  IncidentType('incident_quake', 'Earthquake', 'Lindol', Icons.vibration),
  IncidentType('incident_missing', 'Missing Person', 'Nawawalang tao', Icons.person_search_outlined),
  IncidentType('incident_stranded', 'Stranded Resident', 'Residenteng na-stranded', Icons.sailing_outlined),
  IncidentType('incident_drowning', 'Drowning or Water Rescue', 'Nalulunod o saklolo sa tubig', Icons.pool_outlined),
  IncidentType('incident_tree', 'Fallen Tree', 'Natumbang puno', Icons.park_outlined),
  IncidentType(
    'incident_powerline',
    'Downed Power Line',
    'Bumagsak na kawad ng kuryente',
    Icons.electric_bolt_outlined,
  ),
  IncidentType('incident_obstruction', 'Road Obstruction', 'Harang sa daan', Icons.construction_outlined),
  IncidentType('incident_bridge', 'Damaged Bridge', 'Sirang tulay', Icons.add_road_outlined),
  IncidentType('incident_structure', 'Structural Damage', 'Pinsala sa gusali o bahay', Icons.house_siding_outlined),
  IncidentType('incident_farm', 'Agricultural Damage', 'Pinsala sa pananim o hayop', Icons.agriculture_outlined),
  IncidentType('incident_water', 'Water Interruption', 'Walang tubig', Icons.water_drop_outlined),
  IncidentType('incident_power', 'Power Interruption', 'Walang kuryente', Icons.power_off_outlined),
  IncidentType(
    'incident_health',
    'Public Health Emergency',
    'Emergency sa kalusugan ng publiko',
    Icons.health_and_safety_outlined,
  ),
];

const allIncidentTypes = <IncidentType>[...incidentTypes, ...moreIncidentTypes];

/// The severities, sent as they are (SakunaVocabulary::SEVERITIES).
const incidentSeverities = ['Low', 'Medium', 'High', 'Critical'];

/// Reports filed under the app's older names, read under the shared name
/// (the website's OLD_INCIDENT_TYPES).
const oldIncidentTypeNames = {'Flooding': 'Flood', 'Road Accident': 'Vehicular Accident', 'Other Concern': 'Other'};

/// A report's type in the shared name.
String incidentTypeName(String sent) => oldIncidentTypeNames[sent] ?? sent;
