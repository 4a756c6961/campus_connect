import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/providers/feed_provider.dart';

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
  final DateTime? editedAt;

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
    this.editedAt,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser?.uid == userId;

    final initial =
        authorName.trim().isNotEmpty
            ? authorName.trim().characters.first.toUpperCase()
            : '?';

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
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty ? Text(initial) : null,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
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

            Text(text),

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
                IconButton(
                  onPressed: onToggleLike,
                  icon: Icon(hasLiked ? Icons.favorite : Icons.favorite_border),
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
