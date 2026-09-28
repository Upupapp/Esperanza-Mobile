import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/balita_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/date_text.dart';

/// Bottom sheet for viewing a post's real comments (GET .../comments) and
/// posting a new one (POST .../comments) as the signed-in citizen.
class CommentsSheet extends StatefulWidget {
  final Announcement post;

  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  late Future<List<PostComment>> _future;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = context.read<BalitaService>().loadComments(widget.post);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final balita = context.read<BalitaService>();
      final comment = await balita.addComment(widget.post, text);
      if (!mounted) return;
      setState(() {
        _future = _future.then((list) => [...list, comment]);
        _sending = false;
      });
      _controller.clear();
      FocusScope.of(context).unfocus();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.message();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, AppSpacing.md, 0, 0),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slate200,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Comments',
                style: TextStyle(fontSize: AppTextSize.body, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              Flexible(
                child: FutureBuilder<List<PostComment>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      final err = snapshot.error;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl, horizontal: AppSpacing.xl),
                        child: Text(
                          err is ApiException ? err.message() : 'Could not load comments.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
                        ),
                      );
                    }
                    final comments = snapshot.data ?? const [];
                    if (comments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                        child: Text(
                          'No comments yet. Be the first to comment.',
                          style: TextStyle(fontSize: AppTextSize.helper, color: AppColors.textMuted),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.slate100,
                                child: Text(
                                  c.author.isNotEmpty ? c.author.substring(0, 1).toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: AppTextSize.fine,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate50,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text.rich(
                                        TextSpan(
                                          text: c.author,
                                          style: const TextStyle(
                                            fontSize: AppTextSize.label,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          children: [
                                            // When it was said: the server
                                            // sends it; it was never shown.
                                            if (c.at != null)
                                              TextSpan(
                                                text: '  ·  ${timeAgo(c.at!.toLocal())}',
                                                style: AppTypography.fine.copyWith(color: AppColors.textMuted),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        c.body,
                                        style: const TextStyle(
                                          fontSize: AppTextSize.helper,
                                          color: AppColors.slate700,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: AppTextSize.label, color: AppColors.rose600),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: BalitaService.commentMaxLength,
                        // Counter only near the limit: the pill-shaped box
                        // stays clean for the usual short comment.
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                            maxLength != null && currentLength > maxLength * 0.8
                            ? Text('$currentLength / $maxLength', style: AppTypography.fine)
                            : null,
                        style: const TextStyle(fontSize: AppTextSize.body),
                        decoration: InputDecoration(
                          hintText: 'Write a comment…',
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Material(
                      color: AppColors.brand500,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _send,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        ),
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
}
