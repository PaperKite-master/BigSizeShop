import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/catalog_providers.dart';
import '../../../providers/cart_providers.dart';
import '../../../services/product_service.dart';
import '../../products/widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String? _selectedCategory;

  // 🔍 Các biến cấu hình cho gợi ý tìm kiếm
  Timer? _debounceTimer;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // 🎬 Bộ điều khiển hiệu ứng nền động
  late AnimationController _animationController;
  late List<SunflowerParticle> _particles;

  // 🎨 Bộ palette màu cốt lõi của Van Gogh
  final Color vgMidnight = const Color(0xFF0F1E36);     // Xanh thẳm đêm sâu hoàng hôn
  final Color vgCyanSky = const Color(0xFF1C528B);      // Xanh coban bầu trời xoáy
  final Color vgStarGold = const Color(0xFFF3C63F);     // Vàng rực sao đêm đầy tinh tú
  final Color vgCypressGreen = const Color(0xFF233B2B);  // Xanh lá cây tùng bách ám khói

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particles = List.generate(15, (index) => SunflowerParticle());
  }

  @override
void dispose() {
  _animationController.stop(); // 🌟 THÊM LỆNH NÀY: Ép dừng hiệu ứng ngay lập tức
  _animationController.dispose(); // Hủy bộ điều khiển
  _searchController.dispose();
  _minPriceController.dispose();
  _maxPriceController.dispose();
  _debounceTimer?.cancel();
  _hideSuggestions();
  super.dispose();
}

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      _hideSuggestions();
      _applyFilters();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _applyFilters();
        _showSuggestionsOverlay();
      }
    });
  }

  void _showSuggestionsOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _layerLink.leaderSize?.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: vgCyanSky.withOpacity(0.15)),
              ),
              constraints: const BoxConstraints(maxHeight: 250),
              child: Consumer(
                builder: (context, searchRef, child) {
                  final productsAsync = searchRef.watch(productsProvider);

                  return productsAsync.maybeWhen(
                    loading: () => Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: vgStarGold))),
                    ),
                    data: (result) {
                      if (result.items.isEmpty || _searchController.text.trim().isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('No suggestions found', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: result.items.length > 5 ? 5 : result.items.length,
                        itemBuilder: (context, index) {
                          final product = result.items[index];
                          return ListTile(
                            title: Text(product.name, style: TextStyle(fontFamily: 'serif', color: vgMidnight, fontWeight: FontWeight.w600)),
                            subtitle: Text('${product.price} đ', style: TextStyle(color: vgStarGold, fontWeight: FontWeight.bold)),
                            trailing: Icon(Icons.north_west, size: 16, color: vgCyanSky.withOpacity(0.5)),
                            onTap: () {
                              _searchController.text = product.name;
                              _hideSuggestions();
                              _applyFilters();
                              context.go('/products/${product.id}');
                            },
                          );
                        },
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _applyFilters({int page = 1}) {
    ref.read(productQueryProvider.notifier).state = ProductQuery(
      page: page,
      limit: 12,
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
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
    _hideSuggestions();
    ref.read(productQueryProvider.notifier).state = const ProductQuery(page: 1, limit: 12);
    ref.invalidate(productsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    final query = ref.watch(productQueryProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          foregroundColor: vgMidnight,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          labelStyle: TextStyle(color: vgCypressGreen, fontFamily: 'serif'),
          hintStyle: TextStyle(color: vgCyanSky.withOpacity(0.4), fontStyle: FontStyle.italic),
          prefixIconColor: vgCyanSky,
          suffixIconColor: vgStarGold,
          border: OutlineInputBorder(borderSide: BorderSide(color: vgCyanSky.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: vgCyanSky.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: vgStarGold, width: 2), borderRadius: BorderRadius.circular(8)),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Lớp 1: Nền động Hoa hướng dương cuộn xoáy trên trời đêm
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: VanGoghSkyPainter(
                    particles: _particles,
                    animationValue: _animationController.value,
                    midnight: vgMidnight,
                    cyanSky: vgCyanSky,
                    starGold: vgStarGold,
                  ),
                  child: Container(),
                );
              },
            ),

            // Lớp 2: Nội dung ứng dụng chính
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                // 🌻 Dán đè hình ảnh nghệ thuật van_gogh_title.png thay cho chữ text thông thường
                title: Image.asset(
                  'assets/images/van_gogh_title.png',// Hãy chắc chắn đường dẫn này trùng với khai báo trong pubspec.yaml của bạn
                  height: 45, // Chiều cao vừa vặn hoàn hảo với thanh Headbar chuẩn
                  fit: BoxFit.contain, // Giữ nguyên tỉ lệ vàng của bức tranh không bị méo
                  errorBuilder: (context, error, stackTrace) {
                    // Trường hợp nếu chưa nạp được ảnh, hệ thống tự động hiển thị chữ dự phòng để không lỗi app
                    return const Text(
                      'BigSize Shop',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif', color: Color(0xFF0F1E36)),
                    );
                  },
                ),
                // Giữ nguyên thuộc tính flexibleSpace của thanh Headbar màu vàng trong suốt
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
                actions: [
                  IconButton(
                    onPressed: () => context.go('/profile'),
                    icon: Icon(Icons.person_outline, color: vgMidnight),
                  ),
                  CartBadgeIconButton(color: vgMidnight),
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
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Big size fashion, delivered.',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'serif',
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(color: vgMidnight, blurRadius: 10, offset: const Offset(2, 2)),
                                  Shadow(color: vgStarGold.withOpacity(0.6), blurRadius: 20),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            authState.when(
                              loading: () => const Text('Checking session...', style: TextStyle(color: Colors.white70)),
                              error: (_, __) => Row(
                                children: [
                                  const Text('Browse as guest', style: TextStyle(color: Colors.white70)),
                                  TextButton(
                                    onPressed: () => context.go('/login'),
                                    child: Text('Login', style: TextStyle(color: vgStarGold, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                              data: (user) => Text(
                                user == null
                                    ? 'Browse as guest or login to manage your account.'
                                    : 'Hello, ${user.fullName} (${user.role})',
                                style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 24),

                            CompositedTransformTarget(
                              link: _layerLink,
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                onTap: () {
                                  if (_searchController.text.trim().isNotEmpty) {
                                    _showSuggestionsOverlay();
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search products...',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: IconButton(
                                    onPressed: () => _applyFilters(),
                                    icon: Icon(Icons.arrow_forward, color: vgStarGold),
                                  ),
                                ),
                                onSubmitted: (_) => _applyFilters(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minPriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Min price'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _maxPriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'Max price'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            categoriesAsync.when(
                              loading: () => LinearProgressIndicator(color: vgStarGold, backgroundColor: vgCyanSky.withOpacity(0.1)),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (categories) => SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FilterChip(
                                      label: const Text('All'),
                                      selected: _selectedCategory == null,
                                      selectedColor: vgStarGold,
                                      checkmarkColor: vgMidnight,
                                      backgroundColor: Colors.white.withOpacity(0.8),
                                      shadowColor: vgMidnight.withOpacity(0.2),
                                      elevation: _selectedCategory == null ? 4 : 1,
                                      labelStyle: TextStyle(fontFamily: 'serif', color: _selectedCategory == null ? vgMidnight : vgCypressGreen, fontWeight: FontWeight.bold),
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
                                          selectedColor: vgStarGold,
                                          checkmarkColor: vgMidnight,
                                          backgroundColor: Colors.white.withOpacity(0.8),
                                          shadowColor: vgMidnight.withOpacity(0.2),
                                          elevation: _selectedCategory == category.name ? 4 : 1,
                                          labelStyle: TextStyle(fontFamily: 'serif', color: _selectedCategory == category.name ? vgMidnight : vgCypressGreen, fontWeight: FontWeight.bold),
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
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [vgCyanSky, vgMidnight], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [BoxShadow(color: vgCyanSky.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _applyFilters(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                    child: Text('Apply filters', style: TextStyle(color: vgStarGold, fontWeight: FontWeight.w900, fontSize: 15, fontFamily: 'serif')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: _clearFilters,
                                  child: Text('Clear', style: TextStyle(color: vgStarGold, fontWeight: FontWeight.bold, fontFamily: 'serif', shadows: [Shadow(color: vgMidnight, blurRadius: 4)])),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    productsAsync.when(
                      loading: () => const SliverFillRemaining(child: LoadingView()),
                      error: (error, _) => SliverFillRemaining(
                        child: ErrorView(message: error.toString(), onRetry: () => ref.invalidate(productsProvider)),
                      ),
                      data: (result) {
                        if (result.items.isEmpty) {
                          return const SliverFillRemaining(child: EmptyView(message: 'No products found'));
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.sizeOf(context).width > 900 ? 4 : MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final product = result.items[index];
                                return Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(color: vgMidnight.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
                                      ]
                                  ),
                                  child: ProductCard(
                                    product: product,
                                    onTap: () => context.go('/products/${product.id}'),
                                  ),
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
                        if (result.meta.totalPages <= 1) return const SliverToBoxAdapter(child: SizedBox.shrink());
                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: query.page > 1 ? () => _applyFilters(page: query.page - 1) : null,
                                  icon: Icon(Icons.chevron_left, color: vgStarGold),
                                ),
                                Text('Page ${result.meta.page} / ${result.meta.totalPages}', style: TextStyle(color: vgStarGold, fontWeight: FontWeight.bold, fontFamily: 'serif', shadows: [Shadow(color: vgMidnight, blurRadius: 4)])),
                                IconButton(
                                  onPressed: query.page < result.meta.totalPages ? () => _applyFilters(page: query.page + 1) : null,
                                  icon: Icon(Icons.chevron_right, color: vgStarGold),
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
            ),
          ],
        ),
      ),
    );
  }
}

class SunflowerParticle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double rotationSpeed;
  late double baseAngle;
  final math.Random random = math.Random();

  SunflowerParticle() {
    x = random.nextDouble();
    y = random.nextDouble();
    size = random.nextDouble() * 24 + 12;
    speed = random.nextDouble() * 0.02 + 0.01;
    rotationSpeed = random.nextDouble() * 2 + 0.5;
    baseAngle = random.nextDouble() * math.pi * 2;
  }

  void update(double value) {
    y -= speed * 0.01;
    x += math.sin(value * math.pi * 2 + baseAngle) * 0.002;

    if (y < -0.05) {
      y = 1.05;
      x = random.nextDouble();
    }
  }
}

class VanGoghSkyPainter extends CustomPainter {
  final List<SunflowerParticle> particles;
  final double animationValue;
  final Color midnight;
  final Color cyanSky;
  final Color starGold;

  VanGoghSkyPainter({
    required this.particles,
    required this.animationValue,
    required this.midnight,
    required this.cyanSky,
    required this.starGold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [midnight, cyanSky, midnight],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final Paint wavePaint = Paint()
      ..color = cyanSky.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 35
      ..strokeCap = StrokeCap.round;

    final Path wavePath = Path();
    for (double i = 0; i < size.width; i += 4) {
      double y = size.height * 0.3 + math.sin((i / size.width) * math.pi * 3 + animationValue * math.pi * 2) * 40;
      if (i == 0) wavePath.moveTo(i, y); else wavePath.lineTo(i, y);
    }
    canvas.drawPath(wavePath, wavePaint);

    for (var particle in particles) {
      particle.update(animationValue);

      final double px = particle.x * size.width;
      final double py = particle.y * size.height;
      final double pAngle = animationValue * math.pi * 2 * particle.rotationSpeed;

      final Paint glowPaint = Paint()
        ..color = starGold.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawCircle(Offset(px, py), particle.size * 1.8, glowPaint);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(pAngle);

      final Paint petalPaint = Paint()..color = starGold.withOpacity(0.85);
      final Paint centerPaint = Paint()..color = const Color(0xFF8A5A00).withOpacity(0.9);

      for (int i = 0; i < 8; i++) {
        canvas.rotate(math.pi / 4);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(particle.size * 0.6, 0), width: particle.size * 0.5, height: particle.size * 0.25),
          petalPaint,
        );
      }

      canvas.drawCircle(Offset.zero, particle.size * 0.35, centerPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant VanGoghSkyPainter oldDelegate) => true;
}

class CartBadgeIconButton extends ConsumerWidget {
  const CartBadgeIconButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartBadgeCountProvider);
    final activeColor = color ?? const Color(0xFF0F1E36);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.shopping_cart_outlined, color: activeColor),
          onPressed: () => context.go('/cart'),
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}