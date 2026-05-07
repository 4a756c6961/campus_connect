import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final postsStream = FirebaseFirestore.instance
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
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text('Noch keine Beiträge vorhanden.'),
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

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final post = posts[index];
                final data = post.data() as Map<String, dynamic>;

                final text = (data['text'] ?? '').toString();
                final createdAt = data['createdAt'] as Timestamp?;
                final editedAt = data['editedAt'] as Timestamp?;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatTimestamp(createdAt)}${editedAt != null ? ' · bearbeitet' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
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