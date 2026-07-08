import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../models/category_model.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/catalog_providers.dart';

class AdminAddProductScreen extends ConsumerStatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  ConsumerState<AdminAddProductScreen> createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends ConsumerState<AdminAddProductScreen> {
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);
  final Color vgCypressGreen = const Color(0xFF233B2B);

  final _formKey = GlobalKey<FormState>();

  // Base product controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // Category selection variables
  String? _selectedCategoryId;
  bool _createNewCategory = false;
  final _newCategoryController = TextEditingController();

  // Sub-images and variants
  final List<Map<String, dynamic>> _images = [];
  final List<Map<String, dynamic>> _variants = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _newCategoryController.dispose();
    super.dispose();
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
        // Invalidate categories to refresh cache
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

      // 5. POST to backend
      final productService = ref.read(productServiceProvider);
      await productService.create(payload);

      // Refresh catalog list
      ref.invalidate(productsProvider);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Product created successfully');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

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
                'Add New Product',
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: vgMidnight),
                onPressed: () => context.go('/'),
              ),
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Basic Product details Section
                  _buildSectionTitle('1. Product Information'),
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
                        // Toggle for creating new category
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
                            loading: () => const LoadingView(),
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

                  // Submit button
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
                              'Save Product',
                              style: TextStyle(
                                color: vgStarGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'serif',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
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
