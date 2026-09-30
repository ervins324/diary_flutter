import 'package:flutter/material.dart';
import '../../../core/theme/liquid_theme.dart';

/// Descriptor for a single segment in a [LiquidSlidingSwitcher].
class LiquidSegment<T> {
  final T value;
  final String label;
  final IconData? icon;
  final double? iconSize;
  final double? fontSize;
  final Widget? customChild;

  const LiquidSegment({
    required this.value,
    required this.label,
    this.icon,
    this.iconSize,
    this.fontSize,
    this.customChild,
  });
}

/// A liquid glass segmented switcher that features a smooth, physically translating
/// glowing liquid capsule instead of discrete fading button highlights.
class LiquidSlidingSwitcher<T> extends StatelessWidget {
  final List<LiquidSegment<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onSelectionChanged;
  final bool isDark;
  final bool isPerfMode;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry itemMargin;
  final Duration animationDuration;
  final Curve animationCurve;

  const LiquidSlidingSwitcher({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onSelectionChanged,
    required this.isDark,
    this.isPerfMode = false,
    this.height = 38.0,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.all(3.0),
    this.itemMargin = const EdgeInsets.symmetric(horizontal: 2.0),
    this.animationDuration = const Duration(milliseconds: 280),
    this.animationCurve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = segments.indexWhere((s) => s.value == selectedValue);
    final validIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: isPerfMode
            ? (isDark ? const Color(0x381E293B) : const Color(0xB3FFFFFF))
            : (isDark ? const Color(0x221E293B) : const Color(0x80FFFFFF)),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalCount = segments.length;
          if (totalCount == 0) return const SizedBox.shrink();

          final itemWidth = constraints.maxWidth / totalCount;

          return Stack(
            children: [
              // Smooth translating liquid glass indicator capsule
              AnimatedPositioned(
                duration: animationDuration,
                curve: animationCurve,
                left: validIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  margin: itemMargin,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              LiquidTheme.accent.withValues(alpha: 0.45),
                              Colors.purpleAccent.withValues(alpha: 0.3),
                            ]
                          : [
                              LiquidTheme.accent.withValues(alpha: 0.28),
                              Colors.purpleAccent.withValues(alpha: 0.18),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(
                      (borderRadius - 2).clamp(4.0, 999.0),
                    ),
                    border: Border.all(
                      color: isDark
                          ? LiquidTheme.accentLight.withValues(alpha: 0.5)
                          : LiquidTheme.accent.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LiquidTheme.accent.withValues(
                          alpha: isDark ? 0.3 : 0.15,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Segment Row
              Row(
                children: List.generate(totalCount, (index) {
                  final seg = segments[index];
                  final isSelected = index == validIndex;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (seg.value != selectedValue) {
                          onSelectionChanged(seg.value);
                        }
                      },
                      child: Center(
                        child:
                            seg.customChild ??
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (seg.icon != null) ...[
                                  AnimatedScale(
                                    scale: isSelected ? 1.06 : 1.0,
                                    duration: const Duration(milliseconds: 180),
                                    child: Icon(
                                      seg.icon,
                                      size: seg.iconSize ?? 15,
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white
                                                : LiquidTheme.accent)
                                          : (isDark
                                                ? LiquidTheme.darkTextSecondary
                                                : LiquidTheme
                                                      .lightTextSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Flexible(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 180),
                                    style: TextStyle(
                                      fontSize: seg.fontSize ?? 11,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white
                                                : LiquidTheme.accent)
                                          : (isDark
                                                ? LiquidTheme.darkTextSecondary
                                                : LiquidTheme
                                                      .lightTextSecondary),
                                    ),
                                    child: Text(
                                      seg.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
