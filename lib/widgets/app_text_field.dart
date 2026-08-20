import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimensions.dart';

/// Styled text field used across forms. Auto-pads input direction (LTR for OTP
/// + phone prefix, RTL by default), shows focus glow, and supports a hero icon.
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool obscure;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool enabled;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.obscure = false,
    this.maxLength,
    this.inputFormatters,
    this.autofocus = false,
    this.enabled = true,
    this.suffix,
    this.textInputAction,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _autoFocus = FocusNode();
  late final FocusNode _focus = widget.focusNode ?? _autoFocus;

  @override
  void dispose() {
    if (widget.focusNode == null) _autoFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withOpacity(0.75),
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: AppDimensions.sm),
        TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          obscureText: widget.obscure,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          textInputAction: widget.textInputAction,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: '',
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, color: AppColors.primary)
                : null,
            suffixIcon: widget.suffix,
          ),
        ),
      ],
    );
  }
}
