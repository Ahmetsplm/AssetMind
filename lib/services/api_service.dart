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
}
