import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_colors.dart';

/// Bottom sheet for viewing a post's comments and adding a local mock
/// comment as the signed-in citizen. Purely local state — appended comments
/// live only in the in-memory [Announcement] passed in from BalitaScreen.
class CommentsSheet extends StatefulWidget {
  final Announcement post;
  final ValueChanged<PostComment> onSubmit;

  const CommentsSheet({super.key, required this.post, required this.onSubmit});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  late final List<PostComment> _comments = List.of(widget.post.comments);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final account = context.read<CitizenSessionService>().account;
    final comment = PostComment(author: account?.fullName ?? 'You', body: text);
    setState(() => _comments.add(comment));
    widget.onSubmit(comment);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.slate200, borderRadius: BorderRadius.circular(999)),
              ),
              const SizedBox(height: 14),
              const Text('Comments', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              const Divider(height: 1),
              Flexible(
                child: _comments.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No comments yet. Be the first to comment.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, i) {
                          final c = _comments[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 15,
                                  backgroundColor: AppColors.slate100,
                                  child: Text(
                                    c.author.isNotEmpty ? c.author.substring(0, 1).toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate600),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(14)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.author, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(c.body, style: const TextStyle(fontSize: 12.5, color: AppColors.slate700, height: 1.35)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Write a comment…',
                          filled: true,
                          fillColor: AppColors.slate50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.brand500,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _send,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send_rounded, size: 18, color: Colors.white),
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
