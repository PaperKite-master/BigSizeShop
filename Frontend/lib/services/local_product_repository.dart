import 'dart:convert';
import '../core/storage/sqlite_service.dart';
import '../models/product_model.dart';

class LocalProductRepository {
  const LocalProductRepository(this._sqliteService);

  final SqliteService _sqliteService;

  Future<void> saveProductsToCache(List<ProductModel> products) async {
    final db = await _sqliteService.database;
    final batch = db.batch();

    // Clear old cache before saving new
    batch.delete('products');

    for (final product in products) {
      final categoryJson = product.category != null
          ? jsonEncode({
              'id': product.category!.id,
              'name': product.category!.name,
              'createdAt': product.category!.createdAt?.toIso8601String(),
            })
          : null;

      final imagesJson = jsonEncode(
        product.images
            .map((img) => {
                  'id': img.id,
                  'image_url': img.imageUrl,
                  'is_thumbnail': img.isThumbnail,
                })
            .toList(),
      );

      final variantsJson = jsonEncode(
        product.variants
            .map((v) => {
                  'id': v.id,
                  'variant_name': v.variantName,
                  'sku': v.sku,
                  'price': v.price,
                  'stock': v.stock,
                  'image_url': v.imageUrl,
                })
            .toList(),
      );

      batch.insert(
        'products',
        {
          'id': product.id,
          'categoryId': product.categoryId,
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'stock': product.stock,
          'imageUrl': product.imageUrl,
          'isActive': product.isActive ? 1 : 0,
          'category_json': categoryJson,
          'images_json': imagesJson,
          'variants_json': variantsJson,
        },
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> getCachedProducts() async {
    final db = await _sqliteService.database;
    final List<Map<String, dynamic>> maps = await db.query('products');

    return maps.map((map) {
      final categoryJson = map['category_json'] as String?;
      final imagesJson = map['images_json'] as String?;
      final variantsJson = map['variants_json'] as String?;

      final Map<String, dynamic> productJson = {
        'id': map['id'],
        'categoryId': map['categoryId'],
        'name': map['name'],
        'description': map['description'],
        'price': map['price'],
        'stock': map['stock'],
        'imageUrl': map['imageUrl'],
        'is_active': map['isActive'] == 1,
        'categories': categoryJson != null ? jsonDecode(categoryJson) : null,
        'product_images': imagesJson != null ? jsonDecode(imagesJson) : [],
        'product_variants': variantsJson != null ? jsonDecode(variantsJson) : [],
      };

      return ProductModel.fromJson(productJson);
    }).toList();
  }

  Future<void> clearProductCache() async {
    final db = await _sqliteService.database;
    await db.delete('products');
  }
}
