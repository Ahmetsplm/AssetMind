import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/holding.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date locale
import 'portfolio/category_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null); // Initialize Turkish locale
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateHeader(context),
              const SizedBox(height: 12),
              _buildSelectorHeader(context),
              const SizedBox(height: 24),
              _buildDashboardCard(context),
              const SizedBox(height: 32),
              _buildAssetsHeader(context),
              const SizedBox(height: 16),
              _buildAssetCategories(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('d MMMM EEEE', 'tr_TR').format(now);

    return Text(
      "Bugün, $dateStr",
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
      ),
    );
  }

  Widget _buildSelectorHeader(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final portfolioName = provider.selectedPortfolio?.name ?? "Portföy Seç";

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                portfolioName,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
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
              child: PopupMenuButton<int>(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).cardColor,
                elevation: 4,
                icon: Icon(
                  Icons.expand_more_rounded,
                  color: Theme.of(context).primaryColor,
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
                        style: GoogleFonts.poppins(
                          fontWeight: p.id == provider.selectedPortfolio?.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: -1,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Yeni Portföy",
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          return SizedBox(
            height: 250,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
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
              return const Color(0xFFEA4335); // Red
            case AssetType.CRYPTO:
              return const Color(0xFFFBBC05); // Yellow
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
                radius: 20, // Sleeker
                titleStyle: const TextStyle(
                  fontSize: 0, // Hide text inside
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                showTitle: false,
              ),
            );
          }
        });

        if (sections.isEmpty) {
          sections.add(
            PieChartSectionData(
              color: Colors.white.withOpacity(0.2),
              value: 1,
              radius: 20,
              showTitle: false,
            ),
          );
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            // Premium Gradient for Light mode to pop? Or Solid for clean look?
            // Let's use a solid clean look for dashboard, maybe slight gradient
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFFAFAFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : const Color(0xFF1A237E).withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                blurRadius: 0,
                offset: const Offset(0, 0),
              ),
            ],
            // Border highlight for dark mode
            border: isDark
                ? Border.all(color: Colors.white.withOpacity(0.1))
                : null,
          ),
          child: Column(
            children: [
              // Total Value Section
              Column(
                children: [
                  Text(
                    "Toplam Varlık",
                    style: GoogleFonts.poppins(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₺${NumberFormat('#,##0.00', 'tr_TR').format(totalValue)}',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 24),

              // Chart & Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Chart
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 45,
                            sectionsSpace: 4,
                            startDegreeOffset: -90,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isProfit ? "Kâr" : "Zarar",
                                style: GoogleFonts.poppins(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                "%${plRate.toStringAsFixed(1)}",
                                style: GoogleFonts.poppins(
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

                  const SizedBox(width: 16),

                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatRow(
                          context,
                          "Net Kâr/Zarar",
                          '${isProfit ? '+' : ''}₺${NumberFormat('#,##0.00', 'tr_TR').format(totalPL)}',
                          isProfit
                              ? (isDark ? Colors.greenAccent : Colors.green)
                              : (isDark ? Colors.redAccent : Colors.red),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          context,
                          "Varlık Sayısı",
                          provider.holdings.length.toString(),
                          Theme.of(context).primaryColor,
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
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetsHeader(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        String sortText = "Değer";
        IconData sortIcon = Icons.sort;

        switch (provider.sortOption) {
          case SortOption.valueDesc:
            sortText = "Azalan Değer";
            sortIcon = Icons.arrow_downward_rounded;
            break;
          case SortOption.valueAsc:
            sortText = "Artan Değer";
            sortIcon = Icons.arrow_upward_rounded;
            break;
          case SortOption.nameAsc:
            sortText = "İsim (A-Z)";
            sortIcon = Icons.sort_by_alpha_rounded;
            break;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Portföy Dağılımı',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            PopupMenuButton<SortOption>(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      sortIcon,
                      size: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sortText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (value) {
                provider.setSortOption(value);
              },
              itemBuilder: (context) => [
                _buildSortItem(
                  context,
                  SortOption.valueDesc,
                  "Azalan Değer",
                  Icons.arrow_downward_rounded,
                ),
                _buildSortItem(
                  context,
                  SortOption.valueAsc,
                  "Artan Değer",
                  Icons.arrow_upward_rounded,
                ),
                _buildSortItem(
                  context,
                  SortOption.nameAsc,
                  "İsim (A-Z)",
                  Icons.sort_by_alpha_rounded,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  PopupMenuItem<SortOption> _buildSortItem(
    BuildContext context,
    SortOption value,
    String text,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCategories(BuildContext context) {
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

        // Mock data to prevent empty feel if desired, but here we show a message
        if (stockCount == 0 &&
            goldCount == 0 &&
            cryptoCount == 0 &&
            forexCount == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.add_chart_rounded,
                    size: 48,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz varlık eklemediniz.",
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Create a list of Map to sort easily
        List<Map<String, dynamic>> categories = [];

        if (stockCount > 0) {
          categories.add({
            'type': AssetType.STOCK,
            'title': "Türk Hisse Senetleri",
            'subtitle': "BIST 100 Endeks", // More context
            'count': stockCount,
            'value': stockVal,
            'icon': Icons.trending_up_rounded,
            'color': const Color(0xFF4285F4),
          });
        }
        if (goldCount > 0) {
          categories.add({
            'type': AssetType.GOLD,
            'title': "Değerli Madenler",
            'subtitle': "Altın, Gümüş, Platin",
            'count': goldCount,
            'value': goldVal,
            'icon': Icons.diamond_outlined, // More premium icon
            'color': const Color(0xFFEA4335),
          });
        }
        if (cryptoCount > 0) {
          categories.add({
            'type': AssetType.CRYPTO,
            'title': "Kripto Para",
            'subtitle': "Bitcoin, Ethereum...",
            'count': cryptoCount,
            'value': cryptoVal,
            'icon': Icons.currency_bitcoin_rounded,
            'color': const Color(0xFFFBBC05),
          });
        }
        if (forexCount > 0) {
          categories.add({
            'type': AssetType.FOREX,
            'title': "Döviz",
            'subtitle': "Dolar, Euro ve diğerleri",
            'count': forexCount,
            'value': forexVal,
            'icon': Icons.currency_exchange_rounded,
            'color': const Color(0xFF34A853),
          });
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
                  c['subtitle'],
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
    String subtitle,
    int count,
    double value,
    double total,
    IconData icon,
    Color color,
  ) {
    final percent = total > 0 ? (value / total) * 100 : 0;
    // Brighten color for dark mode slightly to pop?
    Color displayColor = color;

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
        child: Row(
          children: [
            // Icon Container
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: displayColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: displayColor, size: 28),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    "$count Varlık • $subtitle",
                    style: GoogleFonts.poppins(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Value Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(value)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "%${percent.toStringAsFixed(1)}",
                    style: GoogleFonts.poppins(
                      color: displayColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Yeni Portföy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: TextField(
          controller: controller,
          cursorColor: Theme.of(context).primaryColor,
          decoration: InputDecoration(
            hintText: 'Portföy Adı (Örn: Emeklilik)',
            hintStyle: GoogleFonts.poppins(
              color: Theme.of(context).disabledColor,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addPortfolio(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Oluştur',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
