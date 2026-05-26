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

      case AssetType.GLOBAL:
        // App format: "AAPL", "MSFT"
        final cleanSymbol = symbol.trim().toUpperCase();
        return cleanSymbol; // TradingView auto-resolves AAPL, MSFT, etc.

      case AssetType.FUND:
        final cleanSymbol = symbol.trim().toUpperCase();
        return "TEFAS:$cleanSymbol";

      case AssetType.FOREX:
        final cleanSymbol = symbol.trim().toUpperCase();
        if (cleanSymbol.contains('/')) {
          return cleanSymbol.replaceAll('/', '');
        }
        return "${cleanSymbol}TRY";

      case AssetType.GOLD:
        switch(symbol) {
          case 'Ons Altın': return 'OANDA:XAUUSD';
          case 'Gram Altın': return 'FX_IDC:XAUTRYG';
          case 'Çeyrek Altın': return 'FX_IDC:XAUTRYG';
          case 'Yarım Altın': return 'FX_IDC:XAUTRYG';
          case 'Tam Altın': return 'FX_IDC:XAUTRYG';
          case 'Cumhuriyet Altın': return 'FX_IDC:XAUTRYG';
          case 'Ons Gümüş': return 'OANDA:XAGUSD';
          case 'Gram Gümüş': return 'FX_IDC:XAGTRYG';
          case 'Ons Platin': return 'OANDA:XPTUSD';
          case 'Gram Platin': return 'FX_IDC:XPTTRYG';
          case 'Ons Paladyum': return 'OANDA:XPDUSD';
          case 'Gram Paladyum': return 'FX_IDC:XPDTRYG';
          default: return null;
        }

    }
  }

  static String? getTradingViewUrl(String symbol, AssetType type) {
    final clean = symbol.trim().toUpperCase();
    switch (type) {
      case AssetType.STOCK:
        return "https://tr.tradingview.com/symbols/BIST-$clean/";
      case AssetType.CRYPTO:
        return "https://tr.tradingview.com/symbols/${clean}USDT/";
      case AssetType.GLOBAL:
        return "https://tr.tradingview.com/symbols/$clean/";
      case AssetType.FUND:
        return "https://www.tefas.gov.tr/FonAnaliz.aspx?FonKod=$clean";
      case AssetType.FOREX:
        final tvSym = getTradingViewSymbol(symbol, type)?.replaceAll('FX:', '');
        return "https://tr.tradingview.com/symbols/$tvSym/";
      case AssetType.GOLD:
        final tvSym = getTradingViewSymbol(symbol, type)?.split(':').last;
        if (tvSym != null) {
          return "https://tr.tradingview.com/symbols/$tvSym/";
        }
        return null;
    }
  }

  /// Returns TradingView's official embed URL (loaded directly, no origin issues)
  static String getEmbedUrl(String tvSymbol, bool isDark) {
    final theme = isDark ? "dark" : "light";
    final encodedSymbol = Uri.encodeComponent(tvSymbol);
    return "https://s.tradingview.com/widgetembed/?"
        "hideideas=1&"
        "overrides=%7B%7D&"
        "enabled_features=%5B%5D&"
        "disabled_features=%5B%5D&"
        "locale=tr&"
        "utm_source=www.tradingview.com&"
        "utm_medium=widget_new&"
        "utm_campaign=chart&"
        "utm_term=$encodedSymbol&"
        "symbol=$encodedSymbol&"
        "interval=D&"
        "theme=$theme&"
        "style=1&"
        "timezone=Etc%2FUTC&"
        "studies=%5B%5D&"
        "hide_side_toolbar=0&"
        "allow_symbol_change=0&"
        "save_image=0&"
        "show_popup_button=0";
  }
}

