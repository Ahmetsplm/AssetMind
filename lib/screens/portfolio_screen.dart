import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/holding.dart';
import 'package:intl/intl.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildDashboardCard(context),
              const SizedBox(height: 24),
              const Text(
                'Varlıklarım',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildAssetCategories(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final portfolioName = provider.selectedPortfolio?.name ?? "Portföy Seç";

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  portfolioName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            PopupMenuButton<int>(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text("Seçenekler"),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
              onSelected: (value) {
                if (value == -1) {
                  _showAddPortfolioDialog(context, provider);
                } else {
                  final p = provider.portfolios.firstWhere(
                    (e) => e.id == value,
                  );
                  provider.selectPortfolio(p);
                }
              },
              itemBuilder: (context) => [
                ...provider.portfolios.map(
                  (p) => PopupMenuItem(
                    value: p.id,
                    child: Text(
                      p.name,
                      style: TextStyle(
                        fontWeight: p.id == provider.selectedPortfolio?.id
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: -1,
                  child: Row(
                    children: [
                      Icon(Icons.add, color: Color(0xFF1A237E), size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Yeni Portföy Oluştur",
                        style: TextStyle(
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboardCard(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SizedBox(
            height: 250,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final totalValue = provider.totalPortfolioValue;
        final totalPL = provider.totalProfitLoss;
        final plRate = provider.totalProfitLossRate;
        final isProfit = totalPL >= 0;

        // Data for chart
        final Map<AssetType, double> data = provider.valueByType;
        final List<PieChartSectionData> sections = [];

        // Colors
        Color getColor(AssetType type) {
          switch (type) {
            case AssetType.STOCK:
              return const Color(0xFF4285F4); // Blue
            case AssetType.GOLD:
              return const Color(0xFFEA4335); // Red/Orange ish
            case AssetType.CRYPTO:
              return const Color(0xFFFBBC05); // Yellow/Orange
            case AssetType.FOREX:
              return const Color(0xFF34A853); // Green
          }
        }

        data.forEach((type, value) {
          if (value > 0) {
            final double percentage = (value / totalValue) * 100;
            sections.add(
              PieChartSectionData(
                color: getColor(type),
                value: value,
                title: '${percentage.toStringAsFixed(1)}%',
                radius: 25,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                showTitle: false, // Too small, prefer legend or just visual
              ),
            );
          }
        });

        // If empty mock data
        if (sections.isEmpty) {
          sections.add(
            PieChartSectionData(
              color: Colors.grey.shade300,
              value: 1,
              radius: 20,
              showTitle: false,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Chart
              SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 55,
                        sectionsSpace: 2,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Toplam",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            isProfit
                                ? "+%${plRate.toStringAsFixed(2)}"
                                : "%${plRate.toStringAsFixed(2)}",
                            style: TextStyle(
                              color: isProfit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Legend & Total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Toplam Değer",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₺${NumberFormat('#,##0.00', 'tr_TR').format(totalValue)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLegendItem(
                      getColor(AssetType.CRYPTO),
                      "Kripto Para",
                      data[AssetType.CRYPTO] ?? 0,
                      totalValue,
                    ),
                    _buildLegendItem(
                      getColor(AssetType.GOLD),
                      "Değerli Madenler",
                      data[AssetType.GOLD] ?? 0,
                      totalValue,
                    ),
                    _buildLegendItem(
                      getColor(AssetType.STOCK),
                      "Türk Hisse Senetleri",
                      data[AssetType.STOCK] ?? 0,
                      totalValue,
                    ),
                    _buildLegendItem(
                      getColor(AssetType.FOREX),
                      "Döviz",
                      data[AssetType.FOREX] ?? 0,
                      totalValue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(
    Color color,
    String text,
    double value,
    double total,
  ) {
    if (value <= 0) return const SizedBox.shrink();
    final percent = (value / total) * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 4),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Text(
            "${percent.toStringAsFixed(1)}%",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCategories(BuildContext context) {
    // Only show categories that have assets
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const SizedBox();

        final stockCount = provider.getCountByType(AssetType.STOCK);
        final goldCount = provider.getCountByType(AssetType.GOLD);
        final cryptoCount = provider.getCountByType(AssetType.CRYPTO);
        final forexCount = provider.getCountByType(AssetType.FOREX);

        final stockVal = provider.getValueByType(AssetType.STOCK);
        final goldVal = provider.getValueByType(AssetType.GOLD);
        final cryptoVal = provider.getValueByType(AssetType.CRYPTO);
        final forexVal = provider.getValueByType(AssetType.FOREX);

        final total = provider.totalPortfolioValue;

        final List<Widget> items = [];

        if (stockCount > 0)
          items.add(
            _buildCategoryItem(
              "Türk Hisse Senetleri",
              stockCount,
              stockVal,
              total,
              Icons.show_chart,
              const Color(0xFF4285F4),
            ),
          );
        if (goldCount > 0)
          items.add(
            _buildCategoryItem(
              "Değerli Madenler",
              goldCount,
              goldVal,
              total,
              Icons.hexagon_outlined,
              const Color(0xFFEA4335),
            ),
          );
        if (cryptoCount > 0)
          items.add(
            _buildCategoryItem(
              "Kripto Para",
              cryptoCount,
              cryptoVal,
              total,
              Icons.currency_bitcoin,
              const Color(0xFFFBBC05),
            ),
          );
        if (forexCount > 0)
          items.add(
            _buildCategoryItem(
              "Döviz",
              forexCount,
              forexVal,
              total,
              Icons.attach_money,
              const Color(0xFF34A853),
            ),
          );

        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Henüz varlık eklemediniz."),
            ),
          );
        }

        return Column(children: items);
      },
    );
  }

  Widget _buildCategoryItem(
    String title,
    int count,
    double value,
    double total,
    IconData icon,
    Color color,
  ) {
    final percent = total > 0 ? (value / total) * 100 : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50)), // Slight border
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(20),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "$count Varlık",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(value)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${percent.toStringAsFixed(1)}%",
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddPortfolioDialog(
    BuildContext context,
    PortfolioProvider provider,
  ) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Portföy'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Portföy Adı (Örn: Emeklilik)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addPortfolio(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}
