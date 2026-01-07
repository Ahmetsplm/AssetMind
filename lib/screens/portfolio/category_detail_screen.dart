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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
            padding: const EdgeInsets.all(16),
            children: [
              if (activeHoldings.isEmpty && closedHoldings.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text("Bu kategoride varlık bulunmuyor."),
                  ),
                ),

              ...activeHoldings.map(
                (h) => _buildHoldingItem(context, h, provider),
              ),

              if (closedHoldings.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "Kapanan Pozisyonlar",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 8),
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
        label: const Text(
          "Yeni Varlık Ekle",
          style: TextStyle(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildHoldingItem(
    BuildContext context,
    Holding holding,
    PortfolioProvider provider, {
    bool isClosed = false,
  }) {
    // Need current price for calc
    // In a real app we'd map this better, but let's access via provider helper or api
    // Simply recalculate here for display
    // Note: Provider doesn't expose price map directly publicly easily but we can access via holding extensions if we did that
    // Or just look up from provider if we expose it.
    // Let's assume provider has loaded prices.

    // For now, since we don't have public access to price map in provider easily without getter,
    // let's rely on cached avgCost if closed, or fetch via a hacked way or update provider.
    // Actually, let's just use what we have.
    // IF active, we want Current Value.
    // We can assume loadHoldings fetched prices.

    // Quick fix: Add public lookup to provider or calculate P/L
    // Since we can't easily change provider signature mid-build without planning,
    // let's assume we can calculate a rough Estimate or use avgCost as placeholder if price missing.
    // Ideally we should have `currentPrice` on the Holding model or updated in memory.

    // Let's USE Average Cost as Current Price for Closed positions (P/L is realized).
    // For Active, we normally need the price map.

    // Workaround: We will update PortfolioProvider to expose price helper or just ignore live price update here for a second
    // but the prompt demands it.
    // Actually `PortfolioProvider` has `_assetPrices` but it's private.
    // Let's pretend we can't see live price for a second or...

    // Better: I'll use a standard ListTile and user can click to see details.
    // OR: I can modify Provider to check price.

    return Card(
      elevation: 0,
      color: isClosed ? Colors.grey[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssetDetailScreen(holding: holding),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isClosed ? Colors.grey[300] : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            holding.symbol.substring(0, 1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isClosed ? Colors.grey : const Color(0xFF1A237E),
            ),
          ),
        ),
        title: Text(
          holding.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(isClosed ? "Kapandı" : "${holding.quantity} Adet"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Active: Show Current Value (Qty * CurrentPrice)
            // Closed: Show Profit/Loss (Total Realized) because qty is 0
            if (!isClosed) ...[
              Builder(
                builder: (context) {
                  double curPrice = provider.getCurrentPrice(holding.symbol);
                  if (curPrice == 0) curPrice = holding.averageCost;
                  final val = holding.quantity * curPrice;

                  return Text(
                    '₺${NumberFormat('#,##0.00', 'tr_TR').format(val)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ] else ...[
              // For Closed, the quantity is 0, so cost/val is 0. Show Realized Profit as main stat?
              // Or just keep the subtitle.
              Text(
                'Kâr: ₺${NumberFormat('#,##0.00', 'tr_TR').format(holding.totalRealizedProfit)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
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
