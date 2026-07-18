import 'package:flutter/material.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../models/product_model.dart';

class ManageProductListItem extends StatelessWidget {
  const ManageProductListItem({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.vgMidnight,
    required this.vgCyanSky,
  });

  final ProductModel product;
  final ValueChanged<ProductModel> onEdit;
  final ValueChanged<ProductModel> onDelete;
  final Color vgMidnight;
  final Color vgCyanSky;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.displayImage;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withOpacity(0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          title: Text(
            product.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: vgMidnight,
              fontSize: 14,
              fontFamily: 'serif',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                formatCurrency(product.price),
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Stock: ${product.stock} • Category: ${product.category?.name ?? 'None'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: vgCyanSky, size: 22),
                onPressed: () => onEdit(product),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                onPressed: () => onDelete(product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20),
    );
  }
}
