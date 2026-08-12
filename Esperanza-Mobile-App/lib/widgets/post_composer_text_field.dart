import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The properly-padded, multiline "What's happening..." composer input
/// used by the Balita post composer. Centralizes `contentPadding` in one
/// place so both the hint and typed text always start with a comfortable
/// inset from every edge — the previous inline `TextField` used
/// `contentPadding: EdgeInsets.zero` directly, which is what put the
/// cursor right against the top-left corner. Fixing `contentPadding` here
/// (rather than padding some wrapper around the field) means the fix
/// applies everywhere this input is used, not just at one call site.
class PostComposerTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool autofocus;

  const PostComposerTextField({
    super.key,
    required this.controller,
    this.hintText = "What's happening in Esperanza?",
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: 3,
      maxLines: 8,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.45),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.45),
        filled: true,
        fillColor: AppColors.slate50,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.brand200, width: 1.5)),
      ),
    );
  }
}
