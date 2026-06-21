import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'app_providers.dart';

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(categoryServiceProvider).list();
});

final productQueryProvider = StateProvider<ProductQuery>(
  (ref) => const ProductQuery(page: 1, limit: 12),
);

final productsProvider = FutureProvider<ProductListResult>((ref) async {
  final query = ref.watch(productQueryProvider);
  final service = ref.watch(productServiceProvider);

  if (query.search != null && query.search!.isNotEmpty) {
    return service.search(query);
  }

  if (query.category != null ||
      query.minPrice != null ||
      query.maxPrice != null) {
    return service.filter(query);
  }

  return service.list(query);
});

final productDetailProvider = FutureProvider.family<ProductModel, String>(
  (ref, productId) {
    return ref.watch(productServiceProvider).getById(productId);
  },
);
