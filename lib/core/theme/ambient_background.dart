import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/hive_boxes.dart';
import '../../providers/settings_provider.dart';

/// Ambient gradient mesh background providing vibrant colors for LiquidGlass refraction.
/// Optimized with a dedicated CustomPainter and RepaintBoundary for maximum frame performance.
class AmbientBackground extends ConsumerStatefulWidget {
  final Widget child;
  final bool isDark;

  const AmbientBackground({super.key, required this.child, this.isDark = true});

  @override
  ConsumerState<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends ConsumerState<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // Gentle 30-second smooth loop (only active if not in performance mode)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    if (!HiveBoxes.getPerformanceMode()) {
      _controller.repeat();
    }

    // Lifecycle optimization: pause animation ticker when app is backgrounded or hidden
    _lifecycleListener = AppLifecycleListener(
      onPause: () => _controller.stop(),
      onHide: () => _controller.stop(),
      onResume: () {
        if (mounted &&
            !HiveBoxes.getPerformanceMode() &&
            !_controller.isAnimating) {
          _controller.repeat();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPerfMode = ref.watch(performanceModeProvider);
    if (isPerfMode && _controller.isAnimating) {
      _controller.stop();
    } else if (!isPerfMode && !_controller.isAnimating) {
      _controller.repeat();
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: isPerfMode
                ? CustomPaint(
                    painter: AmbientMeshPainter(
                      animationProgress: 0.0,
                      isDark: widget.isDark,
                    ),
                    isComplex: true,
                    willChange: false,
                  )
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: AmbientMeshPainter(
                          animationProgress: _controller.value,
                          isDark: widget.isDark,
                        ),
                        isComplex: true,
                        willChange: true,
                      );
                    },
                  ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Lightweight canvas painter that renders soft ambient orbs directly to GPU.
/// Uses recycled Paint instances to eliminate per-frame heap allocations.
class AmbientMeshPainter extends CustomPainter {
  final double animationProgress;
  final bool isDark;

  // Cached Paint objects to avoid garbage collection churn
  static final Paint _basePaint = Paint();
  static final Paint _paint1 = Paint();
  static final Paint _paint2 = Paint();
  static final Paint _paint3 = Paint();

  AmbientMeshPainter({required this.animationProgress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Base solid background
    _basePaint.color = isDark
        ? const Color(0xFF090D16)
        : const Color(0xFFF1F5F9);
    canvas.drawRect(Offset.zero & size, _basePaint);

    final t = animationProgress * 2 * math.pi;

    // 2. Animated orb 1 (Indigo / Blue)
    final c1 = Offset(
      size.width * 0.15 + math.cos(t) * 35,
      size.height * 0.12 + math.sin(t) * 40,
    );
    const r1 = 160.0;
    _paint1.shader = ui.Gradient.radial(
      c1,
      r1,
      isDark
          ? const [Color(0x664F46E5), Color(0x004F46E5)]
          : const [Color(0x446366F1), Color(0x006366F1)],
    );
    canvas.drawCircle(c1, r1, _paint1);

    // 3. Animated orb 2 (Purple / Fuchsia)
    final c2 = Offset(
      size.width * 0.85 + math.sin(t * 0.8) * 40,
      size.height * 0.78 + math.cos(t * 0.8) * 45,
    );
    const r2 = 180.0;
    _paint2.shader = ui.Gradient.radial(
      c2,
      r2,
      isDark
          ? const [Color(0x559333EA), Color(0x009333EA)]
          : const [Color(0x35A855F7), Color(0x00A855F7)],
    );
    canvas.drawCircle(c2, r2, _paint2);

    // 4. Animated orb 3 (Cyan / Sky)
    final c3 = Offset(
      size.width * 0.45 + math.cos(t * 1.2) * 40,
      size.height * 0.45 + math.sin(t * 1.2) * 50,
    );
    const r3 = 140.0;
    _paint3.shader = ui.Gradient.radial(
      c3,
      r3,
      isDark
          ? const [Color(0x4406B6D4), Color(0x0006B6D4)]
          : const [Color(0x280284C7), Color(0x000284C7)],
    );
    canvas.drawCircle(c3, r3, _paint3);
  }

  @override
  bool shouldRepaint(covariant AmbientMeshPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.isDark != isDark;
  }
}
