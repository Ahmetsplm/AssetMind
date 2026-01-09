import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class MarketProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Timer? _cryptoTimer;
  Timer? _bistTimer;
  Timer? _forexTimer;

  bool _isInit = false;

  Future<void> init() async {
    if (_isInit) return;
    _isInit = true;

    // 1. Load Cache (Sync-like user experience)
    await _api.init();
    notifyListeners(); // Show initial cached data immediately

    // 2. Start Schedulers
    _startCryptoTimer();
    _startBistTimer();
    _startForexTimer();
  }

  // --- 1. CRYPTO SCHEDULER (15s) ---
  void _startCryptoTimer() {
    // Run immediately first
    _fetchCrypto();

    _cryptoTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchCrypto();
    });
  }

  Future<void> _fetchCrypto() async {
    print("MarketProvider: Fetching Crypto...");
    await _api.fetchCrypto();
    print("MarketProvider: Crypto Fetched. Notifying listeners.");
    notifyListeners();
  }

  // --- 2. BIST SCHEDULER (10m - Business Hours) ---
  void _startBistTimer() {
    // Initial check: if cache is empty, force fetch regardless of time (Fix Night Install)
    if (_api.isCacheEmpty) {
      _fetchBist();
    } else {
      // Otherwise check rules
      _checkAndFetchBist();
    }

    _bistTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _checkAndFetchBist();
    });
  }

  Future<void> _checkAndFetchBist() async {
    final now = DateTime.now();
    // UTC+3 Correction explicitly if needed, but simple DateTime.now() usually
    // reflects device time which user expects.
    // Rule: Mon(1) - Fri(5). Hours 10 - 18.

    final bool isWeekday = now.weekday >= 1 && now.weekday <= 5;
    final bool isOpen = now.hour >= 10 && now.hour < 18;

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
    _fetchForex(); // Initial
    _forexTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _fetchForex();
    });
  }

  Future<void> _fetchForex() async {
    await _api.fetchForex();
    notifyListeners();
  }

  @override
  void dispose() {
    _cryptoTimer?.cancel();
    _bistTimer?.cancel();
    _forexTimer?.cancel();
    super.dispose();
  }
}
