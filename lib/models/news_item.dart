class NewsItem {
  final String title;
  final String url;
  final String source;
  final DateTime publishedAt;
  final String category;

  NewsItem({
    required this.title,
    required this.url,
    required this.source,
    required this.publishedAt,
    required this.category,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json, String category) {
    return NewsItem(
      title: json['title'] ?? 'Başlıksız',
      url: json['url'] ?? '',
      source: json['source'] ?? 'Haber',
      publishedAt: json['publishedAt'] != null 
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now()
          : DateTime.now(),
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'category': category,
    };
  }
}
