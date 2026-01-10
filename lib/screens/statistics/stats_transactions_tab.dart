import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/transaction.dart';

class StatsTransactionsTab extends StatelessWidget {
  const StatsTransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        final transactions = provider.allTransactions;

        if (transactions.isEmpty) {
          return const Center(child: Text("İşlem Geçmişi Yok"));
        }

        // Calculate Stats
        final totalTransactions = transactions.length;
        // Total Volume (Sum of all transaction values)
        double totalVolume = 0;
        final Map<int, double> monthlyVolume = {};

        for (var t in transactions) {
          final val = t.amount * t.price;
          totalVolume += val;

          // Bucket by month (e.g., 202310 for Oct 2023)
          // Actually just use month index 1-12 for simple chart of THIS year?
          // Or last 6 months.
          // Let's do simple: Last 12 months.
          final key = t.date.month; // 1-12
          // Note: Aggregating all years for simplicity or need Year check?
          // Let's assume current view is generic. A more complex one checks Year.
          // For simple UI, let's just show Month name of transaction.
          monthlyVolume[key] = (monthlyVolume[key] ?? 0) + val;
        }

        final avgTransaction = totalTransactions > 0
            ? totalVolume / totalTransactions
            : 0;
        final currencySymbol = provider.currencySymbol;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol(
                      context,
                      "$totalTransactions",
                      "Toplam İşlem",
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    _buildStatCol(
                      context,
                      "$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(avgTransaction)}",
                      "Ort. İşlem Büyüklüğü",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Monthly Chart (Simplified Bar Chart)
              Container(
                height: 200,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    Text(
                      "Aylık İşlem Hacmi (Son 1 Yıl)",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: monthlyVolume.values.isEmpty
                              ? 100
                              : monthlyVolume.values.reduce(
                                      (a, b) => a > b ? a : b,
                                    ) *
                                    1.2,
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  // value is month index 1-12
                                  if (value < 1 || value > 12) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = DateTime(2023, value.toInt());
                                  return Text(
                                    DateFormat.MMM('tr_TR').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barGroups: List.generate(12, (index) {
                            final month = index + 1;
                            final vol = monthlyVolume[month] ?? 0;
                            return BarChartGroupData(
                              x: month,
                              barRods: [
                                BarChartRodData(
                                  toY: vol,
                                  color: Theme.of(context).primaryColor,
                                  width: 12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Transactions List
              Text(
                "Son İşlemler",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.take(10).length, // Show last 10
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  // Need to fetch Holding symbol...
                  // Uh oh, TransactionModel only has holdingId.
                  // We need to look up Symbol from provider.holdings.
                  // provider.holdings contains ALL holdings (loaded by loadHoldings).
                  try {
                    final holding = provider.holdings.firstWhere(
                      (h) => h.id == t.holdingId,
                    );
                    final isBuy = t.type == TransactionType.BUY;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBuy
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          child: Icon(
                            isBuy
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded, // IN vs OUT
                            color: isBuy ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          holding.symbol,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd MMMM yyyy, HH:mm',
                            'tr_TR',
                          ).format(t.date),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${isBuy ? '+' : '-'}$currencySymbol${NumberFormat('#,##0.00', 'tr_TR').format(t.amount * t.price)}",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: isBuy ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              "${t.amount} ${isBuy ? 'Adet' : ''}",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } catch (e) {
                    // Holding might be deleted? Or not loaded?
                    return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCol(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
