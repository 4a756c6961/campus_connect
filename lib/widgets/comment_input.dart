import 'package:flutter/material.dart';

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const CommentInput({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!isSending) {
                    onSend();
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Schreibe einen Kommentar...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            isSending
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : IconButton(onPressed: onSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
