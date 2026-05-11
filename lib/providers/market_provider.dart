import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/asset_service.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class MarketProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ApiService _api = ApiService();

  Timer? _cryptoTimer;
  Timer? _bistTimer;
  Timer? _forexTimer;
  Timer? _globalTimer;
  Timer? _fundTimer;
  Timer? _foregroundAlertTimer;

  bool _isInit = false;
  DateTime? _lastFetchTime;

  DateTime? get lastFetchTime => _lastFetchTime;
  
  double getPrice(String symbol) {
    return _api.getAsset(symbol)?.price ?? 0.0;
  }

  AssetCacheModel? getAsset(String symbol) {
    return _api.getAsset(symbol);
  }

  Future<void> fetchSingleAndNotify(String symbol) async {
    // Sadece anlık UI gösterimi için geçici (transient) fetch
    await _api.fetchSingle(symbol, isTransient: true);
    notifyListeners();
  }

  String get lastUpdateText {
    if (_lastFetchTime == null) return "Güncelleniyor...";
    final diff = DateTime.now().difference(_lastFetchTime!);
    if (diff.inMinutes < 1) return "Az önce güncellendi";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce güncellendi";
    
    final h = _lastFetchTime!.hour.toString().padLeft(2, '0');
    final m = _lastFetchTime!.minute.toString().padLeft(2, '0');
    return "Son Güncelleme: $h:$m";
  }

  MarketProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkAndRefreshPricesIfNeeded();
    }
  }

  void checkAndRefreshPricesIfNeeded() {
    if (_lastFetchTime == null) {
      fetchAllPrices();
      return;
    }
    final diff = DateTime.now().difference(_lastFetchTime!);
    if (diff.inMinutes >= 15) {
      fetchAllPrices();
    }
  }

  Future<void> fetchAllPrices() async {
    await Future.wait([
      _fetchCrypto(),
      _fetchBist(),
      _fetchForex(),
      _fetchGlobal(),
      _fetchFunds(),
    ]);
    _lastFetchTime = DateTime.now();
    notifyListeners();
    _updateWidgetData();
  }

  Future<void> _updateWidgetData() async {
    try {
      final favs = await AssetService().getFavorites();
      List<Map<String, dynamic>> favWidgetData = [];
      for (var f in favs) {
        final sym = f['symbol'] as String? ?? '';
        if (sym.isEmpty) continue;
        var asset = _api.getAsset(sym) ?? _api.getAsset('$sym.IS');
        if (asset != null) {
          favWidgetData.add({
            'symbol': sym.replaceAll('.IS', ''),
            'price': asset.price,
            'change': asset.change,
          });
        }
      }
      await WidgetService.updateWatchlistWidget(favWidgetData);

      // --- Portfolio Widget Update ---
      final portfolios = await AssetService().getPortfolios();
      double totalValue = 0;
      double totalCost = 0;
      int assetCount = 0;
      
      for (var p in portfolios) {
        final holdings = await AssetService().getHoldings(p.id!);
        for (var h in holdings) {
          if (h.quantity <= 0) continue;
          var asset = _api.getAsset(h.symbol) ?? _api.getAsset('${h.symbol}.IS');
          double price = asset?.price ?? h.averageCost;
          totalValue += h.quantity * price;
          totalCost += h.quantity * h.averageCost;
          assetCount++;
        }
      }
      
      double netProfit = totalValue - totalCost;
      double profitPercentage = totalCost > 0 ? (netProfit / totalCost) * 100 : 0.0;
      
      await WidgetService.updatePortfolioWidget(
        totalValue: totalValue,
        netProfit: netProfit,
        profitPercentage: profitPercentage,
        assetCount: assetCount,
      );
    } catch (e) {
      debugPrint("Widget update from MarketProvider failed: $e");
    }
  }

  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;

    // 1. Load Cache (Sync-like user experience)
    await _api.init();
    notifyListeners(); // Show initial cached data immediately

    // Always fetch latest on app start
    await fetchAllPrices();

    // 2. Start Schedulers
    _startCryptoTimer();
    _startBistTimer();
    _startForexTimer();
    _startGlobalTimer();
    _startFundTimer();
    _startForegroundAlertTimer();
  }

  // --- FOREGROUND ALERTS SCHEDULER (30s) ---
  void _startForegroundAlertTimer() {
    _foregroundAlertTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkForegroundAlerts();
    });
  }

  Future<void> _checkForegroundAlerts() async {
    try {
      final assetService = AssetService();
      if (assetService.userId == null) return; // User not logged in

      final alerts = await assetService.getActiveAlerts();
      if (alerts.isEmpty) return;

      final notificationService = NotificationService();

      for (var alert in alerts) {
        double price = getPrice(alert.symbol);
        if (price == 0.0) {
          price = getPrice('${alert.symbol}.IS');
        }
        
        if (price == 0.0) continue;

        bool triggered = false;
        if (alert.condition == 'above' && price >= alert.targetPrice) {
          triggered = true;
        } else if (alert.condition == 'below' && price <= alert.targetPrice) {
          triggered = true;
        }

        if (triggered) {
          await notificationService.showNotification(
            id: alert.id.hashCode,
            title: 'Fiyat Alarmı: ${alert.symbol}',
            body: '${alert.symbol} belirlediğiniz hedef fiyata ulaştı! Güncel: \$${price.toStringAsFixed(2)}',
          );
          await assetService.deactivateAlert(alert.id);
        }
      }
    } catch (e) {
      debugPrint("Foreground Alert Check Error: $e");
    }
  }

  // --- 1. CRYPTO SCHEDULER (15s) ---
  void _startCryptoTimer() {
    _cryptoTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchCrypto();
    });
  }

  Future<void> _fetchCrypto() async {
    await _api.fetchCrypto();
    notifyListeners();
  }

  // --- 2. BIST SCHEDULER (10m - Business Hours) ---
  void _startBistTimer() {
    _bistTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _checkAndFetchBist();
    });
  }

  Future<void> _checkAndFetchBist() async {
    final now = DateTime.now();

    final bool isWeekday = now.weekday >= 1 && now.weekday <= 5;
    final bool isOpen = now.hour >= 9 && now.hour < 19;

    if (isWeekday && isOpen) {
      await _fetchBist(); // includes Gold Ounce
      notifyListeners();
    }
    // Else do nothing, preserve cache
  }

  Future<void> _fetchBist() async {
    await _api.fetchBist();
  }

  // --- 3. FOREX SCHEDULER (1h) ---
  void _startForexTimer() {
    _forexTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _fetchForex();
    });
  }

  Future<void> _fetchForex() async {
    await _api.fetchForex();
    notifyListeners();
  }

  // --- 4. GLOBAL SCHEDULER (15m) ---
  void _startGlobalTimer() {
    _globalTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _fetchGlobal();
    });
  }

  Future<void> _fetchGlobal() async {
    await _api.fetchGlobal();
    notifyListeners();
  }

  // --- 5. FUND SCHEDULER (1h) ---
  void _startFundTimer() {
    _fundTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _fetchFunds();
    });
  }

  Future<void> _fetchFunds() async {
    await _api.fetchFunds();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cryptoTimer?.cancel();
    _bistTimer?.cancel();
    _forexTimer?.cancel();
    _globalTimer?.cancel();
    _fundTimer?.cancel();
    _foregroundAlertTimer?.cancel();
    super.dispose();
  }
}
