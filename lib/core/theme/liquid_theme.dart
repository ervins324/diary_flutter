import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// Semantic styling and reusable LiquidGlass styles for Diary.
class LiquidTheme {
  // Brand colors
  static const Color accent = Color(0xFF6366F1); // Indigo 500
  static const Color accentLight = Color(0xFF818CF8);
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  // Dark palette
  static const Color darkBg = Color(0xFF090D16);
  static const Color darkCard = Color(0x1F1E293B);
  static const Color darkBorder = Color(0x2694A3B8);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0x40FFFFFF);
  static const Color lightBorder = Color(0x33CBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Cached style instances to avoid object allocation during list builds
  static final Map<String, LiquidGlassStyle> _styleCache = {};

  /// Predefined LiquidGlassStyle for primary cards (lessons, homework, notes)
  static LiquidGlassStyle cardStyle({bool isDark = true, double radius = 20.0}) {
    final key = 'card_${isDark}_$radius';
    return _styleCache.putIfAbsent(
      key,
      () => LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(cornerRadius: radius),
        appearance: LiquidGlassAppearance(
          color: isDark ? const Color(0x281E293B) : const Color(0x60FFFFFF),
          blur: const LiquidGlassBlur(sigmaX: 6.0, sigmaY: 6.0),
        ),
        liteGlass: LiquidGlassLitePickup.blend,
      ),
    );
  }

  /// Predefined LiquidGlassStyle for small badges, chips, and pills
  static LiquidGlassStyle pillStyle({bool isDark = true, double radius = 12.0}) {
    final key = 'pill_${isDark}_$radius';
    return _styleCache.putIfAbsent(
      key,
      () => LiquidGlassStyle(
        shape: LiquidGlassShape.continuousRoundedRectangle(cornerRadius: radius),
        appearance: LiquidGlassAppearance(
          color: isDark ? const Color(0x33334155) : const Color(0x66E2E8F0),
          blur: const LiquidGlassBlur(sigmaX: 4.0, sigmaY: 4.0),
        ),
        liteGlass: LiquidGlassLitePickup.blend,
      ),
    );
  }

  /// LiquidGlassStyle for navigation bars and floating headers
  static LiquidGlassStyle navBarStyle({bool isDark = true}) {
    final key = 'navbar_$isDark';
    return _styleCache.putIfAbsent(
      key,
      () => LiquidGlassStyle(
        shape: const LiquidGlassShape.continuousRoundedRectangle(cornerRadius: 32.0),
        appearance: LiquidGlassAppearance(
          color: isDark ? const Color(0x550F172A) : const Color(0x80FFFFFF),
          blur: const LiquidGlassBlur(sigmaX: 7.0, sigmaY: 7.0),
        ),
        liteGlass: LiquidGlassLitePickup.blend,
      ),
    );
  }
}
