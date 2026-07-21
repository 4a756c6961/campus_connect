import 'package:flutter/material.dart';

class PostPreviewCard extends StatelessWidget {
  final String authorName;
  final String authorPhotoUrl;
  final String formattedDate;
  final String postText;
  final String gifUrl;
  final String gifTitle;
  final List<String> tags;
  final VoidCallback? onAuthorTap;

  const PostPreviewCard({
    super.key,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.formattedDate,
    required this.postText,
    this.gifUrl = '',
    this.gifTitle = '',
    this.tags = const [],
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = authorPhotoUrl.trim().isNotEmpty;
    final hasText = postText.trim().isNotEmpty;
    final hasGif = gifUrl.trim().isNotEmpty;

    final visibleTags =
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    ],
                  ),
                ),
              ],
            ),

            if (hasText) ...[const SizedBox(height: 12), Text(postText)],

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

            if (hasGif) ...[
              if (hasText || visibleTags.isNotEmpty)
                const SizedBox(height: 12)
              else
                const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  gifUrl.trim(),
                  width: double.infinity,
                  fit: BoxFit.contain,
                  semanticLabel:
                      gifTitle.trim().isNotEmpty
                          ? gifTitle.trim()
                          : 'GIPHY GIF',
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('GIF konnte nicht geladen werden.'),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),

              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Powered by GIPHY',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
