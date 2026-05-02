import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum RkBtnVariant { accent, ghost, outlined }
enum RkBtnSize    { md, lg }

class RkButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final RkBtnVariant variant;
  final RkBtnSize size;
  final IconData? icon;
  final bool fullWidth;

  const RkButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = RkBtnVariant.accent,
    this.size = RkBtnSize.md,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final h = size == RkBtnSize.lg ? 48.0 : 38.0;
    final fs = size == RkBtnSize.lg ? 14.0 : 13.0;

    Color bg, fg;
    BoxBorder? border;
    switch (variant) {
      case RkBtnVariant.accent:
        bg = AppColors.accent; fg = Colors.white; border = null;
        break;
      case RkBtnVariant.ghost:
        bg = AppColors.surface2; fg = AppColors.text;
        border = Border.all(color: AppColors.hairline);
        break;
      case RkBtnVariant.outlined:
        bg = Colors.transparent; fg = AppColors.text;
        border = Border.all(color: AppColors.hairline);
        break;
    }

    final btn = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: disabled ? bg.withOpacity(0.4) : bg,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          DefaultTextStyle.merge(
            style: TextStyle(
              color: fg,
              fontSize: fs,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            child: child,
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: btn,
      ),
    );
  }
}
