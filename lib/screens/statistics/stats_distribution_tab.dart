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
          padding: const EdgeInsets.all(20),
          itemCount: distData.length,
          itemBuilder: (context, index) {
            final item = distData[index];
            final h = item['holding'] as Holding;
            final percent = item['percent'] as double;
            // final value = item['value'] as double;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            h.type.name, // Or formatted name
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "%${percent.toStringAsFixed(1)}",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForIndex(index, context),
                      ),
                      minHeight: 8,
                    ),
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
