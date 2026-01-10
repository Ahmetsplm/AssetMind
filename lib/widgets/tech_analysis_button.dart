import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/trading_view_screen.dart';
import '../models/holding.dart';
import '../utils/trading_view_helper.dart';

class TechAnalysisButton extends StatelessWidget {
  final String symbol;
  final AssetType type;

  const TechAnalysisButton({
    super.key,
    required this.symbol,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (type != AssetType.STOCK && type != AssetType.CRYPTO) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: Icon(
        type == AssetType.STOCK
            ? Icons.open_in_new_rounded
            : Icons.candlestick_chart_rounded,
        color: Theme.of(context).disabledColor,
        size: 24,
      ),
      tooltip: type == AssetType.STOCK ? "TradingView'de Aç" : "Teknik Analiz",
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () async {
        if (type == AssetType.STOCK) {
          // Open in Browser
          final urlStr = TradingViewHelper.getTradingViewUrl(symbol, type);
          if (urlStr != null) {
            final uri = Uri.parse(urlStr);
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Link açılamadı")));
              }
            }
          }
        } else {
          // Open WebView
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TradingViewScreen(symbol: symbol, type: type),
            ),
          );
        }
      },
    );
  }
}
