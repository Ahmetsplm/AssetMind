import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/holding.dart';

// Helper Model for Cache
class AssetCacheModel {
  final double price;
  final double change;
  final String lastUpdated;

  AssetCacheModel({
    required this.price,
    required this.change,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'price': price,
    'change': change,
    'lastUpdated': lastUpdated,
  };

  factory AssetCacheModel.fromJson(Map<String, dynamic> json) {
    return AssetCacheModel(
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }
}

// AssetType is imported from holding.dart

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- WHITELISTS (Production Rules) ---
  static const List<String> _whitelistBist = [
    'AKBNK.IS', 'ALARK.IS', 'ARCLK.IS', 'ASELS.IS', 'BIMAS.IS', 'EREGL.IS',
    'FROTO.IS', 'GARAN.IS', 'HEKTS.IS', 'ISCTR.IS', 'KCHOL.IS', 'KOZAL.IS',
    'PETKM.IS', 'SAHOL.IS', 'SISE.IS', 'TCELL.IS', 'THYAO.IS', 'TOASO.IS',
    'TUPRS.IS', 'YKBNK.IS', 'PGSUS.IS', 'KONTR.IS', 'GESAN.IS', 'ASTOR.IS',
    'XU100.IS', // Endeks (Display: BIST 100)
  ];

  static const List<String> _whitelistCrypto = [
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'SOLUSDT',
    'XRPUSDT',
    'ADAUSDT',
    'DOGEUSDT',
    'AVAXUSDT',
    'TRXUSDT',
    'LINKUSDT',
    'MATICUSDT',
    'DOTUSDT',
    'LTCUSDT',
    'SHIBUSDT',
    'ATOMUSDT',
  ];

  static const List<String> _whitelistForex = [
    'USD',
    'EUR',
    'GBP',
    'CHF',
    'CAD',
    'JPY',
  ];

  // --- CONFIG ---
  static const String _binance24hrUrl =
      "https://api.binance.com/api/v3/ticker/24hr";
  static const String _frankfurterBaseUrl =
      "https://api.frankfurter.app/latest";
  static const Map<String, String> _headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  };
  static const String _cacheKey = "asset_mind_rich_cache_v1";

  // --- STATE ---
  /// In-memory cache: Symbol -> Model
  final Map<String, AssetCacheModel> _cache = {};
  double? _cachedUsdTry; // Helper for conversions

  // --- PUBLIC API ---

  /// 1. Initialize Cache from Disk
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_cacheKey);
      if (jsonString != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        decoded.forEach((key, value) {
          _cache[key] = AssetCacheModel.fromJson(value);
        });
      }
      // Restore USDTRY specific helper if available in cache for logic needs
      if (_cache.containsKey('USD/TRY')) {
        _cachedUsdTry = _cache['USD/TRY']!.price;
      }
    } catch (e) {
      print("Cache Load Error: $e");
    }
  }

  /// 2. Get Data (Directly from Cache)
  Map<String, double> get cachedPrices {
    return _cache.map((key, value) => MapEntry(key, value.price));
  }

  // Safe Accessor for UI
  AssetCacheModel? getAsset(String symbol) => _cache[symbol];

  bool get isCacheEmpty => _cache.isEmpty;

  /// 3. FETCH: BIST & Gold (Yahoo Chart)
  Future<void> fetchBist() async {
    // Add Gold Ounce to fetch list
    final List<String> targets = List.from(_whitelistBist)..add("GC=F");

    // Yahoo v8 Parallel Fetch
    await Future.wait(
      targets.map((s) async {
        await _fetchYahooSingle(s);
      }),
    );

    // Calculate Gold Types if data exists
    _calculateGold();

    await _saveCache();
  }

  /// 4. FETCH: Crypto (Binance)
  Future<void> fetchCrypto() async {
    try {
      // Fetch all tickers (~2MB json, fast enough) or usage specific endpoint?
      // Since we whitelist only ~20, let's filter the big list or use parallel.
      // Parallel logic is safer for bandwidth if whitelist small.
      // BUT Binance 24hr is one request. Let's do huge request, filter local.
      final response = await http.get(Uri.parse(_binance24hrUrl));
      if (response.statusCode == 200) {
        final List<dynamic> all = jsonDecode(response.body);

        await _ensureUsdRate(); // Need USD for conversion
        if (_cachedUsdTry == null) return; // Cannot convert without USD

        for (var item in all) {
          final String symbol = item['symbol'];
          if (_whitelistCrypto.contains(symbol)) {
            final double priceUsd =
                double.tryParse(item['lastPrice'].toString()) ?? 0.0;
            final double change =
                double.tryParse(item['priceChangePercent'].toString()) ?? 0.0;

            final double priceTl = priceUsd * _cachedUsdTry!;
            final String simpleSymbol = symbol.replaceAll(
              "USDT",
              "",
            ); // BTCUSDT -> BTC

            _updateCache(simpleSymbol, priceTl, change);
          }
        }
        await _saveCache();
      }
    } catch (e) {
      print("Binance Fetch Error: $e");
    }
  }

  /// 5. FETCH: Forex (Frankfurter)
  Future<void> fetchForex() async {
    try {
      final String toSyms = _whitelistForex.where((x) => x != "USD").join(',');
      // Base USD -> we get 1 USD = X TRY, 1 USD = Y EUR.
      // We need X/TRY.
      final url = Uri.parse("$_frankfurterBaseUrl?from=USD&to=TRY,$toSyms");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'];

        final double usdTry = (rates['TRY'] as num).toDouble();
        _cachedUsdTry = usdTry;

        // USD Special
        // Calculate change for USD? Yahoo might be better for change.
        // For now, assume 0 for Frankfurter or fetch history?
        // User agreed: "if hist unavailable, set to 0".
        _updateCache("USD/TRY", usdTry, 0.0);

        for (var cur in _whitelistForex) {
          if (cur == "USD") continue; // Handled
          if (cur == "TRY") continue;

          if (rates.containsKey(cur)) {
            final double usdToCur = (rates[cur] as num)
                .toDouble(); // 1 USD = ? EUR
            // 1 EUR = ? USD -> 1/usdToCur
            // 1 EUR in TL = (1/usdToCur) * USDTRY
            final double priceTl = (1.0 / usdToCur) * usdTry;
            _updateCache("$cur/TRY", priceTl, 0.0);
          }
        }
        await _saveCache();
      }
    } catch (e) {
      print("Forex Fetch Error: $e");
    }
  }

  // --- PRIVATE HELPERS ---

  Future<void> _fetchYahooSingle(String symbol) async {
    try {
      final url = Uri.parse(
        "https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1d&range=1d",
      );
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final result = json['chart']['result'][0];
        final meta = result['meta'];

        double current = (meta['regularMarketPrice'] as num).toDouble();
        double prev = (meta['chartPreviousClose'] as num).toDouble();

        double change = 0.0;
        if (prev > 0) change = ((current - prev) / prev) * 100;

        // BIST 100 Fix
        if (symbol == "XU100.IS" && current > 50000) current /= 100;

        _updateCache(symbol, current, change);
      }
    } catch (_) {}
  }

  void _calculateGold() {
    // Needs GC=F and USD/TRY
    if (_cache.containsKey('GC=F') && _cachedUsdTry != null) {
      final ons = _cache['GC=F']!; // AssetCacheModel
      final double gramPrice = (ons.price / 31.1035) * _cachedUsdTry!;

      // Change percent is assumed same as Ounce
      final double chg = ons.change;

      _updateCache("GRAM", gramPrice, chg);
      _updateCache("CEYREK", gramPrice * 1.63, chg);
      _updateCache("YARIM", gramPrice * 3.26, chg);
      _updateCache("TAM", gramPrice * 6.52, chg);
      _updateCache("CUMHURIYET", gramPrice * 6.70, chg);
    }
  }

  Future<void> _ensureUsdRate() async {
    if (_cachedUsdTry != null) return;
    // Check cache first
    if (_cache.containsKey("USD/TRY")) {
      _cachedUsdTry = _cache["USD/TRY"]!.price;
      return;
    }
    // Else fetch simple
    await fetchForex();
  }

  void _updateCache(String symbol, double price, double change) {
    _cache[symbol] = AssetCacheModel(
      price: price,
      change: change,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_cache);
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      print("Save Cache Error: $e");
    }
  }

  // --- UI PROVIDERS (Read from Cache) ---
  // Just simple accessors now, logic is in Fetchers

  Future<List<Map<String, dynamic>>> getMarketSummary() async {
    // Return specific keys for Home Screen
    final List<Map<String, dynamic>> list = [];

    // Helper
    void add(String sym, String display) {
      final item = _cache[sym] ?? _cache["$sym.IS"]; // Try both
      if (item != null) {
        list.add({
          'symbol': display,
          'value': item.price,
          'change_rate': double.parse(item.change.toStringAsFixed(2)),
          'is_rising': item.change >= 0,
        });
      }
    }

    add("XU100.IS", "BIST 100");
    add("USD/TRY", "Dolar");
    add("EUR/TRY", "Euro");
    add("GRAM", "Gram Altın");

    return list;
  }

  Future<List<Map<String, dynamic>>> getStockMovers({
    bool isRising = true,
  }) async {
    // Filter cache for BIST symbols
    final items = _cache.entries
        .where((e) => e.key.endsWith(".IS") && e.key != "XU100.IS")
        .map(
          (e) => {
            'symbol': e.key.replaceAll(".IS", ""),
            'price': e.value.price,
            'change': e.value.change,
          },
        )
        .toList();

    items.sort(
      (a, b) => (b['change'] as double).compareTo(a['change'] as double),
    );

    if (isRising)
      return items.where((i) => (i['change'] as double) > 0).take(5).toList();
    return items.reversed
        .where((i) => (i['change'] as double) < 0)
        .take(5)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCryptoMovers({
    bool isRising = true,
  }) async {
    // Filter cache for Crypto (Keys that are in whitelist without USDT suffix usually)
    // In fetchCrypto we stored them as "BTC", "ETH" etc.
    final items = _cache.entries
        .where(
          (e) =>
              !e.key.contains(".IS") &&
              !e.key.contains("=") &&
              !e.key.contains("/TRY") &&
              !["GRAM", "CEYREK", "YARIM", "TAM", "CUMHURIYET"].contains(e.key),
        )
        .map(
          (e) => {
            'symbol': e.key,
            'price': e.value.price,
            'change': e.value.change,
          },
        )
        .toList();

    items.sort(
      (a, b) => (b['change'] as double).compareTo(a['change'] as double),
    );

    if (isRising)
      return items.where((i) => (i['change'] as double) > 0).take(5).toList();
    return items.reversed
        .where((i) => (i['change'] as double) < 0)
        .take(5)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAssetsByType(AssetType type) async {
    final List<Map<String, dynamic>> results = [];

    switch (type) {
      case AssetType.STOCK:
        for (var s in _whitelistBist) {
          if (s == "XU100.IS") continue;
          final d = _cache[s];
          if (d != null) {
            results.add({
              'symbol': s,
              'name': s.replaceAll(".IS", ""),
              'price': d.price,
              'change': d.change,
            });
          }
        }
        break;
      case AssetType.CRYPTO:
        for (var s in _whitelistCrypto) {
          final outputSym = s.replaceAll("USDT", "");
          final d = _cache[outputSym];
          if (d != null) {
            results.add({
              'symbol': outputSym,
              'name': s,
              'price': d.price,
              'change': d.change,
            });
          }
        }
        break;
      case AssetType.GOLD:
        for (var s in ["GRAM", "CEYREK", "YARIM", "TAM", "CUMHURIYET"]) {
          final d = _cache[s];
          if (d != null)
            results.add({
              'symbol': s,
              'name': s,
              'price': d.price,
              'change': d.change,
            });
        }
        break;
      case AssetType.FOREX:
        for (var s in _whitelistForex) {
          if (s == "USD") {
            final d = _cache["USD/TRY"];
            if (d != null)
              results.add({
                'symbol': 'USD',
                'name': 'Dolar',
                'price': d.price,
                'change': d.change,
              });
          } else {
            final d = _cache["$s/TRY"];
            if (d != null)
              results.add({
                'symbol': s,
                'name': s,
                'price': d.price,
                'change': d.change,
              });
          }
        }
        break;
    }
    return results;
  }

  // --- COMPATIBILITY / PUBLIC ---
  Future<Map<String, double>> getCurrentPrices(List<String> symbols) async {
    // Actually this is what PortfolioProvider uses.
    // It passes pure symbols e.g. "THYAO", "BTC", "GRAM".
    // We try to match with keys.
    final Map<String, double> map = {};
    for (var s in symbols) {
      // Direct match
      if (_cache.containsKey(s)) {
        map[s] = _cache[s]!.price;
        continue;
      }
      // Try suffixes
      if (_cache.containsKey("$s.IS")) {
        map[s] = _cache["$s.IS"]!.price;
        continue;
      }
      // Try prefixes
      if (_cache.containsKey("$s/TRY")) {
        map[s] = _cache["$s/TRY"]!.price;
        continue;
      }
    }
    return map;
  }

  // Cleanups
  Future<List<Map<String, dynamic>>> getFavoritesData(List<dynamic> f) async =>
      [];
  Future<Map<String, dynamic>?> getLatestPrice(String s, AssetType t) async =>
      null;
}
