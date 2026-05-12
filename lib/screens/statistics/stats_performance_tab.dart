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
        final holdings =
            provider.holdings.where((h) => h.quantity > 0).toList();

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

        final bestList = [...performanceData]..sort(
            (a, b) =>
                (b['percent'] as double).compareTo(a['percent'] as double),
          );

        final worstList = [...performanceData]..sort(
            (a, b) =>
                (a['percent'] as double).compareTo(b['percent'] as double),
          );

        if (holdings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart_rounded, size: 64, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                Text("Veri Bulunmuyor", style: GoogleFonts.outfit(color: Theme.of(context).disabledColor)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              context,
              provider,
              "🏆 EN İYİ PERFORMANS",
              bestList.take(5).toList(),
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              provider,
              "📉 EN KÖTÜ PERFORMANS",
              worstList.take(5).toList(),
            ),
            const SizedBox(height: 120), // Padding for nav
          ],
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    PortfolioProvider provider,
    String title,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
        ...items.map((item) {
          final h = item['holding'] as Holding;
          final profit = item['profit'] as double;
          final percent = item['percent'] as double;
          final price = item['price'] as double;
          final isUp = profit >= 0;
          final trendColor = isUp ? Colors.greenAccent : Colors.redAccent;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: trendColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.symbol,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "₺${price.toStringAsFixed(2)}",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isUp ? '+' : ''}₺${NumberFormat('#,##0.00', 'tr_TR').format(profit)}",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: trendColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${isUp ? '+' : ''}%${percent.toStringAsFixed(2)}",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
