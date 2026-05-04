import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/providers/comments_provider.dart';
import 'package:campus_connect/services/feed_service.dart';
import 'package:campus_connect/widgets/comment_card.dart';
import 'package:campus_connect/widgets/comment_input.dart';
import 'package:campus_connect/widgets/post_preview_card.dart';

class FeedCommentsScreen extends StatelessWidget {
  final String postId;
  final String postText;
  final String authorName;
  final String authorPhotoUrl;
  final Timestamp? createdAt;

  const FeedCommentsScreen({
    super.key,
    required this.postId,
    required this.postText,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentsProvider(FeedService(), postId),
      child: _FeedCommentsView(
        postId: postId,
        postText: postText,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        createdAt: createdAt,
      ),
    );
  }
}

class _FeedCommentsView extends StatelessWidget {
  final String postId;
  final String postText;
  final String authorName;
  final String authorPhotoUrl;
  final Timestamp? createdAt;

  const _FeedCommentsView({
    required this.postId,
    required this.postText,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.createdAt,
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Gerade eben';
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  Future<void> _handleSendComment(BuildContext context) async {
    final message = await context.read<CommentsProvider>().sendComment();

    if (!context.mounted) return;

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showEditCommentDialog({
    required BuildContext context,
    required String commentId,
    required String currentText,
  }) async {
    final controller = TextEditingController(text: currentText);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kommentar bearbeiten'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Kommentar eingeben'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newText = controller.text.trim();

                if (newText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Der Kommentar darf nicht leer sein.'),
                    ),
                  );
                  return;
                }

                try {
                  await FeedService().updateComment(
                    postId: postId,
                    commentId: commentId,
                    text: newText,
                  );

                  if (!context.mounted) return;

                  Navigator.of(dialogContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kommentar wurde bearbeitet.'),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Kommentar konnte nicht bearbeitet werden.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _confirmDeleteComment({
    required BuildContext context,
    required String commentId,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Kommentar löschen?'),
          content: const Text('Möchtest du diesen Kommentar wirklich löschen?'),
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

    if (shouldDelete != true) return;

    try {
      await FeedService().deleteComment(postId: postId, commentId: commentId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kommentar wurde gelöscht.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kommentar konnte nicht gelöscht werden.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsProvider = context.watch<CommentsProvider>();
    final commentsStream = commentsProvider.commentsStream;

    return Scaffold(
      appBar: AppBar(title: const Text('Kommentare')),
      body: Column(
        children: [
          PostPreviewCard(
            authorName: authorName,
            authorPhotoUrl: authorPhotoUrl,
            formattedDate: _formatTimestamp(createdAt),
            postText: postText,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: commentsStream,
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Fehler beim Laden der Kommentare.'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Noch keine Kommentare vorhanden.'),
                  );
                }

                final commentDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: commentDocs.length,
                  itemBuilder: (ctx, index) {
                    final commentDoc = commentDocs[index];
                    final commentId = commentDoc.id;
                    final commentData =
                        commentDoc.data() as Map<String, dynamic>;

                    final commentText = (commentData['text'] ?? '').toString();
                    final commentAuthor =
                        (commentData['authorName'] ?? 'Unbekannt').toString();
                    final commentCreatedAt =
                        commentData['createdAt'] as Timestamp?;
                    final commentPhotoUrl =
                        (commentData['photoUrl'] ?? '').toString();
                    final commentUserId =
                        (commentData['userId'] ?? '').toString();

                    final currentUser = FirebaseAuth.instance.currentUser;
                    final isCommentOwner = currentUser?.uid == commentUserId;

                    return Stack(
                      children: [
                        CommentCard(
                          authorName: commentAuthor,
                          commentText: commentText,
                          formattedDate: _formatTimestamp(commentCreatedAt),
                          photoUrl: commentPhotoUrl,
                        ),

                        if (isCommentOwner)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditCommentDialog(
                                    context: context,
                                    commentId: commentId,
                                    currentText: commentText,
                                  );
                                }

                                if (value == 'delete') {
                                  _confirmDeleteComment(
                                    context: context,
                                    commentId: commentId,
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Bearbeiten'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Löschen'),
                                    ),
                                  ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          CommentInput(
            controller: commentsProvider.controller,
            isSending: commentsProvider.isSending,
            onSend: () => _handleSendComment(context),
          ),
        ],
      ),
    );
  }
}
