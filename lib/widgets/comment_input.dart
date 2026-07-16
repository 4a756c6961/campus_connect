import 'package:flutter/material.dart';

class CommentInput extends StatefulWidget {
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
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_updateHasText);
  }

  @override
  void didUpdateWidget(covariant CommentInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateHasText);
      _hasText = widget.controller.text.trim().isNotEmpty;
      widget.controller.addListener(_updateHasText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateHasText);
    super.dispose();
  }

  void _updateHasText() {
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (hasText == _hasText) return;

    setState(() {
      _hasText = hasText;
    });
  }

  void _handleSend() {
    if (!_hasText || widget.isSending) return;

    FocusScope.of(context).unfocus();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canSend = _hasText && !widget.isSending;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                },
                decoration: InputDecoration(
                  hintText: 'Schreibe einen Kommentar...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            SizedBox(
              width: 48,
              height: 48,
              child:
                  widget.isSending
                      ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton.filled(
                        onPressed: canSend ? _handleSend : null,
                        tooltip: 'Kommentar senden',
                        icon: const Icon(Icons.send_rounded),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
