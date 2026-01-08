import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/holding.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // URL'ler
  static const String _binance24hrUrl =
      "https://api.binance.com/api/v3/ticker/24hr";
  static const String _frankfurterBaseUrl =
      "https://api.frankfurter.app/latest";

  // Yahoo Headers
  static const Map<String, String> _headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  };

  // Cache
  double? _cachedUsdTry;

  // Önbellek (Kısa süreli)
  final Map<String, Map<String, dynamic>> _memoryCache = {};
  DateTime? _lastCacheTime;

  // --- PUBLIC METHODS (UI CONSUMERS) ---

  /// 1. VARLIK FİYATLARINI GETİR (PortfolioProvider için)
  Future<Map<String, double>> getCurrentPrices(List<String> symbols) async {
    final Map<String, double> prices = {};
    if (symbols.isEmpty) return prices;

    // A. Önce Dolar Kurunu Garantile (Frankfurter)
    await _ensureUsdRate();

    // B. Sembolleri Ayır
    final yahooSymbols = <String>[];
    final binanceSymbols = <String>[];
    final specialSymbols = <String>{
      "GRAM",
      "CEYREK",
      "YARIM",
      "TAM",
      "CUMHURIYET",
    };

    for (var s in symbols) {
      if (specialSymbols.contains(s)) continue; // Bunlar hesaplanacak
      if (s == "USDTRY" || s == "EURTRY")
        continue; // Frankfurter'den bakacağız veya Yahoo fallback

      if (s.endsWith(".IS") ||
          s.contains("=") ||
          !s.contains(RegExp(r'[A-Z]'))) {
        yahooSymbols.add(s);
      } else {
        // Varsayım: Uzantısı yoksa ve standartsa Kriptodur (veya Yahoo da olabilir ama Binance daha hızlı)
        // Kullanıcı hisse eklerken .IS eklemiş olmalı.
        if (s.contains(".")) {
          yahooSymbols.add(s);
        } else {
          binanceSymbols.add(s);
        }
      }
    }

    // C. Paralel İstekler
    await Future.wait([
      _fetchYahooChartBatchInto(yahooSymbols, prices),
      _fetchBinanceBatchInto(binanceSymbols, prices),
    ]);

    // D. Dolar/Euro Ekle
    if (_cachedUsdTry != null) {
      prices["USDTRY"] = _cachedUsdTry!;
      // Euro'yu Frankfurter cache'den alabilirdik ama basitçe hesaplayalım veya Yahoo'dan geleni koruyalım
      // Eğer Yahoo'dan EURTRY geldiyse kalsın, gelmediyse Frankfurter oranını kullanabiliriz.
    }

    // E. Altın Hesapla (Eğer talep edildiyse)
    if (_cachedUsdTry != null && prices.containsKey("GC=F")) {
      final onsPrice = prices["GC=F"]!;
      final gramTl = (onsPrice / 31.1035) * _cachedUsdTry!;

      if (symbols.contains("GRAM")) prices["GRAM"] = gramTl;
      if (symbols.contains("CEYREK")) prices["CEYREK"] = gramTl * 1.63;
      if (symbols.contains("YARIM")) prices["YARIM"] = gramTl * 3.26;
      if (symbols.contains("TAM")) prices["TAM"] = gramTl * 6.52;
      if (symbols.contains("CUMHURIYET")) prices["CUMHURIYET"] = gramTl * 6.70;
    }

    return prices;
  }

  /// 2. PİYASA ÖZETİ (HomeScreen için)
  Future<List<Map<String, dynamic>>> getMarketSummary() async {
    await _ensureUsdRate();

    // Kritik verileri çek: BIST 100, Altın Ons, Dolar, Euro
    // Dolar/Euro için Yahoo Chart kullanalım ki "değişim oranı" da gelsin.

    final targets = ["XU100.IS", "GC=F", "TRY=X", "EURTRY=X"];
    final Map<String, Map<String, dynamic>> rawData = {};

    // Tek tek çekelim (Güvenli Mod)
    await Future.wait(
      targets.map((t) async {
        final data = await _fetchSingleYahooChart(t);
        if (data != null) rawData[t] = data;
      }),
    );

    // BIST 100 Düzeltmesi (Format)
    if (rawData.containsKey("XU100.IS")) {
      if (rawData["XU100.IS"]!['price'] > 50000) {
        rawData["XU100.IS"]!['price'] = rawData["XU100.IS"]!['price'] / 100;
      }
    }

    // TRY=X Yahoo'da "1 USD kaç TRY" değil bazen ters gelebilir, kontrol et.
    // Genelde 30-40 bandındaysa doğrudur. 0.02 ise terstir.
    if (rawData.containsKey("TRY=X")) {
      double p = rawData["TRY=X"]!['price'];
      if (p < 1.0) {
        rawData["TRY=X"]!['price'] = 1.0 / p;
        rawData["TRY=X"]!['change'] =
            -rawData["TRY=X"]!['change']; // Ters çevir
      }
    }

    // Gram Altın Hesapla
    double gramVal = 0.0;
    double gramChange = 0.0;

    if (rawData.containsKey("GC=F") && _cachedUsdTry != null) {
      double ons = rawData["GC=F"]!['price'];
      double onsChg = rawData["GC=F"]!['change'];

      gramVal = (ons / 31.1035) * _cachedUsdTry!;

      // Gram değişimi ≈ Ons Değişimi + Dolar Değişimi (Basit yaklaşım)
      double usdChg = rawData.containsKey("TRY=X")
          ? rawData["TRY=X"]!['change']
          : 0.0;
      gramChange = onsChg + usdChg;
    }

    return [
      {
        'symbol': 'BIST 100', // UI bunu XU100.IS olarak bilmez, display name
        'value': rawData["XU100.IS"]?['price'] ?? 0.0,
        'change_rate': rawData["XU100.IS"]?['change'] ?? 0.0,
        'is_rising': (rawData["XU100.IS"]?['change'] ?? 0) >= 0,
      },
      {
        'symbol': 'Dolar',
        'value': rawData["TRY=X"]?['price'] ?? _cachedUsdTry ?? 0.0,
        'change_rate': rawData["TRY=X"]?['change'] ?? 0.0,
        'is_rising': (rawData["TRY=X"]?['change'] ?? 0) >= 0,
      },
      {
        'symbol': 'Euro',
        'value': rawData["EURTRY=X"]?['price'] ?? 0.0,
        'change_rate': rawData["EURTRY=X"]?['change'] ?? 0.0,
        'is_rising': (rawData["EURTRY=X"]?['change'] ?? 0) >= 0,
      },
      {
        'symbol': 'Gram Altın',
        'value': gramVal,
        'change_rate': gramChange,
        'is_rising': gramChange >= 0,
      },
    ];
  }

  /// 3. PİYASA HAREKETLERİ (BIST & KRİPTO)
  Future<List<Map<String, dynamic>>> getStockMovers({
    bool isRising = true,
  }) async {
    // Sabit bir BIST 30 listesinden çekip sıralayacağız (Yahoo Chart ile)
    final symbols = [
      "THYAO.IS",
      "GARAN.IS",
      "AKBNK.IS",
      "EREGL.IS",
      "TUPRS.IS",
      "KCHOL.IS",
      "BIMAS.IS",
      "SISE.IS",
      "ASELS.IS",
      "SASA.IS",
      "HEKTS.IS",
      "YKBNK.IS",
      "ISCTR.IS",
      "SAHOL.IS",
      "PETKM.IS",
      "FROTO.IS",
      "TOASO.IS",
      "PGSUS.IS",
      "KONTR.IS",
      "GESAN.IS",
    ];

    List<Map<String, dynamic>> items = [];

    // Paralel çek
    await Future.wait(
      symbols.map((s) async {
        final d = await _fetchSingleYahooChart(s);
        if (d != null) {
          items.add({
            'symbol': s.replaceAll(".IS", ""), // UI'da temiz görünsün
            'price': d['price'],
            'change': d['change'],
            'name': s, // Full sembol lazım olabilir
          });
        }
      }),
    );

    // Sırala
    items.sort((a, b) => b['change'].compareTo(a['change'])); // Azalan

    if (isRising) {
      return items.where((i) => i['change'] > 0).take(5).toList();
    } else {
      items = items.reversed.toList(); // Artan (En çok düşen en başta)
      return items.where((i) => i['change'] < 0).take(5).toList();
    }
  }

  Future<List<Map<String, dynamic>>> getCryptoMovers({
    bool isRising = true,
  }) async {
    try {
      final response = await http.get(Uri.parse(_binance24hrUrl));
      if (response.statusCode == 200) {
        List<dynamic> all = jsonDecode(response.body);
        var usdtPairs = all
            .where((t) => t['symbol'].toString().endsWith("USDT"))
            .toList();

        // Hacim filtresi (Çok düşük hacimlileri ele)
        usdtPairs = usdtPairs.where((t) {
          double vol = double.tryParse(t['quoteVolume'].toString()) ?? 0;
          return vol > 1000000; // 1M USDT altı hacimliler spekülatif olabilir
        }).toList();

        // Model Map'e çevir
        List<Map<String, dynamic>> items = [];
        await _ensureUsdRate();

        for (var t in usdtPairs) {
          double chg = double.tryParse(t['priceChangePercent'].toString()) ?? 0;
          double price = double.tryParse(t['lastPrice'].toString()) ?? 0;
          if (_cachedUsdTry != null) price *= _cachedUsdTry!; // TL çevir

          items.add({
            'symbol': t['symbol'].toString().replaceAll("USDT", ""),
            'price': price,
            'change': chg,
            'name': t['symbol'],
          });
        }

        // Sırala
        items.sort((a, b) => b['change'].compareTo(a['change']));

        if (isRising) {
          return items.where((i) => i['change'] > 0).take(5).toList();
        } else {
          return items.reversed.where((i) => i['change'] < 0).take(5).toList();
        }
      }
    } catch (e) {
      print("Binance Movers Err: $e");
    }
    return [];
  }

  /// 4. VARLIK EKLEME LİSTESİ (Discovery)
  Future<List<Map<String, dynamic>>> getAssetsByType(AssetType type) async {
    await _ensureUsdRate();
    final List<Map<String, dynamic>> results = [];

    switch (type) {
      case AssetType.STOCK:
        // Popüler BIST Hisseleri
        final symbols = [
          "THYAO.IS",
          "GARAN.IS",
          "AKBNK.IS",
          "EREGL.IS",
          "ASELS.IS",
          "BIMAS.IS",
          "SISE.IS",
          "KCHOL.IS",
          "TUPRS.IS",
          "SASA.IS",
          "HEKTS.IS",
          "FROTO.IS",
        ];
        await Future.wait(
          symbols.map((s) async {
            final d = await _fetchSingleYahooChart(s);
            if (d != null) {
              results.add({
                'symbol': s, // .IS kalsın ki kaydederken doğru olsun
                'name': s.replaceAll(".IS", ""),
                'price': d['price'],
                'change': d['change'],
              });
            }
          }),
        );
        break;

      case AssetType.CRYPTO:
        // Top 20 Binance (Hacme göre)
        try {
          final response = await http.get(Uri.parse(_binance24hrUrl));
          if (response.statusCode == 200) {
            List<dynamic> all = jsonDecode(response.body);
            final usdt = all
                .where((t) => t['symbol'].toString().endsWith("USDT"))
                .toList();
            usdt.sort((a, b) {
              double v1 = double.tryParse(a['quoteVolume'].toString()) ?? 0;
              double v2 = double.tryParse(b['quoteVolume'].toString()) ?? 0;
              return v2.compareTo(v1); // Desc
            });

            for (var t in usdt.take(20)) {
              double p = double.tryParse(t['lastPrice'].toString()) ?? 0;
              if (_cachedUsdTry != null) p *= _cachedUsdTry!;
              double c =
                  double.tryParse(t['priceChangePercent'].toString()) ?? 0;
              String s = t['symbol'].toString().replaceAll("USDT", "");
              results.add({
                'symbol': s,
                'name': t['symbol'], // Full symbol
                'price': p,
                'change': c,
              });
            }
          }
        } catch (_) {}
        break;

      case AssetType.GOLD:
        // Ons çek, hesapla
        final d = await _fetchSingleYahooChart("GC=F");
        if (d != null && _cachedUsdTry != null) {
          double ons = d['price'];
          double onsChg = d['change'];
          double gram = (ons / 31.1035) * _cachedUsdTry!;

          results.add({
            'symbol': 'ONS',
            'name': 'Ons Altın (\$)',
            'price': ons,
            'change': onsChg,
          });
          results.add({
            'symbol': 'GRAM',
            'name': 'Gram Altın',
            'price': gram,
            'change': onsChg,
          });
          results.add({
            'symbol': 'CEYREK',
            'name': 'Çeyrek Altın',
            'price': gram * 1.63,
            'change': onsChg,
          });
          results.add({
            'symbol': 'YARIM',
            'name': 'Yarım Altın',
            'price': gram * 3.26,
            'change': onsChg,
          });
          results.add({
            'symbol': 'TAM',
            'name': 'Tam Altın',
            'price': gram * 6.52,
            'change': onsChg,
          });
          results.add({
            'symbol': 'CUMHURIYET',
            'name': 'Cumhuriyet',
            'price': gram * 6.70,
            'change': onsChg,
          });
        }
        break;

      case AssetType.FOREX:
        // Bazı majörler
        final list = [
          "USDTRY",
          "EURTRY",
          "GBPTRY",
          "CHFTRY",
          "JPYTRY",
        ]; // Frankfurter'de JPYTRY yoksa USD üzerinden çevrilir ama simülasyon yapalım
        // Frankfurter sadece Price verir, Change vermez. Yahoo Chart'tan çekelim ki değişim de gelsin.
        // TRY=X, EURTRY=X
        final yahooMap = {
          "USDTRY": "TRY=X",
          "EURTRY": "EURTRY=X",
          "GBPTRY": "GBPTRY=X",
          "CHFTRY": "CHFTRY=X",
          "JPYTRY": "JPYTRY=X", // Yahoo'da var
        };

        await Future.wait(
          list.map((code) async {
            String ySymbol = yahooMap[code] ?? code;
            final d = await _fetchSingleYahooChart(ySymbol);
            if (d != null) {
              double price = d['price'];
              if (code == "USDTRY" && price < 1)
                price = 1 / price; // Ters gelirse

              results.add({
                'symbol': code,
                'name': code,
                'price': price,
                'change': d['change'],
              });
            } else if (code == "USDTRY" && _cachedUsdTry != null) {
              // Fallback
              results.add({
                'symbol': 'USDTRY',
                'name': 'Dolar',
                'price': _cachedUsdTry,
                'change': 0.0,
              });
            }
          }),
        );
        break;
    }
    return results;
  }

  // --- PRIVATE HELPERS ---

  Future<void> _ensureUsdRate() async {
    if (_cachedUsdTry != null) return;
    try {
      final url = Uri.parse("$_frankfurterBaseUrl?from=USD&to=TRY");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedUsdTry = (data['rates']['TRY'] as num).toDouble();
      }
    } catch (e) {
      print("Frankfurter Err: $e");
      _cachedUsdTry = 34.0; // Fail-safe
    }
  }

  // Yahoo Chart v8 Single Fetch
  Future<Map<String, dynamic>?> _fetchSingleYahooChart(String symbol) async {
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

        double chg = 0.0;
        if (prev > 0) chg = ((current - prev) / prev) * 100;

        return {'price': current, 'change': chg};
      }
    } catch (_) {}
    return null;
  }

  Future<void> _fetchYahooChartBatchInto(
    List<String> symbols,
    Map<String, double> results,
  ) async {
    await Future.wait(
      symbols.map((s) async {
        final d = await _fetchSingleYahooChart(s);
        if (d != null) results[s] = d['price'];
      }),
    );
  }

  Future<void> _fetchBinanceBatchInto(
    List<String> symbols,
    Map<String, double> results,
  ) async {
    if (symbols.isEmpty) return;
    // Optimization: Fetch all 24hr once if list is long, or specific pairs if short?
    // Binance 24hr endpoint is huge. Better use `ticker/price` for specific symbols batch.
    // But user might want change rate? getCurrentPrices assumes only Price is needed for Portfolio.
    try {
      // Batch symbol param: ["BTCUSDT","ETHUSDT"]
      final pairs = symbols.map((s) => "${s.toUpperCase()}USDT").toList();
      final String param = jsonEncode(pairs);
      final url = Uri.parse(
        "https://api.binance.com/api/v3/ticker/price?symbols=$param",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        for (var item in data) {
          final p = double.tryParse(item['price'].toString()) ?? 0.0;
          // Map back to original symbol
          final sym = item['symbol'].toString().replaceAll("USDT", "");
          if (_cachedUsdTry != null) {
            results[sym] = p * _cachedUsdTry!;
          } else {
            results[sym] = p; // Fallback USD
          }
        }
      }
    } catch (_) {}
  }

  // -- Legacy/Unused Placeholders --
  Future<List<Map<String, dynamic>>> getFavoritesData(List<dynamic> f) async =>
      [];
  Future<Map<String, dynamic>?> getLatestPrice(String s, AssetType t) async =>
      null;
}
