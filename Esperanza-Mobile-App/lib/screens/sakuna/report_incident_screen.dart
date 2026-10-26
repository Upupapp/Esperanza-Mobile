import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/incident_types.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/barangay_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/cross_platform_image.dart';
import '../../utils/protected_action.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../shared/request_submitted_screen.dart';
import '../../theme/app_typography.dart';

import '../../l10n/tr.dart';
/// Report an Incident, against POST /citizen/incidents.
///
/// Incidents used to go through the Dokyu/Tulong flow, which posted
/// `service_key: incident_flood` to POST /citizen/requests -- a key the
/// backend's `services` table has never held, so every report failed
/// validation. Incidents are their own backend resource and are open to
/// unverified citizens, so they get their own short form: an emergency
/// report should take seconds, not a wizard.
///
/// What is happening is chosen on the form itself, from the website's list
/// (lib/models/incident_types.dart): six tiles, the rest under "More kinds".
class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key, this.initialType, required this.accent});

  /// A kind already chosen, if the resident came from one.
  final IncidentType? initialType;
  final Color accent;

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

/// How many photos a report may carry (the backend's own limit).
const maxIncidentPhotos = 3;

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _sitio = TextEditingController();
  final _description = TextEditingController();
  IncidentType? _type;
  String? _severity;
  String? _barangay;
  bool _submitting = false;
  String? _error;

  /// Photos of what is happening, so responders see it before they set out
  /// (scope round 2026-10-15). Optional: a report must never wait on one.
  final List<({Uint8List bytes, String name})> _photos = [];

  /// One id per report, reused on every retry of it: the backend treats a
  /// repeated `client_uuid` as the same incident, so a tap on Submit after a
  /// timeout cannot file the flood twice.
  final String _clientUuid = _uuidV4();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    final home = context.read<CitizenSessionService>().account?.barangay;
    if (home != null && BarangayService.names.contains(home)) _barangay = home;
  }

  @override
  void dispose() {
    _sitio.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    final file = await pickImageProtected(
      context,
      source: source,
      // Big enough to read a water line or a street sign, small enough to
      // upload on a weak signal.
      maxDimension: 1600,
      explanation: source == ImageSource.camera
          ? 'Esperanza needs the camera so you can take a photo of the incident for the responders.'
          : 'Esperanza needs access to your photos so you can attach a photo of the incident for the responders.',
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted || _photos.length >= maxIncidentPhotos) return;
    setState(() => _photos.add((bytes: bytes, name: file.name.isEmpty ? 'incident-photo.jpg' : file.name)));
  }

  Future<void> _submit() async {
    if (_type == null) {
      setState(() => _error = 'Choose what is happening.');
      return;
    }
    if (_severity == null || _barangay == null) {
      setState(() => _error = 'Please choose how serious it is and the barangay where it is happening.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final sitio = _sitio.text.trim();
      final type = _type!.name;
      final incident = await context.read<RequestsService>().reportIncident(
        type: type,
        title: sitio.isEmpty ? '$type — $_barangay' : '$type — $sitio, $_barangay',
        severity: _severity!,
        barangay: _barangay!,
        sitio: sitio,
        description: _description.text,
        clientUuid: _clientUuid,
        photos: [for (final p in _photos) (bytes: p.bytes, filename: p.name)],
      );
      if (!mounted) return;
      final accent = widget.accent;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestSubmittedScreen(
            referenceNumber: incident.referenceNumber,
            typeName: incident.typeName,
            accent: widget.accent,
            requestId: incident.id,
            reportAnother: (_) => ReportIncidentScreen(accent: accent),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Report an Incident'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
          children: [
            Text(
              tr('For life-threatening emergencies, call a hotline first.'),
              style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              tr('What is happening?'),
              style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            _IncidentTypeTiles(selected: _type, onSelected: _submitting ? null : (t) => setState(() => _type = t)),
            const SizedBox(height: AppSpacing.md),
            AppSelectField<IncidentType>(
              label: tr('More kinds'),
              value: moreIncidentTypes.contains(_type) ? _type : null,
              options: moreIncidentTypes,
              labelBuilder: (t) => t.label,
              hintText: tr('Choose if it is not above'),
              onChanged: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              tr('How serious is it?'),
              style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in incidentSeverities)
                  ChoiceChip(
                    label: Text(severityLabel(s)),
                    selected: _severity == s,
                    selectedColor: AppColors.rose50,
                    onSelected: (_) => setState(() => _severity = s),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // The app's own select, label above like every other field on
            // this form (a bare DropdownButtonFormField floated its label
            // inside the box).
            AppSelectField<String>(
              label: 'Barangay',
              value: _barangay,
              options: BarangayService.names,
              labelBuilder: (b) => b,
              hintText: tr('Choose the barangay'),
              onChanged: (v) => setState(() => _barangay = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: tr('Sitio / purok / landmark (optional)'), controller: _sitio),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: tr('What is happening? (optional)'),
              hintText: tr('e.g. Water is knee-deep near the chapel; two families need help moving.'),
              controller: _description,
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.lg),
            _IncidentPhotosField(
              photos: _photos,
              onAdd: _submitting ? null : _addPhoto,
              onRemove: (i) => setState(() => _photos.removeAt(i)),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.rose600),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: tr('Submit Report'),
              icon: Icons.send_rounded,
              variant: AppButtonVariant.danger,
              fullWidth: true,
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// The six kinds most reported, as tiles (the website's grid).
class _IncidentTypeTiles extends StatelessWidget {
  const _IncidentTypeTiles({required this.selected, required this.onSelected});

  final IncidentType? selected;
  final void Function(IncidentType type)? onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in incidentTypes)
              SizedBox(
                width: width,
                child: _IncidentTypeTile(
                  type: type,
                  selected: selected == type,
                  onTap: onSelected == null ? null : () => onSelected!(type),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IncidentTypeTile extends StatelessWidget {
  const _IncidentTypeTile({required this.type, required this.selected, required this.onTap});

  final IncidentType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.rose600 : AppColors.slate600;
    return Semantics(
      button: true,
      selected: selected,
      label: type.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.rose50 : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: selected ? AppColors.rose600 : AppColors.border, width: selected ? 1.5 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(type.icon, size: AppSizes.iconBase, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      type.label,
                      style: TextStyle(
                        fontSize: AppTextSize.helper,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.rose600 : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IncidentPhotosField extends StatelessWidget {
  const _IncidentPhotosField({required this.photos, required this.onAdd, required this.onRemove});

  final List<({Uint8List bytes, String name})> photos;
  final void Function(ImageSource source)? onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final full = photos.length >= maxIncidentPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Photos (optional)'),
          style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Up to $maxIncidentPhotos. A photo helps responders see what is happening. Do not stop to take one if you are in danger.',
          style: AppTypography.captionSmallRegular.copyWith(color: AppColors.textMuted),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < photos.length; i++)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Image(
                        image: pickedFileImageProvider(bytes: photos[i].bytes)!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        semanticLabel: 'Photo ${i + 1} of the incident',
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Material(
                        color: AppColors.surface,
                        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
                        child: IconButton(
                          tooltip: 'Remove photo ${i + 1}',
                          onPressed: () => onRemove(i),
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.slate600),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        if (!full) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onAdd == null ? null : () => onAdd!(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 17),
                label: const Text('Take a photo'),
              ),
              OutlinedButton.icon(
                onPressed: onAdd == null ? null : () => onAdd!(ImageSource.gallery),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
                label: const Text('Choose a photo'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _uuidV4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
