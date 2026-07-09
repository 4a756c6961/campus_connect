String normalizeTag(String input) {
  return input
      .trim()
      .toLowerCase()
      .replaceAll('#', '')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^a-z0-9äöüß_\-]'), '');
}

List<String> normalizeTags(List<String> tags) {
  return tags
      .map(normalizeTag)
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .take(5)
      .toList();
}