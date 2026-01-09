import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/favorite.dart';
import '../models/holding.dart'; // For AssetType enum
import '../services/api_service.dart';
import '../providers/favorite_provider.dart';

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
    final gold = uniqueFavorites
        .where((f) => f.type == AssetType.GOLD)
        .toList();
    final forex = uniqueFavorites
        .where((f) => f.type == AssetType.FOREX)
        .toList();
    final crypto = uniqueFavorites
        .where((f) => f.type == AssetType.CRYPTO)
        .toList();

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
      ],
    );
  }

  Widget _buildSpecialCard(BuildContext context, Favorite item) {
    final data =
        _marketData[item.symbol] ?? {'price': '0.00', 'change_rate': 0.0};
    final change = (data['change_rate'] as num).toDouble();
    final isUp = change >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Borsa İstanbul Endeksi',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data['price']}',
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
                      ? Colors.greenAccent.withOpacity(0.2)
                      : Colors.redAccent.withOpacity(0.2),
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
                      '%${change.abs().toStringAsFixed(2)}',
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
              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
    final data =
        _marketData[item.symbol] ?? {'price': '0.00', 'change_rate': 0.0};
    final change = (data['change_rate'] as num).toDouble();
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
    } else {
      icon = Icons.show_chart_rounded; // Stock
      iconColor = const Color(0xFF4285F4);
    }

    // Brighten color for dark mode readiness
    // Using base colors is fine as they are vibrant

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
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
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${data['price']}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUp
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '%${change.abs().toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    color: isUp ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Action Button
          Consumer<FavoriteProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(Icons.star_rounded, color: const Color(0xFFFFB300)),
                onPressed: () {
                  provider.toggleFavorite(item);
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
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 24,
              );
            },
          ),
        ],
      ),
    );
  }
}
