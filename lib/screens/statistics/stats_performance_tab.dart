import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/holding.dart';

class StatsPerformanceTab extends StatelessWidget {
  const StatsPerformanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        // Calculate performance for each holding
        final holdings = provider.holdings
            .where((h) => h.quantity > 0)
            .toList();

        // Map holding to profit info
        final List<Map<String, dynamic>> performanceData = holdings.map((h) {
          final price = provider.getCurrentPrice(h.symbol);
          final currentVal = h.quantity * price;
          final cost = h.quantity * h.averageCost;
          final profit = currentVal - cost;
          final percent = cost > 0 ? (profit / cost) * 100 : 0.0;
          return {
            'holding': h,
            'profit': profit,
            'percent': percent,
            'price': price,
          };
        }).toList();

        // Sort by Percent (Best first)
        final bestList = [...performanceData]
          ..sort(
            (a, b) =>
                (b['percent'] as double).compareTo(a['percent'] as double),
          );

        // Sort by Percent (Worst first - effectively reverse of best, but let's handle explicitly)
        final worstList = [...performanceData]
          ..sort(
            (a, b) =>
                (a['percent'] as double).compareTo(b['percent'] as double),
          );

        if (holdings.isEmpty) {
          return const Center(child: Text("Veri Yok"));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              context,
              "🏆 En İyi Performans",
              bestList.take(5).toList(),
              true,
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              "📉 En Kötü Performans",
              worstList.take(5).toList(),
              false,
            ), // Or just show the bottom 5 of the sorted list? No, explicit worst users usually want to see negative numbers.
          ],
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    bool isBest,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final h = item['holding'] as Holding;
              final profit = item['profit'] as double;
              final percent = item['percent'] as double;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      child: Text(
                        "#${index + 1}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(
                      h.symbol,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      h.type.name, // "STOCK" etc. maybe format nicely?
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          // Simple profit/loss amount
                          // Maybe convert based on provider currency later, but logic is complex here without provider ref.
                          // Just showing raw value for now or maybe formatted string
                          // Let's format clearly
                          NumberFormat.currency(symbol: "₺").format(profit),
                          // Note: This assumes TRY. Ideally should use provider.currencySymbol logic.
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "%${percent.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: percent >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                      height: 1,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
