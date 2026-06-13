import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/catalog_providers.dart';
import '../../../services/product_service.dart';
import '../../products/widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _applyFilters({int page = 1}) {
    ref.read(productQueryProvider.notifier).state = ProductQuery(
      page: page,
      limit: 12,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      category: _selectedCategory,
      minPrice: double.tryParse(_minPriceController.text.trim()),
      maxPrice: double.tryParse(_maxPriceController.text.trim()),
    );
    ref.invalidate(productsProvider);
  }

  void _clearFilters() {
    _searchController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() => _selectedCategory = null);
    ref.read(productQueryProvider.notifier).state = const ProductQuery(
      page: 1,
      limit: 12,
    );
    ref.invalidate(productsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final query = ref.watch(productQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BigSize Shop'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(productsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Big size fashion, delivered.',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    authState.when(
                      loading: () => const Text('Checking session...'),
                      error: (_, __) => Row(
                        children: [
                          const Text('Browse as guest'),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                      data: (user) => Text(
                        user == null
                            ? 'Browse as guest or login to manage your account.'
                            : 'Hello, ${user.fullName} (${user.role})',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => _applyFilters(),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ),
                      onSubmitted: (_) => _applyFilters(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min price',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max price',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    categoriesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (categories) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (_) {
                                setState(() => _selectedCategory = null);
                                _applyFilters();
                              },
                            ),
                            ...categories.map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: FilterChip(
                                  label: Text(category.name),
                                  selected: _selectedCategory == category.name,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedCategory = category.name;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => _applyFilters(),
                          child: const Text('Apply filters'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _clearFilters,
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            productsAsync.when(
              loading: () => const SliverFillRemaining(
                child: LoadingView(),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(productsProvider),
                ),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyView(message: 'No products found'),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width > 900
                          ? 4
                          : MediaQuery.sizeOf(context).width > 600
                              ? 3
                              : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = result.items[index];
                        return ProductCard(
                          product: product,
                          onTap: () => context.go('/products/${product.id}'),
                        );
                      },
                      childCount: result.items.length,
                    ),
                  ),
                );
              },
            ),
            productsAsync.maybeWhen(
              data: (result) {
                if (result.meta.totalPages <= 1) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: query.page > 1
                              ? () => _applyFilters(page: query.page - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Text('Page ${result.meta.page} / ${result.meta.totalPages}'),
                        IconButton(
                          onPressed: query.page < result.meta.totalPages
                              ? () => _applyFilters(page: query.page + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}
