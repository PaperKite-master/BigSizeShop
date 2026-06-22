import 'dart:convert';
import '../core/storage/sqlite_service.dart';
import '../models/product_model.dart';
import 'local_product_repository.dart';

class ProductQuery {
  const ProductQuery({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.category,
    this.minPrice,
    this.maxPrice,
  });

  final int page;
  final int limit;
  final String? search;
  final String? category;
  final double? minPrice;
  final double? maxPrice;

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'limit': limit,
      if (search != null && search!.isNotEmpty) 'search': search,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
    };
  }

  ProductQuery copyWith({
    int? page,
    int? limit,
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) {
    return ProductQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

class ProductService {
  const ProductService(this._sqliteService, this._localProductRepository);

  final SqliteService _sqliteService;
  final LocalProductRepository _localProductRepository;

  Future<ProductListResult> list(ProductQuery query) async {
    return _getOfflineProducts(query);
  }

  Future<ProductListResult> search(ProductQuery query) async {
    return _getOfflineProducts(query);
  }

  Future<ProductListResult> filter(ProductQuery query) async {
    return _getOfflineProducts(query);
  }

  Future<ProductModel> getById(String id) async {
    final cachedItems = await _localProductRepository.getCachedProducts();
    return cachedItems.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Product not found'),
    );
  }

  Future<ProductModel> create(Map<String, dynamic> payload) async {
    final db = await _sqliteService.database;
    final id = 'prod-${DateTime.now().millisecondsSinceEpoch}';

    final String? categoryJson = payload['category'] != null
        ? jsonEncode(payload['category'])
        : null;

    final String imagesJson = jsonEncode(payload['product_images'] ?? []);
    final String variantsJson = jsonEncode(payload['product_variants'] ?? []);

    final productRow = {
      'id': id,
      'categoryId': payload['categoryId'],
      'name': payload['name'],
      'description': payload['description'],
      'price': (payload['price'] as num).toDouble(),
      'stock': payload['stock'] ?? 0,
      'imageUrl': payload['imageUrl'],
      'isActive': (payload['is_active'] ?? true) ? 1 : 0,
      'category_json': categoryJson,
      'images_json': imagesJson,
      'variants_json': variantsJson,
    };

    await db.insert('products', productRow);

    final Map<String, dynamic> productJson = {
      ...payload,
      'id': id,
      'is_active': (payload['is_active'] ?? true),
      'categories': payload['category'],
      'product_images': payload['product_images'] ?? [],
      'product_variants': payload['product_variants'] ?? [],
    };

    return ProductModel.fromJson(productJson);
  }

  Future<ProductModel> update(String id, Map<String, dynamic> payload) async {
    final db = await _sqliteService.database;

    final productRow = {
      if (payload.containsKey('categoryId')) 'categoryId': payload['categoryId'],
      if (payload.containsKey('name')) 'name': payload['name'],
      if (payload.containsKey('description')) 'description': payload['description'],
      if (payload.containsKey('price')) 'price': (payload['price'] as num).toDouble(),
      if (payload.containsKey('stock')) 'stock': payload['stock'],
      if (payload.containsKey('imageUrl')) 'imageUrl': payload['imageUrl'],
      if (payload.containsKey('is_active')) 'isActive': (payload['is_active'] ?? true) ? 1 : 0,
      if (payload.containsKey('category')) 'category_json': jsonEncode(payload['category']),
      if (payload.containsKey('product_images')) 'images_json': jsonEncode(payload['product_images']),
      if (payload.containsKey('product_variants')) 'variants_json': jsonEncode(payload['product_variants']),
    };

    await db.update(
      'products',
      productRow,
      where: 'id = ?',
      whereArgs: [id],
    );

    final list = await _localProductRepository.getCachedProducts();
    return list.firstWhere((p) => p.id == id);
  }

  Future<void> delete(String id) async {
    final db = await _sqliteService.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ProductListResult> _getOfflineProducts(ProductQuery query) async {
    final cachedItems = await _localProductRepository.getCachedProducts();
    List<ProductModel> filtered = cachedItems;

    // Lọc theo tìm kiếm
    if (query.search != null && query.search!.isNotEmpty) {
      final term = query.search!.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(term) ||
              (p.description?.toLowerCase().contains(term) ?? false))
          .toList();
    }

    // Lọc theo danh mục
    if (query.category != null && query.category!.isNotEmpty) {
      filtered = filtered
          .where((p) => p.categoryId == query.category || p.category?.name == query.category)
          .toList();
    }

    // Lọc theo giá
    if (query.minPrice != null) {
      filtered = filtered.where((p) => p.price >= query.minPrice!).toList();
    }
    if (query.maxPrice != null) {
      filtered = filtered.where((p) => p.price <= query.maxPrice!).toList();
    }

    final total = filtered.length;
    final startIndex = (query.page - 1) * query.limit;
    final endIndex = startIndex + query.limit;
    final paginatedItems = filtered.sublist(
      startIndex.clamp(0, total),
      endIndex.clamp(0, total),
    );

    return ProductListResult(
      items: paginatedItems,
      meta: PaginationMeta(
        total: total,
        page: query.page,
        limit: query.limit,
        totalPages: (total / query.limit).ceil(),
      ),
    );
  }
}
