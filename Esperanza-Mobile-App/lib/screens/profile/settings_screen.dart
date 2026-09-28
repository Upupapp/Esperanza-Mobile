import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/notification_preferences_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_version.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';
import '../../theme/app_typography.dart';

/// Basic account preferences. Kept intentionally small — matches what a
/// citizen actually needs, not a copy of the Web Admin's admin-facing
/// Settings module (General/Branding/Audit Logs are admin-only concerns
/// and must never appear on mobile, per Section 6 of the alignment doc).
///
/// Notifications are the citizen's real preferences on the server
/// (GET/PUT /citizen/notification-preferences). This screen used to show a
/// Push and an Email switch and a Filipino/English choice that were plain
/// widget state: none of them was sent anywhere or read by anything, and all
/// three reset every time the screen opened. The app has no push service and
/// no translations, so those controls are gone rather than faked.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<NotificationPreference>? _preferences;
  String? _loadError;
  final Set<String> _saving = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final preferences = await NotificationPreferencesService.fetch();
      if (mounted) setState(() => _preferences = preferences);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message());
    }
  }

  Future<void> _change(NotificationPreference updated) async {
    final before = _preferences!;
    setState(() {
      _saving.add(updated.category);
      _preferences = [for (final p in before) p.category == updated.category ? updated : p];
    });
    try {
      final stored = await NotificationPreferencesService.save(updated);
      if (!mounted) return;
      setState(() {
        if (stored.isNotEmpty) _preferences = stored;
        _saving.remove(updated.category);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _preferences = before;
        _saving.remove(updated.category);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxxl),
        children: [
          const _SectionLabel('Notifications'),
          const Padding(
            padding: EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.xs, bottom: AppSpacing.md),
            child: Text(
              'Updates always appear in the app. Choose which ones also reach you by text message or email. '
              'Texts go only to a verified mobile number, and emails only to a verified email address.',
              style: AppTypography.helper,
            ),
          ),
          AppCard(padding: EdgeInsets.zero, child: _preferencesBody()),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('About'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Esperanza Mobile',
                  style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Version $appVersion',
                  style: TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Municipality of Esperanza, Masbate — Region V (Bicol Region)',
                  style: TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferencesBody() {
    final preferences = _preferences;
    if (preferences == null && _loadError == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (preferences == null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_loadError!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: _load, child: const Text('Try Again')),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < preferences.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          _PreferenceRow(
            preference: preferences[i],
            saving: _saving.contains(preferences[i].category),
            onChanged: _change,
          ),
        ],
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({required this.preference, required this.saving, required this.onChanged});

  final NotificationPreference preference;
  final bool saving;
  final ValueChanged<NotificationPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preference.labelEn,
            style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _ChannelChip(
                label: 'Text (SMS)',
                selected: preference.sms,
                onSelected: saving ? null : (v) => onChanged(preference.copyWith(sms: v)),
              ),
              _ChannelChip(
                label: 'Email',
                selected: preference.email,
                onSelected: saving ? null : (v) => onChanged(preference.copyWith(email: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({required this.label, required this.selected, required this.onSelected});

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      checkmarkColor: AppColors.brand600,
      selectedColor: AppColors.brand50,
      labelStyle: TextStyle(
        fontSize: AppTextSize.helper,
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.brand700 : AppColors.slate600,
      ),
      side: BorderSide(color: selected ? AppColors.brand200 : AppColors.slate200),
      // Chips draw at 32pt; the padded tap target keeps them at 48.
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: AppTextSize.fine,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
