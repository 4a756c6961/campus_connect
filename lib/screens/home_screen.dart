import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:campus_connect/providers/feed_provider.dart';
import 'package:campus_connect/screens/feed_comments_screen.dart';
import 'package:campus_connect/services/feed_service.dart';
import 'package:campus_connect/widgets/post_card.dart';
import 'package:campus_connect/screens/visited_user_profile_screen.dart';
import 'package:campus_connect/screens/tag_filter_screen.dart';
import 'package:campus_connect/screens/notifications_screen.dart';
import 'package:campus_connect/services/notification_service.dart';
import 'package:campus_connect/services/follow_service.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeScreenView();
  }
}

class _HomeScreenView extends StatelessWidget {
  const _HomeScreenView();

  static final FeedService _feedService = FeedService();
  static final NotificationService _notificationService = NotificationService();
  static final FollowService _followService = FollowService();
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'wird geladen...';
    return DateFormat('dd.MM.yyyy, HH:mm').format(timestamp.toDate());
  }
  double _calculateFeedScore({
  required Timestamp? createdAt,
  required bool isFollowed,
}) {
  final createdDate =
      createdAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);

  final ageInHours =
      DateTime.now().difference(createdDate).inHours.toDouble();

  const followBonus = 24.0;

  return (isFollowed ? followBonus : 0.0) - ageInHours;
}

  void _sortPostsByFollowing(
  List<QueryDocumentSnapshot> posts,
  Set<String> followedUserIds,
) {
  posts.sort((a, b) {
    final aData = a.data() as Map<String, dynamic>;
    final bData = b.data() as Map<String, dynamic>;

    final aUserId = (aData['userId'] ?? '').toString();
    final bUserId = (bData['userId'] ?? '').toString();

    final aCreatedAtRaw = aData['createdAt'];
    final bCreatedAtRaw = bData['createdAt'];

    final aCreatedAt =
        aCreatedAtRaw is Timestamp ? aCreatedAtRaw : null;

    final bCreatedAt =
        bCreatedAtRaw is Timestamp ? bCreatedAtRaw : null;

    final aScore = _calculateFeedScore(
      createdAt: aCreatedAt,
      isFollowed: followedUserIds.contains(aUserId),
    );

    final bScore = _calculateFeedScore(
      createdAt: bCreatedAt,
      isFollowed: followedUserIds.contains(bUserId),
    );

    return bScore.compareTo(aScore);
  });
}

  Future<void> _handleToggleLike(BuildContext context, String postId) async {
    final message = await context.read<FeedProvider>().toggleLike(postId);

    if (!context.mounted) return;

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openComments(
    BuildContext context, {
    required String postId,
    required String postText,
    required String authorName,
    required String authorPhotoUrl,
    required Timestamp? createdAt,
    required String authorUserId,
    required List<String> tags,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => FeedCommentsScreen(
              postId: postId,
              postText: postText,
              authorName: authorName,
              authorPhotoUrl: authorPhotoUrl,
              createdAt: createdAt,
              authorUserId: authorUserId,
              tags: tags,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final postsStream = feedProvider.postsStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusConnect Feed'),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream:
                FirebaseAuth.instance.currentUser == null
                    ? null
                    : _notificationService.getUnreadNotifications(
                      FirebaseAuth.instance.currentUser!.uid,
                    ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              final hasUnreadNotifications = unreadCount > 0;

              return IconButton(
                tooltip: 'Benachrichtigungen',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NotificationsScreen()),
                  );
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (hasUnreadNotifications)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<Set<String>>(
              stream: _followService.followingUserIdsStream(),
              builder: (context, followingSnapshot) {
                if (followingSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Follow-Daten konnten nicht geladen werden: '
                      '${followingSnapshot.error}',
                    ),
                  );
                }

                if (followingSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !followingSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final followedUserIds = followingSnapshot.data ?? <String>{};

                return StreamBuilder<QuerySnapshot>(
                  stream: postsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Fehler: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = List<QueryDocumentSnapshot>.from(
                      snapshot.data?.docs ?? [],
                    );

                    _sortPostsByFollowing(docs, followedUserIds);

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('Dein Feed sieht noch leer aus 🤭'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final doc = docs[i];
                        final data = doc.data() as Map<String, dynamic>;

                        final text = (data['text'] ?? '').toString();
                        final email = (data['userEmail'] ?? '').toString();
                        final userName = (data['userName'] ?? '').toString();
                        final userId = (data['userId'] ?? '').toString();
                        final photoUrl = (data['photoUrl'] ?? '').toString();

                        final gifDataRaw = data['gif'];
                        final gifData =
                            gifDataRaw is Map<String, dynamic>
                                ? gifDataRaw
                                : null;

                        final gifUrl = (gifData?['url'] ?? '').toString();
                        final gifTitle = (gifData?['title'] ?? '').toString();

                        final author =
                            userName.isNotEmpty
                                ? userName
                                : email.isNotEmpty
                                ? email
                                : 'Unbekannt';

                        final createdAtRaw = data['createdAt'];
                        final createdAt =
                            createdAtRaw is Timestamp ? createdAtRaw : null;

                        final editedAtRaw = data['editedAt'];
                        final editedAt =
                            editedAtRaw is Timestamp
                                ? editedAtRaw.toDate()
                                : null;

                        final formattedDate = _formatTimestamp(createdAt);
                        final imageUrl = (data['imageUrl'] ?? '').toString();

                        final tags =
                            (data['tags'] as List<dynamic>? ?? [])
                                .map((tag) => tag.toString())
                                .where((tag) => tag.trim().isNotEmpty)
                                .toList();

                        return StreamBuilder<QuerySnapshot>(
                          stream: _feedService.getLikesStream(doc.id),
                          builder: (context, likeSnapshot) {
                            final likeDocs = likeSnapshot.data?.docs ?? [];

                            final currentUser =
                                FirebaseAuth.instance.currentUser;

                            final likeCount = likeDocs.length;

                            final hasLiked =
                                currentUser != null &&
                                likeDocs.any(
                                  (likeDoc) => likeDoc.id == currentUser.uid,
                                );

                            return StreamBuilder<QuerySnapshot>(
                              stream: _feedService.getCommentsStream(doc.id),
                              builder: (context, commentSnapshot) {
                                final liveCommentCount =
                                    commentSnapshot.data?.docs.length ?? 0;

                                return PostCard(
                                  postId: doc.id,
                                  text: text,
                                  userId: userId,
                                  authorName: author,
                                  photoUrl: photoUrl,
                                  formattedDate: formattedDate,
                                  likeCount: likeCount,
                                  commentCount: liveCommentCount,
                                  hasLiked: hasLiked,
                                  editedAt: editedAt,
                                  gifUrl: gifUrl,
                                  gifTitle: gifTitle,
                                  imageUrl: imageUrl,
                                  tags: tags,
                                  onTagTap: (tag) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => TagFilterScreen(tag: tag),
                                      ),
                                    );
                                  },
                                  onToggleLike:
                                      () => _handleToggleLike(context, doc.id),
                                  onAuthorTap: () {
                                    if (userId.isEmpty) return;

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (_) => VisitedUserProfileScreen(
                                              userId: userId,
                                            ),
                                      ),
                                    );
                                  },
                                  onOpenComments: () {
                                    _openComments(
                                      context,
                                      postId: doc.id,
                                      postText: text,
                                      authorName: author,
                                      authorPhotoUrl: photoUrl,
                                      createdAt: createdAt,
                                      authorUserId: userId,
                                      tags: tags,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
