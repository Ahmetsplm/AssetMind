import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';

import 'providers/favorite_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_provider.dart';

import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'providers/auth_provider.dart';
import 'services/notification_service.dart';
import 'services/asset_service.dart';
import 'services/api_service.dart';
import 'services/widget_service.dart';
import 'package:home_widget/home_widget.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
      
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );

      final assetService = AssetService();
      
      final api = ApiService();
      await api.init();
      
      await api.fetchBist();
      await api.fetchCrypto();
      await api.fetchForex();
      await api.fetchGlobal();
      await api.fetchFunds();

      // --- WIDGET UPDATE LOGIC ---
      try {
        // Portföy widget'ı için: tüm portföylerdeki holdingleri topla
        final portfolios = await assetService.getPortfolios();
        double totalValue = 0;
        double totalCost = 0;
        int assetCount = 0;
        
        for (var p in portfolios) {
          final holdings = await assetService.getHoldings(p.id!);
          for (var h in holdings) {
            if (h.quantity <= 0) continue;
            var asset = api.getAsset(h.symbol) ?? api.getAsset('${h.symbol}.IS');
            double price = asset?.price ?? h.averageCost;
            totalValue += h.quantity * price;
            totalCost += h.quantity * h.averageCost;
            assetCount++;
          }
        }
        
        double netProfit = totalValue - totalCost;
        double profitPercentage = totalCost > 0 ? (netProfit / totalCost) * 100 : 0.0;
        
        await WidgetService.init();
        await WidgetService.updatePortfolioWidget(
          totalValue: totalValue,
          netProfit: netProfit,
          profitPercentage: profitPercentage,
          assetCount: assetCount,
        );

        // Favoriler widget'ı için
        final favs = await assetService.getFavorites();
        List<Map<String, dynamic>> favWidgetData = [];
        for (var f in favs) {
          final sym = f['symbol'] as String? ?? '';
          if (sym.isEmpty) continue;
          var asset = api.getAsset(sym) ?? api.getAsset('$sym.IS');
          if (asset != null) {
            favWidgetData.add({
              'symbol': sym.replaceAll('.IS', ''),
              'price': asset.price,
              'change': asset.change,
            });
          }
        }
        await WidgetService.updateWatchlistWidget(favWidgetData);
      } catch (e) {
        debugPrint("Background widget update error: $e");
      }
      
      // --- ALERT LOGIC ---
      final alerts = await assetService.getActiveAlerts();
      if (alerts.isEmpty) return Future.value(true);

      final notificationService = NotificationService();
      await notificationService.init();

      for (var alert in alerts) {
        var asset = api.getAsset(alert.symbol);
        double price = asset?.price ?? 0.0;
        if (price == 0.0) {
          asset = api.getAsset('${alert.symbol}.IS');
          price = asset?.price ?? 0.0;
        }
        
        if (price == 0.0) continue;

        bool triggered = false;
        if (alert.condition == 'above' && price >= alert.targetPrice) {
          triggered = true;
        } else if (alert.condition == 'below' && price <= alert.targetPrice) {
          triggered = true;
        }

        if (triggered) {
          await notificationService.showNotification(
            id: alert.id.hashCode,
            title: 'Fiyat Alarmı: ${alert.symbol}',
            body: '${alert.symbol} belirlediğiniz hedef fiyata ulaştı! Güncel: \$${price.toStringAsFixed(2)}',
          );
          await assetService.deactivateAlert(alert.id);
        }
      }
    } catch (e) {
      debugPrint("Background Task Error: $e");
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await NotificationService().init();
  await WidgetService.init();
  
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  
  Workmanager().registerPeriodicTask(
    "1",
    "priceAlertTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  // Deep Link: Widget'tan gelen URI'yi kontrol et
  final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  int initialTab = 0;
  if (initialUri != null) {
    if (initialUri.host == 'portfolio') {
      initialTab = 3;
    } else if (initialUri.host == 'favorites') {
      initialTab = 1;
    }
  }

  runApp(MyApp(initialTab: initialTab));
}

class MyApp extends StatelessWidget {
  final int initialTab;
  const MyApp({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider()..loadFavorites(),
        ),
        ChangeNotifierProvider(
          create: (_) => PortfolioProvider()..loadPortfolios(),
        ),
        ChangeNotifierProvider(
          create: (_) => MarketProvider()..init(),
          lazy: false,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AssetMind',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(initialTab: initialTab),
          );
        },
      ),
    );
  }
}
