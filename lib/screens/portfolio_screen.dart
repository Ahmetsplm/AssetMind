import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/holding.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date locale
import 'portfolio/category_detail_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../models/portfolio.dart';
import '../widgets/analysis_sheet.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  int touchedIndex = -1;

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
        color: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.color
            ?.withValues(alpha: 0.6),
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
              child: Row(
                children: [
                  Flexible(
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
                  if (provider.selectedPortfolio != null)
                    IconButton(
                      onPressed: () => _showRenamePortfolioDialog(
                        context,
                        provider,
                        provider.selectedPortfolio!,
                      ),
                      icon: Icon(
                        Icons.edit_rounded,
                        size: 20,
                        color: Theme.of(context).disabledColor,
                      ),
                      tooltip: "Portföy Adını Değiştir",
                    ),
                ],
              ),
            ),
            // PRIVACY TOGGLE BUTTON
            Container(
              margin: const EdgeInsets.only(right: 12),
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
              child: IconButton(
                icon: Icon(
                  provider.isPrivacyMode
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                tooltip: "Gizlilik Modu",
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.togglePrivacyMode();
                },
              ),
            ),
            // ANALYSIS BUTTON
            Container(
              margin: const EdgeInsets.only(right: 12),
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
              child: IconButton(
                icon: Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: "Portföy Analizi",
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => const AnalysisSheet(),
                  );
                },
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

        final totalValue = provider.displayedTotalValue;
        final totalPL = provider.displayedTotalProfitLoss;
        final plRate = provider.totalProfitLossRate;
        final isProfit = totalPL >= 0;
        final currencySymbol = provider.currencySymbol;

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
                radius: 20,
                titleStyle: const TextStyle(
                  fontSize: 0,
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
              color: Colors.white.withValues(alpha: 0.2),
              value: 1,
              radius: 20,
              showTitle: false,
            ),
          );
        }

        final themeProvider = Provider.of<ThemeProvider>(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final int styleIndex = themeProvider.cardStyleIndex;
        final bool isCustom = styleIndex > 0;

        final Gradient backgroundGradient = isCustom
            ? AppTheme.cardGradients[styleIndex]
            : (isDark
                ? AppTheme.darkCardGradient
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFFAFAFA)],
                  ));

        final Color textColor = isCustom
            ? Colors.white
            : Theme.of(context).textTheme.bodyLarge!.color!;
        final Color subTextColor = isCustom
            ? Colors.white70
            : Theme.of(context)
                .textTheme
                .bodyMedium!
                .color!
                .withValues(alpha: 0.6);

        return Container(
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isCustom
                    ? AppTheme.cardGradients[styleIndex].colors.first
                        .withValues(alpha: 0.3)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : const Color(0xFF1A237E).withValues(alpha: 0.08)),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              if (!isCustom)
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.white,
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                ),
            ],
            border: isDark && !isCustom
                ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Total Value Section
                    Column(
                      children: [
                        Text(
                          "Toplam Varlık",
                          style: GoogleFonts.poppins(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        provider.isPrivacyMode
                            ? Text(
                                '****',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: 4,
                                ),
                              )
                            : Text(
                                '$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(totalValue)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  letterSpacing: -0.5,
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(
                        height: 1, color: subTextColor.withValues(alpha: 0.2)),
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
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          touchedIndex = -1;
                                          return;
                                        }
                                        touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  sections: sections
                                      .asMap()
                                      .map<int, PieChartSectionData>((
                                        index,
                                        data,
                                      ) {
                                        final isTouched = index == touchedIndex;
                                        final double fontSize =
                                            isTouched ? 16.0 : 0.0;
                                        final double radius =
                                            isTouched ? 30.0 : 20.0;

                                        return MapEntry(
                                          index,
                                          data.copyWith(
                                            radius: radius,
                                            titleStyle: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      })
                                      .values
                                      .toList(),
                                  centerSpaceRadius: 40,
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
                                        color: subTextColor,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      "%${plRate.toStringAsFixed(1)}",
                                      style: GoogleFonts.poppins(
                                        color: isProfit
                                            ? (isCustom
                                                ? Colors.white
                                                : Colors.green)
                                            : (isCustom
                                                ? Colors.white
                                                : Colors.red),
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
                                '${isProfit ? '+' : ''}$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(totalPL)}',
                                isProfit
                                    ? (isCustom
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.greenAccent
                                            : Colors.green))
                                    : (isCustom
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.redAccent
                                            : Colors.red)),
                                textColor,
                                subTextColor,
                              ),
                              const SizedBox(height: 12),
                              _buildStatRow(
                                context,
                                "Varlık Sayısı",
                                provider.activeHoldingsCount.toString(),
                                isCustom
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                                textColor,
                                subTextColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    _buildCurrencyToggle(context, provider, subTextColor),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: subTextColor.withValues(alpha: 0.5),
                        size: 20,
                      ),
                      onPressed: () => _showCardStylePicker(context),
                      tooltip: "Kart Stilini Düzenle",
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

  Widget _buildCurrencyToggle(
    BuildContext context,
    PortfolioProvider provider,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => provider.toggleCurrency(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              provider.selectedCurrency,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: subTextColor),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: valueColor,
            fontWeight: FontWeight.bold,
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
        if (provider.isLoading) {
          return _buildSkeletonLoading(context);
        }

        if (provider.activeHoldingsCount == 0) {
          return _buildEmptyState(context);
        }

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
                  isPrivacyMode: provider.isPrivacyMode,
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
    Color color, {
    required bool isPrivacyMode,
  }) {
    final double percentage = total > 0 ? (value / total) * 100 : 0;
    Color displayColor = color;

    return _AnimatedCategoryCard(
      type: type,
      title: title,
      subtitle: subtitle,
      count: count,
      value: value,
      percentage: percentage,
      icon: icon,
      color: displayColor,
      isPrivacyMode: isPrivacyMode,
    );
  }
}

void _showAddPortfolioDialog(BuildContext context, PortfolioProvider provider) {
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
            style: GoogleFonts.poppins(color: Theme.of(context).disabledColor),
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

void _showCardStylePicker(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          "Kart Stili",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: AppTheme.cardGradients.length,
            itemBuilder: (context, index) {
              final gradient = AppTheme.cardGradients[index];
              return GestureDetector(
                onTap: () {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setCardStyle(index);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: index ==
                          Provider.of<ThemeProvider>(context).cardStyleIndex
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Widget _buildSkeletonLoading(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return Column(
    children: List.generate(3, (index) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }),
  );
}

Widget _buildEmptyState(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.8, end: 1.0),
          duration: const Duration(seconds: 2),
          curve: Curves.elasticOut,
          builder: (context, double value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 80,
            color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Portföyün Boş",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Henüz hiç varlık eklemedin.\n'Portföyüm' sekmesinden ekleyebilirsin.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 40),
      ],
    ),
  );
}

void _showRenamePortfolioDialog(
  BuildContext context,
  PortfolioProvider provider,
  Portfolio portfolio,
) {
  final TextEditingController controller = TextEditingController(
    text: portfolio.name,
  );
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Portföy Adını Düzenle',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      content: TextField(
        controller: controller,
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          hintText: 'Yeni İsim',
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
            style: GoogleFonts.poppins(color: Theme.of(context).disabledColor),
          ),
        ),
        TextButton(
          onPressed: () {
            if (controller.text.isNotEmpty) {
              provider.renamePortfolio(portfolio.id!, controller.text);
              Navigator.pop(context);
            }
          },
          child: Text(
            'Kaydet',
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

class _AnimatedCategoryCard extends StatefulWidget {
  final AssetType type;
  final String title;
  final String subtitle;
  final int count;
  final double value;
  final double percentage;
  final IconData icon;
  final Color color;
  final bool isPrivacyMode;

  const _AnimatedCategoryCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.value,
    required this.percentage,
    required this.icon,
    required this.color,
    required this.isPrivacyMode,
  });

  @override
  State<_AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<_AnimatedCategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CategoryDetailScreen(type: widget.type, title: widget.title),
          ),
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
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
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(width: 16),

              // Text Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    Text(
                      "${widget.count} Varlık • ${widget.subtitle}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Value & Percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  widget.isPrivacyMode
                      ? Text(
                          "**** ",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                            letterSpacing: 2,
                          ),
                        )
                      : Text(
                          '₺${NumberFormat('#,##0.00', 'tr_TR').format(widget.value)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.isPrivacyMode
                          ? "%-.-"
                          : '%${widget.percentage.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
