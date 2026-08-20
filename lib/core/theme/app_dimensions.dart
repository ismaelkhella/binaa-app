import 'package:flutter/widgets.dart';

/// Centralized spacing/radius/timing tokens used by the design system.
class AppDimensions {
  AppDimensions._();

  // Spacing scale (8pt grid with extras)
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Radii
  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusPill = 999;

  // Icon sizes
  static const double iconSm = 16;
  static const double iconMd = 22;
  static const double iconLg = 28;
  static const double iconXl = 36;

  // Page-level horizontal padding
  static const double horizontalPadding = 20;

  // Animation timings
  static const Duration microAnim = Duration(milliseconds: 120);
  static const Duration shortAnim = Duration(milliseconds: 220);
  static const Duration mediumAnim = Duration(milliseconds: 350);
  static const Duration longAnim = Duration(milliseconds: 600);
}

/// Semantic gap widgets. Use these for vertical/horizontal spacing rather than SizedBox with magic numbers.
class Gap extends StatelessWidget {
  final double size;
  final bool vertical;
  const Gap(this.size, {super.key, this.vertical = true});

  const Gap.h(double size, {Key? key}) : this(size, key: key, vertical: false);
  const Gap.v(double size, {Key? key}) : this(size, key: key, vertical: true);

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: vertical ? null : size, height: vertical ? size : null);
}

