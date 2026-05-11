import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/portfolio.dart';
import '../models/holding.dart';
import '../models/transaction.dart';
import '../models/alert.dart';

class AssetService {
  final SupabaseClient _client = Supabase.instance.client;

  String? get userId => _client.auth.currentUser?.id;

  // -- Alerts --
  Future<List<Alert>> getActiveAlerts() async {
    if (userId == null) return [];
    final data = await _client
        .from('alerts')
        .select()
        .eq('user_id', userId!)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return data.map((e) => Alert.fromJson(e)).toList();
  }

  Future<List<Alert>> getAllAlerts() async {
    if (userId == null) return [];
    final data = await _client
        .from('alerts')
        .select()
        .eq('user_id', userId!)
        .order('created_at', ascending: false);
    return data.map((e) => Alert.fromJson(e)).toList();
  }

  Future<Alert> addAlert(Alert alert) async {
    if (userId == null) throw Exception("Kullanıcı girişi yapılmamış");
    
    final Map<String, dynamic> dataToInsert = alert.toJson();
    dataToInsert['user_id'] = userId;
    
    final data = await _client.from('alerts').insert(dataToInsert).select().single();
    return Alert.fromJson(data);
  }

  Future<void> deleteAlert(String id) async {
    if (userId == null) return;
    await _client
        .from('alerts')
        .delete()
        .eq('id', id)
        .eq('user_id', userId!);
  }

  Future<void> deactivateAlert(String id) async {
    if (userId == null) return;
    await _client
        .from('alerts')
        .update({'is_active': false})
        .eq('id', id)
        .eq('user_id', userId!);
  }

  // -- Portfolios --
  Future<List<Portfolio>> getPortfolios() async {
    if (userId == null) return [];
    final data = await _client
        .from('portfolios')
        .select()
        .eq('user_id', userId!)
        .order('creation_date', ascending: true);
    return data.map((e) => Portfolio.fromMap(e)).toList();
  }

  Future<Portfolio> addPortfolio(String name, {bool isDefault = false}) async {
    if (userId == null) throw Exception("Kullanıcı girişi yapılmamış");
    final data = await _client.from('portfolios').insert({
      'user_id': userId,
      'name': name,
      'is_default': isDefault,
    }).select().single();
    return Portfolio.fromMap(data);
  }

  Future<void> updatePortfolio(int id, String newName) async {
    if (userId == null) return;
    await _client
        .from('portfolios')
        .update({'name': newName})
        .eq('id', id)
        .eq('user_id', userId!);
  }

  // -- Holdings --
  Future<List<Holding>> getHoldings(int portfolioId) async {
    if (userId == null) return [];
    final data = await _client
        .from('holdings')
        .select()
        .eq('portfolio_id', portfolioId)
        .eq('user_id', userId!);
    return data.map((e) => Holding.fromMap(e)).toList();
  }

  Future<Holding> upsertHolding(Holding holding) async {
    if (userId == null) throw Exception("Kullanıcı girişi yapılmamış");
    
    final Map<String, dynamic> dataToInsert = holding.toMap();
    dataToInsert['user_id'] = userId;
    
    if (holding.id == null) {
      dataToInsert.remove('id'); // DB auto-generates
      final data = await _client.from('holdings').insert(dataToInsert).select().single();
      return Holding.fromMap(data);
    } else {
      final data = await _client
          .from('holdings')
          .update(dataToInsert)
          .eq('id', holding.id!)
          .select()
          .single();
      return Holding.fromMap(data);
    }
  }

  // -- Transactions --
  Future<List<TransactionModel>> getAllTransactionsForPortfolio(int portfolioId) async {
     if (userId == null) return [];
     
     // Supabase 'in_' metodu ile holding ID'lerine göre filtreleme
     final holdings = await getHoldings(portfolioId);
     if (holdings.isEmpty) return [];
     
     final holdingIds = holdings.map((h) => h.id).toList();
     final data = await _client
         .from('transactions')
         .select()
         .inFilter('holding_id', holdingIds) // Or .filter('holding_id', 'in', holdingIds) 
         // supabase-flutter v2 uses .inFilter, let's keep it or fallback to .in_
         .order('date', ascending: true);
         
     return data.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<TransactionModel> addTransaction(TransactionModel tx) async {
    if (userId == null) throw Exception("Kullanıcı girişi yapılmamış");
    final Map<String, dynamic> dataToInsert = tx.toMap();
    dataToInsert.remove('id'); // DB auto-generates
    dataToInsert['user_id'] = userId;
    
    final data = await _client.from('transactions').insert(dataToInsert).select().single();
    return TransactionModel.fromMap(data);
  }

  // -- Favorites --
  Future<List<Map<String, dynamic>>> getFavorites() async {
    if (userId == null) return [];
    final data = await _client
        .from('favorites')
        .select()
        .eq('user_id', userId!);
    return data;
  }

  Future<void> addFavorite(String symbol, String type) async {
    if (userId == null) return;
    await _client.from('favorites').upsert({
      'user_id': userId,
      'symbol': symbol,
      'type': type,
    });
  }

  Future<void> removeFavorite(String symbol) async {
    if (userId == null) return;
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId!)
        .eq('symbol', symbol);
  }

  // -- Data Wipe --
  Future<void> wipeAllUserData() async {
    if (userId == null) return;
    try {
      // ON DELETE CASCADE will handle holdings and transactions
      await _client.from('portfolios').delete().eq('user_id', userId!);
      await _client.from('favorites').delete().eq('user_id', userId!);
      await _client.from('alerts').delete().eq('user_id', userId!);
    } catch (e) {
      debugPrint("Wipe User Data Error: $e");
    }
  }
}
