import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/holding.dart';

class StatsDistributionTab extends StatelessWidget {
  const StatsDistributionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final totalValue = provider.displayedTotalValue;

        // Calculate data
        final holdings =
            provider.holdings.where((h) => h.quantity > 0).toList();
        final List<Map<String, dynamic>> distData = holdings.map((h) {
          final price = provider.getCurrentPrice(h.symbol);
          final val = h.quantity * price;
          final percent = totalValue > 0 ? (val / totalValue) * 100 : 0.0;
          return {
            'holding': h,
            'percent': percent, // 0-100
            'value': val,
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
            // final value = item['value'] as double;

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
                          "%${percent.toStringAsFixed(1)}",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: _getColorForIndex(index, context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
