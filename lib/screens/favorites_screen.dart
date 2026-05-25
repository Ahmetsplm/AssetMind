import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/favorite.dart';
import '../models/holding.dart'; // For AssetType enum
import '../services/api_service.dart';
import 'home_screen.dart';
import 'settings/alerts_screen.dart';
import '../providers/favorite_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/animated_price_widget.dart';
import '../widgets/alert_bottom_sheet.dart';
import 'trading_view_screen.dart';
import 'package:shimmer/shimmer.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _api = ApiService();
  Map<String, Map<String, dynamic>> _marketData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  Future<void> _fetchMarketData() async {
    if (!mounted) return;

    // We get the list from provider
    final favorites = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    ).favorites;

    // Get dummy market data
    if (favorites.isNotEmpty) {
      final symbols = favorites.map((e) => e.symbol).toList();
      final data = await _api.getFavoritesData(symbols);
      final dataMap = {for (var item in data) item['symbol'] as String: item};

      if (mounted) {
        setState(() {
          _marketData = dataMap;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final favorites = favoriteProvider.favorites;

        // Lazy load logic for simplified fetching
        final missingData = favorites.any(
          (f) => !_marketData.containsKey(f.symbol),
        );
        if (missingData && !_isLoading) {
          _api.getFavoritesData(favorites.map((e) => e.symbol).toList()).then((
            data,
          ) {
            if (mounted) {
              setState(() {
                _marketData = {
                  for (var item in data) item['symbol'] as String: item,
                };
              });
            }
          });
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Favoriler',
              style: GoogleFonts.poppins(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: "Yeni Varlık",
                onPressed: () {
                  HomeScreen.switchTab(context, 2);
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: "Alarmlar",
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen()));
                },
              ),
            ],
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: Theme.of(context).iconTheme,
          ),
          body: favorites.isEmpty
              ? _buildEmptyState(context)
              : _buildFavoritesList(context, favorites),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 80,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz takip ettiğiniz\nbir varlık yok.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Theme.of(context).disabledColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, List<Favorite> favorites) {
    // Deduplicate logic for Display
    final Set<String> seen = {};
    final List<Favorite> uniqueFavorites = [];

    // Helper must match Provider's logic implicitly
    String canonical(String s) {
      if (s == 'USD' || s == 'Dolar') return 'USD/TRY';
      if (s == 'EUR' || s == 'Euro') return 'EUR/TRY';
      if (s == 'Gram Altın') return 'GRAM';
      return s.toUpperCase();
    }

    for (var f in favorites) {
      final key = canonical(f.symbol);
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueFavorites.add(f);
      }
    }

    final xu100 = uniqueFavorites.where((f) => f.symbol == 'XU100').firstOrNull;
    final stocks = uniqueFavorites
        .where((f) => f.type == AssetType.STOCK && f.symbol != 'XU100')
        .toList();
    final gold =
        uniqueFavorites.where((f) => f.type == AssetType.GOLD).toList();
    final forex =
        uniqueFavorites.where((f) => f.type == AssetType.FOREX).toList();
    final crypto =
        uniqueFavorites.where((f) => f.type == AssetType.CRYPTO).toList();
    final global =
        uniqueFavorites.where((f) => f.type == AssetType.GLOBAL).toList();
    final fund =
        uniqueFavorites.where((f) => f.type == AssetType.FUND).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (xu100 != null) _buildSpecialCard(context, xu100),
        if (stocks.isNotEmpty) ...[
          _buildSectionHeader(context, 'Hisse Senetleri'),
          ...stocks.map((f) => _buildListItem(context, f)),
        ],
        if (gold.isNotEmpty) ...[
          _buildSectionHeader(context, 'Kıymetli Madenler'),
          ...gold.map((f) => _buildListItem(context, f)),
        ],
        if (forex.isNotEmpty) ...[
          _buildSectionHeader(context, 'Döviz'),
          ...forex.map((f) => _buildListItem(context, f)),
        ],
        if (crypto.isNotEmpty) ...[
          _buildSectionHeader(context, 'Kripto Paralar'),
          ...crypto.map((f) => _buildListItem(context, f)),
        ],
        if (global.isNotEmpty) ...[
          _buildSectionHeader(context, 'Global Hisseler'),
          ...global.map((f) => _buildListItem(context, f)),
        ],
        if (fund.isNotEmpty) ...[
          _buildSectionHeader(context, 'Yatırım Fonları'),
          ...fund.map((f) => _buildListItem(context, f)),
        ],
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildSpecialCard(BuildContext context, Favorite item) {
    return Consumer<MarketProvider>(
      builder: (context, marketProvider, _) {
        String cacheSym = item.symbol;
        if (item.type == AssetType.STOCK) cacheSym = '${item.symbol}.IS';
        
        final d = marketProvider.getAsset(cacheSym);
        final data = _marketData[item.symbol] ?? {'price': '0.00', 'change_rate': 0.0};
        
        final double currentPrice = d?.price ?? (double.tryParse(data['price'].toString().replaceAll(',', '')) ?? 0.0);
        final double change = d?.change ?? (data['change_rate'] as num).toDouble();
        final isUp = change >= 0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BIST 100',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Borsa İstanbul',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedPriceWidget(
                    numericValue: currentPrice,
                    displayString: '${item.type.getCurrencySymbol(item.symbol)}${currentPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isUp
                          ? Colors.greenAccent.withValues(alpha: 0.2)
                          : Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: isUp ? Colors.greenAccent : Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isUp ? '' : '-'}%${change.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isUp ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Divider(), // Removed divider for cleaner look
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Favorite item) {
    return Consumer<MarketProvider>(
      builder: (context, marketProvider, _) {
        String cacheSym = item.symbol;
        if (item.type == AssetType.STOCK) cacheSym = '${item.symbol}.IS';
        
        final d = marketProvider.getAsset(cacheSym);
        final data = _marketData[item.symbol] ?? {'price': '0.00', 'change_rate': 0.0};
        
        final double currentPrice = d?.price ?? (double.tryParse(data['price'].toString().replaceAll(',', '')) ?? 0.0);
        final double change = d?.change ?? (data['change_rate'] as num).toDouble();
        final isUp = change >= 0;

        // Time Logic (Mock or Real)
        String timeStr;
        final now = DateTime.now();
        // Simplified logic for demo
        if (item.type == AssetType.CRYPTO) {
          timeStr = "${now.hour}:${now.minute}";
        } else {
          timeStr = "15dk Gecikmeli";
        }

        // Icon Logic
        IconData icon;
        Color iconColor;
        if (item.type == AssetType.CRYPTO) {
          icon = Icons.currency_bitcoin_rounded;
          iconColor = const Color(0xFFFBBC05);
        } else if (item.type == AssetType.FOREX) {
          icon = Icons.currency_exchange_rounded;
          iconColor = const Color(0xFF34A853);
        } else if (item.type == AssetType.GOLD) {
          icon = Icons.diamond_outlined;
          iconColor = const Color(0xFFEA4335);
        } else if (item.type == AssetType.GLOBAL) {
          icon = Icons.public_rounded;
          iconColor = const Color(0xFF9C27B0);
        } else if (item.type == AssetType.FUND) {
          icon = Icons.account_balance_rounded;
          iconColor = const Color(0xFF00BCD4);
        } else {
          icon = Icons.show_chart_rounded; // Stock
          iconColor = const Color(0xFF4285F4);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item.symbol == 'USD/TRY')
                          ? 'USD'
                          : (item.symbol == 'EUR/TRY')
                              ? 'EUR'
                              : (item.symbol == 'GRAM')
                                  ? 'Gram Altın'
                                  : (item.symbol == 'CEYREK')
                                      ? 'Çeyrek Altın'
                                      : (item.symbol == 'YARIM')
                                          ? 'Yarım Altın'
                                          : (item.symbol == 'TAM')
                                              ? 'Tam Altın'
                                              : (item.symbol == 'CUMHURIYET')
                                                  ? 'Cumhuriyet Altın'
                                                  : (item.symbol == 'ONS')
                                                      ? 'Ons Altın'
                                                      : item.symbol,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeStr,
                      style: GoogleFonts.poppins(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (currentPrice == 0.0 && item.type == AssetType.FUND)
                    Text(
                      'Veri Güncellenemedi',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else ...[
                    AnimatedPriceWidget(
                      numericValue: currentPrice,
                      displayString: '${item.type.getCurrencySymbol(item.symbol)}${currentPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    currentPrice == 0.0
                        ? Shimmer.fromColors(
                            baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800]! : Colors.grey[300]!,
                            highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[100]!,
                            child: Container(
                              width: 80,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUp
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${isUp ? '' : '-'}%${change.abs().toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                color: isUp ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                  ],
                ],
              ),
              const SizedBox(width: 8),

              // Action Button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'chart') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TradingViewScreen(
                          symbol: item.symbol,
                          type: item.type,
                        ),
                      ),
                    );
                  } else if (value == 'alert') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AlertBottomSheet(
                        symbol: item.symbol,
                        currentPrice: currentPrice,
                        type: item.type,
                      ),
                    );
                  } else if (value == 'remove') {
                    Provider.of<FavoriteProvider>(context, listen: false).toggleFavorite(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                        content: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.symbol} favorilerden çıkarıldı',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'chart',
                    child: Row(
                      children: [
                        const Icon(Icons.candlestick_chart_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text('Grafik', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'alert',
                    child: Row(
                      children: [
                        const Icon(Icons.add_alert_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text('Alarm Kur', style: GoogleFonts.poppins()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 20, color: Color(0xFFFFB300)),
                        const SizedBox(width: 8),
                        Text('Favoriden Çıkar', style: GoogleFonts.poppins()),
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
}
