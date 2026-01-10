import 'package:flutter/material.dart';
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/news_service.dart';
import '../../widgets/skeleton_list_item.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen>
    with AutomaticKeepAliveClientMixin {
  final NewsService _newsService = NewsService();
  late Future<List<RssItem>> _newsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _newsFuture = _newsService.getNews();
  }

  Future<void> _refreshNews() async {
    setState(() {
      _newsFuture = _newsService.getNews();
    });
    await _newsFuture;
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Haber açılamadı: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: _refreshNews,
      color: Theme.of(context).primaryColor,
      child: FutureBuilder<List<RssItem>>(
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
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Haberler yüklenemedi',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refreshNews,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Haber bulunamadı."));
          }

          final news = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ), // Bottom padding for FAB/Nav
            itemCount: news.length,
            itemBuilder: (context, index) {
              final item = news[index];
              final date = item.pubDate != null
                  ? DateFormat('dd MMM HH:mm', 'tr_TR').format(item.pubDate!)
                  : '';

              return Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: InkWell(
                  onTap: () =>
                      item.link != null ? _launchUrl(item.link!) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title ?? 'Başlıksız',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (date.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                date,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.source?.value ?? 'Finans Haberleri',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
