import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/holding.dart';
import 'package:intl/intl.dart';
import 'portfolio/category_detail_screen.dart';

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
              const SizedBox(height: 24),
              _buildAssetsHeader(context),
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
                            "Toplam K/Z",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isProfit ? '+' : ''}₺${NumberFormat('#,##0.00', 'tr_TR').format(totalPL)}',
                            style: GoogleFonts.poppins(
                              color: isProfit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isProfit
                                ? "%${plRate.toStringAsFixed(2)}"
                                : "%${plRate.toStringAsFixed(2)}",
                            style: GoogleFonts.poppins(
                              color: isProfit ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
    if (value <= 0) {
      return const SizedBox.shrink();
    }
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

  Widget _buildAssetsHeader(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        String sortText = "Değere Göre";
        if (provider.sortOption == SortOption.nameAsc) sortText = "A-Z";
        if (provider.sortOption == SortOption.valueAsc)
          sortText = "Değer Artan";

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Varlıklarım',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            PopupMenuButton<SortOption>(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      sortText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (value) {
                provider.setSortOption(value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SortOption.valueDesc,
                  child: Text("Değere Göre (Azalan)"),
                ),
                const PopupMenuItem(
                  value: SortOption.valueAsc,
                  child: Text("Değere Göre (Artan)"),
                ),
                const PopupMenuItem(
                  value: SortOption.nameAsc,
                  child: Text("İsim (A-Z)"),
                ),
              ],
            ),
          ],
        );
      },
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

        // Create a list of Map to sort easily
        List<Map<String, dynamic>> categories = [];

        if (stockCount > 0) {
          categories.add({
            'type': AssetType.STOCK,
            'title': "Türk Hisse Senetleri",
            'count': stockCount,
            'value': stockVal,
            'icon': Icons.show_chart,
            'color': const Color(0xFF4285F4),
          });
        }
        if (goldCount > 0) {
          categories.add({
            'type': AssetType.GOLD,
            'title': "Değerli Madenler",
            'count': goldCount,
            'value': goldVal,
            'icon': Icons.hexagon_outlined,
            'color': const Color(0xFFEA4335),
          });
        }
        if (cryptoCount > 0) {
          categories.add({
            'type': AssetType.CRYPTO,
            'title': "Kripto Para",
            'count': cryptoCount,
            'value': cryptoVal,
            'icon': Icons.currency_bitcoin,
            'color': const Color(0xFFFBBC05),
          });
        }
        if (forexCount > 0) {
          categories.add({
            'type': AssetType.FOREX,
            'title': "Döviz",
            'count': forexCount,
            'value': forexVal,
            'icon': Icons.attach_money,
            'color': const Color(0xFF34A853),
          });
        }

        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("Henüz varlık eklemediniz."),
            ),
          );
        }

        // SORTING LOGIC
        categories.sort((a, b) {
          switch (provider.sortOption) {
            case SortOption.valueDesc:
              return (b['value'] as double).compareTo(a['value'] as double);
            case SortOption.valueAsc:
              return (a['value'] as double).compareTo(b['value'] as double);
            case SortOption.nameAsc:
              return (a['title'] as String).compareTo(b['title'] as String);
          }
        });

        return Column(
          children: categories
              .map(
                (c) => _buildCategoryItem(
                  context,
                  c['type'],
                  c['title'],
                  c['count'],
                  c['value'],
                  total,
                  c['icon'],
                  c['color'],
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    AssetType type,
    String title,
    int count,
    double value,
    double total,
    IconData icon,
    Color color,
  ) {
    final percent = total > 0 ? (value / total) * 100 : 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(type: type, title: title),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "$count Varlık",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(value)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${percent.toStringAsFixed(1)}%",
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
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
