import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/holding.dart'; // For AssetType
import '../../models/favorite.dart';
import '../../providers/favorite_provider.dart';
import 'add_transaction_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    final data = await _api.getAssetsByType(widget.type);
    if (mounted) {
      setState(() {
        _assets = data;
        _filteredAssets = data;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAssets = _assets.where((item) {
        final symbol = item['symbol'].toString().toLowerCase();
        final name = item['name'].toString().toLowerCase();
        return symbol.contains(query) || name.contains(query);
      }).toList();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _filteredAssets.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _filteredAssets[index];
                      return _buildListItem(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item) {
    final change = item['change'] as double;
    final isUp = change >= 0;

    return ListTile(
      onTap: () {
        _openTransactionSheet(item);
      },
      leading: Consumer<FavoriteProvider>(
        builder: (context, provider, child) {
          final isFav = provider.isFavorite(item['symbol']);
          return IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_border,
              color: isFav ? Colors.amber : Colors.grey[400],
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
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(item['name'] ?? ''),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₺${item['price']}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isUp
                  ? Colors.green.withAlpha(30)
                  : Colors.red.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '%${change.abs()}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isUp ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
          scrollController: controller,
        ),
      ),
    );
  }
}
