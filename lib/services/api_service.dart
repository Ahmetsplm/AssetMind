import '../models/holding.dart'; // For AssetType enum

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Mock Data Generators for UI Testing

  Future<List<Map<String, dynamic>>> getMarketSummary() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'symbol': 'BIST 100',
        'value': 11534.09,
        'change_rate': 0.31,
        'is_rising': true,
      },
      {
        'symbol': 'USD/TRY',
        'value': 43.0435,
        'change_rate': 0.01,
        'is_rising': true,
      },
      {
        'symbol': 'EUR/TRY',
        'value': 50.3637,
        'change_rate': -0.22,
        'is_rising': false,
      },
      {
        'symbol': 'Gram Altın',
        'value': 2950.40,
        'change_rate': 2.04,
        'is_rising': true,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getStockMovers({
    bool isRising = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock tickers
    final risingStocks = [
      {'symbol': 'TRMET', 'price': 113.10, 'change': 4.72},
      {'symbol': 'TRALT', 'price': 43.90, 'change': 4.62},
      {'symbol': 'TRENJ', 'price': 99.50, 'change': 4.13},
      {'symbol': 'ALTNY', 'price': 15.47, 'change': 3.76},
      {'symbol': 'CANTE', 'price': 2.09, 'change': 2.45},
    ];

    final fallingStocks = [
      {'symbol': 'BJKAS', 'price': 89.50, 'change': -5.12},
      {'symbol': 'FENER', 'price': 120.30, 'change': -4.80},
      {'symbol': 'GSRAY', 'price': 210.00, 'change': -3.50},
      {'symbol': 'TSPOR', 'price': 45.20, 'change': -3.10},
      {'symbol': 'KARSN', 'price': 12.40, 'change': -2.90},
    ];

    return isRising ? risingStocks : fallingStocks;
  }

  Future<List<Map<String, dynamic>>> getFavoritesData(
    List<String> symbols,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Generate dummy data based on symbols
    return symbols.map((symbol) {
      // Mock logic to generate consistent dummy data
      double price = 0;
      double change = 0;

      if (symbol == 'XU100') {
        price = 11534.09;
        change = 0.31;
      } else if (symbol == 'THYAO') {
        price = 312.50;
        change = 1.25;
      } else if (symbol == 'GARAN') {
        price = 118.40;
        change = -0.45;
      } else if (symbol == 'USDTRY') {
        price = 34.15;
        change = 0.05;
      } else if (symbol == 'BTC') {
        price = 67500.00;
        change = 2.10;
      } else if (symbol == 'GLD') {
        price = 2450.00;
        change = 0.85;
      } else {
        // Fallback for other symbols
        price = 100.0 + (symbol.length * 10);
        change = (symbol.length % 2 == 0) ? 1.5 : -1.5;
      }

      return {
        'symbol': symbol,
        'price': price,
        'change_rate': change,
        'last_update': '10:30',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCryptoMovers({
    bool isRising = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final risingCryptos = [
      {'symbol': 'BTC', 'price': 65430.00, 'change': 2.50},
      {'symbol': 'ETH', 'price': 3450.00, 'change': 3.10},
      {'symbol': 'SOL', 'price': 145.20, 'change': 5.40},
      {'symbol': 'AVAX', 'price': 45.30, 'change': 4.20},
      {'symbol': 'BNB', 'price': 580.00, 'change': 1.80},
    ];

    final fallingCryptos = [
      {'symbol': 'XRP', 'price': 0.60, 'change': -1.20},
      {'symbol': 'DOGE', 'price': 0.15, 'change': -2.50},
      {'symbol': 'ADA', 'price': 0.45, 'change': -3.10},
      {'symbol': 'MATIC', 'price': 0.70, 'change': -4.50},
      {'symbol': 'SHIB', 'price': 0.000025, 'change': -5.60},
    ];

    return isRising ? risingCryptos : fallingCryptos;
  }

  Future<List<Map<String, dynamic>>> getAssetsByType(AssetType type) async {
    await Future.delayed(const Duration(milliseconds: 300));

    switch (type) {
      case AssetType.STOCK:
        return [
          {
            'symbol': 'ACSEL',
            'name': 'Acıpayam Selüloz',
            'price': 99.10,
            'change': 1.43,
          },
          {
            'symbol': 'ADEL',
            'name': 'Adel Kalemcilik',
            'price': 34.22,
            'change': 3.70,
          },
          {
            'symbol': 'ADESE',
            'name': 'Adese Gayrimenkul',
            'price': 1.54,
            'change': 1.32,
          },
          {
            'symbol': 'AEFES',
            'name': 'Anadolu Efes',
            'price': 15.96,
            'change': 1.10,
          },
          {
            'symbol': 'AFYON',
            'name': 'Afyon Çimento',
            'price': 13.13,
            'change': 1.16,
          },
          {
            'symbol': 'AGESA',
            'name': 'Agesa Emeklilik',
            'price': 215.50,
            'change': -2.58,
          },
          {
            'symbol': 'AGHOL',
            'name': 'AG Anadolu Grubu',
            'price': 29.34,
            'change': 2.23,
          },
          {'symbol': 'AKBNK', 'name': 'Akbank', 'price': 42.50, 'change': 0.50},
          {
            'symbol': 'ALARK',
            'name': 'Alarko Holding',
            'price': 110.20,
            'change': -1.20,
          },
          {
            'symbol': 'ASELS',
            'name': 'Aselsan',
            'price': 65.40,
            'change': 1.80,
          },
          {
            'symbol': 'BIMAS',
            'name': 'BİM Mağazalar',
            'price': 380.00,
            'change': -0.40,
          },
          {
            'symbol': 'EREGL',
            'name': 'Ereğli Demir Çelik',
            'price': 48.70,
            'change': 0.90,
          },
          {
            'symbol': 'FROTO',
            'name': 'Ford Otosan',
            'price': 1100.00,
            'change': 2.10,
          },
          {
            'symbol': 'GARAN',
            'name': 'Garanti BBVA',
            'price': 118.40,
            'change': -0.45,
          },
          {
            'symbol': 'KCHOL',
            'name': 'Koç Holding',
            'price': 185.00,
            'change': 1.15,
          },
          {
            'symbol': 'ODAS',
            'name': 'Odaş Elektrik',
            'price': 9.80,
            'change': 3.40,
          },
          {
            'symbol': 'PETKM',
            'name': 'Petkim',
            'price': 22.10,
            'change': -1.10,
          },
          {
            'symbol': 'PGSUS',
            'name': 'Pegasus',
            'price': 850.50,
            'change': 4.20,
          },
          {
            'symbol': 'SAHOL',
            'name': 'Sabancı Holding',
            'price': 95.30,
            'change': 0.80,
          },
          {
            'symbol': 'SISE',
            'name': 'Şişecam',
            'price': 52.40,
            'change': -0.30,
          },
          {
            'symbol': 'THYAO',
            'name': 'Türk Hava Yolları',
            'price': 312.50,
            'change': 1.25,
          },
          {
            'symbol': 'TUPRS',
            'name': 'Tüpraş',
            'price': 175.80,
            'change': 0.60,
          },
          {'symbol': 'VESTL', 'name': 'Vestel', 'price': 88.90, 'change': 2.80},
          {
            'symbol': 'YKBNK',
            'name': 'Yapı Kredi Bankası',
            'price': 32.10,
            'change': 0.10,
          },
        ];
      case AssetType.GOLD:
        return [
          {
            'symbol': 'ONS',
            'name': 'Ons Altın',
            'price': 2450.00,
            'change': 0.8,
          },
          {
            'symbol': 'GRAM',
            'name': 'Gram Altın',
            'price': 2950.40,
            'change': 1.2,
          },
          {
            'symbol': 'CEYREK',
            'name': 'Çeyrek Altın',
            'price': 4850.00,
            'change': 1.1,
          },
          {
            'symbol': 'YARIM',
            'name': 'Yarım Altın',
            'price': 9700.00,
            'change': 1.1,
          },
          {
            'symbol': 'TAM',
            'name': 'Tam Altın',
            'price': 19400.00,
            'change': 1.1,
          },
          {
            'symbol': 'CUMHURIYET',
            'name': 'Cumhuriyet Altını',
            'price': 20100.00,
            'change': 1.0,
          },
          {
            'symbol': 'GUMUS',
            'name': 'Gümüş (Gram)',
            'price': 32.40,
            'change': 2.5,
          },
        ];
      case AssetType.CRYPTO:
        return [
          {
            'symbol': 'BTC',
            'name': 'Bitcoin',
            'price': 67500.00,
            'change': 2.1,
          },
          {
            'symbol': 'ETH',
            'name': 'Ethereum',
            'price': 3500.00,
            'change': 1.5,
          },
          {'symbol': 'SOL', 'name': 'Solana', 'price': 148.50, 'change': 4.2},
          {
            'symbol': 'BNB',
            'name': 'Binance Coin',
            'price': 590.00,
            'change': 0.5,
          },
          {'symbol': 'XRP', 'name': 'Ripple', 'price': 0.62, 'change': -1.0},
          {'symbol': 'ADA', 'name': 'Cardano', 'price': 0.46, 'change': -0.8},
          {
            'symbol': 'AVAX',
            'name': 'Avalanche',
            'price': 46.20,
            'change': 3.0,
          },
          {'symbol': 'DOGE', 'name': 'Dogecoin', 'price': 0.16, 'change': -2.0},
        ];
      case AssetType.FOREX:
        return [
          {
            'symbol': 'USDTRY',
            'name': 'Amerikan Doları',
            'price': 34.15,
            'change': 0.05,
          },
          {'symbol': 'EURTRY', 'name': 'Euro', 'price': 37.25, 'change': -0.1},
          {
            'symbol': 'GBPTRY',
            'name': 'İngiliz Sterlini',
            'price': 43.50,
            'change': 0.2,
          },
          {
            'symbol': 'EURUSD',
            'name': 'Euro / USD',
            'price': 1.09,
            'change': -0.15,
          },
        ];
    }
  }
}
