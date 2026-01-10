import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'market_screen.dart';
import 'favorites_screen.dart';
import 'add_asset/asset_type_selection_screen.dart';
import 'portfolio_screen.dart';

import 'settings_screen.dart';

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
    const PortfolioScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Key for glass effect over content
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    0,
                    Icons.bar_chart_rounded,
                    Icons.bar_chart_rounded,
                    'Piyasalar',
                  ),
                  _buildNavItem(
                    1,
                    Icons.star_border_rounded,
                    Icons.star_rounded,
                    'Favoriler',
                  ),
                  _buildNavItem(
                    2,
                    CupertinoIcons.add_circled,
                    CupertinoIcons.add_circled_solid,
                    'Ekle',
                    isMain: true,
                  ),
                  _buildNavItem(
                    3,
                    Icons.pie_chart_outline_rounded,
                    Icons.pie_chart_rounded,
                    'Portföy',
                  ),
                  _buildNavItem(
                    4,
                    Icons.settings_outlined,
                    Icons.settings,
                    'Ayarlar',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label, {
    bool isMain = false,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isMain ? 8 : 0),
              decoration: isMain && isSelected
                  ? BoxDecoration(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: isMain ? 32 : 24,
              ),
            ),
            const SizedBox(height: 4),
            if (!isMain)
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
