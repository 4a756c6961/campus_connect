import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final String authorName;
  final String commentText;
  final String formattedDate;
  final String photoUrl;

  const CommentCard({
    super.key,
    required this.authorName,
    required this.commentText,
    required this.formattedDate,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: hasPhoto ? NetworkImage(photoUrl.trim()) : null,
              child: hasPhoto ? null : const Icon(Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(commentText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
