import '../core/storage/sqlite_service.dart';
import '../models/category_model.dart';

class CategoryService {
  const CategoryService(this._sqliteService);

  final SqliteService _sqliteService;

  Future<List<CategoryModel>> list() async {
    try {
      final db = await _sqliteService.database;
      final List<Map<String, dynamic>> maps = await db.query('categories');
      return maps.map((map) {
        return CategoryModel(
          id: map['id'] as String,
          name: map['name'] as String,
          createdAt: map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'] as String)
              : null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<CategoryModel> create(String name) async {
    final db = await _sqliteService.database;
    final newCategory = {
      'id': 'cat-${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await db.insert('categories', newCategory);
    return CategoryModel(
      id: newCategory['id']!,
      name: newCategory['name']!,
      createdAt: DateTime.parse(newCategory['createdAt']!),
    );
  }

  Future<CategoryModel> update(String id, String name) async {
    final db = await _sqliteService.database;
    await db.update(
      'categories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
    return CategoryModel(
      id: id,
      name: name,
      createdAt: DateTime.now(),
    );
  }

  Future<void> delete(String id) async {
    final db = await _sqliteService.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
