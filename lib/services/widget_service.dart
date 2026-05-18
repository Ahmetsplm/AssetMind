import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const String portfolioWidgetName = 'PortfolioWidgetProvider';
  static const String watchlistWidgetName = 'WatchlistWidgetProvider';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId('group.com.ahmet.assetmind');
  }

  static Future<void> updatePortfolioWidget({
    required double totalValue,
    required double netProfit,
    required double profitPercentage,
    required int assetCount,
  }) async {
    try {
      final formatCurrency = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
      
      await HomeWidget.saveWidgetData<String>('total_value', formatCurrency.format(totalValue));
      await HomeWidget.saveWidgetData<String>('net_profit', formatCurrency.format(netProfit));
      await HomeWidget.saveWidgetData<String>('profit_percentage', '%${profitPercentage.toStringAsFixed(2)}');
      await HomeWidget.saveWidgetData<String>('last_update', DateFormat('HH:mm').format(DateTime.now()));
      await HomeWidget.saveWidgetData<int>('asset_count', assetCount);
      await HomeWidget.saveWidgetData<bool>('is_positive', netProfit >= 0);

      await HomeWidget.updateWidget(name: portfolioWidgetName);
    } catch (e) {
      debugPrint('Error updating portfolio widget: $e');
    }
  }

  static Future<void> updateWatchlistWidget(List<Map<String, dynamic>> favorites) async {
    try {
      int count = favorites.length > 10 ? 10 : favorites.length;
      await HomeWidget.saveWidgetData<int>('fav_count', count);
      
      for (int i = 0; i < count; i++) {
        final fav = favorites[i];
        final price = fav['price'] as double? ?? 0.0;
        final change = fav['change'] as double? ?? 0.0;
        
        await HomeWidget.saveWidgetData<String>('fav_${i}_symbol', fav['symbol'] ?? '');
        await HomeWidget.saveWidgetData<String>('fav_${i}_price', price.toStringAsFixed(2));
        await HomeWidget.saveWidgetData<String>('fav_${i}_change', '%${change.toStringAsFixed(2)}');
        await HomeWidget.saveWidgetData<bool>('fav_${i}_is_positive', change >= 0);
        await HomeWidget.saveWidgetData<String>('fav_${i}_currency_symbol', fav['currencySymbol'] ?? '₺');
      }
      
      await HomeWidget.updateWidget(name: watchlistWidgetName);
    } catch (e) {
      debugPrint('Error updating watchlist widget: $e');
    }
  }
}
