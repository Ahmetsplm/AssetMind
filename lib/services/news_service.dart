import 'package:http/http.dart' as http;
import 'package:webfeed_plus/webfeed_plus.dart';

class NewsService {
  // Turkish Financial News (Google News - Economy/Finance)
  static const String _feedUrl =
      "https://news.google.com/rss/search?q=ekonomi+finans&hl=tr&gl=TR&ceid=TR:tr";

  Future<List<RssItem>> getNews() async {
    try {
      final response = await http.get(Uri.parse(_feedUrl));
      if (response.statusCode == 200) {
        final feed = RssFeed.parse(response.body);
        return feed.items ?? [];
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}
