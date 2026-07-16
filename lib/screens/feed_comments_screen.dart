import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/providers/comments_provider.dart';
import 'package:campus_connect/screens/visited_user_profile_screen.dart';
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
  final String authorUserId;
  final List<String> tags;
  final String gifUrl;
  final String gifTitle;

  const FeedCommentsScreen({
    super.key,
    required this.postId,
    required this.postText,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.createdAt,
    required this.authorUserId,
    this.tags = const [],
    this.gifUrl = '',
    this.gifTitle = '',
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
        authorUserId: authorUserId,
        tags: tags,
        gifUrl: gifUrl,
        gifTitle: gifTitle,
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
  final String authorUserId;
  final List<String> tags;
  final String gifUrl;
  final String gifTitle;

  const _FeedCommentsView({
    required this.postId,
    required this.postText,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.createdAt,
    required this.authorUserId,
    this.tags = const [],
    this.gifUrl = '',
    this.gifTitle = '',
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Gerade eben';

    return DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate());
  }

  List<String> _readTags(dynamic rawTags) {
    if (rawTags is! Iterable) {
      return [];
    }

    return rawTags
        .map((tag) => tag.toString().trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  String _readGifImageUrl(Map<String, dynamic> gifData) {
    final imagesRaw = gifData['images'];

    if (imagesRaw is! Map) {
      return '';
    }

    final images = Map<String, dynamic>.from(imagesRaw);

    final originalRaw = images['original'];
    final fixedHeightRaw = images['fixed_height'];
    final downsizedRaw = images['downsized_medium'];

    String originalImageUrl = '';
    String fixedHeightImageUrl = '';
    String downsizedImageUrl = '';

    if (originalRaw is Map) {
      final original = Map<String, dynamic>.from(originalRaw);
      originalImageUrl = (original['url'] ?? '').toString();
    }

    if (fixedHeightRaw is Map) {
      final fixedHeight = Map<String, dynamic>.from(fixedHeightRaw);
      fixedHeightImageUrl = (fixedHeight['url'] ?? '').toString();
    }

    if (downsizedRaw is Map) {
      final downsized = Map<String, dynamic>.from(downsizedRaw);
      downsizedImageUrl = (downsized['url'] ?? '').toString();
    }

    return _firstNonEmpty([
      originalImageUrl,
      fixedHeightImageUrl,
      downsizedImageUrl,
    ]);
  }

  Map<String, String> _readGifData(Map<String, dynamic> postData) {
    final gifRaw = postData['gif'];

    final gifData =
        gifRaw is Map ? Map<String, dynamic>.from(gifRaw) : <String, dynamic>{};

    final selectedGifRaw = postData['selectedGif'];

    final selectedGifData =
        selectedGifRaw is Map
            ? Map<String, dynamic>.from(selectedGifRaw)
            : <String, dynamic>{};

    final gifImageUrl = _readGifImageUrl(gifData);
    final selectedGifImageUrl = _readGifImageUrl(selectedGifData);

    final resolvedGifUrl = _firstNonEmpty([
      postData['gifUrl'],
      gifData['url'],
      gifData['gifUrl'],
      selectedGifData['url'],
      selectedGifData['gifUrl'],
      gifImageUrl,
      selectedGifImageUrl,
      gifUrl,
    ]);

    final resolvedGifTitle = _firstNonEmpty([
      postData['gifTitle'],
      gifData['title'],
      gifData['name'],
      selectedGifData['title'],
      selectedGifData['name'],
      gifTitle,
    ]);

    return {'url': resolvedGifUrl, 'title': resolvedGifTitle};
  }

  void _openVisitedProfile(BuildContext context, String targetUserId) {
    if (targetUserId.trim().isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitedUserProfileScreen(userId: targetUserId),
      ),
    );
  }

  Widget _buildPostPreview(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .doc(postId)
              .snapshots(),
      builder: (context, snapshot) {
        final postData = snapshot.data?.data();

        if (postData == null) {
          return PostPreviewCard(
            authorName: authorName,
            authorPhotoUrl: authorPhotoUrl,
            formattedDate: _formatTimestamp(createdAt),
            postText: postText,
            tags: tags,
            gifUrl: gifUrl,
            gifTitle: gifTitle,
            onAuthorTap: () {
              _openVisitedProfile(context, authorUserId);
            },
          );
        }

        final previewText = (postData['text'] ?? postText).toString();

        final previewAuthorName =
            (postData['authorName'] ??
                    postData['displayName'] ??
                    postData['userName'] ??
                    authorName)
                .toString();

        final previewAuthorPhotoUrl =
            (postData['authorPhotoUrl'] ??
                    postData['photoUrl'] ??
                    authorPhotoUrl)
                .toString();

        final previewAuthorUserId =
            (postData['authorUserId'] ?? postData['userId'] ?? authorUserId)
                .toString();

        final createdAtRaw = postData['createdAt'];

        final previewCreatedAt =
            createdAtRaw is Timestamp ? createdAtRaw : createdAt;

        final previewTags = _readTags(postData['tags']);
        final previewGifData = _readGifData(postData);

        return PostPreviewCard(
          authorName: previewAuthorName,
          authorPhotoUrl: previewAuthorPhotoUrl,
          formattedDate: _formatTimestamp(previewCreatedAt),
          postText: previewText,
          tags: previewTags.isNotEmpty ? previewTags : tags,
          gifUrl: previewGifData['url'] ?? '',
          gifTitle: previewGifData['title'] ?? '',
          onAuthorTap: () {
            _openVisitedProfile(context, previewAuthorUserId);
          },
        );
      },
    );
  }

  Widget _buildEmptyCommentsState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: colorScheme.primary.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Kommentare',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Starte die Unterhaltung und schreibe den ersten Kommentar.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
          _buildPostPreview(context),

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
                  return _buildEmptyCommentsState(context);
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
                          onAuthorTap: () {
                            _openVisitedProfile(context, commentUserId);
                          },
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
