import 'service_form_spec.dart';
import '../services/json_read.dart';

/// A selectable document type (Dokyu) or assistance program (Tulong).
///
/// Core fields (key/name/office/fee/days/requirements/process) come from
/// the real backend, GET /services and GET /services/{key}
/// (CatalogController::serialize()) -- previously a hardcoded copy of the
/// Web Admin's own inline fixtures (production-readiness programme,
/// 2026-09-25).
///
/// The form's questions are the server's too, since 2026-10-22: staff edit
/// them in the Service Catalog (`fields`, published with the service's
/// version) and the website asks exactly those, so the app does as well
/// ([ServiceFormSpec.fromServerFields]). Only a service with no published version
/// keeps the questions written into this app.
class CatalogItem {
  final String key;
  final String name;
  final String office;

  /// Human-readable amount/rule, e.g. "Free", "₱50.00", "₱500.00 and up
  /// (based on capital)" -- flattened from the server's `fee.display`.
  final String fee;

  /// The server's `fee.required_inputs`: the declared amounts this fee is
  /// assessed on (`declared_capital`, `income`, ...). Both request screens
  /// ask for each one; the server refuses a filing without them. See
  /// utils/fee_inputs.dart.
  final List<String> feeInputs;

  final String days;
  final List<String> requirements;
  final List<String> process;

  /// 'dokyu' or 'tulong' -- the server's own `type`, real, needed to route
  /// `GET /services?type=` and no longer inferred from which fixture list an
  /// item happened to live in.
  final String type;

  /// True when the server has flagged this service's own configuration as
  /// incomplete (e.g. Business Permit's fee schedule has no LGU bracket
  /// ordinance loaded yet) -- "a declared gap is shipped and flagged, never
  /// guessed at" is the backend's own stated policy for this field. The
  /// wizard must show this rather than let a citizen submit against an
  /// assessment that can't actually be completed.
  final bool policyBlocked;
  final String? policyGapNote;

  final String? amount; // Tulong only, mobile-only, no server field
  final String? icon; // lucide-style icon name, mapped to Material in UI

  /// Sourced, service-specific citizen-input fields — see
  /// docs/DOKYU_TULONG_FORM_AUDIT.md for where each one came from. Null
  /// means no reliable source was found for this item, so it keeps the
  /// generic Purpose + Attachments request flow instead of invented fields.
  final ServiceFormSpec? formSpec;

  /// Realistic, service-specific demo answers for [formSpec] fields that
  /// aren't already covered by the Resident Master Profile prefill (see
  /// ServiceRequestWizardScreen's own prefill block) — e.g. a select's
  /// option value, a checkbox's bool, free text. Applied only when the
  /// signed-in resident is the primary demo resident (Perlita Quiambao),
  /// so a live client demo opens every form already realistically filled
  /// in rather than blank (see the Mobile <-> Web Admin final alignment
  /// pass). Keyed by [ServiceFormField.key], same as [formSpec] itself.
  /// Empty for a service with no formSpec, or one already fully covered by
  /// Master Profile fields. Still a plain starting value in an editable
  /// field — never locked, and editing it only affects that one
  /// application, exactly like every other prefilled field in this wizard.
  final Map<String, dynamic> demoDefaults;

  /// A realistic default for the Requirements step's own free-text Purpose
  /// / Additional Notes field (see ServiceRequestWizardScreen/
  /// NewRequestScreen), applied under the same "Perlita only" condition as
  /// [demoDefaults]. Null leaves that field blank, as before.
  final String? demoPurpose;

  /// Kept only so mock_catalog.dart's ~1,400 lines of existing `CatalogItem(...)`
  /// literals (still the real source of [formSpec]/[demoDefaults]/[demoPurpose]
  /// lookups by key, see requests_service.dart) keep compiling unchanged.
  /// No longer read anywhere -- RequestDetailScreen's "Reject (Demo)"
  /// simulation control and RequestsService.rejectDemo() were both removed
  /// once request status came from the real backend instead.
  final String? demoRejectionReason;

  const CatalogItem({
    required this.key,
    required this.name,
    required this.office,
    required this.fee,
    required this.days,
    required this.requirements,
    required this.process,
    this.type = '',
    this.feeInputs = const [],
    this.policyBlocked = false,
    this.policyGapNote,
    this.amount,
    this.icon,
    this.formSpec,
    this.demoDefaults = const {},
    this.demoPurpose,
    this.demoRejectionReason,
  });

  factory CatalogItem.fromApi(Map<String, dynamic> json, {ServiceFormSpec? formSpec, Map<String, dynamic> demoDefaults = const {}, String? demoPurpose, String? icon}) {
    final fee = json['fee'];
    String? str(String key) => JsonRead.string(json[key]);
    // A published version's questions are the ones asked (an empty list means
    // the form asks only a purpose); [formSpec] is this app's own fallback.
    final published = json['version'] != null;
    final entitlement = JsonRead.nonEmpty(JsonRead.map(json['form_spec'])?['entitlement']);
    return CatalogItem(
      key: str('key') ?? '',
      name: str('name') ?? '',
      office: str('office') ?? '',
      // A missing fee renders as a dash, never 'Free': on a government fee
      // schedule an absent amount must not read as "costs nothing" (the same
      // ruling the web lane applied to its Service Catalog, web 73b8ea8).
      fee: (fee is Map ? JsonRead.nonEmpty(fee['display']) : JsonRead.nonEmpty(fee)) ?? '—',
      days: str('days') ?? '',
      requirements: JsonRead.list(json['requirements'])
          .map((e) => e is Map ? (JsonRead.string(e['label']) ?? '') : e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      process: JsonRead.strings(json['process']),
      type: str('type') ?? '',
      feeInputs: fee is Map ? JsonRead.strings(fee['required_inputs']) : const [],
      policyBlocked: JsonRead.boolean(json['policy_blocked']) ?? false,
      policyGapNote: JsonRead.nonEmpty(json['policy_gap_note']),
      amount: entitlement,
      formSpec: published ? ServiceFormSpec.fromServerFields(json['fields']) : formSpec,
      demoDefaults: published ? const {} : demoDefaults,
      demoPurpose: published ? null : demoPurpose,
      icon: icon,
    );
  }
}
