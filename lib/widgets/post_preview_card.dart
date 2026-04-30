import 'package:flutter/material.dart';

class PostPreviewCard extends StatelessWidget {
  final String authorName;
  final String authorPhotoUrl;
  final String formattedDate;
  final String postText;

  const PostPreviewCard({
    super.key,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.formattedDate,
    required this.postText,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = authorPhotoUrl.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage:
                  hasPhoto ? NetworkImage(authorPhotoUrl.trim()) : null,
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
                  const SizedBox(height: 12),
                  Text(postText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
