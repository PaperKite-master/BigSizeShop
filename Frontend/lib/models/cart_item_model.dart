import 'product_model.dart';

class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.variantId,
    required this.product,
    this.variant,
  });

  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final String? variantId;
  final ProductModel product;
  final ProductVariantModel? variant;

  double get unitPrice {
    if (variant != null && variant!.price != null) {
      return variant!.price!;
    }
    return product.price;
  }

  double get totalPrice => unitPrice * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      quantity: json['quantity'] as int,
      variantId: json['variant_id'] as String?,
      product: ProductModel.fromJson(json['products'] as Map<String, dynamic>),
      variant: json['product_variants'] != null
          ? ProductVariantModel.fromJson(json['product_variants'] as Map<String, dynamic>)
          : null,
    );
  }
}
