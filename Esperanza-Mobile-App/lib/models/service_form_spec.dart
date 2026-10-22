/// Data-driven description of a Dokyu/Tulong service's citizen-facing
/// fields, sourced from the real Esperanza forms audited in
/// docs/DOKYU_TULONG_FORM_AUDIT.md. A [CatalogItem] with a non-null
/// [ServiceFormSpec] is rendered through `ServiceRequestWizardScreen`
/// (Applicant Info -> each spec step -> Requirements & Attachments ->
/// Review & Submit) instead of the older single-step `NewRequestScreen`,
/// so the step count/names adapt per service rather than a fixed template.
/// A `null` formSpec means "no reliable citizen-fillable source was found
/// for this pre-existing item" — it keeps using the generic Purpose +
/// Attachments flow rather than inventing fields.
library;

import '../services/json_read.dart';

enum ServiceFieldType {
  text,
  textarea,
  number,

  /// A Philippine mobile number: digits only, 11 of them (utils/ph_mobile.dart).
  phone,
  date,
  select,
  multiselect,
  checkbox,

  /// A read-only "N years old" display computed from another field's
  /// [ServiceFormField.derivedFromKey] (that field must be `date`-typed).
  /// If a source form asks for both Date of Birth and Age, the mobile
  /// field list should use a `date` field plus one of these instead of two
  /// independently-typed values — see docs/DOKYU_TULONG_FORM_AUDIT.md's
  /// global birthdate/age rule. Never independently required/editable.
  derivedAge,

  /// Rows the resident adds, one per person or item (a household's members,
  /// a beneficiary's dependents), each with the same [ServiceFormField.columns].
  table,
}

/// One column of a [ServiceFieldType.table] question.
class ServiceTableColumn {
  final String key;
  final String label;

  /// 'date', 'number' or text; a column with [options] is a choice.
  final String type;
  final List<String>? options;

  const ServiceTableColumn({required this.key, required this.label, this.type = 'text', this.options});
}

class ServiceFormField {
  final String key;
  final String label;
  final ServiceFieldType type;
  final bool required;
  final String? hint;
  final List<String>? options; // select / multiselect

  /// For [ServiceFieldType.derivedAge] only — the key of the `date` field
  /// this age is computed from.
  final String? derivedFromKey;

  /// Optional conditional-visibility gate — when set, this field is only
  /// shown (and only enforced if [required]) while the field keyed
  /// [visibleWhenKey] currently holds one of [visibleWhenValueIn]. Null
  /// (the default, and every pre-existing field's behavior) means always
  /// visible. Kept deliberately minimal — a single-field value-in-list
  /// check, not a general expression engine — since that's the only shape
  /// any sourced form has actually needed so far (e.g. a "specify if
  /// multiple delivery" field that only applies when Type of Delivery
  /// isn't Single).
  final String? visibleWhenKey;
  final List<String>? visibleWhenValueIn;

  /// The server's own condition (`showIf: {field, contains}`): shown while
  /// the answer to [visibleWhenKey] contains this text, as on the website.
  final String? visibleWhenContains;

  /// A multiselect that also takes "Others (please specify)".
  final bool allowOther;

  /// The answer the form starts with.
  final String? defaultValue;

  /// For [ServiceFieldType.table] only.
  final List<ServiceTableColumn>? columns;
  final String? rowLabel;

  const ServiceFormField({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.hint,
    this.options,
    this.derivedFromKey,
    this.visibleWhenKey,
    this.visibleWhenValueIn,
    this.visibleWhenContains,
    this.allowOther = false,
    this.defaultValue,
    this.columns,
    this.rowLabel,
  });
}

class ServiceFormStep {
  final String label;
  final String? description;
  final List<ServiceFormField> fields;

  const ServiceFormStep({required this.label, this.description, required this.fields});
}

class ServiceFormSpec {
  final List<ServiceFormStep> steps;

  /// True when the questions are the ones published in the Service Catalog
  /// (GET /services `fields`), the same the website asks.
  final bool fromServer;

  const ServiceFormSpec({required this.steps, this.fromServer = false});

  /// The questions a service's form asks, as staff publish them in the
  /// Service Catalog and the website draws them (esperanza-backend
  /// FormFields; the website's document-requests/assistance-requests
  /// wizards): one "Application Details" step. Null when the service asks
  /// none, so the request takes a purpose instead, as on the website. A
  /// question the app cannot read is skipped, never the whole form.
  static ServiceFormSpec? fromServerFields(Object? raw) {
    final fields = JsonRead.rows(raw, _serverField);
    if (fields.isEmpty) return null;
    return ServiceFormSpec(
      steps: [ServiceFormStep(label: 'Application Details', fields: fields)],
      fromServer: true,
    );
  }

  static ServiceFormField? _serverField(Map<String, dynamic> f) {
    final key = JsonRead.nonEmpty(f['key']);
    final label = JsonRead.nonEmpty(f['label']);
    if (key == null || label == null) return null;
    final options = JsonRead.strings(f['options']);
    final type = switch (JsonRead.nonEmpty(f['type']) ?? 'text') {
      'text' => ServiceFieldType.text,
      'textarea' => ServiceFieldType.textarea,
      'number' => ServiceFieldType.number,
      'date' => ServiceFieldType.date,
      'tel' => ServiceFieldType.phone,
      'select' => ServiceFieldType.select,
      'checkbox-group' || 'multiselect' => ServiceFieldType.multiselect,
      'checkbox' => ServiceFieldType.checkbox,
      'derived_age' => ServiceFieldType.derivedAge,
      'table' => ServiceFieldType.table,
      _ => null,
    };
    if (type == null) return null;
    if ((type == ServiceFieldType.select || type == ServiceFieldType.multiselect) && options.isEmpty) return null;
    final columns = type == ServiceFieldType.table
        ? JsonRead.rows(JsonRead.list(f['columns']), (c) {
            final ck = JsonRead.nonEmpty(c['key']);
            if (ck == null) return null;
            final co = JsonRead.strings(c['options']);
            return ServiceTableColumn(
              key: ck,
              label: JsonRead.nonEmpty(c['label']) ?? ck,
              type: JsonRead.nonEmpty(c['type']) ?? 'text',
              options: co.isEmpty ? null : co,
            );
          })
        : null;
    if (type == ServiceFieldType.table && (columns == null || columns.isEmpty)) return null;
    final derivedFrom = JsonRead.nonEmpty(f['derived_from']) ?? JsonRead.nonEmpty(f['derivedFromKey']);
    if (type == ServiceFieldType.derivedAge && derivedFrom == null) return null;
    final showIf = JsonRead.map(f['showIf']);
    return ServiceFormField(
      key: key,
      label: label,
      type: type,
      // The website asks every question but blocks only on those marked.
      required: type != ServiceFieldType.derivedAge && (JsonRead.boolean(f['required']) ?? false),
      options: options.isEmpty ? null : options,
      derivedFromKey: derivedFrom,
      visibleWhenKey: showIf == null ? null : JsonRead.nonEmpty(showIf['field']),
      visibleWhenContains: showIf == null ? null : JsonRead.string(showIf['contains']),
      allowOther: JsonRead.boolean(f['allowOther']) ?? false,
      defaultValue: JsonRead.nonEmpty(f['default']),
      columns: columns,
      rowLabel: JsonRead.nonEmpty(f['rowLabel']),
    );
  }
}
