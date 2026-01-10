import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/portfolio_provider.dart';
import '../../models/holding.dart';
import '../../models/transaction.dart';
import '../add_asset/add_transaction_screen.dart';

class AssetDetailScreen extends StatelessWidget {
  final Holding holding;

  const AssetDetailScreen({super.key, required this.holding});

  @override
  Widget build(BuildContext context) {
    // Need to listen to provider to get updates on this specific holding
    return Consumer<PortfolioProvider>(
      builder: (context, provider, child) {
        // Find the updated holding from the list to ensure we show latest data
        final currentHolding = provider.holdings.firstWhere(
          (h) => h.id == holding.id,
          orElse: () => holding,
        );

        // Fetch price for P/L calculation
        double currentPrice = provider.getCurrentPrice(currentHolding.symbol);
        if (currentPrice == 0) currentPrice = currentHolding.averageCost;

        final currentValue = currentHolding.quantity * currentPrice;
        final totalCost = currentHolding.quantity * currentHolding.averageCost;
        final unrealizedPL = currentValue - totalCost;
        final plRate = totalCost > 0 ? (unrealizedPL / totalCost) * 100 : 0;
        final isProfit = unrealizedPL >= 0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            iconTheme: Theme.of(context).iconTheme,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentHolding.symbol,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Detay & İşlemler",
                  style: GoogleFonts.poppins(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        "Tutar",
                        '₺${NumberFormat('#,##0.00', 'tr_TR').format(currentValue)}',
                        true,
                        null,
                      ),
                      _buildInfoRow(
                        context,
                        "Adet",
                        '${currentHolding.quantity}',
                        false,
                        null,
                      ),
                      _buildInfoRow(
                        context,
                        "Alış Maliyeti",
                        '₺${NumberFormat('#,##0.00', 'tr_TR').format(currentHolding.averageCost)}',
                        false,
                        null,
                      ),
                      _buildInfoRow(
                        context,
                        "Güncel Fiyat",
                        '₺${NumberFormat('#,##0.00', 'tr_TR').format(currentPrice)}',
                        true,
                        null,
                      ),
                      Divider(
                        height: 24,
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.2),
                      ),
                      _buildInfoRow(
                        context,
                        "Toplam Kâr/Zarar (₺)",
                        '₺${NumberFormat('#,##0.00', 'tr_TR').format(unrealizedPL)}',
                        true,
                        isProfit ? Colors.green : Colors.red,
                      ),
                      _buildInfoRow(
                        context,
                        "Toplam Kâr/Zarar (%)",
                        '%${plRate.toStringAsFixed(2)}',
                        true,
                        isProfit ? Colors.green : Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                      foregroundColor: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddTransactionScreen(
                          symbol: currentHolding.symbol,
                          name: "Varlık", // Simplified
                          initialPrice: currentHolding.averageCost,
                          type: currentHolding.type,
                        ),
                      );
                    },
                    child: Text(
                      "Yeni İşlem Ekle",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Transaction History
                Text(
                  "İşlemler",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 16),

                FutureBuilder<List<TransactionModel>>(
                  future: provider.getTransactionsForHolding(
                    currentHolding.id!,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      );
                    }
                    final transactions = snapshot.data!;

                    if (transactions.isEmpty) {
                      return Text(
                        "İşlem geçmişi bulunamadı.",
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).disabledColor,
                        ),
                      );
                    }

                    return Column(
                      children: transactions
                          .map((t) => _buildTransactionItem(context, t))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),

                if (currentHolding.quantity == 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Bu pozisyon kapanmıştır.\nToplam Realize Kâr: ₺${NumberFormat('#,##0.00', 'tr_TR').format(currentHolding.totalRealizedProfit)}",
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    bool isBold,
    Color? color, // Positional -> Named if possible, but keeping logic
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel t) {
    final isBuy = t.type == TransactionType.BUY;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isBuy
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isBuy ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isBuy ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBuy ? "Alış" : "Satış",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(t.date),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(t.amount * t.price)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              Text(
                "${t.amount} Adet",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
