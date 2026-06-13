String normalizeSearchValue(String value) {
  return value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .trim();
}

List<String> buildSearchTerms({
  required String displayName,
  required String userName,
  String? location,
  String? cohort,
}) {
  final fields = [
    displayName,
    userName,
    location ?? '',
    cohort ?? '',
  ];

  final terms = <String>{};

  for (final field in fields) {
    final normalized = normalizeSearchValue(field);

    if (normalized.isEmpty) continue;

    final compactValue = normalized.replaceAll(RegExp(r'\s+'), '');

    final parts = normalized
        .split(RegExp(r'[\s,.;:_-]+'))
        .where((part) => part.isNotEmpty);

    final searchableParts = {
      ...parts,
      compactValue,
      normalized,
    };

    for (final part in searchableParts) {
      final maxLength = part.length > 30 ? 30 : part.length;

      for (int i = 1; i <= maxLength; i++) {
        terms.add(part.substring(0, i));
      }
    }
  }

  return terms.toList();
}