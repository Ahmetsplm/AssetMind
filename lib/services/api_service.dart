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
    // Expanded List
    'UNIUSDT',
    'XLMUSDT',
    'BCHUSDT',
    'NEARUSDT',
    'FILUSDT',
    'HBARUSDT',
    'APTUSDT',
    'ICPUSDT',
    'LDOUSDT',
    'ARBUSDT',
    'VETUSDT',
    'QNTUSDT',
    'MKRUSDT',
    'GRTUSDT',
    'AAVEUSDT',
    'OPUSDT',
    'ALGOUSDT',
    'STXUSDT',
    'EGLDUSDT',
    'SANDUSDT',
    'THETAUSDT',
    'FTMUSDT',
    'EOSUSDT',
    'MANAUSDT',
    'XTZUSDT',
    'AXSUSDT',
    'CAKEUSDT',
    'NEOUSDT',
    'KAVAUSDT',
    'RUNEUSDT',
    'FLOWUSDT',
    'CHZUSDT',
  ];

  static const List<String> _whitelistForex = [
    'USD', 'EUR', 'GBP', 'CHF', 'CAD', 'JPY',
    // Expanded List
    'AUD', 'SEK', 'NOK', 'DKK', 'SAR', 'RUB', 'CNY', 'AZN', 'BGN',
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
    // Add Gold & Metals to fetch list
    final List<String> targets = List.from(_whitelistBist)
      ..addAll(["GC=F", "SI=F", "PL=F", "PA=F"]);

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
  /// 5. FETCH: Forex (Yahoo Finance for rich data including Change%)
  Future<void> fetchForex() async {
    // We prefer Yahoo for USD and EUR to get the Daily Change %.
    // Symbols: USDTRY=X, EURTRY=X
    final List<String> yahooForex = ["USDTRY=X", "EURTRY=X"];

    await Future.wait(
      yahooForex.map((s) async {
        await _fetchYahooSingle(s);
      }),
    );

    // Map Yahoo results to our internal keys
    if (_cache.containsKey("USDTRY=X")) {
      final item = _cache["USDTRY=X"]!;
      _cachedUsdTry = item.price;
      _updateCache("USD/TRY", item.price, item.change);
    }

    if (_cache.containsKey("EURTRY=X")) {
      final item = _cache["EURTRY=X"]!;
      _updateCache("EUR/TRY", item.price, item.change);

      // Calculate EUR/USD parity for information? Not needed for now.
    }

    // Fallback/Secondary: Fetch other currencies using Frankfurter
    await _fetchFrankfurterForex();

    // Now that we have fresh USD, recalculate Gold
    _calculateGold();

    await _saveCache();
  }

  /// Fetch non-USD/EUR currencies from Frankfurter (GBP, CHF, CAD, JPY)
  Future<void> _fetchFrankfurterForex() async {
    try {
      // 1. Define targets (excluding USD, EUR which are handled by Yahoo)
      // We need TRY to calculate cross rates (Base is EUR)
      const targets = [
        "TRY",
        "GBP",
        "CHF",
        "CAD",
        "JPY",
        "AUD",
        "SEK",
        "NOK",
        "DKK",
        "SAR",
        "RUB",
        "CNY",
        "AZN",
        "BGN",
      ];
      final symbolsStr = targets.join(",");

      // 2. Fetch Latest
      final latestUrl = Uri.parse("$_frankfurterBaseUrl?to=$symbolsStr");
      final latestResp = await http.get(latestUrl);

      if (latestResp.statusCode != 200) return;

      final latestJson = jsonDecode(latestResp.body);
      final Map<String, dynamic> latestRates = latestJson['rates'];
      final String dateStr = latestJson['date'];

      // Calculate Today's Cross Rates (X/TRY)
      // EUR/TRY is known (latestRates['TRY'])
      // EUR/X is known (latestRates['X'])
      // X/TRY = (EUR/TRY) / (EUR/X)
      // We assume EUR base = 1

      final double eurTryToday = (latestRates['TRY'] as num).toDouble();

      // 3. Determine Previous Working Day
      DateTime date = DateTime.parse(dateStr);
      DateTime prevDate = date.subtract(const Duration(days: 1));

      // Simple loop to skip weekends (Sat=6, Sun=7)
      while (prevDate.weekday >= 6) {
        prevDate = prevDate.subtract(const Duration(days: 1));
      }

      final String prevDateStr =
          "${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}";

      // 4. Fetch Previous
      final prevUrl = Uri.parse(
        "https://api.frankfurter.app/$prevDateStr?to=$symbolsStr",
      );
      final prevResp = await http.get(prevUrl);

      Map<String, dynamic> prevRates = {};
      if (prevResp.statusCode == 200) {
        prevRates = jsonDecode(prevResp.body)['rates'];
      }

      // 5. Calculate and Update Cache for each target
      final currencies = [
        "GBP",
        "CHF",
        "CAD",
        "JPY",
        "AUD",
        "SEK",
        "NOK",
        "DKK",
        "SAR",
        "RUB",
        "CNY",
        "AZN",
        "BGN",
      ];

      for (var curr in currencies) {
        if (latestRates.containsKey(curr)) {
          // Calculate Today
          final double eurXToday = (latestRates[curr] as num).toDouble();
          final double priceToday = eurTryToday / eurXToday;

          // Calculate Change
          double change = 0.0;
          if (prevRates.isNotEmpty &&
              prevRates.containsKey(curr) &&
              prevRates.containsKey('TRY')) {
            final double eurTryPrev = (prevRates['TRY'] as num).toDouble();
            final double eurXPrev = (prevRates[curr] as num).toDouble();
            final double pricePrev = eurTryPrev / eurXPrev;

            change = ((priceToday - pricePrev) / pricePrev) * 100;
          }

          _updateCache("$curr/TRY", priceToday, change);
        }
      }
    } catch (e) {
      print("Frankfurter Fetch Error: $e");
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
    if (_cachedUsdTry == null) return;

    // 1. GOLD (GC=F)
    if (_cache.containsKey('GC=F')) {
      final ons = _cache['GC=F']!;
      final double gramPrice = (ons.price / 31.1035) * _cachedUsdTry!;
      final double chg = ons.change;

      _updateCache("Gram Altın", gramPrice, chg);
      _updateCache("Çeyrek Altın", gramPrice * 1.608, chg);
      _updateCache("Yarım Altın", gramPrice * 3.216, chg);
      _updateCache("Tam Altın", gramPrice * 6.432, chg);
      _updateCache("Cumhuriyet Altın", gramPrice * 6.672, chg);
      _updateCache("Ons Altın", ons.price * _cachedUsdTry!, chg);
    }

    // 2. SILVER (SI=F)
    if (_cache.containsKey('SI=F')) {
      final ons = _cache['SI=F']!;
      final double gram = (ons.price / 31.1035) * _cachedUsdTry!;
      _updateCache("Ons Gümüş", ons.price * _cachedUsdTry!, ons.change);
      _updateCache("Gram Gümüş", gram, ons.change);
    }

    // 3. PLATINUM (PL=F)
    if (_cache.containsKey('PL=F')) {
      final ons = _cache['PL=F']!;
      final double gram = (ons.price / 31.1035) * _cachedUsdTry!;
      _updateCache("Ons Platin", ons.price * _cachedUsdTry!, ons.change);
      _updateCache("Gram Platin", gram, ons.change);
    }

    // 4. PALLADIUM (PA=F)
    if (_cache.containsKey('PA=F')) {
      final ons = _cache['PA=F']!;
      final double gram = (ons.price / 31.1035) * _cachedUsdTry!;
      _updateCache("Ons Paladyum", ons.price * _cachedUsdTry!, ons.change);
      _updateCache("Gram Paladyum", gram, ons.change);
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

  // --- SYNC PUBLIC API (For UI Consumers via Provider) ---

  List<Map<String, dynamic>> getMarketSummarySync() {
    final List<Map<String, dynamic>> list = [];

    void add(String sym, String display) {
      final item = _cache[sym] ?? _cache["$sym.IS"];
      if (item != null) {
        list.add({
          'symbol': display,
          'value': item.price.toStringAsFixed(2),
          'change_rate': item.change.toStringAsFixed(2),
          'is_rising': item.change >= 0,
        });
      }
    }

    add("XU100.IS", "BIST 100");
    add("USD/TRY", "Dolar");
    add("EUR/TRY", "Euro");
    add("Gram Altın", "Gram Altın");

    return list;
  }

  List<Map<String, dynamic>> getStockMoversSync({bool isRising = true}) {
    final now = DateTime.now().subtract(const Duration(minutes: 15));
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final items = _cache.entries
        .where((e) => e.key.endsWith(".IS") && e.key != "XU100.IS")
        .map(
          (e) => {
            'symbol': e.key.replaceAll(".IS", ""),
            'price': e.value.price.toStringAsFixed(2),
            'change': e.value.change.toStringAsFixed(2),
            'raw_change': e.value.change,
            'time': timeStr,
          },
        )
        .toList();

    // Sort by magnitude
    items.sort(
      (a, b) => (b['raw_change'] as double).abs().compareTo(
        (a['raw_change'] as double).abs(),
      ),
    );

    // Filter by direction
    final filtered = items.where((i) {
      final chg = i['raw_change'] as double;
      return isRising ? chg > 0 : chg < 0;
    }).toList();

    filtered.sort((a, b) {
      final da = a['raw_change'] as double;
      final db = b['raw_change'] as double;
      return isRising ? db.compareTo(da) : da.compareTo(db);
    });

    return filtered.take(5).toList();
  }

  List<Map<String, dynamic>> getCryptoMoversSync({bool isRising = true}) {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final items = _cache.entries
        .where(
          (e) =>
              !e.key.contains(".IS") &&
              !e.key.contains("=") &&
              !e.key.contains("/TRY") &&
              !e.key.contains("Altın") &&
              !e.key.contains("Gümüş") &&
              !e.key.contains("Platin") &&
              !e.key.contains("Paladyum") &&
              !e.key.contains("_") && // Kill all legacy keys like PALADYUM_ONS
              !e.key.contains("PALADYUM") &&
              !e.key.contains("PLATIN") &&
              !e.key.contains("GUMUS") &&
              !e.key.contains("_TL") && // Legacy
              ![
                "GRAM",
                "CEYREK",
                "YARIM",
                "TAM",
                "CUMHURIYET",
                "ONS",
              ].contains(e.key), // Legacy Upper
        )
        .map(
          (e) => {
            'symbol': e.key,
            'price': e.value.price.toStringAsFixed(2),
            'change': e.value.change.toStringAsFixed(2),
            'raw_change': e.value.change,
            'time': timeStr,
          },
        )
        .toList();

    final filtered = items.where((i) {
      final chg = i['raw_change'] as double;
      return isRising ? chg > 0 : chg < 0;
    }).toList();

    filtered.sort((a, b) {
      final da = a['raw_change'] as double;
      final db = b['raw_change'] as double;
      return isRising ? db.compareTo(da) : da.compareTo(db);
    });

    return filtered.take(5).toList();
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
        final metals = [
          {'key': 'Gram Altın', 'name': 'Altın'},
          {'key': 'Çeyrek Altın', 'name': 'Altın'},
          {'key': 'Yarım Altın', 'name': 'Altın'},
          {'key': 'Tam Altın', 'name': 'Altın'},
          {'key': 'Cumhuriyet Altın', 'name': 'Altın'},
          {'key': 'Ons Altın', 'name': 'Altın'},
          {'key': 'Gram Gümüş', 'name': 'Gümüş'},
          {'key': 'Ons Gümüş', 'name': 'Gümüş'},
          {'key': 'Gram Platin', 'name': 'Platin'},
          {'key': 'Ons Platin', 'name': 'Platin'},
          {'key': 'Gram Paladyum', 'name': 'Paladyum'},
          {'key': 'Ons Paladyum', 'name': 'Paladyum'},
        ];

        for (var m in metals) {
          final s = m['key']!;
          final d = _cache[s];
          if (d != null)
            results.add({
              'symbol': s,
              'name': m['name'],
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
  Future<List<Map<String, dynamic>>> getFavoritesData(
    List<dynamic> symbols,
  ) async {
    final List<Map<String, dynamic>> results = [];

    for (var s in symbols) {
      final String inputSym = s.toString();
      String? foundKey;
      AssetCacheModel? item;

      // Helper to find key case-insensitively if direct match fails
      String? findCaseInsensitive(String target) {
        try {
          return _cache.keys.firstWhere(
            (k) => k.toLowerCase() == target.toLowerCase(),
          );
        } catch (_) {
          return null;
        }
      }

      // 1. Try Direct Match
      if (_cache.containsKey(inputSym)) {
        foundKey = inputSym;
        item = _cache[inputSym];
      }
      // 2. Try .IS
      else if (_cache.containsKey("$inputSym.IS")) {
        foundKey = inputSym; // Keep original for stocks usually
        item = _cache["$inputSym.IS"];
      }
      // 3. Try /TRY
      else if (_cache.containsKey("$inputSym/TRY")) {
        foundKey = "$inputSym/TRY";
        item = _cache["$inputSym/TRY"];
      }
      // 4. Legacy / Logic Mapping
      else {
        // Map Legacy -> New Cache Key
        String targetKey = inputSym;
        if (inputSym == 'GRAM')
          targetKey = 'Gram Altın';
        else if (inputSym == 'CEYREK')
          targetKey = 'Çeyrek Altın';
        else if (inputSym == 'YARIM')
          targetKey = 'Yarım Altın';
        else if (inputSym == 'TAM')
          targetKey = 'Tam Altın';
        else if (inputSym == 'CUMHURIYET')
          targetKey = 'Cumhuriyet Altın';
        else if (inputSym == 'ONS')
          targetKey = 'Ons Altın';
        // Handle potential UPPERCASE versions from UI (e.g. CEYREK ALTIN)
        else {
          // Try to find a loosely matching key in cache (e.g. "ÇEYREK ALTIN" -> "Çeyrek Altın")
          final possible = findCaseInsensitive(inputSym);
          if (possible != null) targetKey = possible;
        }

        if (_cache.containsKey(targetKey)) {
          foundKey = targetKey; // Use the CLEAN name
          item = _cache[targetKey];
        }
      }

      if (item != null) {
        results.add({
          // CRITICAL: Return the FOUND key (Clean Name) if available, otherwise input
          'symbol': foundKey ?? inputSym,
          'price': item.price.toStringAsFixed(2),
          'change_rate': item.change,
        });
      } else {
        results.add({'symbol': inputSym, 'price': "0.00", 'change_rate': 0.0});
      }
    }
    return results;
  }

  Future<Map<String, dynamic>?> getLatestPrice(String s, AssetType t) async =>
      null;
}
