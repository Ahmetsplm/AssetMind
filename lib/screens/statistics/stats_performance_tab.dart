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
          return const Center(child: Text("Veri Yok"));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(
              context,
              provider,
              "🏆 En İyi Performans",
              bestList.take(5).toList(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              provider,
              "📉 En Kötü Performans",
              worstList.take(5).toList(),
            ),
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
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final h = item['holding'] as Holding;
          final profit = item['profit'] as double;
          final percent = item['percent'] as double;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (percent >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (percent >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    "#${index + 1}",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: percent >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
              title: Text(
                h.symbol,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                h.type.name.toUpperCase(),
                style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 1, color: Theme.of(context).disabledColor),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(symbol: provider.currencySymbol).format(profit / provider.getConversionRate()),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (percent >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${percent >= 0 ? '+' : ''}${percent.toStringAsFixed(2)}%",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: percent >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
