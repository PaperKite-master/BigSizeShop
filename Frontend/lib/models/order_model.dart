import 'product_model.dart';

class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    this.variantId,
    required this.product,
    this.variant,
  });

  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double price;
  final String? variantId;
  final ProductModel product;
  final ProductVariantModel? variant;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      // Prisma returns camelCase for @map fields
      orderId: (json['orderId'] ?? json['order_id']) as String,
      productId: (json['productId'] ?? json['product_id']) as String,
      quantity: json['quantity'] as int,
      price: double.parse(json['price'].toString()),
      variantId: (json['variantId'] ?? json['variant_id']) as String?,
      product: ProductModel.fromJson(json['products'] as Map<String, dynamic>),
      variant: json['product_variants'] != null
          ? ProductVariantModel.fromJson(json['product_variants'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.userId,
    required this.totalPrice,
    required this.status,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
    required this.orderItems,
  });

  final String id;
  final String userId;
  final double totalPrice;
  final String status;
  final String address;
  final String paymentMethod;
  final DateTime createdAt;
  final List<OrderItemModel> orderItems;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Prisma returns camelCase for fields with @map, and original name for relations
    final itemsJson = (json['order_items'] as List<dynamic>?) ?? [];
    return OrderModel(
      id: json['id'] as String,
      // Support both camelCase (Prisma) and snake_case (raw SQL fallback)
      userId: (json['userId'] ?? json['user_id']) as String,
      totalPrice: double.parse(json['totalPrice']?.toString() ?? json['total_price'].toString()),
      status: json['status'] as String? ?? 'PENDING',
      address: json['address'] as String,
      paymentMethod: (json['paymentMethod'] ?? json['payment_method']) as String? ?? 'COD',
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
      orderItems: itemsJson
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

