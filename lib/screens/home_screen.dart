import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'market_screen.dart';
import 'favorites_screen.dart';
import 'add_asset/asset_type_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MarketScreen(),
    const FavoritesScreen(),
    const AssetTypeSelectionScreen(),
    const Center(child: Text("Portföyüm")), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 4 items require fixed type
        selectedItemColor: const Color(0xFF1A237E),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Piyasalar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: 'Favoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled, size: 32),
            label: 'Ekle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline_rounded),
            activeIcon: Icon(Icons.pie_chart_rounded),
            label: 'Portföy',
          ),
        ],
      ),
    );
  }
}
