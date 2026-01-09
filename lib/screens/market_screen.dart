import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/favorite_provider.dart';
import '../providers/market_provider.dart';
import '../models/favorite.dart';
import '../models/holding.dart'; // For AssetType
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'add_asset/asset_list_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _selectedCategoryIndex = 0; // 0: Özet, 1: BIST, 2: Kripto, 3: Döviz
  bool _isStockRising = true;
  bool _isCryptoRising = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketProvider>(
      builder: (context, marketProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(context),
          body: _buildBody(context),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Piyasalar',
        style: GoogleFonts.poppins(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).iconTheme.color,
            size: 28,
          ),
          onPressed: () {
            // Future search implementation
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final api = ApiService();
    // In a real app, this should be async/future builder or from provider
    // Using Sync here as per existing pattern
    final summaryData = api.getMarketSummarySync();

    return AnimationLimiter(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Category Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildCategorySelector(context),
            ),
          ),

          // Horizontal Summary List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SizedBox(
                height: 150, // Slightly taller for premium look
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: summaryData.length,
                  itemBuilder: (context, index) {
                    final item = summaryData[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildMarketCard(context, item),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // BIST Movers Header
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context,
              'BIST 100', // Cleaner title
              'Piyasa Hareketleri',
              _isStockRising,
              (val) => setState(() => _isStockRising = val),
            ),
          ),

          // BIST Movers List (Sliver)
          _buildSliverList(
            context,
            api.getStockMoversSync(isRising: _isStockRising),
            false,
            AssetType.STOCK,
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 24)),

          // Crypto Movers Header
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context,
              'Kripto Para',
              'Anlık Değişimler',
              _isCryptoRising,
              (val) => setState(() => _isCryptoRising = val),
            ),
          ),

          // Crypto Movers List (Sliver)
          _buildSliverList(
            context,
            api.getCryptoMoversSync(isRising: _isCryptoRising),
            true,
            AssetType.CRYPTO,
          ),

          SliverToBoxAdapter(child: const SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
    bool isRising,
    Function(bool) onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  context,
                  'Yükselen',
                  isRising,
                  () => onToggle(true),
                  Colors.green,
                ),
                _buildToggleButton(
                  context,
                  'Düşen',
                  !isRising,
                  () => onToggle(false),
                  Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context,
    String text,
    bool isActive,
    VoidCallback onTap,
    Color activeColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isActive
                ? activeColor
                : Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.5),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverList(
    BuildContext context,
    List<Map<String, dynamic>> data,
    bool isCrypto,
    AssetType type,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildListItem(context, data[index], isCrypto, type),
              ),
            ),
          );
        }, childCount: data.length),
      ),
    );
  }

  AssetType _determineTypeFromSummary(String symbol) {
    if (symbol.contains('Altın') ||
        symbol.contains('Gümüş') ||
        symbol.contains('Platin') ||
        symbol.contains('Paladyum') ||
        symbol == 'GRAM')
      return AssetType.GOLD;
    if (symbol.contains('Dolar') ||
        symbol.contains('Euro') ||
        symbol.contains('USD') ||
        symbol.contains('EUR'))
      return AssetType.FOREX;
    return AssetType.STOCK;
  }

  String _getCanonicalSymbol(String displaySymbol) {
    if (displaySymbol == 'BIST 100') return 'XU100';
    if (displaySymbol == 'Dolar') return 'USD/TRY';
    if (displaySymbol == 'Euro') return 'EUR/TRY';
    return displaySymbol;
  }

  Widget _buildMarketCard(BuildContext context, Map<String, dynamic> item) {
    final bool isUp = item['is_rising'];
    final Color trendColor = isUp ? Colors.green : Colors.red;
    final symbol = item['symbol'] as String;

    final mappedSymbol = _getCanonicalSymbol(symbol);
    final type = _determineTypeFromSummary(symbol);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFav = favoriteProvider.isFavorite(mappedSymbol);

        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            // Slight gradient for depth
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8F9FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: isDark ? Border.all(color: Colors.white10) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      symbol,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      favoriteProvider.toggleFavorite(
                        Favorite(symbol: mappedSymbol, type: type),
                      );
                    },
                    child: Icon(
                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 22,
                      color: isFav
                          ? const Color(0xFFFFB300)
                          : Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['value'].toString(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: trendColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '%${item['change_rate']}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final categories = ['Özet', 'BIST', 'Kripto', 'Döviz'];
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index && index == 0;

          Color bgColor = isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor;
          Color textColor = isSelected
              ? Colors.white
              : Theme.of(context).textTheme.bodyMedium!.color!;

          if (!isSelected) {
            // Slight differentiation for non-selected
            bgColor = Theme.of(context).dividerColor.withOpacity(0.1);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                if (index == 0) {
                  setState(() => _selectedCategoryIndex = 0);
                } else {
                  AssetType type;
                  if (index == 1)
                    type = AssetType.STOCK;
                  else if (index == 2)
                    type = AssetType.CRYPTO;
                  else
                    type = AssetType.FOREX;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssetListScreen(type: type),
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(25),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.1),
                        ),
                ),
                alignment: Alignment.center,
                child: Text(
                  categories[index],
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    Map<String, dynamic> item,
    bool isCrypto,
    AssetType type,
  ) {
    final double rawChange = item['raw_change'];
    final bool isUp = rawChange >= 0;
    final symbol = item['symbol'] as String;
    final String timeStr = item['time'] ?? '';

    final trendColor = isUp ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCrypto
                  ? const Color(0xFFFBBC05).withOpacity(0.1)
                  : const Color(0xFF4285F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCrypto
                  ? Icons.currency_bitcoin_rounded
                  : Icons.show_chart_rounded,
              color: isCrypto
                  ? const Color(0xFFFBBC05)
                  : const Color(0xFF4285F4),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: GoogleFonts.poppins(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['price'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '%${item['change']}',
                  style: GoogleFonts.poppins(
                    color: trendColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Consumer<FavoriteProvider>(
            builder: (context, favoriteProvider, child) {
              final isFav = favoriteProvider.isFavorite(symbol);
              return GestureDetector(
                onTap: () {
                  favoriteProvider.toggleFavorite(
                    Favorite(symbol: symbol, type: type),
                  );
                },
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav
                      ? const Color(0xFFFFB300)
                      : Theme.of(context).disabledColor,
                  size: 24,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
