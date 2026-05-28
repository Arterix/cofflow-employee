import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class BrewButton extends StatelessWidget {
  const BrewButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.color,
    this.foregroundColor,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? color;
  final Color? foregroundColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    final bg = color ?? AppColors.primary;
    final fg = foregroundColor ?? AppColors.onPrimary;

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(outlined ? bg : fg),
            ),
          )
        : Text(label);

    final btn = outlined
        ? OutlinedButton(
            onPressed: disabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: bg,
              side: BorderSide(color: bg),
            ),
            child: child,
          )
        : ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              disabledBackgroundColor: bg.withValues(alpha: 0.5),
              disabledForegroundColor: fg,
            ),
            child: child,
          );

    return isFullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
