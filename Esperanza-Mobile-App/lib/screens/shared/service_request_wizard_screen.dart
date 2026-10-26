import 'package:flutter/material.dart';
import '../../widgets/payment_guidance_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/citizen_account.dart';
import '../../models/document_preview.dart';
import '../../models/resident_profile.dart';
import '../../models/service_form_spec.dart';
import '../../models/service_request.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/document_templates_service.dart';
import '../../services/requests_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/age_calculator.dart';
import '../../utils/fee_inputs.dart';
import '../../utils/peso_text.dart';
import '../../utils/ph_mobile.dart';
import '../../utils/requirement_document_type.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/document_paper.dart';
import '../../widgets/zoomable_document.dart';
import '../../widgets/fee_input_fields.dart';
import '../../widgets/request_documents_picker.dart';
import '../../widgets/form_section.dart';
import '../../widgets/onboarding_step_indicator.dart';
import '../profile/resident_profile/personal_information_screen.dart';
import 'document_view_screen.dart';
import 'request_submitted_screen.dart';
import '../../theme/app_typography.dart';
import '../../widgets/esperanza_art.dart';

import '../../l10n/tr.dart';
import 'dart:async';
import '../../services/master_file_service.dart';
/// "Sir Paul's Required Form Experience" — a data-driven, multi-step
/// service-request wizard mirroring `RegisterScreen`'s step pattern
/// (indicator, per-step validation, Back/Continue, a Review step with
/// per-field Edit links) instead of the older single-screen Purpose +
/// Attachments form. Step count/labels come from the service's
/// [ServiceFormSpec] (see docs/DOKYU_TULONG_FORM_AUDIT.md for sourcing),
/// so a richly-sourced service like the Solo Parent application gets many
/// steps while a lightly-sourced one gets few — nothing here forces a
/// fixed step count.
///
/// Fixed steps around the data-driven middle:
///   0. Applicant Information (auto-filled from the signed-in account)
///   1..N. one step per `formSpec.steps` entry
///   N+1. Requirements & Attachments (from `item.requirements`)
///   N+2. Review & Submit
class ServiceRequestWizardScreen extends StatefulWidget {
  final ServiceCategory category;
  final CatalogItem item;
  final Color accent;

  const ServiceRequestWizardScreen({super.key, required this.category, required this.item, required this.accent});

  @override
  State<ServiceRequestWizardScreen> createState() => _ServiceRequestWizardScreenState();
}

class _ServiceRequestWizardScreenState extends State<ServiceRequestWizardScreen> {
  /// The primary demo resident — same id ResidentProfileService and
  /// RequestsService already use for their own Perlita-specific logic. Only
  /// her forms get [CatalogItem.demoDefaults]/[CatalogItem.demoPurpose]
  /// applied; a different verified resident's form stays exactly as
  /// blank/Master-Profile-only as before.
  static const _verifiedDemoAccountId = 'ESP-RES-2024-9002';

  List<ServiceFormStep> get _serviceSteps => widget.item.formSpec!.steps;
  int get _requirementsStep => _serviceSteps.length + 1;
  int get _reviewStep => _serviceSteps.length + 2;

  // Payment happens after real submission (issuing a receipt is admin-only,
  // see PRODUCTION_READINESS.md's mobile section) -- there is no citizen
  // payment endpoint to collect a method for, so Review is always the last
  // step regardless of whether this service has a fee.
  int get _lastStep => _reviewStep;

  late final List<String> _stepLabels = [
    'Applicant Info',
    for (final s in _serviceSteps) s.label,
    'Requirements',
    'Review',
  ];

  int _step = 0;
  String? _error;
  bool _submitting = false;

  // Applicant info (step 0) — the website's applicant block: prefilled from
  // the signed-in account, still editable since a request's details can
  // differ from the base profile (e.g. requesting on behalf of a household
  // matter). Sent as applicant_first_name ... applicant_email, as there.
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();

  // Service-specific field values, keyed by ServiceFormField.key. Text-like
  // fields are read from `_controllers`; everything else lives here.
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  // Master Profile — reusable demographic fields (see
  // docs on the "single source of truth" rule): keys this specific
  // service's formSpec happens to ask for AND the citizen's Resident
  // Profile already has an answer for. These render read-only (with an
  // "Edit Profile" escape hatch) instead of an editable input, so a single
  // request can never silently drift from the citizen's master record —
  // see _MasterSourcedField. Keys the profile *doesn't* have yet stay
  // normally editable and get backfilled into the profile on submit (see
  // _backfillMasterProfile), rather than left as a one-off, request-only
  // answer.
  static const _masterEligibleKeys = {'sex', 'civilStatus', 'occupation', 'educationalAttainment'};
  Individual? _personal;
  final Set<String> _prefilledFromProfile = {};

  // Requirements step — informational only now: POST /citizen/requests has
  // no attachments field, and the only real file-upload endpoint
  // (.../requirements/{key}/replace) requires a requirement to already be
  // staff-flagged, so there is no way to attach one at creation time (see
  // PRODUCTION_READINESS.md's mobile section, and RequestDetailScreen's own
  // correction-flow upload, which stays real). The wizard's Purpose/Notes
  // field is still real -- it flows into form_data.
  final _notesController = TextEditingController();
  /// The documents owed for the answers so far: a requirement asked only for
  /// some answers (the Solo Parent ID's category documents) shows once they
  /// call for it.
  List<RequirementInfo> get _requirementInfos => resolveRequirements(widget.item.requirementsFor(_values));

  // Every request takes its documents while it is filled in, Dokyu as well
  // as Tulong (live test 2026-10-07, UX-16): a Dokyu request said 'no need
  // to attach anything now', and then waited for the office to ask.

  /// Files picked on the Requirements step, by requirement label.
  final Map<String, Attachment> _picked = {};

  /// The amounts this service's fee is computed from ([CatalogItem.feeInputs]),
  /// asked on the Requirements step and sent as `fee_inputs`.
  late final Map<String, TextEditingController> _feeControllers = {
    for (final name in widget.item.feeInputs) name: TextEditingController(),
  };

  bool get _hasPurposeField => _serviceSteps.any((s) => s.fields.any((f) => f.key == 'purpose'));

  /// The Service Catalog's questions (the website's), not this app's own.
  bool get _fromServer => widget.item.formSpec!.fromServer;

  /// The "Others (please specify)" box of a multiselect.
  static String _otherKey(String key) => '$key::other';

  /// Whether [f] should currently be shown/enforced — see
  /// [ServiceFormField.visibleWhenKey]'s own doc comment. Fields with no
  /// gate are always visible, which is every pre-existing formSpec's
  /// entire field list, so this is a no-op for them.
  bool _isFieldVisible(ServiceFormField f) {
    final key = f.visibleWhenKey;
    if (key == null) return true;
    // The server's rule, read as the website reads it: the answer's text
    // contains the given words.
    if (f.visibleWhenContains != null) return _answerText(key).contains(f.visibleWhenContains!);
    return f.visibleWhenValueIn?.contains(_values[key]) ?? true;
  }

  /// An answer as text, for a show-if rule.
  String _answerText(String key) {
    final field = _fieldByKey(key);
    if (field == null) return '';
    return switch (field.type) {
      ServiceFieldType.multiselect => ((_values[key] as Set<String>?) ?? const <String>{}).join(','),
      ServiceFieldType.select => (_values[key] as String?) ?? '',
      ServiceFieldType.date => _dateOnly(_values[key] as DateTime?) ?? '',
      ServiceFieldType.checkbox => _values[key] == true ? 'true' : '',
      _ => _controllers[key]?.text ?? '',
    };
  }

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account;
    // "From My Papeles" offers what the wallet holds now.
    unawaited(context.read<MasterFileService?>()?.refreshQuietly(account?.id));
    if (account != null) {
      _firstName.text = account.firstName;
      _lastName.text = account.lastName;
      _address.text = account.address;
      _contact.text = PhMobile.normalise(account.mobile);
      _email.text = account.email;
    }
    if (_fromServer) {
      _applyServerDefaults(account);
    } else if (account != null) {
      // Sourced from the Resident Profile (the Master Profile's richer,
      // editable record) rather than the shallower CitizenSessionService
      // account — editing Personal Information never writes back to that
      // account object, so reading it directly here would show stale data
      // once a citizen updates their profile. ResidentProfileService seeds
      // a fresh profile straight from the account on first-ever access, so
      // this is never *less* complete than the old source, only ever more
      // current.
      final personal = context.read<ResidentProfileService>().profileFor(account).personal;
      _personal = personal;

      // Prefill Date of Birth from the citizen's existing Resident Profile
      // (already parsed to a real DateTime there) rather than making them
      // re-enter it on every application — see the global birthdate/age
      // rule in docs/DOKYU_TULONG_FORM_AUDIT.md. Only applied to field keys
      // this service actually asks for; 'party1DateOfBirth' covers the
      // Marriage License item, whose first party is assumed to be the
      // applicant.
      final dob = personal.birthdate;
      if (dob != null) {
        for (final key in const ['dateOfBirth', 'party1DateOfBirth']) {
          if (_serviceSteps.any((s) => s.fields.any((f) => f.key == key))) {
            _values[key] = dob;
          }
        }
      }

      // Same "single source of truth" treatment for the other reusable
      // demographic fields already modeled on the Master Profile. Text-
      // and select-typed fields store their current value differently
      // (_controllers vs. _values), so both are populated depending on
      // what this particular field actually is.
      for (final key in _masterEligibleKeys) {
        final masterValue = switch (key) {
          'sex' => personal.sex,
          'civilStatus' => personal.civilStatus,
          'occupation' => personal.occupation,
          'educationalAttainment' => personal.educationalAttainment,
          _ => '',
        };
        if (masterValue.trim().isEmpty) continue;
        final field = _fieldByKey(key);
        if (field == null) continue;
        if (field.type == ServiceFieldType.text) {
          _controllerFor(key).text = masterValue;
        } else if (field.type == ServiceFieldType.select) {
          // A select field's own local option list is sourced per-service
          // from an official form and isn't guaranteed to include every
          // Master Profile value verbatim (e.g. several older forms here
          // predate "Senior High School" as its own tier and only offer
          // "High School"/"College") — DropdownButtonFormField crashes
          // outright if given a value absent from its own items, so this
          // must never force a mismatched value in. Skipping leaves the
          // field a normal, still-required editable select the citizen
          // picks themself, same as before this Master Profile value ever
          // existed.
          if (field.options?.contains(masterValue) ?? false) {
            _values[key] = masterValue;
          } else {
            continue;
          }
        } else {
          _values[key] = masterValue;
        }
        _prefilledFromProfile.add(key);
      }

      // Richer student/family fields (Educational Assistance today — see
      // mock_catalog.dart's tulong_educational formSpec) prefilled the same
      // way Date of Birth is above: a starting value in an otherwise-
      // editable text field, not the stricter _masterEligibleKeys lock,
      // since Personal Information has no dedicated UI for these yet (only
      // Edit Profile's Basic Information covers the fields that lock).
      // Field keys match Individual's own field names exactly (see that
      // class's doc comment), so this is a direct 1:1 lookup.
      final personalPrefills = <String, String>{
        'placeOfBirth': personal.placeOfBirth,
        'schoolName': personal.schoolName,
        'yearOrGradeLevel': personal.yearOrGradeLevel,
        'degreeProgramOrCourse': personal.degreeProgramOrCourse,
        'lastSchoolAverageGrade': personal.lastSchoolAverageGrade,
        'communityInvolvement': personal.communityInvolvement,
        'postGraduationPlans': personal.postGraduationPlans,
      };
      for (final entry in personalPrefills.entries) {
        if (entry.value.trim().isEmpty) continue;
        final field = _fieldByKey(entry.key);
        if (field == null) continue;
        if (field.type == ServiceFieldType.select) {
          // Year / Grade Level is a choice now; a value typed into the
          // profile before that is used only when it is one of the choices
          // (an unmatched value would crash the dropdown).
          if (field.options?.contains(entry.value) ?? false) _values[entry.key] = entry.value;
        } else {
          _controllerFor(entry.key).text = entry.value;
        }
      }

      // Father/Mother — sourced from Family Information (relationshipToHead
      // == 'Father'/'Mother'), not from `personal` itself, so this is a
      // separate lookup from the block above.
      final profile = context.read<ResidentProfileService>().profileFor(account);
      Individual? familyMemberWhere(String relationship) {
        for (final m in profile.familyMembers) {
          if (m.relationshipToHead == relationship) return m;
        }
        return null;
      }

      final father = familyMemberWhere('Father');
      if (father != null) {
        if (father.fullName.trim().isNotEmpty && _fieldByKey('fatherName') != null) {
          _controllerFor('fatherName').text = father.fullName;
        }
        if (father.occupation.trim().isNotEmpty && _fieldByKey('fatherOccupation') != null) {
          _controllerFor('fatherOccupation').text = father.occupation;
        }
      }
      final mother = familyMemberWhere('Mother');
      if (mother != null) {
        if (mother.fullName.trim().isNotEmpty && _fieldByKey('motherName') != null) {
          _controllerFor('motherName').text = mother.fullName;
        }
        if (mother.occupation.trim().isNotEmpty && _fieldByKey('motherOccupation') != null) {
          _controllerFor('motherOccupation').text = mother.occupation;
        }
      }

      // Emergency Contact — sourced from Family Information's own Emergency
      // Contact fields (see ResidentProfile.emergencyContactName/Number and
      // the targeted Family Information Emergency Contact editing pass),
      // reused by any service form that asks for one under these exact
      // shared field-key names (e.g. Pet Registration, Solo Parent Cash
      // Assistance) — same "single source of truth" treatment as
      // Father/Mother above, so this never needs a separate
      // service-specific demoDefault.
      final emergencyContactPrefills = <String, String>{
        'emergencyContactName': profile.emergencyContactName,
        'emergencyContactNumber': PhMobile.normalise(profile.emergencyContactNumber),
      };
      for (final entry in emergencyContactPrefills.entries) {
        if (entry.value.trim().isEmpty) continue;
        if (_fieldByKey(entry.key) == null) continue;
        _controllerFor(entry.key).text = entry.value;
      }

      // Service-specific demo answers (see mock_catalog.dart's own
      // CatalogItem.demoDefaults doc comment) — realistic starting values
      // for fields no Master Profile mechanism above already covers (e.g.
      // Purpose selects, business details, confirmation checkboxes), so
      // the primary demo resident's forms open ready for a live
      // presentation instead of blank. Every field this touches remains a
      // normal, editable value — nothing here locks or validates
      // differently. Gated to Perlita specifically (the account these
      // values were written for), not every verified resident.
      if (account.id == _verifiedDemoAccountId) {
        for (final entry in widget.item.demoDefaults.entries) {
          final field = _fieldByKey(entry.key);
          if (field == null) continue;
          switch (field.type) {
            case ServiceFieldType.text:
            case ServiceFieldType.textarea:
            case ServiceFieldType.number:
            case ServiceFieldType.phone:
              if (_controllerFor(entry.key).text.isEmpty) {
                _controllerFor(entry.key).text = entry.value as String;
              }
            case ServiceFieldType.date:
              // demoDefaults stores dates as an ISO string, not a DateTime
              // literal — CatalogItem.demoDefaults must stay a const map
              // (documentTypes/assistanceTypes are const lists) and
              // DateTime has no const constructor.
              _values.putIfAbsent(entry.key, () => DateTime.parse(entry.value as String));
            case ServiceFieldType.select:
              // Guards the same class of crash as the Master-Profile
              // select prefill above — a demoDefault authored for one
              // version of a field's option list must never be trusted
              // blindly if that list changes later, since
              // DropdownButtonFormField crashes outright on an unmatched
              // value.
              if (field.options?.contains(entry.value) ?? false) {
                _values.putIfAbsent(entry.key, () => entry.value);
              }
            case ServiceFieldType.multiselect:
            case ServiceFieldType.checkbox:
              _values.putIfAbsent(entry.key, () => entry.value);
            case ServiceFieldType.derivedAge:
            case ServiceFieldType.table:
              break; // never independently set — always derived
          }
        }
        if (widget.item.demoPurpose != null && _notesController.text.isEmpty) {
          _notesController.text = widget.item.demoPurpose!;
        }
      }
    }
  }

  /// Each question's starting answer, then the resident's own details for the
  /// questions that ask them again (the website's profileDefaults: name, age,
  /// purok, address, birthdate, civil status, sex, occupation). Only blank
  /// answers are filled, and every one stays editable: a request can be for
  /// someone else.
  void _applyServerDefaults(CitizenAccount? account) {
    final fields = [for (final s in _serviceSteps) ...s.fields];
    for (final f in fields) {
      final d = f.defaultValue;
      if (d == null) continue;
      switch (f.type) {
        case ServiceFieldType.text:
        case ServiceFieldType.textarea:
        case ServiceFieldType.number:
        case ServiceFieldType.phone:
          _controllerFor(f.key).text = d;
        case ServiceFieldType.select:
          if (f.options?.contains(d) ?? false) _values[f.key] = d;
        case ServiceFieldType.date:
          final parsed = DateTime.tryParse(d);
          if (parsed != null) _values[f.key] = parsed;
        case ServiceFieldType.multiselect:
        case ServiceFieldType.checkbox:
        case ServiceFieldType.derivedAge:
        case ServiceFieldType.table:
          break;
      }
    }
    if (account == null) return;
    final birthdate = DateTime.tryParse(account.birthdate);
    final byKey = <String, Object?>{
      'requester_name': account.fullName.trim(),
      'applicant_name': account.fullName.trim(),
      'full_name': account.fullName.trim(),
      'subject_name': account.fullName.trim(),
      'age': birthdate == null ? null : calculateAge(birthdate),
      'purok': account.purok,
      'address': account.address,
      'date_of_birth': birthdate,
      'civil_status': account.civilStatus,
      'sex': account.sex,
      'occupation': account.occupation,
    };
    for (final f in fields) {
      final value = byKey[f.key];
      if (value == null || (value is String && value.trim().isEmpty)) continue;
      switch (f.type) {
        case ServiceFieldType.text:
        case ServiceFieldType.number:
          final c = _controllerFor(f.key);
          if (c.text.trim().isEmpty) {
            c.text = value is DateTime ? _dateOnly(value)! : '$value';
          }
        case ServiceFieldType.date:
          if (_values[f.key] == null && value is DateTime) _values[f.key] = value;
        case ServiceFieldType.select:
          if (_values[f.key] == null && (f.options?.contains('$value') ?? false)) _values[f.key] = '$value';
        default:
          break;
      }
    }
  }

  /// A fee amount the details already ask for is not asked again: the
  /// Business Permit took the capital twice, and the two answers could
  /// disagree (live test 2026-10-07, UX-10).
  static const _feeInputFromField = {
    'declared_capital': ['capitalAmount', 'capital_investment'],
  };

  /// The detail field a fee amount comes from, or null when the Fee step asks.
  String? _feeSource(String name) {
    for (final key in _feeInputFromField[name] ?? const <String>[]) {
      if (_fieldByKey(key) != null) return key;
    }
    return null;
  }

  /// The wizard step that asks [key], or null.
  int? _stepOfField(String? key) {
    if (key == null) return null;
    for (var i = 0; i < _serviceSteps.length; i++) {
      if (_serviceSteps[i].fields.any((f) => f.key == key)) return i + 1;
    }
    return null;
  }

  List<String> get _feeAsked => widget.item.feeInputs.where((n) => _feeSource(n) == null).toList();

  num? _feeValue(String name) {
    final source = _feeSource(name);
    return FeeInputs.parse(source != null ? (_controllers[source]?.text ?? '') : (_feeControllers[name]?.text ?? ''));
  }

  ServiceFormField? _fieldByKey(String key) {
    for (final s in _serviceSteps) {
      for (final f in s.fields) {
        if (f.key == key) return f;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _address.dispose();
    _contact.dispose();
    _email.dispose();
    _notesController.dispose();
    for (final c in [..._controllers.values, ..._feeControllers.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String key) => _controllers.putIfAbsent(key, () => TextEditingController());

  void _next() {
    final err = _validateStep(_step);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      if (_step < _lastStep) _step++;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _error = null;
      _step--;
    });
  }

  String? _validateStep(int step) {
    if (step == 0) {
      if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
        return 'Please enter your first and last name.';
      }
      return PhMobile.validate(_contact.text);
    }
    if (step >= 1 && step <= _serviceSteps.length) {
      final s = _serviceSteps[step - 1];
      for (final f in s.fields) {
        if (!_isFieldVisible(f)) continue;
        if (f.required && _isFieldEmpty(f)) return 'Please complete "${f.label}".';
        if (f.type == ServiceFieldType.number) {
          final t = _controllers[f.key]?.text.trim() ?? '';
          if (t.isNotEmpty && FeeInputs.parse(t) == null) return '${f.label}: numbers only.';
          if (widget.item.feeInputs.any((n) => _feeSource(n) == f.key) && FeeInputs.parse(t) == null) {
            return '${f.label}: enter the amount; the fee is computed from it.';
          }
        }
        if (f.type == ServiceFieldType.phone) {
          final err = PhMobile.validate(_controllers[f.key]?.text ?? '', required: f.required);
          if (err != null) return '${f.label}: $err';
        }
      }
      return null;
    }
    if (step == _requirementsStep) {
      // A Service Catalog form asks its own questions and no purpose box, as
      // on the website.
      if (!_fromServer && !_hasPurposeField && _notesController.text.trim().isEmpty) {
        return 'Please describe the purpose of this request.';
      }
      return FeeInputs.validate(_feeAsked, _feeControllers);
    }
    return null; // review step
  }

  /// Computes an [ServiceFieldType.derivedAge] field's value from its
  /// paired birthdate field — the only source of truth for age anywhere in
  /// this wizard; nothing lets a citizen type an age independently.
  int? _computeAge(String derivedFromKey) {
    final dob = _values[derivedFromKey] as DateTime?;
    return dob == null ? null : calculateAge(dob);
  }

  bool _isFieldEmpty(ServiceFormField f) {
    switch (f.type) {
      case ServiceFieldType.text:
      case ServiceFieldType.textarea:
      case ServiceFieldType.number:
      case ServiceFieldType.phone:
        return _controllers[f.key]?.text.trim().isEmpty ?? true;
      case ServiceFieldType.date:
        return _values[f.key] == null;
      case ServiceFieldType.select:
        return _values[f.key] == null;
      case ServiceFieldType.multiselect:
        final v = _values[f.key];
        return v == null || (v as Set<String>).isEmpty;
      case ServiceFieldType.checkbox:
        return _values[f.key] != true;
      case ServiceFieldType.derivedAge:
        return _computeAge(f.derivedFromKey!) == null;
      case ServiceFieldType.table:
        return _tableRows(f.key).isEmpty;
    }
  }

  String _displayValue(ServiceFormField f) {
    switch (f.type) {
      case ServiceFieldType.text:
      case ServiceFieldType.textarea:
      case ServiceFieldType.number:
      case ServiceFieldType.phone:
        final t = _controllers[f.key]?.text.trim() ?? '';
        return t.isEmpty ? '—' : t;
      case ServiceFieldType.date:
        final v = _values[f.key] as DateTime?;
        return v == null ? '—' : DateFormat('MMM d, y').format(v);
      case ServiceFieldType.select:
        return (_values[f.key] as String?) ?? '—';
      case ServiceFieldType.multiselect:
        final v = _multiselectAnswer(f);
        return (v == null || v.isEmpty) ? '—' : v.join(', ');
      case ServiceFieldType.checkbox:
        return (_values[f.key] == true) ? 'Yes' : 'No';
      case ServiceFieldType.derivedAge:
        final a = _computeAge(f.derivedFromKey!);
        return a == null ? '—' : '$a years old';
      case ServiceFieldType.table:
        final rows = _tableRows(f.key);
        return rows.isEmpty ? '—' : '${rows.length} added';
    }
  }

  /// A multiselect's choices, "Others" carrying what the resident typed
  /// ("Others: ..."), as the website sends it.
  List<String>? _multiselectAnswer(ServiceFormField f) {
    final chosen = (_values[f.key] as Set<String>?)?.toList();
    if (chosen == null) return null;
    final other = _controllers[_otherKey(f.key)]?.text.trim() ?? '';
    if (!f.allowOther || other.isEmpty) return chosen;
    final others = RegExp('^others', caseSensitive: false);
    return [for (final o in chosen) others.hasMatch(o) ? 'Others: $other' : o];
  }

  // -- Table questions: one row per person or item. A row is an id; its
  // cells live in [_controllers] (text) and [_values] (choices, dates).
  List<String> _tableRows(String key) => (_values[key] as List<String>?) ?? const [];
  static String _cellKey(String field, String row, String column) => 'cell::$field::$row::$column';
  int _rowSeq = 0;

  void _addTableRow(ServiceFormField f) {
    setState(() => _values[f.key] = [..._tableRows(f.key), 'r${_rowSeq++}']);
  }

  void _removeTableRow(ServiceFormField f, String row) {
    setState(() => _values[f.key] = _tableRows(f.key).where((r) => r != row).toList());
  }

  String _cellText(ServiceFormField f, String row, ServiceTableColumn c) {
    final key = _cellKey(f.key, row, c.key);
    if (c.options != null) return (_values[key] as String?) ?? '';
    if (c.type == 'date') return _dateOnly(_values[key] as DateTime?) ?? '';
    return _controllers[key]?.text.trim() ?? '';
  }

  List<Map<String, String>> _tableAnswer(ServiceFormField f) => [
    for (final row in _tableRows(f.key)) {for (final c in f.columns!) c.key: _cellText(f, row, c)},
  ];

  Map<String, dynamic> _buildFormFields() {
    // The website's names for the applicant block.
    final out = <String, dynamic>{
      'applicant_first_name': _firstName.text.trim(),
      'applicant_last_name': _lastName.text.trim(),
      'applicant_address': _address.text.trim(),
      'applicant_mobile': _contact.text.trim(),
      'applicant_email': _email.text.trim(),
    };
    for (final s in _serviceSteps) {
      for (final f in s.fields) {
        // A field hidden by an earlier answer (the course, for a student
        // who is not in college) is not part of this application.
        if (!_isFieldVisible(f)) continue;
        final dynamic raw = switch (f.type) {
          ServiceFieldType.text ||
          ServiceFieldType.textarea ||
          ServiceFieldType.number ||
          ServiceFieldType.phone => _controllers[f.key]?.text.trim(),
          ServiceFieldType.date => _dateOnly(_values[f.key] as DateTime?),
          ServiceFieldType.select => _values[f.key],
          ServiceFieldType.multiselect => _multiselectAnswer(f) ?? const <String>[],
          ServiceFieldType.checkbox => _values[f.key] == true,
          // Preserved in submission data (some official/backend shapes
          // expect an age value) but always derived, never typed — see the
          // global birthdate/age rule.
          ServiceFieldType.derivedAge => _computeAge(f.derivedFromKey!),
          ServiceFieldType.table => _tableAnswer(f),
        };
        out[f.key] = raw;
      }
    }
    return out;
  }

  /// Writes any master-eligible field the citizen typed fresh in this
  /// request (i.e. the Master Profile didn't already have it — see
  /// [_prefilledFromProfile]) back into their Resident Profile, so the next
  /// applicable request prefills it too instead of asking again. Fields the
  /// profile already answered are never touched here, and request-specific
  /// fields (purpose, reasons, etc.) are never candidates at all — only the
  /// fixed [_masterEligibleKeys] set.
  Future<void> _backfillMasterProfile(ResidentProfileService profileService, String accountId) async {
    final personal = _personal;
    if (personal == null) return;
    var changed = false;
    for (final key in _masterEligibleKeys) {
      if (_prefilledFromProfile.contains(key)) continue;
      final field = _fieldByKey(key);
      if (field == null) continue;
      final value = field.type == ServiceFieldType.text ? _controllers[key]?.text.trim() : _values[key] as String?;
      if (value == null || value.isEmpty) continue;
      switch (key) {
        case 'sex':
          personal.sex = value;
        case 'civilStatus':
          personal.civilStatus = value;
        case 'occupation':
          personal.occupation = value;
        case 'educationalAttainment':
          personal.educationalAttainment = value;
      }
      changed = true;
    }
    if (changed) await profileService.backfillPersonalField(accountId, personal);
  }

  String _resolvePurpose() {
    final notes = _notesController.text.trim();
    if (_hasPurposeField) {
      final v = _values['purpose'] as String?;
      if (v != null && v.isNotEmpty) return notes.isEmpty ? v : '$v — $notes';
    }
    return notes.isEmpty ? widget.item.name : notes;
  }

  Future<void> _submit() async {
    final account = context.read<CitizenSessionService>().account!;
    final requestsService = context.read<RequestsService>();


    setState(() {
      _submitting = true;
      _error = null;
    });

    final profileService = context.read<ResidentProfileService>();
    await _backfillMasterProfile(profileService, account.id);

    final formData = _buildFormFields();
    // This app's own forms carry a purpose box; a Service Catalog form asks
    // its own questions (its purpose among them, where it has one).
    if (!_fromServer) formData['purpose'] = _resolvePurpose();

    try {
      final request = await requestsService.submit(
        serviceKey: widget.item.key,
        formData: formData,
        feeInputs: {
          for (final name in widget.item.feeInputs) name: ?_feeValue(name),
        },
      );
      // Only the files of documents still owed: an answer changed after a
      // file was picked can make one not apply.
      final owed = {for (final r in _requirementInfos) r.label};
      final notUploaded = await requestsService.attachPicked(request, {
        for (final e in _picked.entries)
          if (owed.contains(e.key)) e.key: e.value,
      });

      if (!mounted) return;
      setState(() => _submitting = false);
      if (notUploaded.isNotEmpty) {
        AppDialogs.toast(
          context,
          'Your request was filed, but ${notUploaded.join(', ')} could not be uploaded. Add it from your request.',
          success: false,
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestSubmittedScreen(
            referenceNumber: request.referenceNumber,
            typeName: request.typeName,
            accent: widget.accent,
            requestId: request.id,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.explain();
      });
    }
  }

  /// This form's module colours (see [_WizardAccent]); read directly here,
  /// because this build sits above the [_WizardAccent] it provides.
  _WizardAccent get _accent => _WizardAccent(category: widget.category, child: const SizedBox());

  @override
  Widget build(BuildContext context) {
    return _WizardAccent(
      category: widget.category,
      // The design's form wizard (2026-10): a navy header holding the
      // stepper, the step's form on a glass card, the pill buttons below.
      child: Scaffold(
        appBar: NavyBand.appBar(title: Text(widget.item.name)),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              NavyBand(
                child: OnboardingStepIndicator(
                  currentStep: _step,
                  stepLabels: _stepLabels,
                  accent: _accent.strongOrNull,
                  onDark: true,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: GlassSurface(radius: 28, padding: wizardCardPadding(context), child: _buildStep()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: tr('Back'),
                        variant: AppButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: _submitting ? null : _back,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        label: _step != _lastStep ? 'Continue' : 'Submit Request',
                        icon: _step == _lastStep ? Icons.send_rounded : Icons.arrow_forward_rounded,
                        iconTrailing: _step != _lastStep,
                        fullWidth: true,
                        loading: _submitting,
                        accent: _accent.strongOrNull,
                        onPressed: _step == _lastStep ? _submit : _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_step == 0) return _applicantInfoStep();
    if (_step >= 1 && _step <= _serviceSteps.length) return _serviceFieldStep(_serviceSteps[_step - 1]);
    if (_step == _requirementsStep) return _requirementsAttachmentsStep();
    return _reviewStepWidget();
  }

  Widget _applicantInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: _accent.soft, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _accent.strong, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "We've prefilled this from your Resident Profile. Changes here only apply to this request — to update your saved profile, use Edit Profile.",
                  style: TextStyle(fontSize: AppTextSize.label, color: _accent.deep, height: 1.4),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: _goToEditProfile,
                child: Text(
                  tr('Edit Profile'),
                  style: TextStyle(fontSize: AppTextSize.label, fontWeight: FontWeight.w700, color: _accent.deep),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(label: 'First name', controller: _firstName, required: true),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Last name', controller: _lastName, required: true),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: tr('Address'), controller: _address, icon: Icons.place_outlined),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: tr('Mobile number'),
          controller: _contact,
          keyboardType: TextInputType.phone,
          inputFormatters: PhMobile.inputFormatters,
          icon: Icons.phone_outlined,
          hintText: PhMobile.hint,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Email address',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.mail_outline_rounded,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600),
          ),
        ],
      ],
    );
  }

  Widget _serviceFieldStep(ServiceFormStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSection(
          title: step.label,
          description: step.description,
          children: [for (final f in step.fields.where(_isFieldVisible)) _buildField(f)],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600),
          ),
        ],
      ],
    );
  }

  void _goToEditProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PersonalInformationScreen()));
  }

  Widget _buildField(ServiceFormField f) {
    // Already known on the Master Profile — read-only here, with an
    // explicit escape hatch, rather than a second editable copy that could
    // silently drift from the citizen's actual record. See the class-level
    // Master Profile doc comment.
    if (_prefilledFromProfile.contains(f.key)) {
      return _MasterSourcedField(label: f.label, value: _displayValue(f), onEditProfile: _goToEditProfile);
    }
    switch (f.type) {
      case ServiceFieldType.text:
        return AppTextField(label: f.label, hintText: f.hint, controller: _controllerFor(f.key), required: f.required);
      case ServiceFieldType.number:
        return AppTextField(
          label: f.label,
          hintText: f.hint,
          controller: _controllerFor(f.key),
          keyboardType: TextInputType.number,
          required: f.required,
        );
      case ServiceFieldType.textarea:
        return AppTextField(
          label: f.label,
          hintText: f.hint,
          controller: _controllerFor(f.key),
          maxLines: 4,
          required: f.required,
        );
      case ServiceFieldType.phone:
        return AppTextField(
          label: f.label,
          hintText: f.hint ?? PhMobile.hint,
          controller: _controllerFor(f.key),
          keyboardType: TextInputType.phone,
          inputFormatters: PhMobile.inputFormatters,
          required: f.required,
        );
      case ServiceFieldType.date:
        return AppDateField(
          label: f.label,
          value: _values[f.key] as DateTime?,
          onChanged: (d) => setState(() => _values[f.key] = d),
          lastDate: DateTime.now(),
          required: f.required,
        );
      case ServiceFieldType.select:
        return AppSelectField<String>(
          label: f.label,
          value: _values[f.key] as String?,
          options: f.options!,
          labelBuilder: (o) => o,
          onChanged: (v) => setState(() => _values[f.key] = v),
          hintText: f.hint ?? 'Select ${f.label}',
          required: f.required,
        );
      case ServiceFieldType.multiselect:
        final picker = _MultiSelectField(
          label: f.label,
          options: f.options!,
          selected: (_values[f.key] as Set<String>?) ?? <String>{},
          onChanged: (s) => setState(() => _values[f.key] = s),
        );
        if (!f.allowOther) return picker;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            picker,
            const SizedBox(height: AppSpacing.sm),
            AppTextField(hintText: 'Others (please specify)', controller: _controllerFor(_otherKey(f.key))),
          ],
        );
      case ServiceFieldType.checkbox:
        return _CheckboxField(
          label: f.label,
          value: (_values[f.key] as bool?) ?? false,
          onChanged: (v) => setState(() => _values[f.key] = v),
        );
      case ServiceFieldType.derivedAge:
        // Read-only — rebuilds live whenever the paired date field's
        // setState fires, since both fields live in the same step.
        return _DerivedAgeField(label: f.label, age: _computeAge(f.derivedFromKey!));
      case ServiceFieldType.table:
        return _tableField(f);
    }
  }

  /// A table question: a card per row with every column, a remove button, and
  /// "Add" and the row's name (the website's family members / dependents list).
  Widget _tableField(ServiceFormField f) {
    final rows = _tableRows(f.key);
    final rowLabel = f.rowLabel ?? 'Entry';
    final accent = _WizardAccent.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          f.label + (f.required ? ' *' : ''),
          style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (rows.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'None added yet.',
              textAlign: TextAlign.center,
              style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
            ),
          ),
        for (var i = 0; i < rows.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$rowLabel ${i + 1}',
                        style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w700, color: accent.deep),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove $rowLabel ${i + 1}',
                      onPressed: () => _removeTableRow(f, rows[i]),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate600),
                    ),
                  ],
                ),
                for (final c in f.columns!) ...[const SizedBox(height: AppSpacing.sm), _tableCell(f, rows[i], c)],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _addTableRow(f),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text('Add $rowLabel'),
        ),
      ],
    );
  }

  Widget _tableCell(ServiceFormField f, String row, ServiceTableColumn c) {
    final key = _cellKey(f.key, row, c.key);
    if (c.options != null) {
      return AppSelectField<String>(
        label: c.label,
        value: _values[key] as String?,
        options: c.options!,
        labelBuilder: (o) => o,
        onChanged: (v) => setState(() => _values[key] = v),
        hintText: 'Select',
      );
    }
    if (c.type == 'date') {
      return AppDateField(
        label: c.label,
        value: _values[key] as DateTime?,
        onChanged: (d) => setState(() => _values[key] = d),
        lastDate: DateTime.now(),
      );
    }
    return AppTextField(
      label: c.label,
      controller: _controllerFor(key),
      keyboardType: c.type == 'number' ? TextInputType.number : null,
    );
  }

  Widget _requirementsAttachmentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_fromServer)
          AppTextField(
            label: _hasPurposeField ? 'Additional notes (optional)' : 'Purpose',
            hintText: 'e.g. Employment requirement, medical assistance for hospital bill...',
            controller: _notesController,
            maxLines: 3,
          ),
        if (_feeAsked.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          FeeInputFields(names: _feeAsked, controllers: _feeControllers),
        ],
        if (_requirementInfos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          RequestDocumentsPicker(
            requirements: _requirementInfos,
            picked: _picked,
            onPicked: (e) => setState(() => _picked[e.key] = e.value),
            accent: widget.accent,
            serviceName: widget.item.name,
            category: widget.category,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600),
          ),
        ],
      ],
    );
  }

  /// A date answer as YYYY-MM-DD (live test 2026-10-07, BUG-1): the time
  /// part of toIso8601String() made the staff site show 'Invalid Date'.
  static String? _dateOnly(DateTime? d) => d == null ? null : DateFormat('yyyy-MM-dd').format(d);

  Widget _reviewStepWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Review Your Request'),
          style: TextStyle(fontSize: AppTextSize.card, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Make sure everything looks correct before submitting.',
          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        _reviewRow(
          tr('Name'),
          '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
          onEdit: () => setState(() => _step = 0),
        ),
        _reviewRow(
          tr('Address'),
          _address.text.trim().isEmpty ? '—' : _address.text.trim(),
          onEdit: () => setState(() => _step = 0),
        ),
        _reviewRow(
          'Mobile',
          _contact.text.trim().isEmpty ? '—' : _contact.text.trim(),
          onEdit: () => setState(() => _step = 0),
        ),
        for (int i = 0; i < _serviceSteps.length; i++) ...[
          for (final f in _serviceSteps[i].fields.where(_isFieldVisible))
            // Derived Age never gets its own Edit control — editing it
            // means changing the Date of Birth it's computed from, so only
            // that field's row is tappable. Master-Profile-sourced fields
            // route to "Edit Profile" instead of jumping back a step, same
            // as their read-only rendering in the field step itself.
            _reviewRow(
              f.label,
              _displayValue(f),
              onEdit: f.type == ServiceFieldType.derivedAge
                  ? null
                  : _prefilledFromProfile.contains(f.key)
                  ? _goToEditProfile
                  : () => setState(() => _step = i + 1),
              editLabel: _prefilledFromProfile.contains(f.key) ? 'Edit Profile' : 'Edit',
            ),
        ],
        if (!_fromServer)
          _reviewRow(
            _hasPurposeField ? 'Additional notes' : 'Purpose',
            _notesController.text.trim().isEmpty ? '—' : _notesController.text.trim(),
            onEdit: () => setState(() => _step = _requirementsStep),
          ),
        for (final name in widget.item.feeInputs)
          _reviewRow(
            FeeInputs.label(name),
            pesoText(_feeValue(name)) ?? '—',
            onEdit: () => setState(() => _step = _stepOfField(_feeSource(name)) ?? _requirementsStep),
          ),
        for (final req in _requirementInfos.where((r) => r.requiresUpload))
          _reviewRow(
            req.label,
            _picked[req.label]?.fileName ?? (req.isRequired ? 'Not attached yet — add it later from your request' : 'Not attached'),
            onEdit: () => setState(() => _step = _requirementsStep),
          ),
        if (widget.item.fee != 'Free') _reviewRow(tr('Fee'), widget.item.fee, onEdit: null),
        // How the fee is paid, as the website's Payment step says it.
        const SizedBox(height: AppSpacing.lg),
        PaymentGuidanceCard(item: widget.item, sayWhenFree: widget.category == ServiceCategory.dokyu),
        if (_documentMeta != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Preview',
            style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _documentPreview(),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600),
          ),
        ],
      ],
    );
  }

  /// The document this request is for, as the website previews it on its
  /// Review step: Dokyu documents it draws, filled with the answers so far.
  DocumentMeta? get _documentMeta => widget.category == ServiceCategory.dokyu ? documentMetas[widget.item.key] : null;

  Future<(Map<String, DocumentTemplate>, ({String? captain, String? secretary, String? sealUrl}))>? _documentContext;

  Future<(Map<String, DocumentTemplate>, ({String? captain, String? secretary, String? sealUrl}))> _loadDocumentContext(
    String barangay,
  ) async => (await DocumentTemplatesService.load(), await barangayOfficials(barangay));

  Widget _documentPreview() {
    final barangay = context.read<CitizenSessionService>().account?.barangay ?? '';
    _documentContext ??= _loadDocumentContext(barangay);
    return FutureBuilder(
      future: _documentContext,
      builder: (context, snap) {
        final (templates, officials) =
            snap.data ?? (const <String, DocumentTemplate>{}, (captain: null, secretary: null, sealUrl: null));
        final sheet = buildDocument(
          _documentMeta!,
          _buildFormFields(),
          barangay: barangay,
          punongBarangay: officials.captain,
          barangaySecretary: officials.secretary,
          template: templates[_documentMeta!.key],
        );
        // Tap to open it full screen, where it can be pinched in and out.
        return Semantics(
          button: true,
          hint: 'Opens the document full screen to zoom',
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DocumentFullScreen(sheet: sheet, barangaySealUrl: officials.sealUrl)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DocumentPaper(sheet: sheet, barangaySealUrl: officials.sealUrl),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap to view full screen and pinch to zoom.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reviewRow(String label, String value, {required VoidCallback? onEdit, String editLabel = 'Edit'}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTextSize.body,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Text(
                editLabel,
                style: TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600, color: _accent.strong),
              ),
            ),
        ],
      ),
    );
  }
}

/// Read-only "N years old" display for a [ServiceFieldType.derivedAge]
/// field — never a text box, never independently editable. Rebuilds
/// automatically whenever its paired Date of Birth field changes, since
/// both live in the same `FormSection` and a birthdate edit triggers the
/// whole step's `setState`.
class _DerivedAgeField extends StatelessWidget {
  final String label;
  final int? age;

  const _DerivedAgeField({required this.label, required this.age});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, size: 17, color: AppColors.slate400),
              const SizedBox(width: AppSpacing.sm),
              Text(
                age == null ? 'Select your Date of Birth above first' : '$age years old',
                style: const TextStyle(
                  fontSize: AppTextSize.body,
                  color: AppColors.textBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Read-only display for a field the citizen's Master (Resident) Profile
/// already answers — Sex, Civil Status, Occupation, Educational Attainment,
/// etc. Editing it here would create a second, request-only copy that can
/// silently drift from the citizen's actual record, so it's shown rather
/// than typed; "Edit Profile" is the one place that value can change, and
/// that change then applies to every future request too.
class _MasterSourcedField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEditProfile;

  const _MasterSourcedField({required this.label, required this.value, required this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Expanded, not a bare fixed-size child in a spaceBetween Row —
            // a longer field label (e.g. "Educational attainment", now also
            // reachable here since the Master Profile started answering it
            // — see the Perlita Master Profile Web Admin sync) plus "Edit
            // Profile" together can exceed a narrow phone's width.
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextSize.helper,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onEditProfile,
              child: Text(
                tr('Edit Profile'),
                style: TextStyle(
                  fontSize: AppTextSize.label,
                  fontWeight: FontWeight.w600,
                  color: _WizardAccent.of(context).strong,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.slate400),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTextSize.body,
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MultiSelectField extends StatelessWidget {
  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _MultiSelectField({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o, style: const TextStyle(fontSize: AppTextSize.label)),
                selected: selected.contains(o),
                onSelected: (v) {
                  final next = Set<String>.from(selected);
                  if (v) {
                    next.add(o);
                  } else {
                    next.remove(o);
                  }
                  onChanged(next);
                },
                selectedColor: _WizardAccent.of(context).chip,
                backgroundColor: AppColors.slate100,
                checkmarkColor: _WizardAccent.of(context).deep,
                labelStyle: TextStyle(
                  color: selected.contains(o) ? _WizardAccent.of(context).deep : AppColors.slate600,
                  fontWeight: selected.contains(o) ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }
}

class _CheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckboxField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: _WizardAccent.of(context).check,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.slate700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The form's module colours, shared with the field widgets below. Tulong is
/// purple everywhere else in the app (its tab, cards, request list and
/// confirmation), but this form drew its step bar, buttons, notes and links
/// in Dokyu's blue. Dokyu keeps exactly the blues it had.
class _WizardAccent extends InheritedWidget {
  const _WizardAccent({required this.category, required super.child});

  final ServiceCategory category;

  bool get _tulong => category == ServiceCategory.tulong;

  /// Null for Dokyu, so shared widgets fall back to their own brand blues.
  Color? get strongOrNull => _tulong ? AppColors.purple700 : null;
  Color get strong => _tulong ? AppColors.purple700 : AppColors.brand600;
  Color get deep => _tulong ? AppColors.purple700 : AppColors.brand700;
  Color get soft => _tulong ? AppColors.purple50 : AppColors.brand50;
  Color get check => _tulong ? AppColors.purple700 : AppColors.brand500;
  Color get chip => _tulong ? AppColors.purple50 : AppColors.brand100;

  static _WizardAccent of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WizardAccent>() ??
      const _WizardAccent(category: ServiceCategory.dokyu, child: SizedBox());

  @override
  bool updateShouldNotify(_WizardAccent old) => old.category != category;
}
