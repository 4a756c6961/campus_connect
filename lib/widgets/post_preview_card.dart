import 'package:flutter/material.dart';

class PostPreviewCard extends StatelessWidget {
  final String authorName;
  final String formattedDate;
  final String postText;

  const PostPreviewCard({
    super.key,
    required this.authorName,
    required this.formattedDate,
    required this.postText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
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
            const SizedBox(height: 10),
            Text(postText),
          ],
        ),
      ),
    );
  }
}
