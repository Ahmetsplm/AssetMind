import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/portfolio.dart';
import '../models/holding.dart';
import '../models/transaction.dart';

class PortfolioProvider extends ChangeNotifier {
  List<Portfolio> _portfolios = [];
  Portfolio? _selectedPortfolio;

  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get selectedPortfolio => _selectedPortfolio;

  // Load portfolios from DB
  Future<void> loadPortfolios() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('portfolios');
    _portfolios = result.map((e) => Portfolio.fromMap(e)).toList();

    if (_portfolios.isNotEmpty) {
      // Logic to select default OR the first one
      _selectedPortfolio = _portfolios.firstWhere(
        (p) => p.isDefault,
        orElse: () => _portfolios.first,
      );
    }
    notifyListeners();
  }

  // Add new Portfolio
  Future<void> addPortfolio(String name) async {
    final db = await DatabaseHelper.instance.database;
    final newPortfolio = Portfolio(
      name: name,
      isDefault: _portfolios.isEmpty, // Default if it's the first one
      creationDate: DateTime.now(),
    );

    await db.insert('portfolios', newPortfolio.toMap());
    await loadPortfolios(); // Reload to get IDs and fresh list

    // Select the newly created portfolio
    if (_portfolios.isNotEmpty) {
      _selectedPortfolio = _portfolios.last;
      notifyListeners();
    }
  }

  // Select a different portfolio
  void selectPortfolio(Portfolio portfolio) {
    _selectedPortfolio = portfolio;
    notifyListeners();
  }

  // Add Transaction (Buy Logic)
  Future<void> addTransaction(
    TransactionModel transaction,
    String symbol,
    AssetType type,
  ) async {
    if (_selectedPortfolio == null) return;

    final db = await DatabaseHelper.instance.database;

    // 1. Check if holding exists for this portfolio and symbol
    final holdingResult = await db.query(
      'holdings',
      where: 'portfolio_id = ? AND symbol = ?',
      whereArgs: [_selectedPortfolio!.id, symbol],
    );

    int holdingId;

    if (holdingResult.isNotEmpty) {
      // UPDATE existing holding
      final existingHolding = Holding.fromMap(holdingResult.first);

      // Calculate Weighted Average Cost
      final totalQuantity = existingHolding.quantity + transaction.amount;
      final totalCost =
          (existingHolding.quantity * existingHolding.averageCost) +
          (transaction.amount * transaction.price);
      final newAverageCost = totalCost / totalQuantity;

      // New holding object
      final updatedHolding = Holding(
        id: existingHolding.id,
        portfolioId: existingHolding.portfolioId,
        symbol: existingHolding.symbol,
        type: existingHolding.type,
        quantity: totalQuantity,
        averageCost: newAverageCost,
        totalRealizedProfit:
            existingHolding.totalRealizedProfit, // Unchanged on BUY
        lastUpdate: DateTime.now(),
      );

      await db.update(
        'holdings',
        updatedHolding.toMap(),
        where: 'id = ?',
        whereArgs: [existingHolding.id],
      );
      holdingId = existingHolding.id!;
    } else {
      // INSERT new holding
      final newHolding = Holding(
        portfolioId: _selectedPortfolio!.id!,
        symbol: symbol,
        type: type,
        quantity: transaction.amount,
        averageCost: transaction.price,
        totalRealizedProfit: 0.0,
        lastUpdate: DateTime.now(),
      );

      holdingId = await db.insert('holdings', newHolding.toMap());
    }

    // 2. Insert Transaction record
    final newTransaction = TransactionModel(
      holdingId: holdingId,
      type: transaction.type,
      amount: transaction.amount,
      price: transaction.price,
      date: transaction.date,
    );

    await db.insert('transactions', newTransaction.toMap());
    notifyListeners();
  }
}
