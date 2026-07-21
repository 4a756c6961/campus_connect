import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:campus_connect/screens/feed_comments_screen.dart';
import 'package:campus_connect/screens/tag_filter_screen.dart';
import 'package:campus_connect/widgets/post_card.dart';

class UserPostsSection extends StatelessWidget {
  final String userId;
  final String title;

  const UserPostsSection({
    super.key,
    required this.userId,
    this.title = 'Beiträge',
  });

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'gerade eben';

    return DateFormat(
      'dd.MM.yyyy, HH:mm',
    ).format(timestamp.toDate());
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _subcollectionStream(
    String postId,
    String subcollectionName,
  ) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection(subcollectionName)
        .snapshots();
  }

  List<String> _readTags(dynamic rawTags) {
    if (rawTags is! Iterable) {
      return [];
    }

    return rawTags
        .map((tag) => tag.toString().trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
  }

  int _readCount(dynamic value) {
    return value is num ? value.toInt() : 0;
  }

  Map<String, String> _readGifData(Map<String, dynamic> postData) {
    final gifRaw = postData['gif'];

    final gifData = gifRaw is Map
        ? Map<String, dynamic>.from(gifRaw)
        : <String, dynamic>{};

    final selectedGifRaw = postData['selectedGif'];

    final selectedGifData = selectedGifRaw is Map
        ? Map<String, dynamic>.from(selectedGifRaw)
        : <String, dynamic>{};

    String nestedImageUrl = '';

    final imagesRaw = gifData['images'];

    if (imagesRaw is Map) {
      final images = Map<String, dynamic>.from(imagesRaw);
      final originalRaw = images['original'];

      if (originalRaw is Map) {
        final original = Map<String, dynamic>.from(originalRaw);
        nestedImageUrl = (original['url'] ?? '').toString();
      }
    }

    final gifUrl = (
      postData['gifUrl'] ??
      gifData['url'] ??
      gifData['gifUrl'] ??
      selectedGifData['url'] ??
      selectedGifData['gifUrl'] ??
      nestedImageUrl
    ).toString().trim();

    final gifTitle = (
      postData['gifTitle'] ??
      gifData['title'] ??
      gifData['name'] ??
      selectedGifData['title'] ??
      selectedGifData['name'] ??
      ''
    ).toString().trim();

    return {
      'url': gifUrl,
      'title': gifTitle,
    };
  }

  bool _hasCurrentUserLiked(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> likeDocuments,
    String? currentUserId,
  ) {
    if (currentUserId == null) return false;

    return likeDocuments.any((likeDocument) {
      if (likeDocument.id == currentUserId) {
        return true;
      }

      final likeData = likeDocument.data();

      return likeData['userId']?.toString() == currentUserId;
    });
  }

  Future<void> _toggleLike(
    BuildContext context,
    String postId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Du musst eingeloggt sein, um Beiträge zu liken.',
          ),
        ),
      );
      return;
    }

    final likesCollection = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes');

    final ownLikeReference = likesCollection.doc(currentUser.uid);

    try {
      final ownLikeSnapshot = await ownLikeReference.get();

      if (ownLikeSnapshot.exists) {
        await ownLikeReference.delete();
        return;
      }

      final existingLegacyLikes = await likesCollection
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (existingLegacyLikes.docs.isNotEmpty) {
        await existingLegacyLikes.docs.first.reference.delete();
        return;
      }

      await ownLikeReference.set({
        'userId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Like konnte nicht aktualisiert werden: $error',
          ),
        ),
      );
    }
  }

  void _openComments({
    required BuildContext context,
    required String postId,
    required String text,
    required String authorName,
    required String authorPhotoUrl,
    required Timestamp? createdAt,
    required String authorUserId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedCommentsScreen(
          postId: postId,
          postText: text,
          authorName: authorName,
          authorPhotoUrl: authorPhotoUrl,
          createdAt: createdAt,
          authorUserId: authorUserId,
        ),
      ),
    );
  }

  void _openTagFilter(
    BuildContext context,
    String tag,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TagFilterScreen(tag: tag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final postsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: postsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Beiträge konnten nicht geladen werden.',
                style: TextStyle(color: Colors.red),
              ),
            ],
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.article_outlined),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Noch keine Beiträge vorhanden.'),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final data = post.data();

                final text = (data['text'] ?? '').toString();

                final createdAtRaw = data['createdAt'];
                final createdAt =
                    createdAtRaw is Timestamp ? createdAtRaw : null;

                final editedAtRaw = data['editedAt'];
                final editedAt =
                    editedAtRaw is Timestamp ? editedAtRaw : null;

                final authorName = (
                  data['authorName'] ??
                  data['displayName'] ??
                  data['userName'] ??
                  'Unbekannt'
                ).toString();

                final authorPhotoUrl = (
                  data['authorPhotoUrl'] ??
                  data['photoUrl'] ??
                  ''
                ).toString();

                final authorUserId = (
                  data['authorUserId'] ??
                  data['userId'] ??
                  userId
                ).toString();

                final gifData = _readGifData(data);
                final gifUrl = gifData['url'] ?? '';
                final gifTitle = gifData['title'] ?? '';

                final tags = _readTags(data['tags']);

                final storedLikeCount = _readCount(
                  data['likeCount'],
                );

                final storedCommentCount = _readCount(
                  data['commentCount'],
                );

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: _subcollectionStream(
                    post.id,
                    'likes',
                  ),
                  builder: (context, likesSnapshot) {
                    final likeDocuments =
                        likesSnapshot.data?.docs ?? [];

                    final likeCount = likesSnapshot.hasData
                        ? likeDocuments.length
                        : storedLikeCount;

                    final hasLiked = _hasCurrentUserLiked(
                      likeDocuments,
                      currentUser?.uid,
                    );

                    return StreamBuilder<
                        QuerySnapshot<Map<String, dynamic>>>(
                      stream: _subcollectionStream(
                        post.id,
                        'comments',
                      ),
                      builder: (context, commentsSnapshot) {
                        final commentCount =
                            commentsSnapshot.hasData
                            ? commentsSnapshot.data!.docs.length
                            : storedCommentCount;

                        return PostCard(
                          postId: post.id,
                          text: text,
                          userId: authorUserId,
                          authorName: authorName,
                          photoUrl: authorPhotoUrl,
                          formattedDate: _formatTimestamp(
                            createdAt,
                          ),
                          likeCount: likeCount,
                          commentCount: commentCount,
                          hasLiked: hasLiked,
                          editedAt: editedAt?.toDate(),
                          gifUrl: gifUrl,
                          gifTitle: gifTitle,
                          tags: tags,
                          onToggleLike: () {
                            _toggleLike(
                              context,
                              post.id,
                            );
                          },
                          onOpenComments: () {
                            _openComments(
                              context: context,
                              postId: post.id,
                              text: text,
                              authorName: authorName,
                              authorPhotoUrl: authorPhotoUrl,
                              createdAt: createdAt,
                              authorUserId: authorUserId,
                            );
                          },
                          onTagTap: (tag) {
                            _openTagFilter(
                              context,
                              tag,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}