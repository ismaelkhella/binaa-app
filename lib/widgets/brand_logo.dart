import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

/// Bina Academy brand logo: stylized "ب" with an academic gilded dot.
/// Composed in pure Flutter — no asset files required.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool bright;

  const BrandLogo({super.key, this.size = 96, this.bright = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bright
                      ? AppColors.accent.withOpacity(0.55)
                      : AppColors.primary.withOpacity(0.35),
                  blurRadius: size * 0.6,
                  spreadRadius: size * 0.04,
                ),
              ],
            ),
            width: size,
            height: size,
          ),
          // Background disc
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
              boxShadow: AppColors.elevatedShadow,
            ),
            width: size * 0.8,
            height: size * 0.8,
          ),
          // "ب" letter centered
          Center(
            child: Text(
              'ب',
              style: TextStyle(
                fontSize: size * 0.45,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
                shadows: bright
                    ? [
                        const Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          // Gilded accent dot in top-right corner (positioned explicitly)
          Positioned(
            top: size * 0.08,
            right: size * 0.08,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.warmGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  final double fontSize;
  final Color color;
  final bool showSub;
  final bool reverseColors;

  const BrandWordmark({
    super.key,
    this.fontSize = 28,
    this.color = Colors.white,
    this.showSub = true,
    this.reverseColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = reverseColors ? AppColors.primary : color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            colors: reverseColors
                ? [AppColors.primary, AppColors.primaryLight]
                : [Colors.white, AppColors.accentLight],
          ).createShader(rect),
          child: Text(
            'Bina Academy',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (showSub) ...[
          const Gap(AppDimensions.xs),
          Text(
            'أكاديمية بناء  ·  التوجيهي بثقة',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: fontSize * 0.45,
              fontWeight: FontWeight.w700,
              color: primary.withOpacity(0.9),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ],
    );
  }
}
