import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/citizen_session_service.dart';
import '../../services/json_read.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/phone_dial.dart';
import '../../widgets/app_card.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/segmented_tabs.dart';

/// The Government Directory: municipal offices (public GET /directory,
/// CommunicationsController::directory) and barangays (public GET
/// /barangays, CatalogController::barangays), the same two sources the
/// website's citizen/directory.blade.php reads.
///
/// Until 2026-09-28 mobile showed the offices only, dropped each office's
/// position and email, and had no search; the barangay halls (the office a
/// resident deals with most) were missing entirely.
class DirectoryScreen extends StatelessWidget {
  const DirectoryScreen({super.key});

  static Future<List<_Office>> _loadOffices() async {
    final res = await api.get('/directory');
    return JsonRead.rows(res.list, (m) {
      final name = JsonRead.nonEmpty(m['office']) ?? JsonRead.nonEmpty(m['name']);
      if (name == null) return null;
      return _Office(
        name: name,
        head: JsonRead.nonEmpty(m['official_name']),
        position: JsonRead.nonEmpty(m['position']),
        contact: JsonRead.nonEmpty(m['contact']),
        email: JsonRead.nonEmpty(m['email']),
      );
    });
  }

  static Future<List<_Barangay>> _loadBarangays() async {
    final res = await api.get('/barangays');
    final rows = JsonRead.rows(res.list, (m) {
      final name = JsonRead.nonEmpty(m['name']);
      if (name == null) return null;
      return _Barangay(
        name: name,
        captain: JsonRead.nonEmpty(m['punong_barangay']),
        secretary: JsonRead.nonEmpty(m['barangay_secretary']),
        contact: JsonRead.nonEmpty(m['contact']),
      );
    });
    return rows..sort((a, b) => a.name.compareTo(b.name));
  }

  /// The barangays half may fail on its own (null) without taking the
  /// offices with it.
  static Future<_DirectoryData> _load() async {
    final offices = _loadOffices();
    final barangays = _loadBarangays().then<List<_Barangay>?>((b) => b).catchError((Object _) => null);
    return (offices: await offices, barangays: await barangays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Government Directory')),
      body: AsyncStateView<_DirectoryData>(
        loader: _load,
        builder: (context, data, reload) => _DirectoryBody(data: data, reload: reload),
      ),
    );
  }
}

typedef _DirectoryData = ({List<_Office> offices, List<_Barangay>? barangays});

class _Office {
  const _Office({required this.name, this.head, this.position, this.contact, this.email});

  final String name;
  final String? head;
  final String? position;
  final String? contact;
  final String? email;

  bool matches(String q) => [name, head, position].any((s) => s != null && s.toLowerCase().contains(q));
}

class _Barangay {
  const _Barangay({required this.name, this.captain, this.secretary, this.contact});

  final String name;
  final String? captain;
  final String? secretary;
  final String? contact;

  bool matches(String q) => [name, captain].any((s) => s != null && s.toLowerCase().contains(q));
}

class _DirectoryBody extends StatefulWidget {
  const _DirectoryBody({required this.data, required this.reload});

  final _DirectoryData data;
  final VoidCallback reload;

  @override
  State<_DirectoryBody> createState() => _DirectoryBodyState();
}

class _DirectoryBodyState extends State<_DirectoryBody> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final mine = context.watch<CitizenSessionService>().account?.barangay;
    final offices = [
      for (final o in widget.data.offices)
        if (q.isEmpty || o.matches(q)) o,
    ];
    final barangays = widget.data.barangays;
    final shownBarangays = [
      for (final b in barangays ?? const <_Barangay>[])
        if (q.isEmpty || b.matches(q)) b,
    ];
    final myBarangay = q.isEmpty ? shownBarangays.where((b) => b.name == mine).firstOrNull : null;

    return RefreshIndicator(
      onRefresh: () async => widget.reload(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.md,
          AppSpacing.screenGutter,
          AppSpacing.scrollEnd,
        ),
        children: [
          SegmentedTabs(
            labels: const ['Offices', 'Barangays'],
            selectedIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: _tab == 0 ? 'Search offices or officials' : 'Search barangays or captains',
              prefixIcon: const Icon(Icons.search_rounded, size: AppSizes.iconBase),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_tab == 0) ...[
            if (offices.isEmpty)
              _Note(q.isEmpty ? 'No offices listed yet.' : 'No office matches "$_query".')
            else
              for (final o in offices) _OfficeTile(office: o),
          ] else if (barangays == null)
            _Note('Barangays could not be loaded. Pull down to try again.')
          else ...[
            if (myBarangay != null) ...[
              const Text('Your barangay', style: AppTypography.subsectionLabel),
              const SizedBox(height: AppSpacing.sm),
              _BarangayTile(barangay: myBarangay, highlighted: true),
              const SizedBox(height: AppSpacing.md),
              const Text('All barangays', style: AppTypography.subsectionLabel),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (shownBarangays.isEmpty)
              _Note(q.isEmpty ? 'No barangays listed yet.' : 'No barangay matches "$_query".')
            else
              for (final b in shownBarangays)
                if (b != myBarangay) _BarangayTile(barangay: b),
          ],
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
    child: Text(text, textAlign: TextAlign.center, style: AppTypography.helper),
  );
}

class _OfficeTile extends StatelessWidget {
  const _OfficeTile({required this.office});

  final _Office office;

  @override
  Widget build(BuildContext context) {
    final who = [?office.head, ?office.position].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.navy900, borderRadius: BorderRadius.circular(AppRadius.md)),
              child: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    office.name,
                    style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600),
                  ),
                  if (who.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      who,
                      style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            _ContactButtons(label: office.name, contact: office.contact, email: office.email),
          ],
        ),
      ),
    );
  }
}

class _BarangayTile extends StatelessWidget {
  const _BarangayTile({required this.barangay, this.highlighted = false});

  final _Barangay barangay;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final card = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: highlighted ? AppColors.brand500 : AppColors.brand50,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(Icons.holiday_village_outlined, size: 18, color: highlighted ? Colors.white : AppColors.brand600),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brgy. ${barangay.name}',
                style: const TextStyle(fontSize: AppTextSize.helper, fontWeight: FontWeight.w600),
              ),
              if (barangay.captain != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Punong Barangay: ${barangay.captain}',
                  style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                ),
              ],
              if (barangay.secretary != null)
                Text(
                  'Secretary: ${barangay.secretary}',
                  style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.textMuted),
                ),
            ],
          ),
        ),
        _ContactButtons(label: 'Barangay ${barangay.name}', contact: barangay.contact),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: highlighted
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.brand50,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.brand200),
              ),
              child: card,
            )
          : AppCard(child: card),
    );
  }
}

/// Call and email as full 44pt targets. The call button used to be a 16pt
/// icon in an 8pt ring (about 32pt), and email was never offered.
class _ContactButtons extends StatelessWidget {
  const _ContactButtons({required this.label, this.contact, this.email});

  final String label;
  final String? contact;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final call = dialUri(contact);
    final mail = email == null ? null : Uri(scheme: 'mailto', path: email);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mail != null)
          IconButton(
            tooltip: 'Email $label',
            onPressed: () => launchUrl(mail),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.brand50,
              minimumSize: const Size.square(AppSizes.minTouchTarget),
            ),
            icon: const Icon(Icons.mail_outline_rounded, size: AppSizes.iconBase, color: AppColors.brand600),
          ),
        if (mail != null && call != null) const SizedBox(width: AppSpacing.xs),
        if (call != null)
          IconButton(
            tooltip: 'Call $label',
            onPressed: () => launchUrl(call),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.emerald50,
              minimumSize: const Size.square(AppSizes.minTouchTarget),
            ),
            icon: const Icon(Icons.call_outlined, size: AppSizes.iconBase, color: AppColors.emerald700),
          ),
      ],
    );
  }
}
