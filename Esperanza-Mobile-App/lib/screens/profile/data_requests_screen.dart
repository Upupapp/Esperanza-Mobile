import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/account_privacy_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_status.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_chip.dart';

/// My data requests: a citizen's rights under the Data Privacy Act (see, correct,
/// delete, or take a copy of their personal data), against
/// GET/POST /citizen/data-requests. Each request gets a reference and moves
/// through the canonical statuses as the Municipality handles it.
class DataRequestsScreen extends StatefulWidget {
  const DataRequestsScreen({super.key});

  @override
  State<DataRequestsScreen> createState() => _DataRequestsScreenState();
}

class _DataRequestsScreenState extends State<DataRequestsScreen> {
  final _detail = TextEditingController();
  String? _kind;
  bool _submitting = false;
  String? _formError;

  List<DataRequest>? _requests;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final rows = await AccountPrivacyService.dataRequests();
      if (mounted) setState(() => _requests = rows);
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message());
    }
  }

  Future<void> _submit() async {
    final detail = _detail.text.trim();
    if (_kind == null || detail.isEmpty) {
      setState(() => _formError = 'Choose what you are asking for and tell us a little about it.');
      return;
    }
    if (detail.length > AccountPrivacyService.detailMaxLength) {
      setState(() => _formError = 'Please keep the details under ${AccountPrivacyService.detailMaxLength} characters.');
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final filed = await AccountPrivacyService.fileDataRequest(kind: _kind!, detail: detail);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _kind = null;
        _detail.clear();
        _requests = [filed, ...?_requests];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ${filed.ref} received. The Municipality will contact you about it.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Data Requests')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenGutter,
            AppSpacing.lg,
            AppSpacing.screenGutter,
            AppSpacing.scrollEnd,
          ),
          children: [
            const Text(
              'Under the Data Privacy Act you can ask the Municipality to show, correct, delete or give you a copy '
              'of the personal information it holds about you.',
              style: AppTypography.helper,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(child: _form()),
            const SizedBox(height: AppSpacing.sectionGap),
            const Text('Your requests', style: AppTypography.cardHeading),
            const SizedBox(height: AppSpacing.headingGap),
            ..._history(),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Make a request', style: AppTypography.cardHeading),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<String>(
          groupValue: _kind,
          onChanged: (v) => setState(() => _kind = v),
          child: Column(
            children: [
              for (final k in AccountPrivacyService.kinds)
                RadioListTile<String>(
                  value: k.key,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.brand500,
                  title: Text(
                    k.title,
                    style: const TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(k.description, style: AppTypography.helper),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTextField(
          label: 'Details',
          hintText: 'e.g. My birthdate in the resident record is wrong; it should be 15 March 2001.',
          controller: _detail,
          maxLines: 4,
        ),
        if (_formError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_formError!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: 'Send Request',
          icon: Icons.send_rounded,
          fullWidth: true,
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }

  List<Widget> _history() {
    final requests = _requests;
    if (requests == null && _loadError == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (requests == null) {
      return [
        Text(_loadError!, style: AppTypography.helper.copyWith(color: AppColors.danger)),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(onPressed: _load, child: const Text('Try Again')),
        ),
      ];
    }
    if (requests.isEmpty) {
      return const [Text('You have not made a data request yet.', style: AppTypography.helper)];
    }
    return [
      for (final r in requests) ...[_RequestCard(request: r), const SizedBox(height: AppSpacing.itemGap)],
    ];
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final DataRequest request;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(AccountPrivacyService.kindTitle(request.kind), style: AppTypography.cardHeading)),
              const SizedBox(width: AppSpacing.sm),
              StatusChip(status: AppStatusX.fromLabel(request.status), small: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [request.ref, if (request.submittedAt != null) date.format(request.submittedAt!.toLocal())].join(' · '),
            style: AppTypography.helper,
          ),
          if (request.detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(request.detail, style: AppTypography.bodyText),
          ],
          if (request.resolution != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Response: ${request.resolution}', style: AppTypography.bodyText),
          ],
        ],
      ),
    );
  }
}
