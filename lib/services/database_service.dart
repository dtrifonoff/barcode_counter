import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/barcode_item.dart';
import '../models/scanning_session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'barcode_inventory.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    // Create items table
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        barcode TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Create index for faster session queries
    await db.execute('''
      CREATE INDEX idx_items_session_id ON items(session_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add notes column to sessions table
      await db.execute('''
        ALTER TABLE sessions ADD COLUMN notes TEXT NOT NULL DEFAULT ''
      ''');
    }
  }

  // ===== SESSION OPERATIONS =====

  Future<int> createSession(ScanningSession session) async {
    final db = await database;
    return await db.insert('sessions', session.toMap());
  }

  Future<ScanningSession?> getSession(int id) async {
    final db = await database;
    final sessionMaps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (sessionMaps.isEmpty) return null;

    final session = ScanningSession.fromMap(sessionMaps.first);
    final items = await getItemsBySession(id);

    return session.copyWith(items: items);
  }

  Future<List<ScanningSession>> getAllSessions() async {
    final db = await database;
    final sessionMaps = await db.query(
      'sessions',
      orderBy: 'created_at DESC',
    );

    List<ScanningSession> sessions = [];
    for (var map in sessionMaps) {
      final session = ScanningSession.fromMap(map);
      final items = await getItemsBySession(session.id!);
      sessions.add(session.copyWith(items: items));
    }

    return sessions;
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    // Items will be deleted automatically due to CASCADE
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSession(ScanningSession session) async {
    final db = await database;
    return await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // ===== ITEM OPERATIONS =====

  Future<int> addItem(BarcodeItem item) async {
    final db = await database;
    return await db.insert('items', item.toMap());
  }

  Future<List<BarcodeItem>> getItemsBySession(int sessionId) async {
    final db = await database;
    final itemMaps = await db.query(
      'items',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return itemMaps.map((map) => BarcodeItem.fromMap(map)).toList();
  }

  Future<int> updateItemQuantity(int itemId, int newQuantity) async {
    final db = await database;
    return await db.update(
      'items',
      {'quantity': newQuantity},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> deleteItem(int itemId) async {
    final db = await database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ===== UTILITY OPERATIONS =====

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('items');
    await db.delete('sessions');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
