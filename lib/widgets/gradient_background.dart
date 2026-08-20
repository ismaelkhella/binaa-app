import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

/// Premium-feeling gradient backdrop. Used by auth screens and shell headers.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool dark;
  final List<Color>? colors;
  final bool withStars;

  const GradientBackground({
    super.key,
    required this.child,
    this.dark = false,
    this.colors,
    this.withStars = true,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = colors != null
        ? LinearGradient(
            colors: colors!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : (dark ? AppColors.cosmicGradient : AppColors.brandGradient);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: const SizedBox.expand(),
        ),
        if (withStars) ..._decorBlobs(dark),
        child,
      ],
    );
  }

  List<Widget> _decorBlobs(bool dark) => [
        Positioned(
          top: -120,
          right: -80,
          child: _Blob(
            size: 320,
            color: Colors.white.withOpacity(dark ? 0.06 : 0.18),
          ),
        ),
        Positioned(
          top: 180,
          left: -100,
          child: _Blob(
            size: 280,
            color: AppColors.accent.withOpacity(dark ? 0.16 : 0.28),
          ),
        ),
        Positioned(
          bottom: -160,
          right: -60,
          child: _Blob(
            size: 360,
            color: Colors.white.withOpacity(dark ? 0.04 : 0.12),
          ),
        ),
      ];
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }
}

/// A subtle dotted background pattern. Used for some surfaces.
class DottedSurface extends StatelessWidget {
  final Color color;
  final double density;
  const DottedSurface({super.key, required this.color, this.density = 0.04});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedPainter(color: color, density: density),
      size: Size.infinite,
    );
  }
}

class _DottedPainter extends CustomPainter {
  final Color color;
  final double density;
  _DottedPainter({required this.color, required this.density});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), density, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DottedPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.density != density;
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.horizontalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const Gap(AppDimensions.sm),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
