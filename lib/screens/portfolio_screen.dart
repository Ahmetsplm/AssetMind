import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'portfolio/daily_performance_screen.dart';
import '../providers/portfolio_provider.dart';
import '../providers/market_provider.dart';
import '../models/holding.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date locale
import 'portfolio/category_detail_screen.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../models/portfolio.dart';
import '../widgets/analysis_sheet.dart';
import '../widgets/mesh_gradient_background.dart';
import 'dart:ui' as ui;

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
      dateStr.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
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
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
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
    return Consumer2<PortfolioProvider, MarketProvider>(
      builder: (context, provider, marketProvider, child) {
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

        final stats = provider.getPortfolioStats(marketProvider);
        
        final totalValue = stats.liveTotalValue;
        final totalPL = stats.totalPL;
        final plRate = stats.plRate;
        final isProfit = totalPL >= 0;
        final data = stats.assetValues;
        
        final dailyChange = stats.dailyChange;
        final isDailyUp = dailyChange >= 0;
        
        final currencySymbol = provider.currencySymbol;

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
            case AssetType.GLOBAL:
              return const Color(0xFF9C27B0); // Purple
            case AssetType.FUND:
              return const Color(0xFF00BCD4); // Cyan
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

        return ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: MeshGradientBackground(
            primaryColor: isCustom ? backgroundGradient.colors.first : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
            secondaryColor: isCustom ? backgroundGradient.colors.last : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isCustom 
                      ? Colors.black.withValues(alpha: 0.1) 
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Stack(
                  children: [
                    // Pulse Indicator
                    Positioned(
                      top: 24,
                      left: 24,
                      child: _PulseIndicator(isPositive: isProfit),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Total Value Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // TOPLAM VARLIK
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    Text(
                                      "TOPLAM VARLIK",
                                      style: GoogleFonts.outfit(
                                        color: subTextColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: provider.isPrivacyMode
                                          ? Text(
                                              '****',
                                              style: GoogleFonts.outfit(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: textColor,
                                                letterSpacing: 4,
                                              ),
                                            )
                                          : Text(
                                              '$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(totalValue)}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: textColor,
                                                letterSpacing: -1,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 6),
                                    Consumer<MarketProvider>(
                                      builder: (context, marketProvider, _) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.sync_rounded,
                                                size: 10,
                                                color: subTextColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                marketProvider.lastUpdateText.toUpperCase(),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: subTextColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              // Döviz ve Ayar Butonları
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildCurrencyToggleGroup(context, provider),
                                  const SizedBox(height: 8),
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
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            height: 0.5,
                            width: 60,
                            color: subTextColor.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 24),
                          
                          // Günlük Değişim Kartı
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyPerformanceScreen()));
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCustom 
                                   ? Colors.black.withValues(alpha: 0.15) 
                                   : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Günlük Değişim",
                                    style: GoogleFonts.outfit(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "${isDailyUp ? '+' : ''}$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(dailyChange)}",
                                        style: GoogleFonts.outfit(
                                          color: isDailyUp ? (isCustom ? Colors.white : Colors.green) : (isCustom ? Colors.white : Colors.red),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: subTextColor,
                                        size: 16,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),

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
                                key: ValueKey(totalValue),
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
                                      "${isProfit ? '' : '-'}%${plRate.abs().toStringAsFixed(1)}",
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
            ],
          ),
        ),
      ),
    ),
  );
      },
    );
  }

  Widget _buildCurrencyToggleGroup(BuildContext context, PortfolioProvider provider) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.3 : 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['TRY', 'USD', 'EUR'].map((currency) {
          final isActive = provider.selectedCurrency == currency;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              provider.setCurrency(currency);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: Text(
                currency,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive 
                    ? Colors.white 
                    : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }).toList(),
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
    return Consumer2<PortfolioProvider, MarketProvider>(
      builder: (context, provider, marketProvider, child) {
        if (provider.isLoading) {
          return _buildSkeletonLoading(context);
        }

        if (provider.holdings.isEmpty) {
          return _buildEmptyState(context);
        }

        final stockCount = provider.getCountByType(AssetType.STOCK);
        final goldCount = provider.getCountByType(AssetType.GOLD);
        final cryptoCount = provider.getCountByType(AssetType.CRYPTO);
        final forexCount = provider.getCountByType(AssetType.FOREX);
        final globalCount = provider.getCountByType(AssetType.GLOBAL);
        final fundCount = provider.getCountByType(AssetType.FUND);

        final stats = provider.getPortfolioStats(marketProvider);
        final total = stats.liveTotalValue;

        // Mock data to prevent empty feel if desired, but here we show a message
        if (stockCount == 0 &&
            goldCount == 0 &&
            cryptoCount == 0 &&
            forexCount == 0 &&
            globalCount == 0 &&
            fundCount == 0) {
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

        Map<String, dynamic> getCategoryData(AssetType type, String defaultTitle, IconData icon, Color color) {
          final hList = provider.getHoldingsByType(type).where((h) => h.quantity > 0).toList();
          
          hList.sort((a, b) {
            double aVal = a.quantity * (marketProvider.getAsset(a.symbol)?.price ?? a.averageCost);
            double bVal = b.quantity * (marketProvider.getAsset(b.symbol)?.price ?? b.averageCost);
            return bVal.compareTo(aVal);
          });
          
          String subtitle = "";
          if (hList.isNotEmpty) {
            if (hList.length == 1) {
              subtitle = hList[0].symbol;
            } else if (hList.length == 2) {
              subtitle = "${hList[0].symbol}, ${hList[1].symbol}";
            } else {
              subtitle = "${hList[0].symbol}, ${hList[1].symbol} (+${hList.length - 2})";
            }
          }

          double val = stats.assetValues[type] ?? 0;
          double profit = stats.assetProfits[type] ?? 0;
          double totalCost = val - profit;
          double profitPercent = totalCost > 0 ? (profit / totalCost) * 100 : 0.0;

          return {
            'type': type,
            'title': defaultTitle,
            'subtitle': subtitle,
            'count': hList.length,
            'value': val,
            'profit': profit,
            'profitPercent': profitPercent,
            'icon': icon,
            'color': color,
          };
        }

        if (stockCount > 0) {
          categories.add(getCategoryData(AssetType.STOCK, "Türk Hisse Senetleri", Icons.trending_up_rounded, const Color(0xFF4285F4)));
        }
        if (goldCount > 0) {
          categories.add(getCategoryData(AssetType.GOLD, "Değerli Madenler", Icons.diamond_outlined, const Color(0xFFEA4335)));
        }
        if (cryptoCount > 0) {
          categories.add(getCategoryData(AssetType.CRYPTO, "Kripto Para", Icons.currency_bitcoin_rounded, const Color(0xFFFBBC05)));
        }
        if (forexCount > 0) {
          categories.add(getCategoryData(AssetType.FOREX, "Döviz", Icons.currency_exchange_rounded, const Color(0xFF34A853)));
        }
        if (globalCount > 0) {
          categories.add(getCategoryData(AssetType.GLOBAL, "Global Hisseler", Icons.public_rounded, const Color(0xFF9C27B0)));
        }
        if (fundCount > 0) {
          categories.add(getCategoryData(AssetType.FUND, "Yatırım Fonları", Icons.account_balance_rounded, const Color(0xFF00BCD4)));
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
                  c['profit'],
                  c['profitPercent'],
                  total,
                  c['icon'],
                  c['color'],
                  isPrivacyMode: provider.isPrivacyMode,
                  currencySymbol: provider.currencySymbol,
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
    double profit,
    double profitPercent,
    double total,
    IconData icon,
    Color color, {
    required bool isPrivacyMode,
    required String currencySymbol,
  }) {
    final double percentage = total > 0 ? (value / total) * 100 : 0;
    Color displayColor = color;

    return _AnimatedCategoryCard(
      type: type,
      title: title,
      subtitle: subtitle,
      count: count,
      value: value,
      profit: profit,
      profitPercent: profitPercent,
      percentage: percentage,
      icon: icon,
      color: displayColor,
      isPrivacyMode: isPrivacyMode,
      currencySymbol: currencySymbol,
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
  final double profit;
  final double profitPercent;
  final double percentage;
  final IconData icon;
  final Color color;
  final bool isPrivacyMode;
  final String currencySymbol;

  const _AnimatedCategoryCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.value,
    required this.profit,
    required this.profitPercent,
    required this.percentage,
    required this.icon,
    required this.color,
    required this.isPrivacyMode,
    required this.currencySymbol,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${widget.count} Varlık • ${widget.subtitle}",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: subTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 6),
                  if (!widget.isPrivacyMode)
                    Text(
                      '${widget.profit >= 0 ? '+' : '-'}${widget.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(widget.profit.abs())} (${widget.profit >= 0 ? '+' : '-'}%${widget.profitPercent.abs().toStringAsFixed(2)})',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: widget.profit >= 0 ? Colors.green : Colors.red,
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

class _PulseIndicator extends StatefulWidget {
  final bool isPositive;
  const _PulseIndicator({required this.isPositive});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isPositive ? Colors.greenAccent : Colors.redAccent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2 * (1 - _controller.value)),
                border: Border.all(color: color.withValues(alpha: 1 - _controller.value), width: 2),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
