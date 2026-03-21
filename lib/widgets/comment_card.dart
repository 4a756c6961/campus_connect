import 'package:flutter/material.dart';

class CommentCard extends StatelessWidget {
  final String authorName;
  final String commentText;
  final String formattedDate;

  const CommentCard({
    super.key,
    required this.authorName,
    required this.commentText,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(commentText),
          ],
        ),
      ),
    );
  }
}
