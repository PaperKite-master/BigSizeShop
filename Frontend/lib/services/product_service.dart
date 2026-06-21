import '../core/network/api_client.dart';
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
  const ProductService(this._client, this._localProductRepository);

  final ApiClient _client;
  final LocalProductRepository _localProductRepository;

  Future<ProductListResult> list(ProductQuery query) async {
    try {
      final result = await _fetchProducts('/products', query);
      // Cache products if it is the first page of default list (no search, no category filter)
      if (query.page == 1 &&
          (query.search == null || query.search!.isEmpty) &&
          (query.category == null || query.category!.isEmpty)) {
        await _localProductRepository.saveProductsToCache(result.items);
      }
      return result;
    } catch (e) {
      final fallbackResult = await _getOfflineProducts(query);
      if (fallbackResult != null) {
        return fallbackResult;
      }
      rethrow;
    }
  }

  Future<ProductListResult> search(ProductQuery query) async {
    try {
      return await _fetchProducts('/products/search', query);
    } catch (e) {
      final fallbackResult = await _getOfflineProducts(query);
      if (fallbackResult != null) {
        return fallbackResult;
      }
      rethrow;
    }
  }

  Future<ProductListResult> filter(ProductQuery query) async {
    try {
      return await _fetchProducts('/products/filter', query);
    } catch (e) {
      final fallbackResult = await _getOfflineProducts(query);
      if (fallbackResult != null) {
        return fallbackResult;
      }
      rethrow;
    }
  }

  Future<ProductModel> getById(String id) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/products/$id');
      return ProductModel.fromJson(response.data!['data'] as Map<String, dynamic>);
    } catch (e) {
      final cachedItems = await _localProductRepository.getCachedProducts();
      final localProduct = cachedItems.firstWhere(
        (p) => p.id == id,
        orElse: () => throw e,
      );
      return localProduct;
    }
  }

  Future<ProductModel> create(Map<String, dynamic> payload) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/products',
      data: payload,
    );

    return ProductModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<ProductModel> update(String id, Map<String, dynamic> payload) async {
    final response = await _client.put<Map<String, dynamic>>(
      '/products/$id',
      data: payload,
    );

    return ProductModel.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete<Map<String, dynamic>>('/products/$id');
  }

  Future<ProductListResult> _fetchProducts(
    String path,
    ProductQuery query,
  ) async {
    final response = await _client.get<Map<String, dynamic>>(
      path,
      queryParameters: query.toQueryParameters(),
    );

    final data = response.data!['data'] as List<dynamic>;
    final meta = PaginationMeta.fromJson(
      response.data!['meta'] as Map<String, dynamic>,
    );

    return ProductListResult(
      items: data
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: meta,
    );
  }

  Future<ProductListResult?> _getOfflineProducts(ProductQuery query) async {
    final cachedItems = await _localProductRepository.getCachedProducts();
    if (cachedItems.isEmpty) {
      return null;
    }

    List<ProductModel> filtered = cachedItems;

    // Search filter
    if (query.search != null && query.search!.isNotEmpty) {
      final term = query.search!.toLowerCase();
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(term) ||
              (p.description?.toLowerCase().contains(term) ?? false))
          .toList();
    }

    // Category filter
    if (query.category != null && query.category!.isNotEmpty) {
      filtered = filtered
          .where((p) => p.categoryId == query.category || p.category?.name == query.category)
          .toList();
    }

    // Price filters
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
