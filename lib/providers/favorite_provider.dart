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

  bool isFavorite(String symbol) {
    return _favorites.any((f) => f.symbol == symbol);
  }

  Future<void> toggleFavorite(Favorite favorite) async {
    final db = await DatabaseHelper.instance.database;
    final isFav = isFavorite(favorite.symbol);

    if (isFav) {
      await db.delete(
        'favorites',
        where: 'symbol = ?',
        whereArgs: [favorite.symbol],
      );
      _favorites.removeWhere((f) => f.symbol == favorite.symbol);
    } else {
      await db.insert('favorites', favorite.toMap());
      _favorites.add(favorite);
    }
    notifyListeners();
  }
}
