import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/holding.dart';

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

              const SizedBox(height: 32),

              // Pie Chart Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Text(
                      "KATEGORİ DAĞILIMI",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: _buildChartSections(provider),
                              centerSpaceRadius: 65,
                              sectionsSpace: 4,
                              startDegreeOffset: -90,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "AKTİF",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).disabledColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                "${_countActiveCategories(provider)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Legend
                    _buildLegend(context, provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

  int _countActiveCategories(PortfolioProvider provider) {
    int count = 0;
    if (provider.getCountByType(AssetType.STOCK) > 0) count++;
    if (provider.getCountByType(AssetType.CRYPTO) > 0) count++;
    if (provider.getCountByType(AssetType.GOLD) > 0) count++;
    if (provider.getCountByType(AssetType.FOREX) > 0) count++;
    return count;
  }

  List<PieChartSectionData> _buildChartSections(PortfolioProvider provider) {
    List<PieChartSectionData> sections = [];
    final total = provider.displayedTotalValue;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.withValues(alpha: 0.1),
          showTitle: false,
        ),
      ];
    }

    void addSection(AssetType type, Color color) {
      final val = provider.getValueByType(type);
      if (val > 0) {
        sections.add(
          PieChartSectionData(
            color: color,
            value: val,
            radius: 25,
            showTitle: false,
          ),
        );
      }
    }

    addSection(AssetType.STOCK, const Color(0xFF4285F4));
    addSection(AssetType.GOLD, const Color(0xFFEA4335));
    addSection(AssetType.CRYPTO, const Color(0xFFFBBC05));
    addSection(AssetType.FOREX, const Color(0xFF34A853));

    return sections;
  }

  Widget _buildLegend(BuildContext context, PortfolioProvider provider) {
    final total = provider.displayedTotalValue;

    Widget item(String text, double val, Color color) {
      if (val <= 0) return const SizedBox.shrink();
      final percent = (val / total) * 100;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: GoogleFonts.poppins(fontSize: 12)),
            ),
            Text(
              "%${percent.toStringAsFixed(1)}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        item(
          "Türk Hisse Senetleri",
          provider.getValueByType(AssetType.STOCK),
          const Color(0xFF4285F4),
        ),
        item(
          "Değerli Madenler",
          provider.getValueByType(AssetType.GOLD),
          const Color(0xFFEA4335),
        ),
        item(
          "Kripto Para",
          provider.getValueByType(AssetType.CRYPTO),
          const Color(0xFFFBBC05),
        ),
        item(
          "Döviz",
          provider.getValueByType(AssetType.FOREX),
          const Color(0xFF34A853),
        ),
      ],
    );
  }
}
