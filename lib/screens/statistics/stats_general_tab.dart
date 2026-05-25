import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../services/portfolio_analyzer.dart';

class StatsGeneralTab extends StatelessWidget {
  const StatsGeneralTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final totalValue = provider.displayedTotalValue;
        final totalPL = provider.displayedTotalProfitLoss;
        // final plRate = provider.totalProfitLossRate; // Not used in this layout
        final currencySymbol = provider.currencySymbol;
        final isProfit = totalPL >= 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Summary Grid (4 Cards)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1, // Adjusted to prevent bottom overflow
                children: [
                  _buildSummaryCard(
                    context,
                    icon: Icons.pie_chart_rounded,
                    iconColor: Colors.blueGrey,
                    value:
                        '$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(totalValue)}',
                    label: "Toplam Değer",
                  ),
                  _buildSummaryCard(
                    context,
                    icon: isProfit
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    iconColor: isProfit ? Colors.green : Colors.red,
                    iconData: isProfit
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    value:
                        '${isProfit ? '+' : ''}$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(totalPL)}',
                    label: "Toplam Değişim",
                    valueColor: isProfit ? Colors.green : Colors.red,
                  ),
                  _buildSummaryCard(
                    context,
                    icon: Icons.bar_chart_rounded,
                    iconColor: Colors.blue,
                    value: "${provider.activeHoldingsCount}",
                    label: "Benzersiz Varlık",
                  ),
                  _buildSummaryCard(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    iconColor: Colors.orange,
                    value: "${provider.allTransactions.length}",
                    label: "Toplam İşlem",
                  ),
                ],
              ),

              const SizedBox(height: 16),
              _buildRealizedProfitBanner(context, provider.displayedTotalRealizedProfit, currencySymbol),
              const SizedBox(height: 32),

              // Detailed Analysis Summary Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).cardColor,
                      Theme.of(context).cardColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SEKTÖREL DAĞILIM",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        Icon(Icons.info_outline_rounded, size: 16, color: Theme.of(context).disabledColor),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectorsView(context, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectorsView(BuildContext context, PortfolioProvider provider) {
    final prices = <String, double>{};
    for (var h in provider.holdings) {
      prices[h.symbol] = provider.getCurrentPrice(h.symbol);
    }

    final result = PortfolioAnalyzer.analyze(provider.holdings, prices);
    final total = provider.displayedTotalValue;

    if (result.sectorDistribution.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 48, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text("Henüz veri bulunmuyor", style: GoogleFonts.inter(color: Theme.of(context).disabledColor)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 55,
              sections: result.sectorDistribution.entries.map((e) {
                return PieChartSectionData(
                  color: _getSectorColor(e.key),
                  value: e.value,
                  radius: 20,
                  showTitle: false,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Grouped Legend
        ...result.sectorDistribution.entries.map((e) {
          final percentage = (e.value / total) * 100;
          final sectorColor = _getSectorColor(e.key);
          
          // Get assets in this sector
          final sectorAssets = provider.holdings.where((h) {
            if (h.quantity <= 0) return false;
            return PortfolioAnalyzer.getMetadata(h.symbol, h.type).sector == e.key;
          }).map((h) => h.symbol).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sectorColor.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sectorColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: sectorColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.key,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "%${percentage.toStringAsFixed(1)}",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: sectorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 22),
                    Expanded(
                      child: Text(
                        sectorAssets.join(", "),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context).disabledColor,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Color _getSectorColor(String sector) {
    switch (sector) {
      case 'Kripto': return Colors.deepPurpleAccent;
      case 'Emtia': return Colors.amberAccent;
      case 'Döviz': return Colors.greenAccent;
      case 'Küresel Teknoloji': return Colors.blueAccent;
      case 'Banka': return Colors.indigoAccent;
      case 'Enerji': return Colors.orangeAccent;
      case 'Havacılık/Ulaşım': return Colors.lightBlueAccent;
      case 'Teknoloji': return Colors.cyanAccent;
      case 'Holding': return Colors.brown;
      case 'Perakende/Gıda': return Colors.pinkAccent;
      case 'Otomotiv': return Colors.redAccent;
      default: return Colors.blueGrey;
    }
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    IconData? iconData,
    required Color iconColor,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(iconData ?? icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11, 
              color: Theme.of(context).disabledColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRealizedProfitBanner(BuildContext context, double realizedProfit, String currencySymbol) {
    final isProfit = realizedProfit >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: (isProfit ? Colors.green : Colors.red).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isProfit ? Colors.green : Colors.red).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: isProfit ? Colors.green : Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Realize Kâr (Kapananlar)",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Theme.of(context).disabledColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isProfit ? '+' : ''}$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(realizedProfit)}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isProfit ? Colors.green : Colors.red,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
