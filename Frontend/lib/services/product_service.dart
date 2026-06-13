import '../core/network/api_client.dart';
import '../models/product_model.dart';

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
  const ProductService(this._client);

  final ApiClient _client;

  Future<ProductListResult> list(ProductQuery query) async {
    return _fetchProducts('/products', query);
  }

  Future<ProductListResult> search(ProductQuery query) async {
    return _fetchProducts('/products/search', query);
  }

  Future<ProductListResult> filter(ProductQuery query) async {
    return _fetchProducts('/products/filter', query);
  }

  Future<ProductModel> getById(String id) async {
    final response = await _client.get<Map<String, dynamic>>('/products/$id');
    return ProductModel.fromJson(response.data!['data'] as Map<String, dynamic>);
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
}
