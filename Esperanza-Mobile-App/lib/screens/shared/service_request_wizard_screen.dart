import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/attachment.dart';
import '../../models/catalog_item.dart';
import '../../models/service_form_spec.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/requests_service.dart';
import '../../services/resident_profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/age_calculator.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_date_field.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/attachment_picker.dart';
import '../../widgets/form_section.dart';
import '../../widgets/onboarding_step_indicator.dart';
import 'request_detail_screen.dart';
import 'request_submitted_screen.dart';

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
  List<ServiceFormStep> get _serviceSteps => widget.item.formSpec!.steps;
  int get _requirementsStep => _serviceSteps.length + 1;
  int get _reviewStep => _serviceSteps.length + 2;
  int get _lastStep => _reviewStep;

  late final List<String> _stepLabels = [
    'Applicant Info',
    for (final s in _serviceSteps) s.label,
    'Requirements',
    'Review & Submit',
  ];

  int _step = 0;
  String? _error;
  bool _submitting = false;

  // Applicant info (step 0) — prefilled from the signed-in account, still
  // editable since a request's details can differ from the base profile
  // (e.g. requesting on behalf of a household matter).
  final _fullName = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _purok = TextEditingController();
  String? _barangay;

  // Service-specific field values, keyed by ServiceFormField.key. Text-like
  // fields are read from `_controllers`; everything else lives here.
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};

  // Requirements & Attachments step.
  final _notesController = TextEditingController();
  final List<Attachment> _attachments = [];

  bool get _hasPurposeField => _serviceSteps.any((s) => s.fields.any((f) => f.key == 'purpose'));

  /// Whether [f] should currently be shown/enforced — see
  /// [ServiceFormField.visibleWhenKey]'s own doc comment. Fields with no
  /// gate are always visible, which is every pre-existing formSpec's
  /// entire field list, so this is a no-op for them.
  bool _isFieldVisible(ServiceFormField f) {
    if (f.visibleWhenKey == null) return true;
    return f.visibleWhenValueIn!.contains(_values[f.visibleWhenKey]);
  }

  @override
  void initState() {
    super.initState();
    final account = context.read<CitizenSessionService>().account;
    if (account != null) {
      _fullName.text = account.fullName;
      _contact.text = account.mobile;
      _email.text = account.email;
      _purok.text = account.purok == '—' ? '' : account.purok;
      _barangay = account.barangay;

      // Prefill Date of Birth from the citizen's existing Resident Profile
      // (already parsed to a real DateTime there) rather than making them
      // re-enter it on every application — see the global birthdate/age
      // rule in docs/DOKYU_TULONG_FORM_AUDIT.md. Only applied to field keys
      // this service actually asks for; 'party1DateOfBirth' covers the
      // Marriage License item, whose first party is assumed to be the
      // applicant.
      final dob = context.read<ResidentProfileService>().profileFor(account).personal.birthdate;
      if (dob != null) {
        for (final key in const ['dateOfBirth', 'party1DateOfBirth']) {
          if (_serviceSteps.any((s) => s.fields.any((f) => f.key == key))) {
            _values[key] = dob;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _contact.dispose();
    _email.dispose();
    _purok.dispose();
    _notesController.dispose();
    for (final c in _controllers.values) {
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
      if (_fullName.text.trim().isEmpty) return 'Please enter your full name.';
      if (_barangay == null) return 'Please select your barangay.';
      return null;
    }
    if (step >= 1 && step <= _serviceSteps.length) {
      final s = _serviceSteps[step - 1];
      for (final f in s.fields) {
        if (!f.required || !_isFieldVisible(f)) continue;
        if (_isFieldEmpty(f)) return 'Please complete "${f.label}".';
      }
      return null;
    }
    if (step == _requirementsStep) {
      if (!_hasPurposeField && _notesController.text.trim().isEmpty) {
        return 'Please describe the purpose of this request.';
      }
      if (_attachments.isEmpty) return 'Please attach at least one requirement document or photo.';
      return null;
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
    }
  }

  String _displayValue(ServiceFormField f) {
    switch (f.type) {
      case ServiceFieldType.text:
      case ServiceFieldType.textarea:
      case ServiceFieldType.number:
        final t = _controllers[f.key]?.text.trim() ?? '';
        return t.isEmpty ? '—' : t;
      case ServiceFieldType.date:
        final v = _values[f.key] as DateTime?;
        return v == null ? '—' : DateFormat('MMM d, y').format(v);
      case ServiceFieldType.select:
        return (_values[f.key] as String?) ?? '—';
      case ServiceFieldType.multiselect:
        final v = _values[f.key] as Set<String>?;
        return (v == null || v.isEmpty) ? '—' : v.join(', ');
      case ServiceFieldType.checkbox:
        return (_values[f.key] == true) ? 'Yes' : 'No';
      case ServiceFieldType.derivedAge:
        final a = _computeAge(f.derivedFromKey!);
        return a == null ? '—' : '$a years old';
    }
  }

  Map<String, dynamic> _buildFormFields() {
    final out = <String, dynamic>{
      'applicantFullName': _fullName.text.trim(),
      'applicantBarangay': _barangay ?? '',
      'applicantPurok': _purok.text.trim(),
      'applicantContact': _contact.text.trim(),
      'applicantEmail': _email.text.trim(),
    };
    for (final s in _serviceSteps) {
      for (final f in s.fields) {
        final dynamic raw = switch (f.type) {
          ServiceFieldType.text ||
          ServiceFieldType.textarea ||
          ServiceFieldType.number => _controllers[f.key]?.text.trim(),
          ServiceFieldType.date => (_values[f.key] as DateTime?)?.toIso8601String(),
          ServiceFieldType.select => _values[f.key],
          ServiceFieldType.multiselect => (_values[f.key] as Set<String>?)?.toList(),
          ServiceFieldType.checkbox => _values[f.key] == true,
          // Preserved in submission data (some official/backend shapes
          // expect an age value) but always derived, never typed — see the
          // global birthdate/age rule.
          ServiceFieldType.derivedAge => _computeAge(f.derivedFromKey!),
        };
        out[f.key] = raw;
      }
    }
    return out;
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
    setState(() {
      _submitting = true;
      _error = null;
    });

    final account = context.read<CitizenSessionService>().account!;
    final requestsService = context.read<RequestsService>();
    await Future.delayed(const Duration(milliseconds: 900)); // simulated network/processing delay

    final request = await requestsService.submit(
      applicantId: account.id,
      applicantName: _fullName.text.trim(),
      typeName: widget.item.name,
      category: widget.category,
      office: widget.item.office,
      purpose: _resolvePurpose(),
      expectedDays: widget.item.days,
      attachments: _attachments,
      formFields: _buildFormFields(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RequestSubmittedScreen(
          referenceNumber: request.referenceNumber,
          typeName: request.typeName,
          accent: widget.accent,
          onViewRequest: () => Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: request.id))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: OnboardingStepIndicator(currentStep: _step, stepLabels: _stepLabels),
            ),
            Expanded(
              child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: _buildStep()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Back',
                      variant: AppButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: _submitting ? null : _back,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: _step == _lastStep ? 'Submit Request' : 'Continue',
                      icon: _step == _lastStep ? Icons.send_rounded : Icons.arrow_forward_rounded,
                      iconTrailing: _step != _lastStep,
                      fullWidth: true,
                      loading: _submitting,
                      onPressed: _step == _lastStep ? _submit : _next,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.brand600, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "We've prefilled this from your account. Update anything that's different for this request.",
                  style: TextStyle(fontSize: 12, color: AppColors.brand700, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(label: 'Full name', controller: _fullName),
        const SizedBox(height: AppSpacing.lg),
        AppSelectField<String>(
          label: 'Barangay',
          value: _barangay,
          options: MockCatalog.barangays,
          labelBuilder: (b) => b,
          onChanged: (v) => setState(() => _barangay = v),
          hintText: 'Select your barangay',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Purok / Sitio', controller: _purok, icon: Icons.place_outlined),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Mobile number',
          controller: _contact,
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
          hintText: '09XX XXX XXXX',
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
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
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
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _buildField(ServiceFormField f) {
    switch (f.type) {
      case ServiceFieldType.text:
        return AppTextField(label: f.label, hintText: f.hint, controller: _controllerFor(f.key));
      case ServiceFieldType.number:
        return AppTextField(
          label: f.label,
          hintText: f.hint,
          controller: _controllerFor(f.key),
          keyboardType: TextInputType.number,
        );
      case ServiceFieldType.textarea:
        return AppTextField(label: f.label, hintText: f.hint, controller: _controllerFor(f.key), maxLines: 4);
      case ServiceFieldType.date:
        return AppDateField(
          label: f.label,
          value: _values[f.key] as DateTime?,
          onChanged: (d) => setState(() => _values[f.key] = d),
          lastDate: DateTime.now(),
        );
      case ServiceFieldType.select:
        return AppSelectField<String>(
          label: f.label,
          value: _values[f.key] as String?,
          options: f.options!,
          labelBuilder: (o) => o,
          onChanged: (v) => setState(() => _values[f.key] = v),
          hintText: f.hint ?? 'Select ${f.label}',
        );
      case ServiceFieldType.multiselect:
        return _MultiSelectField(
          label: f.label,
          options: f.options!,
          selected: (_values[f.key] as Set<String>?) ?? <String>{},
          onChanged: (s) => setState(() => _values[f.key] = s),
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
    }
  }

  Widget _requirementsAttachmentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 16, color: widget.accent),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Requirements', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              ...widget.item.requirements.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.emerald500),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(r, style: const TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.3)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: _hasPurposeField ? 'Additional notes (optional)' : 'Purpose',
          hintText: 'e.g. Employment requirement, medical assistance for hospital bill...',
          controller: _notesController,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text(
          'Attach Requirements',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Take a photo or choose a file for each requirement above.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpacing.md),
        AttachmentPicker(
          documentTypeLabel: widget.item.name,
          attachments: _attachments,
          onAdd: (a) => setState(() => _attachments.add(a)),
          onRemove: (id) => setState(() => _attachments.removeWhere((a) => a.id == id)),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _reviewStepWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Review Your Request',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Make sure everything looks correct before submitting.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.xl),
        _reviewRow('Full name', _fullName.text.trim(), onEdit: () => setState(() => _step = 0)),
        _reviewRow('Barangay', _barangay ?? '—', onEdit: () => setState(() => _step = 0)),
        _reviewRow(
          'Purok / Sitio',
          _purok.text.trim().isEmpty ? '—' : _purok.text.trim(),
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
            // that field's row is tappable.
            _reviewRow(
              f.label,
              _displayValue(f),
              onEdit: f.type == ServiceFieldType.derivedAge ? null : () => setState(() => _step = i + 1),
            ),
        ],
        _reviewRow(
          _hasPurposeField ? 'Additional notes' : 'Purpose',
          _notesController.text.trim().isEmpty ? '—' : _notesController.text.trim(),
          onEdit: () => setState(() => _step = _requirementsStep),
        ),
        _reviewRow(
          'Attachments',
          _attachments.isEmpty ? '—' : '${_attachments.length} file(s)',
          onEdit: () => setState(() => _step = _requirementsStep),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.rose600)),
        ],
      ],
    );
  }

  Widget _reviewRow(String label, String value, {required VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.slate700),
                ),
              ],
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: const Text(
                'Edit',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.brand600),
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, size: 17, color: AppColors.slate400),
              const SizedBox(width: 10),
              Text(
                age == null ? 'Select your Date of Birth above first' : '$age years old',
                style: const TextStyle(fontSize: 14, color: AppColors.textBody, fontWeight: FontWeight.w500),
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.slate700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o, style: const TextStyle(fontSize: 12)),
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
                selectedColor: AppColors.brand100,
                backgroundColor: AppColors.slate100,
                checkmarkColor: AppColors.brand700,
                labelStyle: TextStyle(
                  color: selected.contains(o) ? AppColors.brand700 : AppColors.slate600,
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
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false), activeColor: AppColors.brand500),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.slate700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
