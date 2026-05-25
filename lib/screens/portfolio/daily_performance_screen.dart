import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/market_provider.dart';
import '../../models/holding.dart';

class DailyPerformanceScreen extends StatelessWidget {
  const DailyPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).iconTheme,
        title: Text(
          "Günlük Performans",
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer2<PortfolioProvider, MarketProvider>(
        builder: (context, provider, marketProvider, child) {
          final holdings = provider.holdings.where((h) => h.quantity > 0).toList();
          
          double totalDailyProfit = 0;
          double totalPortfolioCostForToday = 0; // for percentage
          
          List<Map<String, dynamic>> performanceItems = [];

          for (var h in holdings) {
            double currentPrice = provider.getCurrentPrice(h.symbol);
            if (currentPrice == 0) currentPrice = h.averageCost;

            final assetCache = marketProvider.getAsset(h.symbol) ?? marketProvider.getAsset('${h.symbol}.IS');
            double changePercent = assetCache?.change ?? 0.0;
            double previousPrice = currentPrice / (1 + (changePercent / 100));

            // Advanced Daily Profit Calculation
            double dailyProfitAsset = provider.getDailyProfitForHolding(h, marketProvider);
            
            double totalValueAsset = currentPrice * h.quantity;
            double totalProfitAsset = (currentPrice - h.averageCost) * h.quantity;
            double totalProfitPercent = h.averageCost > 0 ? ((currentPrice - h.averageCost) / h.averageCost) * 100 : 0.0;

            // Kur Dönüşümü
            if (h.type == AssetType.CRYPTO || h.type == AssetType.GLOBAL) {
               totalValueAsset *= marketProvider.usdTryRate;
               totalProfitAsset *= marketProvider.usdTryRate;
               previousPrice *= marketProvider.usdTryRate; 
            }

            double currentQuantityCostForToday = previousPrice * h.quantity;
            double displayDailyPercent = currentQuantityCostForToday > 0 ? (dailyProfitAsset / currentQuantityCostForToday) * 100 : 0.0;

            // Para birimi dönüşümü (Kullanıcı USD seçtiyse vs.)
            final convRate = provider.getConversionRate();
            dailyProfitAsset /= convRate;
            totalValueAsset /= convRate;
            totalProfitAsset /= convRate;
            currentQuantityCostForToday /= convRate;

            totalDailyProfit += dailyProfitAsset;
            totalPortfolioCostForToday += currentQuantityCostForToday;
            
            performanceItems.add({
              'holding': h,
              'symbol': h.symbol,
              'totalValue': totalValueAsset,
              'dailyProfit': dailyProfitAsset,
              'dailyPercent': displayDailyPercent,
              'totalProfit': totalProfitAsset,
              'totalPercent': totalProfitPercent,
            });
          }

          // Toplam Portföy Değerleri
          final stats = provider.getPortfolioStats(marketProvider);
          final totalPortfolioValue = stats.liveTotalValue;
          final totalDailyPercent = totalPortfolioCostForToday > 0 
              ? (totalDailyProfit / totalPortfolioCostForToday) * 100 
              : 0.0;

          final isTotalProfit = totalDailyProfit >= 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Ana Portföy Özet Kartı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.selectedPortfolio?.name ?? "Ana Portföy",
                      style: GoogleFonts.inter(
                        color: Theme.of(context).disabledColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tüm Varlıklar",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Günlük Net Değişim",
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${isTotalProfit ? '+' : ''}${provider.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalDailyProfit)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isTotalProfit ? Colors.green[600] : Colors.red[600],
                                ),
                              ),
                              Text(
                                "${isTotalProfit ? '+' : ''}%${totalDailyPercent.toStringAsFixed(2)}",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isTotalProfit ? Colors.green[600] : Colors.red[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Portföy Değeri",
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).disabledColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${provider.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalPortfolioValue)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20), // Placeholder to align
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Varlıklar Listesi
              ...performanceItems.map((item) {
                final Holding h = item['holding'];
                final dailyProfit = item['dailyProfit'] as double;
                final dailyPercent = item['dailyPercent'] as double;
                final totalProfit = item['totalProfit'] as double;
                final totalPercent = item['totalPercent'] as double;
                final totalVal = item['totalValue'] as double;
                
                final isDailyProfit = dailyProfit >= 0;
                final isTotalProfitAsset = totalProfit >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Üst Kısım: Sembol ve Adet / Toplam Değer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDailyProfit 
                                      ? Colors.green.withOpacity(0.1) 
                                      : Colors.red.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDailyProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: isDailyProfit ? Colors.green[700] : Colors.red[700],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                h.symbol,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${provider.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalVal)}",
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${h.quantity} adet",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Alt Kısım: 2 Kutu (Günlük Değişim | Toplam K/Z)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Günlük Değişim",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${isDailyProfit ? '+' : ''}${provider.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(dailyProfit)}",
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDailyProfit ? Colors.green[600] : Colors.red[600],
                                    ),
                                  ),
                                  Text(
                                    "${isDailyProfit ? '+' : ''}%${dailyPercent.toStringAsFixed(2)}",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDailyProfit ? Colors.green[600] : Colors.red[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Toplam K/Z",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${isTotalProfitAsset ? '+' : ''}${provider.currencySymbol}${NumberFormat('#,##0.00', 'tr_TR').format(totalProfit)}",
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isTotalProfitAsset ? Colors.green[600] : Colors.red[600],
                                    ),
                                  ),
                                  Text(
                                    "${isTotalProfitAsset ? '+' : ''}%${totalPercent.toStringAsFixed(2)}",
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isTotalProfitAsset ? Colors.green[600] : Colors.red[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
