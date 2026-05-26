import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/holding.dart';
import '../../services/api_service.dart';

class StatsDistributionTab extends StatelessWidget {
  const StatsDistributionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        // Calculate data
        final holdings =
            provider.holdings.where((h) => h.quantity > 0).toList();
            
        double realTotalValue = 0.0;
        for (var h in holdings) {
          double val = h.quantity * provider.getCurrentPrice(h.symbol);
          if (h.type == AssetType.CRYPTO || h.type == AssetType.GLOBAL) {
            val *= ApiService().usdTryRate;
          }
          realTotalValue += val;
        }

        final List<Map<String, dynamic>> distData = holdings.map((h) {
          final price = provider.getCurrentPrice(h.symbol);
          double val = h.quantity * price;
          double cost = h.quantity * h.averageCost;
          if (h.type == AssetType.CRYPTO || h.type == AssetType.GLOBAL) {
            val *= ApiService().usdTryRate;
            cost *= ApiService().usdTryRate;
          }
          final profit = val - cost;
          final profitPercent = cost > 0 ? (profit / cost) * 100 : 0.0;
          final percent = realTotalValue > 0 ? (val / realTotalValue) * 100 : 0.0;
          return {
            'holding': h,
            'percent': percent, // 0-100
            'value': val,
            'profit': profit,
            'profitPercent': profitPercent,
          };
        }).toList();

        // Sort Highest % first
        distData.sort(
          (a, b) => (b['percent'] as double).compareTo(a['percent'] as double),
        );

        if (holdings.isEmpty) {
          return const Center(child: Text("Veri Yok"));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          itemCount: distData.length,
          itemBuilder: (context, index) {
            final item = distData[index];
            final h = item['holding'] as Holding;
            final percent = item['percent'] as double;
            final val = item['value'] as double;
            final profit = item['profit'] as double;
            final profitPercent = item['profitPercent'] as double;
            final isProfit = profit >= 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.symbol,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            h.type.name.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              letterSpacing: 1,
                              color: Theme.of(context).disabledColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getColorForIndex(index, context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "%${percent.toStringAsFixed(2)}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _getColorForIndex(index, context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${val.toStringAsFixed(2)} ₺",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: isProfit ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${profit.abs().toStringAsFixed(2)} ₺ (%${profitPercent.abs().toStringAsFixed(2)})",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isProfit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 8,
                        width: (MediaQuery.of(context).size.width - 80) * (percent / 100),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getColorForIndex(index, context),
                              _getColorForIndex(index, context).withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: _getColorForIndex(index, context).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
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
      },
    );
  }

  Color _getColorForIndex(int index, BuildContext context) {
    // Just cycle through some colors or use a consistent palette
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}
