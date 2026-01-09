import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/favorite_provider.dart';
import '../providers/market_provider.dart';
import '../models/favorite.dart';
import '../models/holding.dart'; // For AssetType
import 'add_asset/asset_list_screen.dart'; // For Navigation

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
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Piyasalar',
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black87),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              _buildCategorySelector(context),
              Expanded(child: _buildSummaryView()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final categories = ['Özet', 'BIST', 'Kripto', 'Döviz'];
    return SizedBox(
      height: 50, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index && index == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 12), // Reduced padding
            child: InkWell(
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
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ), // Generous padding
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25),
                ),
                alignment: Alignment.center,
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
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

  Widget _buildSummaryView() {
    final api = ApiService();
    final summaryData = api.getMarketSummarySync();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: summaryData.length,
                itemBuilder: (context, index) {
                  final item = summaryData[index];
                  return _buildMarketCard(item);
                },
              ),
            ),
          ),

          _buildMoversSection(
            title: 'Piyasa Hareketleri - BIST',
            isRising: _isStockRising,
            onToggle: (val) => setState(() => _isStockRising = val),
            data: api.getStockMoversSync(isRising: _isStockRising),
            type: AssetType.STOCK,
          ),

          const SizedBox(height: 20),

          _buildMoversSection(
            title: 'Piyasa Hareketleri - Kripto',
            isRising: _isCryptoRising,
            onToggle: (val) => setState(() => _isCryptoRising = val),
            data: api.getCryptoMoversSync(isRising: _isCryptoRising),
            isCrypto: true,
            type: AssetType.CRYPTO,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  AssetType _determineTypeFromSummary(String symbol) {
    if (symbol.contains('Altın')) return AssetType.GOLD;
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
    if (displaySymbol == 'Gram Altın') return 'GRAM';
    return displaySymbol;
  }

  Widget _buildMarketCard(Map<String, dynamic> item) {
    final bool isUp = item['is_rising'];
    final Color color = isUp ? Colors.green : Colors.red;
    final symbol =
        item['symbol'] as String; // e.g. "Dolar", "Gram Altın", "BIST 100"

    // Use canonical symbol for matching in Favorites database
    final mappedSymbol = _getCanonicalSymbol(symbol);
    final type = _determineTypeFromSummary(symbol);

    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFav = favoriteProvider.isFavorite(mappedSymbol);

        return Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black54,
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
                      isFav ? Icons.star : Icons.star_border,
                      size: 20,
                      color: isFav ? Colors.amber : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['value'].toString(), // It's already formatted String
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isUp ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '%${item['change_rate']}', // Already formatted String
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoversSection({
    required String title,
    required bool isRising,
    required Function(bool) onToggle,
    required List<Map<String, dynamic>> data, // Changed from Future to List
    bool isCrypto = false,
    required AssetType type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildToggleButton('Yükselen', isRising, () => onToggle(true)),
              const SizedBox(width: 12),
              _buildToggleButton('Düşen', !isRising, () => onToggle(false)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // No FutureBuilder!
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.length,
          itemBuilder: (context, index) {
            return _buildListItem(data[index], isCrypto, type);
          },
        ),
      ],
    );
  }

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: Colors.grey.shade300) : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(
    Map<String, dynamic> item,
    bool isCrypto,
    AssetType type,
  ) {
    // New API keys: price(String), change(String), raw_change(double), time(String)
    final double rawChange = item['raw_change']; // Use raw for logic
    final bool isUp = rawChange >= 0;
    final symbol = item['symbol'] as String;
    final String timeStr = item['time'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCrypto ? Icons.currency_bitcoin : Icons.show_chart,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  timeStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['price'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUp ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '%${item['change']}',
                  style: TextStyle(
                    color: isUp ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
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
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.amber : Colors.grey[400],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderView() {
    return const Center(child: Text('Bu liste yakında eklenecek.'));
  }
}
