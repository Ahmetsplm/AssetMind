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

  // Refresh data when the tab is visible or provider changes
  // Ideally we would listen to provider, but fetching market data on every toggle might be heavy.
  // For now, let's re-fetch if the list size changes significantly or rely on polling.
  // Simplified for this step: We use a FutureBuilder or just re-fetch in build if new symbols appear.
  // Better approach: Listen to provider, if new symbol appears in favorites that is not in _marketData, fetch it.

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final favorites = favoriteProvider.favorites;

        // Simple logic: if we have symbols without data, fetch data (lazy load)
        // This is a bit rough but works for this stage.
        final missingData = favorites.any(
          (f) => !_marketData.containsKey(f.symbol),
        );
        if (missingData && !_isLoading) {
          // Trigger fetch
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
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Favoriler',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Test button removed as requested
          ),
          body: favorites.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(favorites),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Henüz takip ettiğiniz\nbir varlık yok.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<Favorite> favorites) {
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

    // Note: display item.symbol might still be "USD" if it was old, but we mapped data in API service.
    // _buildListItem uses item.symbol to fetch data. ApiService handles "USD".
    // Perfect.

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (xu100 != null) _buildSpecialCard(xu100),

        if (stocks.isNotEmpty) ...[
          _buildSectionHeader('Hisse Senetleri'),
          ...stocks.map(_buildListItem),
        ],

        if (gold.isNotEmpty) ...[
          _buildSectionHeader('Kıymetli Madenler'),
          ...gold.map(_buildListItem),
        ],

        if (forex.isNotEmpty) ...[
          _buildSectionHeader('Döviz'),
          ...forex.map(_buildListItem),
        ],

        if (crypto.isNotEmpty) ...[
          _buildSectionHeader('Kripto Paralar'),
          ...crypto.map(_buildListItem),
        ],
      ],
    );
  }

  Widget _buildSpecialCard(Favorite item) {
    final data =
        _marketData[item.symbol] ?? {'price': '0.00', 'change_rate': 0.0};
    final change = (data['change_rate'] as num).toDouble();
    final isUp = change >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Endeks',
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUp ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '%${change.abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Favorite item) {
    final data =
        _marketData[item.symbol] ?? {'price': '0.00', 'change_rate': 0.0};
    final change = (data['change_rate'] as num).toDouble();
    final isUp = change >= 0;

    // Time Logic
    String timeStr;
    final now = DateTime.now();
    if (item.type == AssetType.CRYPTO) {
      timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    } else {
      // Stock, Gold, Forex -> 15 min delay simulation
      final delayed = now.subtract(const Duration(minutes: 15));
      timeStr =
          "${delayed.hour.toString().padLeft(2, '0')}:${delayed.minute.toString().padLeft(2, '0')}:${delayed.second.toString().padLeft(2, '0')}";
    }

    // Icon Logic
    IconData icon;
    if (item.type == AssetType.CRYPTO)
      icon = Icons.currency_bitcoin;
    else if (item.type == AssetType.FOREX)
      icon = Icons.attach_money;
    else if (item.type == AssetType.GOLD)
      icon = Icons.diamond;
    else
      icon = Icons.show_chart; // Stock

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1A237E), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.symbol,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Veri: $timeStr',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
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
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUp ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '%${change.abs().toStringAsFixed(2)}', // Fixed Decimals
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
                icon: Icon(
                  Icons.star,
                  color: Colors.amber,
                ), // Always amber in favorites screen
                onPressed: () {
                  provider.toggleFavorite(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.symbol} favorilerden çıkarıldı'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 22,
              );
            },
          ),
        ],
      ),
    );
  }
}
