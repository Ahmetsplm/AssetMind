import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';

import 'providers/favorite_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/market_provider.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => FavoriteProvider()..loadFavorites(),
        ),
        ChangeNotifierProvider(
          create: (_) => PortfolioProvider()..loadPortfolios(),
        ),
        ChangeNotifierProvider(
          // MarketProvider must be EAGER to run background timers
          lazy: false,
          create: (_) {
            print("MARKET PROVIDER INIT STARTED");
            return MarketProvider()..init();
          },
        ),
      ],
      child: MaterialApp(
        title: 'AssetMind',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A237E), // Lacivert
            primary: const Color(0xFF1A237E),
            secondary: Colors.blueAccent,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Color(0xFF1A237E),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
