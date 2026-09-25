import 'service_form_spec.dart';

/// A selectable document type (Dokyu) or assistance program (Tulong).
///
/// Core fields (key/name/office/fee/days/requirements/process) come from
/// the real backend, GET /services and GET /services/{key}
/// (CatalogController::serialize()) -- previously a hardcoded copy of the
/// Web Admin's own inline fixtures (production-readiness programme,
/// 2026-09-25). [formSpec]/[demoDefaults]/[demoPurpose]/[demoRejectionReason]
/// stay locally sourced (see [ServiceFormSpec]'s own doc comment) -- they
/// describe *this wizard's own question set*, audited against the real
/// paper forms in docs/DOKYU_TULONG_FORM_AUDIT.md, not business data the
/// backend has any equivalent shape for; `services.fields`/`form_spec`
/// exist server-side but are unconfirmed to be the same shape and were not
/// assumed to be.
class CatalogItem {
  final String key;
  final String name;
  final String office;

  /// Human-readable amount/rule, e.g. "Free", "₱50.00", "₱500.00 and up
  /// (based on capital)" -- flattened from the server's `fee.display`.
  /// `fee.kind`/`fee.required_inputs` (needed to actually assess a
  /// `per_bracket`/`schedule` fee) aren't surfaced here; the wizard doesn't
  /// collect fee inputs today (see the payment/receipt gap this pass left
  /// alone -- no citizen payment endpoint exists to spend them on).
  final String fee;

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
    return CatalogItem(
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? '',
      office: json['office'] as String? ?? '',
      fee: fee is Map ? (fee['display'] as String? ?? 'Free') : (fee as String? ?? 'Free'),
      days: json['days'] as String? ?? '',
      requirements: (json['requirements'] as List?)?.map((e) => e is Map ? (e['label']?.toString() ?? '') : e.toString()).toList() ?? const [],
      process: (json['process'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      type: json['type'] as String? ?? '',
      policyBlocked: json['policy_blocked'] as bool? ?? false,
      policyGapNote: json['policy_gap_note'] as String?,
      formSpec: formSpec,
      demoDefaults: demoDefaults,
      demoPurpose: demoPurpose,
      icon: icon,
    );
  }
}
