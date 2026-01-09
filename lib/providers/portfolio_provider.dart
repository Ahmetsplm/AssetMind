import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/portfolio.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';

enum SortOption { valueDesc, valueAsc, nameAsc }

class PortfolioProvider extends ChangeNotifier {
  List<Portfolio> _portfolios = [];
  Portfolio? _selectedPortfolio;
  List<Holding> _holdings = [];
  Map<String, double> _assetPrices = {};
  bool _isLoading = false;

  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get selectedPortfolio => _selectedPortfolio;
  List<Holding> get holdings => _holdings;
  bool get isLoading => _isLoading;
  SortOption _sortOption = SortOption.valueDesc;
  SortOption get sortOption => _sortOption;

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  // Stats
  double get totalPortfolioValue => _holdings.fold(0, (sum, h) {
    if (h.quantity <= 0) return sum; // Skip closed positions
    final price = _assetPrices[h.symbol] ?? h.averageCost;
    return sum + (h.quantity * price);
  });

  double get totalPortfolioCost => _holdings.fold(0, (sum, h) {
    if (h.quantity <= 0) return sum;
    return sum + (h.quantity * h.averageCost);
  });

  double get totalProfitLoss => totalPortfolioValue - totalPortfolioCost;

  double get totalProfitLossRate {
    if (totalPortfolioCost == 0) return 0;
    return (totalProfitLoss / totalPortfolioCost) * 100;
  }

  // Stats by Type
  Map<AssetType, double> get valueByType {
    final Map<AssetType, double> map = {};
    for (var h in _holdings) {
      if (h.quantity <= 0) continue; // Skip closed positions for value charts
      final price = _assetPrices[h.symbol] ?? h.averageCost;
      final value = h.quantity * price;
      map[h.type] = (map[h.type] ?? 0) + value;
    }
    return map;
  }

  int getCountByType(AssetType type) {
    return _holdings.where((h) => h.type == type && h.quantity > 0).length;
  }

  double getValueByType(AssetType type) {
    return valueByType[type] ?? 0;
  }

  List<Holding> getHoldingsByType(AssetType type) {
    return _holdings.where((h) => h.type == type).toList();
  }

  double getCurrentPrice(String symbol) {
    return _assetPrices[symbol] ?? 0.0;
  }

  Future<List<TransactionModel>> getTransactionsForHolding(
    int holdingId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'transactions',
      where: 'holding_id = ?',
      whereArgs: [holdingId],
      orderBy: 'date DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<void> loadPortfolios() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('portfolios');
    _portfolios = result.map((e) => Portfolio.fromMap(e)).toList();

    if (_portfolios.isNotEmpty) {
      if (_selectedPortfolio == null) {
        _selectedPortfolio = _portfolios.firstWhere(
          (p) => p.isDefault,
          orElse: () => _portfolios.first,
        );
      }
      await loadHoldings();
    }
    notifyListeners();
  }

  Future<void> loadHoldings() async {
    if (_selectedPortfolio == null) return;
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'holdings',
      where: 'portfolio_id = ?', // Fetch ALL holdings, including closed
      whereArgs: [_selectedPortfolio!.id],
    );

    _holdings = result.map((e) => Holding.fromMap(e)).toList();

    await _fetchPrices();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchPrices() async {
    if (_holdings.isEmpty) return;
    final symbols = _holdings.map((e) => e.symbol).toList();
    final api = ApiService(); // Or inject
    _assetPrices = await api.getCurrentPrices(symbols);
  }

  Future<void> addPortfolio(String name) async {
    final db = await DatabaseHelper.instance.database;
    final newPortfolio = Portfolio(
      name: name,
      isDefault: _portfolios.isEmpty,
      creationDate: DateTime.now(),
    );

    await db.insert('portfolios', newPortfolio.toMap());
    // Reload
    final result = await db.query('portfolios');
    _portfolios = result.map((e) => Portfolio.fromMap(e)).toList();

    // Select the new one
    if (_portfolios.isNotEmpty) {
      _selectedPortfolio = _portfolios.last;
      await loadHoldings();
    }
    notifyListeners();
  }

  List<List<dynamic>> _historyPoints = [];
  List<List<dynamic>> get historyPoints => _historyPoints;

  Future<void> loadHistory() async {
    if (_selectedPortfolio == null) return;

    final db = await DatabaseHelper.instance.database;
    final transactions = await db.query(
      'transactions',
      where: 'holding_id IN (SELECT id FROM holdings WHERE portfolio_id = ?)',
      whereArgs: [_selectedPortfolio!.id],
      orderBy: 'date ASC',
    );

    double cumulativeValue = 0;
    List<List<dynamic>> points = [];

    // Initial point
    if (transactions.isNotEmpty) {
      // Add a starting point just before the first transaction?
      // Or just start from 0 at the first date?
    }

    for (var t in transactions) {
      final dynamic typeRaw = t['type'];
      int typeIndex = 0;

      if (typeRaw is int) {
        typeIndex = typeRaw;
      } else if (typeRaw is String) {
        // Try parsing "0" or "1"
        final parsed = int.tryParse(typeRaw);
        if (parsed != null) {
          typeIndex = parsed;
        } else {
          // Fallback for legacy "BUY"/"SELL" strings if they exist
          if (typeRaw == 'SELL' || typeRaw == 'TransactionType.SELL')
            typeIndex = 1;
        }
      }

      final amount = t['amount'] as double;
      final price = t['price'] as double;
      final total = amount * price;
      final dateStr = t['date'] as String;
      final date = DateTime.parse(dateStr); // Database stores ISO string

      // Enums: BUY=0, SELL=1
      if (typeIndex == 0) {
        // BUY
        cumulativeValue += total;
      } else {
        // SELL
        cumulativeValue -= total;
      }

      // Ensure positive only?
      if (cumulativeValue < 0) cumulativeValue = 0;

      points.add([date.millisecondsSinceEpoch.toDouble(), cumulativeValue]);
    }
    _historyPoints = points;
    notifyListeners();
  }

  void selectPortfolio(Portfolio portfolio) {
    _selectedPortfolio = portfolio;
    loadHoldings();
    loadHistory(); // Load history when selected
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

      double newQuantity = existingHolding.quantity;
      double newAverageCost = existingHolding.averageCost;
      double newRealizedProfit = existingHolding.totalRealizedProfit;

      if (transaction.type == TransactionType.BUY) {
        final totalQuantity = existingHolding.quantity + transaction.amount;
        final totalCost =
            (existingHolding.quantity * existingHolding.averageCost) +
            (transaction.amount * transaction.price);
        newAverageCost = totalCost / totalQuantity;
        newQuantity = totalQuantity;
      } else {
        // SELL Logic
        if (transaction.amount > existingHolding.quantity) {
          throw Exception("Satılacak miktar eldeki miktardan fazla olamaz!");
        }
        newQuantity = existingHolding.quantity - transaction.amount;
        // Average cost does NOT change on sell

        // Calculate Realized Profit
        final realizedProfitFromThisSale =
            (transaction.price - existingHolding.averageCost) *
            transaction.amount;
        newRealizedProfit += realizedProfitFromThisSale;
      }

      // New holding object
      final updatedHolding = Holding(
        id: existingHolding.id,
        portfolioId: existingHolding.portfolioId,
        symbol: existingHolding.symbol,
        type: existingHolding.type,
        quantity: newQuantity,
        averageCost: newAverageCost,
        totalRealizedProfit: newRealizedProfit,
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
      if (transaction.type == TransactionType.SELL) {
        throw Exception("Portföyde olmayan bir varlığı satamazsınız!");
      }

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
    await loadHoldings(); // Refresh holdings and stats
    await loadHistory();
  }
}
