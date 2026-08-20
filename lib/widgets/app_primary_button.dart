import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

/// Primary action button with built-in loading state and animated gradient.
class AppPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool secondary;
  final IconData? icon;
  final double? width;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.secondary = false,
    this.icon,
    this.width,
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown() => _ctrl.forward();
  void _onTapUp() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final disabled = !enabled;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final scale = 1 - (_ctrl.value * 0.03);
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => _onTapDown() : null,
        onTapUp: enabled
            ? (_) {
                _onTapUp();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: () => _onTapUp(),
        child: AnimatedContainer(
          duration: AppDimensions.shortAnim,
          width: widget.width,
          height: 54,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMd),
            gradient: disabled
                ? null
                : (widget.secondary ? AppColors.warmGradient : AppColors.brandGradient),
            color: disabled ? AppColors.outline : null,
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const Gap(AppDimensions.sm, vertical: false),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: disabled
                              ? AppColors.textTertiary
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
