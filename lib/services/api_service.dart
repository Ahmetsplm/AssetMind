import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/holding.dart';
import 'asset_service.dart';

// Helper Model for Cache
class AssetCacheModel {
  final double price;
  final double change;
  final DateTime timestamp;
  final bool isTransient;

  AssetCacheModel({
    required this.price,
    required this.change,
    required this.timestamp,
    this.isTransient = false,
  });

  Map<String, dynamic> toJson() => {
        'price': price,
        'change': change,
        'timestamp': timestamp.toIso8601String(),
        'isTransient': isTransient,
      };

  factory AssetCacheModel.fromJson(Map<String, dynamic> json) {
    return AssetCacheModel(
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isTransient: json['isTransient'] ?? false,
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

  static const List<String> _allBistStocks = [
    "A1YEN","AAGYO","ACSEL","ADEL","ADESE","AEFES","AFYON","AGESA","AGHOL","AGROT",
    "AGYO","AHGAZ","AHSGY","AKBNK","AKCNS","AKENR","AKFGY","AKFIS","AKFYE","AKGRT",
    "AKMGY","AKSA","AKSEN","AKSUE","AKYHO","ALARK","ALBRK","ALCAR","ALCTL","ALFAS",
    "ALGYO","ALKA","ALKIM","ALKLC","ALTNY","ANELE","APBDL","APGLD","APMDL","APX30",
    "ARASE","ARCLK","ARDYZ","ARENA","ARFYE","ARSAN","ARTMS","ARZUM","ASGYO","ASTOR",
    "ASUZU","ATAKP","ATATP","ATATR","ATEKS","ATLAS","ATSYH","AVGYO","AVHOL","AVPGY",
    "AVTUR","AYDEM","AYEN","AYES","AYGAZ","AZTEK","BAGFS","BAHKM","BAKAB","BALAT",
    "BANVT","BARMA","BASCM","BASGZ","BAYRK","BEGYO","BESLR","BESTE","BFREN","BIENY",
    "BIGCH","BIGTK","BIMAS","BINBN","BINHO","BIOEN","BIZIM","BJKAS","BLCYT","BLUME",
    "BMSCH","BMSTL","BNTAS","BOBET","BORLS","BORSK","BOSSA","BRISA","BRKO","BRKSN",
    "BRLSM","BRMEN","BRSAN","BRYAT","BSOKE","BTCIM","BUCIM","BULGS","BURCE","BURVA",
    "CANTE","CASA","CATES","CCOLA","CELHA","CEMAS","CEMTS","CEMZY","CGCAM","CIMSA",
    "CLEBI","CMBTN","CMENT","CONSE","COSMO","CRDFA","CRFSA","CUSAN","CVKMD","CWENE",
    "DAGI","DAPGM","DARDL","DCTTR","DENGE","DERHL","DERIM","DESPC","DEVA","DGATE",
    "DGGYO","DGNMO","DIRIT","DITAS","DMRGD","DMSAS","DNISI","DOAS","DOCO","DOFER",
    "DOFRB","DOGUB","DOHOL","DOKTA","DUNYH","DURDO","DURKN","DYOBY","DZGYO","EBEBK",
    "ECILC","ECOGR","ECZYT","EDATA","EDIP","EFOR","EGEEN","EGEGY","EGEPO","EGGUB",
    "EGSER","EKGYO","EKIZ","EKOS","EKSUN","ELITE","EMKEL","EMNIS","EMPAE","ENDAE",
    "ENJSA","ENKAI","ENPRA","ENSRI","EPLAS","ERBOS","ERCB","EREGL","ERSU","ESCAR",
    "ESCOM","ESEN","ETILR","ETYAT","EUKYO","EUPWR","EUREN","EUYO","FENER","FLAP",
    "FMIZP","FONET","FORTE","FRIGO","FRMPL","FZLGY","GARAN","GARFA","GATEG","GEDIK",
    "GEDZA","GENIL","GENKM","GENTS","GEREL","GESAN","GLBMD","GLCVY","GLDTR","GLRMK",
    "GLRYH","GLYHO","GMSTR","GMTAS","GOKNR","GOLTS","GOODY","GOZDE","GRNYO","GRSEL",
    "GRTHO","GSDDE","GSDHO","GSRAY","GUBRF","GWIND","GZNMI","HALKB","HATEK","HATSN",
    "HDFGS","HEDEF","HEKTS","HKTM","HLGYO","HOROZ","HRKET","HTTBT","HUBVC","HUNER",
    "HURGZ","ICBCT","ICUGS","IDGYO","IEYHO","IHAAS","IHEVA","IHLAS","IHLGM","IHYAY",
    "IMASM","INDES","INFO","INGRM","INTEK","INVEO","INVES","ISBIR","ISBTR","ISCTR",
    "ISDMR","ISFIN","ISGLK","ISGSY","ISGYO","ISKPL","ISKUR","ISMEN","ISYAT","IZENR",
    "IZFAS","IZINV","IZMDC","JANTS","KAPLM","KAREL","KARSN","KATMR","KAYSE","KBORU",
    "KCAER","KCHOL","KENT","KERVN","KFEIN","KGYO","KIMMR","KLGYO","KLKIM","KLMSN",
    "KLNMA","KLSER","KLSYN","KLYPV","KMPUR","KNFRT","KOCMT","KONKA","KONTR","KONYA",
    "KOPOL","KORDS","KOTON","KRDMA","KRDMB","KRDMD","KRGYO","KRONT","KRPLS","KRTEK",
    "KRVGD","KSTUR","KTLEV","KTSKR","KUTPO","KUVVA","KUYAS","KZBGY","LIDER","LILAK",
    "LKMNH","LMKDC","LOGO","LRSHO","LUKSK","LXGYO","LYDHO","LYDYE","MAALT","MACKO",
    "MAGEN","MAKIM","MAKTK","MANAS","MARBL","MARKA","MARMR","MARTI","MAVI","MCARD",
    "MEDTR","MEGAP","MEGMT","MEKAG","MEPET","MERCN","MERIT","MERKO","METRO","MEYSU",
    "MGROS","MMCAS","MNDRS","MOBTL","MOGAN","MOPAS","MPARK","MRGYO","MRSHL","MTRKS",
    "NETAS","NETCD","NIBAS","NPTLR","NTGAZ","NTHOL","NUGYO","NUHCM","OBASE","ODAS",
    "ODINE","OFSYM","ONCSM","OPK30","OPT25","OPTGY","OPTLR","OPX30","ORCAY","ORGE",
    "OSMEN","OSTIM","OTKAR","OTTO","OYAKC","OYAYO","OYLUM","OYYAT","OZGYO","OZKGY",
    "OZRDN","OZSUB","PAGYO","PAHOL","PAMEL","PAPIL","PARSN","PASEU","PATEK","PCILT",
    "PEKGY","PENTA","PETKM","PETUN","PGSUS","PINSU","PKART","PKENT","PLTUR","PNLSN",
    "PNSUT","POLHO","POLTK","PRDGS","PRKME","PRZMA","PSDTC","QNBFK","QNBTR","QTEMZ",
    "QUAGR","RALYH","RAYSG","REEDR","RGYAS","RNPOL","RTALB","RUBNS","RUZYE","RYSAS",
    "SAFKR","SAHOL","SAMAT","SANFM","SANKO","SARKY","SASA","SAYAS","SDTTR","SEGMN",
    "SEGYO","SEKFK","SEKUR","SELEC","SELVA","SERNT","SEYKM","SILVR","SISE","SKBNK",
    "SKTAS","SKYMD","SMRTG","SNGYO","SNICA","SODSN","SOKM","SONME","SRVGY","SUMAS",
    "SUNTK","SURGY","SUWEN","SVGYO","TABGD","TARKM","TATEN","TATGD","TAVHL","TCELL",
    "TCKRC","TEHOL","TEKTU","TERA","TEZOL","TGSAS","THYAO","TKFEN","TKNSA","TLMAN",
    "TMPOL","TMSN","TNZTP","TOASO","TRALT","TRENJ","TRGYO","TRILC","TRMET","TSKB",
    "TTKOM","TTRAK","TUKAS","TUPRS","TUREX","TURGG","TURSG","UFUK","ULAS","ULKER",
    "ULUFA","ULUSE","ULUUN","UNLU","USAK","USDTR","VAKBN","VAKFA","VAKFN","VAKKO",
    "VANGD","VBTYZ","VERTU","VESBE","VKFYO","VKGYO","VKING","VSNMD","YAPRK","YAYLA",
    "YBTAS","YEOTK","YESIL","YGGYO","YIGIT","YKBNK","YKSLN","YONGA","YUNSA","YYAPI",
    "YYLGD","Z30EA","Z30KE","Z30KP","ZEDUR","ZELOT","ZERGY","ZGOLD","ZGYO","ZOREN",
    "ZPBDL","ZPLIB","ZPT10","ZPX30","ZRE20","ZRGYO","ZSR25","ZTLRF","ZTLRK","ZTM25"
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

  static const List<String> _whitelistGlobal = [
    'AAPL', 'MSFT', 'TSLA', 'AMZN', 'GOOGL', 'NVDA', 'META', 'NFLX',
    'AMD', 'INTC', 'JPM', 'V', 'DIS',
    'SPY', // S&P 500 ETF
    'QQQ', // NASDAQ 100 ETF
  ];

  static const List<String> _whitelistFund = [
    // Garanti BBVA
    'GAV', 'GTL', 'GTZ', 'GL1', 'GPA', 'GTA', 'GAU', 
    'GZH', 'GMA', 'GMR', 'GBG', 'GZG', 'GHK', 'GSU',
    // Popüler
    'MAC', 'TCD', 'IIH', 'NNF', 'YAS', 'AFT', 'AFA'         
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

  final Map<String, AssetCacheModel> _cache = {};
  double? _cachedUsdTry; // Helper for conversions

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

    try {
      final assetService = AssetService();
      if (assetService.userId != null) {
        // Favoriler
        final favs = await assetService.getFavorites();
        for (var f in favs) {
          if (f['type'] == 'STOCK') {
            final sym = '${f['symbol']}.IS';
            if (!targets.contains(sym)) targets.add(sym);
          }
        }
        
        // Alarmlar
        final alerts = await assetService.getActiveAlerts();
        for (var a in alerts) {
          if (_allBistStocks.contains(a.symbol)) {
            final sym = '${a.symbol}.IS';
            if (!targets.contains(sym)) targets.add(sym);
          }
        }
        
        // Portföyler
        final ports = await assetService.getPortfolios();
        for (var p in ports) {
          final holds = await assetService.getHoldings(p.id!);
          for (var h in holds) {
            if (h.type == AssetType.STOCK) {
              final sym = '${h.symbol}.IS';
              if (!targets.contains(sym)) targets.add(sym);
            }
          }
        }
      }
    } catch (e) {
      print("Dynamic Target Fetch Error: $e");
    }

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

  Future<void> fetchForex() async {
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
    }

    await _fetchFrankfurterForex();
    _calculateGold();

    await _saveCache();
  }

  Future<void> _fetchFrankfurterForex() async {
    try {
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

      final double eurTryToday = (latestRates['TRY'] as num).toDouble();

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

  // --- FETCH: Global (Tiingo IEX) ---
  Future<void> fetchGlobal() async {
    final apiKey = dotenv.env['TIINGO_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print("Tiingo API Key is missing.");
      return;
    }

    await _ensureUsdRate();
    if (_cachedUsdTry == null) return;

    final symbols = _whitelistGlobal.join(",");
    try {
      final url = Uri.parse("https://api.tiingo.com/iex/?tickers=$symbols&token=$apiKey");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        for (var item in json) {
          final String ticker = item['ticker'];
          final double last = (item['tngoLast'] as num?)?.toDouble() ?? (item['last'] as num?)?.toDouble() ?? 0.0;
          final double prevClose = (item['prevClose'] as num?)?.toDouble() ?? last;

          if (last > 0) {
            final priceTl = last * _cachedUsdTry!;
            final change = prevClose > 0 ? ((last - prevClose) / prevClose) * 100 : 0.0;
            _updateCache(ticker, priceTl, change);
          }
        }
        await _saveCache();
      } else {
        print("Tiingo API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Tiingo Global Fetch Error: $e");
    }
  }

  // --- FETCH: Funds (TEFAS Scraper - Sequential to bypass Rate Limits) ---
  Future<void> fetchFunds() async {
    for (var fund in _whitelistFund) {
      await _fetchTefasSingle(fund);
      // TEFAS F5 ASM / Rate limit korumasına takılmamak için araya bekleme koyuyoruz
      await Future.delayed(const Duration(milliseconds: 350));
    }
    await _saveCache();
  }

  Future<void> _fetchTefasSingle(String fundCode) async {
    try {
      final res = await http.get(
        Uri.parse('https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=$fundCode'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final html = res.body;
        final idx = html.indexOf('Son Fiyat (TL)');
        if (idx != -1) {
          final sub = html.substring(idx, idx + 300);
          final RegExp priceRegex = RegExp(r'>([\d,\.]+)<\/p>');
          final match = priceRegex.firstMatch(sub);
          if (match != null) {
            String priceStr = match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
            double price = double.tryParse(priceStr) ?? 0.0;
            if (price > 0) {
               _updateCache(fundCode, price, 0.0);
               print("TEFAS Success: $fundCode = $price");
            } else {
               print("TEFAS Parse Error: $fundCode, priceStr=$priceStr");
            }
          } else {
             print("TEFAS Regex Match Failed: $fundCode, sub=$sub");
          }
        } else {
           print("TEFAS HTML Missing 'Son Fiyat': $fundCode");
        }
      } else {
        print("TEFAS HTTP Error: $fundCode -> ${res.statusCode}");
      }
    } catch (e) {
      print("Tefas Fetch Error for $fundCode: $e");
    }
  }

  // --- PRIVATE HELPERS ---
  Future<void> _fetchYahooSingle(String symbol, {bool isTransient = false}) async {
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

        _updateCache(symbol, current, change, isTransient: isTransient);
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

  void _updateCache(String symbol, double price, double change, {bool isTransient = false}) {
    _cache[symbol] = AssetCacheModel(
      price: price,
      change: change,
      timestamp: DateTime.now(),
      isTransient: isTransient,
    );
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> mapToSave = {};
      _cache.forEach((key, value) {
        if (!value.isTransient) {
          mapToSave[key] = value.toJson();
        }
      });
      final String jsonString = jsonEncode(mapToSave);
      await prefs.setString(_cacheKey, jsonString);
    } catch (e) {
      print("Save Cache Error: $e");
    }
  }

  List<Map<String, dynamic>> getMarketSummarySync() {
    final List<Map<String, dynamic>> list = [];

    void add(String sym, String display) {
      final item = _cache[sym] ?? _cache["$sym.IS"];
      if (item != null) {
        list.add({
          'symbol': display,
          'value': item.price.toStringAsFixed(2),
          'raw_value': item.price,
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
            'raw_price': e.value.price,
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
              !e.key.contains("_") &&
              !e.key.contains("PALADYUM") &&
              !e.key.contains("PLATIN") &&
              !e.key.contains("GUMUS") &&
              !e.key.contains("_TL") &&
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
            'raw_price': e.value.price,
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
        for (var s in _allBistStocks) {
          final cachedSym = '$s.IS';
          final d = _cache[cachedSym];
          if (d != null) {
            results.add({
              'symbol': s,
              'name': s,
              'price': d.price,
              'change': d.change,
            });
          } else {
            results.add({
              'symbol': s,
              'name': s,
              'price': 0.0,
              'change': 0.0,
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
          if (d != null) {
            results.add({
              'symbol': s,
              'name': m['name'],
              'price': d.price,
              'change': d.change,
            });
          }
        }
        break;
      case AssetType.FOREX:
        for (var s in _whitelistForex) {
          if (s == "USD") {
            final d = _cache["USD/TRY"];
            if (d != null) {
              results.add({
                'symbol': 'USD',
                'name': 'Dolar',
                'price': d.price,
                'change': d.change,
              });
            }
          } else {
            final d = _cache["$s/TRY"];
            if (d != null) {
              results.add({
                'symbol': s,
                'name': s,
                'price': d.price,
                'change': d.change,
              });
            }
          }
        }
        break;
      case AssetType.GLOBAL:
        for (var s in _whitelistGlobal) {
          final d = _cache[s];
          if (d != null) {
            results.add({
              'symbol': s,
              'name': s,
              'price': d.price,
              'change': d.change,
            });
          }
        }
        break;
      case AssetType.FUND:
        for (var s in _whitelistFund) {
          final d = _cache[s];
          if (d != null) {
            results.add({
              'symbol': s,
              'name': s,
              'price': d.price,
              'change': d.change,
            });
          } else {
            // If TEFAS blocked the request, show the fund with 0.0 price
            // so the user knows it's in the list but failed to fetch.
            results.add({
              'symbol': s,
              'name': s,
              'price': 0.0,
              'change': 0.0,
            });
          }
        }
        break;
    }
    return results;
  }

  // --- COMPATIBILITY / PUBLIC ---
  Future<Map<String, double>> getCurrentPrices(List<String> symbols) async {
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
        item = _cache[inputSym];
      }
      // 2. Try .IS
      else if (_cache.containsKey("$inputSym.IS")) {
        item = _cache["$inputSym.IS"];
      }
      // 3. Try /TRY
      else if (_cache.containsKey("$inputSym/TRY")) {
        item = _cache["$inputSym/TRY"];
      }
      // 4. Legacy / Logic Mapping
      else {
        // Map Legacy -> New Cache Key
        String targetKey = inputSym;
        if (inputSym == 'GRAM') {
          targetKey = 'Gram Altın';
        } else if (inputSym == 'CEYREK')
          targetKey = 'Çeyrek Altın';
        else if (inputSym == 'YARIM')
          targetKey = 'Yarım Altın';
        else if (inputSym == 'TAM')
          targetKey = 'Tam Altın';
        else if (inputSym == 'CUMHURIYET')
          targetKey = 'Cumhuriyet Altın';
        else if (inputSym == 'ONS')
          targetKey = 'Ons Altın';
        else {
          final possible = findCaseInsensitive(inputSym);
          if (possible != null) targetKey = possible;
        }

        if (_cache.containsKey(targetKey)) {
          // foundKey = targetKey;
          item = _cache[targetKey];
        }
      }

      if (item != null) {
        results.add({
          // Return the input symbol so the requester can match it with their list
          'symbol': inputSym,
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

  Future<void> fetchSingle(String symbol, {bool isTransient = false}) async {
    try {
      if (_allBistStocks.contains(symbol)) {
        await _fetchYahooSingle('$symbol.IS', isTransient: isTransient);
      } else {
        await _fetchYahooSingle(symbol, isTransient: isTransient);
      }
    } catch (e) {
      print("fetchSingle error for $symbol: $e");
    }
  }
}
