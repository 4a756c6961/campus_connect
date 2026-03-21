import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Timestamp? createdAt;

  const FeedCommentsScreen({
    super.key,
    required this.postId,
    required this.postText,
    required this.authorName,
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
        createdAt: createdAt,
      ),
    );
  }
}

class _FeedCommentsView extends StatelessWidget {
  final String postId;
  final String postText;
  final String authorName;
  final Timestamp? createdAt;

  const _FeedCommentsView({
    required this.postId,
    required this.postText,
    required this.authorName,
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
                    final commentData =
                        commentDocs[index].data() as Map<String, dynamic>;

                    final commentText = (commentData['text'] ?? '').toString();
                    final commentAuthor =
                        (commentData['authorName'] ?? 'Unbekannt').toString();
                    final commentCreatedAt =
                        commentData['createdAt'] as Timestamp?;

                    return CommentCard(
                      authorName: commentAuthor,
                      commentText: commentText,
                      formattedDate: _formatTimestamp(commentCreatedAt),
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
