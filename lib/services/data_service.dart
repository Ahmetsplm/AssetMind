import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/database_helper.dart';

class DataService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Export Data to JSON File and Share it
  Future<void> exportData() async {
    final db = await _dbHelper.database;

    // 1. Fetch all data
    final portfolios = await db.query('portfolios');
    final holdings = await db.query('holdings');
    final transactions = await db.query('transactions');
    final favorites = await db.query('favorites');

    // 2. Create Map
    final data = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'portfolios': portfolios,
      'holdings': holdings,
      'transactions': transactions,
      'favorites': favorites,
    };

    // 3. Convert to JSON
    final jsonString = jsonEncode(data);

    // 4. Write to temporary file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/assetmind_backup.json');
    await file.writeAsString(jsonString);

    // 5. Share file
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'AssetMind Yedek Dosyası');
  }

  // Import Data from JSON File
  Future<bool> importData() async {
    try {
      // 1. Pick File
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return false;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);

      if (data['version'] != 1) {
        throw Exception('Uyumsuz yedek dosyası sürümü');
      }

      // 2. Clear and Insert Data
      final db = await _dbHelper.database;

      await db.transaction((txn) async {
        // Disable Foreign Keys temporarily if needed, or delete in reverse order
        await txn.delete('transactions');
        await txn.delete('holdings');
        await txn.delete('portfolios');
        await txn.delete('favorites');

        // Insert Portfolios
        for (var item in (data['portfolios'] as List)) {
          await txn.insert('portfolios', item);
        }

        // Insert Holdings
        for (var item in (data['holdings'] as List)) {
          await txn.insert('holdings', item);
        }

        // Insert Transactions
        for (var item in (data['transactions'] as List)) {
          await txn.insert('transactions', item);
        }

        // Insert Favorites
        for (var item in (data['favorites'] as List)) {
          await txn.insert('favorites', item);
        }
      });

      return true;
    } catch (e) {
      debugPrint('Import Error: $e');
      return false;
    }
  }

  // Clear All Data
  Future<void> clearAllData() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('holdings');
      await txn.delete('portfolios');
      await txn.delete('favorites');

      await txn.insert('portfolios', {
        'name': 'Ana Portföy',
        'is_default': 1,
        'creation_date': DateTime.now().toIso8601String(),
      });
    });
  }
}
