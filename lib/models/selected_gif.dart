class SelectedGif {
  final String id;
  final String url;
  final String title;

  const SelectedGif({
    required this.id,
    required this.url,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'title': title,
    };
  }

  factory SelectedGif.fromMap(Map<String, dynamic> map) {
    return SelectedGif(
      id: (map['id'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
    );
  }
}