import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/providers/feed_provider.dart';
import 'package:campus_connect/widgets/tag_action_chips.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String text;
  final String userId;
  final String authorName;
  final String photoUrl;
  final String formattedDate;
  final int likeCount;
  final int commentCount;
  final bool hasLiked;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final VoidCallback? onAuthorTap;
  final DateTime? editedAt;
  final String gifUrl;
  final String gifTitle;
  final List<String> tags;
  final ValueChanged<String>? onTagTap;

  const PostCard({
    super.key,
    required this.postId,
    required this.text,
    required this.userId,
    required this.authorName,
    required this.photoUrl,
    required this.formattedDate,
    required this.likeCount,
    required this.commentCount,
    required this.hasLiked,
    required this.onToggleLike,
    required this.onOpenComments,
    this.onAuthorTap,
    this.editedAt,
    required this.gifUrl,
    required this.gifTitle,
    this.onTagTap,
    this.tags = const [],
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == userId;

    final hasPhoto = photoUrl.trim().isNotEmpty;

    final initial =
        authorName.trim().isNotEmpty
            ? authorName.trim().characters.first.toUpperCase()
            : '?';

    final visibleTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAuthorTap,
                  child: CircleAvatar(
                    backgroundImage:
                        hasPhoto ? NetworkImage(photoUrl.trim()) : null,
                    child: hasPhoto ? null : Text(initial),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onAuthorTap,
                        child: Text(
                          authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                if (isOwner)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showEditDialog(context);
                      } else if (value == 'delete') {
                        await _showDeleteDialog(context);
                      }
                    },
                    itemBuilder:
                        (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Beitrag bearbeiten'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Beitrag löschen'),
                          ),
                        ],
                  ),
              ],
            ),

            const SizedBox(height: 8),

            if (text.trim().isNotEmpty) Text(text),

            if (visibleTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              TagActionChips(
                tags: visibleTags,
                onTagTap: (tag) {
                  onTagTap?.call(tag);
                },
              ),
            ],

            if (gifUrl.trim().isNotEmpty) ...[
              if (text.trim().isNotEmpty || visibleTags.isNotEmpty)
                const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  gifUrl.trim(),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  semanticLabel:
                      gifTitle.trim().isNotEmpty
                          ? gifTitle.trim()
                          : 'GIPHY GIF',
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('GIF konnte nicht geladen werden.'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Powered by GIPHY',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],

            if (editedAt != null) ...[
              const SizedBox(height: 6),
              const Text(
                '(bearbeitet)',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                _AnimatedLikeButton(
                  hasLiked: hasLiked,
                  onPressed: onToggleLike,
                ),
                Text('$likeCount'),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: onOpenComments,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                Text('$commentCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext parentContext) async {
    final controller = TextEditingController(text: text);
    bool saving = false;

    await showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return AlertDialog(
              title: const Text('Beitrag bearbeiten'),
              content: TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Beitrag bearbeiten...',
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed:
                      saving
                          ? null
                          : () async {
                            final newText = controller.text.trim();

                            if (newText.isEmpty) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Der Beitrag darf nicht leer sein.',
                                  ),
                                ),
                              );
                              return;
                            }

                            try {
                              setState(() => saving = true);

                              await parentContext
                                  .read<FeedProvider>()
                                  .updatePost(postId, newText);

                              if (parentContext.mounted) {
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text('Beitrag wurde bearbeitet.'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (parentContext.mounted) {
                                ScaffoldMessenger.of(
                                  parentContext,
                                ).showSnackBar(
                                  SnackBar(content: Text('Fehler: $e')),
                                );
                              }
                            } finally {
                              if (stateContext.mounted) {
                                setState(() => saving = false);
                              }
                            }
                          },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Beitrag löschen'),
          content: const Text('Möchtest du diesen Beitrag wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await context.read<FeedProvider>().deletePost(postId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beitrag wurde gelöscht.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }
}

class _AnimatedLikeButton extends StatefulWidget {
  final bool hasLiked;
  final VoidCallback onPressed;

  const _AnimatedLikeButton({required this.hasLiked, required this.onPressed});

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.35,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_controller);
  }

  void _handlePressed() {
    // Nur beim Setzen eines Likes animieren.
    if (!widget.hasLiked) {
      _controller.forward(from: 0);
    }

    widget.onPressed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        onPressed: _handlePressed,
        tooltip: widget.hasLiked ? 'Gefällt mir entfernen' : 'Gefällt mir',
        icon: Icon(
          widget.hasLiked ? Icons.favorite : Icons.favorite_border,
          color: widget.hasLiked ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }
}
