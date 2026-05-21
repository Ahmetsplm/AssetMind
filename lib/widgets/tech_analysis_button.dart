import 'package:flutter/material.dart';
import '../screens/trading_view_screen.dart';
import '../models/holding.dart';

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

    return IconButton(
      icon: Icon(
        Icons.candlestick_chart_rounded,
        color: Theme.of(context).disabledColor,
        size: 24,
      ),
      tooltip: type == AssetType.FUND ? "Fon Analizi" : "Teknik Analiz (TradingView)",
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TradingViewScreen(symbol: symbol, type: type),
          ),
        );
      },
    );
  }
}

