import '../models/holding.dart';

class TradingViewHelper {
  static String? getTradingViewSymbol(String symbol, AssetType type) {
    switch (type) {
      case AssetType.STOCK:
        // App format: "THYAO", "ASELS"
        // Ensure no extra spaces
        final cleanSymbol = symbol.trim().toUpperCase();
        // BIST: is standard.
        return "BIST:$cleanSymbol";

      case AssetType.CRYPTO:
        // App format: "BTC", "ETH"
        // Ensure no extra spaces
        final cleanSymbol = symbol.trim().toUpperCase();
        // TradingView needs "BINANCE:BTCUSDT"
        return "BINANCE:${cleanSymbol}USDT";

      default:
        // For Gold/Forex, maybe handle later.
        // Gold: "XAUUSD" -> "OANDA:XAUUSD"?
        // Forex: "USD/TRY" -> "FX:USDTRY"?
        return null;
    }
  }

  static String? getTradingViewUrl(String symbol, AssetType type) {
    if (type == AssetType.STOCK) {
      // https://tr.tradingview.com/symbols/BIST-THYAO/
      final clean = symbol.trim().toUpperCase();
      return "https://tr.tradingview.com/symbols/BIST-$clean/";
    }
    return null;
  }

  static String getHtmlContent(String tvSymbol, bool isDark) {
    final theme = isDark ? "dark" : "light";
    return """
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background-color: ${isDark ? '#131722' : '#ffffff'}; }
          #tradingview_widget { width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <div class="tradingview-widget-container" id="tradingview_widget"></div>
        <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
        <script type="text/javascript">
          new TradingView.widget({
            "autosize": true,
            "symbol": "$tvSymbol",
            "interval": "D",
            "timezone": "Etc/UTC",
            "theme": "$theme",
            "style": "1",
            "locale": "tr",
            "toolbar_bg": "#f1f3f6",
            "enable_publishing": false,
            "allow_symbol_change": false,
            "container_id": "tradingview_widget",
            "hide_side_toolbar": false
          });
        </script>
      </body>
      </html>
    """;
  }
}
