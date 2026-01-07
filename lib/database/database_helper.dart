import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('asset_mind.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Table A: portfolios
    await db.execute('''
    CREATE TABLE portfolios (
      id $idType,
      name $textType,
      is_default $integerType,
      creation_date $textType
    )
    ''');

    // Table B: holdings
    await db.execute('''
    CREATE TABLE holdings (
      id $idType,
      portfolio_id $integerType,
      symbol $textType,
      type $textType,
      quantity $realType,
      average_cost $realType,
      total_realized_profit $realType,
      last_update $textType,
      FOREIGN KEY (portfolio_id) REFERENCES portfolios (id) ON DELETE CASCADE
    )
    ''');

    // Table C: transactions
    await db.execute('''
    CREATE TABLE transactions (
      id $idType,
      holding_id $integerType,
      type $textType,
      amount $realType,
      price $realType,
      date $textType,
      FOREIGN KEY (holding_id) REFERENCES holdings (id) ON DELETE CASCADE
    )
    ''');

    // Table D: favorites
    await db.execute('''
    CREATE TABLE favorites (
      symbol $textType PRIMARY KEY,
      type $textType
    )
    ''');

    // Insert Default Portfolio
    await db.insert('portfolios', {
      'name': 'Ana Portföy',
      'is_default': 1,
      'creation_date': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
