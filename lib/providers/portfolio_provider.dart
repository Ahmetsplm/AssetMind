import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/portfolio.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import '../services/api_service.dart';
import '../services/asset_service.dart';
import '../services/widget_service.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SortOption { valueDesc, valueAsc, nameAsc }

class PortfolioProvider extends ChangeNotifier {
  List<Portfolio> _portfolios = [];
  Portfolio? _selectedPortfolio;
  List<Holding> _holdings = [];
  Map<String, double> _assetPrices = {};
  bool _isLoading = false;
  bool _isPrivacyMode = false;

  final AssetService _assetService = AssetService();
  StreamSubscription<AuthState>? _authSubscription;

  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get selectedPortfolio => _selectedPortfolio;
  List<Holding> get holdings => _holdings;
  bool get isLoading => _isLoading;
  bool get isPrivacyMode => _isPrivacyMode;
  SortOption _sortOption = SortOption.valueDesc;
  SortOption get sortOption => _sortOption;

  int get activeHoldingsCount => _holdings.where((h) => h.quantity > 0).length;

  PortfolioProvider() {
    _loadPrivacyMode();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        reset();
        loadPortfolios();
      } else if (data.event == AuthChangeEvent.signedOut) {
        reset();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void reset() {
    _portfolios = [];
    _selectedPortfolio = null;
    _holdings = [];
    _allTransactions = [];
    _historyPoints = [];
    _assetPrices = {};
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPrivacyMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isPrivacyMode = prefs.getBool('privacy_mode') ?? false;
    notifyListeners();
  }

  Future<void> togglePrivacyMode() async {
    _isPrivacyMode = !_isPrivacyMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_mode', _isPrivacyMode);
    notifyListeners();
  }

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
      if (h.quantity <= 0) continue; 
      final price = _assetPrices[h.symbol] ?? h.averageCost;
      final value = h.quantity * price;
      map[h.type] = (map[h.type] ?? 0) + value;
    }
    return map;
  }

  int getCountByType(AssetType type) {
    return _holdings.where((h) => h.type == type).length;
  }

  double getValueByType(AssetType type) {
    return valueByType[type] ?? 0;
  }

  List<Holding> getHoldingsByType(AssetType type) {
    return _holdings.where((h) => h.type == type).toList();
  }

  double getCurrentPrice(String symbol) {
    if (_assetPrices.containsKey(symbol) && _assetPrices[symbol]! > 0) {
      return _assetPrices[symbol]!;
    }
    // Fallback to average cost if available in any holding
    final h = _holdings.where((h) => h.symbol == symbol).firstOrNull;
    return h?.averageCost ?? 0.0;
  }

  Future<List<TransactionModel>> getTransactionsForHolding(int holdingId) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'transactions',
      where: 'holding_id = ?',
      whereArgs: [holdingId],
      orderBy: 'date DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  void _resolveSelectedPortfolio() {
    if (_portfolios.isNotEmpty) {
      if (_selectedPortfolio != null) {
        final stillExists = _portfolios.any((p) => p.id == _selectedPortfolio!.id);
        if (!stillExists) {
          _selectedPortfolio = null;
        }
      }
      _selectedPortfolio ??= _portfolios.firstWhere(
        (p) => p.isDefault,
        orElse: () => _portfolios.first,
      );
    } else {
      _selectedPortfolio = null;
      _holdings = [];
    }
  }

  Future<void> loadPortfolios() async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Local Read (Hızlı Gösterim)
    final localResult = await db.query('portfolios');
    _portfolios = localResult.map((e) => Portfolio.fromMap(e)).toList();
    _resolveSelectedPortfolio();
    notifyListeners();
    if (_selectedPortfolio != null) {
      await loadHoldings(); // Yerel holdingleri yükle
    }

    // 2. Cloud Sync (Senkronizasyon)
    if (_assetService.userId != null) {
      try {
        List<Portfolio> cloudPortfolios = await _assetService.getPortfolios();
        
        // İlk giriş yapan yeni kullanıcıya portföy açalım
        if (cloudPortfolios.isEmpty) {
          final newP = await _assetService.addPortfolio("Ana Portföy", isDefault: true);
          cloudPortfolios = [newP];
        }

        // Yereli temizle ve güncel bulutu yaz
        await db.delete('portfolios');
        for (var p in cloudPortfolios) {
          await db.insert('portfolios', p.toMap());
        }

        _portfolios = cloudPortfolios;
        _resolveSelectedPortfolio();
        notifyListeners();
        
        if (_selectedPortfolio != null) {
          await loadHoldings(); // Buluttan holdingleri de yükle
        }
      } catch (_) {
        // Çevrimdışı durumu, lokal verilerle devam edilecek.
      }
    } else {
      reset();
    }
  }

  Future<void> loadHoldings() async {
    if (_selectedPortfolio == null) return;
    _isLoading = true;
    notifyListeners();

    final db = await DatabaseHelper.instance.database;
    final pid = _selectedPortfolio!.id!;

    // 1. Local Read
    final localResult = await db.query(
      'holdings',
      where: 'portfolio_id = ?',
      whereArgs: [pid],
    );
    _holdings = localResult.map((e) => Holding.fromMap(e)).toList();
    await _fetchPrices();
    notifyListeners();

    // 2. Cloud Sync
    if (_assetService.userId != null) {
      try {
        final cloudHoldings = await _assetService.getHoldings(pid);
        
        await db.delete('holdings', where: 'portfolio_id = ?', whereArgs: [pid]);
        for (var h in cloudHoldings) {
          await db.insert('holdings', h.toMap());
        }
        
        _holdings = cloudHoldings;
        await _fetchPrices();
      } catch (_) {}
    }

    _isLoading = false;
    notifyListeners();
    await loadHistory();
  }

  String _selectedCurrency = 'TRY';
  String get selectedCurrency => _selectedCurrency;

  String get currencySymbol {
    switch (_selectedCurrency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '₺';
    }
  }

  void toggleCurrency() {
    if (_selectedCurrency == 'TRY') {
      _selectedCurrency = 'USD';
    } else if (_selectedCurrency == 'USD') {
      _selectedCurrency = 'EUR';
    } else {
      _selectedCurrency = 'TRY';
    }
    notifyListeners();
  }

  double getConversionRate() {
    if (_selectedCurrency == 'TRY') return 1.0;
    final rateSym = _selectedCurrency == 'USD' ? 'USD/TRY' : 'EUR/TRY';
    return _assetPrices[rateSym] ?? 1.0;
  }

  double get displayedTotalValue => totalPortfolioValue / getConversionRate();
  double get displayedTotalCost => totalPortfolioCost / getConversionRate();
  double get displayedTotalProfitLoss => totalProfitLoss / getConversionRate();

  Future<void> _fetchPrices() async {
    final List<String> symbols = _holdings.map((e) => e.symbol).toList();
    if (!symbols.contains('USD/TRY')) symbols.add('USD/TRY');
    if (!symbols.contains('EUR/TRY')) symbols.add('EUR/TRY');

    final api = ApiService();
    _assetPrices = await api.getCurrentPrices(symbols);

    if (_assetPrices['USD/TRY'] == null || _assetPrices['USD/TRY'] == 0) {
      await api.fetchForex();
      _assetPrices = await api.getCurrentPrices(symbols);
    }
    
    // Update Widget
    WidgetService.updatePortfolioWidget(
      totalValue: totalPortfolioValue,
      netProfit: totalProfitLoss,
      profitPercentage: totalProfitLossRate,
      assetCount: activeHoldingsCount,
    );
  }

  Future<void> addPortfolio(String name) async {
    if (_assetService.userId == null) return;
    
    final db = await DatabaseHelper.instance.database;
    try {
      final cloudP = await _assetService.addPortfolio(name, isDefault: _portfolios.isEmpty);
      await db.insert('portfolios', cloudP.toMap());
      await loadPortfolios();
    } catch (e) {
      throw Exception("Bağlantı hatası. İnternet olmadan yeni portföy açılamaz.");
    }
  }

  Future<void> renamePortfolio(int portfolioId, String newName) async {
    if (_assetService.userId == null) return;
    final db = await DatabaseHelper.instance.database;

    try {
      await _assetService.updatePortfolio(portfolioId, newName);
      await db.update(
        'portfolios',
        {'name': newName},
        where: 'id = ?',
        whereArgs: [portfolioId],
      );
      await loadPortfolios();
    } catch (e) {
       throw Exception("Bağlantı hatası. Güncelleme yapılamadı.");
    }
  }

  List<List<dynamic>> _historyPoints = [];
  List<List<dynamic>> get historyPoints => _historyPoints;

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> get allTransactions => _allTransactions;

  Future<void> loadHistory() async {
    if (_selectedPortfolio == null) return;
    final db = await DatabaseHelper.instance.database;
    final pid = _selectedPortfolio!.id!;

    // 1. Local
    final localTxs = await db.query(
      'transactions',
      where: 'holding_id IN (SELECT id FROM holdings WHERE portfolio_id = ?)',
      whereArgs: [pid],
      orderBy: 'date ASC',
    );
    _processTransactions(localTxs.map((e) => TransactionModel.fromMap(e)).toList());

    // 2. Cloud Sync
    if (_assetService.userId != null) {
      try {
        final cloudTxs = await _assetService.getAllTransactionsForPortfolio(pid);
        final holdingIds = _holdings.map((h) => h.id).toList();
        
        if (holdingIds.isNotEmpty) {
           await db.delete('transactions', where: 'holding_id IN (${holdingIds.join(',')})');
           for (var tx in cloudTxs) {
             await db.insert('transactions', tx.toMap());
           }
        }
        _processTransactions(cloudTxs);
      } catch (_) {}
    }
  }

  void _processTransactions(List<TransactionModel> txs) {
    _allTransactions = List.from(txs);
    _allTransactions.sort((a, b) => b.date.compareTo(a.date));

    final chronologicalTransactions = [...txs]..sort((a, b) => a.date.compareTo(b.date));
    double cumulativeValue = 0;
    List<List<dynamic>> points = [];

    for (var t in chronologicalTransactions) {
      final total = t.amount * t.price;
      if (t.type == TransactionType.BUY) {
        cumulativeValue += total;
      } else {
        cumulativeValue -= total;
      }
      if (cumulativeValue < 0) cumulativeValue = 0;
      points.add([t.date.millisecondsSinceEpoch.toDouble(), cumulativeValue]);
    }
    _historyPoints = points;
    notifyListeners();
  }

  void selectPortfolio(Portfolio portfolio) {
    _selectedPortfolio = portfolio;
    loadHoldings();
  }

  // Add Transaction (Buy / Sell Logic)
  Future<void> addTransaction(
    TransactionModel transaction,
    String symbol,
    AssetType type,
  ) async {
    if (_selectedPortfolio == null) return;
    if (_assetService.userId == null) {
      throw Exception("Varlık eklemek için lütfen giriş yapın.");
    }

    final db = await DatabaseHelper.instance.database;
    final pid = _selectedPortfolio!.id!;

    final holdingIndex = _holdings.indexWhere((h) => h.symbol == symbol);
    Holding updatedHolding;

    if (holdingIndex != -1) {
      final existing = _holdings[holdingIndex];
      double newQuantity = existing.quantity;
      double newAverageCost = existing.averageCost;
      double newRealizedProfit = existing.totalRealizedProfit;

      if (transaction.type == TransactionType.BUY) {
        final totalQuantity = existing.quantity + transaction.amount;
        final totalCost = (existing.quantity * existing.averageCost) + (transaction.amount * transaction.price);
        newAverageCost = totalCost / totalQuantity;
        newQuantity = totalQuantity;
      } else {
        if (transaction.amount > existing.quantity) {
          throw Exception("Satılacak miktar eldeki miktardan fazla olamaz!");
        }
        newQuantity = existing.quantity - transaction.amount;
        final realizedProfitFromThisSale = (transaction.price - existing.averageCost) * transaction.amount;
        newRealizedProfit += realizedProfitFromThisSale;
      }

      updatedHolding = Holding(
        id: existing.id,
        portfolioId: pid,
        symbol: symbol,
        type: type,
        quantity: newQuantity,
        averageCost: newAverageCost,
        totalRealizedProfit: newRealizedProfit,
        lastUpdate: DateTime.now(),
      );
    } else {
      if (transaction.type == TransactionType.SELL) {
        throw Exception("Portföyde olmayan bir varlığı satamazsınız!");
      }
      updatedHolding = Holding(
        portfolioId: pid,
        symbol: symbol,
        type: type,
        quantity: transaction.amount,
        averageCost: transaction.price,
        totalRealizedProfit: 0.0,
        lastUpdate: DateTime.now(),
      );
    }

    // 1. Buluta Yaz (Önce Supabase)
    try {
      final cloudHolding = await _assetService.upsertHolding(updatedHolding);
      final cloudTx = await _assetService.addTransaction(TransactionModel(
        holdingId: cloudHolding.id!,
        type: transaction.type,
        amount: transaction.amount,
        price: transaction.price,
        date: transaction.date,
      ));

      // 2. Yerele Yaz (Eşitleme)
      if (updatedHolding.id != null) {
         await db.update('holdings', cloudHolding.toMap(), where: 'id = ?', whereArgs: [cloudHolding.id]);
      } else {
         await db.insert('holdings', cloudHolding.toMap());
      }
      await db.insert('transactions', cloudTx.toMap());

      await loadHoldings();
    } catch (e) {
      throw Exception("Bağlantı hatası: $e");
    }
  }
}
