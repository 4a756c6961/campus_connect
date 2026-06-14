import 'package:flutter/material.dart';

class PostPreviewCard extends StatelessWidget {
  final String authorName;
  final String authorPhotoUrl;
  final String formattedDate;
  final String postText;
  final List<String> tags;
  final VoidCallback? onAuthorTap;

  const PostPreviewCard({
    super.key,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.formattedDate,
    required this.postText,
    this.tags = const [],
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = authorPhotoUrl.trim().isNotEmpty;

    final visibleTags =
        tags
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAuthorTap,
              child: CircleAvatar(
                radius: 22,
                backgroundImage:
                    hasPhoto ? NetworkImage(authorPhotoUrl.trim()) : null,
                child: hasPhoto ? null : const Icon(Icons.person),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onAuthorTap,
                    child: Text(
                      authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),

                  if (postText.trim().isNotEmpty) Text(postText),

                  if (visibleTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          visibleTags.map((tag) {
                            return Chip(
                              label: Text('#$tag'),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}