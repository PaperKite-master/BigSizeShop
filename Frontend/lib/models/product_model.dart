import 'category_model.dart';

class ProductImageModel {
  const ProductImageModel({
    required this.id,
    required this.imageUrl,
    this.isThumbnail = false,
  });

  final String id;
  final String imageUrl;
  final bool isThumbnail;

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as String,
      imageUrl: json['image_url'] as String,
      isThumbnail: json['is_thumbnail'] as bool? ?? false,
    );
  }
}

class ProductVariantModel {
  const ProductVariantModel({
    required this.id,
    required this.variantName,
    this.sku,
    this.price,
    this.stock = 0,
    this.imageUrl,
  });

  final String id;
  final String variantName;
  final String? sku;
  final double? price;
  final int stock;
  final String? imageUrl;

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String,
      variantName: json['variant_name'] as String,
      sku: json['sku'] as String?,
      price: _parseDouble(json['price']),
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.categoryId,
    this.description,
    this.stock = 0,
    this.imageUrl,
    this.isActive = true,
    this.category,
    this.images = const [],
    this.variants = const [],
  });

  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final bool isActive;
  final CategoryModel? category;
  final List<ProductImageModel> images;
  final List<ProductVariantModel> variants;

  String get displayImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }

    final thumbnail = images.where((image) => image.isThumbnail).toList();
    if (thumbnail.isNotEmpty) {
      return thumbnail.first.imageUrl;
    }

    if (images.isNotEmpty) {
      return images.first.imageUrl;
    }

    return '';
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['categories'];
    final imagesJson = json['product_images'] as List<dynamic>? ?? [];
    final variantsJson = json['product_variants'] as List<dynamic>? ?? [];

    return ProductModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: _parseDouble(json['price']) ?? 0,
      stock: json['stock'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      category: categoryJson is Map<String, dynamic>
          ? CategoryModel.fromJson(categoryJson)
          : null,
      images: imagesJson
          .map((item) => ProductImageModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      variants: variantsJson
          .map((item) => ProductVariantModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (categoryId != null) 'categoryId': categoryId,
      'name': name,
      if (description != null) 'description': description,
      'price': price,
      'stock': stock,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'is_active': isActive,
    };
  }
}

double? _parseDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

class PaginationMeta {
  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class ProductListResult {
  const ProductListResult({
    required this.items,
    required this.meta,
  });

  final List<ProductModel> items;
  final PaginationMeta meta;
}
