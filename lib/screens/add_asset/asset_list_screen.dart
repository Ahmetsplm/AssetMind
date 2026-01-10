import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/holding.dart'; // For AssetType
import '../../models/favorite.dart';
import '../../providers/favorite_provider.dart';
import 'add_transaction_screen.dart';
import '../../widgets/skeleton_list_item.dart';
import '../../widgets/animated_price_widget.dart';
import '../../widgets/tech_analysis_button.dart';

class AssetListScreen extends StatefulWidget {
  final AssetType type;
  const AssetListScreen({super.key, required this.type});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _filteredAssets = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  Timer? _debounce;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _searchController.addListener(_onSearchChanged);

    // Auto-Refresh for live updates
    if (widget.type == AssetType.CRYPTO) {
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadAssets(),
      );
    } else if (widget.type == AssetType.STOCK ||
        widget.type == AssetType.FOREX ||
        widget.type == AssetType.GOLD) {
      // Slower refresh for others
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _loadAssets(),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    final data = await _api.getAssetsByType(widget.type);
    if (mounted) {
      setState(() {
        _assets = data;
        // Re-apply filter if searching
        if (_searchController.text.isNotEmpty) {
          final query = _searchController.text.toLowerCase();
          _filteredAssets = _assets.where((item) {
            final symbol = item['symbol'].toString().toLowerCase();
            final name = item['name'].toString().toLowerCase();
            return symbol.contains(query) || name.contains(query);
          }).toList();
        } else {
          _filteredAssets = data;
        }
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredAssets = _assets.where((item) {
          final symbol = item['symbol'].toString().toLowerCase();
          final name = item['name'].toString().toLowerCase();
          return symbol.contains(query) || name.contains(query);
        }).toList();
      });
    });
  }

  String _getTitle() {
    switch (widget.type) {
      case AssetType.STOCK:
        return 'Türk Hisse Senetleri';
      case AssetType.GOLD:
        return 'Değerli Madenler';
      case AssetType.CRYPTO:
        return 'Kripto Para';
      case AssetType.FOREX:
        return 'Döviz';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                decoration: InputDecoration(
                  hintText: 'Varlık ara...',
                  hintStyle: GoogleFonts.poppins(
                    color: Theme.of(context).disabledColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 8,
                    ),
                    itemCount: 10,
                    separatorBuilder: (_, __) => const SizedBox(height: 0),
                    itemBuilder: (_, __) => const SkeletonListItem(),
                  )
                : AnimationLimiter(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _filteredAssets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _filteredAssets[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildListItem(context, item),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // Warning Banner
          if (widget.type != AssetType.CRYPTO)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).cardColor,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Piyasa verileri 15 dakika gecikmeli olabilir.",
                        style: GoogleFonts.poppins(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> item) {
    final change = item['change'] as double;
    final isUp = change >= 0;
    final trendColor = isUp ? Colors.green : Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          _openTransactionSheet(item);
        },
        leading: Consumer<FavoriteProvider>(
          builder: (context, provider, child) {
            final isFav = provider.isFavorite(item['symbol']);
            return IconButton(
              icon: Icon(
                isFav ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFav
                    ? const Color(0xFFFFB300)
                    : Theme.of(context).disabledColor,
                size: 28,
              ),
              onPressed: () {
                provider.toggleFavorite(
                  Favorite(symbol: item['symbol'], type: widget.type),
                );
              },
            );
          },
        ),
        title: Text(
          item['symbol'],
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          item['name'] ?? '',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedPriceWidget(
                  numericValue: (item['price'] as num).toDouble(),
                  displayString:
                      '₺${(item['price'] as num).toDouble().toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '%${change.abs().toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            TechAnalysisButton(symbol: item['symbol'], type: widget.type),
          ],
        ),
      ),
    );
  }

  void _openTransactionSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => AddTransactionScreen(
          symbol: item['symbol'],
          name: item['name'],
          initialPrice: (item['price'] as num).toDouble(),
          type: widget.type,
        ),
      ),
    );
  }
}
