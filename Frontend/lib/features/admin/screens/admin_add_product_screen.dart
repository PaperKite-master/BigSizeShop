import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../models/category_model.dart';
import '../../../models/product_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/catalog_providers.dart';
import '../../../services/product_service.dart';
import '../widgets/manage_product_list_item.dart';

class AdminAddProductScreen extends ConsumerStatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  ConsumerState<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends ConsumerState<AdminAddProductScreen>
    with SingleTickerProviderStateMixin {
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);
  final Color vgCypressGreen = const Color(0xFF233B2B);

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Base product controllers (Tab 1)
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Category selection variables (Tab 1)
  String? _selectedCategoryId;
  bool _createNewCategory = false;
  final _newCategoryController = TextEditingController();

  // Sub-images and variants (Tab 1)
  final List<Map<String, dynamic>> _images = [];
  final List<Map<String, dynamic>> _variants = [];

  bool _isSubmitting = false;
  ProductModel? _editingProduct; // Keeps track of product being updated

  // Local state for product list tab (Tab 2)
  Future<ProductListResult>? _adminProductsFuture;
  final _adminSearchController = TextEditingController();
  String? _adminSelectedCategory;
  int _adminPage = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adminProductsFuture = _fetchAdminProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _newCategoryController.dispose();
    _adminSearchController.dispose();
    super.dispose();
  }

  // --- LOCAL DATA FETCH FOR TAB 2 ---
  Future<ProductListResult> _fetchAdminProducts() async {
    final service = ref.read(productServiceProvider);
    final query = ProductQuery(
      page: _adminPage,
      limit: 8,
      search: _adminSearchController.text.trim().isEmpty ? null : _adminSearchController.text.trim(),
      category: _adminSelectedCategory,
    );
    if (query.search != null) {
      return service.search(query);
    }
    if (query.category != null) {
      return service.filter(query);
    }
    return service.list(query);
  }

  void _refreshAdminProducts() {
    setState(() {
      _adminProductsFuture = _fetchAdminProducts();
    });
  }

  // --- TAB 1 EDIT LOGIC ---
  void _startEditing(ProductModel product) {
    setState(() {
      _editingProduct = product;
      _nameController.text = product.name;
      _descController.text = product.description ?? '';
      _priceController.text = product.price.toString();
      _stockController.text = product.stock.toString();
      _imageUrlController.text = product.imageUrl ?? '';
      _selectedCategoryId = product.categoryId;
      _createNewCategory = false;

      // Clear and populate images
      for (var img in _images) {
        img['urlController'].dispose();
      }
      _images.clear();
      for (var img in product.images) {
        _images.add({
          'urlController': TextEditingController(text: img.imageUrl),
          'isThumbnail': img.isThumbnail,
        });
      }

      // Clear and populate variants
      for (var v in _variants) {
        v['nameController'].dispose();
        v['skuController'].dispose();
        v['priceController'].dispose();
        v['stockController'].dispose();
        v['imageUrlController'].dispose();
      }
      _variants.clear();
      for (var v in product.variants) {
        _variants.add({
          'nameController': TextEditingController(text: v.variantName),
          'skuController': TextEditingController(text: v.sku ?? ''),
          'priceController': TextEditingController(text: v.price?.toString() ?? ''),
          'stockController': TextEditingController(text: v.stock.toString()),
          'imageUrlController': TextEditingController(text: v.imageUrl ?? ''),
        });
      }
    });

    _tabController.animateTo(0); // Switch back to Add/Edit tab
  }

  void _cancelEditing() {
    setState(() {
      _editingProduct = null;
      _nameController.clear();
      _descController.clear();
      _priceController.clear();
      _stockController.clear();
      _imageUrlController.clear();
      _selectedCategoryId = null;
      _createNewCategory = false;
      _newCategoryController.clear();

      for (var img in _images) {
        img['urlController'].dispose();
      }
      _images.clear();

      for (var v in _variants) {
        v['nameController'].dispose();
        v['skuController'].dispose();
        v['priceController'].dispose();
        v['stockController'].dispose();
        v['imageUrlController'].dispose();
      }
      _variants.clear();
    });
  }

  void _addImageField() {
    setState(() {
      _images.add({
        'urlController': TextEditingController(),
        'isThumbnail': false,
      });
    });
  }

  void _removeImageField(int index) {
    setState(() {
      _images[index]['urlController'].dispose();
      _images.removeAt(index);
    });
  }

  void _addVariantField() {
    setState(() {
      _variants.add({
        'nameController': TextEditingController(),
        'skuController': TextEditingController(),
        'priceController': TextEditingController(),
        'stockController': TextEditingController(),
        'imageUrlController': TextEditingController(),
      });
    });
  }

  void _removeVariantField(int index) {
    setState(() {
      _variants[index]['nameController'].dispose();
      _variants[index]['skuController'].dispose();
      _variants[index]['priceController'].dispose();
      _variants[index]['stockController'].dispose();
      _variants[index]['imageUrlController'].dispose();
      _variants.removeAt(index);
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_createNewCategory && _selectedCategoryId == null) {
      AppSnackBar.showError(context, 'Please select a category or create a new one');
      return;
    }

    if (_createNewCategory && _newCategoryController.text.trim().isEmpty) {
      AppSnackBar.showError(context, 'Please enter a name for the new category');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? categoryId = _selectedCategoryId;

      // 1. Create category if required
      if (_createNewCategory) {
        final catService = ref.read(categoryServiceProvider);
        final newCategory = await catService.create(_newCategoryController.text.trim());
        categoryId = newCategory.id;
        ref.invalidate(categoriesProvider);
      }

      // 2. Format additional images
      final imagesPayload = _images
          .map((img) => {
                'image_url': img['urlController'].text.trim(),
                'is_thumbnail': img['isThumbnail'],
              })
          .where((img) => (img['image_url'] as String).isNotEmpty)
          .toList();

      // 3. Format product variants
      final variantsPayload = _variants
          .map((v) => {
                'variant_name': v['nameController'].text.trim(),
                'sku': v['skuController'].text.trim().isEmpty ? null : v['skuController'].text.trim(),
                'price': double.tryParse(v['priceController'].text.trim()),
                'stock': int.tryParse(v['stockController'].text.trim()) ?? 0,
                'image_url': v['imageUrlController'].text.trim().isEmpty ? null : v['imageUrlController'].text.trim(),
              })
          .where((v) => (v['variant_name'] as String).isNotEmpty)
          .toList();

      // 4. Construct payload
      final payload = {
        'categoryId': categoryId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'imageUrl': _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        'images': imagesPayload,
        'variants': variantsPayload,
      };

      // 5. Save or Update in Backend
      final productService = ref.read(productServiceProvider);
      if (_editingProduct != null) {
        await productService.update(_editingProduct!.id, payload);
        AppSnackBar.showSuccess(context, 'Product updated successfully');
      } else {
        await productService.create(payload);
        AppSnackBar.showSuccess(context, 'Product created successfully');
      }

      // Reset editing and local form states
      _cancelEditing();

      // Refresh both local catalog list and global home catalog
      ref.invalidate(productsProvider);
      _refreshAdminProducts();
    } catch (e) {
      AppSnackBar.showError(context, e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // --- SOFT DELETE LOGIC ---
  Future<void> _softDeleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFCF7),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              'Soft Delete Product',
              style: TextStyle(fontFamily: 'serif', color: vgMidnight, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? (This will mark the product as inactive).',
          style: TextStyle(color: vgMidnight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final productService = ref.read(productServiceProvider);
        // Soft delete by setting isActive (is_active) to false
        await productService.update(product.id, {'is_active': false});
        if (mounted) {
          AppSnackBar.showSuccess(context, 'Product deleted successfully');
        }
        ref.invalidate(productsProvider);
        _refreshAdminProducts();
      } catch (e) {
        if (mounted) {
          AppSnackBar.showError(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching app theme
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [vgMidnight, vgCyanSky, vgMidnight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text(
                'Product Panel',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: Color(0xFF0F1E36),
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      vgStarGold.withOpacity(0.95),
                      const Color(0xFFF1C40F).withOpacity(0.80),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: vgMidnight),
                onPressed: () => context.go('/'),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: vgMidnight,
                labelColor: vgMidnight,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'serif'),
                unselectedLabelColor: vgMidnight.withOpacity(0.55),
                tabs: const [
                  Tab(icon: Icon(Icons.add_circle_outline), text: 'Add/Edit Form'),
                  Tab(icon: Icon(Icons.inventory), text: 'Manage Catalog'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAddEditTab(),
                _buildManageTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET FOR TAB 1: ADD/EDIT FORM ---
  Widget _buildAddEditTab() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(_editingProduct == null ? '1. New Product Details' : '1. Edit Product Details'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: vgMidnight),
                  decoration: InputDecoration(
                    labelText: 'Product Name *',
                    labelStyle: TextStyle(color: vgMidnight),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  style: TextStyle(color: vgMidnight),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: vgMidnight),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: vgMidnight),
                        decoration: InputDecoration(
                          labelText: 'Price *',
                          labelStyle: TextStyle(color: vgMidnight),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final num = double.tryParse(val.trim());
                          if (num == null || num < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: vgMidnight),
                        decoration: InputDecoration(
                          labelText: 'Stock *',
                          labelStyle: TextStyle(color: vgMidnight),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          final num = int.tryParse(val.trim());
                          if (num == null || num < 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  style: TextStyle(color: vgMidnight),
                  decoration: InputDecoration(
                    labelText: 'Main Image URL',
                    labelStyle: TextStyle(color: vgMidnight),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Category Section
          _buildSectionTitle('2. Product Category'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _createNewCategory,
                      activeColor: vgCyanSky,
                      onChanged: (val) {
                        setState(() {
                          _createNewCategory = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        'Create a new category instead',
                        style: TextStyle(color: vgMidnight, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_createNewCategory)
                  TextFormField(
                    controller: _newCategoryController,
                    style: TextStyle(color: vgMidnight),
                    decoration: InputDecoration(
                      labelText: 'New Category Name *',
                      labelStyle: TextStyle(color: vgMidnight),
                    ),
                    validator: (val) {
                      if (_createNewCategory && (val == null || val.trim().isEmpty)) {
                        return 'Category name is required';
                      }
                      return null;
                    },
                  )
                else
                  categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading categories: $err', style: TextStyle(color: Colors.red.shade800)),
                    data: (categories) => DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      style: TextStyle(color: vgMidnight),
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Select Category *',
                        labelStyle: TextStyle(color: vgMidnight),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(cat.name),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Additional Images Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('3. Additional Images'),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                onPressed: _addImageField,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_images.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No additional images added.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic),
              ),
            )
          else
            ...List.generate(_images.length, (idx) => _buildImageField(idx)),
          const SizedBox(height: 20),

          // 4. Variants Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('4. Product Variants'),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
                onPressed: _addVariantField,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_variants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No product variants added.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic),
              ),
            )
          else
            ...List.generate(_variants.length, (idx) => _buildVariantField(idx)),

          const SizedBox(height: 32),

          // Action Buttons
          Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [vgCyanSky, vgMidnight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: vgCyanSky.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _editingProduct == null ? 'Save Product' : 'Update Product',
                          style: TextStyle(
                            color: vgStarGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'serif',
                          ),
                        ),
                ),
              ),
              if (_editingProduct != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: vgStarGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancel Edit',
                      style: TextStyle(
                        color: vgStarGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // --- WIDGET FOR TAB 2: MANAGE PRODUCTS ---
  Widget _buildManageTab() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      children: [
        // Search & Filter header
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black.withOpacity(0.15),
          child: Column(
            children: [
              TextField(
                controller: _adminSearchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search system products...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.arrow_forward, color: vgStarGold),
                    onPressed: () {
                      setState(() => _adminPage = 1);
                      _refreshAdminProducts();
                    },
                  ),
                ),
                onSubmitted: (_) {
                  setState(() => _adminPage = 1);
                  _refreshAdminProducts();
                },
              ),
              const SizedBox(height: 8),
              // Category filter dropdown inside manage tab
              categoriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (categories) => Row(
                  children: [
                    const Text('Category:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _adminSelectedCategory,
                            isExpanded: true,
                            dropdownColor: vgMidnight,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('All Categories'),
                              ),
                              ...categories.map((cat) {
                                return DropdownMenuItem<String>(
                                  value: cat.name,
                                  child: Text(cat.name),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _adminSelectedCategory = val;
                                _adminPage = 1;
                              });
                              _refreshAdminProducts();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Grid/List of items
        Expanded(
          child: FutureBuilder<ProductListResult>(
            future: _adminProductsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return ErrorView(
                  message: snapshot.error.toString(),
                  onRetry: _refreshAdminProducts,
                );
              }
              final result = snapshot.data;
              if (result == null || result.items.isEmpty) {
                return const EmptyView(message: 'No products found in database.');
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: result.items.length,
                      itemBuilder: (context, index) {
                        final product = result.items[index];
                        return ManageProductListItem(
                          product: product,
                          onEdit: _startEditing,
                          onDelete: _softDeleteProduct,
                          vgMidnight: vgMidnight,
                          vgCyanSky: vgCyanSky,
                        );
                      },
                    ),
                  ),
                  // Pagination controls
                  if (result.meta.totalPages > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.black.withOpacity(0.1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _adminPage > 1
                                ? () {
                                    setState(() => _adminPage--);
                                    _refreshAdminProducts();
                                  }
                                : null,
                            icon: Icon(Icons.chevron_left, color: vgStarGold),
                          ),
                          Text(
                            'Page $_adminPage / ${result.meta.totalPages}',
                            style: TextStyle(color: vgStarGold, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _adminPage < result.meta.totalPages
                                ? () {
                                    setState(() => _adminPage++);
                                    _refreshAdminProducts();
                                  }
                                : null,
                            icon: Icon(Icons.chevron_right, color: vgStarGold),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'serif',
        shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
      ),
    );
  }

  Widget _buildImageField(int index) {
    final img = _images[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: img['urlController'],
              style: TextStyle(color: vgMidnight),
              decoration: InputDecoration(
                labelText: 'Sub Image URL',
                labelStyle: TextStyle(color: vgMidnight),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              const Text('Thumb', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Checkbox(
                value: img['isThumbnail'],
                activeColor: vgCyanSky,
                onChanged: (val) {
                  setState(() {
                    img['isThumbnail'] = val ?? false;
                  });
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeImageField(index),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantField(int index) {
    final v = _variants[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Variant #${index + 1}', style: TextStyle(color: vgMidnight, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _removeVariantField(index),
              ),
            ],
          ),
          TextFormField(
            controller: v['nameController'],
            style: TextStyle(color: vgMidnight),
            decoration: InputDecoration(
              labelText: 'Variant Name * (e.g. Size L)',
              labelStyle: TextStyle(color: vgMidnight),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: v['skuController'],
                  style: TextStyle(color: vgMidnight),
                  decoration: InputDecoration(
                    labelText: 'SKU',
                    labelStyle: TextStyle(color: vgMidnight),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: v['priceController'],
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: vgMidnight),
                  decoration: InputDecoration(
                    labelText: 'Price override',
                    labelStyle: TextStyle(color: vgMidnight),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final price = double.tryParse(val.trim());
                      if (price == null || price < 0) return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: v['stockController'],
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: vgMidnight),
                  decoration: InputDecoration(
                    labelText: 'Stock',
                    labelStyle: TextStyle(color: vgMidnight),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final stock = int.tryParse(val.trim());
                      if (stock == null || stock < 0) return 'Invalid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: v['imageUrlController'],
            style: TextStyle(color: vgMidnight),
            decoration: InputDecoration(
              labelText: 'Variant Image URL',
              labelStyle: TextStyle(color: vgMidnight),
            ),
          ),
        ],
      ),
    );
  }
}
