import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../../providers/catalog_providers.dart';

// Hàm định dạng tiền tệ nội bộ an toàn
String _localFormatCurrency(dynamic price) {
  if (price == null) return '0 đ';
  String priceStr = double.parse(price.toString()).round().toString();
  RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  String result = priceStr.replaceAllMapped(reg, (Match match) => '${match[1]}.');
  return '$result đ';
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<StarParticle> _stars;

  // 🎨 Bộ palette màu cốt lõi hội họa Van Gogh
  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);
  final Color vgCypressGreen = const Color(0xFF233B2B);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _stars = List.generate(35, (index) => StarParticle());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

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
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Lớp 1: Khung tranh nền động bầu trời đêm tinh tú (Đã giải phóng cánh đồng hướng dương bên dưới)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: VanGoghPureSkyPainter(
                    stars: _stars,
                    animationValue: _animationController.value,
                    midnight: vgMidnight,
                    cyanSky: vgCyanSky,
                    starGold: vgStarGold,
                  ),
                  child: Container(),
                );
              },
            ),

            // Lớp 2: Nội dung chi tiết sản phẩm
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                // Tiêu đề Product Detail nghệ thuật tương phản gắt trên nền vàng
                title: Text(
                  'Product Detail',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'serif',
                    letterSpacing: 1.2,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [
                          Color(0xFF0F1E36),
                          Color(0xFF1B2A4A),
                          Color(0xFF4A3200),
                        ],
                      ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 50.0)),
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFF4CC).withOpacity(0.8),
                        offset: const Offset(1, 1),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Thanh Headbar vàng kính mờ (Glassmorphism) tách biệt khối
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        vgStarGold.withOpacity(0.95),
                        const Color(0xFFF1C40F).withOpacity(0.85),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
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
              body: productAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
                ),
                data: (product) {
                  final imageUrl = product.displayImage;

                  // --- 🖼️ COMPONENT HÌNH ẢNH ---
                  Widget productImage = imageUrl.isNotEmpty
                      ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white.withOpacity(0.9),
                            child: Icon(Icons.image_not_supported_outlined, color: vgCyanSky.withOpacity(0.3), size: 64),
                          ),
                        ),
                      ),
                    ),
                  )
                      : Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: vgCyanSky.withOpacity(0.15)),
                    ),
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined, color: vgCyanSky.withOpacity(0.3), size: 64),
                    ),
                  );

                  // --- 📝 COMPONENT THÔNG TIN CHI TIẾT ---
                  Widget productInfo = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.white, vgStarGold, const Color(0xFFFFF4CC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, fontFamily: 'serif'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [vgStarGold, const Color(0xFFE6A100), Colors.white],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Text(
                          _localFormatCurrency(product.price),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'serif'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Text(
                            'Stock: ${product.stock}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'serif', fontSize: 18, shadows: [Shadow(blurRadius: 5, color: Colors.black45)]),
                          ),
                          if (product.category != null) ...[
                            const SizedBox(width: 20),
                            Chip(
                              label: Text(product.category!.name),
                              backgroundColor: Colors.white.withOpacity(0.85),
                              labelStyle: TextStyle(color: vgCyanSky, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 14),
                              side: BorderSide(color: vgCyanSky.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.white.withOpacity(0.3), thickness: 1.2),
                      const SizedBox(height: 20),

                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif', shadows: [Shadow(blurRadius: 5, color: Colors.black45)]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.description ?? 'No description available.',
                        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9), height: 1.6, letterSpacing: 0.2, shadows: const [Shadow(blurRadius: 4, color: Colors.black54)]),
                      ),
                      const SizedBox(height: 32),

                      if (product.variants.isNotEmpty) ...[
                        const Text(
                          'Available Variants',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif', shadows: [Shadow(blurRadius: 5, color: Colors.black45)]),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: product.variants.map((variant) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              width: 280,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: vgCyanSky.withOpacity(0.15)),
                                boxShadow: [
                                  BoxShadow(color: vgMidnight.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    variant.variantName,
                                    style: TextStyle(color: vgMidnight, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      if (variant.price != null) _localFormatCurrency(variant.price!),
                                      'Stock: ${variant.stock}',
                                    ].join(' • '),
                                    style: TextStyle(color: vgCypressGreen.withOpacity(0.8), fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, color: vgStarGold, size: 28),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  "Mỗi trang phục trong bộ sưu tập BigSize mang dấu ấn cảm tác nghệ thuật độc bản, phóng khoáng, tự tin tôn vinh những đường nét nguyên bản quý giá của riêng bạn.",
                                  style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 14, fontFamily: 'serif', height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],

                      // 🌟 Nút Quay lại thiết kế màu vàng rực rỡ tương phản cao
                      Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              vgStarGold, // Màu vàng tinh tú rực rỡ bên cánh trái
                              const Color(0xFFE6A100), // Vàng thư đậm đầm ấm chuyển dần sang phải
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: vgStarGold.withOpacity(0.35), // Quầng phát sáng vàng nhẹ bao quanh nút
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Center(
                            child: Text(
                              'Back to shop',
                              style: TextStyle(
                                color: vgMidnight, // ✨ ĐÃ ĐỔI: Chuyển chữ sang màu xanh đêm tối để nổi bần bật trên nền vàng
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                fontFamily: 'serif',
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 950) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1600),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 60),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 5, child: productImage),
                                  const SizedBox(width: 60),
                                  Expanded(flex: 6, child: productInfo),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          productImage,
                          const SizedBox(height: 32),
                          productInfo,
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StarParticle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double blinkOffset;
  final math.Random random = math.Random();

  StarParticle() {
    x = random.nextDouble();
    y = random.nextDouble();
    size = random.nextDouble() * 4 + 1.5;
    speed = random.nextDouble() * 0.015 + 0.005;
    blinkOffset = random.nextDouble() * math.pi;
  }

  void update() {
    x += speed * 0.05;
    if (x > 1.05) {
      x = -0.05;
      y = random.nextDouble();
    }
  }
}

// ✨ ĐÃ SỬA: Tên lớp chuẩn chỉnh chỉnh, sạch bóng hoàn toàn ký tự lạ dính phím bộ gõ
class VanGoghPureSkyPainter extends CustomPainter {
  final List<StarParticle> stars;
  final double animationValue;
  final Color midnight;
  final Color cyanSky;
  final Color starGold;

  VanGoghPureSkyPainter({
    required this.stars,
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

    for (var star in stars) {
      star.update();
      final double sx = star.x * size.width;
      final double sy = star.y * size.height;

      double opacity = (math.sin(animationValue * math.pi * 4 + star.blinkOffset) + 1.0) / 2.0;
      opacity = math.max(0.2, opacity);

      final Paint glowPaint = Paint()
        ..color = starGold.withOpacity(opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(sx, sy), star.size * 3.0, glowPaint);

      final Paint corePaint = Paint()..color = const Color(0xFFFFFCE6).withOpacity(opacity);
      canvas.drawCircle(Offset(sx, sy), star.size, corePaint);
    }

    final Paint wavePaint = Paint()
      ..color = cyanSky.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;

    final Path wavePath = Path();
    for (double i = 0; i < size.width; i += 5) {
      double y = size.height * 0.4 + math.sin((i / size.width) * math.pi * 2 + animationValue * math.pi * 2) * 50;
      if (i == 0) wavePath.moveTo(i, y); else wavePath.lineTo(i, y);
    }
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant VanGoghPureSkyPainter oldDelegate) => true;
}