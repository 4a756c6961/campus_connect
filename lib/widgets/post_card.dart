import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String author;
  final String text;
  final String formattedDate;
  final Timestamp? createdAt;

  final VoidCallback onOpenComments;
  final VoidCallback onToggleLike;

  final int likeCount;
  final int commentCount;
  final bool hasLiked;

  const PostCard({
    super.key,
    required this.postId,
    required this.author,
    required this.text,
    required this.formattedDate,
    required this.createdAt,
    required this.onOpenComments,
    required this.onToggleLike,
    required this.likeCount,
    required this.commentCount,
    required this.hasLiked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(text),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onToggleLike,
                  icon: Icon(hasLiked ? Icons.favorite : Icons.favorite_border),
                  label: Text('Zur Kenntnis genommen ($likeCount)'),
                ),
                TextButton.icon(
                  onPressed: onOpenComments,
                  icon: const Icon(Icons.comment_outlined),
                  label: Text('Kommentieren ($commentCount)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
