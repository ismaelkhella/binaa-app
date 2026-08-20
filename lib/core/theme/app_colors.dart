import 'package:flutter/material.dart';

/// Bina Academy color palette - premium academic feel with deep indigo and amber accents.
class AppColors {
  AppColors._();

  // ── Primary brand: deep indigo with subtle violet undertone ──
  static const Color primary = Color(0xFF3D2EAE);
  static const Color primaryLight = Color(0xFF6E5BD9);
  static const Color primaryDark = Color(0xFF1F1672);
  static const Color primarySurface = Color(0xFFF3F1FF);

  // ── Accent: warm amber/gold for "achievement" feel ──
  static const Color accent = Color(0xFFFFB547);
  static const Color accentLight = Color(0xFFFFD27A);
  static const Color accentDark = Color(0xFFD4830F);

  // ── Success / info / warning / error ──
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color info = Color(0xFF0EA5E9);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSurface = Color(0xFFFEE2E2);

  // ── Neutrals for light theme ──
  static const Color background = Color(0xFFF6F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFBFD);
  static const Color outline = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ── Neutrals for dark theme ──
  static const Color backgroundDark = Color(0xFF0B0E1A);
  static const Color surfaceDark = Color(0xFF151829);
  static const Color surfaceDarkAlt = Color(0xFF1C2138);
  static const Color outlineDark = Color(0xFF2A2F45);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFB4B7C9);
  static const Color textTertiaryDark = Color(0xFF6E7191);

  // ── Gradients ──
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF3D2EAE), Color(0xFF6E5BD9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFFB547), Color(0xFFFFD27A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cosmicGradient = LinearGradient(
    colors: [Color(0xFF1F1672), Color(0xFF3D2EAE), Color(0xFF6E5BD9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lockGradient = LinearGradient(
    colors: [Color(0xFF2A2F45), Color(0xFF3B4055)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glow shadow for cards ──
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primary.withOpacity(0.18),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}
