import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/catalog_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product detail'),
      ),
      body: productAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (product) {
          final imageUrl = product.displayImage;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 48),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(product.price),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text('Stock: ${product.stock}'),
              if (product.category != null) ...[
                const SizedBox(height: 8),
                Chip(label: Text(product.category!.name)),
              ],
              const SizedBox(height: 16),
              Text(
                product.description ?? 'No description available.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (product.variants.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Variants',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...product.variants.map(
                  (variant) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(variant.variantName),
                    subtitle: Text(
                      [
                        if (variant.price != null) formatCurrency(variant.price!),
                        'Stock: ${variant.stock}',
                        if (variant.sku != null) 'SKU: ${variant.sku}',
                      ].join(' • '),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Back to shop'),
              ),
            ],
          );
        },
      ),
    );
  }
}
