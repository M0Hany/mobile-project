import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // RX Dart subjects for reactive database updates
  final BehaviorSubject<List<Map<String, dynamic>>> _storesSubject =
      BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final BehaviorSubject<List<Map<String, dynamic>>> _favoritesSubject =
      BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'fci_stores.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stores (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        category TEXT,
        rating REAL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        store_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (store_id) REFERENCES stores (id)
      )
    ''');
  }

  // RX Dart: Expose streams for stores and favorites
  Stream<List<Map<String, dynamic>>> get storesStream => _storesSubject.stream;
  Stream<List<Map<String, dynamic>>> get favoritesStream =>
      _favoritesSubject.stream;

  // Fetch all stores and add to stream
  Future<void> fetchStores() async {
    final db = await database;
    final List<Map<String, dynamic>> stores = await db.query('stores');
    _storesSubject.add(stores);
  }

  // Fetch all favorites for a user and add to stream
  Future<void> fetchFavorites(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> favorites = await db.rawQuery(
      '''
      SELECT s.* FROM stores s
      INNER JOIN favorites f ON s.id = f.store_id
      WHERE f.user_id = ?
    ''',
      [userId],
    );
    _favoritesSubject.add(favorites);
  }

  // Add to favorites and update stream
  Future<void> addToFavorites(int userId, int storeId) async {
    final db = await database;
    await db.insert('favorites', {'user_id': userId, 'store_id': storeId});
    await fetchFavorites(userId);
  }

  // Remove from favorites and update stream
  Future<void> removeFromFavorites(int userId, int storeId) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'user_id = ? AND store_id = ?',
      whereArgs: [userId, storeId],
    );
    await fetchFavorites(userId);
  }

  void dispose() {
    _storesSubject.close();
    _favoritesSubject.close();
  }
}
