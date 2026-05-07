import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:campus_connect/screens/feed_comments_screen.dart';

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
    return DateFormat('dd.MM.yyyy, HH:mm').format(timestamp.toDate());
  }

  Stream<int> _countSubcollection(String postId, String subcollectionName) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection(subcollectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    final postsStream =
        FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: postsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Beiträge konnten nicht geladen werden.',
            style: TextStyle(color: Colors.red),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Noch keine Beiträge vorhanden.'),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),

            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final post = posts[index];
                final data = post.data() as Map<String, dynamic>;

                final text = (data['text'] ?? '').toString();

                final createdAtRaw = data['createdAt'];
                final createdAt =
                    createdAtRaw is Timestamp ? createdAtRaw : null;

                final editedAtRaw = data['editedAt'];
                final editedAt = editedAtRaw is Timestamp ? editedAtRaw : null;

                final authorName =
                    (data['authorName'] ??
                            data['displayName'] ??
                            data['userName'] ??
                            'Unbekannt')
                        .toString();

                final authorPhotoUrl =
                    (data['authorPhotoUrl'] ?? data['photoUrl'] ?? '')
                        .toString();

                final authorUserId =
                    (data['authorUserId'] ?? data['userId'] ?? userId)
                        .toString();

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => FeedCommentsScreen(
                                postId: post.id,
                                postText: text,
                                authorName: authorName,
                                authorPhotoUrl: authorPhotoUrl,
                                createdAt: createdAt,
                                authorUserId: authorUserId,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(text),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_formatTimestamp(createdAt)}${editedAt != null ? ' · bearbeitet' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),

                              StreamBuilder<int>(
                                stream: _countSubcollection(post.id, 'likes'),
                                builder: (context, likeSnapshot) {
                                  final likeCount = likeSnapshot.data ?? 0;

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.favorite_border,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('$likeCount'),
                                    ],
                                  );
                                },
                              ),

                              const SizedBox(width: 12),

                              StreamBuilder<int>(
                                stream: _countSubcollection(
                                  post.id,
                                  'comments',
                                ),
                                builder: (context, commentSnapshot) {
                                  final commentCount =
                                      commentSnapshot.data ?? 0;

                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('$commentCount'),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
