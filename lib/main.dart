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
      final alerts = await assetService.getActiveAlerts();
      
      if (alerts.isEmpty) return Future.value(true);

      final api = ApiService();
      await api.init();
      
      await api.fetchBist();
      await api.fetchCrypto();
      await api.fetchForex();
      await api.fetchGlobal();
      await api.fetchFunds();

      final notificationService = NotificationService();
      await notificationService.init();

      for (var alert in alerts) {
        final asset = api.getAsset(alert.symbol);
        final price = asset?.price ?? 0.0;
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
      print("Background Task Error: $e");
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
