import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'sqlite_mock_data.dart';

class SqliteService {
  SqliteService();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String pathStr;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      final docDir = await getApplicationSupportDirectory();
      pathStr = join(docDir.path, 'big_size_shop.db');
    } else {
      final dbPath = await getDatabasesPath();
      pathStr = join(dbPath, 'big_size_shop.db');
    }

    debugPrint('=== ĐƯỜNG DẪN CƠ SỞ DỮ LIỆU SQLITE (DATABASE PATH) ===');
    debugPrint(pathStr);
    debugPrint('=====================================================');

    final db = await openDatabase(
      pathStr,
      version: 1,
      onCreate: _onCreate,
    );

    // Populate mock data if database is empty
    await _checkAndPopulateMockData(db);

    return db;
  }

  Future<void> _checkAndPopulateMockData(Database db) async {
    try {
      // Đảm bảo các bảng bổ sung tồn tại
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          createdAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          fullName TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          phone TEXT,
          avatar TEXT,
          role TEXT NOT NULL DEFAULT 'USER',
          createdAt TEXT
        )
      ''');

      // Nạp dữ liệu danh mục mẫu
      final List<Map<String, dynamic>> catCountResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM categories');
      final int catCount = catCountResult.first['count'] as int? ?? 0;

      if (catCount == 0) {
        final batch = db.batch();
        for (final category in SqliteMockData.mockCategories) {
          batch.insert('categories', category);
        }
        await batch.commit(noResult: true);
        debugPrint('SQLite: Category mock data populated successfully.');
      }

      // Nạp dữ liệu sản phẩm mẫu
      final List<Map<String, dynamic>> countResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final int count = countResult.first['count'] as int? ?? 0;

      if (count == 0) {
        final batch = db.batch();
        for (final product in SqliteMockData.mockProducts) {
          batch.insert('products', product);
        }
        await batch.commit(noResult: true);
        debugPrint('SQLite: Product mock data populated successfully.');
      }

      // Nạp dữ liệu người dùng mẫu
      final List<Map<String, dynamic>> userCountResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM users');
      final int userCount = userCountResult.first['count'] as int? ?? 0;

      if (userCount == 0) {
        final batch = db.batch();
        for (final user in SqliteMockData.mockUsers) {
          batch.insert('users', user);
        }
        await batch.commit(noResult: true);
        debugPrint('SQLite: User mock data populated successfully.');
      }
    } catch (e) {
      debugPrint('SQLite Error populating mock data: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tạo bảng categories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        createdAt TEXT
      )
    ''');

    // Tạo bảng users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT,
        avatar TEXT,
        role TEXT NOT NULL DEFAULT 'USER',
        createdAt TEXT
      )
    ''');

    // Create products cache table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        categoryId TEXT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        imageUrl TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        category_json TEXT,
        images_json TEXT,
        variants_json TEXT
      )
    ''');

    // Create cart table for offline cart items
    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        variantId TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites (
        productId TEXT PRIMARY KEY,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
