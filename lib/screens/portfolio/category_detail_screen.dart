import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/holding.dart';
import '../add_asset/asset_list_screen.dart';
import 'asset_detail_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final AssetType type;
  final String title;

  const CategoryDetailScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, provider, child) {
          final allHoldings = provider.getHoldingsByType(type);
          final activeHoldings = allHoldings
              .where((h) => h.quantity > 0)
              .toList();
          final closedHoldings = allHoldings
              .where((h) => h.quantity <= 0)
              .toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (activeHoldings.isEmpty && closedHoldings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.hourglass_empty_rounded,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Bu kategoride varlık bulunmuyor.",
                          style: GoogleFonts.poppins(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ...activeHoldings.map(
                (h) => _buildHoldingItem(context, h, provider),
              ),

              if (closedHoldings.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "Kapanan Pozisyonlar",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Theme.of(context).dividerColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...closedHoldings.map(
                  (h) =>
                      _buildHoldingItem(context, h, provider, isClosed: true),
                ),
              ],

              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Asset List for this type
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AssetListScreen(type: type)),
          );
        },
        label: Text(
          "Yeni Varlık Ekle",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildHoldingItem(
    BuildContext context,
    Holding holding,
    PortfolioProvider provider, {
    bool isClosed = false,
  }) {
    // Current Price Logic Reuse
    double curPrice = 0;
    if (!isClosed) {
      curPrice = provider.getCurrentPrice(holding.symbol);
      if (curPrice == 0) curPrice = holding.averageCost;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isClosed
            ? Theme.of(context).disabledColor.withOpacity(0.05)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isClosed
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: Theme.of(
            context,
          ).dividerColor.withOpacity(isClosed ? 0.05 : 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(holding: holding),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isClosed
                ? Theme.of(context).disabledColor.withOpacity(0.1)
                : Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            holding.symbol.substring(0, 1),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isClosed
                  ? Theme.of(context).disabledColor
                  : Theme.of(context).primaryColor,
            ),
          ),
        ),
        title: Text(
          holding.symbol,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isClosed
                ? Theme.of(context).disabledColor
                : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: Text(
          isClosed ? "Kapandı" : "${holding.quantity} Adet",
          style: GoogleFonts.poppins(
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isClosed) ...[
              Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(holding.quantity * curPrice)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ] else ...[
              Text(
                'Kâr: ₺${NumberFormat('#,##0.00', 'tr_TR').format(holding.totalRealizedProfit)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: holding.totalRealizedProfit >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
