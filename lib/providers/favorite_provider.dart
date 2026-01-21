import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/favorite.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Favorite> _favorites = [];

  List<Favorite> get favorites => _favorites;

  Future<void> loadFavorites() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('favorites');
    _favorites = result.map((e) => Favorite.fromMap(e)).toList();
    notifyListeners();
  }

  String _canonical(String s) {
    if (s == 'USD' || s == 'Dolar') return 'USD/TRY';
    if (s == 'EUR' || s == 'Euro') return 'EUR/TRY';
    if (s.contains('Altın') ||
        s.contains('Gümüş') ||
        s.contains('Platin') ||
        s.contains('Paladyum')) {
      return s;
    }
    return s.toUpperCase();
  }

  bool isFavorite(String symbol) {
    final target = _canonical(symbol);
    return _favorites.any((f) => _canonical(f.symbol) == target);
  }

  Future<void> toggleFavorite(Favorite favorite) async {
    final db = await DatabaseHelper.instance.database;
    final targetSymbol = _canonical(favorite.symbol);

    // Check if ANY synonymous symbol exists
    final existingIndex = _favorites.indexWhere(
      (f) => _canonical(f.symbol) == targetSymbol,
    );

    if (existingIndex != -1) {
      final candidates = _favorites
          .where((f) => _canonical(f.symbol) == targetSymbol)
          .toList();

      for (var f in candidates) {
        await db.delete(
          'favorites',
          where: 'symbol = ?',
          whereArgs: [f.symbol],
        );
      }
      _favorites.removeWhere((f) => _canonical(f.symbol) == targetSymbol);
    } else {
      final newFav = Favorite(
        symbol: targetSymbol,
        type: favorite.type,
      );

      await db.insert('favorites', newFav.toMap());
      _favorites.add(newFav);
    }
    notifyListeners();
  }

  Future<void> clearFavorites() async {
    _favorites = [];
    notifyListeners();
  }
}
