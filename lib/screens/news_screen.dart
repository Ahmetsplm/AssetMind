import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/news_service.dart';
import '../../models/news_item.dart';
import '../../widgets/skeleton_list_item.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with AutomaticKeepAliveClientMixin {
  final NewsService _newsService = NewsService();
  late Future<List<NewsItem>> _newsFuture;
  
  final List<String> _categories = ['Tümü', 'BIST', 'Kripto', 'Global', 'Fonlar'];
  String _selectedCategory = 'Tümü';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  void _loadNews() {
    setState(() {
      _newsFuture = _newsService.getNews(category: _selectedCategory);
    });
  }

  Future<void> _refreshNews() async {
    _loadNews();
    await _newsFuture;
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    // Use LaunchMode.inAppWebView for better UX as requested
    if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Haber açılamadı: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Filtreler (ChoiceChips)
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                        ? Colors.white 
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Theme.of(context).primaryColor,
                  backgroundColor: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (selected) {
                    if (selected && _selectedCategory != category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _loadNews();
                    }
                  },
                ),
              );
            },
          ),
        ),
        // Haber Listesi
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshNews,
            color: Theme.of(context).primaryColor,
            child: FutureBuilder<List<NewsItem>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: 10,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, __) => const SkeletonListItem(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Haberler yüklenemedi',
                          style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _refreshNews, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "$_selectedCategory kategorisinde haber bulunamadı.",
                      style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodyMedium?.color),
                    )
                  );
                }

                final news = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: news.length,
                  itemBuilder: (context, index) {
                    final item = news[index];
                    final date = DateFormat('dd MMM HH:mm', 'tr_TR').format(item.publishedAt);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            if (item.url.isNotEmpty) _launchUrl(item.url);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.source.toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      date,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  item.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    height: 1.3,
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
