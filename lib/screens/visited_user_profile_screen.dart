import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:campus_connect/services/follow_service.dart';
import 'package:campus_connect/widgets/user_posts_section.dart';

class VisitedUserProfileScreen extends StatelessWidget {
  final String userId;

  const VisitedUserProfileScreen({super.key, required this.userId});

  static final FollowService _followService = FollowService();

  String _getDisplayName(Map<String, dynamic> data) {
    return (data['displayName'] ??
            data['userName'] ??
            data['name'] ??
            'Unbekannter Nutzer')
        .toString();
  }

  String _getPhotoUrl(Map<String, dynamic> data) {
    return (data['photoUrl'] ?? '').toString();
  }

  String _getBio(Map<String, dynamic> data) {
    return (data['bio'] ?? '').toString().trim();
  }

  Future<void> _toggleFollow({
    required BuildContext context,
    required bool isFollowing,
  }) async {
    try {
      if (isFollowing) {
        await _followService.unfollowUser(userId);
      } else {
        await _followService.followUser(userId);
      }
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _buildFollowCount({
    required BuildContext context,
    required Stream<int> stream,
    required String label,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(userId).snapshots();

    final currentUserId = _followService.currentUserId;
    final isOwnProfile = currentUserId == userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Profil konnte nicht geladen werden.'),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profil nicht gefunden.'));
          }

          final data = snapshot.data!.data()!;

          final displayName = _getDisplayName(data);
          final photoUrl = _getPhotoUrl(data);
          final bio = _getBio(data);
          final location = (data['location'] ?? '').toString().trim();
          final cohort = (data['cohort'] ?? '').toString().trim();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 54,
                  backgroundImage:
                      photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child:
                      photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 54)
                          : null,
                ),

                const SizedBox(height: 16),

                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFollowCount(
                      context: context,
                      stream: _followService.followersCountStream(userId),
                      label: 'Follower',
                    ),
                    const SizedBox(width: 48),
                    _buildFollowCount(
                      context: context,
                      stream: _followService.followingCountStream(userId),
                      label: 'Folgt',
                    ),
                  ],
                ),

                if (!isOwnProfile) ...[
                  const SizedBox(height: 20),

                  StreamBuilder<bool>(
                    stream: _followService.isFollowingStream(userId),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;

                      return SizedBox(
                        width: double.infinity,
                        child:
                            isFollowing
                                ? OutlinedButton.icon(
                                  onPressed:
                                      () => _toggleFollow(
                                        context: context,
                                        isFollowing: true,
                                      ),
                                  icon: const Icon(Icons.person_remove),
                                  label: const Text('Entfolgen'),
                                )
                                : FilledButton.icon(
                                  onPressed:
                                      () => _toggleFollow(
                                        context: context,
                                        isFollowing: false,
                                      ),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Folgen'),
                                ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Über mich',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    bio.isNotEmpty
                        ? bio
                        : 'Noch keine Profilbeschreibung vorhanden.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),

                if (location.isNotEmpty || cohort.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (location.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.location_on, size: 18),
                            label: Text(location),
                          ),
                        if (cohort.isNotEmpty)
                          Chip(
                            avatar: const Icon(Icons.school, size: 18),
                            label: Text(cohort),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                Align(
                  alignment: Alignment.centerLeft,
                  child: UserPostsSection(userId: userId, title: 'Beiträge'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
