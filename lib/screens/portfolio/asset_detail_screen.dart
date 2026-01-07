import 'package:flutter/material.dart';

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
        // If it's become closed (quantity 0), it might be in the full list
        // holding.id should verify it.
        final currentHolding = provider.holdings.firstWhere(
          (h) => h.id == holding.id,
          orElse: () =>
              holding, // Fallback if not found (shouldn't happen if logic correct)
        );

        // Fetch price for P/L calculation
        double currentPrice = provider.getCurrentPrice(currentHolding.symbol);
        if (currentPrice == 0) currentPrice = currentHolding.averageCost;

        final currentValue = currentHolding.quantity * currentPrice;
        final totalCost = currentHolding.quantity * currentHolding.averageCost;
        final unrealizedPL = currentValue - totalCost;
        final plRate = totalCost > 0 ? (unrealizedPL / totalCost) * 100 : 0;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentHolding.symbol,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Detay & İşlemler",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.remove_red_eye),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                _buildInfoRow(
                  "Tutar",
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(currentValue)}',
                  true,
                ),
                _buildInfoRow("Adet", '${currentHolding.quantity}', false),
                _buildInfoRow(
                  "Alış Maliyeti",
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(currentHolding.averageCost)}',
                  false,
                ),
                _buildInfoRow(
                  "Güncel Fiyat",
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(currentPrice)}',
                  true,
                ), // Mocked for now
                const Divider(height: 24),
                _buildInfoRow(
                  "Toplam Kâr/Zarar (₺)",
                  '₺${NumberFormat('#,##0.00', 'tr_TR').format(unrealizedPL)}',
                  true,
                  color: unrealizedPL >= 0 ? Colors.green : Colors.red,
                ),
                _buildInfoRow(
                  "Toplam Kâr/Zarar (%)",
                  '%${plRate.toStringAsFixed(2)}',
                  true,
                  color: unrealizedPL >= 0 ? Colors.green : Colors.red,
                ),

                const SizedBox(height: 24),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) => AddTransactionScreen(
                          symbol: currentHolding.symbol,
                          name: "Varlık", // Simplified
                          initialPrice:
                              currentHolding.averageCost, // Simplified
                          type: currentHolding.type,
                        ),
                      );
                    },
                    child: const Text(
                      "Yeni İşlem Ekle",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Transaction History
                const Text(
                  "İşlemler",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                FutureBuilder<List<TransactionModel>>(
                  future: provider.getTransactionsForHolding(
                    currentHolding.id!,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final transactions = snapshot.data!;

                    if (transactions.isEmpty) {
                      return const Text("İşlem geçmişi bulunamadı.");
                    }

                    return Column(
                      children: transactions
                          .map((t) => _buildTransactionItem(t))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // If closed, maybe show closed summary better
                if (currentHolding.quantity == 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Bu pozisyon kapanmıştır. Toplam Realize Kâr: ₺${NumberFormat('#,##0.00', 'tr_TR').format(currentHolding.totalRealizedProfit)}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
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
    String label,
    String value,
    bool isBold, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final isBuy = t.type == TransactionType.BUY;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isBuy ? Colors.green[100] : Colors.red[100],
            child: Icon(
              isBuy ? Icons.arrow_upward : Icons.arrow_downward,
              color: isBuy ? Colors.green : Colors.red,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isBuy ? "Alış" : "Satış",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(t.date),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₺${NumberFormat('#,##0.00', 'tr_TR').format(t.amount * t.price)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${t.amount} ${isBuy ? 'Lot' : 'Lot'}", // Simplified unit
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
