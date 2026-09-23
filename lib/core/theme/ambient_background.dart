import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ambient gradient mesh background providing vibrant colors for LiquidGlass refraction.
class AmbientBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const AmbientBackground({
    super.key,
    required this.child,
    this.isDark = true,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: [
            // Base background
            Container(
              color: widget.isDark
                  ? const Color(0xFF090D16)
                  : const Color(0xFFF1F5F9),
            ),

            // Animated orb 1 (Indigo / Blue)
            Positioned(
              top: -60 + math.sin(t) * 40,
              left: -40 + math.cos(t) * 35,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: widget.isDark
                        ? [
                            const Color(0x664F46E5), // Indigo 600
                            const Color(0x004F46E5),
                          ]
                        : [
                            const Color(0x446366F1),
                            const Color(0x006366F1),
                          ],
                  ),
                ),
              ),
            ),

            // Animated orb 2 (Purple / Fuchsia)
            Positioned(
              bottom: 120 + math.cos(t * 0.8) * 45,
              right: -50 + math.sin(t * 0.8) * 40,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: widget.isDark
                        ? [
                            const Color(0x559333EA), // Purple 600
                            const Color(0x009333EA),
                          ]
                        : [
                            const Color(0x35A855F7),
                            const Color(0x00A855F7),
                          ],
                  ),
                ),
              ),
            ),

            // Animated orb 3 (Cyan / Sky)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.45 + math.sin(t * 1.2) * 50,
              left: MediaQuery.of(context).size.width * 0.2 + math.cos(t * 1.2) * 40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: widget.isDark
                        ? [
                            const Color(0x4406B6D4), // Cyan 500
                            const Color(0x0006B6D4),
                          ]
                        : [
                            const Color(0x280284C7),
                            const Color(0x000284C7),
                          ],
                  ),
                ),
              ),
            ),

            // Child content placed directly on top of ambient canvas
            widget.child,
          ],
        );
      },
    );
  }
}
