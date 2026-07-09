import 'package:flutter/material.dart';

class TagActionChips extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<String> onTagTap;

  const TagActionChips({
    super.key,
    required this.tags,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (cleanedTags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: cleanedTags.map((tag) {
        final cleanTag = tag.startsWith('#') ? tag.substring(1) : tag;
        final label = '#$cleanTag';

        return ActionChip(
          label: Text(label),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: () {
            onTagTap(cleanTag);
          },
        );
      }).toList(),
    );
  }
}