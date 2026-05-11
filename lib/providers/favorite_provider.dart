import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../models/favorite.dart';
import '../models/holding.dart';
import '../services/asset_service.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Favorite> _favorites = [];
  final AssetService _assetService = AssetService();
  StreamSubscription<AuthState>? _authSubscription;

  List<Favorite> get favorites => _favorites;

  FavoriteProvider() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        loadFavorites();
      } else if (data.event == AuthChangeEvent.signedOut) {
        clearFavorites();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadFavorites() async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Local Read
    final localResult = await db.query('favorites');
    _favorites = localResult.map((e) => Favorite.fromMap(e)).toList();
    notifyListeners();

    // 2. Cloud Sync
    if (_assetService.userId != null) {
      try {
        final cloudFavorites = await _assetService.getFavorites();
        
        await db.delete('favorites');
        
        List<Favorite> newFavorites = [];
        for (var fMap in cloudFavorites) {
          final fav = Favorite(
            symbol: fMap['symbol'],
            type: _parseAssetType(fMap['type']),
          );
          await db.insert('favorites', fav.toMap());
          newFavorites.add(fav);
        }
        
        _favorites = newFavorites;
        notifyListeners();
      } catch (_) {}
    }
  }

  AssetType _parseAssetType(String typeStr) {
    return AssetType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AssetType.STOCK,
    );
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
        if (_assetService.userId != null) {
          await _assetService.removeFavorite(f.symbol);
        }
      }
      _favorites.removeWhere((f) => _canonical(f.symbol) == targetSymbol);
    } else {
      final newFav = Favorite(
        symbol: targetSymbol,
        type: favorite.type,
      );

      await db.insert('favorites', newFav.toMap());
      _favorites.add(newFav);
      if (_assetService.userId != null) {
        await _assetService.addFavorite(newFav.symbol, newFav.type.name);
      }
    }
    notifyListeners();
  }

  Future<void> clearFavorites() async {
    _favorites = [];
    notifyListeners();
  }
}
