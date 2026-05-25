import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';
import '../models/news_item.dart';

class NewsService {
  // Investing.com TR RSS Kaynakları (Tümü Türkçe)
  static const String _bistFeedUrl = "https://tr.investing.com/rss/news_25.rss";
  static const String _cryptoFeedUrl = "https://tr.investing.com/rss/news_301.rss";
  static const String _globalFeedUrl = "https://tr.investing.com/rss/news_285.rss";
  static const String _overviewFeedUrl = "https://tr.investing.com/rss/market_overview.rss";

  Future<List<NewsItem>> getNews({String category = 'Tümü'}) async {
    List<NewsItem> results = [];
    try {
      if (category == 'Tümü') {
        results.addAll(await _fetchRss(_overviewFeedUrl, 'Piyasalar'));
        results.addAll(await _fetchRss(_bistFeedUrl, 'BIST'));
      } else if (category == 'BIST') {
        results.addAll(await _fetchRss(_bistFeedUrl, 'BIST'));
      } else if (category == 'Kripto') {
        results.addAll(await _fetchRss(_cryptoFeedUrl, 'Kripto'));
      } else if (category == 'Global') {
        results.addAll(await _fetchRss(_globalFeedUrl, 'Global'));
      } else if (category == 'Fonlar') {
        // Fonlara özel ayrı bir RSS yok, o yüzden genel Piyasalar akışını veriyoruz.
        results.addAll(await _fetchRss(_overviewFeedUrl, 'Fon & Piyasa'));
      }
      
      // Tarihe göre azalan (yeniden eskiye) sıralama
      results.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      
      // "Tümü" seçildiğinde çok fazla birikmeyi önlemek için ilk 50 veriyi göster
      if (category == 'Tümü' && results.length > 50) {
        results = results.sublist(0, 50);
      }
      
      return results;
    } catch (e) {
      throw Exception('Haberler çekilirken hata oluştu: $e');
    }
  }

  Future<List<NewsItem>> _fetchRss(String url, String categoryName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Türkçe karakter bozulmalarını engellemek için utf8 ile decode ediyoruz.
        final String decodedBody = utf8.decode(response.bodyBytes);
        final feed = RssFeed.parse(decodedBody);
        
        return feed.items?.map((item) => NewsItem(
          title: item.title ?? 'Başlıksız',
          url: item.link ?? '',
          source: 'Investing ($categoryName)',
          publishedAt: item.pubDate ?? DateTime.now(),
          category: categoryName,
        )).toList() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
